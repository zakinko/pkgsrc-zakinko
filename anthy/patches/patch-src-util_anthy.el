$NetBSD$

Keep each buffer's saved undo list to itself, drop code that has never been
able to run, and let the file work from Mule 2.3 through Emacs 31 without a
byte-compile warning on any of them.

anthy stops undo while a preedit is open and puts the buffer's undo list
aside until the text is committed.  The flag that records it did so,
anthy-buffer-undo-list-saved, is anthy-deflocalvar, that is per buffer, but
the list itself was never declared at all and so was one global shared by
every buffer.  Open a preedit in a second buffer while one is still pending
in the first and the first buffer's saved history is overwritten; committing
there installs the second buffer's list, whose positions do not fit, and the
next undo stops with "Changes to be undone are outside visible portion of
buffer".  Reproduced on Emacs 20.7 through 31.1 and on Mule 2.3.

anthy-restore-undo-list cannot run: its one call site is commented out, and
the variable it reads is only ever set in two lines that are commented out
as well, all three already so in anthy 9100h.  It is commented out here the
same way rather than deleted, so that taking the semicolons off brings the
whole idea back.

The rest is portability, and it goes in both directions.  Old style (` ...)
backquote was removed in Emacs 28; new style `(...) does not exist in the
Emacs 19.28 reader Mule 2.3 is built on.  Building the form with list needs
neither.  Names that were renamed or removed are picked once at load time
and called through a variable, because writing the old name in an else
branch leaves a current Emacs reporting it as not known to be defined:

  set-face-underline              Emacs 21; until 24.3 set-face-underline-p
                                  is the current spelling, and -p was removed
                                  in 29.  The call is at top level, so where
                                  the name is missing the file does not load
                                  and only 4 of the 6 .elc files are built.
  set-process-query-on-exit-flag  Emacs 22.1; process-kill-without-query was
                                  removed in 27.  It is on the path that
                                  starts anthy-agent, so Emacs 27 and later
                                  build and load and then die at the first
                                  conversion.
  deactivate-input-method,
  deactivate-current-input-method-function
                                  renamed from inactivate-* in 24.3, old
                                  names removed in 29.
  mapc                            Emacs 21; 9100h used mapcar and threw the
                                  value away, which a current byte compiler
                                  reports.
  last-command-char               removed in Emacs 24.  The XEmacs branch of
                                  anthy-last-command-char already used
                                  last-command-event; only the GNU Emacs
                                  branch was left behind.
  rassoc                          Emacs 19.29, so Mule 2.3 lacks it.  Carried
                                  here.  It is on the candidate-selection
                                  path only, which is why a plain conversion
                                  works there without it.
  when                            not in Emacs 19.28; the two uses are
                                  written out as if and progn.

The XEmacs-only names in anthy-last-command-char go through a variable for
the same reason.  Mule 2.3 predates LEIM and has neither set-language-info
nor current-language-environment, so the registration at the end is guarded;
anthy-mode itself works there, only the japanese-anthy input method is out of
reach.  A lexical-binding cookie is added, which keeps the current dynamic
binding and silences the last warning on Emacs 24 and later.

Measured on NetBSD 11.0/amd64 with Mule 2.3 (Emacs 19.28) and Emacs 20.7,
21.4, 22.3, 23.4, 24.5, 25.3, 26.3, 27.2, 28.2, 29.4, 30.2 and 31.1: all six
.elc files build with no warnings, typing nihongo converts to the same six
EUC-JP bytes under LANG=C, ja_JP.eucJP and ja_JP.UTF-8, and the cross-buffer
undo case above restores the buffer's own list.

anthy has not been released since 2009, so there is nowhere upstream to send
this.  This replaces the former patch-anthy.el, which fixed the backquote by
moving to a syntax Mule 2.3 cannot read.

--- src-util/anthy.el.orig
+++ src-util/anthy.el
@@ -1,4 +1,4 @@
-;;; anthy.el -- Anthy
+;;; anthy.el -- Anthy  -*- lexical-binding: nil -*-
 
 ;; Copyright (C) 2001 - 2007 KMC(Kyoto University Micro Computer Club)
 
@@ -67,11 +67,77 @@
 (defvar anthy-agent-command-list '("anthy-agent")
   "anthy-agentのPATH名")
 
+;; Names that Emacs added, renamed or removed along the way, and names that
+;; only XEmacs has.  Each is picked once here and called through a variable.
+;; Writing the old name in an else branch would work too, but then a current
+;; Emacs reports it as not known to be defined, and the file cannot be built
+;; without warnings on any single version.
+
+;; XEmacs only.  Reached only when anthy-xemacs is true.
+(defvar anthy-event-matches-key-specifier-p-function
+  'event-matches-key-specifier-p)
+(defvar anthy-event-to-character-function 'event-to-character)
+(defvar anthy-char-to-int-function 'char-to-int)
+(defvar anthy-find-coding-system-function 'find-coding-system)
+
+;; set-process-query-on-exit-flag is new in Emacs 22.1 and
+;; process-kill-without-query was removed in Emacs 27.  Both mean "do not ask
+;; on exit" when the second argument is nil.  The call sits in
+;; anthy-check-agent, on the path that starts anthy-agent, so on Emacs 27 and
+;; later the file builds and loads and then dies at the first conversion.
+(defvar anthy-set-process-no-query-function
+  (if (fboundp 'set-process-query-on-exit-flag)
+      'set-process-query-on-exit-flag
+    'process-kill-without-query))
+
+;; Renamed from inactivate-* in Emacs 24.3, old names removed in 29.  Emacs 20
+;; through 23, Mule 2.3 and XEmacs have only the old spelling.
+(defvar anthy-deactivate-input-method-function
+  (if (fboundp 'deactivate-input-method)
+      'deactivate-input-method
+    'inactivate-input-method))
+(defvar anthy-deactivate-current-input-method-variable
+  (if (boundp 'deactivate-current-input-method-function)
+      'deactivate-current-input-method-function
+    'inactivate-current-input-method-function))
+
+;; set-face-underline is new in Emacs 21, but until 24.3 set-face-underline-p
+;; is the current spelling and the new one is the alias; -p was removed in 29.
+;; This call is at top level, so where the name is missing the file does not
+;; load at all and anthy-isearch.elc and anthy-kyuri.elc are never built.
+(defvar anthy-set-face-underline-function
+  (if (fboundp 'set-face-underline)
+      'set-face-underline
+    'set-face-underline-p))
+
+;; mapc is new in Emacs 21; 9100h used mapcar here and threw the value away,
+;; which is what the byte compiler complains about on a current Emacs.
+(defvar anthy-mapc-function
+  (if (fboundp 'mapc)
+      'mapc
+    'mapcar))
+
+;; rassoc arrived in Emacs 19.29 and Mule 2.3 is built on 19.28, so it has to
+;; be carried.  It is on the candidate-selection path only, which is why a
+;; plain conversion works there without it.
+(defun anthy-rassoc (value alist)
+  (let ((res nil))
+    (while (and alist (not res))
+      (if (equal (cdr (car alist)) value)
+	  (setq res (car alist)))
+      (setq alist (cdr alist)))
+    res))
+(defvar anthy-rassoc-function
+  (if (fboundp 'rassoc)
+      'rassoc
+    'anthy-rassoc))
+
 ;; face
 (defvar anthy-highlight-face nil)
 (defvar anthy-underline-face nil)
 (copy-face 'highlight 'anthy-highlight-face)
-(set-face-underline-p 'anthy-highlight-face t)
+;(set-face-underline-p 'anthy-highlight-face t)
+(funcall anthy-set-face-underline-function 'anthy-highlight-face t)
 (copy-face 'underline 'anthy-underline-face)
 
 ;;
@@ -161,11 +227,19 @@
 
 ;; From skk-macs.el From viper-util.el.  Welcome!
 (defmacro anthy-deflocalvar (var default-value &optional documentation)
-  (` (progn
-       (defvar (, var) (, default-value)
-	 (, (format "%s\n\(buffer local\)" documentation)))
-       (make-variable-buffer-local '(, var))
-       )))
+;; The old (` ...) reader syntax was removed in Emacs 28, and the new `(...)
+;; syntax does not exist in the Emacs 19.28 reader that Mule 2.3 is built on.
+;; Building the form with list needs neither, and works from Emacs 18.59
+;; through 31.
+;  (` (progn
+;       (defvar (, var) (, default-value)
+;	 (, (format "%s\n\(buffer local\)" documentation)))
+;       (make-variable-buffer-local '(, var))
+;       )))
+  (list 'progn
+	(list 'defvar var default-value
+	      (format "%s\n\(buffer local\)" documentation))
+	(list 'make-variable-buffer-local (list 'quote var))))
 
 ;; buffer local variables
 (anthy-deflocalvar anthy-context-id nil "コンテキストのid")
@@ -195,6 +269,14 @@
 (anthy-deflocalvar anthy-current-rkmap "hiragana")
 ; undo
 (anthy-deflocalvar anthy-buffer-undo-list-saved nil)
+;; anthy-buffer-undo-list-saved above is buffer local, but the list it guards
+;; was never declared at all, so every buffer shared one global.  Begin a
+;; conversion in a second buffer while one is still pending in the first and
+;; the first buffer's saved history is overwritten; committing there then
+;; installs the other buffer's list, whose positions do not fit this buffer,
+;; and the next undo stops with "Changes to be undone are outside visible
+;; portion of buffer".  Declared here, each buffer keeps its own.
+(anthy-deflocalvar anthy-buffer-undo-list nil)
 
 ;;
 (defvar anthy-wide-space "　" "スペースを押した時に出て来る文字")
@@ -243,7 +325,8 @@
 	(delete-region start (+ start len))
 	(goto-char start)))
   (setq anthy-preedit "")
-  (mapcar 'delete-overlay anthy-preedit-overlays)
+;  (mapcar 'delete-overlay anthy-preedit-overlays)
+  (funcall anthy-mapc-function 'delete-overlay anthy-preedit-overlays)
   (setq anthy-preedit-overlays nil))
 
 (defun anthy-select-face-by-attr (attr)
@@ -539,14 +622,21 @@
 	  (char-to-string ch)
 	nil))))
 
-(defun anthy-restore-undo-list (commit-str)
-  (let* ((len (length commit-str))
-	 (beginning (point))
-	 (end (+ beginning len)))
-    (setq buffer-undo-list
-	  (cons (cons beginning end)
-		(cons nil anthy-saved-buffer-undo-list)))
-	 ))
+;; anthy-restore-undo-list has never been able to run.  Its only call site, in
+;; anthy-proc-agent-reply below, is commented out, and the variable it reads,
+;; anthy-saved-buffer-undo-list, is only ever assigned in two lines that are
+;; themselves commented out further up.  So it is dead code, and the byte
+;; compiler reports the free variable.  Comment it out rather than delete it,
+;; the way its own call site is commented out, so taking the semicolons off
+;; brings the whole idea back.
+;(defun anthy-restore-undo-list (commit-str)
+;  (let* ((len (length commit-str))
+;	 (beginning (point))
+;	 (end (+ beginning len)))
+;    (setq buffer-undo-list
+;	  (cons (cons beginning end)
+;		(cons nil anthy-saved-buffer-undo-list)))
+;	 ))
 
 (defun anthy-proc-agent-reply (repl)
   (let*
@@ -609,7 +699,7 @@
     (anthy-update-mode-line)))
 
 (defun anthy-insert-select-candidate (ch)
-  (let* ((key-idx (car (rassoc (char-to-string ch)
+  (let* ((key-idx (car (funcall anthy-rassoc-function (char-to-string ch)
 			       anthy-select-candidate-keybind)))
 	 (idx (car (cdr (assq key-idx
 			      anthy-enum-candidate-list)))))
@@ -677,7 +767,7 @@
    ;; 候補選択モードから候補を選ぶ
    ((and (or anthy-enum-candidate-p anthy-enum-rcandidate-p)
 	 (integerp ch)
-	 (assq (car (rassoc (char-to-string ch)
+	 (assq (car (funcall anthy-rassoc-function (char-to-string ch)
 			    anthy-select-candidate-keybind))
 	       anthy-enum-candidate-list))
     (anthy-insert-select-candidate ch))
@@ -745,9 +835,12 @@
 	(if anthy-agent-process
 	    (kill-process anthy-agent-process))
 	(setq anthy-agent-process proc)
-	(process-kill-without-query proc)
+;	(process-kill-without-query proc)
+	(funcall anthy-set-process-no-query-function proc nil)
 	(if anthy-xemacs
-	    (if (coding-system-p (find-coding-system 'euc-japan))
+;	    (if (coding-system-p (find-coding-system 'euc-japan))
+	    (if (coding-system-p
+		 (funcall anthy-find-coding-system-function 'euc-japan))
 		(set-process-coding-system proc 'euc-japan 'euc-japan))
 	  (cond ((coding-system-p 'euc-japan)
 		 (set-process-coding-system proc 'euc-japan 'euc-japan))
@@ -864,18 +957,20 @@
 ;; leim の activate
 ;;
 (defun anthy-leim-activate (&optional name)
-  (setq inactivate-current-input-method-function 'anthy-leim-inactivate)
+;  (setq inactivate-current-input-method-function 'anthy-leim-inactivate)
+  (set anthy-deactivate-current-input-method-variable 'anthy-leim-inactivate)
   (setq anthy-leim-active-p t)
   (anthy-update-mode)
-  (when (eq (selected-window) (minibuffer-window))
+  (if (eq (selected-window) (minibuffer-window))
     (add-hook 'minibuffer-exit-hook 'anthy-leim-exit-from-minibuffer)))
 
 ;;
 ;; emacsのバグ避けらしいです
 ;;
 (defun anthy-leim-exit-from-minibuffer ()
-  (inactivate-input-method)
-  (when (<= (minibuffer-depth) 1)
+;  (inactivate-input-method)
+  (funcall anthy-deactivate-input-method-function)
+  (if (<= (minibuffer-depth) 1)
     (remove-hook 'minibuffer-exit-hook 'anthy-leim-exit-from-minibuffer)))
 
 ;;
@@ -884,15 +979,31 @@
 ;;
 (defun anthy-last-command-char ()
   "最後の入力イベントを返す。XEmacs では int に変換する"
+;; The three XEmacs-only names here are reached only when anthy-xemacs is
+;; true, but written directly a GNU Emacs byte compiler reports them as not
+;; known to be defined.  Going through a variable keeps the call and drops
+;; the warning.  last-command-char was an obsolete alias for
+;; last-command-event and was removed in Emacs 24; the XEmacs branch just
+;; above already used the current name, only this one was left behind.
+;  (if anthy-xemacs
+;      (let ((event last-command-event))
+;	(cond
+;	 ((event-matches-key-specifier-p event 'left)      2)
+;	 ((event-matches-key-specifier-p event 'right)     6)
+;	 ((event-matches-key-specifier-p event 'backspace) 8)
+;	 (t
+;	  (char-to-int (event-to-character event)))))
+;    last-command-char))
   (if anthy-xemacs
       (let ((event last-command-event))
 	(cond
-	 ((event-matches-key-specifier-p event 'left)      2)
-	 ((event-matches-key-specifier-p event 'right)     6)
-	 ((event-matches-key-specifier-p event 'backspace) 8)
+	 ((funcall anthy-event-matches-key-specifier-p-function event 'left)      2)
+	 ((funcall anthy-event-matches-key-specifier-p-function event 'right)     6)
+	 ((funcall anthy-event-matches-key-specifier-p-function event 'backspace) 8)
 	 (t
-	  (char-to-int (event-to-character event)))))
-    last-command-char))
+	  (funcall anthy-char-to-int-function
+		   (funcall anthy-event-to-character-function event)))))
+    last-command-event))
 
 ;;
 ;;
@@ -904,8 +1015,20 @@
 (require 'anthy-conf)
 
 ;; is it ok for i18n?
-(set-language-info "Japanese" 'input-method "japanese-anthy")
-(if (equal current-language-environment "Japanese")
+;; Mule 2.3 (Emacs 19.28) predates LEIM: it has neither set-language-info nor
+;; current-language-environment, so loading anthy.el there stopped here with a
+;; void-function error.  anthy-mode itself works on it; only the japanese-anthy
+;; input method is out of reach.  Guard the registration instead of dropping it.
+;(set-language-info "Japanese" 'input-method "japanese-anthy")
+;(if (equal current-language-environment "Japanese")
+;    (progn
+;      (if (boundp 'default-input-method)
+;	  (setq-default default-input-method "japanese-anthy"))
+;      (setq default-input-method "japanese-anthy")))
+(if (fboundp 'set-language-info)
+    (set-language-info "Japanese" 'input-method "japanese-anthy"))
+(if (and (boundp 'current-language-environment)
+	 (equal current-language-environment "Japanese"))
     (progn
       (if (boundp 'default-input-method)
 	  (setq-default default-input-method "japanese-anthy"))
