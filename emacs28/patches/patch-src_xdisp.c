$NetBSD$

Assertion violations reachable from display code, fixed by upstream on the
emacs-28 branch for the 28.3 release that was never made.

	b1e92c59ed  Avoid assertion violations in 'pop_it'
	b560ce3560  Avoid assertion violations in STRING_CHAR

No CVE was assigned to either.  They are here because a build with checking
enabled aborts, and because reaching an assertion from display of a buffer's
contents is the kind of thing that gets a number later.

--- src/xdisp.c.orig
+++ src/xdisp.c
@@ -6034,7 +6034,10 @@
       pos_byte = IT_STRING_BYTEPOS (*it);
       string = it->string;
       s = SDATA (string) + pos_byte;
-      it->c = STRING_CHAR (s);
+      if (STRING_MULTIBYTE (string))
+	it->c = STRING_CHAR (s);
+      else
+	it->c = *s;
     }
   else
     {
@@ -6755,7 +6758,14 @@
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
   /* If we move the iterator over text covered by a display property
      to a new buffer position, any info about previously seen overlays
