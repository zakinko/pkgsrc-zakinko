$NetBSD$

The ALSA code from types.rs and helpers.rs, behind the backend interface.

--- src/backend_alsa.rs.orig
+++ src/backend_alsa.rs
@@ -0,0 +1,389 @@
+// SPDX-License-Identifier: MIT
+// (C) 2022 The Asahi Linux Contributors
+/*!
+    ALSA backend (Linux).  The code is what types.rs and helpers.rs had,
+    moved behind the small interface main.rs and types.rs use, so that
+    other systems can provide the same interface.
+*/
+
+use std::ffi::{CStr, CString};
+use std::fs;
+
+use alsa::mixer::MilliBel;
+use log::warn;
+
+use crate::types::Globals;
+
+pub const FLAGFILE: &str = "/run/speakersafetyd/speakersafetyd.flag";
+
+pub fn get_machine() -> String {
+    fs::read_to_string("/proc/device-tree/compatible")
+        .expect("Could not read device tree compatible")
+        .split_once("\0")
+        .expect("Unexpected compatible format")
+        .0
+        .trim_end_matches(|c: char| c.is_ascii_alphabetic())
+        .to_string()
+}
+
+fn open_card(card: &str) -> alsa::ctl::Ctl {
+    let ctldev: alsa::ctl::Ctl = match alsa::ctl::Ctl::new(card, false) {
+        Ok(ctldev) => ctldev,
+        Err(e) => {
+            panic!("{}: Could not open sound card! Error: {}", card, e);
+        }
+    };
+
+    ctldev
+}
+
+fn open_pcm(dev: &str, chans: u32, mut sample_rate: u32) -> alsa::pcm::PCM {
+    let pcm = alsa::pcm::PCM::new(dev, alsa::Direction::Capture, false).unwrap();
+    {
+        let params = alsa::pcm::HwParams::any(&pcm).unwrap();
+
+        let rate_max = params.get_rate_max().unwrap();
+        let rate_min = params.get_rate_min().unwrap();
+        println!("PCM rate: {}..{}", rate_min, rate_max);
+
+        if sample_rate == 0 {
+            sample_rate = rate_min;
+        }
+
+        params.set_channels(chans).unwrap();
+        params
+            .set_rate(sample_rate, alsa::ValueOr::Nearest)
+            .unwrap();
+        params.set_format(alsa::pcm::Format::s16()).unwrap();
+        params.set_access(alsa::pcm::Access::RWInterleaved).unwrap();
+        pcm.hw_params(&params).unwrap();
+    }
+
+    pcm
+}
+
+/**
+    Wrapper around alsa::ctl::ElemValue::new(). Lets us bail on errors and
+    pass in the Bytes type for V/ISENSE
+*/
+fn new_elemvalue(t: alsa::ctl::ElemType) -> alsa::ctl::ElemValue {
+    match alsa::ctl::ElemValue::new(t) {
+        Ok(val) => val,
+        Err(_e) => {
+            panic!("Could not open a handle to an element!");
+        }
+    }
+}
+
+fn read_ev(card: &alsa::ctl::Ctl, ev: &mut alsa::ctl::ElemValue, name: &str) {
+    match card.elem_read(ev) {
+        Ok(val) => val,
+        Err(e) => {
+            panic!(
+                "Could not read elem value {}. alsa-lib error: {:?}",
+                name, e
+            );
+        }
+    };
+}
+
+fn write_ev(card: &alsa::ctl::Ctl, ev: &alsa::ctl::ElemValue, name: &str) {
+    match card.elem_write(ev) {
+        Ok(val) => val,
+        Err(e) => {
+            panic!(
+                "Could not write elem value {}. alsa-lib error: {:?}",
+                name, e
+            );
+        }
+    };
+}
+
+fn get_range_db(
+    card: &alsa::ctl::Ctl,
+    el: &alsa::ctl::ElemId,
+    name: &str,
+) -> (MilliBel, MilliBel) {
+    match card.get_db_range(el) {
+        Ok(val) => val,
+        Err(e) => {
+            panic!(
+                "Could not get elem db range {}. alsa-lib error: {:?}",
+                name, e
+            );
+        }
+    }
+}
+
+fn lock_el(card: &alsa::ctl::Ctl, el: &alsa::ctl::ElemId, name: &str) {
+    let _val = match card.elem_lock(el) {
+        Ok(val) => val,
+        Err(e) => {
+            panic!("Could not lock elem {}. alsa-lib error: {:?}", name, e);
+        }
+    };
+}
+
+fn int_to_db(card: &alsa::ctl::Ctl, id: &alsa::ctl::ElemId, val: i32) -> MilliBel {
+    match card.convert_to_db(id, val.into()) {
+        Ok(inner) => inner,
+        Err(e) => {
+            panic!(
+                "Could not convert val {} to dB! alsa-lib error: {:?}",
+                val, e
+            );
+        }
+    }
+}
+
+fn db_to_int(card: &alsa::ctl::Ctl, id: &alsa::ctl::ElemId, val: f32) -> i32 {
+    let mb: MilliBel = MilliBel((val * 100.0) as i64);
+
+    match card.convert_from_db(id, mb, alsa::Round::Floor) {
+        Ok(inner) => inner as i32,
+        Err(e) => {
+            panic!(
+                "Could not convert MilliBel {:?} to int! alsa-lib error: {:?}",
+                val, e
+            );
+        }
+    }
+}
+
+/**
+    Struct with fields necessary for manipulating an ALSA elem.
+*/
+struct Elem {
+    elem_name: String,
+    id: alsa::ctl::ElemId,
+    val: alsa::ctl::ElemValue,
+}
+
+impl Elem {
+    fn new(name: String, card: &alsa::ctl::Ctl, t: alsa::ctl::ElemType) -> Elem {
+        let borrow: String = name.clone();
+
+        let mut new_elem: Elem = {
+            Elem {
+                elem_name: name,
+                id: alsa::ctl::ElemId::new(alsa::ctl::ElemIface::Mixer),
+                val: new_elemvalue(t),
+            }
+        };
+
+        let cname: CString = CString::new(borrow).unwrap();
+        let cstr: &CStr = cname.as_c_str();
+
+        new_elem.id.set_name(cstr);
+        new_elem.val.set_id(&new_elem.id);
+        lock_el(card, &new_elem.id, &new_elem.elem_name);
+        read_ev(card, &mut new_elem.val, &new_elem.elem_name);
+
+        new_elem
+    }
+
+    fn read_int(&mut self, card: &alsa::ctl::Ctl) -> i32 {
+        read_ev(card, &mut self.val, &self.elem_name);
+
+        self.val
+            .get_integer(0)
+            .unwrap_or_else(|| panic!("Could not read {}", self.elem_name))
+    }
+
+    fn write_int(&mut self, card: &alsa::ctl::Ctl, value: i32) {
+        self.val
+            .set_integer(0, value)
+            .unwrap_or_else(|| panic!("Could not set {}", self.elem_name));
+        write_ev(card, &self.val, &self.elem_name);
+    }
+}
+
+/// The sound card: its controls and the V/ISENSE capture device name.
+pub struct Card {
+    ctl: alsa::ctl::Ctl,
+    device: String,
+    sample_rate_elem: Elem,
+    unlock_elem: Elem,
+}
+
+impl Card {
+    pub fn open(maker: &str, model: &str) -> Card {
+        let maker_titlecase = maker[0..1].to_ascii_uppercase() + &maker[1..];
+        let device = format!("hw:{}{}", maker_titlecase, model.to_ascii_uppercase());
+        log::info!("Device: {}", device);
+
+        let ctl = open_card(&device);
+        let sample_rate_elem = Elem::new(
+            "Speaker Sample Rate".to_string(),
+            &ctl,
+            alsa::ctl::ElemType::Integer,
+        );
+        let unlock_elem = Elem::new(
+            "Speaker Volume Unlock".to_string(),
+            &ctl,
+            alsa::ctl::ElemType::Integer,
+        );
+
+        Card {
+            ctl,
+            device,
+            sample_rate_elem,
+            unlock_elem,
+        }
+    }
+
+    pub fn sample_rate(&mut self) -> i32 {
+        self.sample_rate_elem.read_int(&self.ctl)
+    }
+
+    pub fn unlock(&mut self, magic: i32) {
+        self.unlock_elem.write_int(&self.ctl, magic);
+    }
+
+    pub fn open_sense(&self, globals: &Globals) -> Sense {
+        let pcm_name = format!("{},{}", self.device, globals.visense_pcm);
+        let pcm = open_pcm(&pcm_name, globals.channels.try_into().unwrap(), 0);
+        Sense {
+            pcm: Some(pcm),
+            name: pcm_name,
+            channels: globals.channels,
+        }
+    }
+}
+
+pub enum ReadError {
+    /// Read nothing; try again (the device was reopened after suspend).
+    Retry,
+    Fatal(String),
+}
+
+/// The V/ISENSE capture stream.
+pub struct Sense {
+    pcm: Option<alsa::pcm::PCM>,
+    name: String,
+    channels: usize,
+}
+
+impl Sense {
+    pub fn read(&mut self, buf: &mut [i16]) -> Result<usize, ReadError> {
+        let res = {
+            let io = self.pcm.as_ref().unwrap().io_i16().unwrap();
+            io.readi(buf)
+        };
+        match res {
+            Ok(n) => Ok(n),
+            Err(e) if e.errno() == libc::ESTRPIPE => {
+                warn!("Suspend detected!");
+                // Work around kernel issue: resume sometimes breaks visense
+                warn!("Reinitializing PCM to work around kernel bug...");
+                self.pcm = None;
+                self.pcm = Some(open_pcm(
+                    &self.name,
+                    self.channels.try_into().unwrap(),
+                    0,
+                ));
+                Err(ReadError::Retry)
+            }
+            Err(e) => Err(ReadError::Fatal(format!("{}", e))),
+        }
+    }
+}
+
+/**
+    Mixer controls of one speaker: its amplifier's gain and the speaker
+    volume the daemon lowers.
+*/
+pub struct SpeakerCtl {
+    drv: String,
+    level: Elem,
+    amp_gain: Elem,
+}
+
+impl SpeakerCtl {
+    pub fn new(name: &str, card: &Card, globals: &Globals) -> SpeakerCtl {
+        let ctl = &card.ctl;
+        let prefix = if name == "Mono" {
+            "".to_string()
+        } else {
+            name.to_owned() + " "
+        };
+
+        let mut vs = Elem::new(
+            prefix.clone() + &globals.ctl_vsense,
+            ctl,
+            alsa::ctl::ElemType::Boolean,
+        );
+
+        vs.val.set_boolean(0, true);
+        write_ev(ctl, &vs.val, &vs.elem_name);
+        read_ev(ctl, &mut vs.val, &vs.elem_name);
+        assert!(vs.val.get_boolean(0).unwrap());
+
+        let mut is = Elem::new(
+            prefix.clone() + &globals.ctl_isense,
+            ctl,
+            alsa::ctl::ElemType::Boolean,
+        );
+
+        is.val.set_boolean(0, true);
+        write_ev(ctl, &is.val, &is.elem_name);
+        read_ev(ctl, &mut vs.val, &vs.elem_name);
+        assert!(vs.val.get_boolean(0).unwrap());
+
+        let mut ret = SpeakerCtl {
+            drv: name.to_owned(),
+            level: Elem::new(
+                prefix.clone() + &globals.ctl_volume,
+                ctl,
+                alsa::ctl::ElemType::Integer,
+            ),
+            amp_gain: Elem::new(
+                prefix + &globals.ctl_amp_gain,
+                ctl,
+                alsa::ctl::ElemType::Integer,
+            ),
+        };
+
+        /*
+         * Set amp gain to max available (kernel should've clamped).
+         * alsa-rs only has bindings for range in dB, so we go through
+         * that.
+         */
+
+        let (_min, max) = get_range_db(ctl, &mut ret.amp_gain.id, &ret.amp_gain.elem_name);
+        let max_int = ctl
+            .convert_from_db(&mut ret.amp_gain.id, max, alsa::Round::Floor)
+            .unwrap();
+
+        ret.amp_gain.val.set_integer(0, max_int.try_into().unwrap());
+
+        write_ev(ctl, &ret.amp_gain.val, &ret.amp_gain.elem_name);
+
+        ret
+    }
+
+    pub fn get_amp_gain(&mut self, card: &Card) -> f32 {
+        read_ev(&card.ctl, &mut self.amp_gain.val, &self.amp_gain.elem_name);
+
+        let val = self
+            .amp_gain
+            .val
+            .get_integer(0)
+            .unwrap_or_else(|| panic!("Could not read amp gain for {}", self.drv));
+
+        int_to_db(&card.ctl, &self.amp_gain.id, val).to_db()
+    }
+
+    pub fn set_lvl(&mut self, card: &Card, lvl: f32) {
+        let new_val: i32 = db_to_int(&card.ctl, &self.level.id, lvl);
+
+        match self.level.val.set_integer(0, new_val) {
+            Some(_) => {}
+            None => {
+                panic!("Could not set level for {}", self.drv);
+            }
+        };
+
+        write_ev(&card.ctl, &self.level.val, &self.level.elem_name);
+    }
+}
