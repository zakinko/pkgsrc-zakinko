$NetBSD$

Go through a per-system backend instead of ALSA directly.

--- src/main.rs.orig
+++ src/main.rs
@@ -21,6 +21,9 @@
 use log::{debug, info, warn};
 use simple_logger::SimpleLogger;
 
+#[cfg_attr(target_os = "linux", path = "backend_alsa.rs")]
+#[cfg_attr(target_os = "netbsd", path = "backend_netbsd.rs")]
+mod backend;
 mod helpers;
 mod types;
 mod uclamp;
@@ -29,7 +32,7 @@
 
 const UNLOCK_MAGIC: i32 = 0xdec1be15u32 as i32;
 
-const FLAGFILE: &str = "/run/speakersafetyd/speakersafetyd.flag";
+const FLAGFILE: &str = backend::FLAGFILE;
 
 /// Simple program to greet a person
 #[derive(Parser, Debug)]
@@ -49,13 +52,7 @@
 }
 
 fn get_machine() -> String {
-    fs::read_to_string("/proc/device-tree/compatible")
-        .expect("Could not read device tree compatible")
-        .split_once("\0")
-        .expect("Unexpected compatible format")
-        .0
-        .trim_end_matches(|c: char| c.is_ascii_alphabetic())
-        .to_string()
+    backend::get_machine()
 }
 
 fn get_speakers(config: &Ini) -> Vec<String> {
@@ -127,11 +124,6 @@
     config_path.set_extension("conf");
     info!("Config file: {:?}", config_path);
 
-    let maker_titlecase = maker[0..1].to_ascii_uppercase() + &maker[1..];
-
-    let device = format!("hw:{}{}", maker_titlecase, model.to_ascii_uppercase());
-    info!("Device: {}", device);
-
     let mut cfg: Ini = Ini::new_cs();
     cfg.load(config_path).expect("Failed to read config file");
 
@@ -150,7 +142,7 @@
         info!("Found {} speakers", speaker_count);
 
         info!("Opening control device");
-        let ctl: alsa::ctl::Ctl = helpers::open_card(&device);
+        let mut card = backend::Card::open(maker, model);
 
         let flag_path = Path::new(FLAGFILE);
 
@@ -177,7 +169,7 @@
         let mut groups: BTreeMap<usize, SpeakerGroup> = BTreeMap::new();
 
         for i in speaker_names {
-            let speaker: types::Speaker = types::Speaker::new(&globals, &i, &cfg, &ctl, cold_boot);
+            let speaker: types::Speaker = types::Speaker::new(&globals, &i, &cfg, &card, cold_boot);
 
             groups
                 .entry(speaker.group)
@@ -195,31 +187,17 @@
         );
         assert!(2 * speaker_count <= globals.channels);
 
-        let pcm_name = format!("{},{}", device, globals.visense_pcm);
         // Set up PCM to buffer in V/ISENSE
-        let mut pcm: Option<alsa::pcm::PCM> =
-            Some(helpers::open_pcm(&pcm_name, globals.channels.try_into().unwrap(), 0));
-        let mut io = Some(pcm.as_ref().unwrap().io_i16().unwrap());
+        let mut sense = card.open_sense(&globals);
 
-        let mut sample_rate_elem = types::Elem::new(
-            "Speaker Sample Rate".to_string(),
-            &ctl,
-            alsa::ctl::ElemType::Integer,
-        );
-        let mut sample_rate = sample_rate_elem.read_int(&ctl);
+        let mut sample_rate = card.sample_rate();
 
-        let mut unlock_elem = types::Elem::new(
-            "Speaker Volume Unlock".to_string(),
-            &ctl,
-            alsa::ctl::ElemType::Integer,
-        );
+        card.unlock(UNLOCK_MAGIC);
 
-        unlock_elem.write_int(&ctl, UNLOCK_MAGIC);
-
         for (_idx, group) in groups.iter_mut() {
             if cold_boot {
                 // Preset the gains to no reduction on cold boot
-                group.speakers.iter_mut().for_each(|s| s.update(&ctl, 0.0));
+                group.speakers.iter_mut().for_each(|s| s.update(&card, 0.0));
                 group.gain = 0.0;
             } else {
                 // Leave the gains at whatever the kernel limit is, use anything
@@ -240,42 +218,20 @@
                 panic!("SIGQUIT received");
             }
             // Block while we're reading into the buffer
-            let read = io.as_ref().unwrap().readi(&mut buf);
-
-            #[allow(unused_mut)]
-            #[allow(unused_assignments)]
-            let read = match read {
-                Ok(a) => Ok(a),
+            let read = match sense.read(&mut buf) {
+                Ok(a) => a,
                 Err(e) => {
                     if sigquit.load(Ordering::Relaxed) {
                         panic!("SIGQUIT received");
                     }
-                    if e.errno() == libc::ESTRPIPE {
-                        warn!("Suspend detected!");
-                        /*
-                        // Resume handling
-                        loop {
-                            match pcm.resume() {
-                                Ok(_) => break Ok(0),
-                                Err(e) if e.errno() == Errno::EAGAIN => continue,
-                                Err(e) => break Err(e),
-                            }
+                    match e {
+                        backend::ReadError::Retry => continue,
+                        backend::ReadError::Fatal(msg) => {
+                            panic!("V/ISENSE read failed: {}", msg)
                         }
-                        .unwrap();
-                        warn!("Resume successful");
-                        */
-                        // Work around kernel issue: resume sometimes breaks visense
-                        warn!("Reinitializing PCM to work around kernel bug...");
-                        io = None;
-                        pcm = None;
-                        pcm = Some(helpers::open_pcm(&pcm_name, globals.channels.try_into().unwrap(), 0));
-                        io = Some(pcm.as_ref().unwrap().io_i16().unwrap());
-                        continue;
                     }
-                    Err(e)
                 }
-            }
-            .unwrap();
+            };
 
             if read != globals.period {
                 warn!("Expected {} samples, got {}", globals.period, read);
@@ -287,7 +243,7 @@
 
             let buf_read = &buf[0..read * globals.channels];
 
-            let cur_sample_rate = sample_rate_elem.read_int(&ctl);
+            let cur_sample_rate = card.sample_rate();
 
             if cur_sample_rate != 0 && cur_sample_rate != sample_rate {
                 sample_rate = cur_sample_rate;
@@ -328,7 +284,7 @@
                     } else {
                         info!("Speaker group {} gain limited to {:.2} dBFS", idx, gain);
                     }
-                    group.speakers.iter_mut().for_each(|s| s.update(&ctl, gain));
+                    group.speakers.iter_mut().for_each(|s| s.update(&card, gain));
                     group.gain = gain;
                 }
                 if gain != 0. {
@@ -345,7 +301,7 @@
                 once_nominal = true;
             }
 
-            unlock_elem.write_int(&ctl, UNLOCK_MAGIC);
+            card.unlock(UNLOCK_MAGIC);
         }
     });
     if let Err(e) = result {
