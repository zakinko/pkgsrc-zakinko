$NetBSD$

Make anthy.el work on current Emacs.  Two obsolete names that were later
removed:

set-face-underline-p became an alias for set-face-underline in Emacs 24.3
and was removed in Emacs 29.  The call is at top level, so on Emacs 29 and
30 merely loading anthy.el signals an error, and anthy-isearch.el and
anthy-kyuri.el then fail to byte-compile because they (require 'anthy) --
their .elc files end up missing from what PLIST expects.  Emacs 20, 21 and
23 have only the -p name, so the call is guarded rather than renamed.

last-command-char was an obsolete alias for last-command-event and was
removed in Emacs 24.  The XEmacs branch of this function already uses
last-command-event; only the GNU Emacs branch was left behind.  That
reference is inside a function, so byte compilation only warns, but
japanese-anthy fails at run time as soon as a key is typed.

anthy has not been released since 2009, so there is nowhere upstream to
send this.

--- src-util/anthy.el.orig
+++ src-util/anthy.el
@@ -71,7 +71,9 @@
 (defvar anthy-highlight-face nil)
 (defvar anthy-underline-face nil)
 (copy-face 'highlight 'anthy-highlight-face)
-(set-face-underline-p 'anthy-highlight-face t)
+(if (fboundp 'set-face-underline)
+    (set-face-underline 'anthy-highlight-face t)
+  (set-face-underline-p 'anthy-highlight-face t))
 (copy-face 'underline 'anthy-underline-face)
 
 ;;
@@ -892,7 +894,7 @@
 	 ((event-matches-key-specifier-p event 'backspace) 8)
 	 (t
 	  (char-to-int (event-to-character event)))))
-    last-command-char))
+    last-command-event))
 
 ;;
 ;;
