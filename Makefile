K = kernel

CROSS_COMPILE = riscv64-linux-gnu-
CC   = $(CROSS_COMPILE)gcc
LD   = $(CROSS_COMPILE)ld
OBJDUMP = $(CROSS_COMPILE)objdump

CFLAGS = -Wall -Werror -O -fno-omit-frame-pointer -ggdb -MD \
         -mcmodel=medany -ffreestanding -fno-common -nostdlib \
         -mno-relax -I.

LDFLAGS = -z max-page-size=4096

QEMU = qemu-system-riscv64
QEMUOPTS = -machine virt -bios none -kernel $K/kernel \
           -m 128M -smp 3 -nographic

OBJS = $K/entry.o $K/start.o $K/main.o $K/uart.o \
       $K/printf.o $K/console.o

$K/kernel: $(OBJS) $K/kernel.ld
	$(LD) $(LDFLAGS) -T $K/kernel.ld -o $K/kernel $(OBJS)
	$(OBJDUMP) -S $K/kernel > $K/kernel.asm
	$(OBJDUMP) -t $K/kernel | sed '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' \
	    > $K/kernel.sym

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.S
	$(CC) $(CFLAGS) -c $< -o $@

qemu: $K/kernel
	$(QEMU) $(QEMUOPTS)

qemu-gdb: $K/kernel
	$(QEMU) $(QEMUOPTS) -S -gdb tcp::26000

clean:
	rm -f *.o *.d $K/*.o $K/*.d $K/kernel $K/kernel.asm $K/kernel.sym

-include *.d $K/*.d
