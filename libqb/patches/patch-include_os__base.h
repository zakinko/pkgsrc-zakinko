$NetBSD$

Use POSIX process-shared semaphores on NetBSD.

NetBSD has no process-shared pthread objects and so does not define
_POSIX_THREAD_PROCESS_SHARED, which is what this file looks at.  libqb
then falls back to SysV semaphores, and NetBSD allows 60 of those
system-wide by default (kern.ipc.semmns): three per shm connection, so
twenty connections use them all and the next fails with ENOSPC.
NetBSD's sem_init() with pshared set does work between processes
mapping the same memory.

--- include/os_base.h.orig
+++ include/os_base.h
@@ -146,6 +146,20 @@
   #endif /* HAVE_SEM_TIMEDWAIT */
 #endif /* posix pshared */
 
+/*
+ * NetBSD has no process-shared pthread objects, so it does not define
+ * _POSIX_THREAD_PROCESS_SHARED, but its unnamed semaphores are: with
+ * pshared set, sem_init() keeps the kernel's ksem id in the sem_t, and
+ * any process mapping it can wait and post while the creating process
+ * lives.  The ringbuffers are created by the server, which outlives its
+ * connections.  Without this the SysV semaphores are used, and NetBSD
+ * allows 60 of them system-wide.
+ */
+#if defined(__NetBSD__) && defined(HAVE_SEM_TIMEDWAIT) && \
+    !defined(HAVE_POSIX_PSHARED_SEMAPHORE)
+#define HAVE_POSIX_PSHARED_SEMAPHORE 1
+#endif /* __NetBSD__ */
+
 #ifdef HAVE_SEMTIMEDOP
 #define HAVE_SYSV_PSHARED_SEMAPHORE 1
 #endif /* HAVE_SEMTIMEDOP */
