$NetBSD$

Recognize DragonFly BSD.

The alias from Elf64_Auxinfo to Elf64_auxv_t is set up under __FreeBSD__
only, and DragonFly spells the type the same way.

Submitted upstream as abseil/abseil-cpp#2160.

--- third_party/abseil-cpp/absl/debugging/internal/vdso_support.cc.orig
+++ third_party/abseil-cpp/absl/debugging/internal/vdso_support.cc
@@ -55,7 +55,7 @@
 using Elf32_auxv_t = Aux32Info;
 using Elf64_auxv_t = Aux64Info;
 #endif
-#if defined(__FreeBSD__)
+#if defined(__FreeBSD__) || defined(__DragonFly__)
 #if defined(__ELF_WORD_SIZE) && __ELF_WORD_SIZE == 64
 using Elf64_auxv_t = Elf64_Auxinfo;
 #endif
