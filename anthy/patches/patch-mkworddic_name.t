$NetBSD$

Fix the kanji for the novelist Abe Kobo (1924-1993).  The entry reads
"abekoubou" and gives 阿部公房; he wrote his family name 安部公房.

The neighbouring entries in this file already spell 安倍晋三, 安倍晴明
and 安倍なつみ correctly, so this is an isolated slip rather than a
convention the dictionary follows.  Writing a person's name with the
wrong character is a discourtesy in Japanese, and an input method that
offers only the wrong form makes the right one awkward to type.

Taken from Fedora, which has carried this since 2010 as
anthy-fix-typo-in-dict-name.patch.  anthy has not been released since
2009, so there is nowhere upstream to send it.

--- mkworddic/name.t.orig
+++ mkworddic/name.t
@@ -43,7 +43,7 @@
 あとうだたかし #JN #_4阿刀田_3高
 あなん #JN アナン
 あびるゆう #JN #_3あびる_2優
-あべこうぼう #JN #_2阿部_4公房
+あべこうぼう #JN #_2安部_4公房
 あべしゅしょう #JN #_2安倍_5首相
 あべしんぞう #JN #_2安倍_4晋三
 あべそうり #JN #_2安倍_3総理
