$NetBSD$

Map OS.NETBSD to @platforms//os:netbsd.

The map is constraint value to OS, not the other way round, so the label
is written before the enum it belongs to.  Without an entry, a target
built on NetBSD gets no os constraint and every platform-specific
toolchain fails to resolve.

--- src/main/java/com/google/devtools/build/lib/analysis/constraints/ConstraintConstants.java.orig	1980-01-01 00:00:00.000000000 +0000
+++ src/main/java/com/google/devtools/build/lib/analysis/constraints/ConstraintConstants.java
@@ -60,6 +60,14 @@ public final class ConstraintConstants {
           OS.FREEBSD,
           ConstraintValueInfo.create(
               OS_CONSTRAINT_SETTING,
+              Label.parseCanonicalUnchecked("@platforms//os:netbsd")),
+          OS.NETBSD,
+          ConstraintValueInfo.create(
+              OS_CONSTRAINT_SETTING,
+              Label.parseCanonicalUnchecked("@platforms//os:dragonfly")),
+          OS.DRAGONFLY,
+          ConstraintValueInfo.create(
+              OS_CONSTRAINT_SETTING,
               Label.parseCanonicalUnchecked("@platforms//os:openbsd")),
           OS.OPENBSD,
           ConstraintValueInfo.create(
