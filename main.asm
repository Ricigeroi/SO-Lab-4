section .text
mov     word [origin + 0], 0000h
mov     word [origin + 2], 0000h

mov     word [origin + 0], ax
mov     word [origin + 2], bx

start:
    mov si, msg
    add si, word [origin + 2]
    mov cx, len
    call print_str
    
    call break_line
    
    call read_input
    call clear_screen
    call get_cursor_pos
    mov [initial_cursor_row], dh
    mov [initial_cursor_col], dl

    loop:
        mov si, input_buffer
        mov cx, 2
        call print_str

        mov     ah, 00h
        int     16h
        cmp     al, 1bh
        je      exit_to_boot

        call break_line
        ; Convert from ASCII to integer (tens place)
        movzx eax, byte [input_buffer] ; First digit
        sub eax, '0'
        imul eax, 10 ; Multiply by 10

        ; Convert from ASCII to integer (ones place)
        movzx ebx, byte [input_buffer + 1] ; Second digit
        sub ebx, '0'

        ; Combine digits and decrement
        add eax, ebx ; Combine the digits

        cmp eax, 0
        je finish_loop
        dec eax      ; Decrement the number

        ; Convert back to ASCII
        xor edx, edx   ; Clear edx for division
        mov ebx, 10
        div ebx        ; Divide eax by 10, quotient in eax, remainder in edx
        add eax, '0'   ; Convert quotient (tens place) to ASCII
        add edx, '0'   ; Convert remainder (ones place) to ASCII

        ; Store the result back in 'num'
        mov [input_buffer], al
        mov [input_buffer + 1], dl
        
        ; Reset cursor position
        mov dh, [initial_cursor_row]
        mov dl, [initial_cursor_col]
        call set_cursor_pos

        jmp loop
    
    finish_loop:
        call clear_screen
        jmp start

clear_screen:
    mov     ah, 02h
    mov     bh, 0
    mov     dh, 0
    mov     dl, 0
    int     10h

    mov     cx, 25

    clear_screen_loop:
        push    cx

        mov     ah, 09h
        mov     al, 20h
        mov     bh, 0
        mov     bl, 07h
        mov     cx, 80
        int     10h

        call    break_line

        pop     cx
        dec     cx
        jnz     clear_screen_loop

    mov     ah, 02h
    mov     bh, 0
    mov     dh, 0
    mov     dl, 0
    int     10h

    ret

break_line:
    call    get_cursor_pos    ; Get the current cursor position
    inc     dh                ; Increment the row (dh holds the row position)
    mov     dl, 0             ; Set the column to the start (0)
    call    set_cursor_pos    ; Move the cursor to the new position
    ret

set_cursor_pos:
    mov     ah, 02h           ; Function code for setting cursor position
    mov     bh, 0             ; Page number (usually 0)
    int     10h               ; Call BIOS interrupt
    ret


print_str:
    push    cx

    call    get_cursor_pos

    mov     es, [origin + 0]
    mov     bp, si

    mov     bl, 07h
    pop     cx

    mov     ax, 1301h
    int     10h

    ret
    

get_cursor_pos:
    mov     ah, 03h
    mov     bh, 0
    int     10h

    ret

read_input:
    mov     si, input_buffer
    call    get_cursor_pos

    typing:

        ; read the key pressed

        mov     ah, 00h
        int     16h

        ; handle special keys

        cmp     al, 08h
	    je      hdl_backspace

	    cmp     al, 0dh
	    je      hdl_enter

        cmp     al, 20h
        je      typing

        ; prevent program form hading more than 2 characters

        cmp     si, input_buffer + 2
        je      typing

        ; save the character read to the buffer

        mov     [si], al
	    inc     si

        ; display the character read

        mov     ah, 0eh
	    int     10h

	    jmp     typing

    hdl_backspace:

        ; if the buffer is empty, ignore backspace

	    cmp     si, input_buffer
	    je      typing

        ; else erase the previous character from the buffer

	    dec     si
    	mov     byte [si], 0

        ; and print a blank space over it on the screen

        call    get_cursor_pos

        ; if at the start of the second+ line return to the previous row and proceed in the same manner

	    cmp     dl, 0
        je      prev_line

        mov     ah, 02h
        dec     dl
        int     10h

        mov     ah, 0ah
        mov     al, 20h
        int     10h

	    jmp     typing

    prev_line:
        mov     ah, 02h
        dec     dh
        mov     dl, 79
        int     10h

        mov     ah, 0ah
        mov     al, 20h
        int     10h
    
        jmp     typing

    hdl_enter:

        ; ensure that the buffer ends with an empty byte

        mov     byte [si], 0

        ret

    exit_to_boot:
        call    clear_screen

        pop     sp
        push    7e00h
        ret

section .data

msg                 db 'Enter a two-digit number: '
len                 equ 26

section .bss

origin              resb 4
input_buffer        resb 2
initial_cursor_row  resb 1
initial_cursor_col  resb 1