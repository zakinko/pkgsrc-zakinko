$NetBSD$

Teach the build driver about NetBSD, and let it pass -j through to ninja.

BuildWithNinja() invoked ninja with no -j, so ninja used its own default
of CPU count + 2 and MAKE_JOBS never reached the compiler.  On a machine
with little memory that is the difference between building and being
killed: on a 3 GB i386 guest with 4 CPUs, cc1plus was OOM killed while
compiling protobuf's descriptor.cc.

The --jobs option is not NetBSD specific and would be useful upstream.

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
