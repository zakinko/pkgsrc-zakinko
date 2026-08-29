$NetBSD$

Foundation 1/3 for backporting a race-free temporary file to Mule 2.3.

Give write-region the MUSTBENEW argument that make-temp-file relies on, so a
temporary file can be created atomically with O_EXCL instead of being merely
named by the racy make-temp-name (mktemp(3), fileio.c).  Without an atomic
create every make-temp-name caller has a symlink/predictable-name window.

Ported from GNU Emacs, where this arrived as two commits on the CVS trunk
(hashes from the git conversion):

  de1d0127029260011436d5bfd5114503a69bf612  1998-03-02
      (Fwrite_region): New arg CONFIRM.  (auto_save_1): Pass new arg.
  505ab9bc44237e371309c555e3d5d245252e0964  1999-09-07
      (Qexcl): New variable.  (Fwrite_region): Special handling for
      CONFIRM = `excl'.  (report_file_error): Handle EEXIST specially.

Upstream later renamed CONFIRM to MUSTBENEW (72bba429, 1999-09-09); this
patch uses the final name.  It implements only CONFIRM = `excl', which is
all make-temp-file needs, not the CONFIRM = t "query before overwriting"
value.

Three details are specific to Mule 2.3:

  - Its write-region is 3,5 (it never grew the LOCKNAME argument vanilla
    19.34 has), so MUSTBENEW is the sixth argument here, not the seventh.
    The make-temp-file patch passes `excl' accordingly.

  - The lone internal caller, Fdo_auto_save, is updated to pass the new
    argument (this is upstream's "auto_save_1: Pass new arg").  The two
    calls in callproc.c sit inside #if 0 and are not compiled.

  - The Unix build only pulled in <fcntl.h> under MSDOS and took O_WRONLY /
    O_RDONLY from local fallbacks; the create now needs O_CREAT, O_TRUNC and
    O_EXCL, which have no safe hardcoded value, so the header is included for
    Unix as well.

Write the types this file leaves to the compiler to guess.

C89 let a definition omit the return type, and a declaration omit the type
altogether, and both meant int.  C99 removed that, and gcc 15 builds C23 by
default, so every one of them is now an error:

  error: return type defaults to 'int' [-Wimplicit-int]

The compiler was already treating them as int, so writing int changes
nothing about what is built.  Only what the source says out loud.

--- src/fileio.c.orig
+++ src/fileio.c
@@ -178,6 +178,14 @@
 #endif
 #endif
 
+/* On Unix this file only ever pulled in <fcntl.h> under MSDOS, and got
+   O_WRONLY/O_RDONLY from the fallbacks below.  write-region now needs
+   O_CREAT, O_TRUNC and O_EXCL for the `excl' create, which have no safe
+   hardcoded value, so include the header here too.  */
+#if !defined (MSDOS) && !defined (VMS)
+#include <fcntl.h>
+#endif
+
 #ifndef O_WRONLY
 #define O_WRONLY 1
 #endif
@@ -232,12 +240,13 @@
 static Lisp_Object Vinhibit_file_name_operation;
 
 Lisp_Object Qfile_error, Qfile_already_exists;
+Lisp_Object Qexcl;
 
 Lisp_Object Qfile_name_history;
 
 Lisp_Object Qcar_less_than_car;
 
-report_file_error (string, data)
+int report_file_error (string, data)
      char *string;
      Lisp_Object data;
 {
@@ -255,7 +264,7 @@
 	     Fcons (build_string (string), Fcons (errstring, data)));
 }
 
