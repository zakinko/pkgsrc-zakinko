$NetBSD$

Print elapsed time with a format that matches time_t.  See
patch-src_augtool.c.

--- examples/dump.c.orig
+++ examples/dump.c
@@ -119,7 +119,7 @@
                              const struct timeval *stop) {
     time_t elapsed = (stop->tv_sec - start->tv_sec)*1000
                    + (stop->tv_usec - start->tv_usec)/1000;
-    fprintf(stderr, "time: %ld ms\n", elapsed);
+    fprintf(stderr, "time: %lld ms\n", (long long) elapsed);
 }
 
 int main(int argc, char **argv) {
