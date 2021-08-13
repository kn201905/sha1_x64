global G_sha1_block

extern DBG_cout_LF
extern DBG_cout_pushed_128

bits 64			; 64bit コードの指定
default rel		; デフォルトで RIP相対アドレシングを利用する


; =========================================
section .text

; -----------------------------------------
; >>> IN
; [ハッシュ初期値] xmm0: (A B C D), xmm1: (E - - -)
; [512 bits ブロック] xmm2, xmm3, xmm4, xmm5 (注意：ビッグエンディアンで値を格納すること)
;
; <<< OUT
; [ハッシュ結果] xmm0 = (A' B' C' D'), xmm1 = (E' - - -)

; *** 破壊
; xmm2 - xmm8（xmm7, xmm8 は工夫次第で、破壊しなくて済むようにするのは容易）

G_sha1_block:
		movdqa		xmm7, xmm0		; (A B C D) を退避（最後に加算する必要があるため）
		movdqa		xmm8, xmm1		; (E - - -) を退避

		movdqa		xmm6, xmm0		; xmm6 = (a0 b0 c0 d0)
		sha1nexte	xmm6, xmm3		; xmm6: (a0 * * *), xmm3: (4 5 6 7)
									; xmm6 = (e4 + 4, 5 6 7)

		paddd		xmm1, xmm2		; xmm1 = (e0 + 0, 1 2 3)
		sha1rnds4	xmm0, xmm1, 0	; xmm0: (a0 b0 c0 d0), xmm1: (e0 + 0, 1 2 3)
									; xmm0 = (a4 b4 c4 d4)

		movdqa		xmm1, xmm0		; xmm1 = (a4 * * *)
		sha1nexte	xmm1, xmm4		; xmm1: (a4 * * *), xmm4: (8 9 10 11)
									; xmm1 = (e8 + 8, 9 10 11)
		sha1rnds4	xmm0, xmm6, 0	; xmm0: (a4 b4 c4 d4), xmm6: (e4 + 4, 5 6 7)
									; xmm0 = (a8 b8 c8 d8)

		movdqa		xmm6, xmm0		; xmm6 = (a8 b8 c8 d8)
		sha1nexte	xmm6, xmm5		; xmm6: (a8 * * *), xmm5: (12 13 14 15)
									; xmm6 = (e12 + 12, 13 14 15)
		sha1rnds4	xmm0, xmm1, 0	; xmm0: (a8 b8 c8 d8), xmm1: (e8 + 8, 9 10 11)
									; xmm0 = (a12 b12 c12 d12)

		sha1msg1	xmm2, xmm3		; xmm2 = (0 1 2 3) ^ (2 3 4 5)
		pxor		xmm2, xmm4		; xmm2 = (0 1 2 3) ^ (2 3 4 5) ^ (8 9 10 11)
		sha1msg2	xmm2, xmm5		; xmm2 = (16 17 18 19)
		; xmm2: (16 17 18 19), xmm3: (4 5 6 7), xmm4: (8 9 10 11), xmm5 (12 13 14 15)

		movdqa		xmm1, xmm0
		sha1nexte	xmm1, xmm2		; xmm1 = (a16 + 16, 17 18 19)
		sha1rnds4	xmm0, xmm6, 0	; xmm0: (a12 b12 c12 d12), xmm6: (e12 + 12, 13 14 15)
									; xmm0 = (a16 b16 c16 d16)

		sha1msg1	xmm3, xmm4		; xmm3: (4 5 6 7)
		pxor		xmm3, xmm5
		sha1msg2	xmm3, xmm2		; xmm3 = (20 21 22 23)

		movdqa		xmm6, xmm0
		sha1nexte	xmm6, xmm3		; xmm6: (e20 + 20, 21 22)
		sha1rnds4	xmm0, xmm1, 0	; xmm0: (a16 b16 c16 d16), xmm1: (a16 + 16, 17 18 19)
									; xmm0 = (a20 b20 c20 d20)

		sha1msg1	xmm4, xmm5		; xmm4: (8 9 10 11)
		pxor		xmm4, xmm2
		sha1msg2	xmm4, xmm3		; xmm4 = (24 25 26 27)

		movdqa		xmm1, xmm0		; xmm0: (a20 b20 c20 d20)
		sha1nexte	xmm1, xmm4		; xmm1 = (e24 + 24, 25 26 27)
		sha1rnds4	xmm0, xmm6, 1	; xmm0 = (a24 b24 c24 d24)

%if 0
		sha1msg1	xmm5, xmm2		; xmm5: (12 13 14 15)
		pxor		xmm5, xmm3
		sha1msg2	xmm5, xmm4		; xmm5 = (28 29 30 31)

		movdqa		xmm6, xmm0		; xmm0: (a24 b24 c24 d24)
		sha1nexte	xmm6, xmm5		; xmm6 = (e28 + 28, 29 30 31)
		sha1rnds4	xmm0, xmm1, 1	; xmm0 = (a28 b28 c28 d28)
%endif

		; ----------------------------------------
	%xdefine	W_0			xmm5
	%xdefine	W_1			xmm2
	%xdefine	W_2			xmm3
	%xdefine	W_3			xmm4
	%xdefine 	W_0_Next	xmm5

	%xdefine	E_0			xmm6
	%xdefine	E_1			xmm1
	%xdefine	E_0_Next	xmm6

%macro	M_Crt_NextHash  1
	sha1msg1	W_0, W_1
	pxor		W_0, W_2
	sha1msg2	W_0_Next, W_3

	movdqa		E_0, xmm0
	sha1nexte	E_0_Next, W_0_Next
	sha1rnds4	xmm0, E_1, %1
%endmacro

%macro	M_W_E_Rotate  0
	%xdefine	W_0		W_1
	%xdefine	W_1		W_2
	%xdefine	W_2		W_3
	%xdefine	W_3		W_0_Next
	%xdefine	W_0_Next	W_0

	%xdefine	E_0		E_1
	%xdefine	E_1		E_0_Next
	%xdefine	E_0_Next	E_0
%endmacro

		M_Crt_NextHash	1		; xmm0 = (a28 b28 c28 d28)

		M_W_E_Rotate
		M_Crt_NextHash	1		; xmm0 = (a32 b32 c32 d32)

		M_W_E_Rotate
		M_Crt_NextHash	1		; xmm0 = (a36 b36 c36 d36)

		M_W_E_Rotate
		M_Crt_NextHash	1		; xmm0 = (a40 b40 c40 d40)

%rep	5
		M_W_E_Rotate
		M_Crt_NextHash	2
%endrep

%rep	4
		M_W_E_Rotate
		M_Crt_NextHash	3
%endrep

		; W80 と e80 + W80 は不要であるため、M_Crt_NextHash は利用しない
		M_W_E_Rotate

		; E_0 = xmm1 , E_1 = xmm6
		movdqa		xmm1, xmm0		; xmm1（= E_0）に a76 を保存しておく
		sha1rnds4	xmm0, xmm6, 3	; xmm0 = (a80 b80 c80 d80)

		; 最初のハッシュ元値を加算して、ハッシュ値の結果を生成する
		paddd		xmm0, xmm7
		sha1nexte	xmm1, xmm8		; xmm1 = (e80 + e0, - - -)

		ret
