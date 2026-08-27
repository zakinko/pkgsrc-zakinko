$NetBSD: patch-gui_config__dialog_keymap__editor.cc,v 1.4 2024/02/10 01:17:27 ryoon Exp $

Treat NetBSD like Linux here.  Upstream supports Linux, macOS, Windows,
Android and WASM only, so every POSIX path is spelled __linux__.

--- gui/config_dialog/keymap_editor.cc.orig
+++ gui/config_dialog/keymap_editor.cc
@@ -442,7 +442,7 @@
   absl::StrAppend(keymap_table, invisible_keymap_table_);
 
   if (new_direct_mode_commands != direct_mode_commands_) {
-#if defined(_WIN32) || defined(__linux__)
+#if defined(_WIN32) || defined(__linux__) || defined(__NetBSD__)
     QMessageBox::information(
         this, windowTitle(),
         tr("Changes of keymaps for direct input mode will apply only to "
