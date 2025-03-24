.intel_syntax noprefix
.globl _start

.section .text
GET_PATH:   #rdi : request , rsi: address of the path

    mov rbp, rsp
    sub rsp, 0x10
    mov rcx, 0
    mov rdx, 0

    while_1:
    
    cmp BYTE PTR [rdi + rcx], 0x2f # '/'
    je while_2
    add rcx, 1
    jmp while_1
    
    while_2:
    
    cmp BYTE PTR [rdi + rcx], 0x20
    je after_while_2
    mov al, BYTE PTR [rdi + rcx]
    mov BYTE PTR [rsi + rdx], al
    add rcx, 1
    add rdx, 1
    jmp while_2

    after_while_2:
    mov rax, rcx
    mov rsp, rbp
    add rbp, 0x408
    ret

BODY_PARSER: #rdi: request , rsi : body address #output rax: length of body
    mov rbp, rsp
    sub rsp, 0x10
    mov rcx, 0
    mov rax, 0
    mov rdx, 0

    _while_1:
    
    cmp DWORD PTR [rdi + rcx], 0xa0d0a0d
    je _after_while_1
    add rcx, 1
    jmp _while_1

    _after_while_1:
    add rcx, 4
    mov rax, 0
    jmp _while_2
    
    _while_2:
    
    cmp BYTE PTR [rdi + rcx], 0x0
    je _after_while_2
    mov dl, BYTE PTR [rdi + rcx]
    mov BYTE PTR [rsi + rax], dl
    add rcx, 1
    add rax, 1
    jmp _while_2

    _after_while_2:

    mov rsp, rbp
    add rbp, 0x408 #this need to be changed if we change the caller function
    ret

_start:
    mov rbp, rsp
    sub rsp, 0x400

    mov rdi, 2
    mov rsi, 1
    mov rdx, 0
    mov rax, 41     
    syscall
    mov r8, rax

    mov WORD PTR [rbp - 0x18], 2
    mov WORD PTR [rbp - 0x16], 20480
    mov DWORD PTR [rbp - 0x14], 0x0

    # we gonna put the response's first line in stack
    mov DWORD PTR [rbp - 0x3f8], 0x50545448  # the statical response
    mov DWORD PTR [rbp - 0x3f4], 0x302e312f
    mov DWORD PTR [rbp - 0x3f0], 0x30303220
    mov DWORD PTR [rbp - 0x3ec], 0x0d4b4f20
    mov DWORD PTR [rbp - 0x3e8], 0x000a0d0a

    mov rdi, rax
    lea rsi, [rbp - 0x18]
    mov rdx, 16
    mov rax, 49
    syscall

    mov rdi, r8
    mov rsi, 0
    mov rax, 50
    syscall

    main_while_loop:
        #accept
        mov rdi, r8 
        mov rsi, 0
        mov rdx, 0
        mov rax, 43
        syscall
        mov r9, rax  # new connection file descriptor

        #fork
        mov rax, 57
        syscall

        cmp rax, 0
        je child

        
        parent : 
            #close
            mov rdi, r9
            mov rax, 3
            syscall

            jmp main_while_loop
            
        child:
            #close 3
            mov rdi, r8
            mov rax, 3
            syscall

            #read request
            mov rdi, r9
            lea rsi, [rbp - 0x3a8] #the content of the request
            mov rdx, 700
            mov rax, 0
            syscall

            #get the path and methode
            lea rdi, [rbp - 0x3a8]
            lea rsi, [rbp - 0x3e4] #PATH
            
            call GET_PATH


            cmp BYTE PTR [rbp - 0x3a8], 0x47
            je GET_HANDLER

            jmp POST_HANDLER

            POST_HANDLER:  
                

                #get the POST's body content
                lea rdi, [rbp - 0x3a8]
                lea rsi, [rbp - 0x1b4]
                call BODY_PARSER
                mov  r14, rax #the body length

                mov rdi, 1
                lea rsi, [rbp - 0x3e4]
                mov rdx, 14
                mov rax, 1
                syscall
                

                #open the file: we have the pathname in [rbp - 0x3e4]
                lea rdi, [rbp - 0x3e4]
                mov rsi, 65
                mov rdx, 511
                mov rax, 2
                syscall
                mov r10, rax
                
                #write content to file
                mov rdx, 0
                mov rdi, r10
                lea rsi, [rbp - 0x1b4]
                mov rdx, r14
                mov rax, 1
                syscall
                
                mov rdi, r10
                mov rax, 3
                syscall
                
                #write the first line (header)
                mov rdi, r9
                lea rsi, [rbp - 0x3f8]
                mov rdx, 19
                mov rax, 1
                syscall

                jmp EXIT

            GET_HANDLER:

                #open the file: we have the pathname in [rbp - 0x3e4]
                lea rdi, [rbp - 0x3e4]
                mov rsi, 0
                mov rdx, 0
                mov rax, 2
                syscall
                mov r10, rax
                

                #get content from the file
                mov rdi, r10
                lea rsi, [rbp - 0x3d0]
                mov rdx, 400
                mov rax, 0
                syscall
                mov r15, rax #file content length

                mov rdi, r10
                mov rax, 3
                syscall

                #write the first line (header)
                mov rdi, r9
                lea rsi, [rbp - 0x3f8]
                mov rdx, 19
                mov rax, 1
                syscall

                #write the body
                mov rdi, r9
                lea rsi, [rbp - 0x3d0]
                mov rdx, r15
                mov rax, 1
                syscall
                jmp EXIT

            EXIT:
                mov rdi, 0
                mov rax, 60
                syscall

        