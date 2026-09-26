$NetBSD$

Treat EOF as the end of a line.  read_record_line stops at a newline, so a
record file whose last line has no trailing newline loses that line.  The
user dictionary is such a file.

Fedora carries this as anthy-fix-eol.patch (2024), and anthy-unicode has the
same change in src-worddic/record.c.  anthy itself has not been released
since 2009, so there is nowhere upstream to send it.

--- src-worddic/record.c.orig
+++ src-worddic/record.c
@@ -1043,7 +1043,7 @@
   if (s) {
     s[len] = '\0';
   }
-  *eol = (c == '\n');
+  *eol = (c == '\n' || c == EOF);
   return s;
 }
 
