$NetBSD$

setq alone left anthy-kyuri-mode-hiragana-map a free variable to the byte
compiler.  It is this file that owns it, so it is declared here.

See patch-src-util_anthy.el for the rest of this.

--- src-util/anthy-kyuri.el.orig
+++ src-util/anthy-kyuri.el
@@ -1,10 +1,14 @@
-;; anthy-kyuri.el
+;; anthy-kyuri.el  -*- lexical-binding: nil -*-
 
 ;; Copyright (C) 2005
 ;; Author: Yukihiro Matsumoto <matz@ruby-lang.org>
 
 (require 'anthy)
 
+
+;; setq alone left this as a free variable to the byte compiler; anthy.el
+;; does not define it, this file is where it comes from.
+(defvar anthy-kyuri-mode-hiragana-map nil)
 (setq anthy-kyuri-mode-hiragana-map
   '(
     ("bh" . "ぁ") ("h" . "あ") ("bk" . "ぃ") ("k" . "い") ("bj" . "ぅ")
