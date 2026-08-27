$NetBSD: patch-gui_config__dialog_config__dialog.cc,v 1.8 2024/02/10 01:17:27 ryoon Exp $

Treat NetBSD like Linux here.  Upstream supports Linux, macOS, Windows,
Android and WASM only, so every POSIX path is spelled __linux__.

--- gui/config_dialog/config_dialog.cc.orig
+++ gui/config_dialog/config_dialog.cc
@@ -104,7 +104,7 @@
   setWindowTitle(tr("%1 Preferences").arg(GuiUtil::ProductName()));
 #endif  // __APPLE__
 
-#if defined(__linux__)
+#if defined(__linux__) || defined(__NetBSD__)
   miscDefaultIMEWidget->setVisible(false);
   miscAdministrationWidget->setVisible(false);
   miscStartupWidget->setVisible(false);
@@ -114,7 +114,7 @@
   // disable logging options
   miscLoggingWidget->setVisible(false);
 
-#if defined(__linux__)
+#if defined(__linux__) || defined(__NetBSD__)
   // The last "misc" tab has no valid configs on Linux
   constexpr int kMiscTabIndex = 6;
   configDialogTabWidget->removeTab(kMiscTabIndex);
@@ -280,7 +280,7 @@
   dictionaryPreloadingAndUACLabel->setVisible(false);
 #endif  // _WIN32
 
-#ifdef __linux__
+#if defined(__linux__) || defined(__NetBSD__)
   // On Linux, disable all fields for UsageStats
   usageStatsLabel->setEnabled(false);
   usageStatsLabel->setVisible(false);
