global _start

extern DBG_cout_LF

extern DBG_cout_pushed_32
extern DBG_cout_pushed_64
extern DBG_cout_pushed_128
extern DBG_cout_pushed_256

extern DBG_cout_LE_mem32_at_rax
extern DBG_cout_LE_mem64_at_rax
extern DBG_cout_LE_mem128_at_rax
extern DBG_cout_LE_mem256_at_rax

extern G_edi_val_to_rax_ui64str

extern  G_sha1_block
extern	G_base64_BE_20bytes

bits 64			; 64bit コードの指定
default rel		; デフォルトで RIP相対アドレシングを利用する

%define	sys_exit	60
%define sys_write	1
%define sys_read	0

; =========================================
section .text align=4096

; -----------------------------------------
_start:
		; ---------------------------------
		; start program の表示
		mov		rax, sys_write
		mov 	rdi, 2					; dbg out
		mov 	rsi, L_msg_start
		mov 	rdx, 18					; length
		syscall

		; ---------------------------------
		mov		rax, sys_read
		mov		rdi, 0					; stdin
		mov 	rsi, L_1st_blk_to_hash	; store address
		mov 	rdx, 22					; length to read
		syscall

		; ---------------------------------
		; 確認のために、受け取った Websocket key を表示する
		mov		rax, sys_write
		mov 	rdi, 2					; dbg out
		mov 	rsi, L_1st_blk_to_hash
		mov 	rdx, 60
		syscall
		call	DBG_cout_LF
		call	DBG_cout_LF

		; ---------------------------------
		; 512 bit ブロックの用意
		movdqa	xmm6, [L_PSHUFB_Reverse]

		mov		rax, L_1st_blk_to_hash
		movdqa	xmm2, [rax]
		movdqa	xmm3, [rax + 16]
		movdqa	xmm4, [rax + 32]
		movdqa	xmm5, [rax + 48]

		pshufb	xmm2, xmm6
		pshufb	xmm3, xmm6
		pshufb	xmm4, xmm6
		pshufb	xmm5, xmm6

		; ---------------------------------
		; sha1 ハッシュ元値の用意
		mov		rax, L_init_sha_state
		movdqa	xmm0, [rax]
		movdqa	xmm1, [rax + 16]

		call	G_sha1_block

		; ---------------------------------
		; sha1 2nd ブロック
		pxor	xmm2, xmm2
		pxor	xmm3, xmm3
		pxor	xmm4, xmm4
		movdqa	xmm5, [L_2nd_blk_to_hash]

		call	G_sha1_block		; xmm0, xmm1 にハッシュ値が生成される

		; ---------------------------------
		; hash 値（20bytes）を、16進数で fd 1 に出力する
		mov		rax, 1				; hash 文字列の出力先
		call	L_out_to_rax_hash_xmm0_xmm1

		; ---------------------------------
		call	G_base64_BE_20bytes

		; ymm0 に設定された base64 文字列を、メモリに格納するため LE に並べ替える
		vpermq	ymm0, ymm0, 0x4e
		vpshufb	ymm0, ymm0, [L_PSHUFB_Reverse]

		; ---------------------------------
		; base64 文字列を fd 3 に出力する
		vmovdqa	[L_base64_str], ymm0

		mov		rax, sys_write
		mov		rdi, 3
		mov		rsi, L_base64_str
		mov		rdx, 27
		syscall

		; ---------------------------------
		mov 	rax, sys_exit
		mov 	rdi, 0  			; return code
		syscall

		; ---------------------------------
align 2
L_msg_start:
	DB  `--- start program\n`

; -----------------------------------------
; >>> IN
; rax : 出力先 fd
; xmm0, xmm1 : sha1 の結果（A' B' C' D'）,（E' - - -）

; <<< out
; rax で示される fd に L_str_of_hash_val の 44文字を出力する

; --- 破壊

L_out_to_rax_hash_xmm0_xmm1:
		push	rax

		pextrd	edi, xmm0, 3
		call	G_edi_val_to_rax_ui64str

		mov		rsi, L_str_of_hash_val
		mov		[rsi], rax

		pextrd	edi, xmm0, 2
		call	G_edi_val_to_rax_ui64str
		mov		[rsi + 9], rax

		pextrd	edi, xmm0, 1
		call	G_edi_val_to_rax_ui64str
		mov		[rsi + 18], rax

		pextrd	edi, xmm0, 0
		call	G_edi_val_to_rax_ui64str
		mov		[rsi + 27], rax

		pextrd	edi, xmm1, 3
		call	G_edi_val_to_rax_ui64str
		mov		[rsi + 36], rax

		mov		rax, sys_write
		pop		rdi
		mov		rsi, L_str_of_hash_val
		mov		rdx, 44
		syscall
		ret


; =========================================
section .data

	align 32
L_DBG_256bit_buf: times 32 db 0

	align 32
L_DBG_256bit_test_val: dq 0x0123456789abcdef,
				db "01234567",
				db "ABCDEFGH",
				db "IJKLMNOP"

	align 16
L_1st_blk_to_hash:
	DB "****####****####****##=="
	DB "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
	DB 0x80, 0, 0, 0

	align 16
L_2nd_blk_to_hash:
	DQ	0x1e0
	DQ	0

	align 16
L_PSHUFB_Reverse:		; 16 bytes x 2
	DQ  0x08090a0b0c0d0e0f
	DQ  0x0001020304050607
	DQ  0x08090a0b0c0d0e0f
	DQ  0x0001020304050607

	align 16
L_init_sha_state:
	DD	0x10325476, 0x98badcfe, 0xefcdab89, 0x67452301
	DD	0x00000000, 0x00000000, 0x00000000, 0xc3d2e1f0

	; ---------------------------------
	align 2
L_str_of_hash_val:
	DB "xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx"

	align 32
L_base64_str:
	times 32 DB 0

; =========================================
section .bss align=16
base64: resb 32

%if 0
; サンプル
		sub		rsp, 16
		movdqa	[rsp], xmm1
		call	DBG_cout_pushed_128
		call	DBG_cout_LF
		add		rsp, 16
%endif
