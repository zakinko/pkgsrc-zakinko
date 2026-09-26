$NetBSD$

Do not dereference a NULL xstr.  anthy_xstrcmp is reached from the dictionary
lookup paths with a NULL argument, and crashes there.

Fedora has carried this since 2013 as anthy-fix-segfault.patch, and
anthy-unicode -- the fork that is still maintained -- has the same guard in
src-diclib/xstr.c.  anthy itself has not been released since 2009, so there
is nowhere upstream to send it.

--- src-diclib/xstr.c.orig
+++ src-diclib/xstr.c
@@ -384,6 +384,10 @@
 anthy_xstrcmp(xstr *x1, xstr *x2)
 {
   int i, m;
+  if (!x1)
+    return -1;
+  if (!x2)
+    return 1;
   if (x1->len < x2->len) {
     m = x1->len;
   }else{
