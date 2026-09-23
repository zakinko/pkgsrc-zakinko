$NetBSD$

Point the bootstrap at the JDK pkgsrc installs.

Each system names its own default here.  Without an entry the bootstrap
runs with an empty JAVA_HOME and fails looking for javac.


It is also converted to /bin/sh; see patch-compile.sh.  This file is the
largest part of that: it is sourced by all three of the scripts above,
and it carries the arrays, [[ ]], "function name()" and ${var,,} that
the rest of the bootstrap inherits.

--- scripts/bootstrap/buildenv.sh.orig
+++ scripts/bootstrap/buildenv.sh
@@ -1,4 +1,4 @@
-#!/usr/bin/env bash
+#!/bin/sh
 
 # Copyright 2015 The Bazel Authors. All rights reserved.
 #
@@ -22,7 +22,7 @@
 # List: https://github.com/bazelbuild/bazel/issues/7641#issuecomment-472344261
 for tool in basename cat chmod comm cp dirname find grep ln ls mkdir mktemp \
             readlink rm sed sort tail touch tr uname unzip which; do
-  if ! hash "$tool" >/dev/null; then
+  if ! command -v "$tool" >/dev/null; then
     echo >&2 "ERROR: cannot find \"$tool\"; check your PATH."
     echo >&2 "       You may need to run the following command or similar:"
     echo >&2 "         export PATH=\"/bin:/usr/bin:\$PATH\""
@@ -35,7 +35,7 @@
 case "$(uname -s | tr "[:upper:]" "[:lower:]")" in
 msys*|mingw*|cygwin*)
   # Ensure Python is on the PATH, otherwise the bootstrapping fails later.
-  if ! hash python.exe >/dev/null; then
+  if ! command -v python.exe >/dev/null; then
     echo >&2 "ERROR: cannot locate python.exe; check your PATH."
     echo >&2 "       You may need to run the following command, or something"
     echo >&2 "       similar, depending on where you installed Python:"
@@ -62,9 +62,9 @@
 
 # We define the fail function early so we can use it when detecting the JDK
 # See https://github.com/bazelbuild/bazel/issues/2949,
-function fail() {
-  local exitCode=$?
-  if [[ "$exitCode" = "0" ]]; then
+fail() {
+  local exitCode="$?"
+  if [ "$exitCode" = "0" ]; then
     exitCode=1
   fi
   echo >&2
@@ -73,9 +73,10 @@
 }
 
 
-# Set standard variables
-DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
-WORKSPACE_DIR="$(dirname "$(dirname "${DIR}")")"
+# Set standard variables.  This file is sourced from the workspace root
+# (compile.sh cds there first), so the tree layout gives us the directories.
+WORKSPACE_DIR="$(pwd)"
+DIR="${WORKSPACE_DIR}/scripts/bootstrap"
 
 JAVA_VERSION=${JAVA_VERSION:-21}
 BAZELRC=${BAZELRC:-"/dev/null"}
@@ -93,13 +94,18 @@
   JAVA_HOME="${JAVA_HOME:-/usr/local/openjdk11}"
   ;;
 
+netbsd)
+  # JAVA_HOME must point to a Java installation.
+  JAVA_HOME="${JAVA_HOME:-@PKG_JAVA_HOME@}"
+  ;;
+
 openbsd)
   # JAVA_HOME must point to a Java installation.
   JAVA_HOME="${JAVA_HOME:-/usr/local/jdk-11}"
   ;;
 
 darwin)
-  if [[ -z "$JAVA_HOME" ]]; then
+  if [ -z "$JAVA_HOME" ]; then
     JAVA_HOME="$(/usr/libexec/java_home -v ${JAVA_VERSION}+ 2> /dev/null)" \
       || fail "Could not find JAVA_HOME, please ensure a JDK (version ${JAVA_VERSION}+) is installed."
   fi
@@ -112,11 +118,11 @@
   # Find the latest available version of the SDK.
   JAVA_HOME="${JAVA_HOME:-$(ls -d C:/Program\ Files/Java/jdk* | sort | tail -n 1)}"
   # Replace backslashes with forward slashes.
-  JAVA_HOME="${JAVA_HOME//\\//}"
+  JAVA_HOME="$(printf '%s' "$JAVA_HOME" | tr '\\' '/')"
 esac
 
 EXE_EXT=""
-if [ "${PLATFORM}" == "windows" ]; then
+if [ "${PLATFORM}" = "windows" ]; then
   # Extension for executables.
   EXE_EXT=".exe"
 
