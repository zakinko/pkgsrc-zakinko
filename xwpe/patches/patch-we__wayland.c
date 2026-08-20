$NetBSD$

Same as patch-we__xterm.c, for the Wayland backend added in 1.6.6.
WpeMouseRestoreShape is void (*)(void); the cast to void (*)(WpeMouseShape)
is wrong.

https://github.com/NetBSD/pkgsrc/pull/180

--- we_wayland.c.orig
+++ we_wayland.c
@@ -1887,7 +1887,7 @@
  e_u_ini_size      = e_w_ini_size;
  e_u_setlastpic    = e_setlastpic;
  WpeMouseChangeShape  = (void (*)(WpeMouseShape))WpeNullFunction;
- WpeMouseRestoreShape = (void (*)(WpeMouseShape))WpeNullFunction;
+ WpeMouseRestoreShape = WpeNullFunction;
  WpeDisplayEnd     = e_w_display_end;
  e_u_switch_screen = WpeZeroFunction;
  e_u_d_switch_out  = (int (*)(int))WpeZeroFunction;
