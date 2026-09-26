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

lwlib calls malloc, free and abort without declaring them.  With no
prototype the compiler assumes each returns int, and on LP64 the pointer
malloc returns is cut down to 32 bits before it is stored.  Include
<stdlib.h> so the real declarations are in scope.

--- lwlib/lwlib-Xaw.c.orig
+++ lwlib/lwlib-Xaw.c
@@ -35,6 +35,9 @@
 
 #include <X11/Xatom.h>
 
+/* Declare the standard functions this file calls. */
+#include <stdlib.h>
+
 static void xaw_generic_callback (/*Widget, XtPointer, XtPointer*/);
 
 
@@ -68,7 +71,7 @@
 		     XtNy, &pos_y,
 		     XtNtopOfThumb, &widget_topOfThumb,
 		     XtNshown, &widget_shown,
-		     0);
+		     NULL);
 
       /*
        * First size and position the scrollbar widget.
@@ -83,7 +86,7 @@
 	  XtVaSetValues (widget,
 			 XtNlength, data->scrollbar_height,
 			 XtNthickness, width,
-			 0);
+			 NULL);
 	}
 
       /*
@@ -136,7 +139,7 @@
       Dimension bw = 0;
       Arg al[3];
 
-      XtVaGetValues (widget, XtNborderWidth, &bw, 0);
+      XtVaGetValues (widget, XtNborderWidth, &bw, NULL);
       if (bw == 0)
 	/* Don't let buttons end up with 0 borderwidth, that's ugly...
 	   Yeah, all this should really be done through app-defaults files
@@ -470,7 +473,7 @@
 
 #if 0
   user_data = NULL;
-  XtVaGetValues (widget, XtNuserData, &user_data, 0);
+  XtVaGetValues (widget, XtNuserData, &user_data, NULL);
 #else
   /* Damn!  Athena doesn't give us a way to hang our own data on the
      buttons, so we have to go find it...  I guess this assumes that
@@ -504,7 +507,7 @@
   Widget widget;
   if (! XtIsSubclass (shell, shellWidgetClass))
     abort ();
-  XtVaGetValues (shell, XtNchildren, &kids, 0);
+  XtVaGetValues (shell, XtNchildren, &kids, NULL);
   if (!kids || !*kids)
     abort ();
   widget = kids [0];
@@ -595,7 +598,7 @@
   Dimension width;
   Widget scrollbar;
 
-  XtVaGetValues (instance->parent, XtNwidth, &width, 0);
+  XtVaGetValues (instance->parent, XtNwidth, &width, NULL);
   
   XtSetArg (av[ac], XtNshowGrip, 0); ac++;
   XtSetArg (av[ac], XtNresizeToPreferred, 1); ac++;
@@ -610,7 +613,7 @@
 
   /* We have to force the border width to be 0 otherwise the
      geometry manager likes to start looping for awhile... */
-  XtVaSetValues (scrollbar, XtNborderWidth, 0, 0);
+  XtVaSetValues (scrollbar, XtNborderWidth, 0, NULL);
 
   XtRemoveAllCallbacks (scrollbar, "jumpProc");
   XtRemoveAllCallbacks (scrollbar, "scrollProc");
