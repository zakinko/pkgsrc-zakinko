$NetBSD$

etags and ctags pass the file name they were given to the shell.  A file
named with shell metacharacters therefore runs commands when it is indexed,
which is what CVE-2022-45939 and CVE-2022-48337 are.  Upstream fixed both on
the emacs-28 branch, for the 28.3 release that was never made:

	5d05ea803e  Fixed ctags local command execute vulnerability
	e339926272  Fix etags local command injection vulnerability

Taken from there unchanged.  See debbugs 59544 and 59817.

--- lib-src/etags.c.orig
+++ lib-src/etags.c
@@ -382,7 +382,7 @@
 
 static language *get_language_from_langname (const char *);
 static void readline (linebuffer *, FILE *);
-static ptrdiff_t readline_internal (linebuffer *, FILE *, char const *);
+static ptrdiff_t readline_internal (linebuffer *, FILE *, char const *, const bool);
 static bool nocase_tail (const char *);
 static void get_tag (char *, char **);
 static void get_lispy_tag (char *);
@@ -406,7 +406,10 @@
 static void pfnote (char *, bool, char *, ptrdiff_t, intmax_t, intmax_t);
 static void invalidate_nodes (fdesc *, node **);
 static void put_entries (node *);
+static void clean_matched_file_tag (char const * const, char const * const);
 
+static char *escape_shell_arg_string (char *);
+static void do_move_file (const char *, const char *);
 static char *concat (const char *, const char *, const char *);
 static char *skip_spaces (char *);
 static char *skip_non_spaces (char *);
@@ -1339,7 +1342,7 @@
 		  if (parsing_stdin)
 		    fatal ("cannot parse standard input "
 			   "AND read file names from it");
-		  while (readline_internal (&filename_lb, stdin, "-") > 0)
+		  while (readline_internal (&filename_lb, stdin, "-", false) > 0)
 		    process_file_name (filename_lb.buffer, lang);
 		}
 	      else
@@ -1387,9 +1390,6 @@
   /* From here on, we are in (CTAGS && !cxref_style) */
   if (update)
     {
-      char *cmd =
-	xmalloc (strlen (tagfile) + whatlen_max +
-		 sizeof "mv..OTAGS;grep -Fv '\t\t' OTAGS >;rm OTAGS");
       for (i = 0; i < current_arg; ++i)
 	{
 	  switch (argbuffer[i].arg_type)
@@ -1400,17 +1400,8 @@
 	    default:
 	      continue;		/* the for loop */
 	    }
-	  char *z = stpcpy (cmd, "mv ");
-	  z = stpcpy (z, tagfile);
-	  z = stpcpy (z, " OTAGS;grep -Fv '\t");
-	  z = stpcpy (z, argbuffer[i].what);
-	  z = stpcpy (z, "\t' OTAGS >");
-	  z = stpcpy (z, tagfile);
-	  strcpy (z, ";rm OTAGS");
-	  if (system (cmd) != EXIT_SUCCESS)
-	    fatal ("failed to execute shell command");
+          clean_matched_file_tag (tagfile, argbuffer[i].what);
 	}
-      free (cmd);
       append_to_tagfile = true;
     }
 
@@ -1438,8 +1429,53 @@
       }
   return EXIT_SUCCESS;
 }
