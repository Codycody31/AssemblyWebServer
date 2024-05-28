SYS_WRITE   equ 1 ; write text to stdout
SYS_READ    equ 0 ; read text from stdin
SYS_EXIT    equ 60 ; terminate the program
SYS_SOCKET  equ 41 ; create a socket
STDOUT      equ 1 ; stdout
SOCK_STREAM equ 1 ; stream socket
AF_INET     equ 2 ; IPv4
SYS_BIND    equ 49 ; bind a socket
SYS_LISTEN  equ 50 ; listen for connections
SYS_ACCEPT  equ 43 ; accept a connection
SYS_CLOSE   equ 3 ; close a file descriptor

;; Data definitions
struc sockaddr_in
    .sin_family resw 1
    .sin_port resw 1
    .sin_addr resd 1
    .sin_zero resb 8
endstruc

section .data
    ;; Data section for initialized data (mainly strings and structs)
    welcome_message db "Welcome to the Web Server in Assembly!", 0xA
    welcome_message_len equ $ - welcome_message

    port_attempt_message db "Attempting to bind to port: ", 0
    port_attempt_message_len equ $ - port_attempt_message

    port_message db "Server is listening on port: ", 0
    port_message_len equ $ - port_message

    connection_message db "Accepted connection!", 0xA
    connection_message_len equ $ - connection_message

    sock_err_msg        db "Failed to initialise socket", 0x0a, 0
    sock_err_msg_len    equ $ - sock_err_msg

    bind_err_msg        db "Failed to bind socket to listening address", 0x0a, 0
    bind_err_msg_len    equ $ - bind_err_msg

    lstn_err_msg        db "Failed to listen on socket", 0x0a, 0
    lstn_err_msg_len    equ $ - lstn_err_msg

    accept_err_msg      db "Could not accept connection attempt", 0x0a, 0
    accept_err_msg_len  equ $ - accept_err_msg

    newline db 0xA, 0         ; Newline

    ;; sockaddr_in structure for the address the listening socket binds to
    pop_sa istruc sockaddr_in
        at sockaddr_in.sin_family, dw AF_INET            ; AF_INET
        at sockaddr_in.sin_port, dw 0xa1ed        ; port 60833
        at sockaddr_in.sin_addr, dd 0             ; localhost
        at sockaddr_in.sin_zero, dd 0, 0
    iend
    sockaddr_in_len     equ $ - pop_sa
    
section .bss
    ; BSS section for uninitialized data
    sock_fd resb 4           ; Socket file descriptor
    client_fd resb 4         ; Client file descriptor
    port_str resb 6          ; Buffer to store port string
    
section .text
    global _start

_start:
    ;; Initialise listening and client socket values to 0, used for cleanup handling
    mov      word [sock_fd], 0
    mov      word [client_fd], 0

    ; Write welcome message to STDOUT
    mov     rax, SYS_WRITE          ; syscall number for SYS_WRITE
    mov     rdi, STDOUT             ; file descriptor for STDOUT
    mov     rsi, welcome_message
    mov     rdx, welcome_message_len
    syscall

    ; TODO: Crappy code below, need to fix
    ; somewhere I am not converting the port number correctly and then it fails to bind to the port

    pop       rax ; pop the arg count
    pop       rax ; pop the program name
    pop       rsi ; pop the only argument
    call string_to_int  ; convert the argument string to int

    ; we need to make the int to reverse byte order
    mov       bl, ah
    mov       bh, al
    mov [pop_sa + sockaddr_in.sin_port], bx

    mov     rax, SYS_WRITE           ; syscall number for SYS_WRITE
    mov     rdi, STDOUT           ; file descriptor for STDOUT
    mov     rsi, port_attempt_message
    mov     rdx, port_attempt_message_len
    syscall

    ; Convert port number to string
    mov     ax, word [pop_sa + sockaddr_in.sin_port]
    call    int_to_str

    ; Write port number to STDOUT
    mov     rax, SYS_WRITE           ; syscall number for SYS_WRITE
    mov     rdi, STDOUT           ; file descriptor for STDOUT
    lea     rsi,port_str
    mov     rdx, 6
    syscall

    ; Write newline to STDOUT
    mov     rax, SYS_WRITE           ; syscall number for SYS_WRITE
    mov     rdi, STDOUT           ; file descriptor for STDOUT
    lea     rsi, newline
    mov     rdx, 1
    syscall

    ;; Initialize socket
    call   _socket

    ;; Bind and Listen
    call _listen

    ; Write port message to STDOUT
    mov     rax, SYS_WRITE           ; syscall number for SYS_WRITE
    mov     rdi, STDOUT           ; file descriptor for STDOUT
    mov     rsi, port_message
    mov     rdx, port_message_len
    syscall

    ; Write port number to STDOUT
    mov     rax, SYS_WRITE           ; syscall number for SYS_WRITE
    mov     rdi, STDOUT           ; file descriptor for STDOUT
    lea     rsi, [port_str]
    mov     rdx, 6
    syscall

    ; Write newline to STDOUT
    mov     rax, SYS_WRITE           ; syscall number for SYS_WRITE
    mov     rdi, STDOUT           ; file descriptor for STDOUT
    lea     rsi, [newline]
    mov     rdx, 1
    syscall

