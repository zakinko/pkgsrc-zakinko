$NetBSD$

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

--- src/emacs.c.orig
+++ src/emacs.c
@@ -247,7 +247,7 @@
 /* Code for dealing with Lisp access to the Unix command line */
 
 static
-init_cmdargs (argc, argv, skip_args)
+int init_cmdargs (argc, argv, skip_args)
      int argc;
      char **argv;
      int skip_args;
@@ -415,7 +415,7 @@
 #include <sys/param.h>
 
 /* ARGSUSED */
-main (argc, argv, envp)
+int main (argc, argv, envp)
      int argc;
      char **argv;
      char **envp;
@@ -1176,7 +1176,7 @@
   return Fnreverse (lpath);
 }
 
-syms_of_emacs ()
+int syms_of_emacs ()
 {
 #ifndef CANNOT_DUMP
 #ifdef HAVE_SHM
