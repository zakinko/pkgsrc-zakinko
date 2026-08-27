$NetBSD$

Say outright which coding system the generated Quail package is written in.

miscdic-convert builds the package in a temp buffer, puts a
`coding:iso-2022-7bit' cookie in its header and sets the buffer's own
coding system to iso-2022-7bit-unix, and then lets with-temp-file work out
how to write it.  select-safe-coding-system decides iso-2022-7bit is unsafe
for a buffer of Big5 characters -- unencodable-char-position finds nothing
unencodable in it, so this is the safety check being wrong, not the buffer
-- and falls through to select-safe-coding-system-interactively, which in
batch has no minibuffer and dies in `min' with

  Wrong type argument: number-or-marker-p, nil

so leim/quail/tsang-b5.el is never written and the build stops at
quail/tsang-b5.elc.  Bind coding-system-for-write to what the header
already promises.

--- lisp/international/titdic-cnv.el.orig
+++ lisp/international/titdic-cnv.el
@@ -1121,6 +1121,13 @@
       (error "%s does not exist" filename))
   (let ((tail quail-misc-package-ext-info)
 	(default-buffer-file-coding-system 'iso-2022-7bit)
+	;; The package written out says `coding:iso-2022-7bit' in its own
+	;; header and the buffer is put in that coding system a few lines
+	;; down, but with-temp-file still asks select-safe-coding-system,
+	;; which decides iso-2022-7bit is unsafe for a buffer of Big5
+	;; characters even though unencodable-char-position finds nothing
+	;; in it, and then dies in batch trying to prompt.  Say it outright.
+	(coding-system-for-write 'iso-2022-7bit-unix)
 	slot
 	name title dicfile coding quailfile converter copyright
 	dicbuf)
