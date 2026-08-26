$NetBSD: patch-gui_dictionary__tool_dictionary__tool.cc,v 1.7 2024/02/10 01:17:27 ryoon Exp $

--- gui/dictionary_tool/dictionary_tool.cc.orig
+++ gui/dictionary_tool/dictionary_tool.cc
@@ -353,7 +353,7 @@
   }
 
   // main window
-#ifndef __linux__
+#if !defined(__linux__) && !defined(__NetBSD__)
   // For some reason setCentralWidget crashes the dictionary_tool on Linux
   // TODO(taku): investigate the cause of the crashes
   setCentralWidget(splitter_);
