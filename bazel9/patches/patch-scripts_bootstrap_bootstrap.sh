$NetBSD$

Build with /bin/sh instead of bash; see patch-compile.sh.

Three things here are bash-only.  The shebang, "function name()" where
sh wants "name()", and an array -- EMBED_LABEL_ARG was built as a bash
array so that an empty label expands to no arguments at all.  sh has no
arrays, so the branch is taken where the label is used instead, which
gives the same two shapes of command line.

local is kept.  It is not in POSIX, but dash, the NetBSD /bin/sh and
busybox ash all have it, and dropping it would mean renaming variables
to avoid collisions across functions that this script calls in sequence.

--- scripts/bootstrap/bootstrap.sh.orig
+++ scripts/bootstrap/bootstrap.sh
@@ -1,4 +1,4 @@
-#!/usr/bin/env bash
+#!/bin/sh
 
 # Copyright 2015 The Bazel Authors. All rights reserved.
 #
@@ -24,11 +24,6 @@
 : ${EMBED_LABEL:=""}
 : ${SOURCE_DATE_EPOCH:=""}
 
-EMBED_LABEL_ARG=()
-if [ -n "${EMBED_LABEL}" ]; then
-    EMBED_LABEL_ARG=(--stamp --embed_label "${EMBED_LABEL}")
-fi
-
 : ${JAVA_VERSION:="21"}
 
 # TODO: remove `--repo_env=BAZEL_HTTP_RULES_URLS_AS_DEFAULT_CANONICAL_ID=0` once all dependencies are
@@ -58,7 +53,7 @@
 cp scripts/bootstrap/BUILD.bootstrap scripts/bootstrap/BUILD
 
 if [ -z "${BAZEL-}" ]; then
-  function _run_bootstrapping_bazel() {
+  _run_bootstrapping_bazel() {
     local command=$1
     shift
     run_bazel_jar $command \
@@ -66,7 +61,7 @@
         --javacopt="-g" "${@}"
   }
 else
-  function _run_bootstrapping_bazel() {
+  _run_bootstrapping_bazel() {
     local command=$1
     shift
     ${BAZEL} --bazelrc=${BAZELRC} ${BAZEL_DIR_STARTUP_OPTIONS} $command \
@@ -75,10 +70,14 @@
   }
 fi
 
-function bazel_build() {
-  _run_bootstrapping_bazel build "${EMBED_LABEL_ARG[@]}" "$@"
+bazel_build() {
+  if [ -n "${EMBED_LABEL}" ]; then
+    _run_bootstrapping_bazel build --stamp --embed_label "${EMBED_LABEL}" "$@"
+  else
+    _run_bootstrapping_bazel build "$@"
+  fi
 }
 
-function get_bazel_bin_path() {
+get_bazel_bin_path() {
   _run_bootstrapping_bazel info "bazel-bin" || echo "bazel-bin"
 }
