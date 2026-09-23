$NetBSD$

Build with /bin/sh instead of bash; see patch-compile.sh.

This runs during the build.  [[ ]], pipefail, and two =~ matches that
are plain prefix tests, so case does them.

It also stops using sed to strip the carriage returns.  A \r on the left
of a sed s/// is a GNU extension; the sed in NetBSD, and in the other
BSDs, matches a literal r there and leaves the CR in place, so every
Add-Exports line keeps a stray character.  tr does it everywhere.
Upstream made the same change after 9.2.0.

--- src/main/cpp/generate_jvm_module_options.sh.orig
+++ src/main/cpp/generate_jvm_module_options.sh
@@ -1,4 +1,4 @@
-#!/bin/bash
+#!/bin/sh
 #
 # Copyright 2025 The Bazel Authors. All rights reserved.
 #
@@ -16,9 +16,9 @@
 #
 # Generates jvm_module_options.h from a deploy jar's manifest.
 
-set -euo pipefail
+set -eu
 
-if [[ $# -ne 2 ]]; then
+if [ $# -ne 2 ]; then
   echo "Usage: $0 <jar_file> <output_file>" >&2
   exit 1
 fi
@@ -41,23 +41,27 @@
   return {
 EOF
 
-if [[ -f "${JAR_FILE}" ]]; then
+if [ -f "${JAR_FILE}" ]; then
   # Extract options from manifest:
   # We first join continuation lines in the manifest, then grep for the headers we
   # care about, and then process them.
   unzip -p "${JAR_FILE}" META-INF/MANIFEST.MF 2>/dev/null | \
-      sed -e 's/\r$//' | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n / /g' | \
+      tr -d '\r' | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n / /g' | \
       grep -E '^(Add-Exports|Add-Opens):' | \
       while read -r line; do
-          if [[ "$line" =~ ^Add-Exports: ]]; then
+          case "$line" in
+          Add-Exports:*)
               key="--add-exports"
               values="${line#Add-Exports: }"
-          elif [[ "$line" =~ ^Add-Opens: ]]; then
+              ;;
+          Add-Opens:*)
               key="--add-opens"
               values="${line#Add-Opens: }"
-          else
+              ;;
+          *)
               continue
-          fi
+              ;;
+          esac
           for val in $values; do
               echo "    \"$key\", \"$val=ALL-UNNAMED\"," >> "${OUTPUT_FILE}"
           done
