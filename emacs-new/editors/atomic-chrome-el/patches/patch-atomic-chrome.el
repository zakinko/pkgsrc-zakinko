$NetBSD$

C-x C-s in the edit buffer was shadowed; the save binding is C-c C-s
now.  Upstream commit ae2a6158 (issue 56), via Debian.

--- atomic-chrome.el.orig
+++ atomic-chrome.el
@@ -71,8 +71,8 @@
   :group 'atomic-chrome)
 
 (defcustom atomic-chrome-enable-auto-update t
-  "If non-nil, edit on Emacs is reflected to Chrome instantly, \
-otherwise you need to type \"C-xC-s\" manually."
+  "If non-nil, edit on Emacs is reflected to the browser instantly, \
+otherwise you need to type \"C-cC-s\" manually."
   :type 'boolean
   :group 'atomic-chrome)
 
@@ -243,7 +243,7 @@ where FRAME show raw data received."
 
 (defvar atomic-chrome-edit-mode-map
   (let ((map (make-sparse-keymap)))
-    (define-key map (kbd "C-x C-s") 'atomic-chrome-send-buffer-text)
+    (define-key map (kbd "C-c C-s") 'atomic-chrome-send-buffer-text)
     (define-key map (kbd "C-c C-c") 'atomic-chrome-close-current-buffer)
     map)
   "Keymap for minor mode `atomic-chrome-edit-mode'.")
