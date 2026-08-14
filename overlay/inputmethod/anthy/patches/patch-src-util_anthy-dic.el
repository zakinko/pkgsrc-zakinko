$NetBSD$

string-to-int was an obsolete alias for string-to-number and was removed in
Emacs 26.  string-to-number has existed since Emacs 20 and in XEmacs 20, so
the calls are renamed rather than guarded.

See patch-src-util_anthy.el for the rest of this.

--- src-util/anthy-dic.el.orig
+++ src-util/anthy-dic.el
@@ -70,7 +70,7 @@
 (defun anthy-dic-get-special-noun-category (word)
   (let 
       ((res '())
-       (cat (string-to-int
+       (cat (string-to-number
 	     (read-from-minibuffer "1:人名 2:地名: "))))
     (cond ((= cat 1)
 	   (setq res '(("品詞" "人名"))))
@@ -113,7 +113,7 @@
     (and (string= word "")
 	 (setq word (read-from-minibuffer "単語(語幹のみ): ")))
     (setq yomi (read-from-minibuffer (concat "読み (" word "): ")))
-    (setq cat (string-to-int
+    (setq cat (string-to-number
 	       (read-from-minibuffer
 		"カテゴリー 1:一般名詞 2:その他の名詞 3:形容詞 4:副詞: ")))
     (cond ((= cat 1)
