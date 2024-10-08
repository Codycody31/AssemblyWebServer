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
SYS_CREATE  equ 8
SYS_MKDIR   equ 83
SYS_STAT    equ 4

;; Data definitions
struc sockaddr_in
    .sin_family resw 1
    .sin_port resw 1
    .sin_addr resd 1
    .sin_zero resb 8
endstruc

section .bss
    ; BSS section for uninitialized data
    sock resw 4           ; Socket file descriptor
    client resw 4         ; Client file descriptor
    port_str resb 6          ; Buffer to store port string
    echobuf resb 256
    read_count resw 2
    fd  resd 1                  ; File descriptor
    bytes_read resd 1           ; Number of bytes read

section .data
    stat_buf times 144 db 0

    welcome_msg db "Welcome to the Web Server in Assembly!", 0xA
    welcome_msg_len equ $ - welcome_msg

    port_attempt_msg db "Attempting to bind to port: ", 0
    port_attempt_msg_len equ $ - port_attempt_msg

    port_msg db "Server is listening on port: ", 0
    port_msg_len equ $ - port_msg

    connection_msg db "Accepted connection!", 0xA
    connection_msg_len equ $ - connection_msg

    sock_err_msg        db "Failed to initialise socket", 0x0a, 0
    sock_err_msg_len    equ $ - sock_err_msg

    bind_err_msg        db "Failed to bind socket to listening address", 0x0a, 0
    bind_err_msg_len    equ $ - bind_err_msg

    lstn_err_msg        db "Failed to listen on socket", 0x0a, 0
    lstn_err_msg_len    equ $ - lstn_err_msg

    accept_err_msg      db "Could not accept connection attempt", 0x0a, 0
    accept_err_msg_len  equ $ - accept_err_msg

    web_root_path_creation_error_msg db "Failed to create directory.", 10
    web_root_path_creation_error_msg_len equ $ - web_root_path_creation_error_msg

    accept_msg          db "Client connected!", 0x0a, 0
    accept_msg_len      equ $ - accept_msg

    response_msg        db `HTTP/1.1 200 OK\r\nConnection: close\r\nContent-length: 0\r\n`
    response_msg_len    equ $ - response_msg

    close_msg           db "Closing connection", 0x0a, 0
    close_msg_len       equ $ - close_msg

    default_port_str    db "8000", 0
    default_port_str_len equ $ - default_port_str

    web_root_path            db "./www", 0
    weB_root_len        equ $ - web_root_path

    config_file             db "./www/aws.cfg", 0
    config_file_len     equ $ - config_file

    buffer   times 4096 db 0    ; Buffer to hold file contents (4 KiB)
    length   equ $ - buffer     ; Length of the buffer

    newline db 0xA, 0         ; Newline

    ;; sockaddr_in structure for the address the listening socket binds to
    pop_sa istruc sockaddr_in
        at sockaddr_in.sin_family, dw 2            ; AF_INET
        at sockaddr_in.sin_port, dw 0xa1ed        ; port 60833
        at sockaddr_in.sin_addr, dd 0             ; localhost
        at sockaddr_in.sin_zero, dd 0, 0
    iend
    sockaddr_in_len     equ $ - pop_sa

section .text
    global _start

_start:
    ;; Initialise listening and client socket values to 0, used for cleanup handling
    mov      word [sock], 0
    mov      word [client], 0

    ; Write welcome msg to STDOUT
    mov     rsi, welcome_msg
    mov     rdx, welcome_msg_len
    call    write_string
    
    ;; TODO: Pass all of this code off to a call, cleaning up _start

    ;; Check if the directory exists using `stat`
    mov     rax, SYS_STAT
    mov     rdi, web_root_path
    lea     rsi, [stat_buf]
    syscall

    ;; Check if stat was successful
    test    rax, rax
    jz      .web_root_path_exists

    ;; If directory doesn't exist, create it using `mkdir`
    mov     rax, SYS_MKDIR
    mov     rdi, web_root_path
    mov     rsi, 0o777
    syscall

    ;; Check if the mkdir syscall was successful
    test    rax, rax
    js      _web_root_path_creation_error

