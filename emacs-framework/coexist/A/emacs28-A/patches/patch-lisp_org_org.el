$NetBSD$

Two things, both about Org fetching things it should ask about first.

LaTeX preview was generated for e-mail attachments, and generating it runs
LaTeX on content the sender wrote.  That is CVE-2024-30204, upstream commit
6f9ea396f4 from the 29.3 emergency release, applied unchanged.

Org treated a remote file name as if it were local, so contents fetched over
TRAMP were trusted.  That is CVE-2024-30205, upstream commit 2bc865ace0 with
its follow-up 7a5d7be52c.  Neither applies to 28.2: the confirmation they
extend does not exist in Org 9.5.5 at all, which fetches a URL named by a
document with no prompt whatsoever.  So the whole mechanism is brought over
from Emacs 29.4 instead -- the options org-resource-download-policy and
org-safe-remote-resources, the helpers org--should-fetch-remote-resource-p,
org--safe-remote-resource-p and org--confirm-resource-safe, and
org-file-contents with them.  They are taken verbatim and call nothing that
9.5.5 lacks; org-url-p is the only Org function among them.

The default policy is prompt, so Org now asks before downloading, where
before it did not.

--- lisp/org/org.el.orig
+++ lisp/org/org.el
@@ -1092,6 +1092,24 @@
   :package-version '(Org . "8.0")
   :type 'boolean)
 
