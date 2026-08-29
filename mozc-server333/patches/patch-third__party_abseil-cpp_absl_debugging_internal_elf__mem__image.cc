$NetBSD$

Key the Versym access on the header rather than on the OS.

NetBSD changed Elf_Versym from a one member struct to an Elf_Half, and
marked the change by giving _SYS_EXEC_ELF_H_ the value 2:

  NetBSD 11.0     #define _SYS_EXEC_ELF_H_
                  typedef struct { Elf32_Half vs_vers; } Elf32_Versym;
  NetBSD 11.99.8  #define _SYS_EXEC_ELF_H_  2
                  typedef Elf32_Half Elf32_Versym;

The bundled abseil branches on __NetBSD__ alone, so on -current it takes
the struct path against an integer:

  error: request for member 'vs_vers' in something not a structure or
  union

The #else branch is already what -current wants.  devel/abseil carries
the same fix, keyed the same way.

--- third_party/abseil-cpp/absl/debugging/internal/elf_mem_image.cc.orig	2026-01-16 05:56:23.000000000 +0000
+++ third_party/abseil-cpp/absl/debugging/internal/elf_mem_image.cc
@@ -377,7 +377,7 @@ void ElfMemImage::SymbolIterator::Update
   const ElfW(Versym) *version_symbol = image->GetVersym(index_);
   ABSL_RAW_CHECK(symbol && version_symbol, "");
   const char *const symbol_name = image->GetDynstr(symbol->st_name);
-#if defined(__NetBSD__)
+#if defined(__NetBSD__) && ((_SYS_EXEC_ELF_H_ + 0) < 2)
   const int version_index = version_symbol->vs_vers & VERSYM_VERSION;
 #else
   const ElfW(Versym) version_index = version_symbol[0] & VERSYM_VERSION;
