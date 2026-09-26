$NetBSD$

etags and ctags hand the name of the file they are indexing to the shell, so
a file whose name holds shell metacharacters runs commands when it is
indexed.  This is CVE-2022-45939 and CVE-2022-48337.

Upstream fixed it on the emacs-28 branch, for the 28.3 release that was never
made, with

	5d05ea803e  Fixed ctags local command execute vulnerability
	e339926272  Fix etags local command injection vulnerability

The helper escape_shell_arg_string is taken from there unchanged.  The call
site is written out by hand because this version's etags.c differs from
28.2's around it.  See debbugs 59544 and 59817.

--- lib-src/etags.c.orig
+++ lib-src/etags.c
@@ -1536,7 +1536,59 @@
 
 /*
  * This routine is called on each file argument.
+ */
+/*
+ * Adds single quotes around a string, if found single quotes, escaped it.
+ * Return a newly-allocated string.
+ *
+ * Backported from Emacs 28.3 (CVE-2022-45939, CVE-2022-48337).
+ *
+ * For example:
+ * escape_shell_arg_string("test.txt") => 'test.txt'
+ * escape_shell_arg_string("'test.txt") => ''\''test.txt'
  */
+static char *
+escape_shell_arg_string (char *str)
+{
+  char *p = str;
+  int need_space = 2;           /* ' at begin and end */
+
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
+
+  return new_str;
+}
+
 static void
 process_file_name (char *file, language *lang)
 {
@@ -1637,13 +1689,22 @@
       else
 	{
 #if MSDOS || defined (DOS_NT)
-	  char *cmd1 = concat (compr->command, " \"", real_name);
-	  char *cmd = concat (cmd1, "\" > ", tmp_name);
+	  int buf_len = strlen (compr->command) + strlen (" \"\" > \"\"")
+			+ strlen (real_name) + strlen (tmp_name) + 1;
+	  char *cmd = xnew (buf_len, char);
+	  snprintf (cmd, buf_len, "%s \"%s\" > \"%s\"",
+		    compr->command, real_name, tmp_name);
 #else
-	  char *cmd1 = concat (compr->command, " '", real_name);
-	  char *cmd = concat (cmd1, "' > ", tmp_name);
+	  /* CVE-2022-45939 and CVE-2022-48337: single quotes alone do not
+	     protect a name that contains a single quote of its own.  */
+	  char *new_real_name = escape_shell_arg_string (real_name);
+	  char *new_tmp_name = escape_shell_arg_string (tmp_name);
+	  int buf_len = strlen (compr->command) + strlen ("  > ")
+			+ strlen (new_real_name) + strlen (new_tmp_name) + 1;
+	  char *cmd = xnew (buf_len, char);
+	  snprintf (cmd, buf_len, "%s %s > %s",
+		    compr->command, new_real_name, new_tmp_name);
 #endif
-	  free (cmd1);
 	  int tmp_errno;
 	  if (system (cmd) == -1)
 	    {
