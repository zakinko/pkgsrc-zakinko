# n-dhcp4 を BSD で測るもの

NetworkManager が同梱する n-dhcp4 の移植を測る。当て物は
`NetworkManager/patches/patch-src_n-dhcp4_*` に在り、**ここに在るのは
当て物が置く実物を取り込んで測る側**である。写しは置かない。本物を直した日に
緑のまま意味を失うため。

## CI が回すもの (root も interface も要らない)

`t-filter.c`
: 当て物が置く `n_dhcp4_bsd_client_filter` と、上流の Linux 版の filter を、
  libpcap の `bpf_filter()` — kernel と同じ interpreter — に通して判定を
  比べる。offset を Ethernet header の分だけ移す変更は、行き過ぎれば何も
  来ず、足りなければ何でも来るという形で静かに壊れる。八つの場合で一致を
  見る。

`t-packet.c`
: `packet-bsd.c` の送受信。pipe へ書かせた frame を分解し直して各 field を
  確かめ、IP checksum を独立に再計算して 0 になることまで見る。受信は
  kernel が返すのと同じ形の buffer を組んで読ませ、切り詰めた一本を飛ばす
  こと、payload が一 byte まで合うこと、payload を壊すと UDP checksum で
  落ちることを見る。最後のは否定的な test で、**検査が入っているだけで素通り
  していないことは、壊して落ちるのを見ないと分からない。**

## 手で回すもの (root と tap が要る)

CI の VM でも動くはずだが、tap の作り方が BSD ごとに違うので自動では回して
いない。NetBSD 11.0 では下の手順で通っている。

	ifconfig tap0 create
	ifconfig tap0 up
	ifconfig tap0 inet 10.99.0.50 netmask 255.255.255.0 alias
	ifconfig tap0 inet 10.99.0.1  netmask 255.255.255.255 alias
	./t-lease tap0            # lease を取り、UDP で更新し、RELEASE まで
	./t-lease tap0 decline    # accept の代わりに decline
	./t-wire tap0             # DHCPDISCOVER が線に出るかだけ
	ifconfig tap0 destroy

**tap を使うのは、借りている箱の segment に DHCPDISCOVER を撒かないため。**
応える server が居れば lease を一つ取ってしまう。tap には誰も繋がっていない
ので frame は外へ出ない。`t-lease` は偽の server を同じ tap の上に置き、更新の
unicast は両端の address を tap に載せて箱の中で折り返す。

測り終えたら `destroy`。address ごと消える。`SIOCGIFFLAGS tap0: Device not
configured` が返るのを見て確かめる。**消したつもりは確かめていない。**
