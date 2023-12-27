org 7e00h

section .text

start:
    xor     sp, sp
    call    read_hts

    mov     si, str2
    mov     cx, str2_len
    call    print_ln

    call    read_input

    mov     ax, 0
    call    check_num_input

    mov     di, nhts
    call    to_int

    call    read_ram_address

    mov     es, [address + 0]
    mov     bx, [address + 2]

    mov     al, [nhts + 0]
    mov     dl, 0
    mov     dh, [nhts + 2]
    mov     ch, [nhts + 4]
    mov     cl, [nhts + 6]

    mov     ah, 02h
    int     13h

    call    wait_for_keypress
    call    clear_screen

    mov     ds, [address + 0]
    mov     si, address + 2

    mov     ax, [address + 0]
    mov     bx, [address + 2]

    jmp     [si]


read_input:
    mov     si, input_buffer

    typing:
        ; read the key pressed
        mov     ah, 00h
        int     16h

        ; handle special keys
        cmp     al, 08h
	    je      backspace

	    cmp     al, 0dh
	    je      enter

        ; prevent program form reading more than 256 characters
        cmp     si, input_buffer + 4
        je      typing

        ; save the character read to the buffer
        mov     [si], al
	    inc     si

        ; display the character read
        mov     ah, 0eh
	    int     10h

	    jmp     typing

    backspace:
        ; if the buffer is empty, ignore backspace
	    cmp     si, input_buffer    
	    je      typing

        ; else erase the previous character from the buffer
	    dec     si
    	mov     byte [si], 0

        ; and print a blank space over it on the screen
        call    get_cursor_pos

        mov     ah, 02h
        dec     dl
        int     10h

        mov     ah, 0ah
        mov     al, 20h
        int     10h

	    jmp     typing

    enter:
        cmp     si, input_buffer    
        je      typing
        
        mov     byte [si], 0

        ret


to_int:
    mov     si, input_buffer

    to_int_loop:
        ; check if all the digits were converted
        cmp     byte [si], 0
        je      to_int_done

        ; convert the digit-character's bytes to the number equivalent
        xor     ax, ax
        mov     al, [si]
        sub     al, '0'

        ; shift all the digits one place left and put a new digit at the first place
        mov     bx, [di]
        imul    bx, 10
        add     bx, ax
        mov     [di], bx

        ; advance to pint at the next digit-char
        inc     si

        jmp     to_int_loop

    to_int_done:
        ret


to_hex:
    mov     si, input_buffer

    to_hex_loop:
        ; check if all the digits were converted
        cmp     byte [si], 0
        je      to_hex_done

        ; convert the digit-/letters-characters accordingly: there are 7 symbols between '9' and 'A' ('A' -> 10 --- 65 - 55 = 10)
        xor     ax, ax
        mov     al, [si]
        cmp     al, 65
        jl      conv_digit  

        conv_letter:
            sub     al, 55
            jmp     to_hex_done_iter

        conv_digit:
            sub     al, 48

        to_hex_done_iter:
            mov     bx, [di]
            imul    bx, 16
            add     bx, ax
            mov     [di], bx

            inc     si

        jmp     to_hex_loop

    to_hex_done:
        ret


check_num_input:
    mov     si, input_buffer
    mov     byte [operation_flag], 1

    check_char_loop:
        cmp     byte [si], 00h
        je      check_input_approved

        check_char_block:

            check_digits:
                cmp     byte [si], 30h
                jl      check_input_denied

                cmp     byte [si], 39h
                jle     char_approved

                cmp     ax, 1
                je      check_letters

                jmp     check_input_denied

            check_letters:
                cmp     byte [si], 41h
                jl      check_input_denied

                cmp     byte [si], 46h
                jg      check_input_denied

            char_approved:
                inc     si
                jmp     check_char_loop

    check_input_denied:
        mov     byte [operation_flag], 0

    check_input_approved:
        ret


read_hts:
    mov     si, str1
    mov     cx, str1_len
    call    print_ln

    mov     word [mp_16bit_counter], 1

    read_hts_loop:
        ; read user input (h)
        mov     si, promt
        mov     cx, plen
        call    print_ln
        call    read_input

        ; check the input
        mov     ax, 0
        call    check_num_input

        cmp     byte [operation_flag], 0
        je      read_hts_end

        ; convert 
        mov     di, nhts
        mov     cx, [mp_16bit_counter]
        imul    cx, 2
        add     di, cx
        call    to_int

        inc     word [mp_16bit_counter]

        cmp     word [mp_16bit_counter], 3
        jle     read_hts_loop

    read_hts_end:
        ret

read_ram_address:
    ; print "At which RAM address..."
    mov     si, str3
    mov     cx, str3_len
    call    print_ln

    mov     word [mp_16bit_counter], 0

    read_ram_address_loop:
        ; read user input (h)
        mov     si, promt
        mov     cx, plen
        call    print_ln
        call    read_input

        ; check the input
        mov     ax, 1
        call    check_num_input

        cmp     byte [operation_flag], 0
        je      read_ram_address_end

        ; convert 
        mov     di, address
        mov     cx, [mp_16bit_counter]
        imul    cx, 2
        add     di, cx
        call    to_hex

        inc     word [mp_16bit_counter]

        cmp     word [mp_16bit_counter], 1
        jle     read_ram_address_loop

    read_ram_address_end:
        ret


print_ln:
    push    cx

    call    get_cursor_pos
    inc     dh
    mov     dl, 0

    xor     ax, ax
    mov     es, ax
    mov     bp, si

    mov     bl, 07h
    pop     cx

    mov     ax, 1301h
    int     10h

    ret


clear_screen:
    call    ret_cursor
    mov     dx, 12

    clear_screen_loop:
        mov     ah, 09h
        mov     al, 20h
        mov     bh, 0
        mov     cx, 80
        int     10h

        push    dx
        mov     si, promt
        mov     cx, 0
        call    print_ln
        pop     dx

        dec     dx
        jnz     clear_screen_loop

    call    ret_cursor

    ret


get_cursor_pos:
    mov     ah, 03h
    mov     bh, 0
    int     10h

    ret


ret_cursor:
    mov     ah, 02h
    mov     bh, 0
    mov     dh, 0
    mov     dl, 0
    int     10h

    ret


wait_for_keypress:
    mov     si, pak_msg
    mov     cx, pak_msg_len
    call    print_ln

    mov     ah, 00h
    int     16h

    ret

section .data
    str1                db "Enter head, track, sector (one per line):"
    str1_len            equ 41

    str2                db "How many sectors to load: "
    str2_len            equ 26

    str3                db "Where in RAM to load (one per line):"
    str3_len            equ 36

    promt               db "> "
    plen                equ 2

    pak_msg             db "Press key to advance"
    pak_msg_len         equ 20

    operation_flag      db 0
    mp_16bit_counter    dw 0

section .bss
    input_buffer        resb 4
    address             resb 4
    nhts                resb 8