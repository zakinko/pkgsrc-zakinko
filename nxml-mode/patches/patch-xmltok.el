$NetBSD$

Emacs 20's regexp engine has no shy groups and no [:alpha:] classes.
The tokenizer builds its regexps from symbolic pieces, so a numbered
group with a placeholder name keeps the named groups' indices right,
and the character classes are spelled out as the ASCII characters that
are not names plus everything non-ASCII.

--- xmltok.el.orig
+++ xmltok.el
@@ -392,9 +392,15 @@
 	     (cons (concat "\\(" ,sym "\\)") (cons ',name nil))
 	   (cons (concat "\\(" (car ,sym) "\\)") (cons ',name (cdr ,sym)))))))
 
-  (defun xmltok-p (&rest r) (xmltok+ "\\(?:" 
-				     (apply 'xmltok+ r)
-				     "\\)"))
+  ;; Emacs 20 has no shy groups: use a numbered group there and give it a
+  ;; placeholder name, so the indices of the named groups stay right.
+  (defconst xmltok-shy-groups-p (>= emacs-major-version 21))
+  (defun xmltok-p (&rest r)
+    (let ((x (apply (quote xmltok+) r)))
+      (if xmltok-shy-groups-p
+	  (xmltok+ "\\(?:" x "\\)")
+	(cons (concat "\\(" (if (stringp x) x (car x)) "\\)")
+	      (cons (make-symbol "shy") (if (stringp x) nil (cdr x)))))))
 
   ;; Get the group index of ELEM in a LIST of symbols.
   (defun xmltok-get-index (elem list)
@@ -447,12 +453,15 @@
 
 (eval-when-compile
   (let* ((or "\\|")
-	 (open "\\(?:")
+	 (open (if xmltok-shy-groups-p "\\(?:" (cons "\\(" (list (make-symbol "shy")))))
 	 (gopen "\\(")
 	 (close "\\)")
-	 (name-start-char "[_[:alpha:]]")
-	 (name-continue-not-start-char "[-.[:digit:]]")
-	 (name-continue-char "[-._[:alnum:]]")
+	 ;; Emacs 20 has no [:alpha:]; the negated classes below list the ASCII
+	 ;; characters that are not allowed, so every non-ASCII character passes,
+	 ;; which is what [:alpha:] gives on a multibyte buffer.
+	 (name-start-char (if xmltok-shy-groups-p "[_[:alpha:]]" "[^\000-\100\133-\136\140\173-\177]"))
+	 (name-continue-not-start-char "[-.0-9]")
+	 (name-continue-char (if xmltok-shy-groups-p "[-._[:alnum:]]" "[^\000-\054\057\072-\100\133-\136\140\173-\177]"))
 	 (* "*")
 	 (+ "+")
 	 (opt "?")
@@ -550,7 +559,7 @@
      xmltok-xml-declaration
      (let* ((literal-content "[-._:a-zA-Z0-9]+")
 	    (literal
-	     (concat open "\"" literal-content "\""
+	     (xmltok+ open "\"" literal-content "\""
 		     or "'" literal-content "'" close))
 	    (version-att
 	     (xmltok+ open
@@ -565,7 +574,7 @@
 		      s* (xmltok-g encoding-value literal)
 		      close opt))
 	   (yes-no
-	    (concat open "yes" or "no" close))
+	    (xmltok+ open "yes" or "no" close))
 	   (standalone-att
 	    (xmltok+ open
 		     s+ (xmltok-g standalone-name "standalone")
@@ -1153,7 +1162,9 @@
     (nreverse xmltok-prolog-regions)))
 
 (defconst xmltok-bad-xml-decl-regexp
-  "[ \t\r\n]*<\\?xml\\(?:[ \t\r\n]\\|\\?>\\)")
+  (if (>= emacs-major-version 21)
+      "[ \t\r\n]*<\\?xml\\(?:[ \t\r\n]\\|\\?>\\)"
+    "[ \t\r\n]*<\\?xml\\([ \t\r\n]\\|\\?>\\)"))
 
 ;;;###autoload
 (defun xmltok-get-declared-encoding-position (&optional limit)