-close_file_unwind (fd)
+int close_file_unwind (fd)
      Lisp_Object fd;
 {
   close (XFASTINT (fd));
@@ -263,7 +272,7 @@
 
 /* Restore point, having saved it as a marker.  */
 
-restore_point_unwind (location)
+int restore_point_unwind (location)
      Lisp_Object location; 
 {
   SET_PT (marker_position (location));
@@ -580,7 +589,7 @@
  * Value is nonzero if the string output is different from the input.
  */
 
-directory_file_name (src, dst)
+int directory_file_name (src, dst)
      char *src, *dst;
 {
   long slen;
@@ -3152,7 +3161,7 @@
   return Qnil;
 }
 
-DEFUN ("write-region", Fwrite_region, Swrite_region, 3, 5,
+DEFUN ("write-region", Fwrite_region, Swrite_region, 3, 6,
   "r\nFWrite region to file: ",
   "Write current region into specified file.\n\
 When called from a program, takes three arguments:\n\
@@ -3169,9 +3178,12 @@
   that means do not print the \"Wrote file\" message.\n\
 Kludgy feature: if START is a string, then that string is written\n\
 to the file, instead of any buffer contents, and END is ignored.\n\
+The optional sixth argument MUSTBENEW, if it is `excl', means create the\n\
+file only if it does not already exist, signalling `file-already-exists'\n\
+if it does.  This lets `make-temp-file' create a file with no race.\n\
 Code convserion occurs accoding to the value of `output-coding-system'.")
-  (start, end, filename, append, visit)
-     Lisp_Object start, end, filename, append, visit;
+  (start, end, filename, append, visit, mustbenew)
+     Lisp_Object start, end, filename, append, visit, mustbenew;
 {
   register int desc;
   int failure;
@@ -3341,7 +3353,13 @@
 	       O_WRONLY | O_TRUNC | O_CREAT | buffer_file_type, 
 	       S_IREAD | S_IWRITE);
 #else /* not MSDOS nor WIN32 */
-  desc = creat (fn, auto_saving ? auto_save_mode_bits : 0666);
+  /* creat() is open() with O_WRONLY|O_CREAT|O_TRUNC; spell it out so that
+     MUSTBENEW = `excl' can add O_EXCL and refuse to follow a pre-planted
+     name.  This is what lets make-temp-file create atomically.  */
+  desc = open (fn,
+	       O_WRONLY | O_CREAT | O_TRUNC
+	       | (EQ (mustbenew, Qexcl) ? O_EXCL : 0),
+	       auto_saving ? auto_save_mode_bits : 0666);
 #endif /* not MSDOS */
 #endif /* not VMS */
 
@@ -3354,6 +3372,13 @@
       if (!auto_saving) unlock_file (visit_file);
       errno = save_errno;
 #endif /* CLASH_DETECTION */
+      /* With MUSTBENEW = `excl' a pre-existing file is not an error to
+	 report as a generic file-error but the specific condition that
+	 make-temp-file loops on.  */
+      if (EQ (mustbenew, Qexcl) && errno == EEXIST)
+	Fsignal (Qfile_already_exists,
+		 Fcons (build_string ("File already exists"),
+			Fcons (filename, Qnil)));
       report_file_error ("Opening output file", Fcons (filename, Qnil));
     }
 
@@ -3846,7 +3871,7 @@
   return
     Fwrite_region (Qnil, Qnil,
 		   current_buffer->auto_save_file_name,
-		   Qnil, Qlambda);
+		   Qnil, Qlambda, Qnil);
 }
 
 static Lisp_Object
@@ -4302,7 +4327,7 @@
 }
 #endif /* Old version */
 
-syms_of_fileio ()
+int syms_of_fileio ()
 {
   Qexpand_file_name = intern ("expand-file-name");
   Qdirectory_file_name = intern ("directory-file-name");
@@ -4367,6 +4392,8 @@
   staticpro (&Qfile_error);
   Qfile_already_exists = intern("file-already-exists");
   staticpro (&Qfile_already_exists);
+  Qexcl = intern ("excl");
+  staticpro (&Qexcl);
   /* <MULE-COMMENT>
      Delete `buffer-file-type' variable for MSDOS because Mule makes
      LF <-> CRLF conversion accroding to `file-coding-system' variable.
