#!/bin/sh
# lang/rust-bin が devel/libatomic を引く条件に riscv64 が入っていない。
# 送る diff そのものを当てる。
set -e
TREE=${1:?usage: $0 <pkgsrc tree>}
D=$(cd "$(dirname "$0")" && pwd)
M=$TREE/lang/rust-bin/Makefile
if grep -q 'MNetBSD-\*-riscv64}' "$M" && grep -q 'libatomic' "$M"; then
	case $(grep -A6 'libatomic' "$M" | grep -c 'riscv64') in
	0) ;;
	*) echo "  rust-bin: 上流に追いついている。何もしない"; exit 0 ;;
	esac
fi
patch -f -p0 -d "$TREE" < "$D/tree-rust-bin-riscv64-atomic.diff" > /dev/null
grep -q 'riscv64 needs it although it is 64-bit' "$M" || {
	echo "!! rust-bin: riscv64 の libatomic が入っていない" >&2; exit 1; }
echo "  rust-bin: riscv64 でも devel/libatomic を引くようにした"
