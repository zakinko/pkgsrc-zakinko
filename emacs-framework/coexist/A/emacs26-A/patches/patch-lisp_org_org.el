$NetBSD$

Four things, all about Org running or fetching something it should ask about
first.

An abbreviated link may name a function, and expanding the link called it, so
following a link in a document ran code the document chose.  That is
CVE-2024-39331, upstream commit c645e1d820 from the 29.4 release.  In 9.1.9
org-link-expand-abbrev still lives in org.el rather than ol.el, so the change
is made there; the code itself is upstream's.

LaTeX preview was generated for e-mail attachments, and generating it runs
LaTeX on content the sender wrote.  That is CVE-2024-30204, upstream commit
6f9ea396f4 from the 29.3 emergency release.  9.1.9 guards the body with
(when (display-graphic-p) ...) rather than the cond of later versions, so the
test is added to that when.

Org treated a remote file name as if it were local, so contents fetched over
TRAMP were trusted.  That is CVE-2024-30205, upstream commit 2bc865ace0 with
its follow-up 7a5d7be52c.  Neither applies to 9.1.9: the confirmation they
extend does not exist in it at all, and it fetches a URL named by a document
with no prompt whatsoever.  So the whole mechanism is brought over from Emacs
29.4 instead -- the options org-resource-download-policy and
org-safe-remote-resources, and the three helpers they drive.

Two substitutions were needed for this Emacs: setq-local, which arrived in
24.3, is written as set + make-local-variable, and the rx form (? "s") is
written as (optional "s").  Neither changes what the code does.

--- lisp/org/org.el.orig
+++ lisp/org/org.el
@@ -1060,6 +1060,24 @@
   :version "24.4"
   :package-version '(Org . "8.0")
   :type 'boolean)
+
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
 
 (defcustom org-insert-mode-line-in-empty-file nil
   "Non-nil means insert the first line setting Org mode in empty files.
@@ -5282,6 +5300,42 @@
   (require 'ffap)
   (string-match-p ffap-url-regexp file))
 
+;; The remote-resource confirmation below is backported from Emacs 29.4
+;; (Org 9.6/9.7).  The Org shipped here fetches a URL named by a document
+;; with no confirmation at all, and treats a remote file name as local;
+;; CVE-2024-30205 is the latter half of that.  The two options and the three
+;; helpers are taken unchanged, and org-file-contents with them.
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
 
@@ -5297,26 +5351,38 @@
 If NOCACHE is non-nil, do a fresh fetch of FILE even if cached version
 is available.  This option applies only if FILE is a URL."
   (let* ((is-url (org-file-url-p file))
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
-		   file))))
+     ((or is-url is-remote)
+      (if (org--should-fetch-remote-resource-p file)
+          (condition-case error
+          (with-current-buffer (url-retrieve-synchronously file)
+    	(goto-char (point-min))
+    	;; Move point to after the url-retrieve header.
+    	(search-forward "\n\n" nil :move)
+    	;; Search for the success code only in the url-retrieve header.
+    	(if (save-excursion
+    	      (re-search-backward "HTTP.*\\s-+200\\s-OK" nil :noerror))
+    	    ;; Update the cache `org--file-cache' and return contents.
+    	    (puthash file
+    		     (buffer-substring-no-properties (point) (point-max))
+    		     org--file-cache)
+    	  (funcall (if noerror #'message #'user-error)
+    		   "Unable to fetch file from %S"
+    		   file)))
+            (error (if noerror
+                       (message "Org couldn't download \"%s\": %s %S" file (car error) (cdr error))
+                     (signal (car error) (cdr error)))))
+        (funcall (if noerror #'message #'user-error)
+                 "The remote resource %S is considered unsafe, and will not be downloaded."
+                 file)))
      (t
       (with-temp-buffer
         (condition-case nil
@@ -5328,6 +5394,96 @@
 		    "Unable to read file %S"
 		    file))))))))
 
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
+                        (rx (seq "http" (optional "s") "://")
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
+        (set (make-local-variable 'cursor-type) nil)
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
+
 (defun org-extract-log-state-settings (x)
   "Extract the log state setting from a TODO keyword string.
 This will extract info from a string like \"WAIT(w@/!)\"."
@@ -9585,16 +9741,33 @@
 	(if (not as)
 	    link
 	  (setq rpl (cdr as))
-	  (cond
-	   ((symbolp rpl) (funcall rpl tag))
-	   ((string-match "%(\\([^)]+\\))" rpl)
-	    (replace-match
-	     (save-match-data
-	       (funcall (intern-soft (match-string 1 rpl)) tag)) t t rpl))
-	   ((string-match "%s" rpl) (replace-match (or tag "") t t rpl))
-	   ((string-match "%h" rpl)
-	    (replace-match (url-hexify-string (or tag "")) t t rpl))
-	   (t (concat rpl tag)))))
+	  ;; Drop any potentially dangerous text properties like
+	  ;; `modification-hooks' that may be used as an attack vector.
+	  (substring-no-properties
+	   (cond
+	    ((symbolp rpl) (funcall rpl tag))
+	    ((string-match "%(\\([^)]+\\))" rpl)
+	     (let ((rpl-fun-symbol (intern-soft (match-string 1 rpl))))
+	       ;; Using `unsafep-function' is not quite enough because
+	       ;; Emacs considers functions like `genenv' safe, while
+	       ;; they can potentially be used to expose private system
+	       ;; data to attacker if abbreviated link is clicked.
+	       (if (or (eq t (get rpl-fun-symbol 'org-link-abbrev-safe))
+		       (eq t (get rpl-fun-symbol 'pure)))
+		   (replace-match
+		    (save-match-data
+		      (funcall (intern-soft (match-string 1 rpl)) tag)) t t rpl)
+		 (org-display-warning
+		  (format "Disabling unsafe link abbrev: %s
+You may mark function safe via (put '%s 'org-link-abbrev-safe t)"
+			  rpl (match-string 1 rpl)))
+		 (setq org-link-abbrev-alist-local (delete as org-link-abbrev-alist-local)
+		       org-link-abbrev-alist (delete as org-link-abbrev-alist))
+		 link)))
+	    ((string-match "%s" rpl) (replace-match (or tag "") t t rpl))
+	    ((string-match "%h" rpl)
+	     (replace-match (url-hexify-string (or tag "")) t t rpl))
+	    (t (concat rpl tag))))))
     link))
 
 ;;; Storing and inserting links
@@ -18833,7 +19006,11 @@
 \\[universal-argument]' preview or clear images
 for all fragments in the buffer."
   (interactive "P")
-  (when (display-graphic-p)
+  (when (and (display-graphic-p)
+             ;; Do not run LaTeX on fragments that came from an untrusted
+             ;; source; generating a preview runs LaTeX on what the sender
+             ;; wrote.  CVE-2024-30204.
+             (or (not untrusted-content) org--latex-preview-when-risky))
     (catch 'exit
       (save-excursion
 	(let (beg end msg)
