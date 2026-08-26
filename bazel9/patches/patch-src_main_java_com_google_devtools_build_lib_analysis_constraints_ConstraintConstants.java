$NetBSD$

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
