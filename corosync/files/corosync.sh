#!@RCD_SCRIPTS_SHELL@
#
# $NetBSD$
#
# PROVIDE: corosync
# REQUIRE: NETWORKING
# KEYWORD: shutdown

$_rc_subr_loaded . /etc/rc.subr

name="corosync"
rcvar=$name
command="@PREFIX@/sbin/${name}"
required_files="@PKG_SYSCONFDIR@/${name}.conf"
pidfile="@VARBASE@/run/${name}.pid"
start_precmd="corosync_precmd"

# libknet takes 8 MB socket buffers and, running as root, refuses a link
# when it cannot have them.  NetBSD's default kern.sbmax is too small.
corosync_sbmax=16777216

corosync_precmd()
{
	if [ "$(/sbin/sysctl -n kern.sbmax)" -lt ${corosync_sbmax} ]; then
		err 3 "kern.sbmax must be at least ${corosync_sbmax}"
	fi
}

load_rc_config $name
run_rc_command "$1"
