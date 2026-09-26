$NetBSD$

Declare what this file calls.  The standard functions come through their
headers; reaching them through an implicit declaration is the form C99
removed and clang 16 and gcc 14 reject.

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

--- src/filelock.c.orig
+++ src/filelock.c
@@ -38,6 +38,9 @@
 #include <paths.h>
 #include "buffer.h"
 
+/* Declare the standard functions this file calls. */
+#include <signal.h>
+
 #ifndef MCPATH
 #ifdef SYSV_SYSTEM_DIR
 #include <dirent.h>
@@ -139,7 +142,7 @@
    fill_in_lock_file_name (lock, (file)))
 
 
-fill_in_lock_file_name (lockfile, fn)
+int fill_in_lock_file_name (lockfile, fn)
      register char *lockfile;
      register Lisp_Object fn;
 {
@@ -424,7 +427,7 @@
 
 /* Unlock the file visited in buffer BUFFER.  */
 
-unlock_buffer (buffer)
+int unlock_buffer (buffer)
      struct buffer *buffer;
 {
   if (buffer->save_modified < BUF_MODIFF (buffer) &&
@@ -457,7 +460,7 @@
 
 /* Initialization functions.  */
 
-init_filelock ()
+int init_filelock ()
 {
   lock_path = egetenv ("EMACSLOCKDIR");
   if (! lock_path)
@@ -478,7 +481,7 @@
   strcat (superlock_path, SUPERLOCK_NAME);
 }
 
-syms_of_filelock ()
+int syms_of_filelock ()
 {
   defsubr (&Sunlock_buffer);
   defsubr (&Slock_buffer);
