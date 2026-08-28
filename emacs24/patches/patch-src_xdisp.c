$NetBSD$

	b1e92c59ed  Avoid assertion violations in 'pop_it'

From the emacs-28 branch, for the 28.3 release that was never made.  No CVE
was assigned.  It is here because a build with checking enabled aborts, and
because reaching an assertion from display of a buffer's contents is the kind
of thing that gets a number later.

--- src/xdisp.c.orig
+++ src/xdisp.c
@@ -6200,7 +6200,14 @@
 	       || (STRINGP (it->object)
 		   && IT_STRING_CHARPOS (*it) == it->bidi_it.charpos
 		   && IT_STRING_BYTEPOS (*it) == it->bidi_it.bytepos)
-	       || (CONSP (it->object) && it->method == GET_FROM_STRETCH));
+	       || (CONSP (it->object) && it->method == GET_FROM_STRETCH)
+	       /* We could be in the middle of handling a list or a
+		  vector of several 'display' properties, in which
+		  case we should only verify the above conditions when
+		  we pop the iterator stack the last time, because
+		  higher stack levels cannot "iterate out of the
+		  display property".  */
+	       || it->sp > 0);
     }
 }
 