+
+/*
+ * Equivalent to: mv tags OTAGS;grep -Fv ' filename ' OTAGS >tags;rm OTAGS
+ */
+static void
+clean_matched_file_tag (const char* tagfile, const char* match_file_name)
+{
+  FILE *otags_f = fopen ("OTAGS", "wb");
+  FILE *tag_f = fopen (tagfile, "rb");
+
+  if (otags_f == NULL)
+    pfatal ("OTAGS");
+
+  if (tag_f == NULL)
+    pfatal (tagfile);
+
+  int buf_len = strlen (match_file_name) + sizeof ("\t\t ") + 1;
+  char *buf = xmalloc (buf_len);
+  snprintf (buf, buf_len, "\t%s\t", match_file_name);
+
+  linebuffer line;
+  linebuffer_init (&line);
+  while (readline_internal (&line, tag_f, tagfile, true) > 0)
+    {
+      if (ferror (tag_f))
+        pfatal (tagfile);
+
+      if (strstr (line.buffer, buf) == NULL)
+        {
+          fprintf (otags_f, "%s\n", line.buffer);
+          if (ferror (tag_f))
+            pfatal (tagfile);
+        }
+    }
+  free (buf);
+  free (line.buffer);
 
+  if (fclose (otags_f) == EOF)
+    pfatal ("OTAGS");
 
+  if (fclose (tag_f) == EOF)
+    pfatal (tagfile);
+
+  do_move_file ("OTAGS", tagfile);
+  return;
+}
+
 /*
  * Return a compressor given the file name.  If EXTPTR is non-zero,
  * return a pointer into FILE where the compressor-specific
@@ -1669,13 +1705,16 @@
       else
 	{
 #if MSDOS || defined (DOS_NT)
-	  char *cmd1 = concat (compr->command, " \"", real_name);
-	  char *cmd = concat (cmd1, "\" > ", tmp_name);
+          int buf_len = strlen (compr->command) + strlen (" \"\" > \"\"") + strlen (real_name) + strlen (tmp_name) + 1;
+          char *cmd = xmalloc (buf_len);
+          snprintf (cmd, buf_len, "%s \"%s\" > \"%s\"", compr->command, real_name, tmp_name);
 #else
-	  char *cmd1 = concat (compr->command, " '", real_name);
-	  char *cmd = concat (cmd1, "' > ", tmp_name);
+          char *new_real_name = escape_shell_arg_string (real_name);
+          char *new_tmp_name = escape_shell_arg_string (tmp_name);
+          int buf_len = strlen (compr->command) + strlen ("  > ") + strlen (new_real_name) + strlen (new_tmp_name) + 1;
+          char *cmd = xmalloc (buf_len);
+          snprintf (cmd, buf_len, "%s %s > %s", compr->command, new_real_name, new_tmp_name);
 #endif
-	  free (cmd1);
 	  inf = (system (cmd) == -1
 		 ? NULL
 		 : fopen (tmp_name, "r" FOPEN_BINARY));
@@ -1822,7 +1861,7 @@
 
   /* Else look for sharp-bang as the first two characters. */
   if (parser == NULL
-      && readline_internal (&lb, inf, infilename) > 0
+      && readline_internal (&lb, inf, infilename, false) > 0
       && lb.len >= 2
       && lb.buffer[0] == '#'
       && lb.buffer[1] == '!')
@@ -6861,7 +6900,7 @@
 	if (regexfp == NULL)
 	  pfatal (regexfile);
 	linebuffer_init (&regexbuf);
-	while (readline_internal (&regexbuf, regexfp, regexfile) > 0)
+	while (readline_internal (&regexbuf, regexfp, regexfile, false) > 0)
 	  analyze_regex (regexbuf.buffer);
 	free (regexbuf.buffer);
 	if (fclose (regexfp) != 0)
@@ -7209,11 +7248,13 @@
 
 /*
  * Read a line of text from `stream' into `lbp', excluding the
- * newline or CR-NL, if any.  Return the number of characters read from
- * `stream', which is the length of the line including the newline.
+ * newline or CR-NL (if `leave_cr` is false), if any.  Return the
+ * number of characters read from `stream', which is the length
+ * of the line including the newline.
  *
- * On DOS or Windows we do not count the CR character, if any before the
- * NL, in the returned length; this mirrors the behavior of Emacs on those
+ * On DOS or Windows, if `leave_cr` is false, we do not count the
+ * CR character, if any before the NL, in the returned length;
+ * this mirrors the behavior of Emacs on those
  * platforms (for text files, it translates CR-NL to NL as it reads in the
  * file).
  *
@@ -7221,7 +7262,7 @@
  * appended to `filebuf'.
  */
 static ptrdiff_t
