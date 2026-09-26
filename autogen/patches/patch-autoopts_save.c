$NetBSD$

Check whether text_mmap() failed before scanning what it returned.

	CVE-2025-8746

remove_settings() passes the result of text_mmap() straight to
strstr(), so a failed mapping walks from MAP_FAILED, that is (void *)-1.
It is reachable through --load-opts, and a proof of concept is public.
Every other caller in the tree already tests it -- configfile.c lines
85 and 379, agen5/tpLoad.c:465, agen5/expFormat.c:901 -- so this is a
single missed check rather than a missing idiom, and the macro is
already defined in autoopts/options.h.

Fixed the same way in openSUSE (bsc#1247921), which is so far the only
other tree carrying it.  Reported upstream with a patch as Savannah
sr #111319 on 2025-09-23; the maintainer took it on 2025-10-02 and it
has not moved since.

	https://savannah.gnu.org/support/index.php?111319

--- autoopts/save.c.orig	2017-09-11 00:00:00.000000000 +0000
+++ autoopts/save.c
@@ -492,7 +492,11 @@
     size_t const name_len = strlen(opts->pzProgName);
     tmap_info_t  map_info;
     char *       text = text_mmap(fname, PROT_READ|PROT_WRITE, MAP_PRIVATE, &map_info);
-    char *       scan = text;
+    char *       scan;
+
+    if (TEXT_MMAP_FAILED_ADDR(text))
+        return;
+    scan = text;
 
     for (;;) {
         char * next = scan = strstr(scan, zCfgProg);
