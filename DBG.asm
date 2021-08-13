global DBG_cout_LF

global DBG_cout_pushed_32
global DBG_cout_pushed_64
global DBG_cout_pushed_128
global DBG_cout_pushed_256

global DBG_cout_LE_mem32_at_rax
global DBG_cout_LE_mem64_at_rax
global DBG_cout_LE_mem128_at_rax
global DBG_cout_LE_mem256_at_rax

global G_edi_val_to_rax_ui64str

bits 64			; 64bit コードの指定
default rel		; デフォルトで RIP相対アドレシングを利用する

%define sys_write	1

; =========================================
section .text

; -----------------------------------------
DBG_cout_LF:
		push	rax
		push	rdi
		push	rsi
		push	rdx
		push	rcx				; sys_write で rcx が破壊される

		mov		rax, sys_write
		mov		rdi, 2			; fd: dbg out
		mov		rsi, L_LF
		mov		rdx, 1			; len
		syscall

		pop		rcx
		pop		rdx
		pop		rsi
		pop		rdi
		pop		rax
		ret

align 2
L_LF:
	DB 0x0a

; -----------------------------------------
; スタックに push された 32bit 値を dbg out する
; <<< IN
; スタックに値を push
; >>> OUT
; 32bit 値の表示

DBG_cout_pushed_32:
		push	rdi
		mov		edi, [rsp + 16]

		push	rax
		push	rsi
		push	rdx
		push	rcx

		call	L_edi_val_to_rax_ui64str

		mov		rsi, L_str_dbgout
		mov		[rsi], rax

		mov		rax, sys_write
		mov		rdi, 2			; fd: dbg out
		mov		rdx, 9			; len
		syscall

		pop		rcx
		pop		rdx
		pop		rsi
		pop		rax

		pop		rdi
		ret

; -----------------------------------------
; スタックに push された 64bit 値を dbg out する
; <<< IN
; スタックに値を push
; >>> OUT
; 64bit 値の表示

DBG_cout_pushed_64:
		push	rdi
		mov		rdi, [rsp + 16]

		push	rax
		push	rsi
		push	rdx
		push	rcx

		mov		rdx, rdi
		call	L_edi_val_to_rax_ui64str

		mov		rsi, L_str_dbgout
		mov		[rsi + 9], rax

		shr		rdx, 32
		mov		edi, edx
		call	L_edi_val_to_rax_ui64str
		mov		[rsi], rax

		mov		rax, sys_write
		mov		rdi, 2			; fd: dbg out
		mov		rdx, 18			; len
		syscall

		pop		rcx
		pop		rdx
		pop		rsi
		pop		rax

		pop		rdi
		ret

; -----------------------------------------
; スタックに push された 128bit 値を dbg out する
; <<< IN
; スタックに値を push
; >>> OUT
; 64bit 値の表示
; 

DBG_cout_pushed_128:
		sub		rsp, 24
		movdqa	[rsp], xmm0
		movdqa	xmm0, [rsp + 32]

		push	rax
		push	rdi
		push	rsi
		push	rdx
		push	rcx

		movq	rdx, xmm0		; bit 63:0
		
		mov		edi, edx
		call	L_edi_val_to_rax_ui64str

		mov		rsi, L_str_dbgout
		mov		[rsi + 27], rax

		shr		rdx, 32
		mov		edi, edx
		call	L_edi_val_to_rax_ui64str
		mov		[rsi + 18], rax

		movhlps	xmm0, xmm0		; bit 127:64 -> 63:0
		movq	rdx, xmm0		; bit 127:64

		mov		edi, edx
		call	L_edi_val_to_rax_ui64str
		mov		[rsi + 9], rax

		shr		rdx, 32
		mov		edi, edx
		call	L_edi_val_to_rax_ui64str
		mov		[rsi], rax

		mov		rax, sys_write
		mov		rdi, 2			; fd: dbg out
		mov		rdx, 36			; len
		syscall

		pop		rcx
		pop		rdx
		pop		rsi
		pop		rdi
		pop		rax

		movdqa	xmm0, [rsp]
		add		rsp, 24
		ret

; -----------------------------------------
; スタックに push された 128bit 値を dbg out する
; <<< IN
; スタックに値を push
; >>> OUT
; 64bit 値の表示
; 

