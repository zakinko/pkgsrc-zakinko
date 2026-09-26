$NetBSD$

The varargs list of XtVaSetValues is terminated by a null pointer, not by the
integer 0.  On LP64 those are different widths, so the callee kept reading past
the end of the list.

--- src/xmenu.c.orig	1998-12-28 23:15:47.000000000 +0100
+++ src/xmenu.c	2008-04-02 22:40:18.000000000 +0200
@@ -1500,7 +1501,7 @@
     {
       XtManageChild (x->menubar_widget);
       XtMapWidget (x->menubar_widget);
-      XtVaSetValues (x->menubar_widget, XtNmappedWhenManaged, 1, 0);
+      XtVaSetValues (x->menubar_widget, XtNmappedWhenManaged, 1, NULL);
     }
 
   /* Re-manage the text-area widget, and then thrash the sizes.  */
