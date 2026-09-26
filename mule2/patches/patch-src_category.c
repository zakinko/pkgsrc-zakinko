$NetBSD$

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

--- src/category.c.orig
+++ src/category.c
@@ -92,7 +92,7 @@
 
 struct Lisp_Category temp_category;
 
-init_category(category)
+int init_category(category)
      struct Lisp_Category *category;
 {
   category->data[0] = category->data[1] = category->data[2] = 0;
@@ -108,7 +108,7 @@
   return Fmake_string (size, init);
 }
 
-update_category(src, mask)
+int update_category(src, mask)
      struct Lisp_Category *src;
      Lisp_Object mask;
 {
@@ -272,7 +272,7 @@
 }
 
 /* 93.7.13 by K.Handa */
-check_category(category, mnemonic, not)
+int check_category(category, mnemonic, not)
      struct Lisp_Category *category;
      char mnemonic;
      int not;
@@ -370,7 +370,7 @@
   return &temp_category;
 }
 
-pack_mnemonic_string(category, str)
+int pack_mnemonic_string(category, str)
      struct Lisp_Category *category;
      char *str;
 {
@@ -407,7 +407,7 @@
   return build_string(str);
 }
 
-modify_category_entry(c, maskbit, ctbl, reset)
+int modify_category_entry(c, maskbit, ctbl, reset)
      register unsigned int c, reset, maskbit;
      Lisp_Object ctbl;
 {				/* 93.2.12 by K.Handa */
@@ -460,7 +460,7 @@
 
 /* Dump category table to buffer in human-readable format */
 
-insert_character_description(i)	/* 94.2.23 by K.Handa */
+int insert_character_description(i)	/* 94.2.23 by K.Handa */
      unsigned int i;
 {				/* 93.6.7 by K.Handa */
   unsigned char str[5];		/* 92.7.10 by T.Enami */
@@ -492,7 +492,7 @@
   }
 }
 
-describe_category (ctbl, parent) /* 94.2.23 by K.Handae */
+int describe_category (ctbl, parent) /* 94.2.23 by K.Handae */
      Lisp_Object ctbl;
      int parent;
 {
@@ -542,7 +542,7 @@
   }
 }
 
-describe_mnemonic(description)
+int describe_mnemonic(description)
      Lisp_Object description;
 {
   int i;
@@ -584,7 +584,7 @@
   return Qnil;
 }
 
-init_category_once ()
+int init_category_once ()
 {
   temp_category.size = 12;
   temp_category.data[0] = temp_category.data[1] = temp_category.data[2] = 0;
@@ -594,7 +594,7 @@
   Vstandard_category_table = Fcopy_category_table (Qnil);
 }
 
-syms_of_category ()
+int syms_of_category ()
 {
   Qcategory_table_p = intern ("category-table-p");
   staticpro (&Qcategory_table_p);
