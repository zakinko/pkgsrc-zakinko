$NetBSD$

Three things this system needs that s/freebsd.h has not caught up with.  The
s/ file is where emacs 20 records what a system does differently, so they sit
in one patch, but they are unrelated to each other.

1. No <utmp.h>.  FreeBSD replaced utmp with utmpx and dropped the header; 14.4
   ships utmpx.h, no utmp.h, and not even a utmp(5) page.  filelock.c includes
   it outside any guard and the build stops there.  NO_UTMP_H turns that
   include off; see patch-src_filelock.c for why nothing in that file needs it.

2. No relocating allocator.  ralloc.c takes over __morecore when REL_ALLOC is
   on, and its obtain() insists each new chunk start exactly where the last one
   ended.  Here that left temacs with a break 4.35G above its data segment, so
   unexelf.c wrote

	p_filesz = new_bss_addr - p_vaddr		(unexelf.c:904)

   as 0x1033820c0 into a 55M file, and the kernel refused the image: every run
   of the dumped emacs died at execve with SIGABRT.  s/gnu-linux.h turns
   REL_ALLOC off for the same kind of reason.  Not ASLR -- the gap between end
   and the initial break measures 0 here, with or without proccontrol -m aslr.

3. Link with cc, not ld.  s/netbsd.h defines ORDINARY_LINK in its own __ELF__
   branch and this file does not, so src/Makefile.in sets LD=ld and passes it
   the START_FILES and LIB_STANDARD written out here.  A bare ld has no default
   library path, and lld stops with

	ld: error: unable to find library -lutil
	ld: error: unable to find library -ltermcap
	ld: error: unable to find library -lm
	ld: error: unable to find library -lgcc
	ld: error: unable to find library -lc

   START_FILES and LIB_STANDARD are removed along with it.  Makefile.in still
   honours START_FILES under ORDINARY_LINK -- "config.h might want to force
   START_FILES anyway" -- and handing crt1.o and its friends to cc, which
   already supplies them, would link them twice.

--- src/s/freebsd.h.orig
+++ src/s/freebsd.h
@@ -56,9 +56,10 @@
 #ifdef __ELF__
 
 #define LD_SWITCH_SYSTEM
-#define START_FILES pre-crt0.o /usr/lib/crt1.o /usr/lib/crti.o /usr/lib/crtbegin.o
 #define UNEXEC unexelf.o
-#define LIB_STANDARD -lgcc -lc -lgcc /usr/lib/crtend.o /usr/lib/crtn.o
+/* Link with the compiler driver, the way s/netbsd.h does for its own ELF
+   case.  See the head of this patch.  */
+#define ORDINARY_LINK
 #undef LIB_GCC
 #define LIB_GCC
 
@@ -103,6 +104,14 @@
 #define TABDLY OXTABS
 #define TAB3 OXTABS
 
+/* FreeBSD replaced utmp with utmpx and no longer ships <utmp.h>, which
+   filelock.c includes.  Nothing there needs it -- see
+   patch-src_filelock.c.  */
+#define NO_UTMP_H
+
+/* Keep ralloc.c out of the malloc path; see the head of this patch.  */
+#undef REL_ALLOC
+
 /* this silences a few compilation warnings */
 #undef BSD_SYSTEM
 #if __FreeBSD__ == 1
