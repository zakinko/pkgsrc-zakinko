;;; mule-tests.el --- mule 2.3 の中核機能を実際に踏む検査
;;
;; batch で走らせる。判定材料は stderr ではなく、この elisp が書き出す
;; ファイルである。mule 2.3 は batch でエラーが起きると内容に関わらず
;; "INVALID DATATYPE" としか言わないので、メッセージを読む方式は原理的に
;; 当てにならない。検査ごとに KEY=VALUE を一行ずつ書き、shell 側が値で
;; 判定する。符号化そのものは、ここが書いたファイルを shell が od で
;; 見て確かめる。
;;
;; どの検査も condition-case でくるむ。くるまないと最初の失敗で mule が
;; 死に、残りの検査結果が取れない。落ちた検査は ERROR:... という値になる。
;;
;; 最後に DONE=1 を書く。これが無ければ、途中で mule が落ちたということ。

(defvar ci-dir (or (getenv "CI_DIR") "/tmp/mule-ci"))
(defvar ci-results nil)

(defun ci-put (key val)
  (setq ci-results (cons (format "%s=%s" key val) ci-results)))

;; 検査本体を関数で受け、値をそのまま記録する。error は握り潰さずに
;; 値として残す。潰すと「検査が走らなかった」と「検査が通った」を
;; shell 側で区別できなくなる。
(defun ci-try (key fn)
  (ci-put key (condition-case e (funcall fn) (error (format "ERROR:%s" e)))))

(defun ci-file (name) (expand-file-name name ci-dir))

