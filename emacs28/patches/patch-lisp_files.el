$NetBSD$

Adds the buffer-local variable untrusted-content and the function
trusted-content-p, which the rest of the security patches here read before
deciding whether to run code that came from the buffer.  Nothing changes on
its own; this is the piece the others stand on.

	ccc188fcf9  * lisp/files.el (untrusted-content): New variable.  (29.3)
	b5158bd191  elisp-mode.el: Disable Flymake byte-compile backend in
	            untrusted files  (30, CVE-2024-53920)

Both taken unchanged.

--- lisp/files.el.orig
+++ lisp/files.el
@@ -622,7 +622,64 @@
   "Non-nil means enable use of directory-local variables.
 Some modes may wish to set this to nil to prevent directory-local
 settings being applied, but still respect file-local ones.")
+
+(defvar-local untrusted-content nil
+  "Non-nil means that current buffer originated from an untrusted source.
+Email clients and some other modes may set this non-nil to mark the
+buffer contents as untrusted.
+
+This variable might be subject to change without notice.")
+(put 'untrusted-content 'permanent-local t)
+
+(defcustom trusted-files nil
+  "List of files and directories whose content we trust.
+Be extra careful here since trusting means that Emacs might execute the
+code contained within those files and directories without an explicit
+request by the user.
+One important case when this might happen is when `flymake-mode' is
+enabled (for example, when it is added to a mode hook).
+Each element of the list should be a string:
+- If it ends in \"/\", it is considered as a directory name and means that
+  Emacs should trust all the files whose name has this directory as a prefix.
+- else it is considered as a file name.
+Use abbreviated file names.  For example, an entry \"~/mycode\" means
+that Emacs will trust all the files in your directory \"mycode\".
+This variable can also be set to `:all', in which case Emacs will trust
+all files, which opens a gaping security hole."
+  :type '(choice (repeat :tag "List" file)
+                 (const :tag "Trust everything (DANGEROUS!)" :all))
+  :version "30.1")
+(put 'trusted-files 'risky-local-variable t)
 
+(defun trusted-content-p ()
+  "Return non-nil if we trust the contents of the current buffer.
+Here, \"trust\" means that we are willing to run code found inside of it.
+See also `trusted-files'."
+  ;; We compare with `buffer-file-truename' i.s.o `buffer-file-name'
+  ;; to try and avoid marking as trusted a file that's merely accessed
+  ;; via a symlink that happens to be inside a trusted dir.
+  (and (not untrusted-content)
+       buffer-file-truename
+       (with-demoted-errors "trusted-content-p: %S"
+         (let ((exists (file-exists-p buffer-file-truename)))
+           (or
+            (eq trusted-files :all)
+            ;; We can't avoid trusting the user's init file.
+            (if (and exists user-init-file)
+                (file-equal-p buffer-file-truename user-init-file)
+              (equal buffer-file-truename user-init-file))
+            (let ((file (abbreviate-file-name buffer-file-truename))
+                  (trusted nil))
+              (dolist (tf trusted-files)
+                (when (or (if exists (file-equal-p tf file) (equal tf file))
+                          ;; We don't use `file-in-directory-p' here, because
+                          ;; we want to err on the conservative side: "guilty
+                          ;; until proven innocent".
+                          (and (string-suffix-p "/" tf)
+                               (string-prefix-p tf file)))
+                  (setq trusted t)))
+              trusted))))))
+
 ;; This is an odd variable IMO.
 ;; You might wonder why it is needed, when we could just do:
 ;; (setq-local enable-local-variables nil)
