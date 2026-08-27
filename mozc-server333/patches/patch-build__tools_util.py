$NetBSD$

Add IsNetBSD(), which build_mozc.py needs to pick the target platform.

--- build_tools/util.py.orig
+++ build_tools/util.py
@@ -103,6 +103,11 @@
   return abs_path
 
 
+def IsNetBSD():
+  """Returns true if the platform is NetBSD."""
+  return os.name == 'posix' and os.uname()[0] == 'NetBSD'
+
+
 def GetNumberOfProcessors():
   """Returns the number of CPU cores available.
 
