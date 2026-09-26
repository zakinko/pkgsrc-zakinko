$NetBSD$

NetBSD backend: applemacaudio(4) sysctl nodes and the audio(4) sense device.

--- src/backend_netbsd.rs.orig
+++ src/backend_netbsd.rs
@@ -0,0 +1,351 @@
+// SPDX-License-Identifier: MIT
+/*!
+    NetBSD backend.
+
+    The kernel driver (applemacaudio(4)) exposes what the ALSA controls
+    give on Linux as sysctl nodes under hw.<device>:
+
+      compatible             machine, e.g. "apple,j293"
+      speaker_rate           speaker sample rate, 0 when idle
+      speaker_unlock         write the magic to keep the lock open
+      amp_gain_max           amplifier level cap, cdBV (hundredths of dBV)
+      sense_audio            audio device recording V/ISENSE, e.g. "audio1"
+      speaker.<name>.volume  speaker volume, cdB, 0 or below
+
+    The amplifiers always have sense on, and their gain is fixed at the
+    cap by the kernel, so the VSENSE/ISENSE/amp gain controls have no
+    counterpart here.
+*/
+
+use std::ffi::{CStr, CString};
+use std::fs::{File, OpenOptions};
+use std::io::Read;
+use std::os::unix::io::AsRawFd;
+
+use log::info;
+
+use crate::types::Globals;
+
+/// Cleared at boot by rc(8), which is what cold boot detection needs.
+pub const FLAGFILE: &str = "@VARBASE@/run/speakersafetyd.flag";
+
+const MAX_DEVICES: usize = 4;
+
+fn sysctl_raw(name: &str, buf: &mut [u8], new: Option<&[u8]>) -> std::io::Result<usize> {
+    let cname = CString::new(name).unwrap();
+    let mut len: libc::size_t = buf.len();
+    let (np, nl) = match new {
+        Some(n) => (n.as_ptr() as *const libc::c_void, n.len()),
+        None => (std::ptr::null(), 0),
+    };
+    let r = unsafe {
+        libc::sysctlbyname(
+            cname.as_ptr(),
+            buf.as_mut_ptr() as *mut libc::c_void,
+            &mut len,
+            np,
+            nl,
+        )
+    };
+    if r != 0 {
+        return Err(std::io::Error::last_os_error());
+    }
+    Ok(len)
+}
+
+fn sysctl_int(name: &str) -> std::io::Result<i32> {
+    let mut buf = [0u8; 4];
+    sysctl_raw(name, &mut buf, None)?;
+    Ok(i32::from_ne_bytes(buf))
+}
+
+fn sysctl_set_int(name: &str, val: i32) -> std::io::Result<()> {
+    let mut old = [0u8; 4];
+    sysctl_raw(name, &mut old, Some(&val.to_ne_bytes()))?;
+    Ok(())
+}
+
+fn sysctl_string(name: &str) -> std::io::Result<String> {
+    let mut buf = [0u8; 256];
+    let n = sysctl_raw(name, &mut buf, None)?;
+    let s = CStr::from_bytes_until_nul(&buf[..n.max(1)])
+        .map(|c| c.to_string_lossy().into_owned())
+        .unwrap_or_default();
+    Ok(s)
+}
+
+/// The first hw.applemacaudioN that answers.
+fn find_device() -> String {
+    for n in 0..MAX_DEVICES {
+        let dev = format!("applemacaudio{}", n);
+        if sysctl_string(&format!("hw.{}.compatible", dev)).is_ok() {
+            return dev;
+        }
+    }
+    panic!("No applemacaudio device");
+}
+
+pub fn get_machine() -> String {
+    let dev = find_device();
+    sysctl_string(&format!("hw.{}.compatible", dev))
+        .expect("Could not read machine compatible")
+        .trim_end_matches(|c: char| c.is_ascii_alphabetic())
+        .to_string()
+}
+
+/// "Left Front" -> "left_front", as the driver names the nodes.
+fn node_name(name: &str) -> String {
+    name.chars()
+        .map(|c| {
+            if c.is_ascii_alphanumeric() {
+                c.to_ascii_lowercase()
+            } else {
+                '_'
+            }
+        })
+        .collect()
+}
+
+pub struct Card {
+    dev: String,
+}
+
+impl Card {
+    pub fn open(_maker: &str, _model: &str) -> Card {
+        let dev = find_device();
+        info!("Device: {}", dev);
+        Card { dev }
+    }
+
+    pub fn sample_rate(&mut self) -> i32 {
+        sysctl_int(&format!("hw.{}.speaker_rate", self.dev))
+            .unwrap_or_else(|e| panic!("Could not read speaker rate: {}", e))
+    }
+
+    pub fn unlock(&mut self, magic: i32) {
+        sysctl_set_int(&format!("hw.{}.speaker_unlock", self.dev), magic)
+            .unwrap_or_else(|e| panic!("Could not write speaker unlock: {}", e));
+    }
+
+    pub fn open_sense(&self, globals: &Globals) -> Sense {
+        let adev = sysctl_string(&format!("hw.{}.sense_audio", self.dev))
+            .unwrap_or_else(|e| panic!("Could not find the sense device: {}", e));
+        if adev.is_empty() {
+            panic!("The driver has no sense capture device");
+        }
+        Sense::open(&format!("/dev/{}", adev), globals.channels)
+    }
+}
+
+pub enum ReadError {
+    #[allow(dead_code)]
+    Retry,
+    Fatal(String),
+}
+
+/*
+ * struct audio_prinfo and struct audio_info from <sys/audioio.h>.  Only
+ * the record side is set; the rest stays all ones, which AUDIO_INITINFO
+ * uses to mean "unchanged".
+ */
+#[repr(C)]
+#[derive(Clone, Copy)]
+struct AudioPrinfo {
+    sample_rate: u32,
+    channels: u32,
+    precision: u32,
+    encoding: u32,
+    gain: u32,
+    port: u32,
+    seek: u32,
+    avail_ports: u32,
+    buffer_size: u32,
+    _ispare: [u32; 1],
+    samples: u32,
+    eof: u32,
+    pause: u8,
+    error: u8,
+    waiting: u8,
+    balance: u8,
+    cspare: [u8; 2],
+    open: u8,
+    active: u8,
+}
+
+#[repr(C)]
+#[derive(Clone, Copy)]
+struct AudioInfo {
+    play: AudioPrinfo,
+    record: AudioPrinfo,
+    monitor_gain: u32,
+    blocksize: u32,
+    hiwat: u32,
+    lowat: u32,
+    _ispare1: u32,
+    mode: u32,
+}
+
+const AUDIO_ENCODING_SLINEAR_LE: u32 = 6;
+const AUMODE_RECORD: u32 = 0x02;
+
+/* _IOWR('A', 22, struct audio_info) */
+const fn iowr(group: u8, num: u8, len: usize) -> libc::c_ulong {
+    const IOC_INOUT: libc::c_ulong = 0x8000_0000 | 0x4000_0000;
+    IOC_INOUT | (((len as libc::c_ulong) & 0x1fff) << 16) | ((group as libc::c_ulong) << 8)
+        | (num as libc::c_ulong)
+}
+const AUDIO_SETINFO: libc::c_ulong = iowr(b'A', 22, std::mem::size_of::<AudioInfo>());
+
+pub struct Sense {
+    file: File,
+    channels: usize,
+    bytes: Vec<u8>,
+}
+
+impl Sense {
+    fn open(path: &str, channels: usize) -> Sense {
+        let file = OpenOptions::new()
+            .read(true)
+            .open(path)
+            .unwrap_or_else(|e| panic!("{}: {}", path, e));
+
+        let mut ai: AudioInfo = unsafe { std::mem::zeroed() };
+        unsafe {
+            std::ptr::write_bytes(
+                &mut ai as *mut AudioInfo as *mut u8,
+                0xff,
+                std::mem::size_of::<AudioInfo>(),
+            );
+        }
+        ai.record.sample_rate = 48000;
+        ai.record.channels = channels as u32;
+        ai.record.precision = 16;
+        ai.record.encoding = AUDIO_ENCODING_SLINEAR_LE;
+        ai.mode = AUMODE_RECORD;
+        let r = unsafe { libc::ioctl(file.as_raw_fd(), AUDIO_SETINFO as _, &mut ai) };
+        if r != 0 {
+            panic!(
+                "{}: AUDIO_SETINFO: {}",
+                path,
+                std::io::Error::last_os_error()
+            );
+        }
+        info!("Sense capture: {}, {} channels", path, channels);
+        Sense {
+            file,
+            channels,
+            bytes: Vec::new(),
+        }
+    }
+
+    /// Whole frames only, as ALSA's readi() gives.
+    pub fn read(&mut self, buf: &mut [i16]) -> Result<usize, ReadError> {
+        let frame = 2 * self.channels;
+        let want = buf.len() * 2;
+        self.bytes.resize(want, 0);
+        let mut got = 0;
+        while got < frame || got % frame != 0 {
+            match self.file.read(&mut self.bytes[got..want]) {
+                Ok(0) => return Err(ReadError::Fatal("end of file".into())),
+                Ok(n) => got += n,
+                Err(e) if e.kind() == std::io::ErrorKind::Interrupted => {
+                    return Err(ReadError::Fatal(format!("{}", e)))
+                }
+                Err(e) => return Err(ReadError::Fatal(format!("{}", e))),
+            }
+            if got == want {
+                break;
+            }
+        }
+        for (i, s) in buf.iter_mut().enumerate().take(got / 2) {
+            *s = i16::from_le_bytes([self.bytes[2 * i], self.bytes[2 * i + 1]]);
+        }
+        Ok(got / frame)
+    }
+}
+
+/// One speaker's volume node.
+pub struct SpeakerCtl {
+    volume: String,
+    cap: String,
+}
+
+impl SpeakerCtl {
+    pub fn new(name: &str, card: &Card, _globals: &Globals) -> SpeakerCtl {
+        let volume = format!("hw.{}.speaker.{}.volume", card.dev, node_name(name));
+        sysctl_int(&volume).unwrap_or_else(|e| panic!("{}: {}", volume, e));
+        SpeakerCtl {
+            volume,
+            cap: format!("hw.{}.amp_gain_max", card.dev),
+        }
+    }
+
+    pub fn get_amp_gain(&mut self, _card: &Card) -> f32 {
+        let cdbv = sysctl_int(&self.cap).unwrap_or_else(|e| panic!("{}: {}", self.cap, e));
+        cdbv as f32 / 100.0
+    }
+
+    pub fn set_lvl(&mut self, _card: &Card, lvl: f32) {
+        sysctl_set_int(&self.volume, level_cdb(lvl))
+            .unwrap_or_else(|e| panic!("{}: {}", self.volume, e));
+    }
+}
+
+/// dB to the driver's cdB: towards more attenuation, as ALSA's
+/// Round::Floor does, and never above 0.
+fn level_cdb(lvl: f32) -> i32 {
+    ((lvl * 100.0).floor() as i32).min(0)
+}
+
+#[cfg(test)]
+mod tests {
+    use super::*;
+    use std::io::Write;
+
+    #[test]
+    fn names() {
+        assert_eq!(node_name("Left Front"), "left_front");
+        assert_eq!(node_name("Right Woofer 2"), "right_woofer_2");
+        assert_eq!(node_name("Mono"), "mono");
+    }
+
+    #[test]
+    fn levels() {
+        assert_eq!(level_cdb(0.0), 0);
+        assert_eq!(level_cdb(0.5), 0);
+        assert_eq!(level_cdb(-0.004), -1);
+        assert_eq!(level_cdb(-7.0), -700);
+        assert_eq!(level_cdb(-12.345), -1235);
+    }
+
+    #[test]
+    fn abi() {
+        /* Measured with the C header on NetBSD 11.0. */
+        assert_eq!(std::mem::size_of::<AudioPrinfo>(), 56);
+        assert_eq!(std::mem::size_of::<AudioInfo>(), 136);
+        assert_eq!(AUDIO_SETINFO, 0xc0884116);
+    }
+
+    #[test]
+    fn whole_frames() {
+        let path = std::env::temp_dir().join(format!("ssd-sense-{}", std::process::id()));
+        {
+            let mut f = File::create(&path).unwrap();
+            /* Two frames of 4 channels, then half a frame. */
+            let samples: [i16; 10] = [1, -2, 3, -4, 5, -6, 7, -32768, 9, 10];
+            for v in samples {
+                f.write_all(&v.to_le_bytes()).unwrap();
+            }
+        }
+        let mut s = Sense {
+            file: File::open(&path).unwrap(),
+            channels: 4,
+            bytes: Vec::new(),
+        };
+        let mut buf = [0i16; 8];
+        let n = s.read(&mut buf).ok().unwrap();
+        assert_eq!(n, 2);
+        assert_eq!(buf, [1, -2, 3, -4, 5, -6, 7, -32768]);
+        std::fs::remove_file(&path).unwrap();
+    }
+}
