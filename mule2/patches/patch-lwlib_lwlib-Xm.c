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

--- lwlib/lwlib-Xm.c.orig
+++ lwlib/lwlib-Xm.c
@@ -237,7 +237,7 @@
 xm_update_pushbutton (widget_instance* instance, Widget widget,
 		      widget_value* val)
 {
-  XtVaSetValues (widget, XmNalignment, XmALIGNMENT_CENTER, 0);
+  XtVaSetValues (widget, XmNalignment, XmALIGNMENT_CENTER, NULL);
   XtRemoveAllCallbacks (widget, XmNactivateCallback);
   XtAddCallback (widget, XmNactivateCallback, xm_generic_callback, instance);
 }
@@ -260,7 +260,7 @@
   XtAddCallback (widget, XmNvalueChangedCallback,
 		 xm_internal_update_other_instances, instance);
   XtVaSetValues (widget, XmNset, val->selected,
-		 XmNalignment, XmALIGNMENT_BEGINNING, 0);
+		 XmNalignment, XmALIGNMENT_BEGINNING, NULL);
 }
 
 static void
@@ -285,11 +285,11 @@
       toggle = XtNameToWidget (widget, cur->value);
       if (toggle)
 	{
-	  XtVaSetValues (toggle, XmNsensitive, cur->enabled, 0);
+	  XtVaSetValues (toggle, XmNsensitive, cur->enabled, NULL);
 	  if (!val->value && cur->selected)
-	    XtVaSetValues (toggle, XmNset, cur->selected, 0);
+	    XtVaSetValues (toggle, XmNset, cur->selected, NULL);
 	  if (val->value && strcmp (val->value, cur->value))
-	    XtVaSetValues (toggle, XmNset, False, 0);
+	    XtVaSetValues (toggle, XmNset, False, NULL);
 	}
     }
 
@@ -298,7 +298,7 @@
     {
       toggle = XtNameToWidget (widget, val->value);
       if (toggle)
-	XtVaSetValues (toggle, XmNset, True, 0);
+	XtVaSetValues (toggle, XmNset, True, NULL);
     }
 }
 
@@ -416,7 +416,7 @@
   XtVaSetValues (widget,
 		 XmNsensitive, val->enabled,
 		 XmNuserData, val->call_data,
-		 0);
+		 NULL);
 
   /* update the menu button as a label. */
   if (val->change >= VISIBLE_CHANGE)
@@ -533,7 +533,7 @@
   XtVaSetValues (widget,
 		 XmNsensitive, val->enabled,
 		 XmNuserData, val->call_data,
-		 0);
+		 NULL);
   
   /* Common to all label like widgets */
   if (XtIsSubclass (widget, xmLabelWidgetClass))
@@ -601,7 +601,7 @@
   
   if (class == xmToggleButtonWidgetClass || class == xmToggleButtonGadgetClass)
     {
-      XtVaGetValues (widget, XmNset, &val->selected, 0);
+      XtVaGetValues (widget, XmNset, &val->selected, NULL);
       val->edited = True;
     }
   else if (class == xmTextWidgetClass)
@@ -636,7 +636,7 @@
 	      int set = False;
 	      Widget toggle = radio->composite.children [i];
 	      
-	      XtVaGetValues (toggle, XmNset, &set, 0);
+	      XtVaGetValues (toggle, XmNset, &set, NULL);
 	      if (set)
 		{
 		  if (val->value)
@@ -996,9 +996,9 @@
   Position x;
   Position y;
 
-  XtVaGetValues (widget, XtNwidth, &child_width, XtNheight, &child_height, 0);
+  XtVaGetValues (widget, XtNwidth, &child_width, XtNheight, &child_height, NULL);
   XtVaGetValues (parent, XtNwidth, &parent_width, XtNheight, &parent_height,
-		 0);
+		 NULL);
 
   x = (((Position)parent_width) - ((Position)child_width)) / 2;
   y = (((Position)parent_height) - ((Position)child_height)) / 2;
@@ -1015,7 +1015,7 @@
   if (y < 0)
     y = 0;
 
-  XtVaSetValues (widget, XtNx, x, XtNy, y, 0);
+  XtVaSetValues (widget, XtNx, x, XtNy, y, NULL);
 }
 
 static Widget
@@ -1045,7 +1045,7 @@
       /* shrink the separator label back to their original size */
       separator = XtNameToWidget (widget, "*separator_button");
       if (separator)
-	XtVaSetValues (separator, XtNwidth, 5, XtNheight, 5, 0);
+	XtVaSetValues (separator, XtNwidth, 5, XtNheight, 5, NULL);
 
       /* Center the dialog in its parent */
       recenter_widget (widget);
@@ -1346,7 +1346,7 @@
       else if (event->xbutton.state & Button3Mask) trans = "<Btn3Down>";
       else if (event->xbutton.state & Button2Mask) trans = "<Btn2Down>";
       else if (event->xbutton.state & Button1Mask) trans = "<Btn1Down>";
-      if (trans) XtVaSetValues (widget, XmNmenuPost, trans, 0);
+      if (trans) XtVaSetValues (widget, XmNmenuPost, trans, NULL);
       XmMenuPosition (widget, (XButtonPressedEvent *) event);
     }
   XtManageChild (widget);
@@ -1357,8 +1357,8 @@
 {
   short width;
   short height;
-  XtVaGetValues (w, XmNwidth, &width, XmNheight, &height, 0);
-  XtVaSetValues (w, XmNminWidth, width, XmNminHeight, height, 0);
+  XtVaGetValues (w, XmNwidth, &width, XmNheight, &height, NULL);
+  XtVaSetValues (w, XmNminWidth, width, XmNminHeight, height, NULL);
 }
 
 void
