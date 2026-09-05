$NetBSD$

enriched-mode's translation table maps the text/enriched annotation
<x-display> onto enriched-decode-display-prop, which reads its parameter with
read-from-string and installs the result as a display property.  Gnus decodes
text/enriched and text/richtext parts with it, so a display property of the
sender's choosing lands in the article buffer, and a display property can name
a function to run.  This is CVE-2017-14482, upstream commit

	9ad0fcc544  Remove unsafe enriched mode translations

released in 25.3.  See debbugs 28350.

The fix removes the feature rather than validating the parameter: the
FUNCTION and display entries go out of enriched-translations, the two
functions behind them go, and mm-view stops calling enriched-decode at all.
editors/emacs21 carries the same change as patch-CVE-2017-14482.

--- lisp/textmodes/enriched.el.orig
+++ lisp/textmodes/enriched.el
@@ -120,12 +120,7 @@
 		   (full        "flushboth")
 		   (center      "center"))
     (PARAMETER     (t           "param")) ; Argument of preceding annotation
-    ;; The following are not part of the standard:
-    (FUNCTION      (enriched-decode-foreground "x-color")
-		   (enriched-decode-background "x-bg-color")
-		   (enriched-decode-display-prop "x-display"))
     (read-only     (t           "x-read-only"))
-    (display	   (nil		enriched-handle-display-prop))
     (unknown       (nil         format-annotate-value))
 ;   (font-size     (2           "bigger")       ; unimplemented
 ;		   (-2          "smaller"))
@@ -475,34 +470,6 @@
       (list from to 'face (list ':background color))
     (message "Warning: no color specified for <x-bg-color>")
     nil))
-
-;;; Handling the `display' property.
-
-
-(defun enriched-handle-display-prop (old new)
-  "Return a list of annotations for a change in the `display' property.
-OLD is the old value of the property, NEW is the new value.  Value
-is a list `(CLOSE OPEN)', where CLOSE is a list of annotations to
-close and OPEN a list of annotations to open.  Each of these lists
-has the form `(ANNOTATION PARAM ...)'."
-  (let ((annotation "x-display")
-	(param (prin1-to-string (or old new))))
-    (if (null old)
-        (cons nil (list (list annotation param)))
-      (cons (list (list annotation param)) nil))))
-
-(defun enriched-decode-display-prop (start end &optional param)
-  "Decode a `display' property for text between START and END.
-PARAM is a `<param>' found for the property.
-Value is a list `(START END SYMBOL VALUE)' with START and END denoting
-the range of text to assign text property SYMBOL with value VALUE."
-  (let ((prop (when (stringp param)
-		(condition-case ()
-		    (car (read-from-string param))
-		  (error nil)))))
-    (unless prop
-      (message "Warning: invalid <x-display> parameter %s" param))
-    (list start end 'display prop)))
 
 ;;; arch-tag: 05cae488-3fea-45cd-ac29-5b02cb64e42b
 ;;; enriched.el ends here