+(defvar untrusted-content) ; defined in files.el
+(defvar org--latex-preview-when-risky nil
+  "If non-nil, enable LaTeX preview in Org buffers from unsafe source.
+
+Some specially designed LaTeX code may generate huge pdf or log files
+that may exhaust disk space.
+
+This variable controls how to handle LaTeX preview when rendering LaTeX
+fragments that originate from incoming email messages.  It has no effect
+when Org mode is unable to determine the origin of the Org buffer.
+
+An Org buffer is considered to be from unsafe source when the
+variable `untrusted-content' has a non-nil value in the buffer.
+
+If this variable is non-nil, LaTeX previews are rendered unconditionally.
+
+This variable may be renamed or changed in the future.")
+
 (defcustom org-insert-mode-line-in-empty-file nil
   "Non-nil means insert the first line setting Org mode in empty files.
 When the function `org-mode' is called interactively in an empty file, this
@@ -4671,7 +4689,44 @@
 (defun org-reset-file-cache ()
   "Reset the cache of files downloaded by `org-file-contents'."
   (clrhash org--file-cache))
+
+;; The remote-resource confirmation below is backported from Emacs 29.4
+;; (Org 9.6/9.7).  Org 9.5.5 as shipped with 28.2 fetches a URL named by a
+;; document with no confirmation at all, and treats a remote file name as
+;; local; CVE-2024-30205 is the latter half of that.  The two options and the
+;; three helpers are taken unchanged, and org-file-contents with them.
+
+(defcustom org-resource-download-policy 'prompt
+  "The policy applied to requests to obtain remote resources.
+
+This affects keywords like #+setupfile and #+include on export,
+`org-persist-write:url',and `org-attach-url' in non-interactive
+Emacs sessions.
+
+This recognizes four possible values:
+- t, remote resources should always be downloaded.
+- prompt, you will be prompted to download resources not considered safe.
+- safe, only resources considered safe will be downloaded.
+- nil, never download remote resources.
+
+A resource is considered safe if it matches one of the patterns
+in `org-safe-remote-resources'."
+  :group 'org
+  :package-version '(Org . "9.6")
+  :type '(choice (const :tag "Always download remote resources" t)
+                 (const :tag "Prompt before downloading an unsafe resource" prompt)
+                 (const :tag "Only download resources considered safe" safe)
+                 (const :tag "Never download any resources" nil)))
+
+(defcustom org-safe-remote-resources nil
+  "A list of regexp patterns matching safe URIs.
+URI regexps are applied to both URLs and Org files requesting
+remote resources."
+  :group 'org
+  :package-version '(Org . "9.6")
+  :type '(repeat regexp))
 
+
 (defun org-file-contents (file &optional noerror nocache)
   "Return the contents of FILE, as a string.
 
@@ -4687,27 +4742,39 @@
 If NOCACHE is non-nil, do a fresh fetch of FILE even if cached version
 is available.  This option applies only if FILE is a URL."
   (let* ((is-url (org-url-p file))
+         (is-remote (condition-case nil
+                        (file-remote-p file)
+                      ;; In case of error, be safe.
+                      (t t)))
          (cache (and is-url
                      (not nocache)
                      (gethash file org--file-cache))))
     (cond
      (cache)
-     (is-url
-      (with-current-buffer (url-retrieve-synchronously file)
-	(goto-char (point-min))
-	;; Move point to after the url-retrieve header.
-	(search-forward "\n\n" nil :move)
-	;; Search for the success code only in the url-retrieve header.
-	(if (save-excursion
-	      (re-search-backward "HTTP.*\\s-+200\\s-OK" nil :noerror))
-	    ;; Update the cache `org--file-cache' and return contents.
-	    (puthash file
-		     (buffer-substring-no-properties (point) (point-max))
-		     org--file-cache)
-	  (funcall (if noerror #'message #'user-error)
-		   "Unable to fetch file from %S"
-		   file)
-	  nil)))
+     ((or is-url is-remote)
+      (if (org--should-fetch-remote-resource-p file)
+          (condition-case error
+              (with-current-buffer (url-retrieve-synchronously file)
+                (goto-char (point-min))
+                ;; Move point to after the url-retrieve header.
+                (search-forward "\n\n" nil :move)
+                ;; Search for the success code only in the url-retrieve header.
+                (if (save-excursion
+                      (re-search-backward "HTTP.*\\s-+200\\s-OK" nil :noerror))
+                    ;; Update the cache `org--file-cache' and return contents.
+                    (puthash file
+                             (buffer-substring-no-properties (point) (point-max))
+                             org--file-cache)
+                  (funcall (if noerror #'message #'user-error)
+                           "Unable to fetch file from %S"
+                           file)
+                  nil))
+            (error (if noerror
+                       (message "Org couldn't download \"%s\": %s %S" file (car error) (cdr error))
+                     (signal (car error) (cdr error)))))
+        (funcall (if noerror #'message #'user-error)
+                 "The remote resource %S is considered unsafe, and will not be downloaded."
+                 file)))
      (t
       (with-temp-buffer
         (condition-case nil
@@ -4719,6 +4786,95 @@
 		    "Unable to read file %S"
 		    file)
 	   nil)))))))
+
+(defun org--should-fetch-remote-resource-p (uri)
+  "Return non-nil if the URI should be fetched."
+  (or (eq org-resource-download-policy t)
+      (org--safe-remote-resource-p uri)
+      (and (eq org-resource-download-policy 'prompt)
+           (org--confirm-resource-safe uri))))
+
+(defun org--safe-remote-resource-p (uri)
+  "Return non-nil if URI is considered safe.
+This checks every pattern in `org-safe-remote-resources', and
+returns non-nil if any of them match."
+  (let ((uri-patterns org-safe-remote-resources)
+        (file-uri (and (buffer-file-name (buffer-base-buffer))
+                       (concat "file://" (file-truename (buffer-file-name (buffer-base-buffer))))))
+        match-p)
+    (while (and (not match-p) uri-patterns)
+      (setq match-p (or (string-match-p (car uri-patterns) uri)
+                        (and file-uri (string-match-p (car uri-patterns) file-uri)))
+            uri-patterns (cdr uri-patterns)))
+    match-p))
+
+(defun org--confirm-resource-safe (uri)
+  "Ask the user if URI should be considered safe, returning non-nil if so."
+  (unless noninteractive
+    (let ((current-file (and (buffer-file-name (buffer-base-buffer))
+                             (file-truename (buffer-file-name (buffer-base-buffer)))))
+          (domain (and (string-match
+                        (rx (seq "http" (? "s") "://")
+                            (optional (+ (not (any "@/\n"))) "@")
+                            (optional "www.")
+                            (one-or-more (not (any ":/?\n"))))
+                        uri)
+                       (match-string 0 uri)))
+          (buf (get-buffer-create "*Org Remote Resource*")))
+      ;; Set up the contents of the *Org Remote Resource* buffer.
+      (with-current-buffer buf
+        (erase-buffer)
+        (insert "An org-mode document would like to download "
+                (propertize uri 'face '(:inherit org-link :weight normal))
+                ", which is not considered safe.\n\n"
+                "Do you want to download this?  You can type\n "
+                (propertize "!" 'face 'success)
+                " to download this resource, and permanently mark it as safe.\n "
+                (if domain
+                    (concat
+                     (propertize "d" 'face 'success)
+                     " to download this resource, and mark the domain ("
+                     (propertize domain 'face '(:inherit org-link :weight normal))
+                     ") as safe.\n ")
+                  "")
+                (if current-file
+                    (concat
+                     (propertize "f" 'face 'success)
+                     " to download this resource, and permanently mark all resources in "
+                     (propertize current-file 'face 'underline)
+                     " as safe.\n ")
+                  "")
+                (propertize "y" 'face 'warning)
+                " to download this resource, just this once.\n "
+                (propertize "n" 'face 'error)
+                " to skip this resource.\n")
+        (setq-local cursor-type nil)
+        (set-buffer-modified-p nil)
+        (goto-char (point-min)))
+      ;; Display the buffer and read a choice.
+      (save-window-excursion
+        (pop-to-buffer buf)
+        (let* ((exit-chars (append '(?y ?n ?! ?d ?\s) (and current-file '(?f))))
+               (prompt (format "Please type y, n%s, d, or !%s: "
+                               (if current-file ", f" "")
+                               (if (< (line-number-at-pos (point-max))
+                                      (window-body-height))
+                                   ""
+                                 ", or C-v/M-v to scroll")))
+               char)
+          (setq char (read-char-choice prompt exit-chars))
+          (when (memq char '(?! ?f ?d))
+            (customize-push-and-save
+             'org-safe-remote-resources
+             (list (if (eq char ?d)
+                       (concat "\\`" (regexp-quote domain) "\\(?:/\\|\\'\\)")
+                     (concat "\\`"
+                             (regexp-quote
+                              (if (and (= char ?f) current-file)
+                                  (concat "file://" current-file) uri))
+                             "\\'")))))
+          (prog1 (memq char '(?y ?! ?d ?\s ?f))
+            (quit-window t)))))))
 
 (defun org-extract-log-state-settings (x)
   "Extract the log state setting from a TODO keyword string.
@@ -16000,6 +16156,7 @@
   (interactive "P")
   (cond
    ((not (display-graphic-p)) nil)
+   ((and untrusted-content (not org--latex-preview-when-risky)) nil)
    ;; Clear whole buffer.
    ((equal arg '(64))
     (org-clear-latex-preview (point-min) (point-max))
