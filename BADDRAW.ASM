.model small,pascal
jumps

code segment byte
   assume cs:code

img_h       dw 0
img_h_cur   dw 0
img_row_end dw 0
img_x_cur   db 0
img_transp  db 0
img_w       dw 0
img_x_shift db 0

BADDRAW proc far p:dword, scr:dword, x:word, y:word, t:word
	public  BADDRAW
    push    bp
    push    ds
    mov     ax, t
    mov     cs:img_transp, al
    mov     dl, ah
    lds     si, p
    les     di, scr
    mov     ax, [si]
    shr     ax, 1
    mov     cs:img_w, ax
    add     si, 2
    mov     ax, [si]
    mov     cs:img_h, ax
    add     si, 4
    mov     bx, y
    cmp     dl, 0
    je short no_cent_y
    shr     ax, 1
    sub     bx, ax
no_cent_y:
    mov     ax, bx
    mov     cl, 5
    shl     ax, cl
    sub     cl, 2
    shl     bx, cl
    add     bx, ax
    mov     ax, x
    cmp     dl, 0
    je short no_cent_x
    sub     ax, cs:img_w
no_cent_x:
    mov     ch, al
    shr     ax, cl
    add     bx, ax
    add     di, bx
    and     ch, 7
    mov     cs:img_x_cur, ch
    mov     cs:img_x_shift, ch
    mov     dx, 3CEh
    mov     al, 5
    out     dx, al
    inc     dx
    mov     al, 2
    out     dx, al
    mov     al, 8
    dec     dx
    out     dx, al
    inc     dx
    xor     ax, ax
    mov     cs:img_h_cur, ax
draw_row:
    xor     ax, ax
    mov     cs:img_w, ax
    mov     ch, cs:img_x_shift
    mov     cs:img_x_cur, ch
    mov     ax, [si]
    add     si, 2
    add     ax, si
    mov     cs:img_row_end, ax
    mov     bl, [si]
    inc     si
block:
    cmp     bl, 0FFh
    jg short draw
    sub     bl, 128
    mov     bh, [si]
fill:
    cmp     bl, 7
    jg short reload1
    mov     cl, bl
    dec     cl
    jmp     nreload1
reload1:
    mov     cl, 7
nreload1:
    mov     ax, 7F80h
    shr     ax, cl
    and     ax, 0FFh
    mov     ch, cl
    mov     cl, cs:img_x_cur
    shr     ax, cl
    cmp     bh, cs:img_transp
    je short transp1
    out     dx, al
    mov     al, es:[di]
    mov     es:[di], bh
transp1:
    mov     ax, 7
    sub     al, cl
    cmp     ch, al
    jle short xlim
    mov     ch, al
xlim:
    inc     ch
    add     cl, ch
    cmp     cl, 7
    jle short nadv_x1
    sub     cl, 8
    inc     di
    inc     cs:img_w
nadv_x1:
    mov     cs:img_x_cur, cl
    sub     bl, ch
    jg short fill
    inc     si
    jmp     end_chain
draw:
    mov     ch, 0
    mov     cl, cs:img_x_cur
draw_pix:
    mov     bh, [si]
    inc     si
    mov     ax, 80h
    shr     ax, cl
    cmp     bh, cs:img_transp
    je short transp2
    out     dx, al
    mov     al, es:[di]
    mov     es:[di], bh
transp2:
    inc     cl
    cmp     cl, 7
    jle short nadv_x2
    inc     di
    inc     cs:img_w
    mov     cl, 0
nadv_x2:
    inc     ch
    cmp     bl, ch
    jne short draw_pix
    mov     cs:img_x_cur, cl
end_chain:
    mov     bl, [si]
    inc     si
    mov     ax, cs:img_row_end
    cmp     ax, si
    jne     block
    mov     ax, cs:img_w
    sub     di, cs:img_w
    add     di, 320 / 8
    mov     ax, cs:img_h_cur
    inc     ax
    mov     cs:img_h_cur, ax
    cmp     ax, cs:img_h
    jl      draw_row
    pop     ds
    pop     bp
    mov     sp, bp
    ret
BADDRAW endp

code ends
end
