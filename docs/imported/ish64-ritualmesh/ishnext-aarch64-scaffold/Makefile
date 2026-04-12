# -------- toolchain --------
CC      := cc
CFLAGS  := -std=c11 -O2 -g -Wall -Wextra -Iinclude
LDFLAGS :=

# -------- sources --------
SRC := \
  loader/elf64.c \
  loader/auxv.c \
  loader/entry.c \
  kernel/sys.c \
  kernel/sys_table.c \
  kernel/mman.c \
  kernel/fs.c \
  kernel/time_mach.c \
  kernel/signal.c \
  kernel/proc_emul.c \
  kernel/errno_linux.c \
  user/init.c

ASM := \
  loader/vdso_shim.S

OBJ := $(SRC:.c=.o) $(ASM:.S=.o)

# -------- rules --------
.PHONY: all clean
all: bin/ishnext-dev

bin/ishnext-dev: $(OBJ)
	@mkdir -p bin
	$(CC) -o $@ $(OBJ) $(LDFLAGS)

# C -> o
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# S -> o (preprocessed assembly)
%.o: %.S
	$(CC) -x assembler-with-cpp $(CFLAGS) -c $< -o $@

clean:
	rm -rf bin $(OBJ)

