$NetBSD$

* Changes from NetBSD base.
* This is a pre-generated file (from sntp/sntp-opts.def via AutoGen);
  patch it directly rather than the .def source, for the same reason
  as patch-ntpd_ntpd.1ntpdman.  The default keyfile path is not a
  simple #define here but a byte offset into a concatenated string
  table (sntp_opt_strs[]), referenced both by parenthesized
  (sntp_opt_strs+N) macros and by two bare sntp_opt_strs+N array
  initializers (apzHomeList).  Replacing "/etc/ntp.keys" with
  "/usr/pkg/etc/ntp.keys" (PR pkg/47149) lengthens the table by 8
  bytes, so every offset at or after the old string's end (1615) is
  shifted by +8, and the declared array size grows from 2566 to 2574.
  This hunk was generated mechanically (not hand-edited) to keep the
  79 affected offsets consistent; every other string's content and
  offset below 1615 is unchanged.

--- sntp/sntp-opts.c.orig	2020-06-23 16:03:47.000000000 +0000
+++ sntp/sntp-opts.c
@@ -69,7 +69,7 @@ extern FILE * option_usage_fp;
 /**
  *  static const strings for sntp options
  */
-static char const sntp_opt_strs[2566] =
+static char const sntp_opt_strs[2574] =
 /*     0 */ "sntp 4.2.8p15\n"
             "Copyright (C) 1992-2020 The University of Delaware and Network Time Foundation, all rights reserved.\n"
             "This is free software. It is licensed for use, modification and\n"
@@ -118,53 +118,53 @@ static char const sntp_opt_strs[2566] =
 /*  1537 */ "Look in this file for the key specified with -a\0"
 /*  1585 */ "KEYFILE\0"
 /*  1593 */ "keyfile\0"
-/*  1601 */ "/etc/ntp.keys\0"
-/*  1615 */ "Log to specified logfile\0"
-/*  1640 */ "LOGFILE\0"
-/*  1648 */ "logfile\0"
-/*  1656 */ "Adjustments less than steplimit msec will be slewed\0"
-/*  1708 */ "STEPLIMIT\0"
-/*  1718 */ "steplimit\0"
-/*  1728 */ "Send int as our NTP protocol version\0"
-/*  1765 */ "NTPVERSION\0"
-/*  1776 */ "ntpversion\0"
-/*  1787 */ "Use the NTP Reserved Port (port 123)\0"
-/*  1824 */ "USERESERVEDPORT\0"
-/*  1840 */ "usereservedport\0"
-/*  1856 */ "OK to 'step' the time with settimeofday(2)\0"
-/*  1899 */ "STEP\0"
-/*  1904 */ "step\0"
-/*  1909 */ "OK to 'slew' the time with adjtime(2)\0"
-/*  1947 */ "SLEW\0"
-/*  1952 */ "slew\0"
-/*  1957 */ "The number of seconds to wait for responses\0"
-/*  2001 */ "TIMEOUT\0"
-/*  2009 */ "timeout\0"
-/*  2017 */ "Wait for pending replies (if not setting the time)\0"
-/*  2068 */ "WAIT\0"
-/*  2073 */ "no-wait\0"
-/*  2081 */ "no\0"
-/*  2084 */ "display extended usage information and exit\0"
-/*  2128 */ "help\0"
-/*  2133 */ "extended usage information passed thru pager\0"
-/*  2178 */ "more-help\0"
-/*  2188 */ "output version information and exit\0"
-/*  2224 */ "version\0"
-/*  2232 */ "save the option state to a config file\0"
-/*  2271 */ "save-opts\0"
-/*  2281 */ "load options from a config file\0"
-/*  2313 */ "LOAD_OPTS\0"
-/*  2323 */ "no-load-opts\0"
-/*  2336 */ "SNTP\0"
-/*  2341 */ "sntp - standard Simple Network Time Protocol client program - Ver. 4.2.8p15\n"
+/*  1601 */ "/usr/pkg/etc/ntp.keys\0"
+/*  1623 */ "Log to specified logfile\0"
+/*  1648 */ "LOGFILE\0"
+/*  1656 */ "logfile\0"
+/*  1664 */ "Adjustments less than steplimit msec will be slewed\0"
+/*  1716 */ "STEPLIMIT\0"
+/*  1726 */ "steplimit\0"
+/*  1736 */ "Send int as our NTP protocol version\0"
+/*  1773 */ "NTPVERSION\0"
+/*  1784 */ "ntpversion\0"
+/*  1795 */ "Use the NTP Reserved Port (port 123)\0"
+/*  1832 */ "USERESERVEDPORT\0"
+/*  1848 */ "usereservedport\0"
+/*  1864 */ "OK to 'step' the time with settimeofday(2)\0"
+/*  1907 */ "STEP\0"
+/*  1912 */ "step\0"
+/*  1917 */ "OK to 'slew' the time with adjtime(2)\0"
+/*  1955 */ "SLEW\0"
+/*  1960 */ "slew\0"
+/*  1965 */ "The number of seconds to wait for responses\0"
+/*  2009 */ "TIMEOUT\0"
+/*  2017 */ "timeout\0"
+/*  2025 */ "Wait for pending replies (if not setting the time)\0"
+/*  2076 */ "WAIT\0"
+/*  2081 */ "no-wait\0"
+/*  2089 */ "no\0"
+/*  2092 */ "display extended usage information and exit\0"
+/*  2136 */ "help\0"
+/*  2141 */ "extended usage information passed thru pager\0"
+/*  2186 */ "more-help\0"
+/*  2196 */ "output version information and exit\0"
+/*  2232 */ "version\0"
+/*  2240 */ "save the option state to a config file\0"
+/*  2279 */ "save-opts\0"
+/*  2289 */ "load options from a config file\0"
+/*  2321 */ "LOAD_OPTS\0"
+/*  2331 */ "no-load-opts\0"
+/*  2344 */ "SNTP\0"
+/*  2349 */ "sntp - standard Simple Network Time Protocol client program - Ver. 4.2.8p15\n"
             "Usage:  %s [ -<flag> [<val>] | --<name>[{=| }<val>] ]... \\\n"
             "\t\t[ hostname-or-IP ...]\n\0"
