$NetBSD$

ilcompat.el stops at Emacs 25 and everything after it falls through to the
fsf-18 branch, which then loads a compatibility file written for Emacs 18 and
dies on (void-variable comint-version).  Emacs 26 and later behave close
enough to 25 for ILISP's purposes, so send them there.

The cl situation needs both halves.  Upstream moved to cl-lib while keeping
the unprefixed names, which only cl defines, so cl is required in every case;
nothing shows at build time, because ilisp-mak.el requires cl itself, and it
is loading the result that stops with (void-function member*).  And cl-lib
only arrived in Emacs 24.3, while this package is still built for emacs20 and
emacs21, so where it is missing the feature is provided here instead.  That
one place is enough: ilisp-mak.el loads this file before compiling any other,
and ilisp.el loads it before anything that wants cl-lib.
--- ilcompat.el.orig
+++ ilcompat.el
@@ -8,7 +8,22 @@
 ;;; Please refer to the file ACKNOWLEGDEMENTS for an (incomplete) list
 ;;; of present and past contributors.
 
-(require 'cl-lib)
+;; Upstream moved to cl-lib but kept calling the unprefixed names that only
+;; the old cl provides: member*, assoc*, delete*, values, first, subseq and
+;; the rest.  cl-lib deliberately defines none of them, so cl is needed in
+;; every case; without it the files byte-compile (ilisp-mak.el pulls in cl
+;; itself) and then loading ilisp stops with (void-function member*).
+(require 'cl)
+;; cl-lib itself only arrived in Emacs 24.3, and this package is still built
+;; for emacs20 and emacs21.  Where it is missing, cl covers everything the
+;; package asks of it except the one prefixed name it uses.  ilisp-mak.el
+;; loads this file before compiling any other, and ilisp.el loads it before
+;; anything that wants cl-lib, so providing the feature here is enough for
+;; the other fifteen (require 'cl-lib) to become no-ops.
+(unless (require 'cl-lib nil t)
+  (when (and (not (fboundp 'cl-flet)) (fboundp 'flet))
+    (defalias 'cl-flet (symbol-function 'flet)))
+  (provide 'cl-lib))
 
 ;;; Global definitions/declarations
 
@@ -33,6 +48,10 @@
 	 'fsf-24)
 	((string-match "^25" emacs-version)
 	 'fsf-25)
+	;; Emacs 26 and later: no layer of their own, and falling through to
+	;; fsf-18 loads a compatibility file written for Emacs 18.
+	((string-match "^\\([3-9][0-9]\\|2[6-9]\\)" emacs-version)
+	 'fsf-25)
 	(t 'fsf-18))
   "The major version of (X)Emacs ILISP is running in.
 Declared as '(member fsf-19 fsf-19 fsf-20 fsf-21 fsf-22 fsf-23 fsf-24
