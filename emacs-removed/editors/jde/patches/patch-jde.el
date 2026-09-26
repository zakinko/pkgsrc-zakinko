$NetBSD$

Only add the JDE New menu when the menu bar has a Files menu.  Under
-batch there is none, (cdr (cdr files)) is nil, and define-key-after
stopped the byte-compile with wrong-type-argument keymapp nil.

--- jde.el.orig
+++ jde.el
@@ -1174,9 +1174,10 @@
 			     (easy-menu-create-menu 
 			      (car val) (cdr val))))
 		   (menu-name (car val)))
-	      (define-key-after (cdr (cdr files)) [jde-new]
-		(cons menu-name menu)
-		'open-file)))))
+	      (if files
+		  (define-key-after (cdr (cdr files)) [jde-new]
+		    (cons menu-name menu)
+		    'open-file))))))
 
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;                                                                            ;;