DBG_cout_pushed_256:
		sub		rsp, 40
		vmovdqu	[rsp], ymm0
		vmovdqu	ymm0, [rsp + 48]

		push	rax
		push	rdi
		push	rsi
		push	rdx
		push	rcx

		movq	rdx, xmm0		; bit 63:0		
		mov		edi, edx
		call	L_edi_val_to_rax_ui64str

		mov		rsi, L_str_dbgout
		mov		[rsi + 64], rax

		shr		rdx, 32
		mov		edi, edx
		call	L_edi_val_to_rax_ui64str
		mov		[rsi + 55], rax

		movhlps	xmm0, xmm0		; bit 127:64 -> 63:0
		movq	rdx, xmm0		; bit 127:64

		mov		edi, edx
		call	L_edi_val_to_rax_ui64str
		mov		[rsi + 46], rax

		shr		rdx, 32
		mov		edi, edx
		call	L_edi_val_to_rax_ui64str
		mov		[rsi + 37], rax

		vextracti128	xmm0, ymm0, 1	; bit 128:255 -> 127:0

		movq	rdx, xmm0		; bit 191:128	
		mov		edi, edx
		call	L_edi_val_to_rax_ui64str
		mov		[rsi + 27], rax

		shr		rdx, 32
		mov		edi, edx
		call	L_edi_val_to_rax_ui64str
		mov		[rsi + 18], rax

		movhlps	xmm0, xmm0
		movq	rdx, xmm0		; bit 255:192

		mov		edi, edx
		call	L_edi_val_to_rax_ui64str
		mov		[rsi + 9], rax

		shr		rdx, 32
		mov		edi, edx
		call	L_edi_val_to_rax_ui64str
		mov		[rsi], rax

		mov		rax, sys_write
		mov		rdi, 2			; fd: dbg out
		mov		rdx, 73			; len
		syscall

		pop		rcx
		pop		rdx
		pop		rsi
		pop		rdi
		pop		rax

		vmovdqu	ymm0, [rsp]
		add		rsp, 40
		ret
	
; -----------------------------------------
; rax で示されるアドレスから、32bit を dbg out する
; <<< IN
; rax : 表示したい 32bit 値が LE で格納されているアドレス
; >>> OUT
; 32bit 値の表示

DBG_cout_LE_mem32_at_rax:
		push	rax
		push	rdi
		push	rsi
		push	rdx
		push	rcx

		mov		edi, [rax]
		call	L_edi_val_to_rax_ui64str

		mov		rsi, L_str_dbgout
		mov		[rsi], rax

		mov		rax, sys_write
		mov		rdi, 2			; fd: dbg out
		mov		rdx, 9			; len
		syscall

		pop		rcx
		pop		rdx
		pop		rsi
		pop		rdi
		pop		rax
		ret

; -----------------------------------------
; rax で示されるアドレスから、64bit を dbg out する
; <<< IN
; rax : 表示したい 64bit 値が LE で格納されているアドレス
; >>> OUT
; 64bit 値の表示

DBG_cout_LE_mem64_at_rax:
		push	rax
		push	rdi
		push	rsi
		push	rdx
		push	rcx

		mov		rdx, [rax]
		mov		edi, edx
		call	L_edi_val_to_rax_ui64str

		mov		rsi, L_str_dbgout
		mov		[rsi + 9], rax

		shr		rdx, 32
		mov		edi, edx
		call	L_edi_val_to_rax_ui64str

		mov		[rsi], rax

		mov		rax, sys_write
		mov		rdi, 2			; fd: dbg out
		mov		rdx, 18			; len
		syscall

		pop		rcx
		pop		rdx
		pop		rsi
		pop		rdi
		pop		rax
		ret

; -----------------------------------------
; rax で示されるアドレスから、128bit を dbg out する
; <<< IN
; rax : 表示したい 128bit 値が LE で格納されているアドレス
; >>> OUT
; 128bit 値の表示

DBG_cout_LE_mem128_at_rax:
		push	rax
		push	rdi
		push	rsi
		push	rdx
		push	rcx
		push	rbx

		mov		rbx, rax
		mov		rdx, [rbx]		; rdx: 下位 64bits
		mov		edi, edx
		call	L_edi_val_to_rax_ui64str

		mov		rsi, L_str_dbgout
		mov		[rsi + 27], rax

		shr		rdx, 32
		mov		edi, edx
		call	L_edi_val_to_rax_ui64str
		mov		[rsi + 18], rax

		mov		rdx, [rbx + 8]	; rdx: 上位 64bits
		mov		edi, edx
		call	L_edi_val_to_rax_ui64str
		mov		[rsi + 9], rax

		shr		rdx, 32
		mov		edi, edx
		call	L_edi_val_to_rax_ui64str
		mov		[rsi], rax

		mov		rax, sys_write
		mov		rdi, 2			; fd: dbg out
		mov		rdx, 36			; len
		syscall

		pop		rbx
		pop		rcx
		pop		rdx
		pop		rsi
		pop		rdi
		pop		rax
		ret

