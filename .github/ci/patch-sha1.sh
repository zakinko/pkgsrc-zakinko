# pkgsrc が distinfo に書く当て物の SHA1 を出す。source して使う。
#
#	. "$WS/.github/ci/patch-sha1.sh"
#	h=$(patch_sha1 /path/to/patch-foo) || exit 1
#
# 数え方は mk/checksum/distinfo.awk の patchsum() と同じで、$NetBSD$ の行を
# 落とした中身の SHA1 である。実物の security/polkit の当て物二本
# (patch-src_polkit_polkitunixprocess.c と
#  patch-src_polkitagent_polkitagenthelper-pam.c) で、pkgsrc の distinfo の
# 値をこの式が再現することを確かめてある。
#
# digest(1) に頼らない。pkgtools/digest は bootstrap の後にしか無く、
# NetBSD の image には入っていないこともある。実際、NetworkManager の
# 段 0.7 はそれで引き返していた:
#
#	★ SHA1 が 40 桁で出ない (digest: PATH に無い)
#
# 名前が合っても別物のことがある。macOS の digest は NSS の物で、
# "digest: NSS_Init failed in directory /tmp" と言って何も出さない。だから
# 出た値が 16 進 40 桁かまで見て、違えば次の道具へ移る。
#
# 呼ぶ側が set -e でも動くよう、道具ごとの失敗は || true で受ける。受けない
# と、最初に試した道具が無い・違う物だっただけで呼ぶ側ごと止まる (macOS の
# NSS の digest、cksum -a を持たない cksum)。出た値は下で 16 進 40 桁かを
# 見るので、失敗を飲み込んでも誤った値は通らない。
#
# digest -p は使わない。あれは別の値を出す。NetBSD 11.0 で同じ file に
# 対して digest sha1 が 5534509b…、digest -p sha1 が c82b12f0… だった。
# distinfo に載っているのは前者である。
patch_sha1() {
	_ps_f=${1:?patch_sha1: file}
	[ -f "$_ps_f" ] || { echo "patch_sha1: $_ps_f が無い" >&2; return 1; }
	for _ps_t in digest cksum sha1 sha1sum openssl; do
		command -v "$_ps_t" > /dev/null 2>&1 || continue
		case $_ps_t in
		digest)  _ps_h=$(sed -e '/\$NetBSD.*\$/d' "$_ps_f" | digest sha1 2>/dev/null || true) ;;
		cksum)   _ps_h=$(sed -e '/\$NetBSD.*\$/d' "$_ps_f" | cksum -a sha1 2>/dev/null || true) ;;
		sha1)    _ps_h=$(sed -e '/\$NetBSD.*\$/d' "$_ps_f" | sha1 2>/dev/null || true) ;;
		sha1sum) _ps_h=$(sed -e '/\$NetBSD.*\$/d' "$_ps_f" | sha1sum 2>/dev/null || true) ;;
		openssl) _ps_h=$(sed -e '/\$NetBSD.*\$/d' "$_ps_f" | openssl dgst -sha1 2>/dev/null || true) ;;
		esac
		_ps_h=$(echo "$_ps_h" | awk '{print $NF}')
		case $_ps_h in
		????????????????????????????????????????)
			# 16 進 40 桁であることまで見る。cksum -a sha1 を持たない
			# 実装は usage を吐いて別の物を最後の語に置くことがある。
			case $_ps_h in
			*[!0-9a-f]*) continue ;;
			esac
			echo "$_ps_h"
			return 0 ;;
		esac
	done
	echo "patch_sha1: SHA1 を出せる道具が無い (digest/cksum/sha1/sha1sum/openssl)" >&2
	return 1
}
