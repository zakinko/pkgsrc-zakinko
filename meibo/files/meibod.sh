#!@RCD_SCRIPTS_SHELL@
#
# $NetBSD$
#
# PROVIDE: meibod
# REQUIRE: DAEMON pgsql
# KEYWORD: shutdown
#
# /etc/rc.conf での設定:
#
#	meibod=YES
#	meibod_flags="-f @PKG_SYSCONFDIR@/meibo.conf"
#
# 事前に一度 meiboctl setup を実行しておくこと。設定ファイルとマスター鍵、
# データベーススキーマ、最初の管理者アカウントがそこで作られる。

. /etc/rc.subr

name="meibod"
rcvar=$name
command="@PREFIX@/bin/meibod"
command_args="-f @PKG_SYSCONFDIR@/meibo.conf"
pidfile="@VARBASE@/run/${name}.pid"
required_files="@PKG_SYSCONFDIR@/meibo.conf"

# meibo 専用ユーザで動かす。マスター鍵 (secret.key) はこのユーザだけが読める。
meibod_user="meibo"
meibod_group="meibo"

start_precmd="meibod_precmd"
meibod_precmd()
{
	# 設定を検査してから起動する。壊れた設定でサービスが上がらないまま
	# 気づかない、という事態を避ける。
	if ! @PREFIX@/bin/meibod -t -f @PKG_SYSCONFDIR@/meibo.conf; then
		warn "meibo.conf に問題があります。起動を中止しました。"
		return 1
	fi
	if [ ! -d @VARBASE@/db/meibo ]; then
		warn "@VARBASE@/db/meibo がありません。meiboctl setup を先に実行してください。"
		return 1
	fi
	return 0
}

load_rc_config $name
run_rc_command "$1"
