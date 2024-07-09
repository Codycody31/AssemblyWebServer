NASM=nasm
GCC=gcc
LD=ld
CFLAGS=-nostdlib -static -m64

SRC=src
OBJ=assemblywebserver.o

all: assemblywebserver

start: assemblywebserver
	./assemblywebserver

assemblywebserver: $(OBJ)
	$(LD) $(LDFLAGS) -o $@ $^

%.o: $(SRC)/%.asm
	$(NASM) -f elf64 -o $@ $<

clean:
	rm -f $(OBJ) assemblywebserver