@@ -137,7 +143,7 @@
 #
 # The handlers will be invoked at exit time in the order they were registered.
 # See comments in run_atexit for more details.
-function atexit() {
+atexit() {
   local handler="${1}"; shift
 
   [ -n "${ATEXIT_HANDLERS}" ] || trap 'run_atexit_handlers $?' EXIT
@@ -149,7 +155,7 @@
 # If the program exited with an error, this exit routine will also exit with the
 # same error.  However, if the program exited successfully, this exit routine
 # will only exit successfully if the atexit handlers succeed.
-function run_atexit_handlers() {
+run_atexit_handlers() {
   local exit_code="$?"
 
   local failed=no
@@ -170,20 +176,20 @@
   fi
 }
 
-function tempdir() {
-  local tmp=${TMPDIR:-/tmp}
+tempdir() {
+  local tmp="${TMPDIR:-/tmp}"
   mkdir -p "${tmp}"
   local DIR="$(mktemp -d "${tmp%%/}/bazel_XXXXXXXX")"
   mkdir -p "${DIR}"
-  local DIRBASE=$(basename "${DIR}")
-  eval "cleanup_tempdir_${DIRBASE}() { rm -rf '${DIR}' >&/dev/null || true ; }"
+  local DIRBASE="$(basename "${DIR}")"
+  eval "cleanup_tempdir_${DIRBASE}() { rm -rf '${DIR}' >/dev/null 2>&1 || true ; }"
   atexit cleanup_tempdir_${DIRBASE}
   NEW_TMPDIR="${DIR}"
 }
 tempdir
 OUTPUT_DIR=${NEW_TMPDIR}
 phasefile=${OUTPUT_DIR}/phase
-function cleanup_phasefile() {
+cleanup_phasefile() {
   if [ -f "${phasefile}" ]; then
     echo 1>&2;
     cat "${phasefile}" 1>&2;
@@ -198,7 +204,7 @@
 # If VERBOSE is no, the command's output is only displayed in case of failure.
 #
 # Exits the script if the command fails.
-function run() {
+run() {
   if [ "${VERBOSE}" = yes ]; then
     echo "${@}"
     "${@}" || exit $?
@@ -214,18 +220,27 @@
   fi
 }
 
-function display() {
-  if [[ -z "${QUIETMODE}" ]]; then
-    echo -e "$@" >&2
+# Displays a message to stderr, interpreting backslash escapes.  A leading
+# -n suppresses the trailing newline, like "echo -n".  We use printf rather
+# than "echo -e"/"echo -n" because those are not portable across shells.
+display() {
+  if [ -n "${QUIETMODE}" ]; then
+    return 0
+  fi
+  if [ "$1" = "-n" ]; then
+    shift
+    printf '%b' "$*" >&2
+  else
+    printf '%b\n' "$*" >&2
   fi
 }
 
-function log() {
-  echo -n "." >&2
+log() {
+  printf '.' >&2
   echo "$1" >${phasefile}
 }
 
-function clear_log() {
+clear_log() {
   echo >&2
   rm -f ${phasefile}
 }
@@ -235,7 +250,7 @@
 WARNING="\033[31mWARN\033[0m:"
 
 first_step=1
-function new_step() {
+new_step() {
   rm -f ${phasefile}
   local new_line=
   if [ -n "${first_step}" ]; then
@@ -250,13 +265,13 @@
   fi
 }
 
-function git_sha1() {
+git_sha1() {
   if [ -x "$(which git 2>/dev/null)" ] && [ -d .git ]; then
     git rev-parse --short HEAD 2>/dev/null || true
   fi
 }
 
-function git_date() {
+git_date() {
   if [ -x "$(which git 2>/dev/null)" ] && [ -d .git ]; then
     git log -1 --pretty=%ai | cut -d " " -f 1 || true
   fi
@@ -264,9 +279,9 @@
 
 # Get the latest release version and append the date of
 # the last commit if any.
-function get_last_version() {
+get_last_version() {
   if [ -f "MODULE.bazel" ]; then
-    local version=$(grep "version =" MODULE.bazel | head -n 1 | sed 's/.*version = "\(.*\)".*/\1/' | cut -d '"' -f2)
+    local version="$(grep "version =" MODULE.bazel | head -n 1 | sed 's/.*version = "\(.*\)".*/\1/' | cut -d '"' -f2)"
   else
     local version=""
   fi
@@ -281,12 +296,12 @@
   echo "${version}-${date}"
 }
 
-if [[ ${PLATFORM} == "darwin" ]]; then
-  function md5_file() {
+if [ "${PLATFORM}" = "darwin" ]; then
+  md5_file() {
     echo $(cat $1 | md5) $1
   }
 else
-  function md5_file() {
+  md5_file() {
     md5sum $1
   }
 fi
@@ -294,15 +309,17 @@
 # Gets the java version from JAVA_HOME
 # Sets JAVAC and JAVAC_VERSION with respectively the path to javac and
 # the version of javac.
-function get_java_version() {
+get_java_version() {
   test -z "$JAVA_HOME" && fail "JDK not found, please set \$JAVA_HOME."
   JAVAC="${JAVA_HOME}/bin/javac"
-  [[ -x "${JAVAC}" ]] \
+  [ -x "${JAVAC}" ] \
     || fail "JAVA_HOME ($JAVA_HOME) is not a path to a working JDK."
 
   JAVAC_VERSION=$("${JAVAC}" -version 2>&1)
-  if [[ "$JAVAC_VERSION" =~ javac\ ((1\.)?([789]|[1-9][0-9])).*$ ]]; then
-    JAVAC_VERSION=1.${BASH_REMATCH[3]}
+  local major=$(printf '%s' "$JAVAC_VERSION" | \
+    sed -nE 's/^javac (1\.)?([789]|[1-9][0-9]).*/\2/p')
+  if [ -n "$major" ]; then
+    JAVAC_VERSION=1.${major}
   else
     fail \
       "Cannot determine JDK version, please set \$JAVA_HOME.\n" \
@@ -311,35 +328,35 @@
 }
 
 # Return the target that a bind point to, using Bazel query.
-function get_bind_target() {
+get_bind_target() {
   $BAZEL --bazelrc=${BAZELRC} ${BAZEL_DIR_STARTUP_OPTIONS} \
     query "deps($1, 1) - $1"
 }
 
 # Create a link for a directory on the filesystem
-function link_dir() {
-  local source=$1
-  local dest=$2
-
-  if [[ "${PLATFORM}" == "windows" ]]; then
-    local -r s="$(cygpath -w "$source")"
-    local -r d="$(cygpath -w "$dest")"
+link_dir() {
+  local source="$1"
+  local dest="$2"
+
+  if [ "${PLATFORM}" = "windows" ]; then
+    local s="$(cygpath -w "$source")"
+    local d="$(cygpath -w "$dest")"
     powershell -command "New-Item -ItemType Junction -Path '$d' -Value '$s'"
   else
     ln -s "${source}" "${dest}"
   fi
 }
 
-function link_file() {
-  local source=$1
-  local dest=$2
+link_file() {
+  local source="$1"
+  local dest="$2"
 
-  if [[ "${PLATFORM}" == "windows" ]]; then
+  if [ "${PLATFORM}" = "windows" ]; then
     # Attempt creating a symlink to the file. This is supported without
     # elevation (Administrator privileges) on Windows 10 version 1709 when
     # Developer Mode is enabled.
-    local -r s="$(cygpath -w "$source")"
-    local -r d="$(cygpath -w "$dest")"
+    local s="$(cygpath -w "$source")"
+    local d="$(cygpath -w "$dest")"
     if ! powershell -command "New-Item -ItemType SymbolicLink -Path '$d' -Value '$s'"; then
       # If the previous call failed to create a symlink, just copy the file.
       cp "$source" "$dest"
@@ -356,20 +373,20 @@
 #   ${BAZEL_TOOLS_REPO}/tools/android -> $PWD/tools/android
 #   ${BAZEL_TOOLS_REPO}/tools/bash -> $PWD/tools/bash
 #   ... and so on for all files and directories directly under "tools".
-function link_children() {
-  local -r source_dir=${1%/}
-  local -r source_subdir=${2%/}
-  local -r dest_dir=${3%/}
+link_children() {
+  local source_dir="${1%/}"
+  local source_subdir="${2%/}"
+  local dest_dir="${3%/}"
 
   for e in $(find "${source_dir}/${source_subdir}" -mindepth 1 -maxdepth 1 -type d); do
     local dest_path="${dest_dir}/${e#$source_dir/}"
-    if [[ ! -d "$dest_path" ]]; then
+    if [ ! -d "$dest_path" ]; then
       link_dir "$e" "$dest_path"
     fi
   done
   for e in $(find "${source_dir}/${source_subdir}" -mindepth 1 -maxdepth 1 -type f); do
     local dest_path="${dest_dir}/${e#$source_dir/}"
-    if [[ ! -f "$dest_path" ]]; then
+    if [ ! -f "$dest_path" ]; then
       link_file "$e" "$dest_path"
     fi
   done
