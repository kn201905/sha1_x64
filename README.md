# このリポジトリの意図
　最近 arm64 のアセンブラに関心を持ち、sha1 と base64 に関するコードを neon で書いてみたところ、なかなか面白かったため、
x64 の sha1 拡張命令（Skylake 以降で利用可能な拡張命令）を用いて書くとどうなるか試したくてコードを書き上げてみた。

　avx 命令や、nasm の使い方の良いサンプルとなるものができたため、リポジトリとして残しておくことにした。
 
　sha1.asm では、コードの完成形をサンプルとして提示するのではなく、nasm の xdefine やマクロの使い方の参考となるように書いたため、
後学者が参考にしやすい形になってると思う。
 
　今回は base64 をビッグエンディアンで処理する形で実装を行ったが、リトルエンディアンで処理する形で処理した方が実装をしやすいと思う。
リトルエンディアンで実装する場合、以下のコードを参考にすると良いと思う。
今後、時間に余裕があれば、リトルエンディアンで処理する実装もしてみたいと思っている。

https://github.com/WojciechMula/base64simd/blob/master/encode/unpack_bigendian.cpp

（注意）base64_BE.asm で利用している pdep 命令は、AMD の ZEN, ZEN2 アーキテクチャでは実行速度が非常に遅いため利用しない方が良い。
ZEN3 において、intel の core i 系と同じ実行速度に改善された。
core i 系では、どのような回路を組んでいるのか関心を引かれるほどに pdep 命令の実行速度が速い。

（補足）私は Websocket をよく利用するため、Websocket に利用しやすい形で実装している。

# リポジトリの内容
* sha1.asm : sha1 ハッシュ値を出力する
* base64_BE.asm : base64 文字列をビッグエンディアンで出力する

* main.asm : sha1.asm のテスト用
* DBG.asm : デバッグ用
* test.sh : main.asm をシェルから起動して確認するスクリプト

 
