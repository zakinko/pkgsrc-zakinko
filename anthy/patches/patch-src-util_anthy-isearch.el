$NetBSD$

A lexical-binding cookie, so that the file compiles without a warning on
Emacs 24 and later.  nil keeps the dynamic binding the file was written for.

This file says DO NOT USE NOW at the top and still assigns to
overriding-terminal-local-map, which Emacs 19.28 does not have; that is left
alone, since nothing loads it.

See patch-src-util_anthy.el for the rest of this.

--- src-util/anthy-isearch.el.orig
+++ src-util/anthy-isearch.el
@@ -1,4 +1,4 @@
-;; anthy-isearch.el -- Anthy
+;; anthy-isearch.el -- Anthy  -*- lexical-binding: nil -*-
 
 ;; Copyright (C) 2003
 ;; Author: Yusuke Tabata <yusuke@cherbim.icw.co.jp>
