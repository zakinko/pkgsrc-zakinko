$NetBSD$

Fix out-of-bounds writes reachable through ntpq and the Palisade
refclock driver.

	CVE-2023-26551, CVE-2023-26552, CVE-2023-26553, CVE-2023-26554
	  [Sec 3806] libntp/mstolfp.c needs bounds checking
	CVE-2023-26555
	  [Sec 3807] praecis_parse() in the Palisade refclock driver has
	  a hypothetical input buffer overflow

Both were fixed in 4.2.8p16.  This is upstream's own backport of the
two of them onto 4.2.8p15, split per file:

	https://downloads.nwtime.org/ntp/4.2.8/ntp-4.2.8p15-3806-3807.patch

Declares the wider buffer mstolfp() now needs.

--- include/ntp_fp.h	2019-06-03 23:41:14.000000000 -0500
+++ ../ntp-stable-p16-sec/include/ntp_fp.h	2023-04-17 03:17:01.655121000 -0500
@@ -195,9 +195,9 @@
 	do { \
 		int32 add_f = (int32)(f); \
 		if (add_f >= 0) \
-			M_ADD((r_i), (r_f), 0, (uint32)( add_f)); \
+			M_ADD((r_i), (r_f), 0, (u_int32)( add_f)); \
 		else \
-			M_SUB((r_i), (r_f), 0, (uint32)(-add_f)); \
+			M_SUB((r_i), (r_f), 0, (u_int32)(-add_f)); \
 	} while(0)
 
 #define	M_ISNEG(v_i)			/* v < 0 */ \
