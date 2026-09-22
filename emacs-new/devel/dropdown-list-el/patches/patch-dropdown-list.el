$NetBSD$

The selection face inherits from dropdown-list-face, the face the file
defines; dropdown-list is the group, not a face.  From Gentoo.

--- dropdown-list.el.orig
+++ dropdown-list.el
@@ -69,7 +69,7 @@
   "*Bla." :group 'dropdown-list)
 
 (defface dropdown-list-selection-face
-    '((t :inherit dropdown-list :background "purple"))
+    '((t :inherit dropdown-list-face :background "purple"))
   "*Bla." :group 'dropdown-list)
 
 (defvar dropdown-list-overlays nil)
