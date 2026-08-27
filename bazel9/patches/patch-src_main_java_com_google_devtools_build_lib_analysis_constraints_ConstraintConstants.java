$NetBSD$

Map OS.NETBSD to @platforms//os:netbsd.

The map is constraint value to OS, not the other way round, so the label
is written before the enum it belongs to.  Without an entry, a target
built on NetBSD gets no os constraint and every platform-specific
toolchain fails to resolve.

--- src/main/java/com/google/devtools/build/lib/analysis/constraints/ConstraintConstants.java.orig
+++ src/main/java/com/google/devtools/build/lib/analysis/constraints/ConstraintConstants.java
@@ -60,6 +60,10 @@
           OS.FREEBSD,
           ConstraintValueInfo.create(
               OS_CONSTRAINT_SETTING,
+              Label.parseCanonicalUnchecked("@platforms//os:netbsd")),
+          OS.NETBSD,
+          ConstraintValueInfo.create(
+              OS_CONSTRAINT_SETTING,
               Label.parseCanonicalUnchecked("@platforms//os:openbsd")),
           OS.OPENBSD,
           ConstraintValueInfo.create(
