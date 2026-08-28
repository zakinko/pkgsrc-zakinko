$NetBSD$

Three fixes to the dump-file loading path, from the emacs-28 branch, for the
28.3 release that was never made.

	7ff5207624  Avoid assertion violation in 'xpalloc'
	e5a49f44ff  * src/emacs.c (load_pdump): Fix use of xpalloc.
	a78af3018e  * src/emacs.c (load_pdump): Propery handle case when
	            executable wasn't found.

The last one matters here beyond tidiness: without it, an Emacs that cannot
find its own executable walks off the end of a buffer while composing the
path of the .pdmp file.

--- src/emacs.c.orig
+++ src/emacs.c
@@ -867,14 +867,17 @@
     }
 
   /* Where's our executable?  */
-  ptrdiff_t bufsize, exec_bufsize;
-  emacs_executable = load_pdump_find_executable (argv[0], &bufsize);
-  exec_bufsize = bufsize;
+  ptrdiff_t exec_bufsize, bufsize, needed;
+  emacs_executable = load_pdump_find_executable (argv[0], &exec_bufsize);
 
   /* If we couldn't find our executable, go straight to looking for
      the dump in the hardcoded location.  */
   if (!(emacs_executable && *emacs_executable))
-    goto hardcoded;
+    {
+      bufsize = 0;
+      dump_file = NULL;
+      goto hardcoded;
+    }
 
   if (dump_file)
     {
@@ -902,8 +905,8 @@
 		      strip_suffix_length))
 	exenamelen = prefix_length;
     }
-  ptrdiff_t needed = exenamelen + strlen (suffix) + 1;
-  dump_file = xpalloc (NULL, &bufsize, needed - bufsize, -1, 1);
+  bufsize = exenamelen + strlen (suffix) + 1;
+  dump_file = xpalloc (NULL, &bufsize, 1, -1, 1);
   memcpy (dump_file, emacs_executable, exenamelen);
   strcpy (dump_file + exenamelen, suffix);
   result = pdumper_load (dump_file, emacs_executable);
