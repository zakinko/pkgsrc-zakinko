$NetBSD$

Keep the bootstrap working on JDK 23 and newer.

javac stopped running annotation processors it finds on the classpath
unless it is asked to, so the AutoValue and AutoService processors never
run and none of the generated classes exist:

	DependencyError.java:135: error: cannot find symbol
	  symbol: variable AutoOneOf_DependencyError
	... 178 errors

-proc:full asks for the old behaviour back.  It is only passed from 23
onwards, because the option does not exist before 21 and the default is
already what we want up to 22.

Upstream solved this after 9.2.0 by naming the processors explicitly
(-processor) and splitting the compilation in two, which is a larger
change than belongs in a patch here.

--- scripts/bootstrap/compile.sh.orig
+++ scripts/bootstrap/compile.sh
@@ -131,6 +131,14 @@ function java_compilation() {

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
@@ -139,6 +147,7 @@ function java_compilation() {
   run "${JAVAC}" -classpath "${classpath}" -sourcepath "${sourcepath}" \
       -d "${output}/classes" -source "$JAVA_VERSION" -target "$JAVA_VERSION" \
       -encoding UTF-8 --add-exports=java.base/jdk.internal.misc=ALL-UNNAMED \
+      ${proc_full} \
       --add-exports=java.base/jdk.internal.vm=ALL-UNNAMED \
       ${BAZEL_JAVAC_OPTS} "@${paramfile}"

