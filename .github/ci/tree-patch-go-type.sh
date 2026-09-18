#!/bin/sh
# GO_TYPE=bin の当て物を木に当てる。build-on-bsd.sh が TREE_PATCH から呼ぶ。
#
#   sh tree-patch-go-type.sh <tree>
#
# 当て物は tree-patches/go-type.diff で、中身は
#   lang/go/version.mk      GO_TYPE (src|bin) と GO_DIR。bin なら go-bin に依存
#   lang/go/go-package.mk   GOTOOLDIR を GO_DIR から
#   lang/go/go-module.mk    _USER_VARS / _SYS_VARS
#   lang/go-bin/Makefile    1.24.11 -> 1.27.1、NetBSD の i386 と x86_64 を足す
#   lang/go-bin/distinfo    14 platform 分
#   mk/defaults/mk.conf     GO_TYPE の説明
# 送る diff と同じ物。ここで当たらなくなったら、上流の木が動いたということ。
set -e
TREE=$1
D=$(cd "$(dirname "$0")" && pwd)
cd "$TREE"
patch -p1 -f -F0 -i "$D/tree-patches/go-type.diff" </dev/null
grep -q '^GO_TYPE?=' lang/go/version.mk
grep -q 'NetBSD-\*-x86_64' lang/go-bin/Makefile
echo "当てた: $(grep '^PKGNAME' lang/go-bin/Makefile)"
