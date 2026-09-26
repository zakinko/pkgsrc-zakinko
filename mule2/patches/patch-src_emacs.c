$NetBSD$

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
@@ -389,10 +389,13 @@
    (We don't have any real constructors or destructors.)  */
 #ifdef __GNUC__
 #ifndef GCC_CTORS_IN_LIBC
+int
 __do_global_ctors ()
 {}
+int
 __do_global_ctors_aux ()
 {}
+int
 __do_global_dtors ()
 {}
 /* Linux has a bug in its library; avoid an error.  */
@@ -401,6 +404,7 @@
 #endif
 char * __DTOR_LIST__[2] = { (char *) (-1), 0 };
 #endif /* GCC_CTORS_IN_LIBC */
+int
 __main ()
 {}
 #endif /* __GNUC__ */
@@ -415,7 +419,7 @@
 #include <sys/param.h>
 
 /* ARGSUSED */
-main (argc, argv, envp)
+int main (argc, argv, envp)
      int argc;
      char **argv;
      char **envp;
@@ -423,7 +427,7 @@
   char stack_bottom_variable;
   int skip_args = 0;
 #if !(defined(BSD) && BSD >= 199306)
-  extern sys_nerr;
+  extern int sys_nerr;
 #endif
 
 /* Map in shared memory, if we are using that.  */
@@ -1176,7 +1180,7 @@
   return Fnreverse (lpath);
 }
 
-syms_of_emacs ()
+int syms_of_emacs ()
 {
 #ifndef CANNOT_DUMP
 #ifdef HAVE_SHM