-readline_internal (linebuffer *lbp, FILE *stream, char const *filename)
+readline_internal (linebuffer *lbp, FILE *stream, char const *filename, const bool leave_cr)
 {
   char *buffer = lbp->buffer;
   char *p = lbp->buffer;
@@ -7251,19 +7292,19 @@
 	  break;
 	}
       if (c == '\n')
-	{
-	  if (p > buffer && p[-1] == '\r')
-	    {
-	      p -= 1;
-	      chars_deleted = 2;
-	    }
-	  else
-	    {
-	      chars_deleted = 1;
-	    }
-	  *p = '\0';
-	  break;
-	}
+        {
+          if (!leave_cr && p > buffer && p[-1] == '\r')
+            {
+              p -= 1;
+              chars_deleted = 2;
+            }
+          else
+            {
+              chars_deleted = 1;
+            }
+          *p = '\0';
+          break;
+        }
       *p++ = c;
     }
   lbp->len = p - buffer;
@@ -7294,7 +7335,7 @@
 readline (linebuffer *lbp, FILE *stream)
 {
   linecharno = charno;		/* update global char number of line start */
-  ptrdiff_t result = readline_internal (lbp, stream, infilename);
+  ptrdiff_t result = readline_internal (lbp, stream, infilename, false);
   lineno += 1;			/* increment global line number */
   charno += result;		/* increment global char number */
 
@@ -7651,7 +7692,96 @@
 
   return templt;
 }
+
+/*
+ * Adds single quotes around a string, if found single quotes, escaped it.
+ * Return a newly-allocated string.
+ *
+ * For example:
+ * escape_shell_arg_string("test.txt") => 'test.txt'
+ * escape_shell_arg_string("'test.txt") => ''\''test.txt'
+ */
+static char *
+escape_shell_arg_string (char *str)
+{
+  char *p = str;
+  int need_space = 2;           /* ' at begin and end */
 
+  while (*p != '\0')
+    {
+      if (*p == '\'')
+        need_space += 4;        /* ' to '\'', length is 4 */
+      else
+        need_space++;
+
+      p++;
+    }
+
+  char *new_str = xnew (need_space + 1, char);
+  new_str[0] = '\'';
+  new_str[need_space-1] = '\'';
+
+  int i = 1;                    /* skip first byte */
+  p = str;
+  while (*p != '\0')
+    {
+      new_str[i] = *p;
+      if (*p == '\'')
+        {
+          new_str[i+1] = '\\';
+          new_str[i+2] = '\'';
+          new_str[i+3] = '\'';
+          i += 3;
+        }
+
+      i++;
+      p++;
+    }
+
+  new_str[need_space] = '\0';
+  return new_str;
+}
+
+static void
+do_move_file(const char *src_file, const char *dst_file)
+{
+  if (rename (src_file, dst_file) == 0)
+    return;
+
+  FILE *src_f = fopen (src_file, "rb");
+  FILE *dst_f = fopen (dst_file, "wb");
+
+  if (src_f == NULL)
+    pfatal (src_file);
+
+  if (dst_f == NULL)
+    pfatal (dst_file);
+
+  int c;
+  while ((c = fgetc (src_f)) != EOF)
+    {
+      if (ferror (src_f))
+        pfatal (src_file);
+
+      if (ferror (dst_f))
+        pfatal (dst_file);
+
+      if (fputc (c, dst_f) == EOF)
+        pfatal ("cannot write");
+    }
+
+  if (fclose (src_f) == EOF)
+    pfatal (src_file);
+
+  if (fclose (dst_f) == EOF)
+    pfatal (dst_file);
+
+  if (unlink (src_file) == -1)
+    pfatal ("unlink error");
+
+  return;
+}
+
 /* Return a newly allocated string containing the file name of FILE
    relative to the absolute directory DIR (which should end with a slash). */
 static char *
