$NetBSD$

Let <sys/exec_elf.h> pick ELFSIZE on NetBSD.

The NetBSD branch decides ELFSIZE from the architecture macros and only
knows about __alpha__ and __sparc_v9__, so on every other LP64 NetBSD --
amd64 among them -- it settles on 32 and then reads a 64-bit temacs through
32-bit Elf structures.  Every offset comes out wrong, and the dump stops at

  emacs: Couldn't find segment next to .bss in .../src/temacs

<sys/exec_elf.h> already defines ELFSIZE for the architecture it is built
for, so include it first and only fall back to the guess when it did not.
Emacs 24 fixed the same thing by adding `|| defined _LP64' to the list;
this is the form editors/emacs22 already carries in pkgsrc.

--- src/unexelf.c.orig
+++ src/unexelf.c
@@ -485,12 +485,16 @@
 /*
  * NetBSD does not have normal-looking user-land ELF support.
  */
+# include <sys/exec_elf.h>
 # if defined __alpha__ || defined __sparc_v9__
-#  define ELFSIZE	64
+#  ifndef ELFSIZE
+#   define ELFSIZE	64
+#  endif
 # else
-#  define ELFSIZE	32
+#  ifndef ELFSIZE
+#   define ELFSIZE	32
+#  endif
 # endif
-# include <sys/exec_elf.h>
 
 # ifndef PT_LOAD
 #  define PT_LOAD	Elf_pt_load