.web_root_path_exists:

    ; TODO: load web_root_path, port number, etc, from .cfg file or whatever (similar to Apache)
    ; first check PWD for aws.cfg (ehhhh...should be fine?), or /etc/ blablabla proper linux dir /aws.cfg

    ; Read File
    
    ; Open the file (syscall: sys_open)
    mov rax, 2                  ; syscall number for sys_open (2)
    lea rdi, [rel config_file]     ; filename pointer
    mov rsi, 0                  ; O_RDONLY (read only)
    syscall                     ; Call the kernel

    test    rax, rax
    js  code_after_file_stuff

    mov [fd], rax               ; Store the file descriptor

read_loop:
    ; Read a chunk of the file (syscall: sys_read)
    mov rax, 0                  ; syscall number for sys_read (0)
    mov rdi, [fd]               ; file descriptor
    lea rsi, [rel buffer]       ; buffer pointer
    mov rdx, length             ; number of bytes to read (4 KiB)
    syscall                     ; Call the kernel
    mov [bytes_read], rax       ; Store the number of bytes read

    ; Check for end of file (EOF)
    cmp rax, 0                  ; Was the number of bytes read 0?
    je close_file               ; If yes, we reached EOF, so close the file

    ; Initialize pointers and flags
    lea rsi, [rel buffer]       ; rsi points to the start of the buffer
    mov rcx, [bytes_read]       ; rcx holds the number of bytes read
    xor rbx, rbx                ; rbx will store the extracted port number
    xor rdi, rdi                ; rdi will be used as a parsing flag (0 = not found, 1 = found)

parse_chunk:
    ; Check if we've parsed the entire buffer
    cmp rcx, 0
    je close_file          ; If zero, we have finished parsing the buffer

    ; Check for "port="
    mov al, byte [rsi]          ; Load current byte
    cmp al, 'p'                 ; Is it 'p'?
    jne next_byte
    cmp byte [rsi+1], 'o'       ; Is the next byte 'o'?
    jne next_byte
    cmp byte [rsi+2], 'r'       ; Is the next byte 'r'?
    jne next_byte
    cmp byte [rsi+3], 't'       ; Is the next byte 't'?
    jne next_byte
    cmp byte [rsi+4], '='       ; Is the next byte '='?
    jne next_byte

    ; "port=" found, parse the number
    add rsi, 4                  ; Skip the "port=" part
    mov rdi, 0                  ; Set parsing flag to 1
parse_port_number:
    cmp byte [rsi], '\n'        ; Check for newline
    je next_byte                ; Stop parsing if newline is found
    cmp byte [rsi], '0'         ; Check if the character is a digit
    jb next_byte                ; If less than '0', skip to the next byte
    cmp byte [rsi], '9'         ; Check if the character is a digit
    ja next_byte                ; If greater than '9', skip to the next byte

    ; Convert character to digit and accumulate in rbx
    sub byte [rsi], '0'         ; Convert ASCII to integer
    imul rbx, rbx, 10           ; Multiply rbx by 10 (shift left by one decimal place)
    add rbx, [rsi]              ; Add the digit to rbx

next_byte:
    inc rsi                     ; Move to the next byte
    loop parse_chunk            ; Repeat until we've parsed all bytes

close_file:
    ; Close the file (syscall: sys_close)
    mov rax, 3                  ; syscall number for sys_close (3)
    mov rdi, [fd]               ; file descriptor
    syscall                     ; Call the kernel

code_after_file_stuff:
    ; write first part of port attmpt msg, must do before due to popping ltr to rsi
    mov     rsi, port_attempt_msg
    mov     rdx, port_attempt_msg_len
    call    write_string

    pop       rax ; pop the arg count
    pop       rax ; pop the program name
    pop       rsi ; pop the only argument

;     ; TODO: Check if RBX contains stuff
;     ; If so convert to string, and overwrite default_port_str

;     ; Find which one works
;     cmp rbx, 0
;     jz  no_config_port_number

;     mov     ax, rbx
;     call int_to_str
;     mov     default_port_str, port_str

; no_config_port_number:

    ; Check if a port number was provided
    test    rsi, rsi           ; Test if RSI is zero (no argument provided)
    jz      use_default_port   ; If zero, use the default port

    cmp     byte [rsi], 0      ; Check if the first byte is null (empty string)
    jne     port_provided      ; If not null, port number is provided

