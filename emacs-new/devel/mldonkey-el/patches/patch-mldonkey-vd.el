$NetBSD$

Options to show release status and comment count in the vd listing;
the Emacs 26 fix below carries this context.  From Gentoo.

--- mldonkey-vd.el.orig
+++ mldonkey-vd.el
@@ -107,6 +107,26 @@
   :group 'mldonkey
   :type 'boolean)
 
+(defcustom mldonkey-show-release-status nil
+  "Show the release status of a download."
+  :group 'mldonkey
+  :type 'boolean)
+
+(defcustom mldonkey-show-comments nil
+  "Show the number of comments in a download."
+  :group 'mldonkey
+  :type 'boolean)
+
+(defcustom mldonkey-show-user nil
+  "Show the user of a download."
+  :group 'mldonkey
+  :type 'boolean)
+
+(defcustom mldonkey-show-group nil
+  "Show the group of a download."
+  :group 'mldonkey
+  :type 'boolean)
+
 (defcustom mldonkey-show-filename t
   "Show the filename of a download."
   :group 'mldonkey
@@ -275,6 +295,14 @@
    ;; FIXME: does a network may contain spaces?
    "\\[\\(.*?\\)[ \t]*\\([0-9]+\\)\\]"       ; network and number
    "[ \t]+"
+   "\\(R\\|\\-\\)"                           ; release status
+   "[ \t]+"
+   "\\([0-9]+\\)"                            ; comments
+   "[ \t]+"
+   "\\([^ \t]+\\)"                           ; user
+   "[ \t]+"
+   "\\([^ \t]+\\)"                           ; group
+   "[ \t]+"
    "\\([^\n]+\\)"                            ; filename
    "[ \t]+"
    "\\([0-9\\.]+\\)"                         ; percent
@@ -283,10 +311,9 @@
    "[ \t]+"
    "\\([0-9\\.]+\\(?:gb\\|mb\\|kb\\|b\\)\\)" ; size
    "[ \t]+"
-   ;; "\\([0-9\\.]+\\(?:gb\\|mb\\|kb\\|b\\|[ \t]*chunks\\)\\)" ; left
-   "\\([0-9]+%\\)"                           ; avail
+   "\\([0-9:\\-]+\\)"                        ; last seen
    "[ \t]+"
-   "\\([0-9]+\\):\\([0-9\\-]+\\)"            ; age and last seen
+   "\\([0-9:\\-]+\\)"                        ; age
    "[ \t]+"
    "\\([0-9]+\\)/\\([0-9]+\\)"               ; active sources and total sources
    "[ \t]+"
@@ -454,7 +481,7 @@
     (setq mldonkey-vd-num-downloading (1+ mldonkey-vd-num-downloading))
     (add-to-list
      'mldonkey-vd-downloading-list
-     (vconcat (mapcar 'mldonkey-vd-get-match (number-sequence 1 13))))))
+     (vconcat (mapcar 'mldonkey-vd-get-match (number-sequence 1 16))))))
 
 
 (defun mldonkey-vd-get-finished ()
@@ -523,13 +550,16 @@
 
   (vector "net "
           "# "
+          "rel "
+          "com "
+          "user "
+          "gr "
           "file "
           "% "
           "down "
           "size "
-          "av "
-          "a "
           "l "
+          "a "
           "as "
           "ts "
           "kb/s "
@@ -553,8 +583,11 @@
 
   (vector 'right
           'right
-          'left
+          'right
           'right
+          'left
+          'left
+          'left
           'right
           'right
           'right
@@ -584,13 +617,16 @@
 
   (vector mldonkey-show-network
           mldonkey-show-number
+          mldonkey-show-release-status
+          mldonkey-show-comments
+          mldonkey-show-user
+          mldonkey-show-group
           mldonkey-show-filename
           mldonkey-show-percent
           mldonkey-show-downloaded
           mldonkey-show-size
-          mldonkey-show-avail
-          mldonkey-show-days
           mldonkey-show-last-seen
+          mldonkey-show-days
           mldonkey-show-active-sources
           mldonkey-show-total-sources
           mldonkey-show-rate
