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


section .data
    welcome_message db "Welcome to the Web Server in Assembly!", 0xA
    welcome_message_len equ $ - welcome_message

    port_number dw 8080       ; Port number (8080 in network byte order)
    port_message db "Server is listening on port: ", 0
    port_message_len equ $ - port_message

    connection_message db "Accepted connection!", 0xA
    connection_message_len equ $ - connection_message

    newline db 0xA, 0         ; Newline

    ; Socket related constants
    sockaddr_in db 2, 0, 0x1F, 0x90 ; sin_family (AF_INET), sin_port (8080), sin_addr (INADDR_ANY)
    sin_addr db 0, 0, 0, 0   ; sin_addr (INADDR_ANY)
    sockaddr_in_size equ $ - sockaddr_in

section .bss
    ; BSS section for uninitialized data
    sock_fd resb 4           ; Socket file descriptor
    client_fd resb 4         ; Client file descriptor
    port_str resb 6          ; Buffer to store port string
    

section .text
    global _start

_start:
    ; Write welcome message to STDOUT
    mov     rax, SYS_WRITE          ; syscall number for SYS_WRITE
    mov     rdi, STDOUT             ; file descriptor for STDOUT
    mov     rsi, welcome_message
    mov     rdx, welcome_message_len
    syscall

    ; TODO: Read from .conf file, parse it and set the port number along with the binding address

    ; FIXME: Port number is listening on the wrong ports randomly

    ; Create a socket
    mov     rax, SYS_SOCKET          ; syscall number for SYS_SOCKET
    mov     edi, AF_INET           ; AF_INET
    mov     esi, SOCK_STREAM          ; SOCK_STREAM
    xor     edx, edx         ; Protocol (0 -> IP)
    syscall
    mov     [sock_fd], eax   ; Save socket file descriptor

    ; Bind the socket
    mov     rax, SYS_BIND          ; syscall number for SYS_BIND
    mov     edi, [sock_fd]   ; Socket file descriptor
    lea     rsi, [sockaddr_in] ; Pointer to sockaddr_in
    mov     edx, sockaddr_in_size ; Size of sockaddr_in
    syscall

    ; Listen on the socket
    mov     rax, SYS_LISTEN          ; syscall number for SYS_LISTEN
    mov     edi, [sock_fd]   ; Socket file descriptor
    mov     esi, 10          ; Backlog
    syscall

    ; Convert port number to string
    mov     ax, word [port_number]
    call    int_to_str

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

.wait_for_connection:
    ; Accept a connection
    mov     rax, SYS_ACCEPT          ; syscall number for SYS_ACCEPT
    mov     edi, [sock_fd]   ; Socket file descriptor
    xor     rsi, rsi         ; Null pointer for addr (we don't care about the address)
    xor     rdx, rdx         ; Null pointer for addrlen
    syscall
    mov     [client_fd], eax ; Save client file descriptor

    ; Write connection message to STDOUT
    mov     rax, SYS_WRITE           ; syscall number for SYS_WRITE
    mov     rdi, STDOUT           ; file descriptor for STDOUT
    mov     rsi, connection_message
    mov     rdx, connection_message_len
    syscall

    ; TODO: Handle the client request

    ; Close the client connection
    mov     rax, SYS_CLOSE           ; syscall number for SYS_CLOSE
    mov     edi, [client_fd] ; Client file descriptor
    syscall

    jmp     .wait_for_connection

    ; Exit the program (not reached in this example)
    mov     rax, SYS_EXIT          ; syscall number for SYS_EXIT
    xor     edi, edi         ; Status: 0
    syscall

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