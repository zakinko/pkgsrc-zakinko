$NetBSD$

--- src/main/tools/process-tools-darwin.cc.orig
+++ src/main/tools/process-tools-darwin.cc
@@ -24,6 +24,12 @@
 #include "src/main/tools/logging.h"
 #include "src/main/tools/process-tools.h"
 
+#if defined(__NetBSD__)
+// NetBSD declares struct kinfo_proc for the kernel only.  Userland asks
+// KERN_PROC2 instead and gets struct kinfo_proc2, whose pid lives in p_pid.
+#define kinfo_proc kinfo_proc2
+#endif
+
 namespace {
 
 int WaitForProcessToTerminate(uintptr_t ident) {
@@ -72,7 +78,15 @@
 }
 
 int WaitForProcessGroupToTerminate(pid_t pgid) {
+#if defined(__NetBSD__)
+  // KERN_PROC2 takes the record size and the record count in the mib itself.
+  int name[] = {CTL_KERN, KERN_PROC2, KERN_PROC_PGRP, pgid,
+                static_cast<int>(sizeof(struct kinfo_proc)), 0};
+  const unsigned int name_len = 6;
+#else
   int name[] = {CTL_KERN, KERN_PROC, KERN_PROC_PGRP, pgid};
+  const unsigned int name_len = 4;
+#endif
 
   for (;;) {
     // Query the list of processes in the group by using sysctl(3).
@@ -84,11 +98,14 @@
     size_t nprocs = 0;
     do {
       size_t len;
-      if (sysctl(name, 4, 0, &len, nullptr, 0) == -1) {
+      if (sysctl(name, name_len, 0, &len, nullptr, 0) == -1) {
         return -1;
       }
+#if defined(__NetBSD__)
+      name[5] = len / sizeof(struct kinfo_proc);
+#endif
       procs = (struct kinfo_proc *)malloc(len);
-      if (sysctl(name, 4, procs, &len, nullptr, 0) == -1) {
+      if (sysctl(name, name_len, procs, &len, nullptr, 0) == -1) {
         if (errno != ENOMEM) {
           DIE("Unexpected error code %d", errno);
         }
@@ -105,7 +122,7 @@
     if (nprocs == 1) {
       // Found only one process, which must be the leader because we have
       // purposely expect it as a zombie with WaitForProcess.
-#if defined(__OpenBSD__)
+#if defined(__OpenBSD__) || defined(__NetBSD__)
       if (procs->p_pid != pgid) {
 #else
       if (procs->kp_proc.p_pid != pgid) {
