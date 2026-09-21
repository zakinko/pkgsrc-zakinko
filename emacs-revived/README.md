# Packages removed with emacs21, brought back for emacs20

pkgsrc removed `misc/bbdb2`, `editors/jde` and `textproc/nxml-mode` on
2026-09-12 together with `editors/emacs21`, because their Makefiles only
accepted emacs21.  Two of them work on emacs20 with small patches, so
here they are as complete package directories (not diffs), taken from
the tree as it was just before the removal.

| package | state |
|---|---|
| misc/bbdb2 (2.35) | builds and runs on emacs20 with two new patches: `bbdb-hooks.el` used `mail-parse` (Gnus 5.8+; Emacs 20.7 ships Gnus 5.7) for one RFC 2047 decode, now optional; `bbdb-rmail.el` required `rmailsum`, which Emacs 20's rmailsum.el does not provide. Accepts emacs20 and XEmacs. Checked by creating, saving and searching a record in batch, and by building the package with `bmake package-install` on NetBSD/amd64 |
| editors/jde (2.3.2) | the "won't compile with emacs20" note in the old Makefile was stale: all 37 files byte-compile with Emacs 20.7 against speedbar, eieio, semantic and elib, and the package builds and installs on emacs20 with openjdk21 in the prefix (mk/java-vm.mk needs a JDK; it defaults to openjdk17, which would be built from source, so the test box got PKG_JVM_DEFAULT=openjdk21). `(require 'jde)` loads and jde-mode indents a Java file from the installed package. Two of Debian's eight fixes for their 2.3.5.1 apply here and are taken: jde-bug.el's missing require of jde-util, and jde-jdb.el erroring when the JDK has no jdb; the rest address code 2.3.2 does not have, or count-matches returning a number, which Emacs 20's does not |
| textproc/nxml-mode (20041004) | not revived. Upstream's README says Emacs 20 will not work, and it does not: the sources use the `#x` reader syntax (Emacs 21) about 830 times, `replace-regexp-in-string` everywhere, and Unicode characters Emacs 20 cannot represent without Mule-UCS. Emacs 23 and later bundle nxml-mode |

editors/leim21 went with the same commit and is not brought back: it was
the input-method library for emacs21 only, and editors/leim20 is still
there for emacs20.

A PKGREVISION bump is not carried here: the packages are being re-added,
and pkgsrc's rule for that is to keep the last revision.
