$NetBSD$

--- lisp/enriched.el.orig	2001-10-29 12:26:42.000000000 +0000
+++ lisp/enriched.el
@@ -119,12 +119,7 @@ expression, which is evaluated to get th
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
@@ -468,35 +463,6 @@ Return value is \(begin end name positiv
 
 
 
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
-	(param (prin1-to-string (or old new)))
-	close open)
-    (if (null old)
-	(list nil (list annotation param))
-      (list (list annotation param)))))
-
-
-(defun enriched-decode-display-prop (start end &optional param)
-  "Decode a `display' property for text between START and END.
-PARAM is a `<param>' found for the property.
-Value is a list `(START END SYMBOL VALUE)' with START and END denoting
-the range of text to assign text property SYMBOL with value VALUE "
-  (let ((prop (when (stringp param)
-		(condition-case ()
-		    (car (read-from-string param))
-		  (error nil)))))
-    (unless prop
-      (message "Warning: invalid <x-display> parameter %s" param))
-    (list start end 'display prop)))
 	       
 	   
 ;;; enriched.el ends here
