$NetBSD$

ilcompat.el stops at Emacs 25 and everything after it falls through to the
fsf-18 branch, which then loads a compatibility file written for Emacs 18 and
dies on (void-variable comint-version).  Emacs 26 and later behave close
enough to 25 for ILISP's purposes, so send them there.

Upstream also moved to cl-lib while keeping the unprefixed cl names, which
only the old cl library defines.  Nothing shows at build time, because
ilisp-mak.el requires cl itself; loading the result is where it stops.
--- ilcompat.el.orig
+++ ilcompat.el
@@ -9,6 +9,12 @@
 ;;; of present and past contributors.
 
 (require 'cl-lib)
+;; Upstream moved to cl-lib but kept calling the unprefixed names that only
+;; the old cl provides: member*, assoc*, delete*, values, first, subseq and
+;; the rest.  cl-lib deliberately defines none of them, so without this the
+;; files byte-compile (ilisp-mak.el pulls in cl) and then loading ilisp stops
+;; with (void-function member*).
+(require 'cl)
 
 ;;; Global definitions/declarations
 
@@ -33,6 +39,10 @@
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
