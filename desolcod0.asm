
ColorC000 .equ 11111111b    ; Color for data on C000-DFFF
ColorE000 .equ 11111110b    ; Color for data on E000-FFFF - game screen
ColorBoth .equ 00000000b    ; Color for '1' bit in both spaces
; Palette colors
Col0000	.equ	00000000b	;0
Col0001	.equ	ColorE000	;1
Col0010	.equ	ColorC000	;2
Col0011	.equ	ColorBoth	;3
Col0100	.equ	00000000b	;4
Col0101	.equ	ColorE000	;5
Col0110	.equ	ColorC000	;6
Col0111	.equ	ColorBoth	;7
Col1000	.equ	00000000b	;8
Col1001	.equ	ColorE000	;9
Col1010	.equ	ColorC000	;10
Col1011	.equ	ColorBoth	;11
Col1100	.equ	00000000b	;12
Col1101	.equ	ColorE000	;13
Col1110	.equ	ColorC000	;14
Col1111	.equ	ColorBoth	;15

Start   .equ    300h

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
; Show the logo
;		lxi	h,Logo
;		lxi	d,0C51Fh
;		call	DrwLogo
;		lxi	h,Logo
;		lxi	d,0E51Fh
;		call	DrwLogo

Restart:
		lxi	sp,100h
		mvi	a, 88h
		out	4		; initialize R-Sound 2

		ei
		jp Start

DrwLogo:
		mvi	b,22
logo2:	push	d
		mvi	c,15
logo1:	mov	a,m
		stax	d
		inx	h
		inr	e
		dcr	c
		jnz	logo1
		pop	d
		inr	d
		dcr	b
		jnz	logo2
		ret

KEYINT:
		push	psw
;TODO: Keyboard scan

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
		.org	2FFh
        .db 0

        .end
