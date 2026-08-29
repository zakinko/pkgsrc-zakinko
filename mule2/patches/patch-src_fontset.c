$NetBSD$

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

--- src/fontset.c.orig
+++ src/fontset.c
@@ -27,7 +27,7 @@
 void (*load_font_func)( /* FONT_INFO *fontinfo */);
 char **(*font_list_func)( /* char *name, int *count, int size */);
 
-fs_new_font(requested, lc)
+int fs_new_font(requested, lc)
      char *requested;
      int lc;
 {
@@ -60,7 +60,7 @@
   return (n_fonts++);
 }
 
-fs_query_font(fontname, lc, size)
+int fs_query_font(fontname, lc, size)
      char *fontname;
      int lc, size;
 {
@@ -79,7 +79,7 @@
   return -1;
 }
 
-load_query_font(fontname, lc, size)
+int load_query_font(fontname, lc, size)
      char *fontname;
      int lc, size;
 {
@@ -89,7 +89,7 @@
 }
 
 static
-fs_copy_font(from, to)
+int fs_copy_font(from, to)
      int from, to;
 {
   font_table[to].font = font_table[from].font;
@@ -102,7 +102,7 @@
   font_table[to].relative_compose = font_table[from].relative_compose;
 }  
 
-fs_load_font(fsID, lc, size)
+int fs_load_font(fsID, lc, size)
      int fsID, lc, size;
 {
   int fontID = FS_FONT_ID(fsID, lc);
@@ -162,7 +162,7 @@
   return (font->status == FONT_OPENED ? fontID : -1);
 }
 
-new_fontset(name, fontnames)
+int new_fontset(name, fontnames)
      char *name, **fontnames;
 {
   int i;
@@ -206,7 +206,7 @@
   return n_fontsets++;
 }
 
-query_fontset(name)
+int query_fontset(name)
      char *name;
 {
   int fsID;
@@ -231,7 +231,7 @@
   return (query_fontset (XSTRING (name)->data) >= 0 ? Qt : Qnil);
 }
 
-load_query_fontset(name, fontnames)
+int load_query_fontset(name, fontnames)
      char *name, **fontnames;
 {
   int fsID = query_fontset(name);
@@ -239,7 +239,7 @@
   return (fsID >= 0 ? fsID : new_fontset(name, fontnames));
 }  
 
-find_fontset_from_font(fontname, lc)
+int find_fontset_from_font(fontname, lc)
      char *fontname;
      int lc;
 {
@@ -406,7 +406,7 @@
   return val;
 }
 
-init_fontset()
+int init_fontset()
 {
   int i;
 
@@ -416,7 +416,7 @@
     STRcasetbl[i] = (i >= 'A' && i <= 'Z') ? i + 'a' - 'A' : i;
 }
 
-syms_of_fontset()
+int syms_of_fontset()
 {
   defsubr (&Sfontsetp);
   defsubr (&Snew_fontset);
