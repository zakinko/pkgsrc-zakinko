$NetBSD$

ruby-mode builds a shell command out of a name typed at a prompt, so a name
holding shell metacharacters runs commands.  This is CVE-2022-48338, upstream
commit

	22fb5ff512  Fix ruby-mode.el local command injection vulnerability

on the emacs-28 branch, for the 28.3 release that was never made.  Taken
unchanged.  See debbugs 60268.

--- lisp/progmodes/ruby-mode.el.orig
+++ lisp/progmodes/ruby-mode.el
@@ -1820,7 +1820,7 @@
       (setq feature-name (read-string "Feature name: " init))))
   (let ((out
          (substring
-          (shell-command-to-string (concat "gem which " feature-name))
+          (shell-command-to-string (concat "gem which " (shell-quote-argument feature-name)))
           0 -1)))
     (if (string-match-p "\\`ERROR" out)
         (user-error "%s" out)
