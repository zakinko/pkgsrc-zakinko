$NetBSD$

find-gc.el builds a working directory by running

	rm -rf /tmp/esrc
	mkdir /tmp/esrc
	ln -s <source>/*.[ch] /tmp/esrc

through csh, then compiles out of it and reads back /tmp/esrc/<file>.rtl.
The name is fixed, so anything already sitting at /tmp/esrc decides what the
rm removes and what the compiler reads.  This is CVE-2014-3422.

Upstream stopped using a temporary directory at all: it compiles in place
with default-directory bound to the source directory, writes the dump next
to the source with -fdump-rtl-expand, reads it and deletes it.  pkgsrc
carries that as patch-lisp_emacs-lisp_find-gc.el in emacs23 and emacs24
(taca, 2014-07-09), but nothing below 23 was ever done.

The replacement function is taken from there.  It does not apply as it
stands: this version has save-excursion/set-buffer where 23.4 has
with-current-buffer, and the whole function is replaced anyway, so the body
is dropped in by hand.

emacs21 also names its variables differently -- emacs-source-directory,
subrs-called and source-files where 23.4 has find-gc-source-directory,
find-gc-subrs-called and find-gc-source-files -- so the body is renamed to
match.  Byte-compiling with emacs21 before and after gives the same set of
warnings; this file has always referred to those three as free variables.

--- lisp/emacs-lisp/find-gc.el.orig
+++ lisp/emacs-lisp/find-gc.el
@@ -25,7 +25,6 @@
 
 ;; Produce in unsafe-list the set of all functions that may invoke GC.
 ;; This expects the Emacs sources to live in emacs-source-directory.
-;; It creates a temporary working directory /tmp/esrc.
 
 ;;; Code:
 
@@ -74,68 +73,38 @@
 ;;; This produces an a-list of functions in subrs-called.  The cdr of
 ;;; each entry is a list of functions which the function in car calls.
 
-(defun trace-call-tree (&optional already-setup)
+(defun trace-call-tree (&optional ignored)
   (message "Setting up directories...")
-  (or already-setup
-      (progn
-	;; Gee, wouldn't a built-in "system" function be handy here.
-	(call-process "csh" nil nil nil "-c" "rm -rf /tmp/esrc")
-	(call-process "csh" nil nil nil "-c" "mkdir /tmp/esrc")
-	(call-process "csh" nil nil nil "-c"
-		      (format "ln -s %s/*.[ch] /tmp/esrc"
-			      emacs-source-directory))))
-  (save-excursion
-    (set-buffer (get-buffer-create "*Trace Call Tree*"))
-    (setq subrs-called nil)
-    (let ((case-fold-search nil)
-	  (files source-files)
-	  name entry)
-      (while files
-	(message "Compiling %s..." (car files))
-	(call-process "csh" nil nil nil "-c"
-		      (format "gcc -dr -c /tmp/esrc/%s -o /dev/null"
-			      (car files)))
-	(erase-buffer)
-	(insert-file-contents (concat "/tmp/esrc/" (car files) ".rtl"))
-	(while (re-search-forward ";; Function \\|(call_insn " nil t)
-	  (if (= (char-after (- (point) 3)) ?o)
-	      (progn
-		(looking-at "[a-zA-Z0-9_]+")
-		(setq name (intern (buffer-substring (match-beginning 0)
-						     (match-end 0))))
-		(message "%s : %s" (car files) name)
-		(setq entry (list name)
-		      subrs-called (cons entry subrs-called)))
-	    (if (looking-at ".*\n?.*\"\\([A-Za-z0-9_]+\\)\"")
+  (setq subrs-called nil)
+  (let ((case-fold-search nil)
+	(default-directory emacs-source-directory)
+	(files source-files)
+	name entry rtlfile)
+    (dolist (file files)
+      (message "Compiling %s..." file)
+      (call-process "gcc" nil nil nil "-I" "." "-I" "../lib"
+		    "-fdump-rtl-expand" "-o" null-device "-c" file)
+      (setq rtlfile
+	    (file-expand-wildcards (format "%s.*.expand" file) t))
+      (if (/= 1 (length rtlfile))
+	  (message "Error compiling `%s'?" file)
+	(with-temp-buffer
+	  (insert-file-contents (setq rtlfile (car rtlfile)))
+	  (delete-file rtlfile)
+	  (while (re-search-forward ";; Function \\|(call_insn " nil t)
+	    (if (= (char-after (- (point) 3)) ?o)
 		(progn
-		  (setq name (intern (buffer-substring (match-beginning 1)
-						       (match-end 1))))
-		  (or (memq name (cdr entry))
-		      (setcdr entry (cons name (cdr entry))))))))
-	(delete-file (concat "/tmp/esrc/" (car files) ".rtl"))
-	(setq files (cdr files)))))
-)
-
-
-;;; This was originally generated directory-files, but there were
-;;; too many files there that were not actually compiled.  The
-;;; list below was created for a HP-UX 7.0 system.
-
-(setq source-files '("dispnew.c" "scroll.c" "xdisp.c" "window.c"
-		     "term.c" "cm.c" "emacs.c" "keyboard.c" "macros.c"
-		     "keymap.c" "sysdep.c" "buffer.c" "filelock.c"
-		     "insdel.c" "marker.c" "minibuf.c" "fileio.c"
-		     "dired.c" "filemode.c" "cmds.c" "casefiddle.c"
-		     "indent.c" "search.c" "regex.c" "undo.c"
-		     "alloc.c" "data.c" "doc.c" "editfns.c"
-		     "callint.c" "eval.c" "fns.c" "print.c" "lread.c"
-		     "abbrev.c" "syntax.c" "unexec.c" "mocklisp.c"
-		     "bytecode.c" "process.c" "callproc.c" "doprnt.c"
-		     "x11term.c" "x11fns.c"))
-
-
-;;; This produces an inverted a-list in subrs-used.  The cdr of each
-;;; entry is a list of functions that call the function in car.
+		  (looking-at "[a-zA-Z0-9_]+")
+		  (setq name (intern (match-string 0)))
+		  (message "%s : %s" (car files) name)
+		  (setq entry (list name)
+			subrs-called
+			(cons entry subrs-called)))
+	      (if (looking-at ".*\n?.*\"\\([A-Za-z0-9_]+\\)\"")
+		  (progn
+		    (setq name (intern (match-string 1)))
+		    (or (memq name (cdr entry))
+			(setcdr entry (cons name (cdr entry)))))))))))))
 
 (defun trace-use-tree ()
   (setq subrs-used (mapcar 'list (mapcar 'car subrs-called)))
