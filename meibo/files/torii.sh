#!@RCD_SCRIPTS_SHELL@
#
# $NetBSD$
#
# PROVIDE: torii
# REQUIRE: DAEMON
# KEYWORD: shutdown
#
# torii は meibo のゲート (identity-aware proxy)。
# 社内 Web アプリの手前に立ち、meibod で認証させてから転送する。
#
# /etc/rc.conf での設定:
#
#	torii=YES
#	torii_flags="-f @PKG_SYSCONFDIR@/torii.conf"
#
# meibod と同じホストに置く必要はない。むしろ公開側に torii、
# 内側に meibod という配置のほうが素直。

. /etc/rc.subr

name="torii"
rcvar=$name
command="@PREFIX@/bin/torii"
command_args="-f @PKG_SYSCONFDIR@/torii.conf"
pidfile="@VARBASE@/run/${name}.pid"
required_files="@PKG_SYSCONFDIR@/torii.conf @PKG_SYSCONFDIR@/routes.json"

torii_user="meibo"
torii_group="meibo"

load_rc_config $name
run_rc_command "$1"
