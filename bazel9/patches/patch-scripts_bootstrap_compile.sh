$NetBSD$

Run the annotation processors on JDK 23 and newer, first stage.

javac stopped running annotation processors it finds on the classpath
unless it is asked to, so the AutoValue and AutoService processors never
run and none of the generated classes exist:

	DependencyError.java:135: error: cannot find symbol
	  symbol: variable AutoOneOf_DependencyError
	... 178 errors

-proc:full asks for the old behaviour back.  It is only passed from 23
onwards, because the option does not exist before 21 and the default is
already what we want up to 22.

This covers the javac that builds the bootstrap bazel and nothing else.
Once that bazel runs, tools/build_rules/java_rules_skylark.bzl calls the
JDK's javac again from a genrule, and the same thing happens there 1,778
actions later.  That one takes --javacopt and --host_javacopt rather than
a patch; the Makefile passes them.  Change one and look at the other.

Upstream solved this after 9.2.0 by naming the processors explicitly
(-processor) and splitting the compilation in two, which is a larger
change than belongs in a patch here.  It did not solve the genrule.


It is also converted to /bin/sh; see patch-compile.sh.

--- scripts/bootstrap/compile.sh.orig
+++ scripts/bootstrap/compile.sh
@@ -1,4 +1,4 @@
-#!/usr/bin/env bash
+#!/bin/sh
 
 # Copyright 2015 The Bazel Authors. All rights reserved.
 #
@@ -29,7 +29,9 @@
 MAVEN_JARS=$(find "derived/maven" -name '*.jar' | sort | grep -Fv netty-tcnative | tr "\n" " ")
 LIBRARY_JARS="${LIBRARY_JARS} ${MAVEN_JARS}"
 
-DIRS=$(echo src/{java_tools/singlejar/java/com/google/devtools/build/zip,main/java,tools/starlark/java} tools/java/runfiles ${OUTPUT_DIR}/src)
+# Brace expansion is a bash-ism; POSIX sh leaves "src/{a,b}" literal, so the
+# directories are listed out in full here.
+DIRS="src/java_tools/singlejar/java/com/google/devtools/build/zip src/main/java src/tools/starlark/java tools/java/runfiles ${OUTPUT_DIR}/src"
 # Exclude source files that are not needed for Bazel itself, which avoids dependencies like truth.
 # Also exclude TreeArtifactValueCodec.java which requires AutoCodec to run, but that's not needed during bootstrap.
 EXCLUDE_FILES="src/java_tools/buildjar/java/com/google/devtools/build/buildjar/javac/testing/* src/main/java/com/google/devtools/build/lib/collect/nestedset/NestedSetCodecTestUtils.java src/main/java/com/google/devtools/build/lib/skyframe/TreeArtifactValueCodec.java"
@@ -38,7 +40,7 @@
 EXCLUDE_DIRS="src/main/java/com/google/devtools/build/docgen src/main/java/com/google/devtools/build/lib/skyframe/serialization/testutils src/main/java/com/google/devtools/common/options/testing src/main/java/com/google/devtools/build/lib/testing"
 for d in $EXCLUDE_DIRS ; do
   for f in $(find $d -type f) ; do
-    EXCLUDE_FILES+=" $f"
+    EXCLUDE_FILES="${EXCLUDE_FILES} $f"
   done
 done
 
@@ -55,7 +57,7 @@
 
 MSYS_DLLS=""
 
