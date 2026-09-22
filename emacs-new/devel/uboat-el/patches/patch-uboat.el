$NetBSD$

interactive-p was removed in Emacs 24.  From Gentoo.

--- uboat.el.orig
+++ uboat.el
@@ -79,7 +79,7 @@
   (let ((s (concat (uboat-iterate-list (uboat-random-member uboat-message)
                                        "uboat-")
                    " U-" (int-to-string (random 999)) ".")))
-    (and (interactive-p)
+    (and (called-interactively-p 'interactive)
          (message "%s" s))
     s))
 