use_default_port:
    ; Use default port if none provided
    mov     rsi, default_port_str
port_provided:
    ; Calculate the length of the port number string
    xor     rcx, rcx        ; Clear rcx to use as a counter
    mov     rdi, rsi        ; Copy rsi to rdi to use it in the loop
calc_length:
    ; Calculate the length of the port number string
    ; Done to prevent the fetching of more memory then we are suppose to, given that if we did mov rdx, [rsi] it would result in dumping the shell stuff also
    ; For example env vars and other things and not just the port number as expected
    cmp     byte [rdi], 0   ; Check if the current byte is 0 (end of string)
    je      length_done     ; If it is, we're done
    inc     rdi             ; Move to the next byte
    inc     rcx             ; Increment the counter (size of port number stored at rsi)
    jmp     calc_length     ; Repeat the loop
length_done:

    ; Write the port number string to STDOUT
    mov     rax, SYS_WRITE          ; syscall number for SYS_WRITE
    mov     rdi, STDOUT             ; file descriptor for STDOUT
    ; rsi already holds the port number string
    mov     rdx, rcx                ; rdx holds the length of the string
    syscall

    ; Mov the string length to r13, and the string to r14
    mov r13, rdx
    mov r14, rsi

    ; Write newline to STDOUT but preserve rsi
    mov    r15, rsi
    call write_newline
    mov    rsi, r15

    call string_to_int  ; convert the argument string to int

    ; we need to make the int to reverse byte order
    mov       bl, ah
    mov       bh, al

    mov [pop_sa + sockaddr_in.sin_port], bx

    ;; Initialize socket
    call   _socket

    ;; Bind and Listen
    call _listen

    ; Write port msg to STDOUT
    mov     rax, SYS_WRITE           ; syscall number for SYS_WRITE
    mov     rdi, STDOUT           ; file descriptor for STDOUT
    mov     rsi, port_msg
    mov     rdx, port_msg_len
    syscall

    ; Mov the string length to r13, and the string to r14
    mov rcx, r13
    mov rsi, r14

    ; Write the port number string to STDOUT
    mov     rax, SYS_WRITE          ; syscall number for SYS_WRITE
    mov     rdi, STDOUT             ; file descriptor for STDOUT
    ; rsi already holds the port number string
    mov     rdx, rcx                ; rdx holds the length of the string
    syscall

    xor rsi, rsi
    xor r13, r13
    xor r14, r14

    ; Write newline to STDOUT but preserve rsi
    call write_newline

    ;; Main loop handles clients connecting (accept()) then echoes any input
     ;; back to the client
     .mainloop:
         call     _accept

         ;; Read and re-send all bytes sent by the client until the client hangs
         ;; up the connection on their end.
         ; .readloop:
         ;     call     _read
             call     _echo

             ;; read_count is set to zero when client hangs up
             ; mov     rax, [read_count]
             ; cmp     rax, 0
         ;     jmp      .read_complete
         ; jmp .readloop

         ; .read_complete:
         ;; Close client socket

         ; mov rax, 35
         ; mov rdi, timespec
         ; xor rsi, rsi
         ; syscall


         mov    rdi, [client]
         call   _close_sock
         mov    word [client], 0
     jmp    .mainloop

     ;; Exit with success (return 0)
     mov     rdi, 0
     call     _exit

;; Performs a sys_socket call to initialise a TCP/IP listening socket, storing
;; socket file descriptor in the sock variable
_socket:
    ; Create a socket
    mov     rax, SYS_SOCKET          ; syscall number for SYS_SOCKET
    mov     rdi, AF_INET           ; AF_INET
    mov     rsi, SOCK_STREAM          ; SOCK_STREAM
    mov     rdx, 0         ; Protocol (0 -> IP)
    syscall

    ;; Check socket was created correctly
    cmp        rax, 0
    jle        _socket_fail

    ;; Store socket descriptor in variable
    mov     [sock], rax   ; Save socket file descriptor

    ret

