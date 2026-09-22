$NetBSD$

yahtml-define-instag-key passed env, a variable it does not have, for
its argument tag, and a fourth argument that
yahtml-define-begend-region-key did not take; with the default
YaTeX-inhibit-prefix-letter nil, loading yahtml.el stopped at the first.
Both as fixed in upstream git (hiroseyuuji/yatex master, 2026).

--- yahtml.el.orig
+++ yahtml.el
@@ -307,10 +307,11 @@
 	   (list func 'arg env))
      map)))
 
-(defun yahtml-define-begend-region-key (key env &optional map)
+(defun yahtml-define-begend-region-key (key env &optional map func)
   "Define short cut yahtml-insert-begend-region key."
   (YaTeX-define-key key (list 'lambda nil '(interactive)
-			      (list 'yahtml-insert-begend t env)) map))
+			      (list (or func 'yahtml-insert-begend)
+				    t env)) map))
 
 (defun yahtml-define-begend-key (key env &optional map)
   "Define short cut key for begin type completion.
@@ -328,7 +329,7 @@
   (yahtml-define-begend-key-normal key tag map 'yahtml-insert-tag)
   (if YaTeX-inhibit-prefix-letter nil
     (yahtml-define-begend-region-key
-     (concat (upcase (substring key 0 1)) (substring key 1)) env map
+     (concat (upcase (substring key 0 1)) (substring key 1)) tag map
      'yahtml-insert-tag)))
 
 (if yahtml-mode-map nil
