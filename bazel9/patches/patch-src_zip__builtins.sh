$NetBSD$

Build with /bin/sh instead of bash; see patch-compile.sh.

The shebang, and pipefail, which is not in POSIX sh.  Every pipeline in
this script ends in the command whose status matters, so -eu alone
leaves the error handling as it was.

--- src/zip_builtins.sh.orig
+++ src/zip_builtins.sh
@@ -1,4 +1,4 @@
-#!/usr/bin/env bash
+#!/bin/sh
 
 # Copyright 2020 The Bazel Authors. All rights reserved.
 #
@@ -20,7 +20,9 @@
 # Usage:
 #     zip_builtins.sh zip output builtins_root files...
 
-set -euo pipefail
+# pipefail is not in POSIX sh; the last command of each pipeline below is
+# the one whose status matters, so -eu is enough.
+set -eu
 
 origdir="$(pwd)"
 
