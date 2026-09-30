$NetBSD$

Restore what upstream removed on 2020-06-25 ("Drop old platforms support"),
so APEL still serves Emacs 20 and XEmacs; pkgsrc has packages that need
it there (misc/lookup, devel/flim, devel/semi).  The functional changes
made upstream since are kept.

--- mcs-20.el.orig
+++ mcs-20.el
@@ -1,4 +1,4 @@
-;;; mcs-20.el --- MIME charset implementation for Emacs 20 and XEmacs/mule  -*- lexical-binding: t -*-
+;;; mcs-20.el --- MIME charset implementation for Emacs 20 and XEmacs/mule
 
 ;; Copyright (C) 1997,1998,1999,2000 Free Software Foundation, Inc.
 
@@ -28,8 +28,14 @@
 ;;    or later.
 
 ;;; Code:
-(require 'subr-x)
-(require 'wid-edit)
+
+(require 'custom)
+(require 'pces)
+(eval-when-compile (require 'wid-edit))
+
+(if (featurep 'xemacs)
+    (require 'mcs-xm)
+  (require 'mcs-e20))
 
 
 ;;; @ MIME charset
@@ -51,8 +57,10 @@
 	   ))
 	dest)
     (while rest
-      (unless (coding-system-p (caar rest))
-	(setq dest (cons (car rest) dest)))
+      (let ((pair (car rest)))
+	(or (find-coding-system (car pair))
+	    (setq dest (cons pair dest))
+	    ))
       (setq rest (cdr rest))
       )
     dest)
@@ -78,7 +86,7 @@ is specified, it is used as line break code type of coding-system."
       (setq charset (intern (downcase charset)))
     )
   (let ((cs (cdr (assq charset mime-charset-coding-system-alist))))
-    (unless (or (null cs) (coding-system-p cs))
+    (unless (or (null cs) (find-coding-system cs))
       (message
        "Invalid coding system: %s.  Confirm mime-charset-coding-system-alist."
        cs)
@@ -91,15 +99,11 @@ is specified, it is used as line break code type of coding-system."
 				       ((eq lbt 'CR) 'mac)
 				       (t lbt)))))
       )
-    (if (coding-system-p cs)
-	cs
-      (when mime-charset-to-coding-system-default-method
-	(funcall mime-charset-to-coding-system-default-method
-		 charset lbt cs)
-	))))
-
-(provide 'mcs-20)
-(require 'mcs-e20)
+    (or (find-coding-system cs)
+	(if mime-charset-to-coding-system-default-method
+	    (funcall mime-charset-to-coding-system-default-method
+		     charset lbt cs)
+	  ))))
 
 (defalias 'mime-charset-p 'mime-charset-to-coding-system)
 
@@ -114,12 +118,13 @@ is specified, it is used as line break code type of coding-system."
   :prompt-value 'widget-mime-charset-prompt-value
   :action 'widget-mime-charset-action)
 
-(defun widget-mime-charset-prompt-value (_widget prompt value _unbound)
+(defun widget-mime-charset-prompt-value (widget prompt value unbound)
   ;; Read mime-charset from minibuffer.
   (intern
    (completing-read (format "%s (default %s) " prompt value)
-		    (mapcar (lambda (sym)
-			      (list (symbol-name sym)))
+		    (mapcar (function
+			     (lambda (sym)
+			       (list (symbol-name sym))))
 			    (mime-charset-list)))))
 
 (defun widget-mime-charset-action (widget &optional event)
@@ -141,17 +146,82 @@ It must be symbol."
   :group 'i18n
   :type 'mime-charset)
 
+(cond ((featurep 'utf-2000)
+;; for CHISE Architecture
+(defun mcs-region-repertoire-p (start end charsets &optional buffer)
+  (save-excursion
+    (if buffer
+	(set-buffer buffer))
+    (save-restriction
+      (narrow-to-region start end)
+      (goto-char (point-min))
+      (catch 'tag
+	(let (ch)
+	  (while (not (eobp))
+	    (setq ch (char-after (point)))
+	    (unless (some (lambda (ccs)
+			    (encode-char ch ccs))
+			  charsets)
+	      (throw 'tag nil))
+	    (forward-char)))
+	t))))
+
+(defun mcs-string-repertoire-p (string charsets &optional start end)
+  (let ((i (if start
+	       (if (< start 0)
+		   (error 'args-out-of-range string start end)
+		 start)
+	     0))
+	ch)
+    (if end
+	(if (> end (length string))
+	    (error 'args-out-of-range string start end))
+      (setq end (length string)))
+    (catch 'tag
+      (while (< i end)
+	(setq ch (aref string i))
+	(unless (some (lambda (ccs)
+			(encode-char ch ccs))
+		      charsets)
+	  (throw 'tag nil))
+	(setq i (1+ i)))
+      t)))
+
+(defun detect-mime-charset-region (start end)
+  "Return MIME charset for region between START and END."
+  (let ((rest charsets-mime-charset-alist)
+	cell)
+    (catch 'tag
+      (while rest
+	(setq cell (car rest))
+	(if (mcs-region-repertoire-p start end (car cell))
+	    (throw 'tag (cdr cell)))
+	(setq rest (cdr rest)))
+      default-mime-charset-for-write)))
+
+(defun detect-mime-charset-string (string)
+  "Return MIME charset for STRING."
+  (let ((rest charsets-mime-charset-alist)
+	cell)
+    (catch 'tag
+      (while rest
+	(setq cell (car rest))
+	(if (mcs-string-repertoire-p string (car cell))
+	    (throw 'tag (cdr cell)))
+	(setq rest (cdr rest)))
+      default-mime-charset-for-write)))
+)
+
+((eval-when-compile (and (boundp 'mule-version)
+			 (null (string< mule-version "6.0"))))
+;; for Emacs 23 and later
 (defcustom detect-mime-charset-from-coding-system nil
-  "When non-nil, `detect-mime-charset-region' and `detect-mime-charset-string'
-functions decide charset by encodability in destination coding system.
+  "When non-nil, `detect-mime-charset-region' and `detect-mime-charset-string' functions decide charset by encodability in destination coding system.
 
 In that case, each car of `charsets-mime-charset-alist' element is ignored."
   :group 'i18n
   :type 'boolean)
 
-(provide 'mcs-20)
-(require 'mcharset)
-
 (defun detect-mime-charset-list (chars)
   "Return MIME charset for the list of characters CHARS."
   (catch 'found
@@ -165,11 +235,9 @@ In that case, each car of `charsets-mime-charset-alist' element is ignored."
     default-mime-charset-for-write))
 
 (defun detect-mime-charset-from-coding-system (start end &optional string)
-  "Return MIME charset for the region between START and END,
-deciding by encodability in destination coding system.
+  "Return MIME charset for the region between START and END, deciding by encodability in destination coding system.
 
-Optional 3rd argument STRING is non-nil, detect MIME charset from STRING.
-In that case, START and END are indexes of the string."
+Optional 3rd argument STRING is non-nil, detect MIME charset from STRING.  In that case, START and END are indexes of the string."
   (let ((alist charsets-mime-charset-alist)
 	result)
     (while alist
@@ -183,29 +251,44 @@ In that case, START and END are indexes of the string."
 (defun detect-mime-charset-string (string)
   "Return MIME charset for STRING.
 
-When `detect-mime-charset-from-coding-system' is non-nil,
-each car of `charsets-mime-charset-alist' element is ignored."
+When `detect-mime-charset-from-coding-system' is non-nil, each car of `charsets-mime-charset-alist' element is ignored."
   (if detect-mime-charset-from-coding-system
       (detect-mime-charset-from-coding-system 0 (length string) string)
-    (let ((table (make-hash-table :test 'eq)))
-      (mapc (lambda (ch) (puthash ch t table))
+    (let (list)
+      (mapc (lambda (ch) (unless (memq ch list)
+			   (setq list (cons ch list))))
 	    string)
-      (detect-mime-charset-list (hash-table-keys table)))))
+      (detect-mime-charset-list list))))
 
 (defun detect-mime-charset-region (start end)
   "Return MIME charset for region between START and END.
 
-When `detect-mime-charset-from-coding-system' is non-nil,
-each car of `charsets-mime-charset-alist' element is ignored."
+When `detect-mime-charset-from-coding-system' is non-nil, each car of `charsets-mime-charset-alist' element is ignored."
   (if detect-mime-charset-from-coding-system
       (detect-mime-charset-from-coding-system start end)
     (let ((point (min start end))
-	  (table (make-hash-table :test 'eq)))
+	  list)
       (setq end (max start end))
       (while (< point end)
-	(puthash (char-after point) t table)
+	(unless (memq (char-after point) list)
+	  (setq list (cons (char-after point) list)))
 	(setq point (1+ point)))
-      (detect-mime-charset-list (hash-table-keys table)))))
+      (detect-mime-charset-list list)))))
+
+(t
+;; for legacy Mule
+(defun detect-mime-charset-region (start end)
+  "Return MIME charset for region between START and END."
+  (find-mime-charset-by-charsets (find-charset-region start end)
+				 'region start end))
+
+;; FLIM's eword-encode has called this since 2020; the old branch never
+;; had it, only the region version.
+(defun detect-mime-charset-string (string)
+  "Return MIME charset for STRING."
+  (find-mime-charset-by-charsets (find-charset-string string)
+				 'string string))
+))
 
 (defun write-region-as-mime-charset (charset start end filename
 					     &optional append visit lockname)
