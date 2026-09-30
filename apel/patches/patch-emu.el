$NetBSD$

Restore what upstream removed on 2020-06-25 ("Drop old platforms support"),
so APEL still serves Emacs 20 and XEmacs; pkgsrc has packages that need
it there (misc/lookup, devel/flim, devel/semi).  The functional changes
made upstream since are kept.

--- emu.el.orig
+++ emu.el
@@ -27,10 +27,11 @@
 (require 'poe)
 
 (defvar running-emacs-18 nil)
-(defvar running-xemacs nil)
+(defvar running-xemacs (featurep 'xemacs))
 
-(defvar running-mule-merged-emacs t)
-(defvar running-xemacs-with-mule nil)
+(defvar running-mule-merged-emacs (and (not (boundp 'MULE))
+				       (not running-xemacs) (featurep 'mule)))
+(defvar running-xemacs-with-mule (and running-xemacs (featurep 'mule)))
 
 (defvar running-emacs-19 nil)
 (defvar running-emacs-19_29-or-later t)
@@ -39,10 +40,18 @@
 (defvar running-xemacs-20-or-later running-xemacs)
 (defvar running-xemacs-19_14-or-later running-xemacs-20-or-later)
 
-;; mouse
-(defvar mouse-button-1 [mouse-1])
-(defvar mouse-button-2 [mouse-2])
-(defvar mouse-button-3 [down-mouse-3])
+(cond (running-xemacs
+       ;; for XEmacs
+       (defvar mouse-button-1 'button1)
+       (defvar mouse-button-2 'button2)
+       (defvar mouse-button-3 'button3)
+       )
+      (t
+       ;; mouse
+       (defvar mouse-button-1 [mouse-1])
+       (defvar mouse-button-2 [mouse-2])
+       (defvar mouse-button-3 [down-mouse-3])
+       ))
 
 (require 'poem)
 (require 'mcharset)
@@ -52,15 +61,58 @@
   "Convert list of character CHAR-LIST to string."
   (apply (function string) char-list))
 
-(defalias 'insert-binary-file-contents-literally
-  'insert-file-contents-literally)
+(cond ((featurep 'mule)
+       (cond ((featurep 'xemacs) ; for XEmacs with MULE
+	      ;; old Mule emulating aliases
 
-;; old Mule emulating aliases
-(defun char-category (character)
-  "Return string of category mnemonics for CHAR in TABLE.
+	      ;;(defalias 'char-leading-char 'char-charset)
+
+	      (defun char-category (character)
+		"Return string of category mnemonics for CHAR in TABLE.
+CHAR can be any multilingual character
+TABLE defaults to the current buffer's category table."
+		(mapconcat (lambda (chr)
+			     (if (integerp chr)
+				 (char-to-string (int-char chr))
+			       (char-to-string chr)))
+			   ;; `char-category-list' returns a list of
+			   ;; characters in XEmacs 21.2.25 and later,
+			   ;; otherwise integers.
+			   (char-category-list character)
+			   ""))
+	      )
+	     (t ; for Emacs 20
+	      (defalias 'insert-binary-file-contents-literally
+		'insert-file-contents-literally)
+	      
+	      ;; old Mule emulating aliases
+	      (defun char-category (character)
+		"Return string of category mnemonics for CHAR in TABLE.
 CHAR can be any multilingual character
 TABLE defaults to the current buffer's category table."
-  (category-set-mnemonics (char-category-set character)))
+		(category-set-mnemonics (char-category-set character)))
+	      ))
+       )
+      (t
+       ;; for Emacs 19 and XEmacs without MULE
+       
+       ;; old MULE emulation
+       (defconst *internal* nil)
+       (defconst *ctext* nil)
+       (defconst *noconv* nil)
+       
+       (defun code-convert-string (str ic oc)
+	 "Convert code in STRING from SOURCE code to TARGET code,
+On successful conversion, returns the result string,
+else returns nil. [emu-latin1.el; old MULE emulating function]"
+	 str)
+
+       (defun code-convert-region (beg end ic oc)
+	 "Convert code of the text between BEGIN and END from SOURCE
+to TARGET. On successful conversion returns t,
+else returns nil. [emu-latin1.el; old MULE emulating function]"
+	 t)
+       ))
 
 
 ;;; @ Mule emulating aliases
@@ -81,6 +133,18 @@ It is obsolete, so don't use it."))
 (make-obsolete 'insert-binary-file-contents 'insert-file-contents-as-binary
 	       "17 Sep 1998")
 
+(defun-maybe insert-binary-file-contents-literally (filename
+						    &optional visit
+						    beg end replace)
+  "Like `insert-file-contents-literally', q.v., but don't code conversion.
+A buffer may be modified in several ways after reading into the buffer due
+to advanced Emacs features, such as file-name-handlers, format decoding,
+find-file-hooks, etc.
+  This function ensures that none of these modifications will take place."
+  (as-binary-input-file
+   ;; Returns list absolute file name and length of data inserted.
+   (insert-file-contents-literally filename visit beg end replace)))
+
 
 ;;; @ end
 ;;;
