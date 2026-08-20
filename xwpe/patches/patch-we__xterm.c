$NetBSD$

WpeMouseRestoreShape is declared as void (*)(void) in edit.h, but assigned
a pointer cast to void (*)(WpeMouseShape).  The cast is wrong for this
variable; we_term.c already carries the plain assignment upstream.

https://github.com/NetBSD/pkgsrc/pull/180

--- we_xterm.c.orig
+++ we_xterm.c
@@ -162,7 +162,7 @@
  e_u_ini_size = e_ini_size;
  e_u_setlastpic = e_setlastpic;
  WpeMouseChangeShape = (void (*)(WpeMouseShape))WpeNullFunction;
- WpeMouseRestoreShape = (void (*)(WpeMouseShape))WpeNullFunction;
+ WpeMouseRestoreShape = WpeNullFunction;
 /* WpeMouseChangeShape = WpeXMouseChangeShape;
  WpeMouseRestoreShape = WpeXMouseRestoreShape;*/
  WpeDisplayEnd = e_x_display_end;
