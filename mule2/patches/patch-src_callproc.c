$NetBSD$

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

--- src/callproc.c.orig
+++ src/callproc.c
@@ -839,7 +839,7 @@
 
 #else /* not WIN32 */
 
-child_setup (in, out, err, new_argv, set_pgrp, current_dir)
+int child_setup (in, out, err, new_argv, set_pgrp, current_dir)
      int in, out, err;
      register char **new_argv;
      int set_pgrp;
@@ -1100,7 +1100,7 @@
 
 /* This is run before init_cmdargs.  */
   
-init_callproc_1 ()
+int init_callproc_1 ()
 {
   char *data_dir = egetenv ("EMACSDATA");
   char *doc_dir = egetenv ("EMACSDOC");
@@ -1121,7 +1121,7 @@
 
 /* This is run after init_cmdargs, so that Vinvocation_directory is valid.  */
 
-init_callproc ()
+int init_callproc ()
 {
   char *data_dir = egetenv ("EMACSDATA");
     
@@ -1218,7 +1218,7 @@
 #endif /* not VMS */
 }
 
-set_process_environment ()
+int set_process_environment ()
 {
   register char **envp;
 
@@ -1231,7 +1231,7 @@
 				    Vprocess_environment);
 }
 
-syms_of_callproc ()
+int syms_of_callproc ()
 {
 /* <MULE-COMMENT>
    Delete `buffer-file-type' and `binary-process-*' variables for
