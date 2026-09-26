#!/bin/sh
# polkit を建てるときに木へ当てるもの。TREE_PATCH は一本しか取れないので束ねる。
set -e
CI=$(cd "$(dirname "$0")" && pwd)
sh "$CI/tree-patch-docbook.sh" "$1"
sh "$CI/tree-patch-glib.sh" "$1"
