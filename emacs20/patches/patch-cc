$NetBSD: patch-cc,v 1.1 2008/07/13 17:28:34 dholland Exp $

"." as a font-lock cache directory means a cache file is written beside the
file being visited, and read from there.  In a directory several people can
write to, that is someone else's cache being loaded as Lisp.  Drop "." from the
default and mark the variable risky so a file-local value cannot put it back.
Same class as CVE-2008-1694 in XEmacs, which was answered the same way.

--- lisp/fast-lock.el.orig	1999-05-14 04:45:54.000000000 -0400
+++ lisp/fast-lock.el	2008-07-13 12:32:19.000000000 -0400
@@ -277,7 +277,7 @@
 				      (integer :tag "size")))))
   :group 'fast-lock)
 
-(defcustom fast-lock-cache-directories '("." "~/.emacs-flc")
+(defcustom fast-lock-cache-directories '("~/.emacs-flc")
 ; - `internal', keep each file's Font Lock cache file in the same file.
 ; - `external', keep each file's Font Lock cache file in the same directory.
   "*Directories in which Font Lock cache files are saved and read.
@@ -295,13 +295,18 @@
  ((\"^/your/true/home/directory/\" . \".\") \"~/.emacs-flc\")
 
 would cause a file's current directory to be used if the file is under your
-home directory hierarchy, or otherwise the absolute directory `~/.emacs-flc'."
+home directory hierarchy, or otherwise the absolute directory `~/.emacs-flc'.
+For security reasons, it is not advisable to use the file's current directory
+to avoid the possibility of using the cache of another user."
   :type '(repeat (radio (directory :tag "directory")
 			(cons :tag "Matching"
 			      (regexp :tag "regexp")
 			      (directory :tag "directory"))))
   :group 'fast-lock)
 
+;;;###autoload
+(put 'fast-lock-cache-directories 'risky-local-variable t)
+
 (defcustom fast-lock-save-events '(kill-buffer kill-emacs)
   "*Events under which caches will be saved.
 Valid events are `save-buffer', `kill-buffer' and `kill-emacs'.
