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

--- src/xmenu.c.orig
+++ src/xmenu.c
@@ -1170,7 +1170,7 @@
     {
       XtManageChild (x->menubar_widget);
       XtMapWidget (x->menubar_widget);
-      XtVaSetValues (x->menubar_widget, XtNmappedWhenManaged, 1, 0);
+      XtVaSetValues (x->menubar_widget, XtNmappedWhenManaged, 1, NULL);
     }
 
 
@@ -1241,7 +1241,7 @@
 		     XtNshowGrip, 0,
 		     XtNresizeToPreferred, 1,
 		     XtNallowResize, 1,
-		     0);
+		     NULL);
     }
   
   free_menubar_widget_value_tree (first_wv);
