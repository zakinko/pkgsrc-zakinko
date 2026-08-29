$NetBSD$

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

--- src/process.c.orig
+++ src/process.c
@@ -325,7 +325,7 @@
 
 Lisp_Object status_convert ();
 
-update_status (p)
+int update_status (p)
      struct Lisp_Process *p;
 {
   union { int i; WAITTYPE wt; } u;
@@ -438,7 +438,7 @@
 allocate_pty ()
 {
   struct stat stb;
-  register c, i;
+  register int c, i;
   int fd;
 
   /* Some systems name their pseudoterminals so that there are gaps in
@@ -572,7 +572,7 @@
   return val;
 }
 
-remove_process (proc)
+int remove_process (proc)
      register Lisp_Object proc;
 {
   register Lisp_Object pair;
@@ -1249,7 +1249,7 @@
 #endif
 
 #ifndef VMS /* VMS version of this function is in vmsproc.c.  */
-create_process (process, new_argv, current_dir)
+int create_process (process, new_argv, current_dir)
      Lisp_Object process;
      char **new_argv;
      Lisp_Object current_dir;
@@ -1790,7 +1790,7 @@
 /* end of patch */
 #endif	/* HAVE_SOCKETS */
 
-deactivate_process (proc)
+int deactivate_process (proc)
      Lisp_Object proc;
 {
   register int inchannel, outchannel;
@@ -1838,7 +1838,7 @@
    with subprocess.  This is used in a newly-forked subprocess
    to get rid of irrelevant descriptors.  */
 
-close_process_descs ()
+int close_process_descs ()
 {
   int i;
   for (i = 0; i < MAXDESC; i++)
@@ -1965,7 +1965,7 @@
      before the timeout elapsed.
    Otherwise, return true iff we received input from any process.  */
 
-wait_reading_process_input (time_limit, microsecs, read_kbd, do_display)
+int wait_reading_process_input (time_limit, microsecs, read_kbd, do_display)
      int time_limit, microsecs;
      Lisp_Object read_kbd;
      int do_display;
@@ -2317,7 +2317,7 @@
    If you want to read all available subprocess output,
    you must call it repeatedly until it returns zero.  */
 
-read_process_output (proc, channel)
+int read_process_output (proc, channel)
      Lisp_Object proc;
      register int channel;
 {
@@ -2541,7 +2541,7 @@
    BUF is the beginning of the data; LEN is the number of characters.
    OBJECT is the Lisp object that the data comes from.  */
 
-send_process (proc, buf, len, object)
+int send_process (proc, buf, len, object)
      Lisp_Object proc;
      char *buf;
      int len;
@@ -3116,7 +3116,7 @@
 /* Kill all processes associated with `buffer'.
  If `buffer' is nil, kill all processes  */
 
-kill_buffer_processes (buffer)
+int kill_buffer_processes (buffer)
      Lisp_Object buffer;
 {
   Lisp_Object tail, proc;
@@ -3348,7 +3348,7 @@
    (either run the sentinel or output a message).
    This is done while Emacs is waiting for keyboard input.  */
 
-status_notify ()
+int status_notify ()
 {
   register Lisp_Object proc, buffer;
   Lisp_Object tail, msg;
@@ -3498,7 +3498,7 @@
 }
 /* end of patch */
 
-init_process ()
+int init_process ()
 {
   register int i;
 
@@ -3534,7 +3534,7 @@
   FD_SET (keyboard_descriptor, &input_wait_mask);
 }
 
-syms_of_process ()
+int syms_of_process ()
 {
 #ifdef HAVE_SOCKETS
   stream_process = intern ("stream");