-function get_minor_java_version() {
+get_minor_java_version() {
   get_java_version
   java_minor_version=$(echo $JAVA_VERSION | sed 's/[^.][^.]*\.//' | sed 's/\..*$//')
   javac_minor_version=$(echo $JAVAC_VERSION | sed 's/[^.][^.]*\.//' | sed 's/\..*$//')
@@ -69,10 +71,10 @@
 JAR="${JAVA_HOME}/bin/jar"
 
 # Ensures unzip won't create paths longer than 259 chars (MAX_PATH) on Windows.
-function check_unzip_wont_create_long_paths() {
+check_unzip_wont_create_long_paths() {
   output_path="$1"
   jars="$2"
-  if [[ "${PLATFORM}" == "windows" ]]; then
+  if [ "${PLATFORM}" = "windows" ]; then
     log "Checking if helper classes can be extracted..."
     max_path=$((259-${#output_path}))
     # Do not quote $jars, we rely on it being split on spaces.
@@ -80,7 +82,7 @@
       # Get the zip entries. Match lines with a date: they have the paths.
       entries="$(unzip -l "$f" | grep '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}' | awk '{print $4}')"
       for e in $entries; do
-        if [[ ${#e} -gt $max_path ]]; then
+        if [ ${#e} -gt $max_path ]; then
           fail "Cannot unzip \"$f\" because the output path is too long: extracting file \"$e\" under \"$output_path\" would create a path longer than 259 characters. To fix this, set a shorter TMP value and try again. Example: export TMP=/c/tmp/bzl"
         fi
       done
@@ -89,15 +91,15 @@
 }
 
 # Compiles java classes.
-function java_compilation() {
-  local name=$1
-  local directories=$2
-  local excludes=$3
-  local library_jars=$4
-  local output=$5
+java_compilation() {
+  local name="$1"
+  local directories="$2"
+  local excludes="$3"
+  local library_jars="$4"
+  local output="$5"
 
-  local classpath=${library_jars// /$PATHSEP}${PATHSEP}$5
-  local sourcepath=${directories// /$PATHSEP}
+  local classpath="$(printf '%s' "${library_jars}" | tr ' ' "$PATHSEP")${PATHSEP}$5"
+  local sourcepath="$(printf '%s' "${directories}" | tr ' ' "$PATHSEP")"
 
   tempdir
   local tmp="${NEW_TMPDIR}"
@@ -131,6 +133,14 @@
 
   check_unzip_wont_create_long_paths "${output}/classes" "$library_jars"
 
+  # javac 23 and later do not run annotation processors found on the
+  # classpath unless asked; without this the AutoValue processor never
+  # runs and the build stops on missing AutoValue_/AutoOneOf_ classes.
+  local proc_full=""
+  case "${JAVAC_VERSION}" in
+    1.2[3-9]|1.[3-9][0-9]) proc_full="-proc:full" ;;
+  esac
+
   # Use BAZEL_JAVAC_OPTS to pass additional arguments to javac, e.g.,
   # export BAZEL_JAVAC_OPTS="-J-Xmx2g -J-Xms200m"
   # Useful if your system chooses too small of a max heap for javac.
@@ -139,6 +149,7 @@
   run "${JAVAC}" -classpath "${classpath}" -sourcepath "${sourcepath}" \
       -d "${output}/classes" -source "$JAVA_VERSION" -target "$JAVA_VERSION" \
       -encoding UTF-8 --add-exports=java.base/jdk.internal.misc=ALL-UNNAMED \
+      ${proc_full} \
       --add-exports=java.base/jdk.internal.vm=ALL-UNNAMED \
       ${BAZEL_JAVAC_OPTS} "@${paramfile}"
 
@@ -149,21 +160,21 @@
 }
 
 # Create the deploy JAR
-function create_deploy_jar() {
-  local name=$1
-  local mainClass=$2
-  local output=$3
+create_deploy_jar() {
+  local name="$1"
+  local mainClass="$2"
+  local output="$3"
   shift 3
   local packages=""
   # Only keep the services subdirectory of META-INF (needed for AutoService).
   for i in $output/classes/META-INF/*; do
-    local package=$(basename $i)
-    if [[ "$package" != "services" ]]; then
+    local package="$(basename $i)"
+    if [ "$package" != "services" ]; then
       rm -r "$i"
     fi
   done
   for i in $output/classes/*; do
-    local package=$(basename $i)
+    local package="$(basename $i)"
     packages="$packages -C $output/classes $package"
   done
 
@@ -210,10 +221,10 @@
         [ -n "${GRPC_JAVA_PLUGIN}" ] \
             || fail "Must specify GRPC_JAVA_PLUGIN if not bootstrapping from the distribution artifact${HOW_TO_BOOTSTRAP}"
 
-        [[ -x "${PROTOC-}" ]] \
+        [ -x "${PROTOC-}" ] \
             || fail "Protobuf compiler not found in ${PROTOC-}"
 
-        [[ -x "${GRPC_JAVA_PLUGIN-}" ]] \
+        [ -x "${GRPC_JAVA_PLUGIN-}" ] \
             || fail "gRPC Java plugin not found in ${GRPC_JAVA_PLUGIN-}"
 
         log "Compiling Java stubs for protocol buffers..."
@@ -323,22 +334,22 @@
 ARCHIVE_DIR=${OUTPUT_DIR}/archive
 mkdir -p ${ARCHIVE_DIR}
 
-function build_jni() {
-  local -r output_dir=$1
+build_jni() {
+  local output_dir="$1"
 
   if [ "${PLATFORM}" = "windows" ]; then
     # We need JNI on Windows because some filesystem operations are not (and
     # cannot be) implemented in native Java.
     log "Building Windows JNI library..."
 
-    local -r jni_lib_name="windows_jni.dll"
-    local -r output="${output_dir}/${jni_lib_name}"
-    local -r tmp_output="${NEW_TMPDIR}/jni/${jni_lib_name}"
+    local jni_lib_name="windows_jni.dll"
+    local output="${output_dir}/${jni_lib_name}"
+    local tmp_output="${NEW_TMPDIR}/jni/${jni_lib_name}"
     mkdir -p "$(dirname "$tmp_output")"
     mkdir -p "$(dirname "$output")"
 
     # Keep this in sync with the `srcs` of //src/main/native/windows:windows_jni
-    local -r srcs="src/main/native/common.cc $(find src/main/native/windows -name '*.cc' -o -name '*.h')"
+    local srcs="src/main/native/common.cc $(find src/main/native/windows -name '*.cc' -o -name '*.h')"
     [ -n "$srcs" ] || fail "Could not find sources for Windows JNI library"
 
     # do not quote $srcs because we need to expand it to multiple args
@@ -361,24 +372,26 @@
 
 # TODO(b/28965185): Remove when xcode-locator is no longer required in embedded_binaries.
 log "Compiling xcode-locator..."
-if [[ $PLATFORM == "darwin" ]]; then
+if [ "$PLATFORM" = "darwin" ]; then
   run /usr/bin/xcrun --sdk macosx clang -mmacosx-version-min=10.13 -fobjc-arc -framework CoreServices -framework Foundation -o ${ARCHIVE_DIR}/xcode-locator tools/osx/xcode_locator.m
 else
   cp tools/osx/xcode_locator_stub.sh ${ARCHIVE_DIR}/xcode-locator
 fi
 
-function get_cwd() {
-  local result=${PWD}
+get_cwd() {
+  local result="${PWD}"
   [ "$PLATFORM" = "windows" ] && result="$(cygpath -m "$result")"
   echo "$result"
 }
 
-function run_bazel_jar() {
-  local command=$1
+run_bazel_jar() {
+  local command="$1"
   shift
-  local client_env=()
   # Propagate all environment variables to bootstrapped Bazel.
   # See https://stackoverflow.com/questions/41898503/loop-over-environment-variables-in-posix-sh
+  # We append each --client_env to the positional parameters (there are no
+  # arrays in POSIX sh); their order relative to the command's own arguments
+  # does not matter to Bazel.
   local env_vars="$(awk 'END { for (name in ENVIRON) { if(name != "_" && name ~ /^[A-Za-z0-9_]*$/) print name; } }' </dev/null)"
   for varname in $env_vars; do
     eval value=\$$varname
@@ -386,7 +399,7 @@
       varname="$(echo "$varname" | tr [:lower:] [:upper:])"
     fi
     if [ "${value}" ]; then
-      client_env=("${client_env[@]}" --client_env="${varname}=${value}")
+      set -- "$@" --client_env="${varname}=${value}"
     fi
   done
 
@@ -412,7 +425,6 @@
       --startup_time=329 --extract_data_time=523 \
       --rc_source=/dev/null --isatty=1 \
       --build_python_zip \
-      "${client_env[@]}" \
       --client_cwd="$(get_cwd)" \
       "${@}"
 }
