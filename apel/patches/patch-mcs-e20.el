$NetBSD$

Restore what upstream removed on 2020-06-25 ("Drop old platforms support"),
so APEL still serves Emacs 20 and XEmacs; pkgsrc has packages that need
it there (misc/lookup, devel/flim, devel/semi).  The functional changes
made upstream since are kept.

--- mcs-e20.el.orig
+++ mcs-e20.el
@@ -1,4 +1,4 @@
-;;; mcs-e20.el --- MIME charset implementation for Emacs 20.1 and 20.2  -*- lexical-binding: t -*-
+;;; mcs-e20.el --- MIME charset implementation for Emacs 20.1 and 20.2
 
 ;; Copyright (C) 1996,1997,1998,1999,2000 Free Software Foundation, Inc.
 
@@ -28,8 +28,8 @@
 
 ;;; Code:
 
-(provide 'mcs-e20)
-(require 'mcs-20)
+(require 'pces)
+(eval-when-compile (require 'static))
 
 (defsubst encode-mime-charset-region (start end charset &optional lbt)
   "Encode the text between START and END as MIME CHARSET."
@@ -66,46 +66,59 @@
 
 
 (defvar charsets-mime-charset-alist
-  '(((ascii)						. us-ascii)
-    ((ascii latin-iso8859-1)				. iso-8859-1)
-    ((ascii latin-iso8859-2)				. iso-8859-2)
-    ((ascii latin-iso8859-3)				. iso-8859-3)
-    ((ascii latin-iso8859-4)				. iso-8859-4)
-    ((ascii latin-iso8859-15)				. iso-8859-15)
-    ;; ((ascii cyrillic-iso8859-5)			. iso-8859-5)
-    ((ascii cyrillic-iso8859-5)			. koi8-r)
-    ((ascii arabic-iso8859-6)				. iso-8859-6)
-    ((ascii greek-iso8859-7)				. iso-8859-7)
-    ((ascii hebrew-iso8859-8)				. iso-8859-8)
-    ((ascii latin-iso8859-9)				. iso-8859-9)
-    ((ascii latin-iso8859-14)				. iso-8859-14)
-    ((ascii latin-jisx0201
-	    japanese-jisx0208-1978 japanese-jisx0208)	. iso-2022-jp)
-    ((ascii latin-jisx0201
-	    katakana-jisx0201 japanese-jisx0208)	. shift_jis)
-    ((ascii korean-ksc5601)				. euc-kr)
-    ((ascii chinese-gb2312)				. gb2312)
-    ((ascii chinese-big5-1 chinese-big5-2)		. big5)
-    ((ascii thai-tis620)				. tis-620)
-    ;; ((ascii latin-iso8859-1 greek-iso8859-7
-    ;; 	     latin-jisx0201 japanese-jisx0208-1978
-    ;; 	     chinese-gb2312 japanese-jisx0208
-    ;; 	     korean-ksc5601 japanese-jisx0212)		. iso-2022-jp-2)
-    ;;((ascii latin-iso8859-1 greek-iso8859-7
-    ;;        latin-jisx0201 japanese-jisx0208-1978
-    ;;        chinese-gb2312 japanese-jisx0208
-    ;;        korean-ksc5601 japanese-jisx0212
-    ;;        chinese-cns11643-1 chinese-cns11643-2)	. iso-2022-int-1)
-    ;;((ascii latin-iso8859-1 latin-iso8859-2
-    ;;        cyrillic-iso8859-5 greek-iso8859-7
-    ;;        latin-jisx0201 japanese-jisx0208-1978
-    ;;        chinese-gb2312 japanese-jisx0208
-    ;;        korean-ksc5601 japanese-jisx0212
-    ;;        chinese-cns11643-1 chinese-cns11643-2
-    ;;        chinese-cns11643-3 chinese-cns11643-4
-    ;;        chinese-cns11643-5 chinese-cns11643-6
-    ;;        chinese-cns11643-7)			. iso-2022-int-1)
-    ))
+  (delq
+   nil
+   `(((ascii)						. us-ascii)
+     ((ascii latin-iso8859-1)				. iso-8859-1)
+     ((ascii latin-iso8859-2)				. iso-8859-2)
+     ((ascii latin-iso8859-3)				. iso-8859-3)
+     ((ascii latin-iso8859-4)				. iso-8859-4)
+     ,(if (find-coding-system 'iso-8859-15)
+	  '((ascii latin-iso8859-15)			. iso-8859-15))
+     ;;((ascii cyrillic-iso8859-5)			. iso-8859-5)
+     ((ascii cyrillic-iso8859-5)			. koi8-r)
+     ((ascii arabic-iso8859-6)				. iso-8859-6)
+     ((ascii greek-iso8859-7)				. iso-8859-7)
+     ((ascii hebrew-iso8859-8)				. iso-8859-8)
+     ((ascii latin-iso8859-9)				. iso-8859-9)
+     ,(if (find-coding-system 'iso-8859-14)
+	  '((ascii latin-iso8859-14)			. iso-8859-14))
+     ((ascii latin-jisx0201
+	     japanese-jisx0208-1978 japanese-jisx0208)	. iso-2022-jp)
+     ((ascii latin-jisx0201
+	     katakana-jisx0201 japanese-jisx0208)	. shift_jis)
+     ((ascii korean-ksc5601)				. euc-kr)
+     ((ascii chinese-gb2312)				. gb2312)
+     ((ascii chinese-big5-1 chinese-big5-2)		. big5)
+     ,(static-cond
+       ((null (string< mule-version "6.0"))
+	'((ascii thai-tis620)				. tis-620))
+       (t
+	'((ascii thai-tis620 composition)      		. tis-620)))
+     ;; ((ascii latin-iso8859-1 greek-iso8859-7
+     ;; 	     latin-jisx0201 japanese-jisx0208-1978
+     ;; 	     chinese-gb2312 japanese-jisx0208
+     ;; 	     korean-ksc5601 japanese-jisx0212)		. iso-2022-jp-2)
+     ;;((ascii latin-iso8859-1 greek-iso8859-7
+     ;;        latin-jisx0201 japanese-jisx0208-1978
+     ;;        chinese-gb2312 japanese-jisx0208
+     ;;        korean-ksc5601 japanese-jisx0212
+     ;;        chinese-cns11643-1 chinese-cns11643-2)	. iso-2022-int-1)
+     ;;((ascii latin-iso8859-1 latin-iso8859-2
+     ;;        cyrillic-iso8859-5 greek-iso8859-7
+     ;;        latin-jisx0201 japanese-jisx0208-1978
+     ;;        chinese-gb2312 japanese-jisx0208
+     ;;        korean-ksc5601 japanese-jisx0212
+     ;;        chinese-cns11643-1 chinese-cns11643-2
+     ;;        chinese-cns11643-3 chinese-cns11643-4
+     ;;        chinese-cns11643-5 chinese-cns11643-6
+     ;;        chinese-cns11643-7)			. iso-2022-int-1)
+     )))
+
+(defun-maybe coding-system-get (coding-system prop)
+  "Extract a value from CODING-SYSTEM's property list for property PROP."
+  (plist-get (coding-system-plist coding-system) prop)
+  )
 
 (defvar coding-system-to-mime-charset-exclude-regexp
   "^unknown$\\|^x-")
@@ -127,18 +140,55 @@ Return nil if corresponding MIME-charset is not found."
 				   (symbol-name result)))
 	  result))))
 
-(defun mime-charset-list ()
+(defun-maybe-cond mime-charset-list ()
   "Return a list of all existing MIME-charset."
-  (let ((dest (mapcar (function car) mime-charset-coding-system-alist))
-	(rest coding-system-list)
-	cs)
-    (while rest
-      (setq cs (car rest))
-      (when (and (setq cs (coding-system-get cs 'mime-charset))
-		 (null (memq cs dest)))
-	(setq dest (cons cs dest)))
-      (setq rest (cdr rest)))
-    dest))
+  ((boundp 'coding-system-list)
+   (let ((dest (mapcar (function car) mime-charset-coding-system-alist))
+	 (rest coding-system-list)
+	 cs)
+     (while rest
+       (setq cs (car rest))
+       (when (and (setq cs (coding-system-get cs 'mime-charset))
+		  (null (memq cs dest)))
+	 (setq dest (cons cs dest)))
+       (setq rest (cdr rest)))
+     dest))
+   (t
+    (let ((dest (mapcar (function car) mime-charset-coding-system-alist))
+	  (rest (coding-system-list))
+	  cs)
+      (while rest
+	(setq cs (car rest))
+	(unless (rassq cs mime-charset-coding-system-alist)
+	  (when (setq cs (or (coding-system-get cs 'mime-charset)
+			     (and
+			      (setq cs (aref
+					(coding-system-get cs 'coding-spec)
+					2))
+			      (string-match "(MIME:[ \t]*\\([^,)]+\\)" cs)
+			      (match-string 1 cs))))
+	    (setq cs (intern (downcase cs)))
+	    (unless (memq cs dest)
+	      (setq dest (cons cs dest))
+	      )))
+	(setq rest (cdr rest)))
+      dest)
+    ))
+
+(static-when (and (string= (decode-coding-string "\e.A\eN!" 'ctext) "\eN!")
+		  (or (not (find-coding-system 'x-ctext))
+		      (coding-system-get 'x-ctext 'apel)))
+  (unless (find-coding-system 'x-ctext)
+    (make-coding-system
+     'x-ctext 2 ?x
+     "Compound text based generic encoding for decoding unknown messages."
+     '((ascii t) (latin-iso8859-1 t) t t
+       nil ascii-eol ascii-cntl nil locking-shift single-shift nil nil nil
+       init-bol nil nil)
+     '((safe-charsets . t)
+       (mime-charset . x-ctext)))
+    (coding-system-put 'x-ctext 'apel t)
+    ))
 
 
 ;;; @ end
