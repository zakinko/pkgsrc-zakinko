$NetBSD$

Terminate execlp's argument list with (char *)NULL, not 0.

execl and friends read the terminator as a char *.  On an LP64 machine 0 is
an int, so only 32 bits get pushed and the callee keeps walking into
whatever was left on the stack.  This is the same mistake as the XtVa*
calls fixed elsewhere in this tree, in a place that has nothing to do with
X: sys_subshell() spawning the user's shell.

The cast is spelled (char *)0 rather than NULL because this file undefines
NULL at line 27 and never pulls in a header that puts it back.

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

Keep the added headers out of the Makefile-generating pass.

config.h is read twice: once by the compiler, and once by the cpp run that
turns Makefile.in into Makefile.  The second one is traditional cpp and
cannot read a modern glibc header at all, so the includes have to sit
inside #ifndef NOT_C_CODE, the way s/irix4-0.h does it.

--- src/sysdep.c.orig
+++ src/sysdep.c
@@ -245,7 +245,7 @@
 /* Arrange for character C to be read as the next input from
    the terminal.  */
 
-stuff_char (c)
+int stuff_char (c)
      char c;
 {
 /* Should perhaps error if in batch mode */
@@ -258,7 +258,7 @@
 
 #endif /* SIGTSTP */
 
-init_baud_rate ()
+int init_baud_rate ()
 {
   if (noninteractive)
     ospeed = 0;
@@ -316,7 +316,7 @@
 }
 
 /*ARGSUSED*/
-set_exclusive_use (fd)
+int set_exclusive_use (fd)
      int fd;
 {
 #ifdef FIOCLEX
@@ -349,7 +349,7 @@
 /* Wait for subprocess with process id `pid' to terminate and
    make sure it will get eliminated (not remain forever as a zombie) */
 
-wait_for_termination (pid)
+int wait_for_termination (pid)
      int pid;
 {
   while (1)
@@ -437,7 +437,7 @@
  *      (may flush input as well; it does not matter the way we use it)
  */
  
-flush_pending_output (channel)
+int flush_pending_output (channel)
      int channel;
 {
 #ifdef HAVE_TERMIOS
@@ -464,7 +464,7 @@
     It should not echo or do line-editing, since that is done
     in Emacs.  No padding needed for insertion into an Emacs buffer.  */
 
-child_setup_tty (out)
+int child_setup_tty (out)
      int out;
 {
 #ifndef MSDOS
@@ -562,7 +562,7 @@
 #endif /* subprocesses */
 
 /*ARGSUSED*/
-setpgrp_of_tty (pid)
+int setpgrp_of_tty (pid)
      int pid;
 {
   EMACS_SET_TTY_PGRP (input_fd, &pid);
@@ -577,7 +577,7 @@
 
 /* Suspend the Emacs process; give terminal to its superior.  */
 
-sys_suspend ()
+int sys_suspend ()
 {
 #ifdef VMS
   /* "Foster" parentage allows emacs to return to a subprocess that attached
@@ -646,7 +646,7 @@
 
 /* Fork a subshell.  */
 
-sys_subshell ()
+int sys_subshell ()
 {
 #ifndef VMS
 #ifdef MSDOS	/* Demacs 1.1.2 91/10/20 Manabu Higashida */
@@ -726,7 +726,7 @@
       if (st)
         report_file_error ("Can't execute subshell", Fcons (build_string (sh), Qnil));
 #else /* not MSDOS */
-      execlp (sh, sh, 0);
+      execlp (sh, sh, (char *)0);
       write (1, "Can't execute subshell", 22);
       _exit (1);
 #endif /* not MSDOS */
@@ -739,7 +739,7 @@
 #endif /* !VMS */
 }
 
-save_signal_handlers (saved_handlers)
+int save_signal_handlers (saved_handlers)
      struct save_signal *saved_handlers;
 {
   while (saved_handlers->code)
@@ -750,7 +750,7 @@
     }
 }
 
-restore_signal_handlers (saved_handlers)
+int restore_signal_handlers (saved_handlers)
      struct save_signal *saved_handlers;
 {
   while (saved_handlers->code)
@@ -764,7 +764,7 @@
 
 int old_fcntl_flags;
 
-init_sigio ()
+int init_sigio ()
 {
 #ifdef FASYNC
   old_fcntl_flags = fcntl (input_fd, F_GETFL, 0) & ~FASYNC;
@@ -772,14 +772,14 @@
   request_sigio ();
 }
 
-reset_sigio ()
+int reset_sigio ()
 {
   unrequest_sigio ();
 }
 
 #ifdef FASYNC		/* F_SETFL does not imply existence of FASYNC */
 
-request_sigio ()
+int request_sigio ()
 {
 #ifdef SIGWINCH
   sigunblock (sigmask (SIGWINCH));
@@ -789,7 +789,7 @@
   interrupts_deferred = 0;
 }
 
-unrequest_sigio ()
+int unrequest_sigio ()
 {
 #ifdef SIGWINCH
   sigblock (sigmask (SIGWINCH));
@@ -1409,7 +1409,7 @@
 /* Return nonzero if safe to use tabs in output.
    At the time this is called, init_sys_modes has not been done yet.  */
    
-tabs_safe_p ()
+int tabs_safe_p ()
 {
   struct emacs_tty tty;
 
@@ -1421,7 +1421,7 @@
    Store number of lines into *HEIGHTP and width into *WIDTHP.
    We store 0 if there's no valid information.  */
 
-get_frame_size (widthp, heightp)
+int get_frame_size (widthp, heightp)
      int *widthp, *heightp;
 {
 
@@ -1594,7 +1594,7 @@
 
 /* Set up the proper status flags for use of a pty.  */
 
-setup_pty (fd)
+int setup_pty (fd)
      int fd;
 {
   /* I'm told that TOICREMOTE does not mean control chars
@@ -2465,6 +2465,7 @@
 sigset_t old_mask, empty_mask, full_mask, temp_mask;
 static struct sigaction new_action, old_action;
 
+void
 init_signals ()
 {
   sigemptyset (&empty_mask);
@@ -3160,6 +3161,7 @@
  *	This function will go away as soon as all the stubs fixed. (fnf)
  */
 
+void
 croak (badfunc)
      char *badfunc;
 {
