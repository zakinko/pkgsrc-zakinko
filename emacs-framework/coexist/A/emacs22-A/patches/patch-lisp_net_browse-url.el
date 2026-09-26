$NetBSD$

browse-url-mosaic writes the URL into /tmp/Mosaic.<pid> with find-file and
save-buffer.  The name is one anybody can predict, and both of those follow a
symlink, so a symlink planted there first decides which file gets written and
with what contents.  This is CVE-2014-3423.

Upstream fixed it in 24.5 with

	4049faae96  * browse-url.el (browse-url-mosaic): Be careful when
	            writing /tmp/Mosaic.PID.  This is CVE-2014-3423.
	8c6699ab19  * browse-url.el (browse-url-mosaic): Create
	            /tmp/Mosaic.PID as a private file.

pkgsrc never carried it below 24.5: the vulnerability database lists only
emacs24{,-nox11}<24.5, and 24.5 got the fix from upstream, so nothing was
ever done for 20 through 23.  The code here is the same as the code that was
fixed.  Written out by hand because the function around it differs.

--- lisp/net/browse-url.el.orig
+++ lisp/net/browse-url.el
@@ -1215,14 +1215,25 @@
 	  (kill-buffer nil)))
     (if (and pid (zerop (signal-process pid 0))) ; Mosaic running
 	(save-excursion
-	  (find-file (format "/tmp/Mosaic.%d" pid))
-	  (erase-buffer)
-	  (insert (if (browse-url-maybe-new-window new-window)
-		      "newwin\n"
-		    "goto\n")
-		  url "\n")
-	  (save-buffer)
-	  (kill-buffer nil)
+	  ;; CVE-2014-3423.  /tmp/Mosaic.<pid> is a name anyone can predict,
+	  ;; so a symlink planted there first decides what this writes to.
+	  ;; find-file and save-buffer follow it; write-region with 'excl
+	  ;; refuses to.  The mode is narrowed while the file is created so
+	  ;; that the URL is not readable by everyone in between.
+	  (let ((mosaic-file (format "/tmp/Mosaic.%d" pid))
+		(saved-modes (default-file-modes)))
+	    (unwind-protect
+		(progn
+		  (set-default-file-modes ?\700)
+		  (if (file-exists-p mosaic-file)
+		      (delete-file mosaic-file))
+		  (with-temp-buffer
+		    (insert (if (browse-url-maybe-new-window new-window)
+				"newwin\n"
+			      "goto\n")
+			    url "\n")
+		    (write-region nil nil mosaic-file nil 'silent nil 'excl)))
+	      (set-default-file-modes saved-modes)))
 	  ;; Send signal SIGUSR to Mosaic
 	  (message "Signaling Mosaic...")
 	  (signal-process pid 'SIGUSR1)
