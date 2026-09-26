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

--- lwlib/lwlib-Xol.c.orig
+++ lwlib/lwlib-Xol.c
@@ -55,7 +55,7 @@
   if (w->core.being_destroyed)
     return;
 
-  XtVaGetValues (w, XtNuserData, &instance, 0);
+  XtVaGetValues (w, XtNuserData, &instance, NULL);
 
   if (!instance)
     return;
@@ -71,7 +71,7 @@
 {
   Widget widget =
     XtVaCreateWidget (instance->info->name, controlAreaWidgetClass,
-		      instance->parent, 0);
+		      instance->parent, NULL);
   return widget;
 }
 
@@ -191,7 +191,7 @@
 	  button =
 	    XtCreateManagedWidget (cur->name, menuButtonWidgetClass, widget,
 				   al, ac);
-	  XtVaGetValues (button, XtNmenuPane, &menu, 0);
+	  XtVaGetValues (button, XtNmenuPane, &menu, NULL);
 	  if (!menu)
 	    abort ();
 	  make_menu_in_widget (instance, menu, cur->contents);
@@ -213,12 +213,12 @@
     return;
 
   /* update the sensitivity */
-  XtVaSetValues (widget, XtNsensitive, val->enabled, 0);
+  XtVaSetValues (widget, XtNsensitive, val->enabled, NULL);
 
   /* update the pulldown/pullaside as needed */
   ac = 0;
   menu = NULL;
-  XtVaGetValues (widget, XtNmenuPane, &menu, 0);
+  XtVaGetValues (widget, XtNmenuPane, &menu, NULL);
   contents = val->contents;
 
   if (!menu)
@@ -285,7 +285,7 @@
   Widget menu = widget;
 
   if (XtIsShell (widget))
-    XtVaGetValues (widget, XtNmenuPane, &menu, 0);
+    XtVaGetValues (widget, XtNmenuPane, &menu, NULL);
 
   update_menu_widget (instance, menu, val);
 }