-/*  2501 */ "$HOME\0"
-/*  2507 */ ".\0"
-/*  2509 */ ".ntprc\0"
-/*  2516 */ "http://bugs.ntp.org, bugs@ntp.org\0"
-/*  2550 */ "\n\0"
-/*  2552 */ "sntp 4.2.8p15";
+/*  2509 */ "$HOME\0"
+/*  2515 */ ".\0"
+/*  2517 */ ".ntprc\0"
+/*  2524 */ "http://bugs.ntp.org, bugs@ntp.org\0"
+/*  2558 */ "\n\0"
+/*  2560 */ "sntp 4.2.8p15";

 /**
  *  ipv4 option description with
@@ -311,11 +311,11 @@ static int const aIpv6CantList[] = {
  *  logfile option description:
  */
 /** Descriptive text for the logfile option */
-#define LOGFILE_DESC      (sntp_opt_strs+1615)
+#define LOGFILE_DESC      (sntp_opt_strs+1623)
 /** Upper-cased name for the logfile option */
-#define LOGFILE_NAME      (sntp_opt_strs+1640)
+#define LOGFILE_NAME      (sntp_opt_strs+1648)
 /** Name string for the logfile option */
-#define LOGFILE_name      (sntp_opt_strs+1648)
+#define LOGFILE_name      (sntp_opt_strs+1656)
 /** Compiled in flag settings for the logfile option */
 #define LOGFILE_FLAGS     (OPTST_DISABLED \
         | OPTST_SET_ARGTYPE(OPARG_TYPE_FILE))
@@ -324,11 +324,11 @@ static int const aIpv6CantList[] = {
  *  steplimit option description:
  */
 /** Descriptive text for the steplimit option */
-#define STEPLIMIT_DESC      (sntp_opt_strs+1656)
+#define STEPLIMIT_DESC      (sntp_opt_strs+1664)
 /** Upper-cased name for the steplimit option */
-#define STEPLIMIT_NAME      (sntp_opt_strs+1708)
+#define STEPLIMIT_NAME      (sntp_opt_strs+1716)
 /** Name string for the steplimit option */
-#define STEPLIMIT_name      (sntp_opt_strs+1718)
+#define STEPLIMIT_name      (sntp_opt_strs+1726)
 /** Compiled in flag settings for the steplimit option */
 #define STEPLIMIT_FLAGS     (OPTST_DISABLED \
         | OPTST_SET_ARGTYPE(OPARG_TYPE_NUMERIC))