; -----------------------------------------
; rax で示されるアドレスから、256bit を dbg out する
; <<< IN
; rax : 表示したい 256bit 値が LE で格納されているアドレス
; >>> OUT
; 256bit 値の表示

DBG_cout_LE_mem256_at_rax:
		push	rax
		push	rdi
		push	rsi
		push	rdx
		push	rcx
		push	rbx

		mov		rbx, rax
		mov		rdx, [rbx]			; rdx: bit 0 - 63
		mov		edi, edx
		call	L_edi_val_to_rax_ui64str

		mov		rsi, L_str_dbgout
		mov		[rsi + 64], rax

		shr		rdx, 32
		mov		edi, edx
		call	L_edi_val_to_rax_ui64str
		mov		[rsi + 55], rax

		mov		rdx, [rbx + 8]		; rdx: bit 64 - 127
		mov		edi, edx
		call	L_edi_val_to_rax_ui64str
		mov		[rsi + 46], rax

		shr		rdx, 32
		mov		edi, edx
		call	L_edi_val_to_rax_ui64str
		mov		[rsi + 37], rax


		mov		rdx, [rbx + 16]		; rdx: bit 128 - 191
		mov		edi, edx
		call	L_edi_val_to_rax_ui64str
		mov		[rsi + 27], rax

		shr		rdx, 32
		mov		edi, edx
		call	L_edi_val_to_rax_ui64str
		mov		[rsi + 18], rax

		mov		rdx, [rbx + 24]		; rdx: bit 192 -255
		mov		edi, edx
		call	L_edi_val_to_rax_ui64str
		mov		[rsi + 9], rax

		shr		rdx, 32
		mov		edi, edx
		call	L_edi_val_to_rax_ui64str
		mov		[rsi], rax

		mov		rax, sys_write
		mov		rdi, 2			; fd: dbg out
		mov		rdx, 73			; len
		syscall

		pop		rbx
		pop		rcx
		pop		rdx
		pop		rsi
		pop		rdi
		pop		rax
		ret

; -----------------------------------------
; <<< IN
; edi : ui64 化したい値
; >>> OUT
; rax : edi を ui64 化したもの（リトルエンディアン）
; *** 破壊
; rdi, rcx : ワーキング

G_edi_val_to_rax_ui64str:
L_edi_val_to_rax_ui64str:
		mov		rcx, 0x3030303030303030

		mov		eax, edi
		and		eax, 0xf
		cmp		eax, 0x0a
		jc		c_1
		add		eax, 0x61 - 0x3a
c_1:	shl		rax, 56
		add		rcx, rax

		mov		eax, edi
		and		eax, 0xf0
		cmp		eax, 0xa0
		jc		c_2
		add		eax, 0x610 - 0x3a0
c_2:	shl		rax, 44
		add		rcx, rax

		mov		eax, edi
		and		eax, 0xf00
		cmp		eax, 0xa00
		jc		c_3
		add		eax, 0x6100 - 0x3a00
c_3:	shl		rax, 32
		add		rcx, rax

		mov		eax, edi
		and		eax, 0xf000
		cmp		eax, 0xa000
		jc		c_4
		add		eax, 0x61000 - 0x3a000
c_4:	shl		rax, 20
		add		rcx, rax

		mov		eax, edi
		and		eax, 0xf0000
		cmp		eax, 0xa0000
		jc		c_5
		add		eax, 0x610000 - 0x3a0000
c_5:	shl		eax, 8
		add		rcx, rax

		mov		eax, edi
		and		eax, 0xf00000
		cmp		eax, 0xa00000
		jc		c_6
		add		eax, 0x6100000 - 0x3a00000
c_6:	shr		eax, 4
		add		rcx, rax

		mov		eax, edi
		and		eax, 0xf000000
		cmp		eax, 0xa000000
		jc		c_7
		add		eax, 0x61000000 - 0x3a000000
c_7:	shr		eax, 16
		add		rcx, rax

		mov		eax, edi
		and		eax, 0xf0000000
		cmp		eax, 0xa0000000
		jc		c_8
		mov		rdi, 0x610000000 - 0x3a0000000
		add		rax, rdi
c_8:	shr		rax, 28
		add		rax, rcx

		ret

; =========================================
section .data

align 2
L_str_dbgout:
	DB "******** ******** ******** ********  "
	DB "******** ******** ******** ******** "
