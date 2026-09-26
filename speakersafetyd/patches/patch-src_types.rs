$NetBSD$

Speaker controls come from the backend.

--- src/types.rs.orig
+++ src/types.rs
@@ -1,196 +1,29 @@
 // SPDX-License-Identifier: MIT
 // (C) 2022 The Asahi Linux Contributors
 
-use alsa::ctl::Ctl;
 use configparser::ini::Ini;
 use log::{debug, info};
-use std::ffi::{CStr, CString};
 
+use crate::backend::{Card, SpeakerCtl};
 use crate::helpers;
 
-/**
-    Struct with fields necessary for manipulating an ALSA elem.
-
-    The val field is created using a wrapper so that we can handle
-    any errors.
-*/
-pub struct Elem {
-    elem_name: String,
-    id: alsa::ctl::ElemId,
-    val: alsa::ctl::ElemValue,
-}
-
-impl Elem {
-    pub fn new(name: String, card: &Ctl, t: alsa::ctl::ElemType) -> Elem {
-        // CString::new() cannot borrow a String. We want name for the elem
-        // for error identification though, so it can't consume name directly.
-        let borrow: String = name.clone();
-
-        let mut new_elem: Elem = {
-            Elem {
-                elem_name: name,
-                id: alsa::ctl::ElemId::new(alsa::ctl::ElemIface::Mixer),
-                val: helpers::new_elemvalue(t),
-            }
-        };
-
-        let cname: CString = CString::new(borrow).unwrap();
-        let cstr: &CStr = cname.as_c_str();
-
-        new_elem.id.set_name(cstr);
-        new_elem.val.set_id(&new_elem.id);
-        helpers::lock_el(card, &new_elem.id, &new_elem.elem_name);
-        helpers::read_ev(card, &mut new_elem.val, &new_elem.elem_name);
-
-        new_elem
-    }
-
-    pub fn read_int(&mut self, card: &Ctl) -> i32 {
-        helpers::read_ev(card, &mut self.val, &self.elem_name);
-
-        self.val
-            .get_integer(0)
-            .unwrap_or_else(|| panic!("Could not read {}", self.elem_name))
-    }
-
-    pub fn write_int(&mut self, card: &Ctl, value: i32) {
-        self.val
-            .set_integer(0, value)
-            .unwrap_or_else(|| panic!("Could not set {}", self.elem_name));
-        helpers::write_ev(card, &mut self.val, &self.elem_name);
-    }
-}
-
-/**
-    Mixer struct representing the controls associated with a given
-    Speaker. Populated with the important ALSA controls at runtime.
-
-    level:  mixer volume control
-    vsense: VSENSE switch
-    isense: ISENSE switch
-
-*/
-struct Mixer {
-    drv: String,
-    level: Elem,
-    amp_gain: Elem,
-}
-
-impl Mixer {
-    // TODO: implement turning on V/ISENSE
-    fn new(name: &str, card: &Ctl, globals: &Globals) -> Mixer {
-        let prefix = if name == "Mono" {
-            "".to_string()
-        } else {
-            name.to_owned() + " "
-        };
-
-        let mut vs = Elem::new(
-            prefix.clone() + &globals.ctl_vsense,
-            card,
-            alsa::ctl::ElemType::Boolean,
-        );
-
-        vs.val.set_boolean(0, true);
-        helpers::write_ev(card, &vs.val, &vs.elem_name);
-        helpers::read_ev(card, &mut vs.val, &vs.elem_name);
-        assert!(vs.val.get_boolean(0).unwrap());
-
-        let mut is = Elem::new(
-            prefix.clone() + &globals.ctl_isense,
-            card,
-            alsa::ctl::ElemType::Boolean,
-        );
-
-        is.val.set_boolean(0, true);
-        helpers::write_ev(card, &is.val, &is.elem_name);
-        helpers::read_ev(card, &mut vs.val, &vs.elem_name);
-        assert!(vs.val.get_boolean(0).unwrap());
-
-        let mut ret = Mixer {
-            drv: name.to_owned(),
-            level: Elem::new(
-                prefix.clone() + &globals.ctl_volume,
-                card,
-                alsa::ctl::ElemType::Integer,
-            ),
-            amp_gain: Elem::new(
-                prefix + &globals.ctl_amp_gain,
-                card,
-                alsa::ctl::ElemType::Integer,
-            ),
-        };
-
-        /*
-         * Set amp gain to max available (kernel should've clamped).
-         * alsa-rs only has bindings for range in dB, so we go through
-         * that.
-         */
-
-        let (_min, max) =
-            helpers::get_range_db(card, &mut ret.amp_gain.id, &ret.amp_gain.elem_name);
-        let max_int = card
-            .convert_from_db(&mut ret.amp_gain.id, max, alsa::Round::Floor)
-            .unwrap();
-
-        ret.amp_gain.val.set_integer(0, max_int.try_into().unwrap());
-
-        helpers::write_ev(card, &ret.amp_gain.val, &ret.amp_gain.elem_name);
-
-        ret
-    }
-
-    fn get_amp_gain(&mut self, card: &Ctl) -> f32 {
-        helpers::read_ev(card, &mut self.amp_gain.val, &self.amp_gain.elem_name);
-
-        let val = self
-            .amp_gain
-            .val
-            .get_integer(0)
-            .unwrap_or_else(|| panic!("Could not read amp gain for {}", self.drv));
-
-        helpers::int_to_db(card, &self.amp_gain.id, val).to_db()
-    }
-
-    /*
-    fn get_lvl(&mut self, card: &Ctl) -> f32 {
-        helpers::read_ev(card, &mut self.level.val, &self.level.elem_name);
-
-        let val = self
-            .level
-            .val
-            .get_integer(0)
-            .expect(&format!("Could not read level for {}", self.drv));
-
-        helpers::int_to_db(card, &self.level.id, val).to_db()
-    }
-    */
-
-    fn set_lvl(&mut self, card: &Ctl, lvl: f32) {
-        let new_val: i32 = helpers::db_to_int(card, &self.level.id, lvl);
-
-        match self.level.val.set_integer(0, new_val) {
-            Some(_) => {}
-            None => {
-                panic!("Could not set level for {}", self.drv);
-            }
-        };
-
-        helpers::write_ev(card, &self.level.val, &self.level.elem_name);
-    }
-}
-
 #[derive(Clone)]
 pub struct Globals {
+    /* The PCM number and control names are ALSA's; other backends ignore them. */
+    #[cfg_attr(not(target_os = "linux"), allow(dead_code))]
     pub visense_pcm: usize,
     pub channels: usize,
     pub period: usize,
     pub t_ambient: f32,
     pub t_window: f32,
     pub t_hysteresis: f32,
+    #[cfg_attr(not(target_os = "linux"), allow(dead_code))]
     pub ctl_vsense: String,
+    #[cfg_attr(not(target_os = "linux"), allow(dead_code))]
     pub ctl_isense: String,
+    #[cfg_attr(not(target_os = "linux"), allow(dead_code))]
     pub ctl_amp_gain: String,
+    #[cfg_attr(not(target_os = "linux"), allow(dead_code))]
     pub ctl_volume: String,
     pub uclamp_min: Option<usize>,
     pub uclamp_max: Option<usize>,
@@ -245,7 +78,7 @@
 pub struct Speaker {
     pub name: String,
     pub group: usize,
-    alsa_iface: Mixer,
+    alsa_iface: SpeakerCtl,
     tau_coil: f32,
     tau_magnet: f32,
     tr_coil: f32,
@@ -263,13 +96,13 @@
 }
 
 impl Speaker {
-    pub fn new(globals: &Globals, name: &str, config: &Ini, ctl: &Ctl, cold_boot: bool) -> Speaker {
+    pub fn new(globals: &Globals, name: &str, config: &Ini, card: &Card, cold_boot: bool) -> Speaker {
         info!("Speaker [{}]:", name);
 
         let section = "Speaker/".to_owned() + name;
         let mut new_speaker: Speaker = Speaker {
             name: name.to_string(),
-            alsa_iface: Mixer::new(name, ctl, globals),
+            alsa_iface: SpeakerCtl::new(name, card, globals),
             group: helpers::parse_int(config, &section, "group"),
             tau_coil: helpers::parse_float(config, &section, "tau_coil"),
             tau_magnet: helpers::parse_float(config, &section, "tau_magnet"),
@@ -302,7 +135,7 @@
         let max_dt = new_speaker.t_limit - globals.t_ambient;
         let max_pwr = max_dt / (new_speaker.tr_magnet + new_speaker.tr_coil);
 
-        let amp_gain = new_speaker.alsa_iface.get_amp_gain(ctl);
+        let amp_gain = new_speaker.alsa_iface.get_amp_gain(card);
 
         // Worst-case peak power is 2x RMS power
         let peak_pwr = 10f32.powf(amp_gain / 10.) / new_speaker.z_nominal * 2.;
@@ -421,7 +254,7 @@
         );
     }
 
-    pub fn update(&mut self, ctl: &Ctl, gain: f32) {
-        self.alsa_iface.set_lvl(ctl, gain);
+    pub fn update(&mut self, card: &Card, gain: f32) {
+        self.alsa_iface.set_lvl(card, gain);
     }
 }
