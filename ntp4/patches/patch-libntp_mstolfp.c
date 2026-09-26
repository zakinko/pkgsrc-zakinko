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

mstolfp() is rewritten to solve numerically rather than by string
manipulation, which is where the four out-of-bounds writes were.

--- libntp/mstolfp.c	2019-06-03 23:41:14.000000000 -0500
+++ ../ntp-stable-p16-sec/libntp/mstolfp.c	2023-04-17 03:07:38.598581000 -0500
@@ -14,86 +14,58 @@
 	l_fp *lfp
 	)
 {
-	register const char *cp;
-	register char *bp;
-	register const char *cpdec;
-	char buf[100];
+	int        ch, neg = 0; 
+	u_int32    q, r;
 
 	/*
 	 * We understand numbers of the form:
 	 *
 	 * [spaces][-|+][digits][.][digits][spaces|\n|\0]
 	 *
-	 * This is one enormous hack.  Since I didn't feel like
-	 * rewriting the decoding routine for milliseconds, what
-	 * is essentially done here is to make a copy of the string
-	 * with the decimal moved over three places so the seconds
-	 * decoding routine can be used.
+	 * This is kinda hack.  We use 'atolfp' to do the basic parsing
+	 * (after some initial checks) and then divide the result by
+	 * 1000.  The original implementation avoided that by
+	 * hacking up the input string to move the decimal point, but
+	 * that needed string manipulations prone to buffer overruns.
+	 * To avoid that trouble we do the conversion first and adjust
+	 * the result.
 	 */
-	bp = buf;
-	cp = str;
-	while (isspace((unsigned char)*cp))
-	    cp++;
 	
-	if (*cp == '-' || *cp == '+') {
-		*bp++ = *cp++;
-	}
-
-	if (*cp != '.' && !isdigit((unsigned char)*cp))
-	    return 0;
-
-
-	/*
-	 * Search forward for the decimal point or the end of the string.
-	 */
-	cpdec = cp;
-	while (isdigit((unsigned char)*cpdec))
-	    cpdec++;
-
-	/*
-	 * Found something.  If we have more than three digits copy the
-	 * excess over, else insert a leading 0.
-	 */
-	if ((cpdec - cp) > 3) {
-		do {
-			*bp++ = (char)*cp++;
-		} while ((cpdec - cp) > 3);
-	} else {
-		*bp++ = '0';
-	}
-
-	/*
-	 * Stick the decimal in.  If we've got less than three digits in
-	 * front of the millisecond decimal we insert the appropriate number
-	 * of zeros.
-	 */
-	*bp++ = '.';
-	if ((cpdec - cp) < 3) {
-		size_t i = 3 - (cpdec - cp);
-		do {
-			*bp++ = '0';
-		} while (--i > 0);
-	}
-
-	/*
-	 * Copy the remainder up to the millisecond decimal.  If cpdec
-	 * is pointing at a decimal point, copy in the trailing number too.
-	 */
-	while (cp < cpdec)
-	    *bp++ = (char)*cp++;
+	while (isspace(ch = *(const unsigned char*)str))
+		++str;
 	
-	if (*cp == '.') {
-		cp++;
-		while (isdigit((unsigned char)*cp))
-		    *bp++ = (char)*cp++;
+	switch (ch) {
+	    case '-': neg = TRUE;
+	    case '+': ++str;
+	    default : break;
 	}
-	*bp = '\0';
-
-	/*
-	 * Check to make sure the string is properly terminated.  If
-	 * so, give the buffer to the decoding routine.
-	 */
-	if (*cp != '\0' && !isspace((unsigned char)*cp))
-	    return 0;
-	return atolfp(buf, lfp);
+	
+	if (!isdigit(ch = *(const unsigned char*)str) && (ch != '.'))
+		return 0;
+	if (!atolfp(str, lfp))
+		return 0;
+
+	/* now do a chained/overlapping division by 1000 to get from
+	 * seconds to msec. 1000 is small enough to go with temporary
+	 * 32bit accus for Q and R.
+	 */
+	q = lfp->l_ui / 1000u;
+	r = lfp->l_ui - (q * 1000u);
+	lfp->l_ui = q;
+
+	r = (r << 16) | (lfp->l_uf >> 16);
+	q = r / 1000u;
+	r = ((r - q * 1000) << 16) | (lfp->l_uf & 0x0FFFFu);
+	lfp->l_uf = q << 16;
+	q = r / 1000;
+	lfp->l_uf |= q;
+	r -= q * 1000u;
+
+	/* fix sign */
+	if (neg)
+		L_NEG(lfp);
+	/* round */
+	if (r >= 500)
+		L_ADDF(lfp, (neg ? -1 : 1));
+	return 1;
 }
