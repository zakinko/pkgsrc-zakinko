$NetBSD$

NetBSD utilization bounds through _sched_setutil(2).

--- src/uclamp.rs.orig
+++ src/uclamp.rs
@@ -1,5 +1,6 @@
 use log::{info, warn};
 
+#[cfg(target_os = "linux")]
 #[derive(Default)]
 #[repr(C)]
 struct SchedAttr {
@@ -15,6 +16,7 @@
     sched_util_max: u32,
 }
 
+#[cfg(target_os = "linux")]
 pub fn set_uclamp(uclamp_min: u32, uclamp_max: u32) {
     let mut attr: SchedAttr = Default::default();
     let pid = unsafe { libc::getpid() };
@@ -48,3 +50,38 @@
 
     info!("Set task uclamp to {}:{}", uclamp_min, uclamp_max);
 }
+
+/*
+ * NetBSD: _sched_setutil(2), syscall 507, with bounds on the same 0..1024
+ * scale.  Called by number: libc has sched_setutil_np() only from the
+ * release that added it, and on an older kernel this fails with ENOSYS,
+ * which is only logged -- the bounds are a hint, not a safety measure.
+ */
+#[cfg(target_os = "netbsd")]
+#[repr(C)]
+struct SchedUtil {
+    su_min: libc::c_int,
+    su_max: libc::c_int,
+    su_spare: [libc::c_int; 6],
+}
+
+#[cfg(target_os = "netbsd")]
+pub fn set_uclamp(uclamp_min: u32, uclamp_max: u32) {
+    const SYS_SCHED_SETUTIL: libc::c_int = 507;
+    let su = SchedUtil {
+        su_min: uclamp_min as libc::c_int,
+        su_max: uclamp_max as libc::c_int,
+        su_spare: [0; 6],
+    };
+
+    /* pid 0 and lid 0: every LWP of this process. */
+    if unsafe { libc::syscall(SYS_SCHED_SETUTIL, 0 as libc::pid_t, 0 as libc::c_int, &su) } != 0 {
+        warn!(
+            "Failed to set utilization bounds: {}",
+            std::io::Error::last_os_error()
+        );
+        return;
+    }
+
+    info!("Set utilization bounds to {}:{}", uclamp_min, uclamp_max);
+}
