$NetBSD$

Terminate the variadic argument lists with NULL, not 0.

XtVaSetValues and its relatives read the terminator as a pointer.  On an
LP64 machine 0 is an int, so only 32 bits get pushed and the upper half is
whatever the stack happened to hold; _XtCountVaList walks past the end of
the list and the process dies in libXt before any Lisp is read.  It has
been getting away with this on the machines where that leftover half
happened to be zero, which is why the same binary starts and stops working
as the Xt library changes underneath it.

NetBSD 9.4/amd64 was where it finally showed: mule -q died with SIGSEGV in
_XtCountVaList, while 10.1 and 11.0 with the same ABI were fine.

Include <X11/Xaw/Paned.h> for XawPanedSetRefigureMode.

--- src/widget.c.orig
+++ src/widget.c
@@ -36,6 +36,9 @@
 #include <X11/Shell.h>
 #include <X11/ShellP.h>
 
+/* XawPanedSetRefigureMode を宣言せずに呼んでいる。  */
+#include <X11/Xaw/Paned.h>
+
 #define max(a, b) ((a) > (b) ? (a) : (b))
 
 /* This sucks: this is the first default that x-faces.el tries.  This won't
@@ -316,17 +319,17 @@
      treat that as the geometry of the frame.  (Is this bogus?
      I'm not sure.) */
   if (ew->emacs_frame.geometry == 0)
-    XtVaGetValues (wmshell, XtNgeometry, &ew->emacs_frame.geometry, 0);
+    XtVaGetValues (wmshell, XtNgeometry, &ew->emacs_frame.geometry, NULL);
 
   /* If the Shell is iconic, then the EmacsFrame is iconic.  (Is
      this bogus? I'm not sure.) */
   if (!ew->emacs_frame.iconic)
-    XtVaGetValues (wmshell, XtNiconic, &ew->emacs_frame.iconic, 0);
+    XtVaGetValues (wmshell, XtNiconic, &ew->emacs_frame.iconic, NULL);
   
   
   {
     char *geom = 0;
-    XtVaGetValues (app_shell, XtNgeometry, &geom, 0);
+    XtVaGetValues (app_shell, XtNgeometry, &geom, NULL);
     if (geom)
       app_flags = XParseGeometry (geom, &app_x, &app_y, &app_w, &app_h);
   }
@@ -376,7 +379,7 @@
 
       /* If the AppShell is iconic, then the EmacsFrame is iconic. */
       if (!ew->emacs_frame.iconic)
-	XtVaGetValues (app_shell, XtNiconic, &ew->emacs_frame.iconic, 0);
+	XtVaGetValues (app_shell, XtNiconic, &ew->emacs_frame.iconic, NULL);
 
       first_frame_p = False;
     }
@@ -448,7 +451,7 @@
 	len = strlen (shell_position) + 1;
 	tem = (char *) xmalloc (len);
 	strncpy (tem, shell_position, len);
-	XtVaSetValues (wmshell, XtNgeometry, tem, 0);
+	XtVaSetValues (wmshell, XtNgeometry, tem, NULL);
       }
     else if (flags & (WidthValue | HeightValue))
       {
@@ -458,7 +461,7 @@
 	len = strlen (shell_position) + 1;
 	tem = (char *) xmalloc (len);
 	strncpy (tem, shell_position, len);
-	XtVaSetValues (wmshell, XtNgeometry, tem, 0);
+	XtVaSetValues (wmshell, XtNgeometry, tem, NULL);
       }
 
     /* If the geometry spec we're using has W/H components, mark the size
@@ -468,7 +471,7 @@
 
     /* Also assign the iconic status of the frame to the Shell, so that
        the WM sees it. */
-    XtVaSetValues (wmshell, XtNiconic, ew->emacs_frame.iconic, 0);
+    XtVaSetValues (wmshell, XtNiconic, ew->emacs_frame.iconic, NULL);
 #endif /* 0 */
   }
 }
@@ -514,7 +517,7 @@
 		 XtNheightInc, ch,
 		 XtNminWidth, base_width + min_cols * cw,
 		 XtNminHeight, base_height + min_rows * ch,
-		 0);
+		 NULL);
 }
 
 static void
@@ -826,7 +829,7 @@
   if (cur->emacs_frame.iconic != new->emacs_frame.iconic)
     {
       Widget wmshell = get_wm_shell ((Widget) cur);
-      XtVaSetValues (wmshell, XtNiconic, new->emacs_frame.iconic, 0);
+      XtVaSetValues (wmshell, XtNiconic, new->emacs_frame.iconic, NULL);
     }
 
   return needs_a_refresh;
