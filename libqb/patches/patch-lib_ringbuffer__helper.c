$NetBSD$

Report a vanished process-shared semaphore as a disconnect on NetBSD.

NetBSD keeps a pshared semaphore as a descriptor of the process that
called sem_init(), and destroys it when that process exits (see
ksem_close_fop() in sys/kern/uipc_sem.c); everyone else then gets
EINVAL.  The server creates every ringbuffer of a connection, so a
client seeing that has lost its server.  Return ENOTCONN, as the SysV
path does with EIDRM, so the client notices the disconnect.

--- lib/ringbuffer_helper.c.orig
+++ lib/ringbuffer_helper.c
@@ -21,6 +21,13 @@
 #include "ringbuffer_int.h"
 #include <qb/qbdefs.h>
 
+/*
+ * A process-shared semaphore on NetBSD lives as a descriptor of the
+ * process that called sem_init(), and dies with it: anyone else using it
+ * afterwards gets EINVAL.  The server creates every ringbuffer of a
+ * connection, so for a client that means the server has gone.  Say so,
+ * as a disconnect, rather than as a bad argument.
+ */
 static int32_t
 my_posix_sem_timedwait(void * instance, int32_t ms_timeout)
 {
@@ -52,6 +59,14 @@
 		case ETIMEDOUT:
 			res = -errno;
 			break;
+#ifdef __NetBSD__
+		case EINVAL:
+			if (rb->flags & QB_RB_FLAG_SHARED_PROCESS) {
+				res = -ENOTCONN;
+				break;
+			}
+			/* FALLTHROUGH */
+#endif /* __NetBSD__ */
 		default:
 			res = -errno;
 			qb_util_perror(LOG_ERR, "error waiting for semaphore");
@@ -66,6 +81,12 @@
 {
 	struct qb_ringbuffer_s *rb = (struct qb_ringbuffer_s *)instance;
 	if (rpl_sem_post(&rb->shared_hdr->posix_sem) < 0) {
+#ifdef __NetBSD__
+		if (errno == EINVAL &&
+		    (rb->flags & QB_RB_FLAG_SHARED_PROCESS)) {
+			return -ENOTCONN;
+		}
+#endif /* __NetBSD__ */
 		return -errno;
 	} else {
 		return 0;
