$NetBSD$

CVE-2022-45939: etags -u ran "mv ... OTAGS; fgrep ..." through the shell
with the file name unquoted, so a crafted file name ran commands.  Do the
filtering in C instead, as Emacs 28.2 does.

--- lib-src/etags.c.orig
+++ lib-src/etags.c
@@ -213,6 +213,7 @@
 int total_size_of_entries ();
 long readline ();
 long readline_internal ();
+void clean_matched_file_tag ();
 #ifdef ETAGS_REGEXPS
 void analyse_regex ();
 void add_regex ();
@@ -763,6 +764,56 @@
 #endif /* VMS */
 
 
+/*
+ * Remove from TAGFILE the entries that came from MATCH_FILE_NAME.
+ * Equivalent to what used to be done with
+ *   mv TAGFILE OTAGS; fgrep -v '\tMATCH\t' OTAGS > TAGFILE; rm OTAGS
+ * through system(), which ran whatever shell metacharacters the file
+ * name carried (CVE-2022-45939).
+ */
+void
+clean_matched_file_tag (tagfile, match_file_name)
+     char *tagfile;
+     char *match_file_name;
+{
+  FILE *otags_f, *tag_f;
+  struct linebuffer line;
+  char *pattern;
+  int patlen;
+
+  tag_f = fopen (tagfile, "r");
+  if (tag_f == NULL)
+    pfatal (tagfile);
+  otags_f = fopen ("OTAGS", "w");
+  if (otags_f == NULL)
+    pfatal ("OTAGS");
+
+  patlen = strlen (match_file_name) + 3;
+  pattern = xnew (patlen, char);
+  sprintf (pattern, "\t%s\t", match_file_name);
+  initbuffer (&line);
+  while (readline_internal (&line, tag_f) > 0)
+    {
+      if (ferror (tag_f))
+	pfatal (tagfile);
+      if (strstr (line.buffer, pattern) == NULL)
+	{
+	  fputs (line.buffer, otags_f);
+	  putc ('\n', otags_f);
+	  if (ferror (otags_f))
+	    pfatal ("OTAGS");
+	}
+    }
+  free (line.buffer);
+  free (pattern);
+  if (fclose (otags_f) == EOF)
+    pfatal ("OTAGS");
+  if (fclose (tag_f) == EOF)
+    pfatal (tagfile);
+  if (rename ("OTAGS", tagfile) < 0)
+    pfatal (tagfile);
+}
+
 int
 main (argc, argv)
      int argc;
@@ -1028,16 +1079,11 @@
 
   if (update)
     {
-      char cmd[BUFSIZ];
       for (i = 0; i < current_arg; ++i)
 	{
 	  if (argbuffer[i].arg_type != at_filename)
 	    continue;
-	  sprintf (cmd,
-		   "mv %s OTAGS;fgrep -v '\t%s\t' OTAGS >%s;rm OTAGS",
-		   tagfile, argbuffer[i].what, tagfile);
-	  if (system (cmd) != GOOD)
-	    fatal ("failed to execute shell command", (char *)NULL);
+	  clean_matched_file_tag (tagfile, argbuffer[i].what);
 	}
       append_to_tagfile = TRUE;
     }
