$NetBSD$

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

--- src/keyboard.c.orig
+++ src/keyboard.c
@@ -569,7 +569,7 @@
    so that it serves as a prompt for the next character.
    Also start echoing.  */
 
-echo_prompt (str)
+int echo_prompt (str)
      char *str;
 {
   int len = strlen (str);
@@ -657,7 +657,7 @@
 /* Display the current echo string, and begin echoing if not already
    doing so.  */
 
-echo ()
+int echo ()
 {
   if (!immediate_echo)
     {
@@ -685,7 +685,7 @@
 
 /* Turn off echoing, for the start of a new command.  */
 
-cancel_echoing ()
+int cancel_echoing ()
 {
   immediate_echo = 0;
   echoptr = echobuf;
@@ -757,14 +757,14 @@
 
 /* When an auto-save happens, record the "time", and don't do again soon.  */
 
-record_auto_save ()
+int record_auto_save ()
 {
   last_auto_save = num_nonmacro_input_chars;
 }
 
 /* Make an auto save happen as soon as possible at command level.  */
 
-force_auto_save_soon ()
+int force_auto_save_soon ()
 {
   last_auto_save = - auto_save_interval - 1;
 
@@ -1379,7 +1379,7 @@
 /* Begin signals to poll for input, if they are appropriate.
    This function is called unconditionally from various places.  */
 
-start_polling ()
+int start_polling ()
 {
 #ifdef POLL_FOR_INPUT
   if (read_socket_hook && !interrupt_input)
@@ -1409,7 +1409,7 @@
 
 /* Turn off polling.  */
 
-stop_polling ()
+int stop_polling ()
 {
 #ifdef POLL_FOR_INPUT
   if (read_socket_hook && !interrupt_input)
@@ -1448,7 +1448,7 @@
 /* Bind polling_period to a value at least N.
    But don't decrease it.  */
 
-bind_polling_period (n)
+int bind_polling_period (n)
      int n;
 {
 #ifdef POLL_FOR_INPUT
@@ -1929,13 +1929,13 @@
    in case get_char is called recursively.
    See read_process_output.  */
 
-save_getcjmp (temp)
+int save_getcjmp (temp)
      jmp_buf temp;
 {
   bcopy (getcjmp, temp, sizeof getcjmp);
 }
 
-restore_getcjmp (temp)
+int restore_getcjmp (temp)
      jmp_buf temp;
 {
   bcopy (temp, getcjmp, sizeof getcjmp);
@@ -5504,7 +5504,7 @@
 }
 
 
-detect_input_pending ()
+int detect_input_pending ()
 {
   if (!input_pending)
     get_input_pending (&input_pending);
@@ -5515,7 +5515,7 @@
 /* This is called in some cases before a possible quit.
    It cases the next call to detect_input_pending to recompute input_pending.
    So calling this function unnecessarily can't do any harm.  */
-clear_input_pending ()
+int clear_input_pending ()
 {
   input_pending = 0;
 }
@@ -5678,7 +5678,7 @@
 /* If STUFFSTRING is a string, stuff its contents as pending terminal input.
    Then in any case stuff anything Emacs has read ahead and not used.  */
 
-stuff_buffered_input (stuffstring)
+int stuff_buffered_input (stuffstring)
      Lisp_Object stuffstring;
 {
   register unsigned char *p;
@@ -5714,7 +5714,7 @@
 #endif /* BSD and not BSD4_1 */
 }
 
-set_waiting_for_input (time_to_clear)
+int set_waiting_for_input (time_to_clear)
      EMACS_TIME *time_to_clear;
 {
   input_available_clear_time = time_to_clear;
@@ -5728,7 +5728,7 @@
     quit_throw_to_read_char ();
 }
 
-clear_waiting_for_input ()
+int clear_waiting_for_input ()
 {
   /* Tell interrupt_signal not to throw back to read_char,  */
   waiting_for_input = 0;
@@ -5857,7 +5857,7 @@
 
 /* Handle a C-g by making read_char return C-g.  */
 
-quit_throw_to_read_char ()
+int quit_throw_to_read_char ()
 {
   quit_error_check ();
   sigfree ();
@@ -5968,7 +5968,7 @@
 }
 
 
-init_keyboard ()
+int init_keyboard ()
 {
   /* This is correct before outermost invocation of the editor loop */
   command_loop_level = -1;
@@ -6054,7 +6054,7 @@
   &Qswitch_frame,	"switch-frame",		&Qswitch_frame,
 };
 
-syms_of_keyboard ()
+int syms_of_keyboard ()
 {
   Qdisabled_command_hook = intern ("disabled-command-hook");
   staticpro (&Qdisabled_command_hook);
@@ -6427,7 +6427,7 @@
   Vdeferred_action_function = Qnil;
 }
 
-keys_of_keyboard ()
+int keys_of_keyboard ()
 {
   initial_define_key (global_map, Ctl ('Z'), "suspend-emacs");
   initial_define_key (control_x_map, Ctl ('Z'), "suspend-emacs");