@@ -337,11 +337,11 @@ static int const aIpv6CantList[] = {
  *  ntpversion option description:
  */
 /** Descriptive text for the ntpversion option */
-#define NTPVERSION_DESC      (sntp_opt_strs+1728)
-/** Upper-cased name for the ntpversion option */
-#define NTPVERSION_NAME      (sntp_opt_strs+1765)
+#define NTPVERSION_DESC      (sntp_opt_strs+1736)
+/** Upper-cased name for the ntpversion option */
+#define NTPVERSION_NAME      (sntp_opt_strs+1773)
 /** Name string for the ntpversion option */
-#define NTPVERSION_name      (sntp_opt_strs+1776)
+#define NTPVERSION_name      (sntp_opt_strs+1784)
 /** The compiled in default value for the ntpversion option argument */
 #define NTPVERSION_DFT_ARG   ((char const*)4)
 /** Compiled in flag settings for the ntpversion option */
@@ -352,11 +352,11 @@ static int const aIpv6CantList[] = {
  *  usereservedport option description:
  */
 /** Descriptive text for the usereservedport option */
-#define USERESERVEDPORT_DESC      (sntp_opt_strs+1787)
+#define USERESERVEDPORT_DESC      (sntp_opt_strs+1795)
 /** Upper-cased name for the usereservedport option */
-#define USERESERVEDPORT_NAME      (sntp_opt_strs+1824)
+#define USERESERVEDPORT_NAME      (sntp_opt_strs+1832)
 /** Name string for the usereservedport option */
-#define USERESERVEDPORT_name      (sntp_opt_strs+1840)
+#define USERESERVEDPORT_name      (sntp_opt_strs+1848)
 /** Compiled in flag settings for the usereservedport option */
 #define USERESERVEDPORT_FLAGS     (OPTST_DISABLED)

@@ -364,11 +364,11 @@ static int const aIpv6CantList[] = {
  *  step option description:
  */
 /** Descriptive text for the step option */
-#define STEP_DESC      (sntp_opt_strs+1856)
+#define STEP_DESC      (sntp_opt_strs+1864)
 /** Upper-cased name for the step option */
-#define STEP_NAME      (sntp_opt_strs+1899)
+#define STEP_NAME      (sntp_opt_strs+1907)
 /** Name string for the step option */
-#define STEP_name      (sntp_opt_strs+1904)
+#define STEP_name      (sntp_opt_strs+1912)
 /** Compiled in flag settings for the step option */
 #define STEP_FLAGS     (OPTST_DISABLED)

@@ -376,11 +376,11 @@ static int const aIpv6CantList[] = {
  *  slew option description:
  */
 /** Descriptive text for the slew option */
-#define SLEW_DESC      (sntp_opt_strs+1909)
+#define SLEW_DESC      (sntp_opt_strs+1917)
 /** Upper-cased name for the slew option */
-#define SLEW_NAME      (sntp_opt_strs+1947)
+#define SLEW_NAME      (sntp_opt_strs+1955)
 /** Name string for the slew option */
-#define SLEW_name      (sntp_opt_strs+1952)
+#define SLEW_name      (sntp_opt_strs+1960)
 /** Compiled in flag settings for the slew option */
 #define SLEW_FLAGS     (OPTST_DISABLED)

@@ -388,11 +388,11 @@ static int const aIpv6CantList[] = {
  *  timeout option description:
  */
 /** Descriptive text for the timeout option */
-#define TIMEOUT_DESC      (sntp_opt_strs+1957)
+#define TIMEOUT_DESC      (sntp_opt_strs+1965)
 /** Upper-cased name for the timeout option */
-#define TIMEOUT_NAME      (sntp_opt_strs+2001)
+#define TIMEOUT_NAME      (sntp_opt_strs+2009)
 /** Name string for the timeout option */
-#define TIMEOUT_name      (sntp_opt_strs+2009)
+#define TIMEOUT_name      (sntp_opt_strs+2017)
 /** The compiled in default value for the timeout option argument */
 #define TIMEOUT_DFT_ARG   ((char const*)5)
 /** Compiled in flag settings for the timeout option */
@@ -403,13 +403,13 @@ static int const aIpv6CantList[] = {
  *  wait option description:
  */
 /** Descriptive text for the wait option */
-#define WAIT_DESC      (sntp_opt_strs+2017)
+#define WAIT_DESC      (sntp_opt_strs+2025)
 /** Upper-cased name for the wait option */
-#define WAIT_NAME      (sntp_opt_strs+2068)
+#define WAIT_NAME      (sntp_opt_strs+2076)
 /** disablement name for the wait option */
-#define NOT_WAIT_name  (sntp_opt_strs+2073)
+#define NOT_WAIT_name  (sntp_opt_strs+2081)
 /** disablement prefix for the wait option */
-#define NOT_WAIT_PFX   (sntp_opt_strs+2081)
+#define NOT_WAIT_PFX   (sntp_opt_strs+2089)
 /** Name string for the wait option */
 #define WAIT_name      (NOT_WAIT_name + 3)
 /** Compiled in flag settings for the wait option */
@@ -418,11 +418,11 @@ static int const aIpv6CantList[] = {
 /*
  *  Help/More_Help/Version option descriptions:
  */
-#define HELP_DESC       (sntp_opt_strs+2084)
-#define HELP_name       (sntp_opt_strs+2128)
+#define HELP_DESC       (sntp_opt_strs+2092)
+#define HELP_name       (sntp_opt_strs+2136)
 #ifdef HAVE_WORKING_FORK
-#define MORE_HELP_DESC  (sntp_opt_strs+2133)
-#define MORE_HELP_name  (sntp_opt_strs+2178)
+#define MORE_HELP_DESC  (sntp_opt_strs+2141)
+#define MORE_HELP_name  (sntp_opt_strs+2186)
 #define MORE_HELP_FLAGS (OPTST_IMM | OPTST_NO_INIT)
 #else
 #define MORE_HELP_DESC  HELP_DESC
@@ -435,14 +435,14 @@ static int const aIpv6CantList[] = {
 #  define VER_FLAGS     (OPTST_SET_ARGTYPE(OPARG_TYPE_STRING) | \
                          OPTST_ARG_OPTIONAL | OPTST_IMM | OPTST_NO_INIT)
 #endif
-#define VER_DESC        (sntp_opt_strs+2188)
-#define VER_name        (sntp_opt_strs+2224)
-#define SAVE_OPTS_DESC  (sntp_opt_strs+2232)
-#define SAVE_OPTS_name  (sntp_opt_strs+2271)
-#define LOAD_OPTS_DESC     (sntp_opt_strs+2281)
-#define LOAD_OPTS_NAME     (sntp_opt_strs+2313)
-#define NO_LOAD_OPTS_name  (sntp_opt_strs+2323)
-#define LOAD_OPTS_pfx      (sntp_opt_strs+2081)
+#define VER_DESC        (sntp_opt_strs+2196)
+#define VER_name        (sntp_opt_strs+2232)
+#define SAVE_OPTS_DESC  (sntp_opt_strs+2240)
+#define SAVE_OPTS_name  (sntp_opt_strs+2279)
+#define LOAD_OPTS_DESC     (sntp_opt_strs+2289)
+#define LOAD_OPTS_NAME     (sntp_opt_strs+2321)
+#define NO_LOAD_OPTS_name  (sntp_opt_strs+2331)
+#define LOAD_OPTS_pfx      (sntp_opt_strs+2089)
 #define LOAD_OPTS_name     (NO_LOAD_OPTS_name + 3)
 /**
  *  Declare option callback procedures
@@ -748,24 +748,24 @@ static tOptDesc optDesc[OPTION_CT] = {

 /* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
 /** Reference to the upper cased version of sntp. */
-#define zPROGNAME       (sntp_opt_strs+2336)
+#define zPROGNAME       (sntp_opt_strs+2344)
 /** Reference to the title line for sntp usage. */
-#define zUsageTitle     (sntp_opt_strs+2341)
+#define zUsageTitle     (sntp_opt_strs+2349)
 /** sntp configuration file name. */
-#define zRcName         (sntp_opt_strs+2509)
+#define zRcName         (sntp_opt_strs+2517)
 /** Directories to search for sntp config files. */
 static char const * const apzHomeList[3] = {
-    sntp_opt_strs+2501,
-    sntp_opt_strs+2507,
+    sntp_opt_strs+2509,
+    sntp_opt_strs+2515,
     NULL };
 /** The sntp program bug email address. */
-#define zBugsAddr       (sntp_opt_strs+2516)
+#define zBugsAddr       (sntp_opt_strs+2524)
 /** Clarification/explanation of what sntp does. */
-#define zExplain        (sntp_opt_strs+2550)
+#define zExplain        (sntp_opt_strs+2558)
 /** Extra detail explaining what sntp does. */
 #define zDetail         (NULL)
 /** The full version string for sntp. */
-#define zFullVersion    (sntp_opt_strs+2552)
+#define zFullVersion    (sntp_opt_strs+2560)
 /* extracted from optcode.tlib near line 364 */

 #if defined(ENABLE_NLS)
