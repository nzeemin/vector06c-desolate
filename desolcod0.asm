
ColorNone .equ 00000000b
ColorC000 .equ 11111111b    ; Color for data on C000-DFFF
ColorE000 .equ 11111110b    ; Color for data on E000-FFFF - game screen
ColorBoth .equ 00000000b    ; Color for '1' bit in both spaces
; Palette colors
Col0000	.equ	ColorNone	;0
Col0001	.equ	ColorE000	;1
Col0010	.equ	ColorC000	;2
Col0011	.equ	ColorBoth	;3
Col0100	.equ	ColorNone	;4
Col0101	.equ	ColorE000	;5
Col0110	.equ	ColorC000	;6
Col0111	.equ	ColorBoth	;7
Col1000	.equ	ColorNone	;8
Col1001	.equ	ColorE000	;9
Col1010	.equ	ColorC000	;10
Col1011	.equ	ColorBoth	;11
Col1100	.equ	ColorNone	;12
Col1101	.equ	ColorE000	;13
Col1110	.equ	ColorC000	;14
Col1111	.equ	ColorBoth	;15

;----------------------------------------------------------------------------

Start	.equ	200h

	.EXPORT CpHLDE
	.EXPORT KeysLine0, KeysLine1, KeysLine5, KeysLine6, KeysLine7

;----------------------------------------------------------------------------

	.org	100h

	di
	xra	a
	out	10h
	lxi	sp,100h
	lxi	h,0C3F3h
	shld	0
	mov	a,h
	lxi	h,Restart
	shld	2
	sta	38h
	lxi	h,KEYINT
	shld	38h+1

	ei
	hlt

; Programming the Palette
	lxi	d, 100Fh
	lxi	h, Palette+15
PaletLoop:
	mov	a, e
	out	2
	mov	a, m
	out	0Ch
	out	0Ch
	out	0Ch
	out	0Ch
	out	0Ch
	dcx	h
	out	0Ch
	dcr	e
	out	0Ch
	dcr	d
	out	0Ch
	jnz	PaletLoop

Restart:
	lxi	sp,100h
	mvi	a, 88h
	out	4		; initialize R-Sound 2

	ei
	jp Start

KEYINT:
	push	psw
; Keyboard scan
	mvi	a, 8Ah
	out	0
	mvi	a, 0FEh
	out	3
	in	2
	sta	KeysLine0
	mvi	a, 0FDh
	out	3
	in	2
	sta	KeysLine1
	mvi	a, 0DFh
	out	3
	in	2
	sta	KeysLine5
	mvi	a, 0BFh
	out	3
	in	2
	sta	KeysLine6
	mvi	a, 07Fh
	out	3
	in	2
	sta	KeysLine7
; Scrolling, screen mode, border
	mvi	a, 88h
	out	0
	mvi	a, 2
	out	1
	mvi	a, 23
	out	3		; scrolling
	mvi	a, 00000000b
	out	2		; screen mode and border
;
	pop	psw
	ei
	ret

KeysLine0:	.db 11111111b
KeysLine1:	.db 11111111b
KeysLine5:	.db 11111111b
KeysLine6:	.db 11111111b
KeysLine7:	.db 11111111b

Palette:
	.db Col0000,Col0001,Col0010,Col0011
	.db Col0100,Col0101,Col0110,Col0111
	.db Col1000,Col1001,Col1010,Col1011
	.db Col1100,Col1101,Col1110,Col1111

; Compare HL and DE
CpHLDE:
	push h
	mov	a, l	  ;
	sbb	e	  ;
	mov	l, a	  ;
	mov	a, h	  ;
	sbb	d	  ;
	mov	h, a	  ;
	jc	$+7	  ;
	ora	l	  ;
	jmp	$+5	  ;
	ora	l	  ;
	stc	 	  ;
	pop h
	ret

; Filler
	.org	Start-1
	.db 0

	.end

;----------------------------------------------------------------------------
