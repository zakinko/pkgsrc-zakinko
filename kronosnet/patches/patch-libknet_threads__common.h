$NetBSD$

NetBSD's pthread_setname_np() takes a printf format and one argument.

--- libknet/threads_common.h.orig
+++ libknet/threads_common.h
@@ -15,7 +15,13 @@
 #include <pthread.h>
 
 #ifdef HAVE_PTHREAD_SETNAME_NP
+#ifdef __NetBSD__
+/* NetBSD's takes a printf format and one argument. */
+#define knet_thread_setname(tid, name) \
+	pthread_setname_np((tid), "%s", (void *)(name))
+#else
 #define knet_thread_setname(tid, name) pthread_setname_np((tid), (name))
+#endif
 #else
 #define knet_thread_setname(tid, name) ((void)0)
 #endif
