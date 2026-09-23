$NetBSD$

Build with /bin/sh instead of bash.

NetBSD has no bash in the base system.  Requiring one to bootstrap bazel
means a package that cannot build until another package is built first,
on every platform, for three constructs that all have plain sh
spellings: source, [[ ]] and $PLATFORM quoting.

The same conversion is offered upstream, but pkgsrc stays on 9.2.0, so
it is carried here whatever happens to that.

--- compile.sh.orig
+++ compile.sh
@@ -1,4 +1,4 @@
-#!/usr/bin/env bash
+#!/bin/sh
 
 # Copyright 2014 The Bazel Authors. All rights reserved.
 #
@@ -33,7 +33,7 @@
 unset MSYS_NO_PATHCONV
 unset MSYS2_ARG_CONV_EXCL
 
-source scripts/bootstrap/buildenv.sh
+. scripts/bootstrap/buildenv.sh
 
 mkdir -p output
 : ${BAZEL:=}
@@ -43,7 +43,7 @@
 #
 if [ ! -x "${BAZEL}" ]; then
   new_step 'Building Bazel from scratch'
-  source scripts/bootstrap/compile.sh
+  . scripts/bootstrap/compile.sh
 fi
 
 #
@@ -55,12 +55,12 @@
   EMBED_LABEL="$(get_last_version) (@${git_sha1:-non-git})"
 fi
 
-if [[ $PLATFORM == "darwin" ]] && \
+if [ "$PLATFORM" = "darwin" ] && \
     xcodebuild -showsdks 2> /dev/null | grep -q '\-sdk iphonesimulator'; then
   EXTRA_BAZEL_ARGS="${EXTRA_BAZEL_ARGS-} --define IPHONE_SDK=1"
 fi
 
-source scripts/bootstrap/bootstrap.sh
+. scripts/bootstrap/bootstrap.sh
 
 new_step 'Building Bazel with Bazel'
 display "."
