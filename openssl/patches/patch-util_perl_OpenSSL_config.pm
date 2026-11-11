$NetBSD$

A strategic chomp makes openssl on NetBSD/i386 configure.
sysctl leaves a newline on hw.model, and the guessed target comes out
as "i686\n-whatever-netbsd".

--- util/perl/OpenSSL/config.pm.orig
+++ util/perl/OpenSSL/config.pm
@@ -130,6 +130,7 @@ my $guess_patterns = [
       sub {
           my $hw = `/usr/sbin/sysctl -n hw.model || /sbin/sysctl -n hw.model`;
           $hw =~  s@.*(.)86-class.*@i${1}86@;
+          chomp $hw;
           return "${hw}-whatever-netbsd";
       }
     ],