;; 出力の符号化は呼び出しごとに縛る。縛らないと buffer 由来の値が効いて、
;; 何の符号化を試したのか分からなくなる。
(defun ci-write (beg end name coding)
  (let ((file-coding-system coding))
    (write-region beg end (ci-file name) nil 'quiet)))

(defun ci-read-into (buf name coding)
  (set-buffer (get-buffer-create buf))
  (erase-buffer)
  (let ((file-coding-system-for-read coding))
    (insert-file-contents (ci-file name)))
  (buffer-string))

;; にほんごのテスト  EUC: a4cb a4db a4f3 a4b4 a4ce a5c6 a5b9 a5c8
(defvar ci-src (ci-file "src.euc"))

;; Mule 2.3 の文字列と buffer 位置は内部表現のバイト単位で、JIS の 1 文字は
;; 3 バイト占める。したがって substring に文字番号を渡すと文字の途中で切れる。
;; 部分文字列は必ず文字移動で取る。
(defun ci-sub (from to)
  (save-excursion
    (set-buffer "src")
    (goto-char (point-min)) (forward-char from)
    (let ((b (point))) (forward-char (- to from)) (buffer-substring b (point)))))

(defun ci-load-src ()
  (set-buffer (get-buffer-create "src"))
  (erase-buffer)
  (let ((file-coding-system-for-read '*euc-japan*))
    (insert-file-contents ci-src))
  ;; 末尾の改行は数えたくない
  (goto-char (point-max))
  (if (bolp) (delete-char -1))
  (buffer-string))


;;; --- A. 起動と素性 ------------------------------------------------

(ci-try "version" (function (lambda () emacs-version)))
(ci-try "mule-p" (function (lambda () (if (boundp 'mule-version) "yes" "no"))))


;;; --- B. 多バイトの中核 --------------------------------------------

(defvar ci-text (ci-load-src))

;; 文字数。バイト数ではないこと。8 文字 16 バイト。
(ci-try "nchars"
  (function (lambda ()
    (set-buffer "src")
    (goto-char (point-min))
    (let ((n 0)) (while (not (eobp)) (forward-char 1) (setq n (1+ n))) n))))

;; length は内部表現のバイト数を返す。JIS の 1 文字が 3 バイトなので
;; 8 文字なら 24。ここが 16 や 8 になったら内部表現が変わったということ。
(ci-try "length" (function (lambda () (length ci-text))))

;; 全角は表示幅 2。ILP32/LP64 で Lisp_Object の詰め方が変わるので、
;; 文字属性が 64bit 環境で壊れていないかがここで出る。
(ci-try "width" (function (lambda () (string-width ci-text))))

;; 日本語の charset として認識されているか。Mule 2.3 に char-charset は
;; 無いので、領域から charset の一覧を取る。
(ci-try "charset"
  (function (lambda ()
    (set-buffer "src")
    (let ((l (find-charset-region (point-min) (point-max))) (r ""))
      (while l
        (setq r (concat r (if (string= r "") "" ",")
                        (if (symbolp (car l)) (symbol-name (car l))
                          (format "%s" (car l)))))
        (setq l (cdr l)))
      r))))

;; 符号化の往復。書いて読み直して、元と一致するか。
;; 期待値をこちらで持たずに済むので、私の符号表の思い違いが混ざらない。
(defun ci-roundtrip (tag coding file)
  (ci-try (concat "rt-" tag)
    (function (lambda ()
      (set-buffer "src")
      (ci-write (point-min) (point-max) file coding)
      (if (string= (ci-read-into "back" file coding) ci-text) "same" "DIFFER")))))

(ci-roundtrip "euc" '*euc-japan* "rt.euc")
(ci-roundtrip "sjis" '*sjis* "rt.sjis")
(ci-roundtrip "jis" '*junet* "rt.jis")
(ci-roundtrip "internal" '*internal* "rt.int")

;; 交差確認。EUC で書いたものを SJIS として読めば別物になるはず。
;; ここが "same" になるなら符号化指定が効いていない。
(ci-try "cross"
  (function (lambda ()
    (if (string= (ci-read-into "x" "rt.euc" '*sjis*) ci-text) "SAME-BUG" "differs"))))

;; ASCII を混ぜても壊れないか
(ci-try "mixed"
  (function (lambda ()
    (set-buffer (get-buffer-create "mix")) (erase-buffer)
    (insert "ab") (insert ci-text) (insert "cd")
    (ci-write (point-min) (point-max) "mix.euc" '*euc-japan*)
    (let ((s (ci-read-into "mixback" "mix.euc" '*euc-japan*)))
      (if (string= s (concat "ab" ci-text "cd")) "same" "DIFFER")))))


;;; --- C. 日本語テキストへの編集操作 --------------------------------

;; 検索。当たった範囲の中身が探した文字列そのものか。位置の数値では
;; なく中身で見る。Mule 2.3 の buffer 位置がバイト基準か文字基準かは
;; ここでは問わない。ずれていれば取り出した文字列が化けるので分かる。
(ci-try "search"
  (function (lambda ()
    (set-buffer "src") (goto-char (point-min))
    (let ((needle (ci-sub 5 8)))                ; テスト
      (if (search-forward needle nil t)
          (if (string= (buffer-substring (match-beginning 0) (match-end 0)) needle)
              "same" "DIFFER")
        "NOTFOUND")))))


;; 置換。長さの変わる置換にして、結果の buffer を丸ごと比べる。
;; 境界の扱いを間違えていれば、隣の文字が欠けるか半端なバイトが残る。
(ci-try "replace"
  (function (lambda ()
    (set-buffer (get-buffer-create "rep")) (erase-buffer)
    (insert ci-text)
    (goto-char (point-min))
    (let ((from (ci-sub 5 8))                   ; テスト  (3 文字)
          (to (ci-sub 0 2)))                    ; にほ    (2 文字)
      (if (search-forward from nil t)
          (progn (replace-match to t t)
                 (ci-write (point-min) (point-max) "rep.euc" '*euc-japan*)
                 (if (string= (buffer-string) (concat (ci-sub 0 5) to))
                     "same" "DIFFER"))
        "NOTFOUND")))))

;; 正規表現が探した中身に当たるか
(ci-try "regexp"
  (function (lambda ()
    (set-buffer "src") (goto-char (point-min))
    (let ((needle (ci-sub 5 8)))
      (if (re-search-forward (regexp-quote needle) nil t)
          (if (string= (buffer-substring (match-beginning 0) (match-end 0)) needle)
              "same" "DIFFER")
        "NOMATCH")))))

;; kill / yank の往復
(ci-try "killyank"
  (function (lambda ()
    (set-buffer (get-buffer-create "ky")) (erase-buffer)
    (insert ci-text)
    (kill-region (point-min) (point-max))
    (goto-char (point-min))
    (yank)
    (if (string= (buffer-string) ci-text) "same" "DIFFER"))))

;; undo が元に戻すか。名前が空白で始まる buffer は undo が切られるので
;; 普通の名前にし、undo-list を明示的に開けておく。
(ci-try "undo"
  (function (lambda ()
    (set-buffer (get-buffer-create "un")) (erase-buffer)
    (setq buffer-undo-list nil)
    (insert ci-text)
    (undo-boundary)
    (goto-char (point-min))
    (insert (ci-sub 0 2))
    ;; ここで undo-boundary を打つと、primitive-undo が先頭の境界だけ食って
    ;; 何も戻さない。境界は挿入の前に置いてあれば足りる。
    (primitive-undo 1 buffer-undo-list)
    (if (string= (buffer-string) ci-text) "same" "DIFFER"))))

;; 文字単位の削除。全角を 1 回の delete-char で消せるか。
(ci-try "delchar"
  (function (lambda ()
    (set-buffer (get-buffer-create "dc")) (erase-buffer)
    (insert ci-text)
    (goto-char (point-min))
    (delete-char 1)
    (if (string= (buffer-string) (ci-sub 1 8)) "same" "DIFFER"))))

;; 大文字化が日本語を壊さないか。ASCII だけが変わるべき。
(ci-try "upcase"
  (function (lambda ()
    (set-buffer (get-buffer-create "uc")) (erase-buffer)
    (insert "ab") (insert ci-text)
    (upcase-region (point-min) (point-max))
    (if (string= (buffer-string) (concat "AB" ci-text)) "same" "DIFFER"))))

;; 行の並べ替え。日本語の行を含めて sort が落ちないこと。
(ci-try "sort"
  (function (lambda ()
    (require 'sort)
    (set-buffer (get-buffer-create "so")) (erase-buffer)
    (insert "b\n") (insert ci-text) (insert "\na\n")
    (sort-lines nil (point-min) (point-max))
    (goto-char (point-min))
    (buffer-substring (point-min) (progn (end-of-line) (point))))))


;;; --- D. byte-compile ----------------------------------------------

;; 日本語文字列を含む .el を compile して、.elc から読み直しても
;; 文字列が保たれるか。compiler の reader/printer が多バイトを
;; 通せていないと、ここで壊れる。
(ci-try "bytecomp"
  (function (lambda ()
    (require 'bytecomp)
    (set-buffer (get-buffer-create "gen")) (erase-buffer)
    ;; defun の本体が文字列 1 個だけだと docstring 扱いになり、関数は nil を
    ;; 返す。値として持たせたいので defconst にする。
    (insert "(defconst ci-sample \"")
    (insert ci-text)
    (insert "\")\n")
    (ci-write (point-min) (point-max) "sample.el" '*euc-japan*)
    (let ((f (ci-file "sample.el")))
      (byte-compile-file f)
      (if (file-exists-p (concat f "c"))
          (progn (load (concat f "c") nil t t)
                 (if (string= ci-sample ci-text) "same" "DIFFER"))
        "NOELC")))))


;;; --- 書き出し ------------------------------------------------------

(ci-put "DONE" "1")
(set-buffer (get-buffer-create "out"))
(erase-buffer)
(let ((l (nreverse ci-results)))
  (while l (insert (car l)) (insert "\n") (setq l (cdr l))))
(let ((file-coding-system '*noconv*))
  (write-region (point-min) (point-max) (ci-file "results.txt") nil 'quiet))