;; Calls sys_bind and sys_listen to start listening for connections
_listen:
    ; Bind the socket
    mov     rax, SYS_BIND          ; syscall number for SYS_BIND
    mov     rdi, [sock]   ; Socket file descriptor
    lea     rsi, pop_sa ; Pointer to sockaddr_in
    mov     rdx, sockaddr_in_len ; Size of sockaddr_in
    syscall

    ;; Check socket was bound correctly
    ;; TODO: Bind logic seems to be failing
    cmp rax, 0
    jl _bind_fail

    ; Listen on the socket
    mov     rax, SYS_LISTEN          ; syscall number for SYS_LISTEN
    mov     rsi, 1          ; Backlog
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

;; Accepts a connection from a client, storing the client socket file descriptor
;; in the client variable and logging the connection to stdout
_accept:
    ;; Call sys_accept
    mov       rax, 43         ; SYS_ACCEPT
    mov       rdi, [sock]     ; listening socket fd
    mov       rsi, 0          ; NULL sockaddr_in value as we don't need that data
    mov       rdx, 0          ; NULLs have length 0
    syscall

    ;; Check call succeeded
    cmp       rax, 0
    jl        _accept_fail

    ;; Store returned fd in variable
    mov     [client], rax

    ;; Log connection to stdout
    mov       rax, 1             ; SYS_WRITE
    mov       rdi, 1             ; STDOUT
    mov       rsi, accept_msg
    mov       rdx, accept_msg_len
    syscall

    ret

;; Reads up to 256 bytes from the client into echobuf and sets the read_count variable
;; to be the number of bytes read by sys_read
_read:
    ;; Call sys_read
    mov     rax, 0          ; SYS_READ
    mov     rdi, [client]   ; client socket fd
    mov     rsi, echobuf    ; buffer
    mov     rdx, 256        ; read 256 bytes
    syscall

    ;; Copy number of bytes read to variable
    mov     [read_count], rax

    ret

;; Sends up to the value of read_count bytes from echobuf to the client socket
;; using sys_write
_echo:
    mov     rax, 1               ; SYS_WRITE
    mov     rdi, [client]        ; client socket fd
    mov     rsi, response_msg         ; buffer
    mov     rdx, response_msg_len    ; number of bytes received in _read
    syscall

    ret

;; Performs sys_close on the socket in rdi
_close_sock:
    mov     rax, SYS_CLOSE        ; SYS_CLOSE
    syscall

    ret

;; Error Handling code
;; _*_fail handle the population of the rsi and rdx registers with the correct
;; error msgs for the labelled situation. They then call _fail to show the
;; error msg and exit the application.
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

_web_root_path_creation_error:
    mov     rsi, web_root_path_creation_error_msg
    mov     rdx, web_root_path_creation_error_msg_len
    call _fail

;; Calls the sys_write syscall, writing an error msg to stderr, then exits
;; the application. rsi and rdx must be populated with the error msg and
;; length of the error msg before calling _fail
_fail:
    mov        rax, 1 ; SYS_WRITE
    mov        rdi, 2 ; STDERR
    syscall

    mov        rdi, 1
    call       _exit

;; Exits cleanly, checking if the listening or client sockets need to be closed
;; before calling sys_exit
_exit:
    mov        rax, [sock]
    cmp        rax, 0
    je         .client_check
    mov        rdi, [sock]
    call       _close_sock

    .client_check:
    mov        rax, [client]
    cmp        rax, 0
    je         .perform_exit
    mov        rdi, [client]
    call       _close_sock

    .perform_exit:
    mov        rax, 60
    syscall

;; Utility/QoL code

;; Writes a newline to STDOUT
;; Uses: rax, rdi, rsi, rdx
write_newline:
    mov     rax, 1        ; syscall number for SYS_WRITE
    mov     rdi, 1        ; file descriptor for STDOUT
    lea     rsi, [newline]
    mov     rdx, 1
    syscall
    ret

    call write_string

;; Writes a string to STDOUT
;; Uses: rax, rdi, rsi, rdx
;; Usage: rsi = pointer to string, rdx = length of string
write_string:
    mov     rax, 1        ; syscall number for SYS_WRITE
    mov     rdi, 1        ; file descriptor for STDOUT
    syscall
    ret
