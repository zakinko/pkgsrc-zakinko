$NetBSD$

NetBSD を platform の一覧に足す。

あわせて版の定義の在処を直す。3.34 は data/version/mozc_version_template.bzl
をやめて version.bzl にした。中身は同じ形なので、写しを置かずに参照先だけ
変える。

--- build_mozc.py.orig
+++ build_mozc.py
@@ -55,6 +55,7 @@
 from build_tools.util import ColoredText
 from build_tools.util import CopyFile
 from build_tools.util import IsLinux
+from build_tools.util import IsNetBSD
 from build_tools.util import IsMac
 from build_tools.util import IsWindows
 from build_tools.util import PrintErrorAndExit
@@ -100,6 +101,7 @@
       'Windows': 'out_win',
       'Mac': 'out_mac',
       'Linux': 'out_linux',
+      'NetBSD': 'out_bsd',
   }
 
   if target_platform not in platform_dict:
@@ -162,7 +164,7 @@
   # Include subdirectory of win32 and breakpad for Windows
   if options.target_platform == 'Windows':
     gyp_file_names.extend(glob.glob('%s/win32/*/*.gyp' % OSS_SRC_DIR))
-  elif options.target_platform == 'Linux':
+  elif options.target_platform in ('Linux', 'NetBSD'):
     gyp_file_names.extend(glob.glob('%s/unix/emacs/*.gyp' % OSS_SRC_DIR))
   gyp_file_names.sort()
   return gyp_file_names
@@ -183,7 +185,9 @@
 
 # TODO(b/68382821): Remove this method. We no longer need --target_platform.
 def AddTargetPlatformOption(parser):
-  if IsLinux():
+  if IsNetBSD():
+    default_target = 'NetBSD'
+  elif IsLinux():
     default_target = 'Linux'
   elif IsWindows():
     default_target = 'Windows'
@@ -240,7 +244,7 @@
   parser.add_option('--noqt', action='store_true', dest='noqt', default=False)
   parser.add_option('--version_file', dest='version_file',
                     help='use the specified version template file',
-                    default='data/version/mozc_version_template.bzl')
+                    default='version.bzl')
   AddTargetPlatformOption(parser)
 
   # Linux
@@ -313,6 +317,8 @@
   AddCommonOptions(parser)
   parser.add_option('--configuration', '-c', dest='configuration',
                     default='Debug', help='specify the build configuration.')
+  parser.add_option('--jobs', '-j', dest='jobs', type='int', default=None,
+                    metavar='N', help='run N compile jobs in parallel.')
 
   (options, args) = parser.parse_args(args)
 
@@ -495,7 +501,7 @@
     gyp_options.extend(['-D', 'use_qt=NO'])
   else:
     gyp_options.extend(['-D', 'use_qt=YES'])
-    if target_platform == 'Linux':
+    if target_platform in ('Linux', 'NetBSD'):
       if PkgExists('Qt6Core', 'Qt6Gui', 'Qt6Widgets'):
         qt_ver = 6
       elif PkgExists('Qt5Core', 'Qt5Gui', 'Qt5Widgets'):
@@ -634,7 +640,11 @@
 
   for target in targets:
     (_, target_name) = target.split(':')
-    RunOrDie([ninja, '-C', build_arg, target_name])
+    ninja_args = [ninja, '-C', build_arg]
+    if options.jobs:
+      ninja_args.extend(['-j', str(options.jobs)])
+    ninja_args.append(target_name)
+    RunOrDie(ninja_args)
 
 
 def BuildOnWindows(targets):
