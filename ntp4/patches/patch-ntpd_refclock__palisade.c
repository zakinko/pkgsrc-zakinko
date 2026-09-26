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

praecis_parse() bounds its input buffer.

--- ntpd/refclock_palisade.c	2020-04-11 04:31:33.000000000 -0500
+++ ../ntp-stable-p16-sec/ntpd/refclock_palisade.c	2023-04-15 18:09:29.787588000 -0500
@@ -1225,9 +1225,9 @@
 		return;  /* using synchronous packet input */
 
 	if(up->type == CLK_PRAECIS) {
-		if(write(peer->procptr->io.fd,"SPSTAT\r\n",8) < 0)
+		if (write(peer->procptr->io.fd,"SPSTAT\r\n",8) < 0) {
 			msyslog(LOG_ERR, "Palisade(%d) write: %m:",unit);
-		else {
+		} else {
 			praecis_msg = 1;
 			return;
 		}
@@ -1249,20 +1249,53 @@
 
 	pp = peer->procptr;
 
-	memcpy(buf+p,rbufp->recv_space.X_recv_buffer, rbufp->recv_length);
+	if (p + rbufp->recv_length >= sizeof buf) {
+		struct palisade_unit *up;
+		up = pp->unitptr;
+
+		/*
+		 * We COULD see if there is a \r\n in the incoming
+		 * buffer before it overflows, and then process the
+		 * current line.
+		 *
+		 * Similarly, if we already have a hunk of data that
+		 * we're now flushing, that will cause the line of
+		 * data we're in the process of collecting to be garbage.
+		 *
+		 * Since we now check for this overflow and log when it
+		 * happens, we're now in a better place to easily see
+		 * what's going on and perhaps better choices can be made.
+		 */
+
+		/* Do we need to log the size of the overflow? */
+		msyslog(LOG_ERR, "Palisade(%d) praecis_parse(): input buffer overflow", 
+			up->unit);
+
+		p = 0;
+		praecis_msg = 0;
+
+		refclock_report(peer, CEVNT_BADREPLY);
+
+		return;
+	}
+
+	memcpy(buf+p, rbufp->recv_buffer, rbufp->recv_length);
 	p += rbufp->recv_length;
 
-	if(buf[p-2] == '\r' && buf[p-1] == '\n') {
+	if (   p >= 2
+	    && buf[p-2] == '\r' 
+	    && buf[p-1] == '\n') {
 		buf[p-2] = '\0';
 		record_clock_stats(&peer->srcadr, buf);
 
 		p = 0;
 		praecis_msg = 0;
 
-		if (HW_poll(pp) < 0)
+		if (HW_poll(pp) < 0) {
 			refclock_report(peer, CEVNT_FAULT);
-
+		}
 	}
+	return;
 }
 
 static void
@@ -1407,7 +1440,10 @@
 
 	/* Edge trigger */
 	if (up->type == CLK_ACUTIME)
-		write (pp->io.fd, "", 1);
+		if (write (pp->io.fd, "", 1) != 1)
+			msyslog(LOG_WARNING,
+				"Palisade(%d) HW_poll: failed to send trigger: %m", 
+				up->unit);
 		
 	if (ioctl(pp->io.fd, TIOCMSET, &x) < 0) { 
 #ifdef DEBUG
