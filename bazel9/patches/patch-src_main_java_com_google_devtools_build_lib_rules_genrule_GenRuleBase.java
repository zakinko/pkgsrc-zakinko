$NetBSD$

Source the genrule setup script with . rather than source.

bazel puts "source <genrule-setup.sh>;" in front of every genrule cmd.
source is a bash builtin; POSIX sh spells it "." and bash accepts that
too, so the change costs nothing where bash is the shell.

It matters here because patch-src_main_java_..._BazelRuleClassProvider.java
makes /bin/sh the shell genrules run under.  With source, every genrule
prints

	sh: source: not found

and carries on, because the failure of the first command in the list does
not stop the rest.  What is skipped is not decoration -- genrule-setup.sh
is the file that turns on the error handling:

	set -e
	set -u
	set -o pipefail

So a genrule whose first command fails would keep going and the action
could report success over a half-written output.  The genrule that was
used to test /bin/sh passed only because it was a single echo.

NetBSD's /bin/sh takes all three options, and reads the file with . --
measured before making this change.

--- src/main/java/com/google/devtools/build/lib/rules/genrule/GenRuleBase.java.orig
+++ src/main/java/com/google/devtools/build/lib/rules/genrule/GenRuleBase.java
@@ -142,7 +142,7 @@
       // Add the genrule environment setup script before the actual shell command.
       command =
           String.format(
-              "source %s; %s",
+              ". %s; %s",
               ruleContext.getPrerequisiteArtifact("$genrule_setup").getExecPath(), command);
     }
 
