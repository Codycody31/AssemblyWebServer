section .data
    filename db 'input.txt', 0  ; Filename to open
    buffer   times 4096 db 0    ; Buffer to hold file contents (4 KiB)
    length   equ $ - buffer     ; Length of the buffer

section .bss
    fd  resd 1                  ; File descriptor
    bytes_read resd 1           ; Number of bytes read

section .text
    global _start

_start:
    ; Open the file (syscall: sys_open)
    mov rax, 2                  ; syscall number for sys_open (2)
    lea rdi, [rel filename]     ; filename pointer
    mov rsi, 0                  ; O_RDONLY (read only)
    syscall                     ; Call the kernel
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

    ; Write the chunk to STDOUT (syscall: sys_write)
    mov rax, 1                  ; syscall number for sys_write (1)
    mov rdi, 1                  ; file descriptor for STDOUT
    lea rsi, [rel buffer]       ; buffer pointer
    mov rdx, [bytes_read]       ; number of bytes to write
    syscall                     ; Call the kernel

    jmp read_loop               ; Repeat the process for the next chunk

close_file:
    ; Close the file (syscall: sys_close)
    mov rax, 3                  ; syscall number for sys_close (3)
    mov rdi, [fd]               ; file descriptor
    syscall                     ; Call the kernel

    ; Exit (syscall: sys_exit)
    mov rax, 60                 ; syscall number for sys_exit (60)
    xor rdi, rdi                ; status 0
    syscall                     ; Call the kernel
