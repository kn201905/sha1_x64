
global G_base64_BE_20bytes

extern DBG_cout_LF
extern DBG_cout_pushed_128
extern DBG_cout_pushed_256

bits 64			; 64bit コードの指定
default rel		; デフォルトで RIP相対アドレシングを利用する

; =========================================
section .text

; -----------------------------------------
; <<< IN
; xmm0: (A B C D), xmm1: (E - - -)

; >>> OUT
; ymm0: base64 に変換された 27文字の ascii コード
;（注意）文字列はビッグエンディアンで格納される
; 　　　末尾 5文字には 'A' = 0x41 が設定される

; *** 破壊
; rax, rdi, ymm1, ymm2, ymm3: ワーキング

G_base64_BE_20bytes:
		; 6 bytes + 6 bytes + 6 bytes + 2 bytes に並べ替える
		vpblendd	xmm1, xmm1, xmm0, 1

		pshufb		xmm0, [L_shuffle_byte_1]
		pshufb		xmm1, [L_shuffle_byte_2]

		; 160 bits を 6 bit 毎に分割
		mov			rdi, 0x3f3f3f3f3f3f3f3f
		pextrq		rax, xmm0, 1
		pdep		rax, rax, rdi
		pinsrq		xmm0, rax, 1

		movq		rax, xmm0
		pdep		rax, rax, rdi
		pinsrq		xmm0, rax, 0

		pextrq		rax, xmm1, 1
		pdep		rax, rax, rdi
		pinsrq		xmm1, rax, 1

		movq		rax, xmm1
		pdep		rax, rax, rdi
		pinsrq		xmm1, rax, 0

		vperm2i128	ymm0, ymm0, ymm1, 0x02

		mov			eax, 51
		movd		xmm3, eax
		vpbroadcastb	ymm3, xmm3
		vpsubusb	ymm1, ymm0, ymm3	; ymm1 <- 0 - 12 の値になる

		mov			eax, 25
		movd		xmm3, eax
		vpbroadcastb	ymm3, xmm3
		vpcmpgtb	ymm2, ymm0, ymm3	; ymm2 <- 26 以上が 0xff

		vpsubb		ymm1, ymm1, ymm2
		;  0 - 25 -> 0 - 0 = 0
		; 26 - 51 -> 0 - 0xff = 1
		;      52 -> 1 - 0xff = 2
		;      53 -> 2 - 0xff = 3
		;   ...
		;      63 -> 12 - 0xff = 13

		vmovdqa		ymm3, [L_table_val]
		vpshufb		ymm1, ymm3, ymm1

		vpaddb		ymm0, ymm0, ymm1
		ret


; -----------------------------------------
	align 16
L_shuffle_byte_1:
	DQ 0x8080090807060504
	DQ 0x80800f0e0d0c0b0a

	align 16
L_shuffle_byte_2:
	DQ 0x80800d0c80808080
	DQ 0x8080030201000f0e

	align 32
L_table_val:
	DB 65		; A - Z 用
	DB 71		; a - z 用
	DB -4, -4, -4, -4, -4,   -4, -4, -4, -4, -4  ; 0 - 9 用
	DB '+'-62, '/'-63, 0, 0

	DB 65
	DB 71
	DB -4, -4, -4, -4, -4,   -4, -4, -4, -4, -4
	DB '+'-62, '/'-63, 0, 0

	; 'A' = 0x41 = 65 / 0 + 65 = 65
	; 'a' = 0x61 = 97 / 26 + 71 = 97
	; '0' = 0x30 = 48 / 52 - 4 = 48


; サンプルコード
%if 0
		; ---------------------------
		sub			rsp, 24
		movdqa		[rsp], xmm0
		call		DBG_cout_pushed_128
		call		DBG_cout_LF
		movdqa		[rsp], xmm1
		call		DBG_cout_pushed_128
		call		DBG_cout_LF
		call		DBG_cout_LF
		add			rsp, 24

		; ---------------------------
		sub			rsp, 40
		vmovdqu		[rsp], ymm0
		call		DBG_cout_pushed_256
		call		DBG_cout_LF
		add			rsp, 40
%endif
