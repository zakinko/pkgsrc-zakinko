$NetBSD$

tv_usec is a suseconds_t, an int on NetBSD; cast it for %ld.

--- test/testcpg.c.orig
+++ test/testcpg.c
@@ -123,7 +123,7 @@
 	t = time(0);
 	gettimeofday( &tnow, 0 );
 	s += strftime(s, sizeof(buf)-(s-buf) , " %Y-%m-%d %T", localtime(&t));
-	s += snprintf(s, sizeof(buf)-(s-buf), ".%03ld", tnow.tv_usec/1000);
+	s += snprintf(s, sizeof(buf)-(s-buf), ".%03ld", (long)tnow.tv_usec/1000);
 	assert(s-buf < (int)sizeof(buf));
 	printf("%s\n", buf);
 }
