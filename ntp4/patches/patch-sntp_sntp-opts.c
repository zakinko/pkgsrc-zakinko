$NetBSD$

* Changes from NetBSD base.
* Let the compiled-in default keys file be overridden from CPPFLAGS so
  it can follow PKG_SYSCONFDIR (PR pkg/47149).  This is a pre-generated
  file (from sntp/sntp-opts.def via AutoGen); patch it directly rather
  than the .def source, which would make the .def newer than the shipped
  generated files and trigger AutoGen regeneration at build time --
  AutoGen is not a build dependency of this package.

  The default is a byte offset into a single concatenated string table,
  so substituting a longer path in place would shift every following
  offset.  Guarding the macro instead leaves the table untouched and
  keeps the substitution a build-time matter, which also keeps it
  correct for any PKG_SYSCONFDIR rather than one hardcoded prefix.

--- sntp/sntp-opts.c.orig	2020-06-23 16:03:47.000000000 +0000
+++ sntp/sntp-opts.c
@@ -302,7 +302,9 @@
 /** Name string for the keyfile option */
 #define KEYFILE_name      (sntp_opt_strs+1593)
 /** The compiled in default value for the keyfile option argument */
+#ifndef KEYFILE_DFT_ARG
 #define KEYFILE_DFT_ARG   (sntp_opt_strs+1601)
+#endif
 /** Compiled in flag settings for the keyfile option */
 #define KEYFILE_FLAGS     (OPTST_DISABLED \
         | OPTST_SET_ARGTYPE(OPARG_TYPE_FILE))