_socket:
    ; Create a socket
    mov     rax, SYS_SOCKET          ; syscall number for SYS_SOCKET
    mov     edi, AF_INET           ; AF_INET
    mov     esi, SOCK_STREAM          ; SOCK_STREAM
    xor     edx, edx         ; Protocol (0 -> IP)
    syscall

    ;; Check socket was created correctly
    cmp        rax, 0
    jle        _socket_fail

    ;; Store socket descriptor in variable
    mov     [sock_fd], eax   ; Save socket file descriptor

_listen:
    ; Bind the socket
    mov     rax, SYS_BIND          ; syscall number for SYS_BIND
    mov     edi, [sock_fd]   ; Socket file descriptor
    lea     rsi, pop_sa ; Pointer to sockaddr_in
    mov     edx, sockaddr_in_len ; Size of sockaddr_in
    syscall

    ;; Check socket was bound correctly
    ;; TODO: Bind logic seems to be failing
    cmp rax, 0
    jl _bind_fail

    ; Listen on the socket
    mov     rax, SYS_LISTEN          ; syscall number for SYS_LISTEN
    mov     edi, [sock_fd]   ; Socket file descriptor
    mov     esi, 10          ; Backlog
    syscall

    ;; Check socket was bound correctly
    cmp rax, 0
    jl _listen_fail

    ret

string_to_int:
    xor     ebx,ebx    ; clear ebx
    xor     eax,eax
.next_digit:
    movzx   eax,byte[rsi]
    cmp     eax, 0
    jz      .finished
    inc     rsi
    sub     al,'0'    ; convert from ASCII to number
    imul    ebx,10
    add     ebx,eax   ; ebx = ebx*10 + eax
    jmp     .next_digit  ; while (--ecx)

    .finished:
    mov     eax,ebx
    ret ; return with the result in eax

; --------------------------------
; Helper function to convert integer to string
; Input: AX (16-bit integer)
; Output: port_str
; --------------------------------
int_to_str:
    push    rbx
    push    rcx
    push    rdx

    mov     rbx, 10
    lea     rdi, [port_str + 5]
    mov     byte [rdi], 0    ; Null-terminate the string

.convert_loop:
    xor     rdx, rdx
    div     rbx              ; Divide AX by 10
    add     dl, '0'
    dec     rdi
    mov     [rdi], dl
    or      ax, ax
    jnz     .convert_loop

    pop     rdx
    pop     rcx
    pop     rbx
    ret

;; Performs sys_close on the socket in rdi
_close_sock:
    mov     rax, SYS_CLOSE        ; SYS_CLOSE
    syscall

    ret

;; Error Handling code
;; _*_fail handle the population of the rsi and rdx registers with the correct
;; error messages for the labelled situation. They then call _fail to show the
;; error message and exit the application.
_socket_fail:
    mov     rsi, sock_err_msg
    mov     rdx, sock_err_msg_len
    call    _fail

_bind_fail:
    mov     rsi, bind_err_msg
    mov     rdx, bind_err_msg_len
    call    _fail

_listen_fail:
    mov     rsi, lstn_err_msg
    mov     rdx, lstn_err_msg_len
    call    _fail

_accept_fail:
    mov     rsi, accept_err_msg
    mov     rdx, accept_err_msg_len
    call    _fail

;; Calls the sys_write syscall, writing an error message to stderr, then exits
;; the application. rsi and rdx must be populated with the error message and
;; length of the error message before calling _fail
_fail:
    mov        rax, 1 ; SYS_WRITE
    mov        rdi, 2 ; STDERR
    syscall

    mov        rdi, 1
    call       _exit

;; Exits cleanly, checking if the listening or client sockets need to be closed
;; before calling sys_exit
_exit:
    mov        rax, [sock_fd]
    cmp        rax, 0
    je         .client_check
    mov        rdi, [sock_fd]
    call       _close_sock

    .client_check:
    mov        rax, [client_fd]
    cmp        rax, 0
    je         .perform_exit
    mov        rdi, [client_fd]
    call       _close_sock

    .perform_exit:
    mov        rax, 60
    syscall