$NetBSD$

Make anthy-unicode.el work on the older Emacs versions pkgsrc still carries,
not only on a current one.

anthy-unicode inherited anthy 9100h's elisp and modernised the names it uses.
That is the mirror image of what 9100h now does on a current Emacs: where
9100h calls names Emacs has since removed, anthy-unicode calls names Emacs 20
and 21 do not have yet.

  set-face-underline              new in Emacs 22.1; Emacs 20 has
                                  set-face-underline-p only.  The call is at
                                  top level, so on Emacs 20 loading the file
                                  signals an error, and anthy-unicode-isearch
                                  and anthy-unicode-kyuri then fail to
                                  byte-compile because they require it --
                                  5 of the 7 .elc files get built.
  mapc                            new in Emacs 21.  9100h used mapcar in this
                                  same line, which every Emacs and XEmacs has.
  set-process-query-on-exit-flag  new in Emacs 22.1; Emacs 20 and 21 have
                                  process-kill-without-query.  It is called
                                  from anthy-check-agent, which starts the
                                  agent, so on Emacs 21 the package builds
                                  cleanly and dies on the first conversion.
  deactivate-current-input-method-function,
  deactivate-input-method         renamed from inactivate-* in Emacs 24.3.
                                  Emacs 20 and 21 know the old names only, so
                                  the input method cannot be switched off.

The coding system of the pipe to the agent is set explicitly as well.
anthy-agent-unicode speaks UTF-8 -- src-util/input.c sets
ANTHY_UTF8_ENCODING unconditionally, and --eucjp only reaches the --egg
protocol, which the elisp does not use.  9100h's anthy.el set euc-japan on
the pipe for exactly this reason; anthy-unicode commented that out and left
the Emacs default in charge, which is utf-8 only on a current Emacs.  On
Emacs 21 with the Japanese language environment the default decodes the
agent's replies as euc-jp, and the conversion result arrives as mojibake.

Emacs 20 has no utf-8 coding system at all, and Emacs 21's mule-utf-8 cannot
represent CJK ideographs: it decodes into the mule-unicode-* charsets, which
cover U+0100-U+33FF and U+E000-U+FFFF but not U+4E00-U+9FFF, and
utf-translate-cjk does not exist before Emacs 22.  So the kanji come back as
eight-bit characters, and a .elc compiled from these UTF-8 sources cannot be
read back either, because the compiler writes the mule-unicode internal form
straight into the .elc.  Mule-UCS supplies a utf-8 that maps CJK onto
japanese-jisx0208 and fixes both, so it is loaded when emacs-major-version is
below 22.  The require is wrapped in condition-case, so nothing changes where
Mule-UCS is not installed, and nothing at all happens on Emacs 22 and later.

From Emacs 21 on, the byte compiler warns that the value from mapcar is
unused and suggests mapc or dolist.  The same warning is already raised twice
in this package -- anthy-unicode-azik.el:226 and anthy-unicode-conf.el:108
call mapcar the same way -- so this adds a third of a warning that is already
there, which is the price of keeping Emacs 20 in the accepted list.  Guarding
the one call with fboundp would cost more lines than the warning is worth.

Measured on NetBSD 11.0/amd64 with emacs 20.7, 21.4 and 30.2: with this patch
and Mule-UCS, all three byte-compile the six files, convert nihongo to the
kanji, and deactivate the input method cleanly.  Without it, Emacs 20 stops
at load and Emacs 21 at the first conversion.

--- src-util/anthy-unicode.el.orig
+++ src-util/anthy-unicode.el
@@ -70,12 +70,23 @@
 (defvar anthy-agent-unicode-command-list '("anthy-agent-unicode")
   "anthy-agent-unicodeのPATH 名")
 
+;; Emacs 20 と 21 の utf-8 は CJK を含まない (20 には utf-8 そのものが無い)。
+;; anthy-agent-unicode は UTF-8 で話すので、Mule-UCS があれば載せる。
+(if (and (not (featurep 'xemacs))
+	 (< emacs-major-version 22)
+	 (not (featurep 'un-define)))
+    (condition-case nil
+	(require 'un-define)
+      (error nil)))
+
 ;; face
 (defvar anthy-highlight-face nil)
 (defvar anthy-underline-face nil)
 (copy-face 'highlight 'anthy-highlight-face)
 (if (not (featurep 'xemacs))
-    (set-face-underline 'anthy-highlight-face t))
+    (if (fboundp 'set-face-underline)
+	(set-face-underline 'anthy-highlight-face t)
+      (set-face-underline-p 'anthy-highlight-face t)))
 (copy-face 'underline 'anthy-underline-face)
 
 ;;
@@ -250,7 +261,7 @@
 	(delete-region start (+ start len))
 	(goto-char start)))
   (setq anthy-preedit "")
-  (mapc 'delete-overlay anthy-preedit-overlays)
+  (mapcar 'delete-overlay anthy-preedit-overlays)
   (setq anthy-preedit-overlays nil))
 
 (defun anthy-select-face-by-attr (attr)
@@ -752,7 +763,11 @@
 	(if anthy-agent-unicode-process
 	    (kill-process anthy-agent-unicode-process))
 	(setq anthy-agent-unicode-process proc)
-	(set-process-query-on-exit-flag proc nil)
+	(if (fboundp 'set-process-query-on-exit-flag)
+	    (set-process-query-on-exit-flag proc nil)
+	  (process-kill-without-query proc))
+	(if (coding-system-p 'utf-8)
+	    (set-process-coding-system proc 'utf-8 'utf-8))
 ;;	(if anthy-xemacs
 ;;	    (if (coding-system-p (find-coding-system 'euc-japan))
 ;;		(set-process-coding-system proc 'euc-japan 'euc-japan))
@@ -871,7 +886,9 @@
 ;; leim の activate
 ;;
 (defun anthy-unicode-leim-activate (&optional name)
-  (setq deactivate-current-input-method-function 'anthy-unicode-leim-inactivate)
+  (if (boundp 'deactivate-current-input-method-function)
+      (setq deactivate-current-input-method-function 'anthy-unicode-leim-inactivate)
+    (setq inactivate-current-input-method-function 'anthy-unicode-leim-inactivate))
   (setq anthy-leim-active-p t)
   (anthy-update-mode)
   (when (eq (selected-window) (minibuffer-window))
@@ -881,7 +898,9 @@
 ;; emacsのバグ避けらしいです
 ;;
 (defun anthy-unicode-leim-exit-from-minibuffer ()
-  (deactivate-input-method)
+  (if (fboundp 'deactivate-input-method)
+      (deactivate-input-method)
+    (inactivate-input-method))
   (when (<= (minibuffer-depth) 1)
     (remove-hook 'minibuffer-exit-hook 'anthy-unicode-leim-exit-from-minibuffer)))
 
