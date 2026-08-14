$NetBSD$

Make anthy.el work on current Emacs.  Five names it uses were made obsolete
and later removed, and one reader syntax was dropped:

set-face-underline-p became an alias for set-face-underline in Emacs 24.3
and was removed in Emacs 29.  The call is at top level, so on Emacs 29 and
30 merely loading anthy.el signals an error, and anthy-isearch.el and
anthy-kyuri.el then fail to byte-compile because they (require 'anthy) --
their .elc files end up missing from what PLIST expects.

The old backquote syntax, (` (foo (, bar))), was removed in Emacs 28.  On
Emacs 28 and later anthy-deflocalvar expands to nil, so none of the eleven
buffer-local variables it is used to define -- anthy-context-id, anthy-mode,
anthy-preedit and the rest -- come into existence.  This does not break the
build; it breaks the input method, which dies with a void-variable error the
moment it is switched on.

process-kill-without-query was obsoleted by set-process-query-on-exit-flag
in Emacs 22.1 and removed in Emacs 30.  It is called from anthy-check-agent,
which anthy-do-send-recv-command calls to start anthy-agent, so on Emacs 30
the first conversion request fails.

inactivate-input-method was renamed deactivate-input-method in Emacs 24.3
and the old name was removed in Emacs 30.  It is called from
anthy-leim-exit-from-minibuffer, which is put on minibuffer-exit-hook while
anthy is active in the minibuffer.

inactivate-current-input-method-function was likewise renamed in Emacs 24.3.
anthy-leim-activate still assigns to the old name, so on any Emacs since
24.3 the input method has never been deactivated through the LEIM hook.

last-command-char was an obsolete alias for last-command-event and was
removed in Emacs 24.  The XEmacs branch of this function already uses
last-command-event; only the GNU Emacs branch was left behind.

emacs20, emacs21 and the XEmacs versions in EMACS_VERSIONS_ACCEPTED do not
have the new names, so the calls are guarded rather than renamed.  The
backquote rewrite needs no guard: the modern syntax has worked since Emacs
19.29 and in XEmacs 20.

anthy has not been released since 2009, so there is nowhere upstream to
send this.

--- src-util/anthy.el.orig
+++ src-util/anthy.el
@@ -71,7 +71,9 @@
 (defvar anthy-highlight-face nil)
 (defvar anthy-underline-face nil)
 (copy-face 'highlight 'anthy-highlight-face)
-(set-face-underline-p 'anthy-highlight-face t)
+(if (fboundp 'set-face-underline)
+    (set-face-underline 'anthy-highlight-face t)
+  (set-face-underline-p 'anthy-highlight-face t))
 (copy-face 'underline 'anthy-underline-face)
 
 ;;
@@ -161,11 +163,11 @@
 
 ;; From skk-macs.el From viper-util.el.  Welcome!
 (defmacro anthy-deflocalvar (var default-value &optional documentation)
-  (` (progn
-       (defvar (, var) (, default-value)
-	 (, (format "%s\n\(buffer local\)" documentation)))
-       (make-variable-buffer-local '(, var))
-       )))
+  `(progn
+     (defvar ,var ,default-value
+       ,(format "%s\n\(buffer local\)" documentation))
+     (make-variable-buffer-local ',var)
+     ))
 
 ;; buffer local variables
 (anthy-deflocalvar anthy-context-id nil "コンテキストのid")
@@ -745,7 +747,9 @@
 	(if anthy-agent-process
 	    (kill-process anthy-agent-process))
 	(setq anthy-agent-process proc)
-	(process-kill-without-query proc)
+	(if (fboundp 'set-process-query-on-exit-flag)
+	    (set-process-query-on-exit-flag proc nil)
+	  (process-kill-without-query proc))
 	(if anthy-xemacs
 	    (if (coding-system-p (find-coding-system 'euc-japan))
 		(set-process-coding-system proc 'euc-japan 'euc-japan))
@@ -864,7 +868,9 @@
 ;; leim の activate
 ;;
 (defun anthy-leim-activate (&optional name)
-  (setq inactivate-current-input-method-function 'anthy-leim-inactivate)
+  (if (boundp 'deactivate-current-input-method-function)
+      (setq deactivate-current-input-method-function 'anthy-leim-inactivate)
+    (setq inactivate-current-input-method-function 'anthy-leim-inactivate))
   (setq anthy-leim-active-p t)
   (anthy-update-mode)
   (when (eq (selected-window) (minibuffer-window))
@@ -874,7 +880,9 @@
 ;; emacsのバグ避けらしいです
 ;;
 (defun anthy-leim-exit-from-minibuffer ()
-  (inactivate-input-method)
+  (if (fboundp 'deactivate-input-method)
+      (deactivate-input-method)
+    (inactivate-input-method))
   (when (<= (minibuffer-depth) 1)
     (remove-hook 'minibuffer-exit-hook 'anthy-leim-exit-from-minibuffer)))
 
@@ -892,7 +900,7 @@
 	 ((event-matches-key-specifier-p event 'backspace) 8)
 	 (t
 	  (char-to-int (event-to-character event)))))
-    last-command-char))
+    last-command-event))
 
 ;;
 ;;
