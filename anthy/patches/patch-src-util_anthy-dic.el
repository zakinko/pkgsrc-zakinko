$NetBSD$

string-to-int was an obsolete alias for string-to-number and was removed in
Emacs 26.  string-to-number has existed since Emacs 19.28, so the calls are
renamed rather than guarded.

The new style `(...) backquote does not exist in the Emacs 19.28 reader that
Mule 2.3 is built on, so the eleven uses here are written with list and
quote, which every version reads.

anthy.el sets anthy-xemacs and requires this file; this file cannot require
it back, so the variable is declared here to keep the byte compiler quiet.
find-coding-system is XEmacs only and is reached only when anthy-xemacs is
true, so it goes through a variable for the same reason.

See patch-src-util_anthy.el for the rest of this.

--- src-util/anthy-dic.el.orig
+++ src-util/anthy-dic.el
@@ -1,4 +1,4 @@
-;; anthy-dic.el -- Anthy
+;; anthy-dic.el -- Anthy  -*- lexical-binding: nil -*-
 
 ;; Copyright (C) 2001 - 2005
 ;; Author: Yusuke Tabata<yusuke@w5.dion.ne.jp>
@@ -17,6 +17,15 @@
 (defvar anthy-dic-util-command "anthy-dic-tool")
 (defvar anthy-dic-buffer-name " *anthy-dic*")
 
+;; Declared, not defined: anthy.el sets both before it requires this file.
+;; anthy-dic.el cannot require anthy.el back, so without these the byte
+;; compiler reports a free variable and an unknown function.
+(defvar anthy-xemacs)
+;; find-coding-system is XEmacs only and is reached only when anthy-xemacs is
+;; true.  Named through a variable so a GNU Emacs byte compiler does not report
+;; it as not known to be defined.
+(defvar anthy-find-coding-system-function 'find-coding-system)
+
 (defun anthy-add-word-compose-paramlist (param)
   (let ((str ""))
     (while param
@@ -37,7 +46,9 @@
     (if proc
 	(progn
 	  (if anthy-xemacs
-	      (if (coding-system-p (find-coding-system 'euc-japan))
+;	      (if (coding-system-p (find-coding-system 'euc-japan))
+	      (if (coding-system-p
+		   (funcall anthy-find-coding-system-function 'euc-japan))
 		  (set-process-coding-system proc 'euc-japan 'euc-japan))
 	    (cond ((coding-system-p 'euc-japan)
 		   (set-process-coding-system proc 'euc-japan 'euc-japan))
@@ -60,17 +71,17 @@
        (suru (y-or-n-p (concat "「" word "する」と言いますか? ")))
        (ind (y-or-n-p (concat "「" word "」は単独で文節になりますか? ")))
        (kaku (y-or-n-p (concat "「" word "と」と言いますか? "))))
-    (setq res (cons `("な接続" ,na) res))
-    (setq res (cons `("さ接続" ,sa) res))
-    (setq res (cons `("する接続" ,suru) res))
-    (setq res (cons `("語幹のみで文節" ,ind) res))
-    (setq res (cons `("格助詞接続" ,kaku) res))
+    (setq res (cons (list "な接続" na) res))
+    (setq res (cons (list "さ接続" sa) res))
+    (setq res (cons (list "する接続" suru) res))
+    (setq res (cons (list "語幹のみで文節" ind) res))
+    (setq res (cons (list "格助詞接続" kaku) res))
     res))
 
 (defun anthy-dic-get-special-noun-category (word)
   (let 
       ((res '())
-       (cat (string-to-int
+       (cat (string-to-number
 	     (read-from-minibuffer "1:人名 2:地名: "))))
     (cond ((= cat 1)
 	   (setq res '(("品詞" "人名"))))
@@ -88,18 +99,18 @@
        (taru (y-or-n-p (concat "「" word "たる」と言いますか?")))
        (suru (y-or-n-p (concat "「" word "する」と言いますか?")))
        (ind (y-or-n-p (concat "「" word "」は単独で文節になりますか?"))))
-    (setq res (cons `("と接続" ,to) res))
-    (setq res (cons `("たる接続" ,taru) res))
-    (setq res (cons `("する接続" ,suru) res))
-    (setq res (cons `("語幹のみで文節" ,ind) res))
+    (setq res (cons (list "と接続" to) res))
+    (setq res (cons (list "たる接続" taru) res))
+    (setq res (cons (list "する接続" suru) res))
+    (setq res (cons (list "語幹のみで文節" ind) res))
     res))
 
 ;; taken from tooltip.el
 (defmacro anthy-region-active-p ()
   "Value is non-nil if the region is currently active."
   (if (string-match "^GNU" (emacs-version))
-      `(and transient-mark-mode mark-active)
-    `(region-active-p)))
+      '(and transient-mark-mode mark-active)
+    '(region-active-p)))
 
 (defun anthy-add-word-interactive ()
   ""
@@ -113,7 +124,7 @@
     (and (string= word "")
 	 (setq word (read-from-minibuffer "単語(語幹のみ): ")))
     (setq yomi (read-from-minibuffer (concat "読み (" word "): ")))
-    (setq cat (string-to-int
+    (setq cat (string-to-number
 	       (read-from-minibuffer
 		"カテゴリー 1:一般名詞 2:その他の名詞 3:形容詞 4:副詞: ")))
     (cond ((= cat 1)
