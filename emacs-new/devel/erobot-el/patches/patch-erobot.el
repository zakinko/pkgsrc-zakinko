$NetBSD$

The interactive spec began with "i\n\n", which hands two ignored
arguments to a function that takes two; the candidates were never read.
From Gentoo.

--- erobot.el.orig
+++ erobot.el
@@ -230,7 +230,7 @@
 `erobot-max-turns' has been exceeded, or if the char q is pressed
 while the game is running.  When the game ends, the candidates on
 the map are returned in a list."
-  (interactive "i\n\naCandidate A: \naCandidate B: ")
+  (interactive "aCandidate A: \naCandidate B: ")
   ;; Place candidates on the map and set erobot-candidates
   (setq erobot-candidates nil)
   (erobot-initialize candidates)
