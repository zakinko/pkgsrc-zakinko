$NetBSD$

Let the Qt cflags and libraries apply on NetBSD.

The pkg-config lookup is guarded by target_platform=="Linux", so a
NetBSD build gets no Qt flags and mozc_tool and mozc_renderer fail to
compile.

--- gui/qt_libraries.gypi.orig
+++ gui/qt_libraries.gypi
@@ -108,7 +108,7 @@
         '$(SDKROOT)/System/Library/Frameworks/Carbon.framework',
       ]
     }],
-    ['target_platform=="Linux"', {
+    ['target_platform=="Linux" or target_platform=="NetBSD"', {
       'cflags': ['<!@(pkg-config --cflags Qt<(qt_ver)Widgets Qt<(qt_ver)Gui Qt<(qt_ver)Core)'],
       'libraries': ['<!@(pkg-config --libs Qt<(qt_ver)Widgets Qt<(qt_ver)Gui Qt<(qt_ver)Core)'],
     }],
