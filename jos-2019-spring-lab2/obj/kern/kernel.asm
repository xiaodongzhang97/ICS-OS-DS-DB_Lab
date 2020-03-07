
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 90 11 00       	mov    $0x119000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0
	# Turn on page size extension.

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 70 11 f0       	mov    $0xf0117000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 08             	sub    $0x8,%esp
f0100047:	e8 03 01 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f010004c:	81 c3 28 a0 01 00    	add    $0x1a028,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100052:	c7 c2 80 a0 11 f0    	mov    $0xf011a080,%edx
f0100058:	c7 c0 e0 a6 11 f0    	mov    $0xf011a6e0,%eax
f010005e:	29 d0                	sub    %edx,%eax
f0100060:	50                   	push   %eax
f0100061:	6a 00                	push   $0x0
f0100063:	52                   	push   %edx
f0100064:	e8 c9 40 00 00       	call   f0104132 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100069:	e8 09 05 00 00       	call   f0100577 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006e:	83 c4 08             	add    $0x8,%esp
f0100071:	68 ac 1a 00 00       	push   $0x1aac
f0100076:	8d 83 0c a5 fe ff    	lea    -0x15af4(%ebx),%eax
f010007c:	50                   	push   %eax
f010007d:	e8 fa 31 00 00       	call   f010327c <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100082:	e8 4f 14 00 00       	call   f01014d6 <mem_init>
f0100087:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010008a:	83 ec 0c             	sub    $0xc,%esp
f010008d:	6a 00                	push   $0x0
f010008f:	e8 ef 09 00 00       	call   f0100a83 <monitor>
f0100094:	83 c4 10             	add    $0x10,%esp
f0100097:	eb f1                	jmp    f010008a <i386_init+0x4a>

f0100099 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100099:	55                   	push   %ebp
f010009a:	89 e5                	mov    %esp,%ebp
f010009c:	57                   	push   %edi
f010009d:	56                   	push   %esi
f010009e:	53                   	push   %ebx
f010009f:	83 ec 0c             	sub    $0xc,%esp
f01000a2:	e8 a8 00 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f01000a7:	81 c3 cd 9f 01 00    	add    $0x19fcd,%ebx
f01000ad:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
f01000b0:	c7 c0 e4 a6 11 f0    	mov    $0xf011a6e4,%eax
f01000b6:	83 38 00             	cmpl   $0x0,(%eax)
f01000b9:	74 0f                	je     f01000ca <_panic+0x31>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000bb:	83 ec 0c             	sub    $0xc,%esp
f01000be:	6a 00                	push   $0x0
f01000c0:	e8 be 09 00 00       	call   f0100a83 <monitor>
f01000c5:	83 c4 10             	add    $0x10,%esp
f01000c8:	eb f1                	jmp    f01000bb <_panic+0x22>
	panicstr = fmt;
f01000ca:	89 38                	mov    %edi,(%eax)
	asm volatile("cli; cld");
f01000cc:	fa                   	cli    
f01000cd:	fc                   	cld    
	va_start(ap, fmt);
f01000ce:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel panic at %s:%d: ", file, line);
f01000d1:	83 ec 04             	sub    $0x4,%esp
f01000d4:	ff 75 0c             	pushl  0xc(%ebp)
f01000d7:	ff 75 08             	pushl  0x8(%ebp)
f01000da:	8d 83 27 a5 fe ff    	lea    -0x15ad9(%ebx),%eax
f01000e0:	50                   	push   %eax
f01000e1:	e8 96 31 00 00       	call   f010327c <cprintf>
	vcprintf(fmt, ap);
f01000e6:	83 c4 08             	add    $0x8,%esp
f01000e9:	56                   	push   %esi
f01000ea:	57                   	push   %edi
f01000eb:	e8 55 31 00 00       	call   f0103245 <vcprintf>
	cprintf("\n");
f01000f0:	8d 83 c6 b4 fe ff    	lea    -0x14b3a(%ebx),%eax
f01000f6:	89 04 24             	mov    %eax,(%esp)
f01000f9:	e8 7e 31 00 00       	call   f010327c <cprintf>
f01000fe:	83 c4 10             	add    $0x10,%esp
f0100101:	eb b8                	jmp    f01000bb <_panic+0x22>

f0100103 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100103:	55                   	push   %ebp
f0100104:	89 e5                	mov    %esp,%ebp
f0100106:	56                   	push   %esi
f0100107:	53                   	push   %ebx
f0100108:	e8 42 00 00 00       	call   f010014f <__x86.get_pc_thunk.bx>
f010010d:	81 c3 67 9f 01 00    	add    $0x19f67,%ebx
	va_list ap;

	va_start(ap, fmt);
f0100113:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f0100116:	83 ec 04             	sub    $0x4,%esp
f0100119:	ff 75 0c             	pushl  0xc(%ebp)
f010011c:	ff 75 08             	pushl  0x8(%ebp)
f010011f:	8d 83 3f a5 fe ff    	lea    -0x15ac1(%ebx),%eax
f0100125:	50                   	push   %eax
f0100126:	e8 51 31 00 00       	call   f010327c <cprintf>
	vcprintf(fmt, ap);
f010012b:	83 c4 08             	add    $0x8,%esp
f010012e:	56                   	push   %esi
f010012f:	ff 75 10             	pushl  0x10(%ebp)
f0100132:	e8 0e 31 00 00       	call   f0103245 <vcprintf>
	cprintf("\n");
f0100137:	8d 83 c6 b4 fe ff    	lea    -0x14b3a(%ebx),%eax
f010013d:	89 04 24             	mov    %eax,(%esp)
f0100140:	e8 37 31 00 00       	call   f010327c <cprintf>
	va_end(ap);
}
f0100145:	83 c4 10             	add    $0x10,%esp
f0100148:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010014b:	5b                   	pop    %ebx
f010014c:	5e                   	pop    %esi
f010014d:	5d                   	pop    %ebp
f010014e:	c3                   	ret    

f010014f <__x86.get_pc_thunk.bx>:
f010014f:	8b 1c 24             	mov    (%esp),%ebx
f0100152:	c3                   	ret    

f0100153 <serial_proc_data>:

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100153:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100158:	ec                   	in     (%dx),%al
static bool serial_exists;

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100159:	a8 01                	test   $0x1,%al
f010015b:	74 0a                	je     f0100167 <serial_proc_data+0x14>
f010015d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100162:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100163:	0f b6 c0             	movzbl %al,%eax
f0100166:	c3                   	ret    
		return -1;
f0100167:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f010016c:	c3                   	ret    

f010016d <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010016d:	55                   	push   %ebp
f010016e:	89 e5                	mov    %esp,%ebp
f0100170:	56                   	push   %esi
f0100171:	53                   	push   %ebx
f0100172:	e8 d8 ff ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100177:	81 c3 fd 9e 01 00    	add    $0x19efd,%ebx
f010017d:	89 c6                	mov    %eax,%esi
	int c;

	while ((c = (*proc)()) != -1) {
f010017f:	ff d6                	call   *%esi
f0100181:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100184:	74 2a                	je     f01001b0 <cons_intr+0x43>
		if (c == 0)
f0100186:	85 c0                	test   %eax,%eax
f0100188:	74 f5                	je     f010017f <cons_intr+0x12>
			continue;
		cons.buf[cons.wpos++] = c;
f010018a:	8b 8b 30 02 00 00    	mov    0x230(%ebx),%ecx
f0100190:	8d 51 01             	lea    0x1(%ecx),%edx
f0100193:	88 84 0b 2c 00 00 00 	mov    %al,0x2c(%ebx,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f010019a:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.wpos = 0;
f01001a0:	b8 00 00 00 00       	mov    $0x0,%eax
f01001a5:	0f 44 d0             	cmove  %eax,%edx
f01001a8:	89 93 30 02 00 00    	mov    %edx,0x230(%ebx)
f01001ae:	eb cf                	jmp    f010017f <cons_intr+0x12>
	}
}
f01001b0:	5b                   	pop    %ebx
f01001b1:	5e                   	pop    %esi
f01001b2:	5d                   	pop    %ebp
f01001b3:	c3                   	ret    

f01001b4 <kbd_proc_data>:
{
f01001b4:	55                   	push   %ebp
f01001b5:	89 e5                	mov    %esp,%ebp
f01001b7:	56                   	push   %esi
f01001b8:	53                   	push   %ebx
f01001b9:	e8 91 ff ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01001be:	81 c3 b6 9e 01 00    	add    $0x19eb6,%ebx
f01001c4:	ba 64 00 00 00       	mov    $0x64,%edx
f01001c9:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f01001ca:	a8 01                	test   $0x1,%al
f01001cc:	0f 84 fb 00 00 00    	je     f01002cd <kbd_proc_data+0x119>
	if (stat & KBS_TERR)
f01001d2:	a8 20                	test   $0x20,%al
f01001d4:	0f 85 fa 00 00 00    	jne    f01002d4 <kbd_proc_data+0x120>
f01001da:	ba 60 00 00 00       	mov    $0x60,%edx
f01001df:	ec                   	in     (%dx),%al
f01001e0:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f01001e2:	3c e0                	cmp    $0xe0,%al
f01001e4:	74 64                	je     f010024a <kbd_proc_data+0x96>
	} else if (data & 0x80) {
f01001e6:	84 c0                	test   %al,%al
f01001e8:	78 75                	js     f010025f <kbd_proc_data+0xab>
	} else if (shift & E0ESC) {
f01001ea:	8b 8b 0c 00 00 00    	mov    0xc(%ebx),%ecx
f01001f0:	f6 c1 40             	test   $0x40,%cl
f01001f3:	74 0e                	je     f0100203 <kbd_proc_data+0x4f>
		data |= 0x80;
f01001f5:	83 c8 80             	or     $0xffffff80,%eax
f01001f8:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001fa:	83 e1 bf             	and    $0xffffffbf,%ecx
f01001fd:	89 8b 0c 00 00 00    	mov    %ecx,0xc(%ebx)
	shift |= shiftcode[data];
f0100203:	0f b6 d2             	movzbl %dl,%edx
f0100206:	0f b6 84 13 8c a6 fe 	movzbl -0x15974(%ebx,%edx,1),%eax
f010020d:	ff 
f010020e:	0b 83 0c 00 00 00    	or     0xc(%ebx),%eax
	shift ^= togglecode[data];
f0100214:	0f b6 8c 13 8c a5 fe 	movzbl -0x15a74(%ebx,%edx,1),%ecx
f010021b:	ff 
f010021c:	31 c8                	xor    %ecx,%eax
f010021e:	89 83 0c 00 00 00    	mov    %eax,0xc(%ebx)
	c = charcode[shift & (CTL | SHIFT)][data];
f0100224:	89 c1                	mov    %eax,%ecx
f0100226:	83 e1 03             	and    $0x3,%ecx
f0100229:	8b 8c 8b 8c ff ff ff 	mov    -0x74(%ebx,%ecx,4),%ecx
f0100230:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100234:	0f b6 f2             	movzbl %dl,%esi
	if (shift & CAPSLOCK) {
f0100237:	a8 08                	test   $0x8,%al
f0100239:	74 65                	je     f01002a0 <kbd_proc_data+0xec>
		if ('a' <= c && c <= 'z')
f010023b:	89 f2                	mov    %esi,%edx
f010023d:	8d 4e 9f             	lea    -0x61(%esi),%ecx
f0100240:	83 f9 19             	cmp    $0x19,%ecx
f0100243:	77 4f                	ja     f0100294 <kbd_proc_data+0xe0>
			c += 'A' - 'a';
f0100245:	83 ee 20             	sub    $0x20,%esi
f0100248:	eb 0c                	jmp    f0100256 <kbd_proc_data+0xa2>
		shift |= E0ESC;
f010024a:	83 8b 0c 00 00 00 40 	orl    $0x40,0xc(%ebx)
		return 0;
f0100251:	be 00 00 00 00       	mov    $0x0,%esi
}
f0100256:	89 f0                	mov    %esi,%eax
f0100258:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010025b:	5b                   	pop    %ebx
f010025c:	5e                   	pop    %esi
f010025d:	5d                   	pop    %ebp
f010025e:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f010025f:	8b 8b 0c 00 00 00    	mov    0xc(%ebx),%ecx
f0100265:	89 ce                	mov    %ecx,%esi
f0100267:	83 e6 40             	and    $0x40,%esi
f010026a:	83 e0 7f             	and    $0x7f,%eax
f010026d:	85 f6                	test   %esi,%esi
f010026f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100272:	0f b6 d2             	movzbl %dl,%edx
f0100275:	0f b6 84 13 8c a6 fe 	movzbl -0x15974(%ebx,%edx,1),%eax
f010027c:	ff 
f010027d:	83 c8 40             	or     $0x40,%eax
f0100280:	0f b6 c0             	movzbl %al,%eax
f0100283:	f7 d0                	not    %eax
f0100285:	21 c8                	and    %ecx,%eax
f0100287:	89 83 0c 00 00 00    	mov    %eax,0xc(%ebx)
		return 0;
f010028d:	be 00 00 00 00       	mov    $0x0,%esi
f0100292:	eb c2                	jmp    f0100256 <kbd_proc_data+0xa2>
		else if ('A' <= c && c <= 'Z')
f0100294:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100297:	8d 4e 20             	lea    0x20(%esi),%ecx
f010029a:	83 fa 1a             	cmp    $0x1a,%edx
f010029d:	0f 42 f1             	cmovb  %ecx,%esi
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002a0:	f7 d0                	not    %eax
f01002a2:	a8 06                	test   $0x6,%al
f01002a4:	75 b0                	jne    f0100256 <kbd_proc_data+0xa2>
f01002a6:	81 fe e9 00 00 00    	cmp    $0xe9,%esi
f01002ac:	75 a8                	jne    f0100256 <kbd_proc_data+0xa2>
		cprintf("Rebooting!\n");
f01002ae:	83 ec 0c             	sub    $0xc,%esp
f01002b1:	8d 83 59 a5 fe ff    	lea    -0x15aa7(%ebx),%eax
f01002b7:	50                   	push   %eax
f01002b8:	e8 bf 2f 00 00       	call   f010327c <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002bd:	b8 03 00 00 00       	mov    $0x3,%eax
f01002c2:	ba 92 00 00 00       	mov    $0x92,%edx
f01002c7:	ee                   	out    %al,(%dx)
f01002c8:	83 c4 10             	add    $0x10,%esp
f01002cb:	eb 89                	jmp    f0100256 <kbd_proc_data+0xa2>
		return -1;
f01002cd:	be ff ff ff ff       	mov    $0xffffffff,%esi
f01002d2:	eb 82                	jmp    f0100256 <kbd_proc_data+0xa2>
		return -1;
f01002d4:	be ff ff ff ff       	mov    $0xffffffff,%esi
f01002d9:	e9 78 ff ff ff       	jmp    f0100256 <kbd_proc_data+0xa2>

f01002de <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002de:	55                   	push   %ebp
f01002df:	89 e5                	mov    %esp,%ebp
f01002e1:	57                   	push   %edi
f01002e2:	56                   	push   %esi
f01002e3:	53                   	push   %ebx
f01002e4:	83 ec 1c             	sub    $0x1c,%esp
f01002e7:	e8 63 fe ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01002ec:	81 c3 88 9d 01 00    	add    $0x19d88,%ebx
f01002f2:	89 c7                	mov    %eax,%edi
	for (i = 0;
f01002f4:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002f9:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002fe:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100303:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100304:	a8 20                	test   $0x20,%al
f0100306:	75 13                	jne    f010031b <cons_putc+0x3d>
f0100308:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f010030e:	7f 0b                	jg     f010031b <cons_putc+0x3d>
f0100310:	89 ca                	mov    %ecx,%edx
f0100312:	ec                   	in     (%dx),%al
f0100313:	ec                   	in     (%dx),%al
f0100314:	ec                   	in     (%dx),%al
f0100315:	ec                   	in     (%dx),%al
	     i++)
f0100316:	83 c6 01             	add    $0x1,%esi
f0100319:	eb e3                	jmp    f01002fe <cons_putc+0x20>
	outb(COM1 + COM_TX, c);
f010031b:	89 f8                	mov    %edi,%eax
f010031d:	88 45 e7             	mov    %al,-0x19(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100320:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100325:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100326:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010032b:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100330:	ba 79 03 00 00       	mov    $0x379,%edx
f0100335:	ec                   	in     (%dx),%al
f0100336:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f010033c:	7f 0f                	jg     f010034d <cons_putc+0x6f>
f010033e:	84 c0                	test   %al,%al
f0100340:	78 0b                	js     f010034d <cons_putc+0x6f>
f0100342:	89 ca                	mov    %ecx,%edx
f0100344:	ec                   	in     (%dx),%al
f0100345:	ec                   	in     (%dx),%al
f0100346:	ec                   	in     (%dx),%al
f0100347:	ec                   	in     (%dx),%al
f0100348:	83 c6 01             	add    $0x1,%esi
f010034b:	eb e3                	jmp    f0100330 <cons_putc+0x52>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010034d:	ba 78 03 00 00       	mov    $0x378,%edx
f0100352:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100356:	ee                   	out    %al,(%dx)
f0100357:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010035c:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100361:	ee                   	out    %al,(%dx)
f0100362:	b8 08 00 00 00       	mov    $0x8,%eax
f0100367:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f0100368:	89 fa                	mov    %edi,%edx
f010036a:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100370:	89 f8                	mov    %edi,%eax
f0100372:	80 cc 07             	or     $0x7,%ah
f0100375:	85 d2                	test   %edx,%edx
f0100377:	0f 44 f8             	cmove  %eax,%edi
	switch (c & 0xff) {
f010037a:	89 f8                	mov    %edi,%eax
f010037c:	0f b6 c0             	movzbl %al,%eax
f010037f:	83 f8 09             	cmp    $0x9,%eax
f0100382:	0f 84 b4 00 00 00    	je     f010043c <cons_putc+0x15e>
f0100388:	7e 74                	jle    f01003fe <cons_putc+0x120>
f010038a:	83 f8 0a             	cmp    $0xa,%eax
f010038d:	0f 84 9c 00 00 00    	je     f010042f <cons_putc+0x151>
f0100393:	83 f8 0d             	cmp    $0xd,%eax
f0100396:	0f 85 d7 00 00 00    	jne    f0100473 <cons_putc+0x195>
		crt_pos -= (crt_pos % CRT_COLS);
f010039c:	0f b7 83 34 02 00 00 	movzwl 0x234(%ebx),%eax
f01003a3:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003a9:	c1 e8 16             	shr    $0x16,%eax
f01003ac:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003af:	c1 e0 04             	shl    $0x4,%eax
f01003b2:	66 89 83 34 02 00 00 	mov    %ax,0x234(%ebx)
	if (crt_pos >= CRT_SIZE) {
f01003b9:	66 81 bb 34 02 00 00 	cmpw   $0x7cf,0x234(%ebx)
f01003c0:	cf 07 
f01003c2:	0f 87 ce 00 00 00    	ja     f0100496 <cons_putc+0x1b8>
	outb(addr_6845, 14);
f01003c8:	8b 8b 3c 02 00 00    	mov    0x23c(%ebx),%ecx
f01003ce:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003d3:	89 ca                	mov    %ecx,%edx
f01003d5:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003d6:	0f b7 9b 34 02 00 00 	movzwl 0x234(%ebx),%ebx
f01003dd:	8d 71 01             	lea    0x1(%ecx),%esi
f01003e0:	89 d8                	mov    %ebx,%eax
f01003e2:	66 c1 e8 08          	shr    $0x8,%ax
f01003e6:	89 f2                	mov    %esi,%edx
f01003e8:	ee                   	out    %al,(%dx)
f01003e9:	b8 0f 00 00 00       	mov    $0xf,%eax
f01003ee:	89 ca                	mov    %ecx,%edx
f01003f0:	ee                   	out    %al,(%dx)
f01003f1:	89 d8                	mov    %ebx,%eax
f01003f3:	89 f2                	mov    %esi,%edx
f01003f5:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01003f6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01003f9:	5b                   	pop    %ebx
f01003fa:	5e                   	pop    %esi
f01003fb:	5f                   	pop    %edi
f01003fc:	5d                   	pop    %ebp
f01003fd:	c3                   	ret    
f01003fe:	83 f8 08             	cmp    $0x8,%eax
f0100401:	75 70                	jne    f0100473 <cons_putc+0x195>
		if (crt_pos > 0) {
f0100403:	0f b7 83 34 02 00 00 	movzwl 0x234(%ebx),%eax
f010040a:	66 85 c0             	test   %ax,%ax
f010040d:	74 b9                	je     f01003c8 <cons_putc+0xea>
			crt_pos--;
f010040f:	83 e8 01             	sub    $0x1,%eax
f0100412:	66 89 83 34 02 00 00 	mov    %ax,0x234(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100419:	0f b7 c0             	movzwl %ax,%eax
f010041c:	89 fa                	mov    %edi,%edx
f010041e:	b2 00                	mov    $0x0,%dl
f0100420:	83 ca 20             	or     $0x20,%edx
f0100423:	8b 8b 38 02 00 00    	mov    0x238(%ebx),%ecx
f0100429:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f010042d:	eb 8a                	jmp    f01003b9 <cons_putc+0xdb>
		crt_pos += CRT_COLS;
f010042f:	66 83 83 34 02 00 00 	addw   $0x50,0x234(%ebx)
f0100436:	50 
f0100437:	e9 60 ff ff ff       	jmp    f010039c <cons_putc+0xbe>
		cons_putc(' ');
f010043c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100441:	e8 98 fe ff ff       	call   f01002de <cons_putc>
		cons_putc(' ');
f0100446:	b8 20 00 00 00       	mov    $0x20,%eax
f010044b:	e8 8e fe ff ff       	call   f01002de <cons_putc>
		cons_putc(' ');
f0100450:	b8 20 00 00 00       	mov    $0x20,%eax
f0100455:	e8 84 fe ff ff       	call   f01002de <cons_putc>
		cons_putc(' ');
f010045a:	b8 20 00 00 00       	mov    $0x20,%eax
f010045f:	e8 7a fe ff ff       	call   f01002de <cons_putc>
		cons_putc(' ');
f0100464:	b8 20 00 00 00       	mov    $0x20,%eax
f0100469:	e8 70 fe ff ff       	call   f01002de <cons_putc>
f010046e:	e9 46 ff ff ff       	jmp    f01003b9 <cons_putc+0xdb>
		crt_buf[crt_pos++] = c;		/* write the character */
f0100473:	0f b7 83 34 02 00 00 	movzwl 0x234(%ebx),%eax
f010047a:	8d 50 01             	lea    0x1(%eax),%edx
f010047d:	66 89 93 34 02 00 00 	mov    %dx,0x234(%ebx)
f0100484:	0f b7 c0             	movzwl %ax,%eax
f0100487:	8b 93 38 02 00 00    	mov    0x238(%ebx),%edx
f010048d:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100491:	e9 23 ff ff ff       	jmp    f01003b9 <cons_putc+0xdb>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100496:	8b 83 38 02 00 00    	mov    0x238(%ebx),%eax
f010049c:	83 ec 04             	sub    $0x4,%esp
f010049f:	68 00 0f 00 00       	push   $0xf00
f01004a4:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004aa:	52                   	push   %edx
f01004ab:	50                   	push   %eax
f01004ac:	e8 c9 3c 00 00       	call   f010417a <memmove>
			crt_buf[i] = 0x0700 | ' ';
f01004b1:	8b 93 38 02 00 00    	mov    0x238(%ebx),%edx
f01004b7:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01004bd:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01004c3:	83 c4 10             	add    $0x10,%esp
f01004c6:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01004cb:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004ce:	39 d0                	cmp    %edx,%eax
f01004d0:	75 f4                	jne    f01004c6 <cons_putc+0x1e8>
		crt_pos -= CRT_COLS;
f01004d2:	66 83 ab 34 02 00 00 	subw   $0x50,0x234(%ebx)
f01004d9:	50 
f01004da:	e9 e9 fe ff ff       	jmp    f01003c8 <cons_putc+0xea>

f01004df <serial_intr>:
{
f01004df:	e8 dc 01 00 00       	call   f01006c0 <__x86.get_pc_thunk.ax>
f01004e4:	05 90 9b 01 00       	add    $0x19b90,%eax
	if (serial_exists)
f01004e9:	80 b8 40 02 00 00 00 	cmpb   $0x0,0x240(%eax)
f01004f0:	75 01                	jne    f01004f3 <serial_intr+0x14>
f01004f2:	c3                   	ret    
{
f01004f3:	55                   	push   %ebp
f01004f4:	89 e5                	mov    %esp,%ebp
f01004f6:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f01004f9:	8d 80 df 60 fe ff    	lea    -0x19f21(%eax),%eax
f01004ff:	e8 69 fc ff ff       	call   f010016d <cons_intr>
}
f0100504:	c9                   	leave  
f0100505:	c3                   	ret    

f0100506 <kbd_intr>:
{
f0100506:	55                   	push   %ebp
f0100507:	89 e5                	mov    %esp,%ebp
f0100509:	83 ec 08             	sub    $0x8,%esp
f010050c:	e8 af 01 00 00       	call   f01006c0 <__x86.get_pc_thunk.ax>
f0100511:	05 63 9b 01 00       	add    $0x19b63,%eax
	cons_intr(kbd_proc_data);
f0100516:	8d 80 40 61 fe ff    	lea    -0x19ec0(%eax),%eax
f010051c:	e8 4c fc ff ff       	call   f010016d <cons_intr>
}
f0100521:	c9                   	leave  
f0100522:	c3                   	ret    

f0100523 <cons_getc>:
{
f0100523:	55                   	push   %ebp
f0100524:	89 e5                	mov    %esp,%ebp
f0100526:	53                   	push   %ebx
f0100527:	83 ec 04             	sub    $0x4,%esp
f010052a:	e8 20 fc ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010052f:	81 c3 45 9b 01 00    	add    $0x19b45,%ebx
	serial_intr();
f0100535:	e8 a5 ff ff ff       	call   f01004df <serial_intr>
	kbd_intr();
f010053a:	e8 c7 ff ff ff       	call   f0100506 <kbd_intr>
	if (cons.rpos != cons.wpos) {
f010053f:	8b 8b 2c 02 00 00    	mov    0x22c(%ebx),%ecx
	return 0;
f0100545:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f010054a:	3b 8b 30 02 00 00    	cmp    0x230(%ebx),%ecx
f0100550:	74 1f                	je     f0100571 <cons_getc+0x4e>
		c = cons.buf[cons.rpos++];
f0100552:	8d 51 01             	lea    0x1(%ecx),%edx
f0100555:	0f b6 84 0b 2c 00 00 	movzbl 0x2c(%ebx,%ecx,1),%eax
f010055c:	00 
		if (cons.rpos == CONSBUFSIZE)
f010055d:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.rpos = 0;
f0100563:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100568:	0f 44 d1             	cmove  %ecx,%edx
f010056b:	89 93 2c 02 00 00    	mov    %edx,0x22c(%ebx)
}
f0100571:	83 c4 04             	add    $0x4,%esp
f0100574:	5b                   	pop    %ebx
f0100575:	5d                   	pop    %ebp
f0100576:	c3                   	ret    

f0100577 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f0100577:	55                   	push   %ebp
f0100578:	89 e5                	mov    %esp,%ebp
f010057a:	57                   	push   %edi
f010057b:	56                   	push   %esi
f010057c:	53                   	push   %ebx
f010057d:	83 ec 1c             	sub    $0x1c,%esp
f0100580:	e8 ca fb ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100585:	81 c3 ef 9a 01 00    	add    $0x19aef,%ebx
	was = *cp;
f010058b:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100592:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100599:	5a a5 
	if (*cp != 0xA55A) {
f010059b:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01005a2:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01005a6:	0f 84 bc 00 00 00    	je     f0100668 <cons_init+0xf1>
		addr_6845 = MONO_BASE;
f01005ac:	c7 83 3c 02 00 00 b4 	movl   $0x3b4,0x23c(%ebx)
f01005b3:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01005b6:	c7 45 e4 00 00 0b f0 	movl   $0xf00b0000,-0x1c(%ebp)
	outb(addr_6845, 14);
f01005bd:	8b bb 3c 02 00 00    	mov    0x23c(%ebx),%edi
f01005c3:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005c8:	89 fa                	mov    %edi,%edx
f01005ca:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005cb:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005ce:	89 ca                	mov    %ecx,%edx
f01005d0:	ec                   	in     (%dx),%al
f01005d1:	0f b6 f0             	movzbl %al,%esi
f01005d4:	c1 e6 08             	shl    $0x8,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005d7:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005dc:	89 fa                	mov    %edi,%edx
f01005de:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005df:	89 ca                	mov    %ecx,%edx
f01005e1:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f01005e2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01005e5:	89 bb 38 02 00 00    	mov    %edi,0x238(%ebx)
	pos |= inb(addr_6845 + 1);
f01005eb:	0f b6 c0             	movzbl %al,%eax
f01005ee:	09 c6                	or     %eax,%esi
	crt_pos = pos;
f01005f0:	66 89 b3 34 02 00 00 	mov    %si,0x234(%ebx)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005f7:	b9 00 00 00 00       	mov    $0x0,%ecx
f01005fc:	89 c8                	mov    %ecx,%eax
f01005fe:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100603:	ee                   	out    %al,(%dx)
f0100604:	bf fb 03 00 00       	mov    $0x3fb,%edi
f0100609:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f010060e:	89 fa                	mov    %edi,%edx
f0100610:	ee                   	out    %al,(%dx)
f0100611:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100616:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010061b:	ee                   	out    %al,(%dx)
f010061c:	be f9 03 00 00       	mov    $0x3f9,%esi
f0100621:	89 c8                	mov    %ecx,%eax
f0100623:	89 f2                	mov    %esi,%edx
f0100625:	ee                   	out    %al,(%dx)
f0100626:	b8 03 00 00 00       	mov    $0x3,%eax
f010062b:	89 fa                	mov    %edi,%edx
f010062d:	ee                   	out    %al,(%dx)
f010062e:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100633:	89 c8                	mov    %ecx,%eax
f0100635:	ee                   	out    %al,(%dx)
f0100636:	b8 01 00 00 00       	mov    $0x1,%eax
f010063b:	89 f2                	mov    %esi,%edx
f010063d:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010063e:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100643:	ec                   	in     (%dx),%al
f0100644:	89 c1                	mov    %eax,%ecx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100646:	3c ff                	cmp    $0xff,%al
f0100648:	0f 95 83 40 02 00 00 	setne  0x240(%ebx)
f010064f:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100654:	ec                   	in     (%dx),%al
f0100655:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010065a:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010065b:	80 f9 ff             	cmp    $0xff,%cl
f010065e:	74 25                	je     f0100685 <cons_init+0x10e>
		cprintf("Serial port does not exist!\n");
}
f0100660:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100663:	5b                   	pop    %ebx
f0100664:	5e                   	pop    %esi
f0100665:	5f                   	pop    %edi
f0100666:	5d                   	pop    %ebp
f0100667:	c3                   	ret    
		*cp = was;
f0100668:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010066f:	c7 83 3c 02 00 00 d4 	movl   $0x3d4,0x23c(%ebx)
f0100676:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100679:	c7 45 e4 00 80 0b f0 	movl   $0xf00b8000,-0x1c(%ebp)
f0100680:	e9 38 ff ff ff       	jmp    f01005bd <cons_init+0x46>
		cprintf("Serial port does not exist!\n");
f0100685:	83 ec 0c             	sub    $0xc,%esp
f0100688:	8d 83 65 a5 fe ff    	lea    -0x15a9b(%ebx),%eax
f010068e:	50                   	push   %eax
f010068f:	e8 e8 2b 00 00       	call   f010327c <cprintf>
f0100694:	83 c4 10             	add    $0x10,%esp
}
f0100697:	eb c7                	jmp    f0100660 <cons_init+0xe9>

f0100699 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100699:	55                   	push   %ebp
f010069a:	89 e5                	mov    %esp,%ebp
f010069c:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010069f:	8b 45 08             	mov    0x8(%ebp),%eax
f01006a2:	e8 37 fc ff ff       	call   f01002de <cons_putc>
}
f01006a7:	c9                   	leave  
f01006a8:	c3                   	ret    

f01006a9 <getchar>:

int
getchar(void)
{
f01006a9:	55                   	push   %ebp
f01006aa:	89 e5                	mov    %esp,%ebp
f01006ac:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01006af:	e8 6f fe ff ff       	call   f0100523 <cons_getc>
f01006b4:	85 c0                	test   %eax,%eax
f01006b6:	74 f7                	je     f01006af <getchar+0x6>
		/* do nothing */;
	return c;
}
f01006b8:	c9                   	leave  
f01006b9:	c3                   	ret    

f01006ba <iscons>:
int
iscons(int fdnum)
{
	// used by readline
	return 1;
}
f01006ba:	b8 01 00 00 00       	mov    $0x1,%eax
f01006bf:	c3                   	ret    

f01006c0 <__x86.get_pc_thunk.ax>:
f01006c0:	8b 04 24             	mov    (%esp),%eax
f01006c3:	c3                   	ret    

f01006c4 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006c4:	55                   	push   %ebp
f01006c5:	89 e5                	mov    %esp,%ebp
f01006c7:	56                   	push   %esi
f01006c8:	53                   	push   %ebx
f01006c9:	e8 81 fa ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01006ce:	81 c3 a6 99 01 00    	add    $0x199a6,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006d4:	83 ec 04             	sub    $0x4,%esp
f01006d7:	8d 83 8c a7 fe ff    	lea    -0x15874(%ebx),%eax
f01006dd:	50                   	push   %eax
f01006de:	8d 83 aa a7 fe ff    	lea    -0x15856(%ebx),%eax
f01006e4:	50                   	push   %eax
f01006e5:	8d b3 af a7 fe ff    	lea    -0x15851(%ebx),%esi
f01006eb:	56                   	push   %esi
f01006ec:	e8 8b 2b 00 00       	call   f010327c <cprintf>
f01006f1:	83 c4 0c             	add    $0xc,%esp
f01006f4:	8d 83 84 a8 fe ff    	lea    -0x1577c(%ebx),%eax
f01006fa:	50                   	push   %eax
f01006fb:	8d 83 b8 a7 fe ff    	lea    -0x15848(%ebx),%eax
f0100701:	50                   	push   %eax
f0100702:	56                   	push   %esi
f0100703:	e8 74 2b 00 00       	call   f010327c <cprintf>
f0100708:	83 c4 0c             	add    $0xc,%esp
f010070b:	8d 83 ac a8 fe ff    	lea    -0x15754(%ebx),%eax
f0100711:	50                   	push   %eax
f0100712:	8d 83 c1 a7 fe ff    	lea    -0x1583f(%ebx),%eax
f0100718:	50                   	push   %eax
f0100719:	56                   	push   %esi
f010071a:	e8 5d 2b 00 00       	call   f010327c <cprintf>
f010071f:	83 c4 0c             	add    $0xc,%esp
f0100722:	8d 83 d4 a8 fe ff    	lea    -0x1572c(%ebx),%eax
f0100728:	50                   	push   %eax
f0100729:	8d 83 cb a7 fe ff    	lea    -0x15835(%ebx),%eax
f010072f:	50                   	push   %eax
f0100730:	56                   	push   %esi
f0100731:	e8 46 2b 00 00       	call   f010327c <cprintf>
	return 0;
}
f0100736:	b8 00 00 00 00       	mov    $0x0,%eax
f010073b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010073e:	5b                   	pop    %ebx
f010073f:	5e                   	pop    %esi
f0100740:	5d                   	pop    %ebp
f0100741:	c3                   	ret    

f0100742 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100742:	55                   	push   %ebp
f0100743:	89 e5                	mov    %esp,%ebp
f0100745:	57                   	push   %edi
f0100746:	56                   	push   %esi
f0100747:	53                   	push   %ebx
f0100748:	83 ec 18             	sub    $0x18,%esp
f010074b:	e8 ff f9 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100750:	81 c3 24 99 01 00    	add    $0x19924,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100756:	8d 83 d0 a7 fe ff    	lea    -0x15830(%ebx),%eax
f010075c:	50                   	push   %eax
f010075d:	e8 1a 2b 00 00       	call   f010327c <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100762:	83 c4 08             	add    $0x8,%esp
f0100765:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f010076b:	8d 83 f8 a8 fe ff    	lea    -0x15708(%ebx),%eax
f0100771:	50                   	push   %eax
f0100772:	e8 05 2b 00 00       	call   f010327c <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100777:	83 c4 0c             	add    $0xc,%esp
f010077a:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f0100780:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f0100786:	50                   	push   %eax
f0100787:	57                   	push   %edi
f0100788:	8d 83 20 a9 fe ff    	lea    -0x156e0(%ebx),%eax
f010078e:	50                   	push   %eax
f010078f:	e8 e8 2a 00 00       	call   f010327c <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100794:	83 c4 0c             	add    $0xc,%esp
f0100797:	c7 c0 7f 45 10 f0    	mov    $0xf010457f,%eax
f010079d:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007a3:	52                   	push   %edx
f01007a4:	50                   	push   %eax
f01007a5:	8d 83 44 a9 fe ff    	lea    -0x156bc(%ebx),%eax
f01007ab:	50                   	push   %eax
f01007ac:	e8 cb 2a 00 00       	call   f010327c <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007b1:	83 c4 0c             	add    $0xc,%esp
f01007b4:	c7 c0 80 a0 11 f0    	mov    $0xf011a080,%eax
f01007ba:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007c0:	52                   	push   %edx
f01007c1:	50                   	push   %eax
f01007c2:	8d 83 68 a9 fe ff    	lea    -0x15698(%ebx),%eax
f01007c8:	50                   	push   %eax
f01007c9:	e8 ae 2a 00 00       	call   f010327c <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007ce:	83 c4 0c             	add    $0xc,%esp
f01007d1:	c7 c6 e0 a6 11 f0    	mov    $0xf011a6e0,%esi
f01007d7:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f01007dd:	50                   	push   %eax
f01007de:	56                   	push   %esi
f01007df:	8d 83 8c a9 fe ff    	lea    -0x15674(%ebx),%eax
f01007e5:	50                   	push   %eax
f01007e6:	e8 91 2a 00 00       	call   f010327c <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007eb:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f01007ee:	29 fe                	sub    %edi,%esi
f01007f0:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f01007f6:	c1 fe 0a             	sar    $0xa,%esi
f01007f9:	56                   	push   %esi
f01007fa:	8d 83 b0 a9 fe ff    	lea    -0x15650(%ebx),%eax
f0100800:	50                   	push   %eax
f0100801:	e8 76 2a 00 00       	call   f010327c <cprintf>
	return 0;
}
f0100806:	b8 00 00 00 00       	mov    $0x0,%eax
f010080b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010080e:	5b                   	pop    %ebx
f010080f:	5e                   	pop    %esi
f0100810:	5f                   	pop    %edi
f0100811:	5d                   	pop    %ebp
f0100812:	c3                   	ret    

f0100813 <do_overflow>:
    return pretaddr;
}

void
do_overflow(void)
{
f0100813:	55                   	push   %ebp
f0100814:	89 e5                	mov    %esp,%ebp
f0100816:	53                   	push   %ebx
f0100817:	83 ec 10             	sub    $0x10,%esp
f010081a:	e8 30 f9 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010081f:	81 c3 55 98 01 00    	add    $0x19855,%ebx
    cprintf("Overflow success\n");
f0100825:	8d 83 e9 a7 fe ff    	lea    -0x15817(%ebx),%eax
f010082b:	50                   	push   %eax
f010082c:	e8 4b 2a 00 00       	call   f010327c <cprintf>
}
f0100831:	83 c4 10             	add    $0x10,%esp
f0100834:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100837:	c9                   	leave  
f0100838:	c3                   	ret    

f0100839 <mon_time>:
        return (uint64_t)hi<<32 | lo;
}

int
mon_time(int argc, char **argv, struct Trapframe *tf)
{
f0100839:	55                   	push   %ebp
f010083a:	89 e5                	mov    %esp,%ebp
f010083c:	57                   	push   %edi
f010083d:	56                   	push   %esi
f010083e:	53                   	push   %ebx
f010083f:	83 ec 2c             	sub    $0x2c,%esp
f0100842:	e8 08 f9 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100847:	81 c3 2d 98 01 00    	add    $0x1982d,%ebx
f010084d:	8b 45 0c             	mov    0xc(%ebp),%eax
	uint64_t begin = 0, end = 1;
	int res = -1;
	char *targetcmd = argv[1];
f0100850:	8b 78 04             	mov    0x4(%eax),%edi
f0100853:	8d b3 ac ff ff ff    	lea    -0x54(%ebx),%esi
f0100859:	8d 4e 30             	lea    0x30(%esi),%ecx
f010085c:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	int res = -1;
f010085f:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
	uint64_t begin = 0, end = 1;
f0100866:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
f010086d:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
f0100874:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f010087b:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	for (int i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(targetcmd, commands[i].name) == 0) {
			begin = rdtsc();
			res = commands[i].func(argc-1, argv+1, tf);
f0100882:	83 c0 04             	add    $0x4,%eax
f0100885:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100888:	8b 45 08             	mov    0x8(%ebp),%eax
f010088b:	83 e8 01             	sub    $0x1,%eax
f010088e:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100891:	eb 2d                	jmp    f01008c0 <mon_time+0x87>
        __asm__ __volatile__("rdtsc":"=a"(lo),"=d"(hi));
f0100893:	0f 31                	rdtsc  
        return (uint64_t)hi<<32 | lo;
f0100895:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100898:	89 55 dc             	mov    %edx,-0x24(%ebp)
			res = commands[i].func(argc-1, argv+1, tf);
f010089b:	83 ec 04             	sub    $0x4,%esp
f010089e:	ff 75 10             	pushl  0x10(%ebp)
f01008a1:	ff 75 cc             	pushl  -0x34(%ebp)
f01008a4:	ff 75 c8             	pushl  -0x38(%ebp)
f01008a7:	ff 56 08             	call   *0x8(%esi)
f01008aa:	89 45 e0             	mov    %eax,-0x20(%ebp)
        __asm__ __volatile__("rdtsc":"=a"(lo),"=d"(hi));
f01008ad:	0f 31                	rdtsc  
        return (uint64_t)hi<<32 | lo;
f01008af:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01008b2:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f01008b5:	83 c4 10             	add    $0x10,%esp
f01008b8:	83 c6 0c             	add    $0xc,%esi
	for (int i = 0; i < ARRAY_SIZE(commands); i++) {
f01008bb:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f01008be:	74 14                	je     f01008d4 <mon_time+0x9b>
		if (strcmp(targetcmd, commands[i].name) == 0) {
f01008c0:	83 ec 08             	sub    $0x8,%esp
f01008c3:	ff 36                	pushl  (%esi)
f01008c5:	57                   	push   %edi
f01008c6:	e8 cc 37 00 00       	call   f0104097 <strcmp>
f01008cb:	83 c4 10             	add    $0x10,%esp
f01008ce:	85 c0                	test   %eax,%eax
f01008d0:	75 e6                	jne    f01008b8 <mon_time+0x7f>
f01008d2:	eb bf                	jmp    f0100893 <mon_time+0x5a>
			end = rdtsc();
		}
	}
	if (res < 0)
f01008d4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01008d8:	78 29                	js     f0100903 <mon_time+0xca>
		cprintf("Unknown command '%s'\n", targetcmd);
	else
		cprintf("%s cycles: %llu\n", targetcmd, end - begin);
f01008da:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01008dd:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01008e0:	2b 45 d8             	sub    -0x28(%ebp),%eax
f01008e3:	1b 55 dc             	sbb    -0x24(%ebp),%edx
f01008e6:	52                   	push   %edx
f01008e7:	50                   	push   %eax
f01008e8:	57                   	push   %edi
f01008e9:	8d 83 11 a8 fe ff    	lea    -0x157ef(%ebx),%eax
f01008ef:	50                   	push   %eax
f01008f0:	e8 87 29 00 00       	call   f010327c <cprintf>
f01008f5:	83 c4 10             	add    $0x10,%esp

	return res;
}
f01008f8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01008fb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008fe:	5b                   	pop    %ebx
f01008ff:	5e                   	pop    %esi
f0100900:	5f                   	pop    %edi
f0100901:	5d                   	pop    %ebp
f0100902:	c3                   	ret    
		cprintf("Unknown command '%s'\n", targetcmd);
f0100903:	83 ec 08             	sub    $0x8,%esp
f0100906:	57                   	push   %edi
f0100907:	8d 83 fb a7 fe ff    	lea    -0x15805(%ebx),%eax
f010090d:	50                   	push   %eax
f010090e:	e8 69 29 00 00       	call   f010327c <cprintf>
f0100913:	83 c4 10             	add    $0x10,%esp
f0100916:	eb e0                	jmp    f01008f8 <mon_time+0xbf>

f0100918 <start_overflow>:
{
f0100918:	55                   	push   %ebp
f0100919:	89 e5                	mov    %esp,%ebp
f010091b:	57                   	push   %edi
f010091c:	56                   	push   %esi
f010091d:	53                   	push   %ebx
f010091e:	83 ec 1c             	sub    $0x1c,%esp
f0100921:	e8 29 f8 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100926:	81 c3 4e 97 01 00    	add    $0x1974e,%ebx
    __asm __volatile("leal 4(%%ebp), %0" : "=r" (pretaddr)); 
f010092c:	8d 75 04             	lea    0x4(%ebp),%esi
f010092f:	89 75 e0             	mov    %esi,-0x20(%ebp)
	target_addr = (uint32_t)do_overflow;	
f0100932:	8d 83 9f 67 fe ff    	lea    -0x19861(%ebx),%eax
f0100938:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010093b:	8d 46 04             	lea    0x4(%esi),%eax
f010093e:	89 45 dc             	mov    %eax,-0x24(%ebp)
    	cprintf("%*s%n\n", pret_addr[i] & 0xFF, "", pret_addr + 4 + i);
f0100941:	8d bb c7 b4 fe ff    	lea    -0x14b39(%ebx),%edi
f0100947:	8d 83 22 a8 fe ff    	lea    -0x157de(%ebx),%eax
f010094d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100950:	8d 46 04             	lea    0x4(%esi),%eax
f0100953:	50                   	push   %eax
f0100954:	57                   	push   %edi
f0100955:	0f b6 06             	movzbl (%esi),%eax
f0100958:	50                   	push   %eax
f0100959:	ff 75 d8             	pushl  -0x28(%ebp)
f010095c:	e8 1b 29 00 00       	call   f010327c <cprintf>
f0100961:	83 c6 01             	add    $0x1,%esi
	for (int i = 0; i < 4; i++){
f0100964:	83 c4 10             	add    $0x10,%esp
f0100967:	3b 75 dc             	cmp    -0x24(%ebp),%esi
f010096a:	75 e4                	jne    f0100950 <start_overflow+0x38>
	for (int i = 0; i < 4; i++){
f010096c:	be 00 00 00 00       	mov    $0x0,%esi
		cprintf("%*s%n\n", (target_addr >> (8*i)) & 0xFF, "", pret_addr + i);
f0100971:	8d bb c7 b4 fe ff    	lea    -0x14b39(%ebx),%edi
f0100977:	8d 83 22 a8 fe ff    	lea    -0x157de(%ebx),%eax
f010097d:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100980:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100983:	01 f0                	add    %esi,%eax
f0100985:	50                   	push   %eax
f0100986:	57                   	push   %edi
f0100987:	8d 0c f5 00 00 00 00 	lea    0x0(,%esi,8),%ecx
f010098e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100991:	d3 e8                	shr    %cl,%eax
f0100993:	0f b6 c0             	movzbl %al,%eax
f0100996:	50                   	push   %eax
f0100997:	ff 75 dc             	pushl  -0x24(%ebp)
f010099a:	e8 dd 28 00 00       	call   f010327c <cprintf>
	for (int i = 0; i < 4; i++){
f010099f:	83 c6 01             	add    $0x1,%esi
f01009a2:	83 c4 10             	add    $0x10,%esp
f01009a5:	83 fe 04             	cmp    $0x4,%esi
f01009a8:	75 d6                	jne    f0100980 <start_overflow+0x68>
}
f01009aa:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01009ad:	5b                   	pop    %ebx
f01009ae:	5e                   	pop    %esi
f01009af:	5f                   	pop    %edi
f01009b0:	5d                   	pop    %ebp
f01009b1:	c3                   	ret    

f01009b2 <mon_backtrace>:
{
f01009b2:	55                   	push   %ebp
f01009b3:	89 e5                	mov    %esp,%ebp
f01009b5:	57                   	push   %edi
f01009b6:	56                   	push   %esi
f01009b7:	53                   	push   %ebx
f01009b8:	83 ec 4c             	sub    $0x4c,%esp
f01009bb:	e8 8f f7 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01009c0:	81 c3 b4 96 01 00    	add    $0x196b4,%ebx
        start_overflow();
f01009c6:	e8 4d ff ff ff       	call   f0100918 <start_overflow>
    cprintf("Stack backtrace:\n");
f01009cb:	83 ec 0c             	sub    $0xc,%esp
f01009ce:	8d 83 29 a8 fe ff    	lea    -0x157d7(%ebx),%eax
f01009d4:	50                   	push   %eax
f01009d5:	e8 a2 28 00 00       	call   f010327c <cprintf>

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f01009da:	89 ee                	mov    %ebp,%esi
    while((uint32_t)ebp != 0){
f01009dc:	83 c4 10             	add    $0x10,%esp
    	cprintf("  eip %x ebp %x args %08x %08x %08x %08x %08x\n", eip, ebp, args[0], args[1], args[2], args[3], args[4]);
f01009df:	8d 83 dc a9 fe ff    	lea    -0x15624(%ebx),%eax
f01009e5:	89 45 b4             	mov    %eax,-0x4c(%ebp)
    	debuginfo_eip(eip, &info);
f01009e8:	8d 45 bc             	lea    -0x44(%ebp),%eax
f01009eb:	89 45 b0             	mov    %eax,-0x50(%ebp)
    while((uint32_t)ebp != 0){
f01009ee:	eb 49                	jmp    f0100a39 <mon_backtrace+0x87>
    	cprintf("  eip %x ebp %x args %08x %08x %08x %08x %08x\n", eip, ebp, args[0], args[1], args[2], args[3], args[4]);
f01009f0:	ff 75 e4             	pushl  -0x1c(%ebp)
f01009f3:	ff 75 e0             	pushl  -0x20(%ebp)
f01009f6:	ff 75 dc             	pushl  -0x24(%ebp)
f01009f9:	ff 75 d8             	pushl  -0x28(%ebp)
f01009fc:	ff 75 d4             	pushl  -0x2c(%ebp)
f01009ff:	56                   	push   %esi
f0100a00:	57                   	push   %edi
f0100a01:	ff 75 b4             	pushl  -0x4c(%ebp)
f0100a04:	e8 73 28 00 00       	call   f010327c <cprintf>
    	debuginfo_eip(eip, &info);
f0100a09:	83 c4 18             	add    $0x18,%esp
f0100a0c:	ff 75 b0             	pushl  -0x50(%ebp)
f0100a0f:	57                   	push   %edi
f0100a10:	e8 6b 29 00 00       	call   f0103380 <debuginfo_eip>
    	cprintf("\t%s:%d %.*s+%x\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, (uint32_t)eip - (uint32_t)info.eip_fn_addr);
f0100a15:	83 c4 08             	add    $0x8,%esp
f0100a18:	2b 7d cc             	sub    -0x34(%ebp),%edi
f0100a1b:	57                   	push   %edi
f0100a1c:	ff 75 c4             	pushl  -0x3c(%ebp)
f0100a1f:	ff 75 c8             	pushl  -0x38(%ebp)
f0100a22:	ff 75 c0             	pushl  -0x40(%ebp)
f0100a25:	ff 75 bc             	pushl  -0x44(%ebp)
f0100a28:	8d 83 3b a8 fe ff    	lea    -0x157c5(%ebx),%eax
f0100a2e:	50                   	push   %eax
f0100a2f:	e8 48 28 00 00       	call   f010327c <cprintf>
    	ebp = (uint32_t *)ebp[0];
f0100a34:	8b 36                	mov    (%esi),%esi
f0100a36:	83 c4 20             	add    $0x20,%esp
    while((uint32_t)ebp != 0){
f0100a39:	85 f6                	test   %esi,%esi
f0100a3b:	74 1a                	je     f0100a57 <mon_backtrace+0xa5>
    	eip = ebp[1];
f0100a3d:	8b 7e 04             	mov    0x4(%esi),%edi
    	for(int i=0; i<5; i++){
f0100a40:	b8 00 00 00 00       	mov    $0x0,%eax
    		args[i] = ebp[i+2];
f0100a45:	8b 54 86 08          	mov    0x8(%esi,%eax,4),%edx
f0100a49:	89 54 85 d4          	mov    %edx,-0x2c(%ebp,%eax,4)
    	for(int i=0; i<5; i++){
f0100a4d:	83 c0 01             	add    $0x1,%eax
f0100a50:	83 f8 05             	cmp    $0x5,%eax
f0100a53:	75 f0                	jne    f0100a45 <mon_backtrace+0x93>
f0100a55:	eb 99                	jmp    f01009f0 <mon_backtrace+0x3e>
    cprintf("Backtrace success\n");
f0100a57:	83 ec 0c             	sub    $0xc,%esp
f0100a5a:	8d 83 4b a8 fe ff    	lea    -0x157b5(%ebx),%eax
f0100a60:	50                   	push   %eax
f0100a61:	e8 16 28 00 00       	call   f010327c <cprintf>
}
f0100a66:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a6b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a6e:	5b                   	pop    %ebx
f0100a6f:	5e                   	pop    %esi
f0100a70:	5f                   	pop    %edi
f0100a71:	5d                   	pop    %ebp
f0100a72:	c3                   	ret    

f0100a73 <overflow_me>:
{
f0100a73:	55                   	push   %ebp
f0100a74:	89 e5                	mov    %esp,%ebp
f0100a76:	83 ec 08             	sub    $0x8,%esp
        start_overflow();
f0100a79:	e8 9a fe ff ff       	call   f0100918 <start_overflow>
}
f0100a7e:	c9                   	leave  
f0100a7f:	c3                   	ret    

f0100a80 <rdtsc>:
        __asm__ __volatile__("rdtsc":"=a"(lo),"=d"(hi));
f0100a80:	0f 31                	rdtsc  
}
f0100a82:	c3                   	ret    

f0100a83 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100a83:	55                   	push   %ebp
f0100a84:	89 e5                	mov    %esp,%ebp
f0100a86:	57                   	push   %edi
f0100a87:	56                   	push   %esi
f0100a88:	53                   	push   %ebx
f0100a89:	83 ec 68             	sub    $0x68,%esp
f0100a8c:	e8 be f6 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100a91:	81 c3 e3 95 01 00    	add    $0x195e3,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100a97:	8d 83 0c aa fe ff    	lea    -0x155f4(%ebx),%eax
f0100a9d:	50                   	push   %eax
f0100a9e:	e8 d9 27 00 00       	call   f010327c <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100aa3:	8d 83 30 aa fe ff    	lea    -0x155d0(%ebx),%eax
f0100aa9:	89 04 24             	mov    %eax,(%esp)
f0100aac:	e8 cb 27 00 00       	call   f010327c <cprintf>
f0100ab1:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100ab4:	8d 83 62 a8 fe ff    	lea    -0x1579e(%ebx),%eax
f0100aba:	89 45 a0             	mov    %eax,-0x60(%ebp)
f0100abd:	e9 d1 00 00 00       	jmp    f0100b93 <monitor+0x110>
f0100ac2:	83 ec 08             	sub    $0x8,%esp
f0100ac5:	0f be c0             	movsbl %al,%eax
f0100ac8:	50                   	push   %eax
f0100ac9:	ff 75 a0             	pushl  -0x60(%ebp)
f0100acc:	e8 24 36 00 00       	call   f01040f5 <strchr>
f0100ad1:	83 c4 10             	add    $0x10,%esp
f0100ad4:	85 c0                	test   %eax,%eax
f0100ad6:	74 6d                	je     f0100b45 <monitor+0xc2>
			*buf++ = 0;
f0100ad8:	c6 06 00             	movb   $0x0,(%esi)
f0100adb:	89 7d a4             	mov    %edi,-0x5c(%ebp)
f0100ade:	8d 76 01             	lea    0x1(%esi),%esi
f0100ae1:	8b 7d a4             	mov    -0x5c(%ebp),%edi
		while (*buf && strchr(WHITESPACE, *buf))
f0100ae4:	0f b6 06             	movzbl (%esi),%eax
f0100ae7:	84 c0                	test   %al,%al
f0100ae9:	75 d7                	jne    f0100ac2 <monitor+0x3f>
	argv[argc] = 0;
f0100aeb:	c7 44 bd a8 00 00 00 	movl   $0x0,-0x58(%ebp,%edi,4)
f0100af2:	00 
	if (argc == 0)
f0100af3:	85 ff                	test   %edi,%edi
f0100af5:	0f 84 98 00 00 00    	je     f0100b93 <monitor+0x110>
f0100afb:	8d b3 ac ff ff ff    	lea    -0x54(%ebx),%esi
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100b01:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b06:	89 7d a4             	mov    %edi,-0x5c(%ebp)
f0100b09:	89 c7                	mov    %eax,%edi
		if (strcmp(argv[0], commands[i].name) == 0)
f0100b0b:	83 ec 08             	sub    $0x8,%esp
f0100b0e:	ff 36                	pushl  (%esi)
f0100b10:	ff 75 a8             	pushl  -0x58(%ebp)
f0100b13:	e8 7f 35 00 00       	call   f0104097 <strcmp>
f0100b18:	83 c4 10             	add    $0x10,%esp
f0100b1b:	85 c0                	test   %eax,%eax
f0100b1d:	0f 84 99 00 00 00    	je     f0100bbc <monitor+0x139>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100b23:	83 c7 01             	add    $0x1,%edi
f0100b26:	83 c6 0c             	add    $0xc,%esi
f0100b29:	83 ff 04             	cmp    $0x4,%edi
f0100b2c:	75 dd                	jne    f0100b0b <monitor+0x88>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100b2e:	83 ec 08             	sub    $0x8,%esp
f0100b31:	ff 75 a8             	pushl  -0x58(%ebp)
f0100b34:	8d 83 fb a7 fe ff    	lea    -0x15805(%ebx),%eax
f0100b3a:	50                   	push   %eax
f0100b3b:	e8 3c 27 00 00       	call   f010327c <cprintf>
f0100b40:	83 c4 10             	add    $0x10,%esp
f0100b43:	eb 4e                	jmp    f0100b93 <monitor+0x110>
		if (*buf == 0)
f0100b45:	80 3e 00             	cmpb   $0x0,(%esi)
f0100b48:	74 a1                	je     f0100aeb <monitor+0x68>
		if (argc == MAXARGS-1) {
f0100b4a:	83 ff 0f             	cmp    $0xf,%edi
f0100b4d:	74 30                	je     f0100b7f <monitor+0xfc>
		argv[argc++] = buf;
f0100b4f:	8d 47 01             	lea    0x1(%edi),%eax
f0100b52:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f0100b55:	89 74 bd a8          	mov    %esi,-0x58(%ebp,%edi,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f0100b59:	0f b6 06             	movzbl (%esi),%eax
f0100b5c:	84 c0                	test   %al,%al
f0100b5e:	74 81                	je     f0100ae1 <monitor+0x5e>
f0100b60:	83 ec 08             	sub    $0x8,%esp
f0100b63:	0f be c0             	movsbl %al,%eax
f0100b66:	50                   	push   %eax
f0100b67:	ff 75 a0             	pushl  -0x60(%ebp)
f0100b6a:	e8 86 35 00 00       	call   f01040f5 <strchr>
f0100b6f:	83 c4 10             	add    $0x10,%esp
f0100b72:	85 c0                	test   %eax,%eax
f0100b74:	0f 85 67 ff ff ff    	jne    f0100ae1 <monitor+0x5e>
			buf++;
f0100b7a:	83 c6 01             	add    $0x1,%esi
f0100b7d:	eb da                	jmp    f0100b59 <monitor+0xd6>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100b7f:	83 ec 08             	sub    $0x8,%esp
f0100b82:	6a 10                	push   $0x10
f0100b84:	8d 83 67 a8 fe ff    	lea    -0x15799(%ebx),%eax
f0100b8a:	50                   	push   %eax
f0100b8b:	e8 ec 26 00 00       	call   f010327c <cprintf>
f0100b90:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100b93:	8d bb 5e a8 fe ff    	lea    -0x157a2(%ebx),%edi
f0100b99:	83 ec 0c             	sub    $0xc,%esp
f0100b9c:	57                   	push   %edi
f0100b9d:	e8 14 33 00 00       	call   f0103eb6 <readline>
		if (buf != NULL)
f0100ba2:	83 c4 10             	add    $0x10,%esp
f0100ba5:	85 c0                	test   %eax,%eax
f0100ba7:	74 f0                	je     f0100b99 <monitor+0x116>
f0100ba9:	89 c6                	mov    %eax,%esi
	argv[argc] = 0;
f0100bab:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f0100bb2:	bf 00 00 00 00       	mov    $0x0,%edi
f0100bb7:	e9 28 ff ff ff       	jmp    f0100ae4 <monitor+0x61>
f0100bbc:	89 f8                	mov    %edi,%eax
f0100bbe:	8b 7d a4             	mov    -0x5c(%ebp),%edi
			return commands[i].func(argc, argv, tf);
f0100bc1:	83 ec 04             	sub    $0x4,%esp
f0100bc4:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100bc7:	ff 75 08             	pushl  0x8(%ebp)
f0100bca:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100bcd:	52                   	push   %edx
f0100bce:	57                   	push   %edi
f0100bcf:	ff 94 83 b4 ff ff ff 	call   *-0x4c(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100bd6:	83 c4 10             	add    $0x10,%esp
f0100bd9:	85 c0                	test   %eax,%eax
f0100bdb:	79 b6                	jns    f0100b93 <monitor+0x110>
				break;
	}
}
f0100bdd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100be0:	5b                   	pop    %ebx
f0100be1:	5e                   	pop    %esi
f0100be2:	5f                   	pop    %edi
f0100be3:	5d                   	pop    %ebp
f0100be4:	c3                   	ret    

f0100be5 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100be5:	55                   	push   %ebp
f0100be6:	89 e5                	mov    %esp,%ebp
f0100be8:	57                   	push   %edi
f0100be9:	56                   	push   %esi
f0100bea:	53                   	push   %ebx
f0100beb:	83 ec 18             	sub    $0x18,%esp
f0100bee:	e8 5c f5 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0100bf3:	81 c3 81 94 01 00    	add    $0x19481,%ebx
f0100bf9:	89 c7                	mov    %eax,%edi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100bfb:	50                   	push   %eax
f0100bfc:	e8 f4 25 00 00       	call   f01031f5 <mc146818_read>
f0100c01:	89 c6                	mov    %eax,%esi
f0100c03:	83 c7 01             	add    $0x1,%edi
f0100c06:	89 3c 24             	mov    %edi,(%esp)
f0100c09:	e8 e7 25 00 00       	call   f01031f5 <mc146818_read>
f0100c0e:	c1 e0 08             	shl    $0x8,%eax
f0100c11:	09 f0                	or     %esi,%eax
}
f0100c13:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c16:	5b                   	pop    %ebx
f0100c17:	5e                   	pop    %esi
f0100c18:	5f                   	pop    %edi
f0100c19:	5d                   	pop    %ebp
f0100c1a:	c3                   	ret    

f0100c1b <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100c1b:	55                   	push   %ebp
f0100c1c:	89 e5                	mov    %esp,%ebp
f0100c1e:	56                   	push   %esi
f0100c1f:	53                   	push   %ebx
f0100c20:	e8 c4 25 00 00       	call   f01031e9 <__x86.get_pc_thunk.cx>
f0100c25:	81 c1 4f 94 01 00    	add    $0x1944f,%ecx
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100c2b:	89 d3                	mov    %edx,%ebx
f0100c2d:	c1 eb 16             	shr    $0x16,%ebx
	if (!(*pgdir & PTE_P))
f0100c30:	8b 04 98             	mov    (%eax,%ebx,4),%eax
f0100c33:	a8 01                	test   $0x1,%al
f0100c35:	74 5a                	je     f0100c91 <check_va2pa+0x76>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100c37:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c3c:	89 c6                	mov    %eax,%esi
f0100c3e:	c1 ee 0c             	shr    $0xc,%esi
f0100c41:	c7 c3 e8 a6 11 f0    	mov    $0xf011a6e8,%ebx
f0100c47:	3b 33                	cmp    (%ebx),%esi
f0100c49:	73 2b                	jae    f0100c76 <check_va2pa+0x5b>
	if (!(p[PTX(va)] & PTE_P))
f0100c4b:	c1 ea 0c             	shr    $0xc,%edx
f0100c4e:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100c54:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100c5b:	89 c2                	mov    %eax,%edx
f0100c5d:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100c60:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100c65:	85 d2                	test   %edx,%edx
f0100c67:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100c6c:	0f 44 c2             	cmove  %edx,%eax
}
f0100c6f:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100c72:	5b                   	pop    %ebx
f0100c73:	5e                   	pop    %esi
f0100c74:	5d                   	pop    %ebp
f0100c75:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c76:	50                   	push   %eax
f0100c77:	8d 81 58 aa fe ff    	lea    -0x155a8(%ecx),%eax
f0100c7d:	50                   	push   %eax
f0100c7e:	68 03 03 00 00       	push   $0x303
f0100c83:	8d 81 f9 b1 fe ff    	lea    -0x14e07(%ecx),%eax
f0100c89:	50                   	push   %eax
f0100c8a:	89 cb                	mov    %ecx,%ebx
f0100c8c:	e8 08 f4 ff ff       	call   f0100099 <_panic>
		return ~0;
f0100c91:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c96:	eb d7                	jmp    f0100c6f <check_va2pa+0x54>

f0100c98 <boot_alloc>:
{
f0100c98:	e8 48 25 00 00       	call   f01031e5 <__x86.get_pc_thunk.dx>
f0100c9d:	81 c2 d7 93 01 00    	add    $0x193d7,%edx
	if (!nextfree) {
f0100ca3:	83 ba 44 02 00 00 00 	cmpl   $0x0,0x244(%edx)
f0100caa:	74 51                	je     f0100cfd <boot_alloc+0x65>
	if(n > 0){
f0100cac:	85 c0                	test   %eax,%eax
f0100cae:	0f 84 93 00 00 00    	je     f0100d47 <boot_alloc+0xaf>
{
f0100cb4:	55                   	push   %ebp
f0100cb5:	89 e5                	mov    %esp,%ebp
f0100cb7:	57                   	push   %edi
f0100cb8:	56                   	push   %esi
f0100cb9:	53                   	push   %ebx
f0100cba:	83 ec 0c             	sub    $0xc,%esp
f0100cbd:	89 c1                	mov    %eax,%ecx
		result = nextfree;
f0100cbf:	8b 82 44 02 00 00    	mov    0x244(%edx),%eax
		nextfree = KADDR(PADDR(ROUNDUP(nextfree+n, PGSIZE)));
f0100cc5:	8d 8c 08 ff 0f 00 00 	lea    0xfff(%eax,%ecx,1),%ecx
f0100ccc:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
	if ((uint32_t)kva < KERNBASE)
f0100cd2:	81 f9 ff ff ff ef    	cmp    $0xefffffff,%ecx
f0100cd8:	76 3d                	jbe    f0100d17 <boot_alloc+0x7f>
	return (physaddr_t)kva - KERNBASE;
f0100cda:	8d 99 00 00 00 10    	lea    0x10000000(%ecx),%ebx
	if (PGNUM(pa) >= npages)
f0100ce0:	89 de                	mov    %ebx,%esi
f0100ce2:	c1 ee 0c             	shr    $0xc,%esi
f0100ce5:	c7 c7 e8 a6 11 f0    	mov    $0xf011a6e8,%edi
f0100ceb:	39 37                	cmp    %esi,(%edi)
f0100ced:	76 40                	jbe    f0100d2f <boot_alloc+0x97>
f0100cef:	89 8a 44 02 00 00    	mov    %ecx,0x244(%edx)
}
f0100cf5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100cf8:	5b                   	pop    %ebx
f0100cf9:	5e                   	pop    %esi
f0100cfa:	5f                   	pop    %edi
f0100cfb:	5d                   	pop    %ebp
f0100cfc:	c3                   	ret    
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100cfd:	c7 c1 e0 a6 11 f0    	mov    $0xf011a6e0,%ecx
f0100d03:	81 c1 ff 0f 00 00    	add    $0xfff,%ecx
f0100d09:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100d0f:	89 8a 44 02 00 00    	mov    %ecx,0x244(%edx)
f0100d15:	eb 95                	jmp    f0100cac <boot_alloc+0x14>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100d17:	51                   	push   %ecx
f0100d18:	8d 82 7c aa fe ff    	lea    -0x15584(%edx),%eax
f0100d1e:	50                   	push   %eax
f0100d1f:	6a 6e                	push   $0x6e
f0100d21:	8d 82 f9 b1 fe ff    	lea    -0x14e07(%edx),%eax
f0100d27:	50                   	push   %eax
f0100d28:	89 d3                	mov    %edx,%ebx
f0100d2a:	e8 6a f3 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d2f:	53                   	push   %ebx
f0100d30:	8d 82 58 aa fe ff    	lea    -0x155a8(%edx),%eax
f0100d36:	50                   	push   %eax
f0100d37:	6a 6e                	push   $0x6e
f0100d39:	8d 82 f9 b1 fe ff    	lea    -0x14e07(%edx),%eax
f0100d3f:	50                   	push   %eax
f0100d40:	89 d3                	mov    %edx,%ebx
f0100d42:	e8 52 f3 ff ff       	call   f0100099 <_panic>
		return nextfree;
f0100d47:	8b 82 44 02 00 00    	mov    0x244(%edx),%eax
}
f0100d4d:	c3                   	ret    

f0100d4e <check_page_free_list>:
{
f0100d4e:	55                   	push   %ebp
f0100d4f:	89 e5                	mov    %esp,%ebp
f0100d51:	57                   	push   %edi
f0100d52:	56                   	push   %esi
f0100d53:	53                   	push   %ebx
f0100d54:	83 ec 2c             	sub    $0x2c,%esp
f0100d57:	e8 91 24 00 00       	call   f01031ed <__x86.get_pc_thunk.si>
f0100d5c:	81 c6 18 93 01 00    	add    $0x19318,%esi
f0100d62:	89 75 c8             	mov    %esi,-0x38(%ebp)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100d65:	84 c0                	test   %al,%al
f0100d67:	0f 85 ec 02 00 00    	jne    f0101059 <check_page_free_list+0x30b>
	if (!page_free_list)
f0100d6d:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0100d70:	83 b8 48 02 00 00 00 	cmpl   $0x0,0x248(%eax)
f0100d77:	74 21                	je     f0100d9a <check_page_free_list+0x4c>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100d79:	c7 45 d4 00 04 00 00 	movl   $0x400,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100d80:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0100d83:	8b b0 48 02 00 00    	mov    0x248(%eax),%esi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d89:	c7 c7 f0 a6 11 f0    	mov    $0xf011a6f0,%edi
	if (PGNUM(pa) >= npages)
f0100d8f:	c7 c0 e8 a6 11 f0    	mov    $0xf011a6e8,%eax
f0100d95:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100d98:	eb 39                	jmp    f0100dd3 <check_page_free_list+0x85>
		panic("'page_free_list' is a null pointer!");
f0100d9a:	83 ec 04             	sub    $0x4,%esp
f0100d9d:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100da0:	8d 83 a0 aa fe ff    	lea    -0x15560(%ebx),%eax
f0100da6:	50                   	push   %eax
f0100da7:	68 3d 02 00 00       	push   $0x23d
f0100dac:	8d 83 f9 b1 fe ff    	lea    -0x14e07(%ebx),%eax
f0100db2:	50                   	push   %eax
f0100db3:	e8 e1 f2 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100db8:	50                   	push   %eax
f0100db9:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100dbc:	8d 83 58 aa fe ff    	lea    -0x155a8(%ebx),%eax
f0100dc2:	50                   	push   %eax
f0100dc3:	6a 52                	push   $0x52
f0100dc5:	8d 83 05 b2 fe ff    	lea    -0x14dfb(%ebx),%eax
f0100dcb:	50                   	push   %eax
f0100dcc:	e8 c8 f2 ff ff       	call   f0100099 <_panic>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100dd1:	8b 36                	mov    (%esi),%esi
f0100dd3:	85 f6                	test   %esi,%esi
f0100dd5:	74 40                	je     f0100e17 <check_page_free_list+0xc9>
	return (pp - pages) << PGSHIFT;
f0100dd7:	89 f0                	mov    %esi,%eax
f0100dd9:	2b 07                	sub    (%edi),%eax
f0100ddb:	c1 f8 03             	sar    $0x3,%eax
f0100dde:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100de1:	89 c2                	mov    %eax,%edx
f0100de3:	c1 ea 16             	shr    $0x16,%edx
f0100de6:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100de9:	73 e6                	jae    f0100dd1 <check_page_free_list+0x83>
	if (PGNUM(pa) >= npages)
f0100deb:	89 c2                	mov    %eax,%edx
f0100ded:	c1 ea 0c             	shr    $0xc,%edx
f0100df0:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100df3:	3b 11                	cmp    (%ecx),%edx
f0100df5:	73 c1                	jae    f0100db8 <check_page_free_list+0x6a>
			memset(page2kva(pp), 0x97, 128);
f0100df7:	83 ec 04             	sub    $0x4,%esp
f0100dfa:	68 80 00 00 00       	push   $0x80
f0100dff:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100e04:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100e09:	50                   	push   %eax
f0100e0a:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100e0d:	e8 20 33 00 00       	call   f0104132 <memset>
f0100e12:	83 c4 10             	add    $0x10,%esp
f0100e15:	eb ba                	jmp    f0100dd1 <check_page_free_list+0x83>
	first_free_page = (char *) boot_alloc(0);
f0100e17:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e1c:	e8 77 fe ff ff       	call   f0100c98 <boot_alloc>
f0100e21:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100e24:	8b 7d c8             	mov    -0x38(%ebp),%edi
f0100e27:	8b 97 48 02 00 00    	mov    0x248(%edi),%edx
		assert(pp >= pages);
f0100e2d:	c7 c0 f0 a6 11 f0    	mov    $0xf011a6f0,%eax
f0100e33:	8b 08                	mov    (%eax),%ecx
		assert(pp < pages + npages);
f0100e35:	c7 c0 e8 a6 11 f0    	mov    $0xf011a6e8,%eax
f0100e3b:	8b 00                	mov    (%eax),%eax
f0100e3d:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100e40:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
	int nfree_basemem = 0, nfree_extmem = 0;
f0100e43:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100e48:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100e4b:	e9 08 01 00 00       	jmp    f0100f58 <check_page_free_list+0x20a>
		assert(pp >= pages);
f0100e50:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100e53:	8d 83 13 b2 fe ff    	lea    -0x14ded(%ebx),%eax
f0100e59:	50                   	push   %eax
f0100e5a:	8d 83 1f b2 fe ff    	lea    -0x14de1(%ebx),%eax
f0100e60:	50                   	push   %eax
f0100e61:	68 57 02 00 00       	push   $0x257
f0100e66:	8d 83 f9 b1 fe ff    	lea    -0x14e07(%ebx),%eax
f0100e6c:	50                   	push   %eax
f0100e6d:	e8 27 f2 ff ff       	call   f0100099 <_panic>
		assert(pp < pages + npages);
f0100e72:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100e75:	8d 83 34 b2 fe ff    	lea    -0x14dcc(%ebx),%eax
f0100e7b:	50                   	push   %eax
f0100e7c:	8d 83 1f b2 fe ff    	lea    -0x14de1(%ebx),%eax
f0100e82:	50                   	push   %eax
f0100e83:	68 58 02 00 00       	push   $0x258
f0100e88:	8d 83 f9 b1 fe ff    	lea    -0x14e07(%ebx),%eax
f0100e8e:	50                   	push   %eax
f0100e8f:	e8 05 f2 ff ff       	call   f0100099 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100e94:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100e97:	8d 83 c4 aa fe ff    	lea    -0x1553c(%ebx),%eax
f0100e9d:	50                   	push   %eax
f0100e9e:	8d 83 1f b2 fe ff    	lea    -0x14de1(%ebx),%eax
f0100ea4:	50                   	push   %eax
f0100ea5:	68 59 02 00 00       	push   $0x259
f0100eaa:	8d 83 f9 b1 fe ff    	lea    -0x14e07(%ebx),%eax
f0100eb0:	50                   	push   %eax
f0100eb1:	e8 e3 f1 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != 0);
f0100eb6:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100eb9:	8d 83 48 b2 fe ff    	lea    -0x14db8(%ebx),%eax
f0100ebf:	50                   	push   %eax
f0100ec0:	8d 83 1f b2 fe ff    	lea    -0x14de1(%ebx),%eax
f0100ec6:	50                   	push   %eax
f0100ec7:	68 5c 02 00 00       	push   $0x25c
f0100ecc:	8d 83 f9 b1 fe ff    	lea    -0x14e07(%ebx),%eax
f0100ed2:	50                   	push   %eax
f0100ed3:	e8 c1 f1 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100ed8:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100edb:	8d 83 59 b2 fe ff    	lea    -0x14da7(%ebx),%eax
f0100ee1:	50                   	push   %eax
f0100ee2:	8d 83 1f b2 fe ff    	lea    -0x14de1(%ebx),%eax
f0100ee8:	50                   	push   %eax
f0100ee9:	68 5d 02 00 00       	push   $0x25d
f0100eee:	8d 83 f9 b1 fe ff    	lea    -0x14e07(%ebx),%eax
f0100ef4:	50                   	push   %eax
f0100ef5:	e8 9f f1 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100efa:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100efd:	8d 83 f8 aa fe ff    	lea    -0x15508(%ebx),%eax
f0100f03:	50                   	push   %eax
f0100f04:	8d 83 1f b2 fe ff    	lea    -0x14de1(%ebx),%eax
f0100f0a:	50                   	push   %eax
f0100f0b:	68 5e 02 00 00       	push   $0x25e
f0100f10:	8d 83 f9 b1 fe ff    	lea    -0x14e07(%ebx),%eax
f0100f16:	50                   	push   %eax
f0100f17:	e8 7d f1 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100f1c:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100f1f:	8d 83 72 b2 fe ff    	lea    -0x14d8e(%ebx),%eax
f0100f25:	50                   	push   %eax
f0100f26:	8d 83 1f b2 fe ff    	lea    -0x14de1(%ebx),%eax
f0100f2c:	50                   	push   %eax
f0100f2d:	68 5f 02 00 00       	push   $0x25f
f0100f32:	8d 83 f9 b1 fe ff    	lea    -0x14e07(%ebx),%eax
f0100f38:	50                   	push   %eax
f0100f39:	e8 5b f1 ff ff       	call   f0100099 <_panic>
	if (PGNUM(pa) >= npages)
f0100f3e:	89 c3                	mov    %eax,%ebx
f0100f40:	c1 eb 0c             	shr    $0xc,%ebx
f0100f43:	39 5d d0             	cmp    %ebx,-0x30(%ebp)
f0100f46:	76 6d                	jbe    f0100fb5 <check_page_free_list+0x267>
	return (void *)(pa + KERNBASE);
f0100f48:	2d 00 00 00 10       	sub    $0x10000000,%eax
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100f4d:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100f50:	77 7c                	ja     f0100fce <check_page_free_list+0x280>
			++nfree_extmem;
f0100f52:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100f56:	8b 12                	mov    (%edx),%edx
f0100f58:	85 d2                	test   %edx,%edx
f0100f5a:	0f 84 90 00 00 00    	je     f0100ff0 <check_page_free_list+0x2a2>
		assert(pp >= pages);
f0100f60:	39 d1                	cmp    %edx,%ecx
f0100f62:	0f 87 e8 fe ff ff    	ja     f0100e50 <check_page_free_list+0x102>
		assert(pp < pages + npages);
f0100f68:	39 d7                	cmp    %edx,%edi
f0100f6a:	0f 86 02 ff ff ff    	jbe    f0100e72 <check_page_free_list+0x124>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100f70:	89 d0                	mov    %edx,%eax
f0100f72:	29 c8                	sub    %ecx,%eax
f0100f74:	a8 07                	test   $0x7,%al
f0100f76:	0f 85 18 ff ff ff    	jne    f0100e94 <check_page_free_list+0x146>
	return (pp - pages) << PGSHIFT;
f0100f7c:	c1 f8 03             	sar    $0x3,%eax
		assert(page2pa(pp) != 0);
f0100f7f:	c1 e0 0c             	shl    $0xc,%eax
f0100f82:	0f 84 2e ff ff ff    	je     f0100eb6 <check_page_free_list+0x168>
		assert(page2pa(pp) != IOPHYSMEM);
f0100f88:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100f8d:	0f 84 45 ff ff ff    	je     f0100ed8 <check_page_free_list+0x18a>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100f93:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100f98:	0f 84 5c ff ff ff    	je     f0100efa <check_page_free_list+0x1ac>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100f9e:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100fa3:	0f 84 73 ff ff ff    	je     f0100f1c <check_page_free_list+0x1ce>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100fa9:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100fae:	77 8e                	ja     f0100f3e <check_page_free_list+0x1f0>
			++nfree_basemem;
f0100fb0:	83 c6 01             	add    $0x1,%esi
f0100fb3:	eb a1                	jmp    f0100f56 <check_page_free_list+0x208>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fb5:	50                   	push   %eax
f0100fb6:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100fb9:	8d 83 58 aa fe ff    	lea    -0x155a8(%ebx),%eax
f0100fbf:	50                   	push   %eax
f0100fc0:	6a 52                	push   $0x52
f0100fc2:	8d 83 05 b2 fe ff    	lea    -0x14dfb(%ebx),%eax
f0100fc8:	50                   	push   %eax
f0100fc9:	e8 cb f0 ff ff       	call   f0100099 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100fce:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0100fd1:	8d 83 1c ab fe ff    	lea    -0x154e4(%ebx),%eax
f0100fd7:	50                   	push   %eax
f0100fd8:	8d 83 1f b2 fe ff    	lea    -0x14de1(%ebx),%eax
f0100fde:	50                   	push   %eax
f0100fdf:	68 60 02 00 00       	push   $0x260
f0100fe4:	8d 83 f9 b1 fe ff    	lea    -0x14e07(%ebx),%eax
f0100fea:	50                   	push   %eax
f0100feb:	e8 a9 f0 ff ff       	call   f0100099 <_panic>
f0100ff0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
	assert(nfree_basemem > 0);
f0100ff3:	85 f6                	test   %esi,%esi
f0100ff5:	7e 1e                	jle    f0101015 <check_page_free_list+0x2c7>
	assert(nfree_extmem > 0);
f0100ff7:	85 db                	test   %ebx,%ebx
f0100ff9:	7e 3c                	jle    f0101037 <check_page_free_list+0x2e9>
	cprintf("check_page_free_list() succeeded!\n");
f0100ffb:	83 ec 0c             	sub    $0xc,%esp
f0100ffe:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0101001:	8d 83 64 ab fe ff    	lea    -0x1549c(%ebx),%eax
f0101007:	50                   	push   %eax
f0101008:	e8 6f 22 00 00       	call   f010327c <cprintf>
}
f010100d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101010:	5b                   	pop    %ebx
f0101011:	5e                   	pop    %esi
f0101012:	5f                   	pop    %edi
f0101013:	5d                   	pop    %ebp
f0101014:	c3                   	ret    
	assert(nfree_basemem > 0);
f0101015:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f0101018:	8d 83 8c b2 fe ff    	lea    -0x14d74(%ebx),%eax
f010101e:	50                   	push   %eax
f010101f:	8d 83 1f b2 fe ff    	lea    -0x14de1(%ebx),%eax
f0101025:	50                   	push   %eax
f0101026:	68 68 02 00 00       	push   $0x268
f010102b:	8d 83 f9 b1 fe ff    	lea    -0x14e07(%ebx),%eax
f0101031:	50                   	push   %eax
f0101032:	e8 62 f0 ff ff       	call   f0100099 <_panic>
	assert(nfree_extmem > 0);
f0101037:	8b 5d c8             	mov    -0x38(%ebp),%ebx
f010103a:	8d 83 9e b2 fe ff    	lea    -0x14d62(%ebx),%eax
f0101040:	50                   	push   %eax
f0101041:	8d 83 1f b2 fe ff    	lea    -0x14de1(%ebx),%eax
f0101047:	50                   	push   %eax
f0101048:	68 69 02 00 00       	push   $0x269
f010104d:	8d 83 f9 b1 fe ff    	lea    -0x14e07(%ebx),%eax
f0101053:	50                   	push   %eax
f0101054:	e8 40 f0 ff ff       	call   f0100099 <_panic>
	if (!page_free_list)
f0101059:	8b 45 c8             	mov    -0x38(%ebp),%eax
f010105c:	8b 80 48 02 00 00    	mov    0x248(%eax),%eax
f0101062:	85 c0                	test   %eax,%eax
f0101064:	0f 84 30 fd ff ff    	je     f0100d9a <check_page_free_list+0x4c>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f010106a:	8d 55 d8             	lea    -0x28(%ebp),%edx
f010106d:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101070:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0101073:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0101076:	8b 75 c8             	mov    -0x38(%ebp),%esi
f0101079:	c7 c3 f0 a6 11 f0    	mov    $0xf011a6f0,%ebx
f010107f:	89 c2                	mov    %eax,%edx
f0101081:	2b 13                	sub    (%ebx),%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0101083:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0101089:	0f 95 c2             	setne  %dl
f010108c:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f010108f:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0101093:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0101095:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0101099:	8b 00                	mov    (%eax),%eax
f010109b:	85 c0                	test   %eax,%eax
f010109d:	75 e0                	jne    f010107f <check_page_free_list+0x331>
		*tp[1] = 0;
f010109f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01010a2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f01010a8:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01010ab:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01010ae:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f01010b0:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01010b3:	8b 75 c8             	mov    -0x38(%ebp),%esi
f01010b6:	89 86 48 02 00 00    	mov    %eax,0x248(%esi)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01010bc:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
f01010c3:	e9 b8 fc ff ff       	jmp    f0100d80 <check_page_free_list+0x32>

f01010c8 <page_init>:
{
f01010c8:	55                   	push   %ebp
f01010c9:	89 e5                	mov    %esp,%ebp
f01010cb:	57                   	push   %edi
f01010cc:	56                   	push   %esi
f01010cd:	53                   	push   %ebx
f01010ce:	83 ec 1c             	sub    $0x1c,%esp
f01010d1:	e8 1b 21 00 00       	call   f01031f1 <__x86.get_pc_thunk.di>
f01010d6:	81 c7 9e 8f 01 00    	add    $0x18f9e,%edi
f01010dc:	89 fe                	mov    %edi,%esi
f01010de:	89 7d e4             	mov    %edi,-0x1c(%ebp)
	pages[0].pp_ref = 1;
f01010e1:	c7 c0 f0 a6 11 f0    	mov    $0xf011a6f0,%eax
f01010e7:	8b 00                	mov    (%eax),%eax
f01010e9:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	pages[0].pp_link = NULL;
f01010ef:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	for(i = 1; i < npages_basemem; i++){
f01010f5:	8b bf 4c 02 00 00    	mov    0x24c(%edi),%edi
f01010fb:	8b 8e 48 02 00 00    	mov    0x248(%esi),%ecx
f0101101:	b8 00 00 00 00       	mov    $0x0,%eax
f0101106:	bb 01 00 00 00       	mov    $0x1,%ebx
		pages[i].pp_ref = 0;
f010110b:	c7 c6 f0 a6 11 f0    	mov    $0xf011a6f0,%esi
	for(i = 1; i < npages_basemem; i++){
f0101111:	39 df                	cmp    %ebx,%edi
f0101113:	76 21                	jbe    f0101136 <page_init+0x6e>
f0101115:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
		pages[i].pp_ref = 0;
f010111c:	89 c2                	mov    %eax,%edx
f010111e:	03 16                	add    (%esi),%edx
f0101120:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
		pages[i].pp_link = page_free_list;
f0101126:	89 0a                	mov    %ecx,(%edx)
	for(i = 1; i < npages_basemem; i++){
f0101128:	83 c3 01             	add    $0x1,%ebx
		page_free_list = &pages[i];
f010112b:	03 06                	add    (%esi),%eax
f010112d:	89 c1                	mov    %eax,%ecx
f010112f:	b8 01 00 00 00       	mov    $0x1,%eax
f0101134:	eb db                	jmp    f0101111 <page_init+0x49>
f0101136:	84 c0                	test   %al,%al
f0101138:	74 09                	je     f0101143 <page_init+0x7b>
f010113a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010113d:	89 88 48 02 00 00    	mov    %ecx,0x248(%eax)
	size_t num = PGNUM(PADDR(boot_alloc(0)));
f0101143:	b8 00 00 00 00       	mov    $0x0,%eax
f0101148:	e8 4b fb ff ff       	call   f0100c98 <boot_alloc>
	if ((uint32_t)kva < KERNBASE)
f010114d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101152:	76 13                	jbe    f0101167 <page_init+0x9f>
	return (physaddr_t)kva - KERNBASE;
f0101154:	05 00 00 00 10       	add    $0x10000000,%eax
f0101159:	c1 e8 0c             	shr    $0xc,%eax
		pages[i].pp_ref = 1;
f010115c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010115f:	c7 c1 f0 a6 11 f0    	mov    $0xf011a6f0,%ecx
	for(; i < num; i++){
f0101165:	eb 30                	jmp    f0101197 <page_init+0xcf>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101167:	50                   	push   %eax
f0101168:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010116b:	8d 83 7c aa fe ff    	lea    -0x15584(%ebx),%eax
f0101171:	50                   	push   %eax
f0101172:	68 1b 01 00 00       	push   $0x11b
f0101177:	8d 83 f9 b1 fe ff    	lea    -0x14e07(%ebx),%eax
f010117d:	50                   	push   %eax
f010117e:	e8 16 ef ff ff       	call   f0100099 <_panic>
		pages[i].pp_ref = 1;
f0101183:	8b 11                	mov    (%ecx),%edx
f0101185:	8d 14 da             	lea    (%edx,%ebx,8),%edx
f0101188:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
		pages[i].pp_link = NULL;
f010118e:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
	for(; i < num; i++){
f0101194:	83 c3 01             	add    $0x1,%ebx
f0101197:	39 c3                	cmp    %eax,%ebx
f0101199:	72 e8                	jb     f0101183 <page_init+0xbb>
f010119b:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010119e:	8b 8e 48 02 00 00    	mov    0x248(%esi),%ecx
f01011a4:	b8 00 00 00 00       	mov    $0x0,%eax
	for(; i < npages; i++){
f01011a9:	c7 c7 e8 a6 11 f0    	mov    $0xf011a6e8,%edi
		pages[i].pp_ref = 0;
f01011af:	c7 c6 f0 a6 11 f0    	mov    $0xf011a6f0,%esi
	for(; i < npages; i++){
f01011b5:	39 1f                	cmp    %ebx,(%edi)
f01011b7:	76 21                	jbe    f01011da <page_init+0x112>
f01011b9:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
		pages[i].pp_ref = 0;
f01011c0:	89 c2                	mov    %eax,%edx
f01011c2:	03 16                	add    (%esi),%edx
f01011c4:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
		pages[i].pp_link = page_free_list;
f01011ca:	89 0a                	mov    %ecx,(%edx)
	for(; i < npages; i++){
f01011cc:	83 c3 01             	add    $0x1,%ebx
		page_free_list = &pages[i];
f01011cf:	03 06                	add    (%esi),%eax
f01011d1:	89 c1                	mov    %eax,%ecx
f01011d3:	b8 01 00 00 00       	mov    $0x1,%eax
f01011d8:	eb db                	jmp    f01011b5 <page_init+0xed>
f01011da:	84 c0                	test   %al,%al
f01011dc:	74 09                	je     f01011e7 <page_init+0x11f>
f01011de:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01011e1:	89 88 48 02 00 00    	mov    %ecx,0x248(%eax)
}
f01011e7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011ea:	5b                   	pop    %ebx
f01011eb:	5e                   	pop    %esi
f01011ec:	5f                   	pop    %edi
f01011ed:	5d                   	pop    %ebp
f01011ee:	c3                   	ret    

f01011ef <page_alloc>:
{
f01011ef:	55                   	push   %ebp
f01011f0:	89 e5                	mov    %esp,%ebp
f01011f2:	53                   	push   %ebx
f01011f3:	83 ec 04             	sub    $0x4,%esp
f01011f6:	e8 54 ef ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01011fb:	81 c3 79 8e 01 00    	add    $0x18e79,%ebx
	if(page_free_list == NULL){
f0101201:	8b 83 48 02 00 00    	mov    0x248(%ebx),%eax
f0101207:	85 c0                	test   %eax,%eax
f0101209:	74 20                	je     f010122b <page_alloc+0x3c>
	if(alloc_flags & ALLOC_ZERO){
f010120b:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f010120f:	75 1f                	jne    f0101230 <page_alloc+0x41>
	struct PageInfo * ret = page_free_list;
f0101211:	8b 83 48 02 00 00    	mov    0x248(%ebx),%eax
	page_free_list = page_free_list->pp_link;
f0101217:	8b 10                	mov    (%eax),%edx
f0101219:	89 93 48 02 00 00    	mov    %edx,0x248(%ebx)
	ret->pp_ref = 0;
f010121f:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
	ret->pp_link = NULL;
f0101225:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
f010122b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010122e:	c9                   	leave  
f010122f:	c3                   	ret    
	return (pp - pages) << PGSHIFT;
f0101230:	c7 c2 f0 a6 11 f0    	mov    $0xf011a6f0,%edx
f0101236:	2b 02                	sub    (%edx),%eax
f0101238:	c1 f8 03             	sar    $0x3,%eax
f010123b:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f010123e:	89 c1                	mov    %eax,%ecx
f0101240:	c1 e9 0c             	shr    $0xc,%ecx
f0101243:	c7 c2 e8 a6 11 f0    	mov    $0xf011a6e8,%edx
f0101249:	3b 0a                	cmp    (%edx),%ecx
f010124b:	73 1a                	jae    f0101267 <page_alloc+0x78>
		memset(page2kva(page_free_list), 0, PGSIZE);
f010124d:	83 ec 04             	sub    $0x4,%esp
f0101250:	68 00 10 00 00       	push   $0x1000
f0101255:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f0101257:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010125c:	50                   	push   %eax
f010125d:	e8 d0 2e 00 00       	call   f0104132 <memset>
f0101262:	83 c4 10             	add    $0x10,%esp
f0101265:	eb aa                	jmp    f0101211 <page_alloc+0x22>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101267:	50                   	push   %eax
f0101268:	8d 83 58 aa fe ff    	lea    -0x155a8(%ebx),%eax
f010126e:	50                   	push   %eax
f010126f:	6a 52                	push   $0x52
f0101271:	8d 83 05 b2 fe ff    	lea    -0x14dfb(%ebx),%eax
f0101277:	50                   	push   %eax
f0101278:	e8 1c ee ff ff       	call   f0100099 <_panic>

f010127d <page_free>:
{
f010127d:	55                   	push   %ebp
f010127e:	89 e5                	mov    %esp,%ebp
f0101280:	53                   	push   %ebx
f0101281:	83 ec 04             	sub    $0x4,%esp
f0101284:	e8 c6 ee ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101289:	81 c3 eb 8d 01 00    	add    $0x18deb,%ebx
f010128f:	8b 45 08             	mov    0x8(%ebp),%eax
	if(pp->pp_ref !=0 || pp->pp_link){
f0101292:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101297:	75 18                	jne    f01012b1 <page_free+0x34>
f0101299:	83 38 00             	cmpl   $0x0,(%eax)
f010129c:	75 13                	jne    f01012b1 <page_free+0x34>
	pp->pp_link = page_free_list;
f010129e:	8b 8b 48 02 00 00    	mov    0x248(%ebx),%ecx
f01012a4:	89 08                	mov    %ecx,(%eax)
	page_free_list = pp;
f01012a6:	89 83 48 02 00 00    	mov    %eax,0x248(%ebx)
}
f01012ac:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01012af:	c9                   	leave  
f01012b0:	c3                   	ret    
		panic("\n[Error]free a page in use\n");
f01012b1:	83 ec 04             	sub    $0x4,%esp
f01012b4:	8d 83 af b2 fe ff    	lea    -0x14d51(%ebx),%eax
f01012ba:	50                   	push   %eax
f01012bb:	68 52 01 00 00       	push   $0x152
f01012c0:	8d 83 f9 b1 fe ff    	lea    -0x14e07(%ebx),%eax
f01012c6:	50                   	push   %eax
f01012c7:	e8 cd ed ff ff       	call   f0100099 <_panic>

f01012cc <page_decref>:
{
f01012cc:	55                   	push   %ebp
f01012cd:	89 e5                	mov    %esp,%ebp
f01012cf:	83 ec 08             	sub    $0x8,%esp
f01012d2:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f01012d5:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f01012d9:	83 e8 01             	sub    $0x1,%eax
f01012dc:	66 89 42 04          	mov    %ax,0x4(%edx)
f01012e0:	66 85 c0             	test   %ax,%ax
f01012e3:	74 02                	je     f01012e7 <page_decref+0x1b>
}
f01012e5:	c9                   	leave  
f01012e6:	c3                   	ret    
		page_free(pp);
f01012e7:	83 ec 0c             	sub    $0xc,%esp
f01012ea:	52                   	push   %edx
f01012eb:	e8 8d ff ff ff       	call   f010127d <page_free>
f01012f0:	83 c4 10             	add    $0x10,%esp
}
f01012f3:	eb f0                	jmp    f01012e5 <page_decref+0x19>

f01012f5 <pgdir_walk>:
{
f01012f5:	55                   	push   %ebp
f01012f6:	89 e5                	mov    %esp,%ebp
f01012f8:	57                   	push   %edi
f01012f9:	56                   	push   %esi
f01012fa:	53                   	push   %ebx
f01012fb:	83 ec 0c             	sub    $0xc,%esp
f01012fe:	e8 4c ee ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0101303:	81 c3 71 8d 01 00    	add    $0x18d71,%ebx
f0101309:	8b 7d 0c             	mov    0xc(%ebp),%edi
	pde_t * t_pde = &pgdir[PDX(va)];
f010130c:	89 fe                	mov    %edi,%esi
f010130e:	c1 ee 16             	shr    $0x16,%esi
f0101311:	c1 e6 02             	shl    $0x2,%esi
f0101314:	03 75 08             	add    0x8(%ebp),%esi
	if(!(*t_pde & PTE_P) && create){
f0101317:	8b 06                	mov    (%esi),%eax
f0101319:	89 c2                	mov    %eax,%edx
f010131b:	83 e2 01             	and    $0x1,%edx
f010131e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101322:	74 04                	je     f0101328 <pgdir_walk+0x33>
f0101324:	85 d2                	test   %edx,%edx
f0101326:	74 30                	je     f0101358 <pgdir_walk+0x63>
	if(!(*t_pde & PTE_P)){
f0101328:	85 d2                	test   %edx,%edx
f010132a:	74 77                	je     f01013a3 <pgdir_walk+0xae>
	t_pte = KADDR(PTE_ADDR(*t_pde));
f010132c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0101331:	89 c1                	mov    %eax,%ecx
f0101333:	c1 e9 0c             	shr    $0xc,%ecx
f0101336:	c7 c2 e8 a6 11 f0    	mov    $0xf011a6e8,%edx
f010133c:	3b 0a                	cmp    (%edx),%ecx
f010133e:	73 43                	jae    f0101383 <pgdir_walk+0x8e>
	return &t_pte[PTX(va)];
f0101340:	c1 ef 0a             	shr    $0xa,%edi
f0101343:	81 e7 fc 0f 00 00    	and    $0xffc,%edi
f0101349:	8d 84 38 00 00 00 f0 	lea    -0x10000000(%eax,%edi,1),%eax
}
f0101350:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101353:	5b                   	pop    %ebx
f0101354:	5e                   	pop    %esi
f0101355:	5f                   	pop    %edi
f0101356:	5d                   	pop    %ebp
f0101357:	c3                   	ret    
		struct PageInfo * pp = (struct PageInfo *)page_alloc(ALLOC_ZERO);
f0101358:	83 ec 0c             	sub    $0xc,%esp
f010135b:	6a 01                	push   $0x1
f010135d:	e8 8d fe ff ff       	call   f01011ef <page_alloc>
		if(pp == NULL){
f0101362:	83 c4 10             	add    $0x10,%esp
f0101365:	85 c0                	test   %eax,%eax
f0101367:	74 33                	je     f010139c <pgdir_walk+0xa7>
		pp->pp_ref++;
f0101369:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f010136e:	c7 c2 f0 a6 11 f0    	mov    $0xf011a6f0,%edx
f0101374:	2b 02                	sub    (%edx),%eax
f0101376:	c1 f8 03             	sar    $0x3,%eax
f0101379:	c1 e0 0c             	shl    $0xc,%eax
		*t_pde = page2pa(pp) | PTE_P | PTE_W | PTE_U;
f010137c:	83 c8 07             	or     $0x7,%eax
f010137f:	89 06                	mov    %eax,(%esi)
f0101381:	eb a9                	jmp    f010132c <pgdir_walk+0x37>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101383:	50                   	push   %eax
f0101384:	8d 83 58 aa fe ff    	lea    -0x155a8(%ebx),%eax
f010138a:	50                   	push   %eax
f010138b:	68 8a 01 00 00       	push   $0x18a
f0101390:	8d 83 f9 b1 fe ff    	lea    -0x14e07(%ebx),%eax
f0101396:	50                   	push   %eax
f0101397:	e8 fd ec ff ff       	call   f0100099 <_panic>
			return NULL;
f010139c:	b8 00 00 00 00       	mov    $0x0,%eax
f01013a1:	eb ad                	jmp    f0101350 <pgdir_walk+0x5b>
		return NULL;
f01013a3:	b8 00 00 00 00       	mov    $0x0,%eax
f01013a8:	eb a6                	jmp    f0101350 <pgdir_walk+0x5b>

f01013aa <page_lookup>:
{
f01013aa:	55                   	push   %ebp
f01013ab:	89 e5                	mov    %esp,%ebp
f01013ad:	56                   	push   %esi
f01013ae:	53                   	push   %ebx
f01013af:	e8 9b ed ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f01013b4:	81 c3 c0 8c 01 00    	add    $0x18cc0,%ebx
f01013ba:	8b 75 10             	mov    0x10(%ebp),%esi
	pte_t *pte = pgdir_walk(pgdir, va, 0);
f01013bd:	83 ec 04             	sub    $0x4,%esp
f01013c0:	6a 00                	push   $0x0
f01013c2:	ff 75 0c             	pushl  0xc(%ebp)
f01013c5:	ff 75 08             	pushl  0x8(%ebp)
f01013c8:	e8 28 ff ff ff       	call   f01012f5 <pgdir_walk>
	if(!pte){
f01013cd:	83 c4 10             	add    $0x10,%esp
f01013d0:	85 c0                	test   %eax,%eax
f01013d2:	74 43                	je     f0101417 <page_lookup+0x6d>
	if(pte_store){
f01013d4:	85 f6                	test   %esi,%esi
f01013d6:	74 02                	je     f01013da <page_lookup+0x30>
		*pte_store = pte;
f01013d8:	89 06                	mov    %eax,(%esi)
	if(*pte & PTE_P){
f01013da:	8b 00                	mov    (%eax),%eax
f01013dc:	a8 01                	test   $0x1,%al
f01013de:	74 3e                	je     f010141e <page_lookup+0x74>
f01013e0:	c1 e8 0c             	shr    $0xc,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01013e3:	c7 c2 e8 a6 11 f0    	mov    $0xf011a6e8,%edx
f01013e9:	39 02                	cmp    %eax,(%edx)
f01013eb:	76 12                	jbe    f01013ff <page_lookup+0x55>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f01013ed:	c7 c2 f0 a6 11 f0    	mov    $0xf011a6f0,%edx
f01013f3:	8b 12                	mov    (%edx),%edx
f01013f5:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f01013f8:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01013fb:	5b                   	pop    %ebx
f01013fc:	5e                   	pop    %esi
f01013fd:	5d                   	pop    %ebp
f01013fe:	c3                   	ret    
		panic("pa2page called with invalid pa");
f01013ff:	83 ec 04             	sub    $0x4,%esp
f0101402:	8d 83 88 ab fe ff    	lea    -0x15478(%ebx),%eax
f0101408:	50                   	push   %eax
f0101409:	6a 4b                	push   $0x4b
f010140b:	8d 83 05 b2 fe ff    	lea    -0x14dfb(%ebx),%eax
f0101411:	50                   	push   %eax
f0101412:	e8 82 ec ff ff       	call   f0100099 <_panic>
		return NULL;
f0101417:	b8 00 00 00 00       	mov    $0x0,%eax
f010141c:	eb da                	jmp    f01013f8 <page_lookup+0x4e>
		return NULL;
f010141e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101423:	eb d3                	jmp    f01013f8 <page_lookup+0x4e>

f0101425 <page_remove>:
{
f0101425:	55                   	push   %ebp
f0101426:	89 e5                	mov    %esp,%ebp
f0101428:	53                   	push   %ebx
f0101429:	83 ec 18             	sub    $0x18,%esp
f010142c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *pte = NULL;
f010142f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	struct PageInfo * pp = page_lookup(pgdir, va, &pte);
f0101436:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101439:	50                   	push   %eax
f010143a:	53                   	push   %ebx
f010143b:	ff 75 08             	pushl  0x8(%ebp)
f010143e:	e8 67 ff ff ff       	call   f01013aa <page_lookup>
	if(!pp){
f0101443:	83 c4 10             	add    $0x10,%esp
f0101446:	85 c0                	test   %eax,%eax
f0101448:	74 18                	je     f0101462 <page_remove+0x3d>
	page_decref(pp);
f010144a:	83 ec 0c             	sub    $0xc,%esp
f010144d:	50                   	push   %eax
f010144e:	e8 79 fe ff ff       	call   f01012cc <page_decref>
	*pte = 0;
f0101453:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101456:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010145c:	0f 01 3b             	invlpg (%ebx)
f010145f:	83 c4 10             	add    $0x10,%esp
}
f0101462:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101465:	c9                   	leave  
f0101466:	c3                   	ret    

f0101467 <page_insert>:
{
f0101467:	55                   	push   %ebp
f0101468:	89 e5                	mov    %esp,%ebp
f010146a:	57                   	push   %edi
f010146b:	56                   	push   %esi
f010146c:	53                   	push   %ebx
f010146d:	83 ec 10             	sub    $0x10,%esp
f0101470:	e8 7c 1d 00 00       	call   f01031f1 <__x86.get_pc_thunk.di>
f0101475:	81 c7 ff 8b 01 00    	add    $0x18bff,%edi
f010147b:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t *pte = pgdir_walk(pgdir, va, 1);
f010147e:	6a 01                	push   $0x1
f0101480:	ff 75 10             	pushl  0x10(%ebp)
f0101483:	ff 75 08             	pushl  0x8(%ebp)
f0101486:	e8 6a fe ff ff       	call   f01012f5 <pgdir_walk>
	if(!pte){
f010148b:	83 c4 10             	add    $0x10,%esp
f010148e:	85 c0                	test   %eax,%eax
f0101490:	74 3d                	je     f01014cf <page_insert+0x68>
f0101492:	89 c3                	mov    %eax,%ebx
	pp->pp_ref++;
f0101494:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
		page_remove(pgdir, va);
f0101499:	83 ec 08             	sub    $0x8,%esp
f010149c:	ff 75 10             	pushl  0x10(%ebp)
f010149f:	ff 75 08             	pushl  0x8(%ebp)
f01014a2:	e8 7e ff ff ff       	call   f0101425 <page_remove>
	return (pp - pages) << PGSHIFT;
f01014a7:	c7 c0 f0 a6 11 f0    	mov    $0xf011a6f0,%eax
f01014ad:	2b 30                	sub    (%eax),%esi
f01014af:	89 f0                	mov    %esi,%eax
f01014b1:	c1 f8 03             	sar    $0x3,%eax
f01014b4:	c1 e0 0c             	shl    $0xc,%eax
	*pte = page2pa(pp) | perm | PTE_P;
f01014b7:	0b 45 14             	or     0x14(%ebp),%eax
f01014ba:	83 c8 01             	or     $0x1,%eax
f01014bd:	89 03                	mov    %eax,(%ebx)
	return 0;
f01014bf:	83 c4 10             	add    $0x10,%esp
f01014c2:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01014c7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01014ca:	5b                   	pop    %ebx
f01014cb:	5e                   	pop    %esi
f01014cc:	5f                   	pop    %edi
f01014cd:	5d                   	pop    %ebp
f01014ce:	c3                   	ret    
		return -E_NO_MEM;
f01014cf:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f01014d4:	eb f1                	jmp    f01014c7 <page_insert+0x60>

f01014d6 <mem_init>:
{
f01014d6:	55                   	push   %ebp
f01014d7:	89 e5                	mov    %esp,%ebp
f01014d9:	57                   	push   %edi
f01014da:	56                   	push   %esi
f01014db:	53                   	push   %ebx
f01014dc:	83 ec 3c             	sub    $0x3c,%esp
f01014df:	e8 0d 1d 00 00       	call   f01031f1 <__x86.get_pc_thunk.di>
f01014e4:	81 c7 90 8b 01 00    	add    $0x18b90,%edi
	basemem = nvram_read(NVRAM_BASELO);
f01014ea:	b8 15 00 00 00       	mov    $0x15,%eax
f01014ef:	e8 f1 f6 ff ff       	call   f0100be5 <nvram_read>
f01014f4:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f01014f6:	b8 17 00 00 00       	mov    $0x17,%eax
f01014fb:	e8 e5 f6 ff ff       	call   f0100be5 <nvram_read>
f0101500:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0101502:	b8 34 00 00 00       	mov    $0x34,%eax
f0101507:	e8 d9 f6 ff ff       	call   f0100be5 <nvram_read>
	if (ext16mem)
f010150c:	c1 e0 06             	shl    $0x6,%eax
f010150f:	0f 84 ca 00 00 00    	je     f01015df <mem_init+0x109>
		totalmem = 16 * 1024 + ext16mem;
f0101515:	05 00 40 00 00       	add    $0x4000,%eax
	npages = totalmem / (PGSIZE / 1024);
f010151a:	89 c1                	mov    %eax,%ecx
f010151c:	c1 e9 02             	shr    $0x2,%ecx
f010151f:	c7 c2 e8 a6 11 f0    	mov    $0xf011a6e8,%edx
f0101525:	89 0a                	mov    %ecx,(%edx)
	npages_basemem = basemem / (PGSIZE / 1024);
f0101527:	89 da                	mov    %ebx,%edx
f0101529:	c1 ea 02             	shr    $0x2,%edx
f010152c:	89 97 4c 02 00 00    	mov    %edx,0x24c(%edi)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101532:	89 c2                	mov    %eax,%edx
f0101534:	29 da                	sub    %ebx,%edx
f0101536:	52                   	push   %edx
f0101537:	53                   	push   %ebx
f0101538:	50                   	push   %eax
f0101539:	8d 87 a8 ab fe ff    	lea    -0x15458(%edi),%eax
f010153f:	50                   	push   %eax
f0101540:	89 fb                	mov    %edi,%ebx
f0101542:	e8 35 1d 00 00       	call   f010327c <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101547:	b8 00 10 00 00       	mov    $0x1000,%eax
f010154c:	e8 47 f7 ff ff       	call   f0100c98 <boot_alloc>
f0101551:	c7 c6 ec a6 11 f0    	mov    $0xf011a6ec,%esi
f0101557:	89 06                	mov    %eax,(%esi)
	memset(kern_pgdir, 0, PGSIZE);
f0101559:	83 c4 0c             	add    $0xc,%esp
f010155c:	68 00 10 00 00       	push   $0x1000
f0101561:	6a 00                	push   $0x0
f0101563:	50                   	push   %eax
f0101564:	e8 c9 2b 00 00       	call   f0104132 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101569:	8b 06                	mov    (%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f010156b:	83 c4 10             	add    $0x10,%esp
f010156e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101573:	76 7a                	jbe    f01015ef <mem_init+0x119>
	return (physaddr_t)kva - KERNBASE;
f0101575:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010157b:	83 ca 05             	or     $0x5,%edx
f010157e:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = (struct PageInfo *)boot_alloc(npages * sizeof(struct PageInfo));
f0101584:	c7 c3 e8 a6 11 f0    	mov    $0xf011a6e8,%ebx
f010158a:	8b 03                	mov    (%ebx),%eax
f010158c:	c1 e0 03             	shl    $0x3,%eax
f010158f:	e8 04 f7 ff ff       	call   f0100c98 <boot_alloc>
f0101594:	c7 c6 f0 a6 11 f0    	mov    $0xf011a6f0,%esi
f010159a:	89 06                	mov    %eax,(%esi)
	memset(pages, 0, npages*sizeof(struct PageInfo));
f010159c:	83 ec 04             	sub    $0x4,%esp
f010159f:	8b 13                	mov    (%ebx),%edx
f01015a1:	c1 e2 03             	shl    $0x3,%edx
f01015a4:	52                   	push   %edx
f01015a5:	6a 00                	push   $0x0
f01015a7:	50                   	push   %eax
f01015a8:	89 fb                	mov    %edi,%ebx
f01015aa:	e8 83 2b 00 00       	call   f0104132 <memset>
	page_init();
f01015af:	e8 14 fb ff ff       	call   f01010c8 <page_init>
	check_page_free_list(1);
f01015b4:	b8 01 00 00 00       	mov    $0x1,%eax
f01015b9:	e8 90 f7 ff ff       	call   f0100d4e <check_page_free_list>
	if (!pages)
f01015be:	83 c4 10             	add    $0x10,%esp
f01015c1:	83 3e 00             	cmpl   $0x0,(%esi)
f01015c4:	74 42                	je     f0101608 <mem_init+0x132>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01015c6:	8b 87 48 02 00 00    	mov    0x248(%edi),%eax
f01015cc:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f01015d3:	85 c0                	test   %eax,%eax
f01015d5:	74 4c                	je     f0101623 <mem_init+0x14d>
		++nfree;
f01015d7:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01015db:	8b 00                	mov    (%eax),%eax
f01015dd:	eb f4                	jmp    f01015d3 <mem_init+0xfd>
		totalmem = 1 * 1024 + extmem;
f01015df:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01015e5:	85 f6                	test   %esi,%esi
f01015e7:	0f 44 c3             	cmove  %ebx,%eax
f01015ea:	e9 2b ff ff ff       	jmp    f010151a <mem_init+0x44>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01015ef:	50                   	push   %eax
f01015f0:	8d 87 7c aa fe ff    	lea    -0x15584(%edi),%eax
f01015f6:	50                   	push   %eax
f01015f7:	68 9b 00 00 00       	push   $0x9b
f01015fc:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0101602:	50                   	push   %eax
f0101603:	e8 91 ea ff ff       	call   f0100099 <_panic>
		panic("'pages' is a null pointer!");
f0101608:	83 ec 04             	sub    $0x4,%esp
f010160b:	8d 87 cb b2 fe ff    	lea    -0x14d35(%edi),%eax
f0101611:	50                   	push   %eax
f0101612:	68 7c 02 00 00       	push   $0x27c
f0101617:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f010161d:	50                   	push   %eax
f010161e:	e8 76 ea ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0101623:	83 ec 0c             	sub    $0xc,%esp
f0101626:	6a 00                	push   $0x0
f0101628:	e8 c2 fb ff ff       	call   f01011ef <page_alloc>
f010162d:	89 c3                	mov    %eax,%ebx
f010162f:	83 c4 10             	add    $0x10,%esp
f0101632:	85 c0                	test   %eax,%eax
f0101634:	0f 84 28 02 00 00    	je     f0101862 <mem_init+0x38c>
	assert((pp1 = page_alloc(0)));
f010163a:	83 ec 0c             	sub    $0xc,%esp
f010163d:	6a 00                	push   $0x0
f010163f:	e8 ab fb ff ff       	call   f01011ef <page_alloc>
f0101644:	89 c6                	mov    %eax,%esi
f0101646:	83 c4 10             	add    $0x10,%esp
f0101649:	85 c0                	test   %eax,%eax
f010164b:	0f 84 32 02 00 00    	je     f0101883 <mem_init+0x3ad>
	assert((pp2 = page_alloc(0)));
f0101651:	83 ec 0c             	sub    $0xc,%esp
f0101654:	6a 00                	push   $0x0
f0101656:	e8 94 fb ff ff       	call   f01011ef <page_alloc>
f010165b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010165e:	83 c4 10             	add    $0x10,%esp
f0101661:	85 c0                	test   %eax,%eax
f0101663:	0f 84 3b 02 00 00    	je     f01018a4 <mem_init+0x3ce>
	assert(pp1 && pp1 != pp0);
f0101669:	39 f3                	cmp    %esi,%ebx
f010166b:	0f 84 54 02 00 00    	je     f01018c5 <mem_init+0x3ef>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101671:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101674:	39 c6                	cmp    %eax,%esi
f0101676:	0f 84 6a 02 00 00    	je     f01018e6 <mem_init+0x410>
f010167c:	39 c3                	cmp    %eax,%ebx
f010167e:	0f 84 62 02 00 00    	je     f01018e6 <mem_init+0x410>
	return (pp - pages) << PGSHIFT;
f0101684:	c7 c0 f0 a6 11 f0    	mov    $0xf011a6f0,%eax
f010168a:	8b 08                	mov    (%eax),%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f010168c:	c7 c0 e8 a6 11 f0    	mov    $0xf011a6e8,%eax
f0101692:	8b 10                	mov    (%eax),%edx
f0101694:	c1 e2 0c             	shl    $0xc,%edx
f0101697:	89 d8                	mov    %ebx,%eax
f0101699:	29 c8                	sub    %ecx,%eax
f010169b:	c1 f8 03             	sar    $0x3,%eax
f010169e:	c1 e0 0c             	shl    $0xc,%eax
f01016a1:	39 d0                	cmp    %edx,%eax
f01016a3:	0f 83 5e 02 00 00    	jae    f0101907 <mem_init+0x431>
f01016a9:	89 f0                	mov    %esi,%eax
f01016ab:	29 c8                	sub    %ecx,%eax
f01016ad:	c1 f8 03             	sar    $0x3,%eax
f01016b0:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f01016b3:	39 c2                	cmp    %eax,%edx
f01016b5:	0f 86 6d 02 00 00    	jbe    f0101928 <mem_init+0x452>
f01016bb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01016be:	29 c8                	sub    %ecx,%eax
f01016c0:	c1 f8 03             	sar    $0x3,%eax
f01016c3:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f01016c6:	39 c2                	cmp    %eax,%edx
f01016c8:	0f 86 7b 02 00 00    	jbe    f0101949 <mem_init+0x473>
	fl = page_free_list;
f01016ce:	8b 87 48 02 00 00    	mov    0x248(%edi),%eax
f01016d4:	89 45 c8             	mov    %eax,-0x38(%ebp)
	page_free_list = 0;
f01016d7:	c7 87 48 02 00 00 00 	movl   $0x0,0x248(%edi)
f01016de:	00 00 00 
	assert(!page_alloc(0));
f01016e1:	83 ec 0c             	sub    $0xc,%esp
f01016e4:	6a 00                	push   $0x0
f01016e6:	e8 04 fb ff ff       	call   f01011ef <page_alloc>
f01016eb:	83 c4 10             	add    $0x10,%esp
f01016ee:	85 c0                	test   %eax,%eax
f01016f0:	0f 85 74 02 00 00    	jne    f010196a <mem_init+0x494>
	page_free(pp0);
f01016f6:	83 ec 0c             	sub    $0xc,%esp
f01016f9:	53                   	push   %ebx
f01016fa:	e8 7e fb ff ff       	call   f010127d <page_free>
	page_free(pp1);
f01016ff:	89 34 24             	mov    %esi,(%esp)
f0101702:	e8 76 fb ff ff       	call   f010127d <page_free>
	page_free(pp2);
f0101707:	83 c4 04             	add    $0x4,%esp
f010170a:	ff 75 d4             	pushl  -0x2c(%ebp)
f010170d:	e8 6b fb ff ff       	call   f010127d <page_free>
	assert((pp0 = page_alloc(0)));
f0101712:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101719:	e8 d1 fa ff ff       	call   f01011ef <page_alloc>
f010171e:	89 c6                	mov    %eax,%esi
f0101720:	83 c4 10             	add    $0x10,%esp
f0101723:	85 c0                	test   %eax,%eax
f0101725:	0f 84 60 02 00 00    	je     f010198b <mem_init+0x4b5>
	assert((pp1 = page_alloc(0)));
f010172b:	83 ec 0c             	sub    $0xc,%esp
f010172e:	6a 00                	push   $0x0
f0101730:	e8 ba fa ff ff       	call   f01011ef <page_alloc>
f0101735:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101738:	83 c4 10             	add    $0x10,%esp
f010173b:	85 c0                	test   %eax,%eax
f010173d:	0f 84 69 02 00 00    	je     f01019ac <mem_init+0x4d6>
	assert((pp2 = page_alloc(0)));
f0101743:	83 ec 0c             	sub    $0xc,%esp
f0101746:	6a 00                	push   $0x0
f0101748:	e8 a2 fa ff ff       	call   f01011ef <page_alloc>
f010174d:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101750:	83 c4 10             	add    $0x10,%esp
f0101753:	85 c0                	test   %eax,%eax
f0101755:	0f 84 72 02 00 00    	je     f01019cd <mem_init+0x4f7>
	assert(pp1 && pp1 != pp0);
f010175b:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f010175e:	0f 84 8a 02 00 00    	je     f01019ee <mem_init+0x518>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101764:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101767:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010176a:	0f 84 9f 02 00 00    	je     f0101a0f <mem_init+0x539>
f0101770:	39 c6                	cmp    %eax,%esi
f0101772:	0f 84 97 02 00 00    	je     f0101a0f <mem_init+0x539>
	assert(!page_alloc(0));
f0101778:	83 ec 0c             	sub    $0xc,%esp
f010177b:	6a 00                	push   $0x0
f010177d:	e8 6d fa ff ff       	call   f01011ef <page_alloc>
f0101782:	83 c4 10             	add    $0x10,%esp
f0101785:	85 c0                	test   %eax,%eax
f0101787:	0f 85 a3 02 00 00    	jne    f0101a30 <mem_init+0x55a>
f010178d:	c7 c0 f0 a6 11 f0    	mov    $0xf011a6f0,%eax
f0101793:	89 f1                	mov    %esi,%ecx
f0101795:	2b 08                	sub    (%eax),%ecx
f0101797:	89 c8                	mov    %ecx,%eax
f0101799:	c1 f8 03             	sar    $0x3,%eax
f010179c:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f010179f:	89 c1                	mov    %eax,%ecx
f01017a1:	c1 e9 0c             	shr    $0xc,%ecx
f01017a4:	c7 c2 e8 a6 11 f0    	mov    $0xf011a6e8,%edx
f01017aa:	3b 0a                	cmp    (%edx),%ecx
f01017ac:	0f 83 9f 02 00 00    	jae    f0101a51 <mem_init+0x57b>
	memset(page2kva(pp0), 1, PGSIZE);
f01017b2:	83 ec 04             	sub    $0x4,%esp
f01017b5:	68 00 10 00 00       	push   $0x1000
f01017ba:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f01017bc:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01017c1:	50                   	push   %eax
f01017c2:	89 fb                	mov    %edi,%ebx
f01017c4:	e8 69 29 00 00       	call   f0104132 <memset>
	page_free(pp0);
f01017c9:	89 34 24             	mov    %esi,(%esp)
f01017cc:	e8 ac fa ff ff       	call   f010127d <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01017d1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01017d8:	e8 12 fa ff ff       	call   f01011ef <page_alloc>
f01017dd:	83 c4 10             	add    $0x10,%esp
f01017e0:	85 c0                	test   %eax,%eax
f01017e2:	0f 84 81 02 00 00    	je     f0101a69 <mem_init+0x593>
	assert(pp && pp0 == pp);
f01017e8:	39 c6                	cmp    %eax,%esi
f01017ea:	0f 85 98 02 00 00    	jne    f0101a88 <mem_init+0x5b2>
	return (pp - pages) << PGSHIFT;
f01017f0:	c7 c2 f0 a6 11 f0    	mov    $0xf011a6f0,%edx
f01017f6:	2b 02                	sub    (%edx),%eax
f01017f8:	c1 f8 03             	sar    $0x3,%eax
f01017fb:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f01017fe:	89 c1                	mov    %eax,%ecx
f0101800:	c1 e9 0c             	shr    $0xc,%ecx
f0101803:	c7 c2 e8 a6 11 f0    	mov    $0xf011a6e8,%edx
f0101809:	3b 0a                	cmp    (%edx),%ecx
f010180b:	0f 83 96 02 00 00    	jae    f0101aa7 <mem_init+0x5d1>
	return (void *)(pa + KERNBASE);
f0101811:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx
f0101817:	2d 00 f0 ff 0f       	sub    $0xffff000,%eax
		assert(c[i] == 0);
f010181c:	80 3a 00             	cmpb   $0x0,(%edx)
f010181f:	0f 85 98 02 00 00    	jne    f0101abd <mem_init+0x5e7>
f0101825:	83 c2 01             	add    $0x1,%edx
	for (i = 0; i < PGSIZE; i++)
f0101828:	39 c2                	cmp    %eax,%edx
f010182a:	75 f0                	jne    f010181c <mem_init+0x346>
	page_free_list = fl;
f010182c:	8b 45 c8             	mov    -0x38(%ebp),%eax
f010182f:	89 87 48 02 00 00    	mov    %eax,0x248(%edi)
	page_free(pp0);
f0101835:	83 ec 0c             	sub    $0xc,%esp
f0101838:	56                   	push   %esi
f0101839:	e8 3f fa ff ff       	call   f010127d <page_free>
	page_free(pp1);
f010183e:	83 c4 04             	add    $0x4,%esp
f0101841:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101844:	e8 34 fa ff ff       	call   f010127d <page_free>
	page_free(pp2);
f0101849:	83 c4 04             	add    $0x4,%esp
f010184c:	ff 75 cc             	pushl  -0x34(%ebp)
f010184f:	e8 29 fa ff ff       	call   f010127d <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101854:	8b 87 48 02 00 00    	mov    0x248(%edi),%eax
f010185a:	83 c4 10             	add    $0x10,%esp
f010185d:	e9 82 02 00 00       	jmp    f0101ae4 <mem_init+0x60e>
	assert((pp0 = page_alloc(0)));
f0101862:	8d 87 e6 b2 fe ff    	lea    -0x14d1a(%edi),%eax
f0101868:	50                   	push   %eax
f0101869:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f010186f:	50                   	push   %eax
f0101870:	68 84 02 00 00       	push   $0x284
f0101875:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f010187b:	50                   	push   %eax
f010187c:	89 fb                	mov    %edi,%ebx
f010187e:	e8 16 e8 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0101883:	8d 87 fc b2 fe ff    	lea    -0x14d04(%edi),%eax
f0101889:	50                   	push   %eax
f010188a:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0101890:	50                   	push   %eax
f0101891:	68 85 02 00 00       	push   $0x285
f0101896:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f010189c:	50                   	push   %eax
f010189d:	89 fb                	mov    %edi,%ebx
f010189f:	e8 f5 e7 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f01018a4:	8d 87 12 b3 fe ff    	lea    -0x14cee(%edi),%eax
f01018aa:	50                   	push   %eax
f01018ab:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f01018b1:	50                   	push   %eax
f01018b2:	68 86 02 00 00       	push   $0x286
f01018b7:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f01018bd:	50                   	push   %eax
f01018be:	89 fb                	mov    %edi,%ebx
f01018c0:	e8 d4 e7 ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f01018c5:	8d 87 28 b3 fe ff    	lea    -0x14cd8(%edi),%eax
f01018cb:	50                   	push   %eax
f01018cc:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f01018d2:	50                   	push   %eax
f01018d3:	68 89 02 00 00       	push   $0x289
f01018d8:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f01018de:	50                   	push   %eax
f01018df:	89 fb                	mov    %edi,%ebx
f01018e1:	e8 b3 e7 ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01018e6:	8d 87 e4 ab fe ff    	lea    -0x1541c(%edi),%eax
f01018ec:	50                   	push   %eax
f01018ed:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f01018f3:	50                   	push   %eax
f01018f4:	68 8a 02 00 00       	push   $0x28a
f01018f9:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f01018ff:	50                   	push   %eax
f0101900:	89 fb                	mov    %edi,%ebx
f0101902:	e8 92 e7 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f0101907:	8d 87 3a b3 fe ff    	lea    -0x14cc6(%edi),%eax
f010190d:	50                   	push   %eax
f010190e:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0101914:	50                   	push   %eax
f0101915:	68 8b 02 00 00       	push   $0x28b
f010191a:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0101920:	50                   	push   %eax
f0101921:	89 fb                	mov    %edi,%ebx
f0101923:	e8 71 e7 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101928:	8d 87 57 b3 fe ff    	lea    -0x14ca9(%edi),%eax
f010192e:	50                   	push   %eax
f010192f:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0101935:	50                   	push   %eax
f0101936:	68 8c 02 00 00       	push   $0x28c
f010193b:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0101941:	50                   	push   %eax
f0101942:	89 fb                	mov    %edi,%ebx
f0101944:	e8 50 e7 ff ff       	call   f0100099 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101949:	8d 87 74 b3 fe ff    	lea    -0x14c8c(%edi),%eax
f010194f:	50                   	push   %eax
f0101950:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0101956:	50                   	push   %eax
f0101957:	68 8d 02 00 00       	push   $0x28d
f010195c:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0101962:	50                   	push   %eax
f0101963:	89 fb                	mov    %edi,%ebx
f0101965:	e8 2f e7 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f010196a:	8d 87 91 b3 fe ff    	lea    -0x14c6f(%edi),%eax
f0101970:	50                   	push   %eax
f0101971:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0101977:	50                   	push   %eax
f0101978:	68 94 02 00 00       	push   $0x294
f010197d:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0101983:	50                   	push   %eax
f0101984:	89 fb                	mov    %edi,%ebx
f0101986:	e8 0e e7 ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f010198b:	8d 87 e6 b2 fe ff    	lea    -0x14d1a(%edi),%eax
f0101991:	50                   	push   %eax
f0101992:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0101998:	50                   	push   %eax
f0101999:	68 9b 02 00 00       	push   $0x29b
f010199e:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f01019a4:	50                   	push   %eax
f01019a5:	89 fb                	mov    %edi,%ebx
f01019a7:	e8 ed e6 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f01019ac:	8d 87 fc b2 fe ff    	lea    -0x14d04(%edi),%eax
f01019b2:	50                   	push   %eax
f01019b3:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f01019b9:	50                   	push   %eax
f01019ba:	68 9c 02 00 00       	push   $0x29c
f01019bf:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f01019c5:	50                   	push   %eax
f01019c6:	89 fb                	mov    %edi,%ebx
f01019c8:	e8 cc e6 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f01019cd:	8d 87 12 b3 fe ff    	lea    -0x14cee(%edi),%eax
f01019d3:	50                   	push   %eax
f01019d4:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f01019da:	50                   	push   %eax
f01019db:	68 9d 02 00 00       	push   $0x29d
f01019e0:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f01019e6:	50                   	push   %eax
f01019e7:	89 fb                	mov    %edi,%ebx
f01019e9:	e8 ab e6 ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f01019ee:	8d 87 28 b3 fe ff    	lea    -0x14cd8(%edi),%eax
f01019f4:	50                   	push   %eax
f01019f5:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f01019fb:	50                   	push   %eax
f01019fc:	68 9f 02 00 00       	push   $0x29f
f0101a01:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0101a07:	50                   	push   %eax
f0101a08:	89 fb                	mov    %edi,%ebx
f0101a0a:	e8 8a e6 ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101a0f:	8d 87 e4 ab fe ff    	lea    -0x1541c(%edi),%eax
f0101a15:	50                   	push   %eax
f0101a16:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0101a1c:	50                   	push   %eax
f0101a1d:	68 a0 02 00 00       	push   $0x2a0
f0101a22:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0101a28:	50                   	push   %eax
f0101a29:	89 fb                	mov    %edi,%ebx
f0101a2b:	e8 69 e6 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0101a30:	8d 87 91 b3 fe ff    	lea    -0x14c6f(%edi),%eax
f0101a36:	50                   	push   %eax
f0101a37:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0101a3d:	50                   	push   %eax
f0101a3e:	68 a1 02 00 00       	push   $0x2a1
f0101a43:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0101a49:	50                   	push   %eax
f0101a4a:	89 fb                	mov    %edi,%ebx
f0101a4c:	e8 48 e6 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101a51:	50                   	push   %eax
f0101a52:	8d 87 58 aa fe ff    	lea    -0x155a8(%edi),%eax
f0101a58:	50                   	push   %eax
f0101a59:	6a 52                	push   $0x52
f0101a5b:	8d 87 05 b2 fe ff    	lea    -0x14dfb(%edi),%eax
f0101a61:	50                   	push   %eax
f0101a62:	89 fb                	mov    %edi,%ebx
f0101a64:	e8 30 e6 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101a69:	8d 87 a0 b3 fe ff    	lea    -0x14c60(%edi),%eax
f0101a6f:	50                   	push   %eax
f0101a70:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0101a76:	50                   	push   %eax
f0101a77:	68 a6 02 00 00       	push   $0x2a6
f0101a7c:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0101a82:	50                   	push   %eax
f0101a83:	e8 11 e6 ff ff       	call   f0100099 <_panic>
	assert(pp && pp0 == pp);
f0101a88:	8d 87 be b3 fe ff    	lea    -0x14c42(%edi),%eax
f0101a8e:	50                   	push   %eax
f0101a8f:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0101a95:	50                   	push   %eax
f0101a96:	68 a7 02 00 00       	push   $0x2a7
f0101a9b:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0101aa1:	50                   	push   %eax
f0101aa2:	e8 f2 e5 ff ff       	call   f0100099 <_panic>
f0101aa7:	50                   	push   %eax
f0101aa8:	8d 87 58 aa fe ff    	lea    -0x155a8(%edi),%eax
f0101aae:	50                   	push   %eax
f0101aaf:	6a 52                	push   $0x52
f0101ab1:	8d 87 05 b2 fe ff    	lea    -0x14dfb(%edi),%eax
f0101ab7:	50                   	push   %eax
f0101ab8:	e8 dc e5 ff ff       	call   f0100099 <_panic>
		assert(c[i] == 0);
f0101abd:	8d 87 ce b3 fe ff    	lea    -0x14c32(%edi),%eax
f0101ac3:	50                   	push   %eax
f0101ac4:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0101aca:	50                   	push   %eax
f0101acb:	68 aa 02 00 00       	push   $0x2aa
f0101ad0:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0101ad6:	50                   	push   %eax
f0101ad7:	89 fb                	mov    %edi,%ebx
f0101ad9:	e8 bb e5 ff ff       	call   f0100099 <_panic>
		--nfree;
f0101ade:	83 6d d0 01          	subl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101ae2:	8b 00                	mov    (%eax),%eax
f0101ae4:	85 c0                	test   %eax,%eax
f0101ae6:	75 f6                	jne    f0101ade <mem_init+0x608>
	assert(nfree == 0);
f0101ae8:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0101aec:	0f 85 65 08 00 00    	jne    f0102357 <mem_init+0xe81>
	cprintf("check_page_alloc() succeeded!\n");
f0101af2:	83 ec 0c             	sub    $0xc,%esp
f0101af5:	8d 87 04 ac fe ff    	lea    -0x153fc(%edi),%eax
f0101afb:	50                   	push   %eax
f0101afc:	89 fb                	mov    %edi,%ebx
f0101afe:	e8 79 17 00 00       	call   f010327c <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101b03:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b0a:	e8 e0 f6 ff ff       	call   f01011ef <page_alloc>
f0101b0f:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101b12:	83 c4 10             	add    $0x10,%esp
f0101b15:	85 c0                	test   %eax,%eax
f0101b17:	0f 84 5b 08 00 00    	je     f0102378 <mem_init+0xea2>
	assert((pp1 = page_alloc(0)));
f0101b1d:	83 ec 0c             	sub    $0xc,%esp
f0101b20:	6a 00                	push   $0x0
f0101b22:	e8 c8 f6 ff ff       	call   f01011ef <page_alloc>
f0101b27:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101b2a:	83 c4 10             	add    $0x10,%esp
f0101b2d:	85 c0                	test   %eax,%eax
f0101b2f:	0f 84 62 08 00 00    	je     f0102397 <mem_init+0xec1>
	assert((pp2 = page_alloc(0)));
f0101b35:	83 ec 0c             	sub    $0xc,%esp
f0101b38:	6a 00                	push   $0x0
f0101b3a:	e8 b0 f6 ff ff       	call   f01011ef <page_alloc>
f0101b3f:	89 c6                	mov    %eax,%esi
f0101b41:	83 c4 10             	add    $0x10,%esp
f0101b44:	85 c0                	test   %eax,%eax
f0101b46:	0f 84 6a 08 00 00    	je     f01023b6 <mem_init+0xee0>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101b4c:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101b4f:	39 4d d0             	cmp    %ecx,-0x30(%ebp)
f0101b52:	0f 84 7d 08 00 00    	je     f01023d5 <mem_init+0xeff>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101b58:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101b5b:	0f 84 93 08 00 00    	je     f01023f4 <mem_init+0xf1e>
f0101b61:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101b64:	0f 84 8a 08 00 00    	je     f01023f4 <mem_init+0xf1e>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101b6a:	8b 87 48 02 00 00    	mov    0x248(%edi),%eax
f0101b70:	89 45 c8             	mov    %eax,-0x38(%ebp)
	page_free_list = 0;
f0101b73:	c7 87 48 02 00 00 00 	movl   $0x0,0x248(%edi)
f0101b7a:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101b7d:	83 ec 0c             	sub    $0xc,%esp
f0101b80:	6a 00                	push   $0x0
f0101b82:	e8 68 f6 ff ff       	call   f01011ef <page_alloc>
f0101b87:	83 c4 10             	add    $0x10,%esp
f0101b8a:	85 c0                	test   %eax,%eax
f0101b8c:	0f 85 83 08 00 00    	jne    f0102415 <mem_init+0xf3f>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101b92:	83 ec 04             	sub    $0x4,%esp
f0101b95:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101b98:	50                   	push   %eax
f0101b99:	6a 00                	push   $0x0
f0101b9b:	c7 c0 ec a6 11 f0    	mov    $0xf011a6ec,%eax
f0101ba1:	ff 30                	pushl  (%eax)
f0101ba3:	e8 02 f8 ff ff       	call   f01013aa <page_lookup>
f0101ba8:	83 c4 10             	add    $0x10,%esp
f0101bab:	85 c0                	test   %eax,%eax
f0101bad:	0f 85 81 08 00 00    	jne    f0102434 <mem_init+0xf5e>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101bb3:	6a 02                	push   $0x2
f0101bb5:	6a 00                	push   $0x0
f0101bb7:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101bba:	c7 c0 ec a6 11 f0    	mov    $0xf011a6ec,%eax
f0101bc0:	ff 30                	pushl  (%eax)
f0101bc2:	e8 a0 f8 ff ff       	call   f0101467 <page_insert>
f0101bc7:	83 c4 10             	add    $0x10,%esp
f0101bca:	85 c0                	test   %eax,%eax
f0101bcc:	0f 89 81 08 00 00    	jns    f0102453 <mem_init+0xf7d>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101bd2:	83 ec 0c             	sub    $0xc,%esp
f0101bd5:	ff 75 d0             	pushl  -0x30(%ebp)
f0101bd8:	e8 a0 f6 ff ff       	call   f010127d <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101bdd:	6a 02                	push   $0x2
f0101bdf:	6a 00                	push   $0x0
f0101be1:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101be4:	c7 c0 ec a6 11 f0    	mov    $0xf011a6ec,%eax
f0101bea:	ff 30                	pushl  (%eax)
f0101bec:	e8 76 f8 ff ff       	call   f0101467 <page_insert>
f0101bf1:	83 c4 20             	add    $0x20,%esp
f0101bf4:	85 c0                	test   %eax,%eax
f0101bf6:	0f 85 76 08 00 00    	jne    f0102472 <mem_init+0xf9c>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101bfc:	c7 c0 ec a6 11 f0    	mov    $0xf011a6ec,%eax
f0101c02:	8b 18                	mov    (%eax),%ebx
	return (pp - pages) << PGSHIFT;
f0101c04:	c7 c0 f0 a6 11 f0    	mov    $0xf011a6f0,%eax
f0101c0a:	8b 08                	mov    (%eax),%ecx
f0101c0c:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0101c0f:	8b 13                	mov    (%ebx),%edx
f0101c11:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101c17:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101c1a:	29 c8                	sub    %ecx,%eax
f0101c1c:	c1 f8 03             	sar    $0x3,%eax
f0101c1f:	c1 e0 0c             	shl    $0xc,%eax
f0101c22:	39 c2                	cmp    %eax,%edx
f0101c24:	0f 85 67 08 00 00    	jne    f0102491 <mem_init+0xfbb>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101c2a:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c2f:	89 d8                	mov    %ebx,%eax
f0101c31:	e8 e5 ef ff ff       	call   f0100c1b <check_va2pa>
f0101c36:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101c39:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101c3c:	c1 fa 03             	sar    $0x3,%edx
f0101c3f:	c1 e2 0c             	shl    $0xc,%edx
f0101c42:	39 d0                	cmp    %edx,%eax
f0101c44:	0f 85 68 08 00 00    	jne    f01024b2 <mem_init+0xfdc>
	assert(pp1->pp_ref == 1);
f0101c4a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c4d:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101c52:	0f 85 7b 08 00 00    	jne    f01024d3 <mem_init+0xffd>
	assert(pp0->pp_ref == 1);
f0101c58:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101c5b:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101c60:	0f 85 8e 08 00 00    	jne    f01024f4 <mem_init+0x101e>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c66:	6a 02                	push   $0x2
f0101c68:	68 00 10 00 00       	push   $0x1000
f0101c6d:	56                   	push   %esi
f0101c6e:	53                   	push   %ebx
f0101c6f:	e8 f3 f7 ff ff       	call   f0101467 <page_insert>
f0101c74:	83 c4 10             	add    $0x10,%esp
f0101c77:	85 c0                	test   %eax,%eax
f0101c79:	0f 85 96 08 00 00    	jne    f0102515 <mem_init+0x103f>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c7f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c84:	c7 c0 ec a6 11 f0    	mov    $0xf011a6ec,%eax
f0101c8a:	8b 00                	mov    (%eax),%eax
f0101c8c:	e8 8a ef ff ff       	call   f0100c1b <check_va2pa>
f0101c91:	c7 c2 f0 a6 11 f0    	mov    $0xf011a6f0,%edx
f0101c97:	89 f1                	mov    %esi,%ecx
f0101c99:	2b 0a                	sub    (%edx),%ecx
f0101c9b:	89 ca                	mov    %ecx,%edx
f0101c9d:	c1 fa 03             	sar    $0x3,%edx
f0101ca0:	c1 e2 0c             	shl    $0xc,%edx
f0101ca3:	39 d0                	cmp    %edx,%eax
f0101ca5:	0f 85 8b 08 00 00    	jne    f0102536 <mem_init+0x1060>
	assert(pp2->pp_ref == 1);
f0101cab:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101cb0:	0f 85 a1 08 00 00    	jne    f0102557 <mem_init+0x1081>

	// should be no free memory
	assert(!page_alloc(0));
f0101cb6:	83 ec 0c             	sub    $0xc,%esp
f0101cb9:	6a 00                	push   $0x0
f0101cbb:	e8 2f f5 ff ff       	call   f01011ef <page_alloc>
f0101cc0:	83 c4 10             	add    $0x10,%esp
f0101cc3:	85 c0                	test   %eax,%eax
f0101cc5:	0f 85 ad 08 00 00    	jne    f0102578 <mem_init+0x10a2>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ccb:	6a 02                	push   $0x2
f0101ccd:	68 00 10 00 00       	push   $0x1000
f0101cd2:	56                   	push   %esi
f0101cd3:	c7 c0 ec a6 11 f0    	mov    $0xf011a6ec,%eax
f0101cd9:	ff 30                	pushl  (%eax)
f0101cdb:	e8 87 f7 ff ff       	call   f0101467 <page_insert>
f0101ce0:	83 c4 10             	add    $0x10,%esp
f0101ce3:	85 c0                	test   %eax,%eax
f0101ce5:	0f 85 ae 08 00 00    	jne    f0102599 <mem_init+0x10c3>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ceb:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cf0:	c7 c0 ec a6 11 f0    	mov    $0xf011a6ec,%eax
f0101cf6:	8b 00                	mov    (%eax),%eax
f0101cf8:	e8 1e ef ff ff       	call   f0100c1b <check_va2pa>
f0101cfd:	c7 c2 f0 a6 11 f0    	mov    $0xf011a6f0,%edx
f0101d03:	89 f1                	mov    %esi,%ecx
f0101d05:	2b 0a                	sub    (%edx),%ecx
f0101d07:	89 ca                	mov    %ecx,%edx
f0101d09:	c1 fa 03             	sar    $0x3,%edx
f0101d0c:	c1 e2 0c             	shl    $0xc,%edx
f0101d0f:	39 d0                	cmp    %edx,%eax
f0101d11:	0f 85 a3 08 00 00    	jne    f01025ba <mem_init+0x10e4>
	assert(pp2->pp_ref == 1);
f0101d17:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d1c:	0f 85 b9 08 00 00    	jne    f01025db <mem_init+0x1105>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101d22:	83 ec 0c             	sub    $0xc,%esp
f0101d25:	6a 00                	push   $0x0
f0101d27:	e8 c3 f4 ff ff       	call   f01011ef <page_alloc>
f0101d2c:	83 c4 10             	add    $0x10,%esp
f0101d2f:	85 c0                	test   %eax,%eax
f0101d31:	0f 85 c5 08 00 00    	jne    f01025fc <mem_init+0x1126>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101d37:	c7 c0 ec a6 11 f0    	mov    $0xf011a6ec,%eax
f0101d3d:	8b 10                	mov    (%eax),%edx
f0101d3f:	8b 02                	mov    (%edx),%eax
f0101d41:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0101d46:	89 c3                	mov    %eax,%ebx
f0101d48:	c1 eb 0c             	shr    $0xc,%ebx
f0101d4b:	c7 c1 e8 a6 11 f0    	mov    $0xf011a6e8,%ecx
f0101d51:	3b 19                	cmp    (%ecx),%ebx
f0101d53:	0f 83 c4 08 00 00    	jae    f010261d <mem_init+0x1147>
	return (void *)(pa + KERNBASE);
f0101d59:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101d5e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101d61:	83 ec 04             	sub    $0x4,%esp
f0101d64:	6a 00                	push   $0x0
f0101d66:	68 00 10 00 00       	push   $0x1000
f0101d6b:	52                   	push   %edx
f0101d6c:	e8 84 f5 ff ff       	call   f01012f5 <pgdir_walk>
f0101d71:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101d74:	8d 51 04             	lea    0x4(%ecx),%edx
f0101d77:	83 c4 10             	add    $0x10,%esp
f0101d7a:	39 d0                	cmp    %edx,%eax
f0101d7c:	0f 85 b6 08 00 00    	jne    f0102638 <mem_init+0x1162>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101d82:	6a 06                	push   $0x6
f0101d84:	68 00 10 00 00       	push   $0x1000
f0101d89:	56                   	push   %esi
f0101d8a:	c7 c0 ec a6 11 f0    	mov    $0xf011a6ec,%eax
f0101d90:	ff 30                	pushl  (%eax)
f0101d92:	e8 d0 f6 ff ff       	call   f0101467 <page_insert>
f0101d97:	83 c4 10             	add    $0x10,%esp
f0101d9a:	85 c0                	test   %eax,%eax
f0101d9c:	0f 85 b7 08 00 00    	jne    f0102659 <mem_init+0x1183>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101da2:	c7 c0 ec a6 11 f0    	mov    $0xf011a6ec,%eax
f0101da8:	8b 18                	mov    (%eax),%ebx
f0101daa:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101daf:	89 d8                	mov    %ebx,%eax
f0101db1:	e8 65 ee ff ff       	call   f0100c1b <check_va2pa>
	return (pp - pages) << PGSHIFT;
f0101db6:	c7 c2 f0 a6 11 f0    	mov    $0xf011a6f0,%edx
f0101dbc:	89 f1                	mov    %esi,%ecx
f0101dbe:	2b 0a                	sub    (%edx),%ecx
f0101dc0:	89 ca                	mov    %ecx,%edx
f0101dc2:	c1 fa 03             	sar    $0x3,%edx
f0101dc5:	c1 e2 0c             	shl    $0xc,%edx
f0101dc8:	39 d0                	cmp    %edx,%eax
f0101dca:	0f 85 aa 08 00 00    	jne    f010267a <mem_init+0x11a4>
	assert(pp2->pp_ref == 1);
f0101dd0:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101dd5:	0f 85 c0 08 00 00    	jne    f010269b <mem_init+0x11c5>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101ddb:	83 ec 04             	sub    $0x4,%esp
f0101dde:	6a 00                	push   $0x0
f0101de0:	68 00 10 00 00       	push   $0x1000
f0101de5:	53                   	push   %ebx
f0101de6:	e8 0a f5 ff ff       	call   f01012f5 <pgdir_walk>
f0101deb:	83 c4 10             	add    $0x10,%esp
f0101dee:	f6 00 04             	testb  $0x4,(%eax)
f0101df1:	0f 84 c5 08 00 00    	je     f01026bc <mem_init+0x11e6>
	assert(kern_pgdir[0] & PTE_U);
f0101df7:	c7 c0 ec a6 11 f0    	mov    $0xf011a6ec,%eax
f0101dfd:	8b 00                	mov    (%eax),%eax
f0101dff:	f6 00 04             	testb  $0x4,(%eax)
f0101e02:	0f 84 d5 08 00 00    	je     f01026dd <mem_init+0x1207>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101e08:	6a 02                	push   $0x2
f0101e0a:	68 00 10 00 00       	push   $0x1000
f0101e0f:	56                   	push   %esi
f0101e10:	50                   	push   %eax
f0101e11:	e8 51 f6 ff ff       	call   f0101467 <page_insert>
f0101e16:	83 c4 10             	add    $0x10,%esp
f0101e19:	85 c0                	test   %eax,%eax
f0101e1b:	0f 85 dd 08 00 00    	jne    f01026fe <mem_init+0x1228>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101e21:	83 ec 04             	sub    $0x4,%esp
f0101e24:	6a 00                	push   $0x0
f0101e26:	68 00 10 00 00       	push   $0x1000
f0101e2b:	c7 c0 ec a6 11 f0    	mov    $0xf011a6ec,%eax
f0101e31:	ff 30                	pushl  (%eax)
f0101e33:	e8 bd f4 ff ff       	call   f01012f5 <pgdir_walk>
f0101e38:	83 c4 10             	add    $0x10,%esp
f0101e3b:	f6 00 02             	testb  $0x2,(%eax)
f0101e3e:	0f 84 db 08 00 00    	je     f010271f <mem_init+0x1249>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101e44:	83 ec 04             	sub    $0x4,%esp
f0101e47:	6a 00                	push   $0x0
f0101e49:	68 00 10 00 00       	push   $0x1000
f0101e4e:	c7 c0 ec a6 11 f0    	mov    $0xf011a6ec,%eax
f0101e54:	ff 30                	pushl  (%eax)
f0101e56:	e8 9a f4 ff ff       	call   f01012f5 <pgdir_walk>
f0101e5b:	83 c4 10             	add    $0x10,%esp
f0101e5e:	f6 00 04             	testb  $0x4,(%eax)
f0101e61:	0f 85 d9 08 00 00    	jne    f0102740 <mem_init+0x126a>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101e67:	6a 02                	push   $0x2
f0101e69:	68 00 00 40 00       	push   $0x400000
f0101e6e:	ff 75 d0             	pushl  -0x30(%ebp)
f0101e71:	c7 c0 ec a6 11 f0    	mov    $0xf011a6ec,%eax
f0101e77:	ff 30                	pushl  (%eax)
f0101e79:	e8 e9 f5 ff ff       	call   f0101467 <page_insert>
f0101e7e:	83 c4 10             	add    $0x10,%esp
f0101e81:	85 c0                	test   %eax,%eax
f0101e83:	0f 89 d8 08 00 00    	jns    f0102761 <mem_init+0x128b>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101e89:	6a 02                	push   $0x2
f0101e8b:	68 00 10 00 00       	push   $0x1000
f0101e90:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101e93:	c7 c0 ec a6 11 f0    	mov    $0xf011a6ec,%eax
f0101e99:	ff 30                	pushl  (%eax)
f0101e9b:	e8 c7 f5 ff ff       	call   f0101467 <page_insert>
f0101ea0:	83 c4 10             	add    $0x10,%esp
f0101ea3:	85 c0                	test   %eax,%eax
f0101ea5:	0f 85 d7 08 00 00    	jne    f0102782 <mem_init+0x12ac>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101eab:	83 ec 04             	sub    $0x4,%esp
f0101eae:	6a 00                	push   $0x0
f0101eb0:	68 00 10 00 00       	push   $0x1000
f0101eb5:	c7 c0 ec a6 11 f0    	mov    $0xf011a6ec,%eax
f0101ebb:	ff 30                	pushl  (%eax)
f0101ebd:	e8 33 f4 ff ff       	call   f01012f5 <pgdir_walk>
f0101ec2:	83 c4 10             	add    $0x10,%esp
f0101ec5:	f6 00 04             	testb  $0x4,(%eax)
f0101ec8:	0f 85 d5 08 00 00    	jne    f01027a3 <mem_init+0x12cd>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101ece:	c7 c0 ec a6 11 f0    	mov    $0xf011a6ec,%eax
f0101ed4:	8b 00                	mov    (%eax),%eax
f0101ed6:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101ed9:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ede:	e8 38 ed ff ff       	call   f0100c1b <check_va2pa>
f0101ee3:	c7 c2 f0 a6 11 f0    	mov    $0xf011a6f0,%edx
f0101ee9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101eec:	2b 1a                	sub    (%edx),%ebx
f0101eee:	c1 fb 03             	sar    $0x3,%ebx
f0101ef1:	c1 e3 0c             	shl    $0xc,%ebx
f0101ef4:	39 d8                	cmp    %ebx,%eax
f0101ef6:	0f 85 c8 08 00 00    	jne    f01027c4 <mem_init+0x12ee>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101efc:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f01:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101f04:	e8 12 ed ff ff       	call   f0100c1b <check_va2pa>
f0101f09:	39 c3                	cmp    %eax,%ebx
f0101f0b:	0f 85 d4 08 00 00    	jne    f01027e5 <mem_init+0x130f>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101f11:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f14:	66 83 78 04 02       	cmpw   $0x2,0x4(%eax)
f0101f19:	0f 85 e7 08 00 00    	jne    f0102806 <mem_init+0x1330>
	assert(pp2->pp_ref == 0);
f0101f1f:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101f24:	0f 85 fd 08 00 00    	jne    f0102827 <mem_init+0x1351>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101f2a:	83 ec 0c             	sub    $0xc,%esp
f0101f2d:	6a 00                	push   $0x0
f0101f2f:	e8 bb f2 ff ff       	call   f01011ef <page_alloc>
f0101f34:	83 c4 10             	add    $0x10,%esp
f0101f37:	39 c6                	cmp    %eax,%esi
f0101f39:	0f 85 09 09 00 00    	jne    f0102848 <mem_init+0x1372>
f0101f3f:	85 c0                	test   %eax,%eax
f0101f41:	0f 84 01 09 00 00    	je     f0102848 <mem_init+0x1372>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101f47:	83 ec 08             	sub    $0x8,%esp
f0101f4a:	6a 00                	push   $0x0
f0101f4c:	c7 c3 ec a6 11 f0    	mov    $0xf011a6ec,%ebx
f0101f52:	ff 33                	pushl  (%ebx)
f0101f54:	e8 cc f4 ff ff       	call   f0101425 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f59:	8b 1b                	mov    (%ebx),%ebx
f0101f5b:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f60:	89 d8                	mov    %ebx,%eax
f0101f62:	e8 b4 ec ff ff       	call   f0100c1b <check_va2pa>
f0101f67:	83 c4 10             	add    $0x10,%esp
f0101f6a:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f6d:	0f 85 f6 08 00 00    	jne    f0102869 <mem_init+0x1393>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101f73:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f78:	89 d8                	mov    %ebx,%eax
f0101f7a:	e8 9c ec ff ff       	call   f0100c1b <check_va2pa>
f0101f7f:	c7 c2 f0 a6 11 f0    	mov    $0xf011a6f0,%edx
f0101f85:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101f88:	2b 0a                	sub    (%edx),%ecx
f0101f8a:	89 ca                	mov    %ecx,%edx
f0101f8c:	c1 fa 03             	sar    $0x3,%edx
f0101f8f:	c1 e2 0c             	shl    $0xc,%edx
f0101f92:	39 d0                	cmp    %edx,%eax
f0101f94:	0f 85 f0 08 00 00    	jne    f010288a <mem_init+0x13b4>
	assert(pp1->pp_ref == 1);
f0101f9a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f9d:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101fa2:	0f 85 03 09 00 00    	jne    f01028ab <mem_init+0x13d5>
	assert(pp2->pp_ref == 0);
f0101fa8:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101fad:	0f 85 19 09 00 00    	jne    f01028cc <mem_init+0x13f6>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101fb3:	6a 00                	push   $0x0
f0101fb5:	68 00 10 00 00       	push   $0x1000
f0101fba:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101fbd:	53                   	push   %ebx
f0101fbe:	e8 a4 f4 ff ff       	call   f0101467 <page_insert>
f0101fc3:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0101fc6:	83 c4 10             	add    $0x10,%esp
f0101fc9:	85 c0                	test   %eax,%eax
f0101fcb:	0f 85 1c 09 00 00    	jne    f01028ed <mem_init+0x1417>
	assert(pp1->pp_ref);
f0101fd1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fd4:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101fd9:	0f 84 2f 09 00 00    	je     f010290e <mem_init+0x1438>
	assert(pp1->pp_link == NULL);
f0101fdf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fe2:	83 38 00             	cmpl   $0x0,(%eax)
f0101fe5:	0f 85 44 09 00 00    	jne    f010292f <mem_init+0x1459>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101feb:	83 ec 08             	sub    $0x8,%esp
f0101fee:	68 00 10 00 00       	push   $0x1000
f0101ff3:	c7 c3 ec a6 11 f0    	mov    $0xf011a6ec,%ebx
f0101ff9:	ff 33                	pushl  (%ebx)
f0101ffb:	e8 25 f4 ff ff       	call   f0101425 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102000:	8b 1b                	mov    (%ebx),%ebx
f0102002:	ba 00 00 00 00       	mov    $0x0,%edx
f0102007:	89 d8                	mov    %ebx,%eax
f0102009:	e8 0d ec ff ff       	call   f0100c1b <check_va2pa>
f010200e:	83 c4 10             	add    $0x10,%esp
f0102011:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102014:	0f 85 36 09 00 00    	jne    f0102950 <mem_init+0x147a>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f010201a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010201f:	89 d8                	mov    %ebx,%eax
f0102021:	e8 f5 eb ff ff       	call   f0100c1b <check_va2pa>
f0102026:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102029:	0f 85 42 09 00 00    	jne    f0102971 <mem_init+0x149b>
	assert(pp1->pp_ref == 0);
f010202f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102032:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102037:	0f 85 55 09 00 00    	jne    f0102992 <mem_init+0x14bc>
	assert(pp2->pp_ref == 0);
f010203d:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102042:	0f 85 6b 09 00 00    	jne    f01029b3 <mem_init+0x14dd>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102048:	83 ec 0c             	sub    $0xc,%esp
f010204b:	6a 00                	push   $0x0
f010204d:	e8 9d f1 ff ff       	call   f01011ef <page_alloc>
f0102052:	83 c4 10             	add    $0x10,%esp
f0102055:	85 c0                	test   %eax,%eax
f0102057:	0f 84 77 09 00 00    	je     f01029d4 <mem_init+0x14fe>
f010205d:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0102060:	0f 85 6e 09 00 00    	jne    f01029d4 <mem_init+0x14fe>

	// should be no free memory
	assert(!page_alloc(0));
f0102066:	83 ec 0c             	sub    $0xc,%esp
f0102069:	6a 00                	push   $0x0
f010206b:	e8 7f f1 ff ff       	call   f01011ef <page_alloc>
f0102070:	83 c4 10             	add    $0x10,%esp
f0102073:	85 c0                	test   %eax,%eax
f0102075:	0f 85 7a 09 00 00    	jne    f01029f5 <mem_init+0x151f>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010207b:	c7 c0 ec a6 11 f0    	mov    $0xf011a6ec,%eax
f0102081:	8b 08                	mov    (%eax),%ecx
f0102083:	8b 11                	mov    (%ecx),%edx
f0102085:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010208b:	c7 c0 f0 a6 11 f0    	mov    $0xf011a6f0,%eax
f0102091:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0102094:	2b 18                	sub    (%eax),%ebx
f0102096:	89 d8                	mov    %ebx,%eax
f0102098:	c1 f8 03             	sar    $0x3,%eax
f010209b:	c1 e0 0c             	shl    $0xc,%eax
f010209e:	39 c2                	cmp    %eax,%edx
f01020a0:	0f 85 70 09 00 00    	jne    f0102a16 <mem_init+0x1540>
	kern_pgdir[0] = 0;
f01020a6:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01020ac:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01020af:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01020b4:	0f 85 7d 09 00 00    	jne    f0102a37 <mem_init+0x1561>
	pp0->pp_ref = 0;
f01020ba:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01020bd:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01020c3:	83 ec 0c             	sub    $0xc,%esp
f01020c6:	50                   	push   %eax
f01020c7:	e8 b1 f1 ff ff       	call   f010127d <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01020cc:	83 c4 0c             	add    $0xc,%esp
f01020cf:	6a 01                	push   $0x1
f01020d1:	68 00 10 40 00       	push   $0x401000
f01020d6:	c7 c3 ec a6 11 f0    	mov    $0xf011a6ec,%ebx
f01020dc:	ff 33                	pushl  (%ebx)
f01020de:	e8 12 f2 ff ff       	call   f01012f5 <pgdir_walk>
f01020e3:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01020e6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01020e9:	8b 1b                	mov    (%ebx),%ebx
f01020eb:	8b 53 04             	mov    0x4(%ebx),%edx
f01020ee:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f01020f4:	c7 c1 e8 a6 11 f0    	mov    $0xf011a6e8,%ecx
f01020fa:	8b 09                	mov    (%ecx),%ecx
f01020fc:	89 d0                	mov    %edx,%eax
f01020fe:	c1 e8 0c             	shr    $0xc,%eax
f0102101:	83 c4 10             	add    $0x10,%esp
f0102104:	39 c8                	cmp    %ecx,%eax
f0102106:	0f 83 4c 09 00 00    	jae    f0102a58 <mem_init+0x1582>
	assert(ptep == ptep1 + PTX(va));
f010210c:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0102112:	39 55 cc             	cmp    %edx,-0x34(%ebp)
f0102115:	0f 85 58 09 00 00    	jne    f0102a73 <mem_init+0x159d>
	kern_pgdir[PDX(va)] = 0;
f010211b:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	pp0->pp_ref = 0;
f0102122:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0102125:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
	return (pp - pages) << PGSHIFT;
f010212b:	c7 c0 f0 a6 11 f0    	mov    $0xf011a6f0,%eax
f0102131:	2b 18                	sub    (%eax),%ebx
f0102133:	89 d8                	mov    %ebx,%eax
f0102135:	c1 f8 03             	sar    $0x3,%eax
f0102138:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f010213b:	89 c2                	mov    %eax,%edx
f010213d:	c1 ea 0c             	shr    $0xc,%edx
f0102140:	39 d1                	cmp    %edx,%ecx
f0102142:	0f 86 4c 09 00 00    	jbe    f0102a94 <mem_init+0x15be>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102148:	83 ec 04             	sub    $0x4,%esp
f010214b:	68 00 10 00 00       	push   $0x1000
f0102150:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f0102155:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010215a:	50                   	push   %eax
f010215b:	89 fb                	mov    %edi,%ebx
f010215d:	e8 d0 1f 00 00       	call   f0104132 <memset>
	page_free(pp0);
f0102162:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0102165:	89 1c 24             	mov    %ebx,(%esp)
f0102168:	e8 10 f1 ff ff       	call   f010127d <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010216d:	83 c4 0c             	add    $0xc,%esp
f0102170:	6a 01                	push   $0x1
f0102172:	6a 00                	push   $0x0
f0102174:	c7 c0 ec a6 11 f0    	mov    $0xf011a6ec,%eax
f010217a:	ff 30                	pushl  (%eax)
f010217c:	e8 74 f1 ff ff       	call   f01012f5 <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f0102181:	c7 c0 f0 a6 11 f0    	mov    $0xf011a6f0,%eax
f0102187:	2b 18                	sub    (%eax),%ebx
f0102189:	89 d8                	mov    %ebx,%eax
f010218b:	c1 f8 03             	sar    $0x3,%eax
f010218e:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102191:	89 c1                	mov    %eax,%ecx
f0102193:	c1 e9 0c             	shr    $0xc,%ecx
f0102196:	83 c4 10             	add    $0x10,%esp
f0102199:	c7 c2 e8 a6 11 f0    	mov    $0xf011a6e8,%edx
f010219f:	3b 0a                	cmp    (%edx),%ecx
f01021a1:	0f 83 05 09 00 00    	jae    f0102aac <mem_init+0x15d6>
	return (void *)(pa + KERNBASE);
f01021a7:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx
	ptep = (pte_t *) page2kva(pp0);
f01021ad:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01021b0:	2d 00 f0 ff 0f       	sub    $0xffff000,%eax
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01021b5:	f6 02 01             	testb  $0x1,(%edx)
f01021b8:	0f 85 06 09 00 00    	jne    f0102ac4 <mem_init+0x15ee>
f01021be:	83 c2 04             	add    $0x4,%edx
	for(i=0; i<NPTENTRIES; i++)
f01021c1:	39 c2                	cmp    %eax,%edx
f01021c3:	75 f0                	jne    f01021b5 <mem_init+0xcdf>
	kern_pgdir[0] = 0;
f01021c5:	c7 c0 ec a6 11 f0    	mov    $0xf011a6ec,%eax
f01021cb:	8b 00                	mov    (%eax),%eax
f01021cd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01021d3:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01021d6:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01021dc:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01021df:	89 8f 48 02 00 00    	mov    %ecx,0x248(%edi)

	// free the pages we took
	page_free(pp0);
f01021e5:	83 ec 0c             	sub    $0xc,%esp
f01021e8:	50                   	push   %eax
f01021e9:	e8 8f f0 ff ff       	call   f010127d <page_free>
	page_free(pp1);
f01021ee:	83 c4 04             	add    $0x4,%esp
f01021f1:	ff 75 d4             	pushl  -0x2c(%ebp)
f01021f4:	e8 84 f0 ff ff       	call   f010127d <page_free>
	page_free(pp2);
f01021f9:	89 34 24             	mov    %esi,(%esp)
f01021fc:	e8 7c f0 ff ff       	call   f010127d <page_free>

	cprintf("check_page() succeeded!\n");
f0102201:	8d 87 af b4 fe ff    	lea    -0x14b51(%edi),%eax
f0102207:	89 04 24             	mov    %eax,(%esp)
f010220a:	89 fb                	mov    %edi,%ebx
f010220c:	e8 6b 10 00 00       	call   f010327c <cprintf>
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U | PTE_P);
f0102211:	c7 c0 f0 a6 11 f0    	mov    $0xf011a6f0,%eax
f0102217:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102219:	89 c3                	mov    %eax,%ebx
f010221b:	83 c4 10             	add    $0x10,%esp
f010221e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102223:	0f 86 bc 08 00 00    	jbe    f0102ae5 <mem_init+0x160f>
f0102229:	c7 c0 ec a6 11 f0    	mov    $0xf011a6ec,%eax
f010222f:	8b 00                	mov    (%eax),%eax
f0102231:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102234:	be 00 00 00 ef       	mov    $0xef000000,%esi
		*pgdir_walk(pgdir, (void *)(va + i), 1) = (pa + i) | perm | PTE_P;
f0102239:	81 c3 00 00 00 21    	add    $0x21000000,%ebx
f010223f:	83 ec 04             	sub    $0x4,%esp
f0102242:	6a 01                	push   $0x1
f0102244:	56                   	push   %esi
f0102245:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102248:	e8 a8 f0 ff ff       	call   f01012f5 <pgdir_walk>
f010224d:	8d 14 33             	lea    (%ebx,%esi,1),%edx
f0102250:	83 ca 05             	or     $0x5,%edx
f0102253:	89 10                	mov    %edx,(%eax)
f0102255:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for(; i < size; i+=PGSIZE){
f010225b:	83 c4 10             	add    $0x10,%esp
f010225e:	81 fe 00 00 40 ef    	cmp    $0xef400000,%esi
f0102264:	75 d9                	jne    f010223f <mem_init+0xd69>
f0102266:	c7 c0 00 f0 10 f0    	mov    $0xf010f000,%eax
f010226c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102271:	0f 86 89 08 00 00    	jbe    f0102b00 <mem_init+0x162a>
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102277:	c7 c2 ec a6 11 f0    	mov    $0xf011a6ec,%edx
f010227d:	8b 32                	mov    (%edx),%esi
f010227f:	89 75 d0             	mov    %esi,-0x30(%ebp)
f0102282:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f0102287:	05 00 80 00 20       	add    $0x20008000,%eax
f010228c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010228f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102292:	8d 1c 06             	lea    (%esi,%eax,1),%ebx
		*pgdir_walk(pgdir, (void *)(va + i), 1) = (pa + i) | perm | PTE_P;
f0102295:	83 ec 04             	sub    $0x4,%esp
f0102298:	6a 01                	push   $0x1
f010229a:	56                   	push   %esi
f010229b:	ff 75 d0             	pushl  -0x30(%ebp)
f010229e:	e8 52 f0 ff ff       	call   f01012f5 <pgdir_walk>
f01022a3:	83 cb 03             	or     $0x3,%ebx
f01022a6:	89 18                	mov    %ebx,(%eax)
f01022a8:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for(; i < size; i+=PGSIZE){
f01022ae:	83 c4 10             	add    $0x10,%esp
f01022b1:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f01022b7:	75 d6                	jne    f010228f <mem_init+0xdb9>
	boot_map_region_large(kern_pgdir, KERNBASE, -KERNBASE, 0, PTE_W);
f01022b9:	c7 c0 ec a6 11 f0    	mov    $0xf011a6ec,%eax
f01022bf:	8b 10                	mov    (%eax),%edx
f01022c1:	8b 45 c4             	mov    -0x3c(%ebp),%eax
		pgdir[PDX(va+i)] = (pa + i) | perm | PTE_P | PTE_PS;
f01022c4:	8d 88 00 00 00 f0    	lea    -0x10000000(%eax),%ecx
f01022ca:	c1 e9 16             	shr    $0x16,%ecx
f01022cd:	89 c3                	mov    %eax,%ebx
f01022cf:	80 cb 83             	or     $0x83,%bl
f01022d2:	89 1c 8a             	mov    %ebx,(%edx,%ecx,4)
	for(; i < size; i+=PTSIZE){
f01022d5:	05 00 00 40 00       	add    $0x400000,%eax
f01022da:	3d 00 00 00 10       	cmp    $0x10000000,%eax
f01022df:	75 e3                	jne    f01022c4 <mem_init+0xdee>
	pgdir = kern_pgdir;
f01022e1:	c7 c0 ec a6 11 f0    	mov    $0xf011a6ec,%eax
f01022e7:	8b 30                	mov    (%eax),%esi
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01022e9:	c7 c0 e8 a6 11 f0    	mov    $0xf011a6e8,%eax
f01022ef:	8b 00                	mov    (%eax),%eax
f01022f1:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f01022f4:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01022fb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102300:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102303:	c7 c0 f0 a6 11 f0    	mov    $0xf011a6f0,%eax
f0102309:	8b 00                	mov    (%eax),%eax
f010230b:	89 45 c0             	mov    %eax,-0x40(%ebp)
f010230e:	89 45 cc             	mov    %eax,-0x34(%ebp)
	return (physaddr_t)kva - KERNBASE;
f0102311:	05 00 00 00 10       	add    $0x10000000,%eax
f0102316:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (i = 0; i < n; i += PGSIZE)
f0102319:	bb 00 00 00 00       	mov    $0x0,%ebx
f010231e:	39 5d d0             	cmp    %ebx,-0x30(%ebp)
f0102321:	0f 86 32 08 00 00    	jbe    f0102b59 <mem_init+0x1683>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102327:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f010232d:	89 f0                	mov    %esi,%eax
f010232f:	e8 e7 e8 ff ff       	call   f0100c1b <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f0102334:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f010233b:	0f 86 da 07 00 00    	jbe    f0102b1b <mem_init+0x1645>
f0102341:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102344:	8d 14 0b             	lea    (%ebx,%ecx,1),%edx
f0102347:	39 c2                	cmp    %eax,%edx
f0102349:	0f 85 e9 07 00 00    	jne    f0102b38 <mem_init+0x1662>
	for (i = 0; i < n; i += PGSIZE)
f010234f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102355:	eb c7                	jmp    f010231e <mem_init+0xe48>
	assert(nfree == 0);
f0102357:	8d 87 d8 b3 fe ff    	lea    -0x14c28(%edi),%eax
f010235d:	50                   	push   %eax
f010235e:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0102364:	50                   	push   %eax
f0102365:	68 b7 02 00 00       	push   $0x2b7
f010236a:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102370:	50                   	push   %eax
f0102371:	89 fb                	mov    %edi,%ebx
f0102373:	e8 21 dd ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0102378:	8d 87 e6 b2 fe ff    	lea    -0x14d1a(%edi),%eax
f010237e:	50                   	push   %eax
f010237f:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0102385:	50                   	push   %eax
f0102386:	68 1f 03 00 00       	push   $0x31f
f010238b:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102391:	50                   	push   %eax
f0102392:	e8 02 dd ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f0102397:	8d 87 fc b2 fe ff    	lea    -0x14d04(%edi),%eax
f010239d:	50                   	push   %eax
f010239e:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f01023a4:	50                   	push   %eax
f01023a5:	68 20 03 00 00       	push   $0x320
f01023aa:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f01023b0:	50                   	push   %eax
f01023b1:	e8 e3 dc ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f01023b6:	8d 87 12 b3 fe ff    	lea    -0x14cee(%edi),%eax
f01023bc:	50                   	push   %eax
f01023bd:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f01023c3:	50                   	push   %eax
f01023c4:	68 21 03 00 00       	push   $0x321
f01023c9:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f01023cf:	50                   	push   %eax
f01023d0:	e8 c4 dc ff ff       	call   f0100099 <_panic>
	assert(pp1 && pp1 != pp0);
f01023d5:	8d 87 28 b3 fe ff    	lea    -0x14cd8(%edi),%eax
f01023db:	50                   	push   %eax
f01023dc:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f01023e2:	50                   	push   %eax
f01023e3:	68 24 03 00 00       	push   $0x324
f01023e8:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f01023ee:	50                   	push   %eax
f01023ef:	e8 a5 dc ff ff       	call   f0100099 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01023f4:	8d 87 e4 ab fe ff    	lea    -0x1541c(%edi),%eax
f01023fa:	50                   	push   %eax
f01023fb:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0102401:	50                   	push   %eax
f0102402:	68 25 03 00 00       	push   $0x325
f0102407:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f010240d:	50                   	push   %eax
f010240e:	89 fb                	mov    %edi,%ebx
f0102410:	e8 84 dc ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0102415:	8d 87 91 b3 fe ff    	lea    -0x14c6f(%edi),%eax
f010241b:	50                   	push   %eax
f010241c:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0102422:	50                   	push   %eax
f0102423:	68 2c 03 00 00       	push   $0x32c
f0102428:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f010242e:	50                   	push   %eax
f010242f:	e8 65 dc ff ff       	call   f0100099 <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0102434:	8d 87 24 ac fe ff    	lea    -0x153dc(%edi),%eax
f010243a:	50                   	push   %eax
f010243b:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0102441:	50                   	push   %eax
f0102442:	68 2f 03 00 00       	push   $0x32f
f0102447:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f010244d:	50                   	push   %eax
f010244e:	e8 46 dc ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0102453:	8d 87 5c ac fe ff    	lea    -0x153a4(%edi),%eax
f0102459:	50                   	push   %eax
f010245a:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0102460:	50                   	push   %eax
f0102461:	68 32 03 00 00       	push   $0x332
f0102466:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f010246c:	50                   	push   %eax
f010246d:	e8 27 dc ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0102472:	8d 87 8c ac fe ff    	lea    -0x15374(%edi),%eax
f0102478:	50                   	push   %eax
f0102479:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f010247f:	50                   	push   %eax
f0102480:	68 36 03 00 00       	push   $0x336
f0102485:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f010248b:	50                   	push   %eax
f010248c:	e8 08 dc ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102491:	8d 87 bc ac fe ff    	lea    -0x15344(%edi),%eax
f0102497:	50                   	push   %eax
f0102498:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f010249e:	50                   	push   %eax
f010249f:	68 37 03 00 00       	push   $0x337
f01024a4:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f01024aa:	50                   	push   %eax
f01024ab:	89 fb                	mov    %edi,%ebx
f01024ad:	e8 e7 db ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01024b2:	8d 87 e4 ac fe ff    	lea    -0x1531c(%edi),%eax
f01024b8:	50                   	push   %eax
f01024b9:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f01024bf:	50                   	push   %eax
f01024c0:	68 38 03 00 00       	push   $0x338
f01024c5:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f01024cb:	50                   	push   %eax
f01024cc:	89 fb                	mov    %edi,%ebx
f01024ce:	e8 c6 db ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f01024d3:	8d 87 e3 b3 fe ff    	lea    -0x14c1d(%edi),%eax
f01024d9:	50                   	push   %eax
f01024da:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f01024e0:	50                   	push   %eax
f01024e1:	68 39 03 00 00       	push   $0x339
f01024e6:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f01024ec:	50                   	push   %eax
f01024ed:	89 fb                	mov    %edi,%ebx
f01024ef:	e8 a5 db ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f01024f4:	8d 87 f4 b3 fe ff    	lea    -0x14c0c(%edi),%eax
f01024fa:	50                   	push   %eax
f01024fb:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0102501:	50                   	push   %eax
f0102502:	68 3a 03 00 00       	push   $0x33a
f0102507:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f010250d:	50                   	push   %eax
f010250e:	89 fb                	mov    %edi,%ebx
f0102510:	e8 84 db ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102515:	8d 87 14 ad fe ff    	lea    -0x152ec(%edi),%eax
f010251b:	50                   	push   %eax
f010251c:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0102522:	50                   	push   %eax
f0102523:	68 3d 03 00 00       	push   $0x33d
f0102528:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f010252e:	50                   	push   %eax
f010252f:	89 fb                	mov    %edi,%ebx
f0102531:	e8 63 db ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102536:	8d 87 50 ad fe ff    	lea    -0x152b0(%edi),%eax
f010253c:	50                   	push   %eax
f010253d:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0102543:	50                   	push   %eax
f0102544:	68 3e 03 00 00       	push   $0x33e
f0102549:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f010254f:	50                   	push   %eax
f0102550:	89 fb                	mov    %edi,%ebx
f0102552:	e8 42 db ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f0102557:	8d 87 05 b4 fe ff    	lea    -0x14bfb(%edi),%eax
f010255d:	50                   	push   %eax
f010255e:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0102564:	50                   	push   %eax
f0102565:	68 3f 03 00 00       	push   $0x33f
f010256a:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102570:	50                   	push   %eax
f0102571:	89 fb                	mov    %edi,%ebx
f0102573:	e8 21 db ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f0102578:	8d 87 91 b3 fe ff    	lea    -0x14c6f(%edi),%eax
f010257e:	50                   	push   %eax
f010257f:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0102585:	50                   	push   %eax
f0102586:	68 42 03 00 00       	push   $0x342
f010258b:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102591:	50                   	push   %eax
f0102592:	89 fb                	mov    %edi,%ebx
f0102594:	e8 00 db ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102599:	8d 87 14 ad fe ff    	lea    -0x152ec(%edi),%eax
f010259f:	50                   	push   %eax
f01025a0:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f01025a6:	50                   	push   %eax
f01025a7:	68 45 03 00 00       	push   $0x345
f01025ac:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f01025b2:	50                   	push   %eax
f01025b3:	89 fb                	mov    %edi,%ebx
f01025b5:	e8 df da ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01025ba:	8d 87 50 ad fe ff    	lea    -0x152b0(%edi),%eax
f01025c0:	50                   	push   %eax
f01025c1:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f01025c7:	50                   	push   %eax
f01025c8:	68 46 03 00 00       	push   $0x346
f01025cd:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f01025d3:	50                   	push   %eax
f01025d4:	89 fb                	mov    %edi,%ebx
f01025d6:	e8 be da ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f01025db:	8d 87 05 b4 fe ff    	lea    -0x14bfb(%edi),%eax
f01025e1:	50                   	push   %eax
f01025e2:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f01025e8:	50                   	push   %eax
f01025e9:	68 47 03 00 00       	push   $0x347
f01025ee:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f01025f4:	50                   	push   %eax
f01025f5:	89 fb                	mov    %edi,%ebx
f01025f7:	e8 9d da ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01025fc:	8d 87 91 b3 fe ff    	lea    -0x14c6f(%edi),%eax
f0102602:	50                   	push   %eax
f0102603:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0102609:	50                   	push   %eax
f010260a:	68 4b 03 00 00       	push   $0x34b
f010260f:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102615:	50                   	push   %eax
f0102616:	89 fb                	mov    %edi,%ebx
f0102618:	e8 7c da ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010261d:	50                   	push   %eax
f010261e:	8d 87 58 aa fe ff    	lea    -0x155a8(%edi),%eax
f0102624:	50                   	push   %eax
f0102625:	68 4e 03 00 00       	push   $0x34e
f010262a:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102630:	50                   	push   %eax
f0102631:	89 fb                	mov    %edi,%ebx
f0102633:	e8 61 da ff ff       	call   f0100099 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0102638:	8d 87 80 ad fe ff    	lea    -0x15280(%edi),%eax
f010263e:	50                   	push   %eax
f010263f:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0102645:	50                   	push   %eax
f0102646:	68 4f 03 00 00       	push   $0x34f
f010264b:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102651:	50                   	push   %eax
f0102652:	89 fb                	mov    %edi,%ebx
f0102654:	e8 40 da ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102659:	8d 87 c0 ad fe ff    	lea    -0x15240(%edi),%eax
f010265f:	50                   	push   %eax
f0102660:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0102666:	50                   	push   %eax
f0102667:	68 52 03 00 00       	push   $0x352
f010266c:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102672:	50                   	push   %eax
f0102673:	89 fb                	mov    %edi,%ebx
f0102675:	e8 1f da ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010267a:	8d 87 50 ad fe ff    	lea    -0x152b0(%edi),%eax
f0102680:	50                   	push   %eax
f0102681:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0102687:	50                   	push   %eax
f0102688:	68 53 03 00 00       	push   $0x353
f010268d:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102693:	50                   	push   %eax
f0102694:	89 fb                	mov    %edi,%ebx
f0102696:	e8 fe d9 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f010269b:	8d 87 05 b4 fe ff    	lea    -0x14bfb(%edi),%eax
f01026a1:	50                   	push   %eax
f01026a2:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f01026a8:	50                   	push   %eax
f01026a9:	68 54 03 00 00       	push   $0x354
f01026ae:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f01026b4:	50                   	push   %eax
f01026b5:	89 fb                	mov    %edi,%ebx
f01026b7:	e8 dd d9 ff ff       	call   f0100099 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01026bc:	8d 87 00 ae fe ff    	lea    -0x15200(%edi),%eax
f01026c2:	50                   	push   %eax
f01026c3:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f01026c9:	50                   	push   %eax
f01026ca:	68 55 03 00 00       	push   $0x355
f01026cf:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f01026d5:	50                   	push   %eax
f01026d6:	89 fb                	mov    %edi,%ebx
f01026d8:	e8 bc d9 ff ff       	call   f0100099 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01026dd:	8d 87 16 b4 fe ff    	lea    -0x14bea(%edi),%eax
f01026e3:	50                   	push   %eax
f01026e4:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f01026ea:	50                   	push   %eax
f01026eb:	68 56 03 00 00       	push   $0x356
f01026f0:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f01026f6:	50                   	push   %eax
f01026f7:	89 fb                	mov    %edi,%ebx
f01026f9:	e8 9b d9 ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01026fe:	8d 87 14 ad fe ff    	lea    -0x152ec(%edi),%eax
f0102704:	50                   	push   %eax
f0102705:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f010270b:	50                   	push   %eax
f010270c:	68 59 03 00 00       	push   $0x359
f0102711:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102717:	50                   	push   %eax
f0102718:	89 fb                	mov    %edi,%ebx
f010271a:	e8 7a d9 ff ff       	call   f0100099 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f010271f:	8d 87 34 ae fe ff    	lea    -0x151cc(%edi),%eax
f0102725:	50                   	push   %eax
f0102726:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f010272c:	50                   	push   %eax
f010272d:	68 5a 03 00 00       	push   $0x35a
f0102732:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102738:	50                   	push   %eax
f0102739:	89 fb                	mov    %edi,%ebx
f010273b:	e8 59 d9 ff ff       	call   f0100099 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102740:	8d 87 68 ae fe ff    	lea    -0x15198(%edi),%eax
f0102746:	50                   	push   %eax
f0102747:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f010274d:	50                   	push   %eax
f010274e:	68 5b 03 00 00       	push   $0x35b
f0102753:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102759:	50                   	push   %eax
f010275a:	89 fb                	mov    %edi,%ebx
f010275c:	e8 38 d9 ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102761:	8d 87 a0 ae fe ff    	lea    -0x15160(%edi),%eax
f0102767:	50                   	push   %eax
f0102768:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f010276e:	50                   	push   %eax
f010276f:	68 5e 03 00 00       	push   $0x35e
f0102774:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f010277a:	50                   	push   %eax
f010277b:	89 fb                	mov    %edi,%ebx
f010277d:	e8 17 d9 ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0102782:	8d 87 d8 ae fe ff    	lea    -0x15128(%edi),%eax
f0102788:	50                   	push   %eax
f0102789:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f010278f:	50                   	push   %eax
f0102790:	68 61 03 00 00       	push   $0x361
f0102795:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f010279b:	50                   	push   %eax
f010279c:	89 fb                	mov    %edi,%ebx
f010279e:	e8 f6 d8 ff ff       	call   f0100099 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01027a3:	8d 87 68 ae fe ff    	lea    -0x15198(%edi),%eax
f01027a9:	50                   	push   %eax
f01027aa:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f01027b0:	50                   	push   %eax
f01027b1:	68 62 03 00 00       	push   $0x362
f01027b6:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f01027bc:	50                   	push   %eax
f01027bd:	89 fb                	mov    %edi,%ebx
f01027bf:	e8 d5 d8 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01027c4:	8d 87 14 af fe ff    	lea    -0x150ec(%edi),%eax
f01027ca:	50                   	push   %eax
f01027cb:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f01027d1:	50                   	push   %eax
f01027d2:	68 65 03 00 00       	push   $0x365
f01027d7:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f01027dd:	50                   	push   %eax
f01027de:	89 fb                	mov    %edi,%ebx
f01027e0:	e8 b4 d8 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01027e5:	8d 87 40 af fe ff    	lea    -0x150c0(%edi),%eax
f01027eb:	50                   	push   %eax
f01027ec:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f01027f2:	50                   	push   %eax
f01027f3:	68 66 03 00 00       	push   $0x366
f01027f8:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f01027fe:	50                   	push   %eax
f01027ff:	89 fb                	mov    %edi,%ebx
f0102801:	e8 93 d8 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 2);
f0102806:	8d 87 2c b4 fe ff    	lea    -0x14bd4(%edi),%eax
f010280c:	50                   	push   %eax
f010280d:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0102813:	50                   	push   %eax
f0102814:	68 68 03 00 00       	push   $0x368
f0102819:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f010281f:	50                   	push   %eax
f0102820:	89 fb                	mov    %edi,%ebx
f0102822:	e8 72 d8 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f0102827:	8d 87 3d b4 fe ff    	lea    -0x14bc3(%edi),%eax
f010282d:	50                   	push   %eax
f010282e:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0102834:	50                   	push   %eax
f0102835:	68 69 03 00 00       	push   $0x369
f010283a:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102840:	50                   	push   %eax
f0102841:	89 fb                	mov    %edi,%ebx
f0102843:	e8 51 d8 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f0102848:	8d 87 70 af fe ff    	lea    -0x15090(%edi),%eax
f010284e:	50                   	push   %eax
f010284f:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0102855:	50                   	push   %eax
f0102856:	68 6c 03 00 00       	push   $0x36c
f010285b:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102861:	50                   	push   %eax
f0102862:	89 fb                	mov    %edi,%ebx
f0102864:	e8 30 d8 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102869:	8d 87 94 af fe ff    	lea    -0x1506c(%edi),%eax
f010286f:	50                   	push   %eax
f0102870:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0102876:	50                   	push   %eax
f0102877:	68 70 03 00 00       	push   $0x370
f010287c:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102882:	50                   	push   %eax
f0102883:	89 fb                	mov    %edi,%ebx
f0102885:	e8 0f d8 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010288a:	8d 87 40 af fe ff    	lea    -0x150c0(%edi),%eax
f0102890:	50                   	push   %eax
f0102891:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0102897:	50                   	push   %eax
f0102898:	68 71 03 00 00       	push   $0x371
f010289d:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f01028a3:	50                   	push   %eax
f01028a4:	89 fb                	mov    %edi,%ebx
f01028a6:	e8 ee d7 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f01028ab:	8d 87 e3 b3 fe ff    	lea    -0x14c1d(%edi),%eax
f01028b1:	50                   	push   %eax
f01028b2:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f01028b8:	50                   	push   %eax
f01028b9:	68 72 03 00 00       	push   $0x372
f01028be:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f01028c4:	50                   	push   %eax
f01028c5:	89 fb                	mov    %edi,%ebx
f01028c7:	e8 cd d7 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f01028cc:	8d 87 3d b4 fe ff    	lea    -0x14bc3(%edi),%eax
f01028d2:	50                   	push   %eax
f01028d3:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f01028d9:	50                   	push   %eax
f01028da:	68 73 03 00 00       	push   $0x373
f01028df:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f01028e5:	50                   	push   %eax
f01028e6:	89 fb                	mov    %edi,%ebx
f01028e8:	e8 ac d7 ff ff       	call   f0100099 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f01028ed:	8d 87 b8 af fe ff    	lea    -0x15048(%edi),%eax
f01028f3:	50                   	push   %eax
f01028f4:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f01028fa:	50                   	push   %eax
f01028fb:	68 76 03 00 00       	push   $0x376
f0102900:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102906:	50                   	push   %eax
f0102907:	89 fb                	mov    %edi,%ebx
f0102909:	e8 8b d7 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref);
f010290e:	8d 87 4e b4 fe ff    	lea    -0x14bb2(%edi),%eax
f0102914:	50                   	push   %eax
f0102915:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f010291b:	50                   	push   %eax
f010291c:	68 77 03 00 00       	push   $0x377
f0102921:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102927:	50                   	push   %eax
f0102928:	89 fb                	mov    %edi,%ebx
f010292a:	e8 6a d7 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_link == NULL);
f010292f:	8d 87 5a b4 fe ff    	lea    -0x14ba6(%edi),%eax
f0102935:	50                   	push   %eax
f0102936:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f010293c:	50                   	push   %eax
f010293d:	68 78 03 00 00       	push   $0x378
f0102942:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102948:	50                   	push   %eax
f0102949:	89 fb                	mov    %edi,%ebx
f010294b:	e8 49 d7 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102950:	8d 87 94 af fe ff    	lea    -0x1506c(%edi),%eax
f0102956:	50                   	push   %eax
f0102957:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f010295d:	50                   	push   %eax
f010295e:	68 7c 03 00 00       	push   $0x37c
f0102963:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102969:	50                   	push   %eax
f010296a:	89 fb                	mov    %edi,%ebx
f010296c:	e8 28 d7 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102971:	8d 87 f0 af fe ff    	lea    -0x15010(%edi),%eax
f0102977:	50                   	push   %eax
f0102978:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f010297e:	50                   	push   %eax
f010297f:	68 7d 03 00 00       	push   $0x37d
f0102984:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f010298a:	50                   	push   %eax
f010298b:	89 fb                	mov    %edi,%ebx
f010298d:	e8 07 d7 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 0);
f0102992:	8d 87 6f b4 fe ff    	lea    -0x14b91(%edi),%eax
f0102998:	50                   	push   %eax
f0102999:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f010299f:	50                   	push   %eax
f01029a0:	68 7e 03 00 00       	push   $0x37e
f01029a5:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f01029ab:	50                   	push   %eax
f01029ac:	89 fb                	mov    %edi,%ebx
f01029ae:	e8 e6 d6 ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f01029b3:	8d 87 3d b4 fe ff    	lea    -0x14bc3(%edi),%eax
f01029b9:	50                   	push   %eax
f01029ba:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f01029c0:	50                   	push   %eax
f01029c1:	68 7f 03 00 00       	push   $0x37f
f01029c6:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f01029cc:	50                   	push   %eax
f01029cd:	89 fb                	mov    %edi,%ebx
f01029cf:	e8 c5 d6 ff ff       	call   f0100099 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f01029d4:	8d 87 18 b0 fe ff    	lea    -0x14fe8(%edi),%eax
f01029da:	50                   	push   %eax
f01029db:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f01029e1:	50                   	push   %eax
f01029e2:	68 82 03 00 00       	push   $0x382
f01029e7:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f01029ed:	50                   	push   %eax
f01029ee:	89 fb                	mov    %edi,%ebx
f01029f0:	e8 a4 d6 ff ff       	call   f0100099 <_panic>
	assert(!page_alloc(0));
f01029f5:	8d 87 91 b3 fe ff    	lea    -0x14c6f(%edi),%eax
f01029fb:	50                   	push   %eax
f01029fc:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0102a02:	50                   	push   %eax
f0102a03:	68 85 03 00 00       	push   $0x385
f0102a08:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102a0e:	50                   	push   %eax
f0102a0f:	89 fb                	mov    %edi,%ebx
f0102a11:	e8 83 d6 ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102a16:	8d 87 bc ac fe ff    	lea    -0x15344(%edi),%eax
f0102a1c:	50                   	push   %eax
f0102a1d:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0102a23:	50                   	push   %eax
f0102a24:	68 88 03 00 00       	push   $0x388
f0102a29:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102a2f:	50                   	push   %eax
f0102a30:	89 fb                	mov    %edi,%ebx
f0102a32:	e8 62 d6 ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f0102a37:	8d 87 f4 b3 fe ff    	lea    -0x14c0c(%edi),%eax
f0102a3d:	50                   	push   %eax
f0102a3e:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0102a44:	50                   	push   %eax
f0102a45:	68 8a 03 00 00       	push   $0x38a
f0102a4a:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102a50:	50                   	push   %eax
f0102a51:	89 fb                	mov    %edi,%ebx
f0102a53:	e8 41 d6 ff ff       	call   f0100099 <_panic>
f0102a58:	52                   	push   %edx
f0102a59:	8d 87 58 aa fe ff    	lea    -0x155a8(%edi),%eax
f0102a5f:	50                   	push   %eax
f0102a60:	68 91 03 00 00       	push   $0x391
f0102a65:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102a6b:	50                   	push   %eax
f0102a6c:	89 fb                	mov    %edi,%ebx
f0102a6e:	e8 26 d6 ff ff       	call   f0100099 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102a73:	8d 87 80 b4 fe ff    	lea    -0x14b80(%edi),%eax
f0102a79:	50                   	push   %eax
f0102a7a:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0102a80:	50                   	push   %eax
f0102a81:	68 92 03 00 00       	push   $0x392
f0102a86:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102a8c:	50                   	push   %eax
f0102a8d:	89 fb                	mov    %edi,%ebx
f0102a8f:	e8 05 d6 ff ff       	call   f0100099 <_panic>
f0102a94:	50                   	push   %eax
f0102a95:	8d 87 58 aa fe ff    	lea    -0x155a8(%edi),%eax
f0102a9b:	50                   	push   %eax
f0102a9c:	6a 52                	push   $0x52
f0102a9e:	8d 87 05 b2 fe ff    	lea    -0x14dfb(%edi),%eax
f0102aa4:	50                   	push   %eax
f0102aa5:	89 fb                	mov    %edi,%ebx
f0102aa7:	e8 ed d5 ff ff       	call   f0100099 <_panic>
f0102aac:	50                   	push   %eax
f0102aad:	8d 87 58 aa fe ff    	lea    -0x155a8(%edi),%eax
f0102ab3:	50                   	push   %eax
f0102ab4:	6a 52                	push   $0x52
f0102ab6:	8d 87 05 b2 fe ff    	lea    -0x14dfb(%edi),%eax
f0102abc:	50                   	push   %eax
f0102abd:	89 fb                	mov    %edi,%ebx
f0102abf:	e8 d5 d5 ff ff       	call   f0100099 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f0102ac4:	8d 87 98 b4 fe ff    	lea    -0x14b68(%edi),%eax
f0102aca:	50                   	push   %eax
f0102acb:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0102ad1:	50                   	push   %eax
f0102ad2:	68 9c 03 00 00       	push   $0x39c
f0102ad7:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102add:	50                   	push   %eax
f0102ade:	89 fb                	mov    %edi,%ebx
f0102ae0:	e8 b4 d5 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ae5:	50                   	push   %eax
f0102ae6:	8d 87 7c aa fe ff    	lea    -0x15584(%edi),%eax
f0102aec:	50                   	push   %eax
f0102aed:	68 bd 00 00 00       	push   $0xbd
f0102af2:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102af8:	50                   	push   %eax
f0102af9:	89 fb                	mov    %edi,%ebx
f0102afb:	e8 99 d5 ff ff       	call   f0100099 <_panic>
f0102b00:	50                   	push   %eax
f0102b01:	8d 87 7c aa fe ff    	lea    -0x15584(%edi),%eax
f0102b07:	50                   	push   %eax
f0102b08:	68 c9 00 00 00       	push   $0xc9
f0102b0d:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102b13:	50                   	push   %eax
f0102b14:	89 fb                	mov    %edi,%ebx
f0102b16:	e8 7e d5 ff ff       	call   f0100099 <_panic>
f0102b1b:	ff 75 c0             	pushl  -0x40(%ebp)
f0102b1e:	8d 87 7c aa fe ff    	lea    -0x15584(%edi),%eax
f0102b24:	50                   	push   %eax
f0102b25:	68 cf 02 00 00       	push   $0x2cf
f0102b2a:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102b30:	50                   	push   %eax
f0102b31:	89 fb                	mov    %edi,%ebx
f0102b33:	e8 61 d5 ff ff       	call   f0100099 <_panic>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102b38:	8d 87 3c b0 fe ff    	lea    -0x14fc4(%edi),%eax
f0102b3e:	50                   	push   %eax
f0102b3f:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0102b45:	50                   	push   %eax
f0102b46:	68 cf 02 00 00       	push   $0x2cf
f0102b4b:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102b51:	50                   	push   %eax
f0102b52:	89 fb                	mov    %edi,%ebx
f0102b54:	e8 40 d5 ff ff       	call   f0100099 <_panic>
	if (!(*pgdir & PTE_P) | !(*pgdir & PTE_PS))
f0102b59:	8b 86 00 0f 00 00    	mov    0xf00(%esi),%eax
f0102b5f:	89 c2                	mov    %eax,%edx
f0102b61:	81 e2 81 00 00 00    	and    $0x81,%edx
f0102b67:	81 fa 81 00 00 00    	cmp    $0x81,%edx
f0102b6d:	75 14                	jne    f0102b83 <mem_init+0x16ad>
	if (check_va2pa_large(pgdir, KERNBASE) == 0) {
f0102b6f:	a9 00 f0 ff ff       	test   $0xfffff000,%eax
f0102b74:	75 0d                	jne    f0102b83 <mem_init+0x16ad>
		for (i = 0; i < npages * PGSIZE; i += PTSIZE)
f0102b76:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0102b79:	c1 e3 0c             	shl    $0xc,%ebx
f0102b7c:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b81:	eb 43                	jmp    f0102bc6 <mem_init+0x16f0>
        for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102b83:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0102b86:	c1 e0 0c             	shl    $0xc,%eax
f0102b89:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102b8c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102b91:	3b 5d d0             	cmp    -0x30(%ebp),%ebx
f0102b94:	0f 83 81 00 00 00    	jae    f0102c1b <mem_init+0x1745>
            assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102b9a:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102ba0:	89 f0                	mov    %esi,%eax
f0102ba2:	e8 74 e0 ff ff       	call   f0100c1b <check_va2pa>
f0102ba7:	39 c3                	cmp    %eax,%ebx
f0102ba9:	0f 85 0f 01 00 00    	jne    f0102cbe <mem_init+0x17e8>
        for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102baf:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102bb5:	eb da                	jmp    f0102b91 <mem_init+0x16bb>
	return PTE_ADDR(*pgdir);
f0102bb7:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
			assert(check_va2pa_large(pgdir, KERNBASE + i) == i);
f0102bbd:	39 d0                	cmp    %edx,%eax
f0102bbf:	75 25                	jne    f0102be6 <mem_init+0x1710>
		for (i = 0; i < npages * PGSIZE; i += PTSIZE)
f0102bc1:	05 00 00 40 00       	add    $0x400000,%eax
f0102bc6:	39 d8                	cmp    %ebx,%eax
f0102bc8:	73 3d                	jae    f0102c07 <mem_init+0x1731>
	pgdir = &pgdir[PDX(va)];
f0102bca:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx
f0102bd0:	c1 ea 16             	shr    $0x16,%edx
	if (!(*pgdir & PTE_P) | !(*pgdir & PTE_PS))
f0102bd3:	8b 14 96             	mov    (%esi,%edx,4),%edx
f0102bd6:	89 d1                	mov    %edx,%ecx
f0102bd8:	81 e1 81 00 00 00    	and    $0x81,%ecx
f0102bde:	81 f9 81 00 00 00    	cmp    $0x81,%ecx
f0102be4:	74 d1                	je     f0102bb7 <mem_init+0x16e1>
			assert(check_va2pa_large(pgdir, KERNBASE + i) == i);
f0102be6:	8d 87 70 b0 fe ff    	lea    -0x14f90(%edi),%eax
f0102bec:	50                   	push   %eax
f0102bed:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0102bf3:	50                   	push   %eax
f0102bf4:	68 d5 02 00 00       	push   $0x2d5
f0102bf9:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102bff:	50                   	push   %eax
f0102c00:	89 fb                	mov    %edi,%ebx
f0102c02:	e8 92 d4 ff ff       	call   f0100099 <_panic>
		cprintf("large page installed!\n");
f0102c07:	83 ec 0c             	sub    $0xc,%esp
f0102c0a:	8d 87 c8 b4 fe ff    	lea    -0x14b38(%edi),%eax
f0102c10:	50                   	push   %eax
f0102c11:	89 fb                	mov    %edi,%ebx
f0102c13:	e8 64 06 00 00       	call   f010327c <cprintf>
f0102c18:	83 c4 10             	add    $0x10,%esp
        for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102c1b:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102c20:	89 da                	mov    %ebx,%edx
f0102c22:	89 f0                	mov    %esi,%eax
f0102c24:	e8 f2 df ff ff       	call   f0100c1b <check_va2pa>
f0102c29:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102c2c:	8d 14 0b             	lea    (%ebx,%ecx,1),%edx
f0102c2f:	39 d0                	cmp    %edx,%eax
f0102c31:	0f 85 a8 00 00 00    	jne    f0102cdf <mem_init+0x1809>
f0102c37:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102c3d:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102c43:	75 db                	jne    f0102c20 <mem_init+0x174a>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102c45:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102c4a:	89 f0                	mov    %esi,%eax
f0102c4c:	e8 ca df ff ff       	call   f0100c1b <check_va2pa>
f0102c51:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102c54:	0f 85 a6 00 00 00    	jne    f0102d00 <mem_init+0x182a>
	for (i = 0; i < NPDENTRIES; i++) {
f0102c5a:	b8 00 00 00 00       	mov    $0x0,%eax
			if (i >= PDX(KERNBASE)) {
f0102c5f:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102c64:	0f 87 b7 00 00 00    	ja     f0102d21 <mem_init+0x184b>
				assert(pgdir[i] == 0);
f0102c6a:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102c6e:	0f 85 00 01 00 00    	jne    f0102d74 <mem_init+0x189e>
	for (i = 0; i < NPDENTRIES; i++) {
f0102c74:	83 c0 01             	add    $0x1,%eax
f0102c77:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102c7c:	0f 87 13 01 00 00    	ja     f0102d95 <mem_init+0x18bf>
f0102c82:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102c87:	72 d6                	jb     f0102c5f <mem_init+0x1789>
f0102c89:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102c8e:	76 07                	jbe    f0102c97 <mem_init+0x17c1>
f0102c90:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102c95:	75 c8                	jne    f0102c5f <mem_init+0x1789>
			assert(pgdir[i] & PTE_P);
f0102c97:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102c9b:	75 d7                	jne    f0102c74 <mem_init+0x179e>
f0102c9d:	8d 87 df b4 fe ff    	lea    -0x14b21(%edi),%eax
f0102ca3:	50                   	push   %eax
f0102ca4:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0102caa:	50                   	push   %eax
f0102cab:	68 e8 02 00 00       	push   $0x2e8
f0102cb0:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102cb6:	50                   	push   %eax
f0102cb7:	89 fb                	mov    %edi,%ebx
f0102cb9:	e8 db d3 ff ff       	call   f0100099 <_panic>
            assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102cbe:	8d 87 9c b0 fe ff    	lea    -0x14f64(%edi),%eax
f0102cc4:	50                   	push   %eax
f0102cc5:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0102ccb:	50                   	push   %eax
f0102ccc:	68 da 02 00 00       	push   $0x2da
f0102cd1:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102cd7:	50                   	push   %eax
f0102cd8:	89 fb                	mov    %edi,%ebx
f0102cda:	e8 ba d3 ff ff       	call   f0100099 <_panic>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102cdf:	8d 87 c4 b0 fe ff    	lea    -0x14f3c(%edi),%eax
f0102ce5:	50                   	push   %eax
f0102ce6:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0102cec:	50                   	push   %eax
f0102ced:	68 df 02 00 00       	push   $0x2df
f0102cf2:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102cf8:	50                   	push   %eax
f0102cf9:	89 fb                	mov    %edi,%ebx
f0102cfb:	e8 99 d3 ff ff       	call   f0100099 <_panic>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102d00:	8d 87 0c b1 fe ff    	lea    -0x14ef4(%edi),%eax
f0102d06:	50                   	push   %eax
f0102d07:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0102d0d:	50                   	push   %eax
f0102d0e:	68 e0 02 00 00       	push   $0x2e0
f0102d13:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102d19:	50                   	push   %eax
f0102d1a:	89 fb                	mov    %edi,%ebx
f0102d1c:	e8 78 d3 ff ff       	call   f0100099 <_panic>
				assert(pgdir[i] & PTE_P);
f0102d21:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102d24:	f6 c2 01             	test   $0x1,%dl
f0102d27:	74 2a                	je     f0102d53 <mem_init+0x187d>
				assert(pgdir[i] & PTE_W);
f0102d29:	f6 c2 02             	test   $0x2,%dl
f0102d2c:	0f 85 42 ff ff ff    	jne    f0102c74 <mem_init+0x179e>
f0102d32:	8d 87 f0 b4 fe ff    	lea    -0x14b10(%edi),%eax
f0102d38:	50                   	push   %eax
f0102d39:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0102d3f:	50                   	push   %eax
f0102d40:	68 ed 02 00 00       	push   $0x2ed
f0102d45:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102d4b:	50                   	push   %eax
f0102d4c:	89 fb                	mov    %edi,%ebx
f0102d4e:	e8 46 d3 ff ff       	call   f0100099 <_panic>
				assert(pgdir[i] & PTE_P);
f0102d53:	8d 87 df b4 fe ff    	lea    -0x14b21(%edi),%eax
f0102d59:	50                   	push   %eax
f0102d5a:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0102d60:	50                   	push   %eax
f0102d61:	68 ec 02 00 00       	push   $0x2ec
f0102d66:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102d6c:	50                   	push   %eax
f0102d6d:	89 fb                	mov    %edi,%ebx
f0102d6f:	e8 25 d3 ff ff       	call   f0100099 <_panic>
				assert(pgdir[i] == 0);
f0102d74:	8d 87 01 b5 fe ff    	lea    -0x14aff(%edi),%eax
f0102d7a:	50                   	push   %eax
f0102d7b:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0102d81:	50                   	push   %eax
f0102d82:	68 ef 02 00 00       	push   $0x2ef
f0102d87:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0102d8d:	50                   	push   %eax
f0102d8e:	89 fb                	mov    %edi,%ebx
f0102d90:	e8 04 d3 ff ff       	call   f0100099 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102d95:	83 ec 0c             	sub    $0xc,%esp
f0102d98:	8d 87 3c b1 fe ff    	lea    -0x14ec4(%edi),%eax
f0102d9e:	50                   	push   %eax
f0102d9f:	89 fb                	mov    %edi,%ebx
f0102da1:	e8 d6 04 00 00       	call   f010327c <cprintf>
	asm volatile("movl %%cr4,%0" : "=r" (cr4));
f0102da6:	0f 20 e0             	mov    %cr4,%eax
	cr4 |= CR4_PSE;
f0102da9:	83 c8 10             	or     $0x10,%eax
	asm volatile("movl %0,%%cr4" : : "r" (val));
f0102dac:	0f 22 e0             	mov    %eax,%cr4
	lcr3(PADDR(kern_pgdir));
f0102daf:	c7 c0 ec a6 11 f0    	mov    $0xf011a6ec,%eax
f0102db5:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102db7:	83 c4 10             	add    $0x10,%esp
f0102dba:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102dbf:	0f 86 32 02 00 00    	jbe    f0102ff7 <mem_init+0x1b21>
	return (physaddr_t)kva - KERNBASE;
f0102dc5:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102dca:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102dcd:	b8 00 00 00 00       	mov    $0x0,%eax
f0102dd2:	e8 77 df ff ff       	call   f0100d4e <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102dd7:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102dda:	83 e0 f3             	and    $0xfffffff3,%eax
f0102ddd:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102de2:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102de5:	83 ec 0c             	sub    $0xc,%esp
f0102de8:	6a 00                	push   $0x0
f0102dea:	e8 00 e4 ff ff       	call   f01011ef <page_alloc>
f0102def:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102df2:	83 c4 10             	add    $0x10,%esp
f0102df5:	85 c0                	test   %eax,%eax
f0102df7:	0f 84 13 02 00 00    	je     f0103010 <mem_init+0x1b3a>
	assert((pp1 = page_alloc(0)));
f0102dfd:	83 ec 0c             	sub    $0xc,%esp
f0102e00:	6a 00                	push   $0x0
f0102e02:	e8 e8 e3 ff ff       	call   f01011ef <page_alloc>
f0102e07:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102e0a:	83 c4 10             	add    $0x10,%esp
f0102e0d:	85 c0                	test   %eax,%eax
f0102e0f:	0f 84 1a 02 00 00    	je     f010302f <mem_init+0x1b59>
	assert((pp2 = page_alloc(0)));
f0102e15:	83 ec 0c             	sub    $0xc,%esp
f0102e18:	6a 00                	push   $0x0
f0102e1a:	e8 d0 e3 ff ff       	call   f01011ef <page_alloc>
f0102e1f:	89 c6                	mov    %eax,%esi
f0102e21:	83 c4 10             	add    $0x10,%esp
f0102e24:	85 c0                	test   %eax,%eax
f0102e26:	0f 84 22 02 00 00    	je     f010304e <mem_init+0x1b78>
	page_free(pp0);
f0102e2c:	83 ec 0c             	sub    $0xc,%esp
f0102e2f:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102e32:	e8 46 e4 ff ff       	call   f010127d <page_free>
	return (pp - pages) << PGSHIFT;
f0102e37:	c7 c0 f0 a6 11 f0    	mov    $0xf011a6f0,%eax
f0102e3d:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102e40:	2b 08                	sub    (%eax),%ecx
f0102e42:	89 c8                	mov    %ecx,%eax
f0102e44:	c1 f8 03             	sar    $0x3,%eax
f0102e47:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102e4a:	89 c1                	mov    %eax,%ecx
f0102e4c:	c1 e9 0c             	shr    $0xc,%ecx
f0102e4f:	83 c4 10             	add    $0x10,%esp
f0102e52:	c7 c2 e8 a6 11 f0    	mov    $0xf011a6e8,%edx
f0102e58:	3b 0a                	cmp    (%edx),%ecx
f0102e5a:	0f 83 0d 02 00 00    	jae    f010306d <mem_init+0x1b97>
	memset(page2kva(pp1), 1, PGSIZE);
f0102e60:	83 ec 04             	sub    $0x4,%esp
f0102e63:	68 00 10 00 00       	push   $0x1000
f0102e68:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102e6a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102e6f:	50                   	push   %eax
f0102e70:	e8 bd 12 00 00       	call   f0104132 <memset>
	return (pp - pages) << PGSHIFT;
f0102e75:	c7 c0 f0 a6 11 f0    	mov    $0xf011a6f0,%eax
f0102e7b:	89 f1                	mov    %esi,%ecx
f0102e7d:	2b 08                	sub    (%eax),%ecx
f0102e7f:	89 c8                	mov    %ecx,%eax
f0102e81:	c1 f8 03             	sar    $0x3,%eax
f0102e84:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102e87:	89 c1                	mov    %eax,%ecx
f0102e89:	c1 e9 0c             	shr    $0xc,%ecx
f0102e8c:	83 c4 10             	add    $0x10,%esp
f0102e8f:	c7 c2 e8 a6 11 f0    	mov    $0xf011a6e8,%edx
f0102e95:	3b 0a                	cmp    (%edx),%ecx
f0102e97:	0f 83 e6 01 00 00    	jae    f0103083 <mem_init+0x1bad>
	memset(page2kva(pp2), 2, PGSIZE);
f0102e9d:	83 ec 04             	sub    $0x4,%esp
f0102ea0:	68 00 10 00 00       	push   $0x1000
f0102ea5:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102ea7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102eac:	50                   	push   %eax
f0102ead:	e8 80 12 00 00       	call   f0104132 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102eb2:	6a 02                	push   $0x2
f0102eb4:	68 00 10 00 00       	push   $0x1000
f0102eb9:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0102ebc:	53                   	push   %ebx
f0102ebd:	c7 c0 ec a6 11 f0    	mov    $0xf011a6ec,%eax
f0102ec3:	ff 30                	pushl  (%eax)
f0102ec5:	e8 9d e5 ff ff       	call   f0101467 <page_insert>
	assert(pp1->pp_ref == 1);
f0102eca:	83 c4 20             	add    $0x20,%esp
f0102ecd:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102ed2:	0f 85 c1 01 00 00    	jne    f0103099 <mem_init+0x1bc3>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102ed8:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102edf:	01 01 01 
f0102ee2:	0f 85 d2 01 00 00    	jne    f01030ba <mem_init+0x1be4>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102ee8:	6a 02                	push   $0x2
f0102eea:	68 00 10 00 00       	push   $0x1000
f0102eef:	56                   	push   %esi
f0102ef0:	c7 c0 ec a6 11 f0    	mov    $0xf011a6ec,%eax
f0102ef6:	ff 30                	pushl  (%eax)
f0102ef8:	e8 6a e5 ff ff       	call   f0101467 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102efd:	83 c4 10             	add    $0x10,%esp
f0102f00:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102f07:	02 02 02 
f0102f0a:	0f 85 cb 01 00 00    	jne    f01030db <mem_init+0x1c05>
	assert(pp2->pp_ref == 1);
f0102f10:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102f15:	0f 85 e1 01 00 00    	jne    f01030fc <mem_init+0x1c26>
	assert(pp1->pp_ref == 0);
f0102f1b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102f1e:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102f23:	0f 85 f4 01 00 00    	jne    f010311d <mem_init+0x1c47>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102f29:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102f30:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0102f33:	c7 c0 f0 a6 11 f0    	mov    $0xf011a6f0,%eax
f0102f39:	89 f1                	mov    %esi,%ecx
f0102f3b:	2b 08                	sub    (%eax),%ecx
f0102f3d:	89 c8                	mov    %ecx,%eax
f0102f3f:	c1 f8 03             	sar    $0x3,%eax
f0102f42:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102f45:	89 c1                	mov    %eax,%ecx
f0102f47:	c1 e9 0c             	shr    $0xc,%ecx
f0102f4a:	c7 c2 e8 a6 11 f0    	mov    $0xf011a6e8,%edx
f0102f50:	3b 0a                	cmp    (%edx),%ecx
f0102f52:	0f 83 e6 01 00 00    	jae    f010313e <mem_init+0x1c68>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102f58:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102f5f:	03 03 03 
f0102f62:	0f 85 ee 01 00 00    	jne    f0103156 <mem_init+0x1c80>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102f68:	83 ec 08             	sub    $0x8,%esp
f0102f6b:	68 00 10 00 00       	push   $0x1000
f0102f70:	c7 c0 ec a6 11 f0    	mov    $0xf011a6ec,%eax
f0102f76:	ff 30                	pushl  (%eax)
f0102f78:	e8 a8 e4 ff ff       	call   f0101425 <page_remove>
	assert(pp2->pp_ref == 0);
f0102f7d:	83 c4 10             	add    $0x10,%esp
f0102f80:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102f85:	0f 85 ec 01 00 00    	jne    f0103177 <mem_init+0x1ca1>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102f8b:	c7 c0 ec a6 11 f0    	mov    $0xf011a6ec,%eax
f0102f91:	8b 08                	mov    (%eax),%ecx
f0102f93:	8b 11                	mov    (%ecx),%edx
f0102f95:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0102f9b:	c7 c0 f0 a6 11 f0    	mov    $0xf011a6f0,%eax
f0102fa1:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0102fa4:	2b 30                	sub    (%eax),%esi
f0102fa6:	89 f0                	mov    %esi,%eax
f0102fa8:	c1 f8 03             	sar    $0x3,%eax
f0102fab:	c1 e0 0c             	shl    $0xc,%eax
f0102fae:	39 c2                	cmp    %eax,%edx
f0102fb0:	0f 85 e2 01 00 00    	jne    f0103198 <mem_init+0x1cc2>
	kern_pgdir[0] = 0;
f0102fb6:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102fbc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102fbf:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102fc4:	0f 85 ef 01 00 00    	jne    f01031b9 <mem_init+0x1ce3>
	pp0->pp_ref = 0;
f0102fca:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102fcd:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// free the pages we took
	page_free(pp0);
f0102fd3:	83 ec 0c             	sub    $0xc,%esp
f0102fd6:	50                   	push   %eax
f0102fd7:	e8 a1 e2 ff ff       	call   f010127d <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102fdc:	8d 87 d0 b1 fe ff    	lea    -0x14e30(%edi),%eax
f0102fe2:	89 04 24             	mov    %eax,(%esp)
f0102fe5:	89 fb                	mov    %edi,%ebx
f0102fe7:	e8 90 02 00 00       	call   f010327c <cprintf>
}
f0102fec:	83 c4 10             	add    $0x10,%esp
f0102fef:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102ff2:	5b                   	pop    %ebx
f0102ff3:	5e                   	pop    %esi
f0102ff4:	5f                   	pop    %edi
f0102ff5:	5d                   	pop    %ebp
f0102ff6:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ff7:	50                   	push   %eax
f0102ff8:	8d 87 7c aa fe ff    	lea    -0x15584(%edi),%eax
f0102ffe:	50                   	push   %eax
f0102fff:	68 e2 00 00 00       	push   $0xe2
f0103004:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f010300a:	50                   	push   %eax
f010300b:	e8 89 d0 ff ff       	call   f0100099 <_panic>
	assert((pp0 = page_alloc(0)));
f0103010:	8d 87 e6 b2 fe ff    	lea    -0x14d1a(%edi),%eax
f0103016:	50                   	push   %eax
f0103017:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f010301d:	50                   	push   %eax
f010301e:	68 b7 03 00 00       	push   $0x3b7
f0103023:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0103029:	50                   	push   %eax
f010302a:	e8 6a d0 ff ff       	call   f0100099 <_panic>
	assert((pp1 = page_alloc(0)));
f010302f:	8d 87 fc b2 fe ff    	lea    -0x14d04(%edi),%eax
f0103035:	50                   	push   %eax
f0103036:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f010303c:	50                   	push   %eax
f010303d:	68 b8 03 00 00       	push   $0x3b8
f0103042:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0103048:	50                   	push   %eax
f0103049:	e8 4b d0 ff ff       	call   f0100099 <_panic>
	assert((pp2 = page_alloc(0)));
f010304e:	8d 87 12 b3 fe ff    	lea    -0x14cee(%edi),%eax
f0103054:	50                   	push   %eax
f0103055:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f010305b:	50                   	push   %eax
f010305c:	68 b9 03 00 00       	push   $0x3b9
f0103061:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0103067:	50                   	push   %eax
f0103068:	e8 2c d0 ff ff       	call   f0100099 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010306d:	50                   	push   %eax
f010306e:	8d 87 58 aa fe ff    	lea    -0x155a8(%edi),%eax
f0103074:	50                   	push   %eax
f0103075:	6a 52                	push   $0x52
f0103077:	8d 87 05 b2 fe ff    	lea    -0x14dfb(%edi),%eax
f010307d:	50                   	push   %eax
f010307e:	e8 16 d0 ff ff       	call   f0100099 <_panic>
f0103083:	50                   	push   %eax
f0103084:	8d 87 58 aa fe ff    	lea    -0x155a8(%edi),%eax
f010308a:	50                   	push   %eax
f010308b:	6a 52                	push   $0x52
f010308d:	8d 87 05 b2 fe ff    	lea    -0x14dfb(%edi),%eax
f0103093:	50                   	push   %eax
f0103094:	e8 00 d0 ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 1);
f0103099:	8d 87 e3 b3 fe ff    	lea    -0x14c1d(%edi),%eax
f010309f:	50                   	push   %eax
f01030a0:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f01030a6:	50                   	push   %eax
f01030a7:	68 be 03 00 00       	push   $0x3be
f01030ac:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f01030b2:	50                   	push   %eax
f01030b3:	89 fb                	mov    %edi,%ebx
f01030b5:	e8 df cf ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01030ba:	8d 87 5c b1 fe ff    	lea    -0x14ea4(%edi),%eax
f01030c0:	50                   	push   %eax
f01030c1:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f01030c7:	50                   	push   %eax
f01030c8:	68 bf 03 00 00       	push   $0x3bf
f01030cd:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f01030d3:	50                   	push   %eax
f01030d4:	89 fb                	mov    %edi,%ebx
f01030d6:	e8 be cf ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f01030db:	8d 87 80 b1 fe ff    	lea    -0x14e80(%edi),%eax
f01030e1:	50                   	push   %eax
f01030e2:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f01030e8:	50                   	push   %eax
f01030e9:	68 c1 03 00 00       	push   $0x3c1
f01030ee:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f01030f4:	50                   	push   %eax
f01030f5:	89 fb                	mov    %edi,%ebx
f01030f7:	e8 9d cf ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 1);
f01030fc:	8d 87 05 b4 fe ff    	lea    -0x14bfb(%edi),%eax
f0103102:	50                   	push   %eax
f0103103:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0103109:	50                   	push   %eax
f010310a:	68 c2 03 00 00       	push   $0x3c2
f010310f:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0103115:	50                   	push   %eax
f0103116:	89 fb                	mov    %edi,%ebx
f0103118:	e8 7c cf ff ff       	call   f0100099 <_panic>
	assert(pp1->pp_ref == 0);
f010311d:	8d 87 6f b4 fe ff    	lea    -0x14b91(%edi),%eax
f0103123:	50                   	push   %eax
f0103124:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f010312a:	50                   	push   %eax
f010312b:	68 c3 03 00 00       	push   $0x3c3
f0103130:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0103136:	50                   	push   %eax
f0103137:	89 fb                	mov    %edi,%ebx
f0103139:	e8 5b cf ff ff       	call   f0100099 <_panic>
f010313e:	50                   	push   %eax
f010313f:	8d 87 58 aa fe ff    	lea    -0x155a8(%edi),%eax
f0103145:	50                   	push   %eax
f0103146:	6a 52                	push   $0x52
f0103148:	8d 87 05 b2 fe ff    	lea    -0x14dfb(%edi),%eax
f010314e:	50                   	push   %eax
f010314f:	89 fb                	mov    %edi,%ebx
f0103151:	e8 43 cf ff ff       	call   f0100099 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0103156:	8d 87 a4 b1 fe ff    	lea    -0x14e5c(%edi),%eax
f010315c:	50                   	push   %eax
f010315d:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0103163:	50                   	push   %eax
f0103164:	68 c5 03 00 00       	push   $0x3c5
f0103169:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f010316f:	50                   	push   %eax
f0103170:	89 fb                	mov    %edi,%ebx
f0103172:	e8 22 cf ff ff       	call   f0100099 <_panic>
	assert(pp2->pp_ref == 0);
f0103177:	8d 87 3d b4 fe ff    	lea    -0x14bc3(%edi),%eax
f010317d:	50                   	push   %eax
f010317e:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f0103184:	50                   	push   %eax
f0103185:	68 c7 03 00 00       	push   $0x3c7
f010318a:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f0103190:	50                   	push   %eax
f0103191:	89 fb                	mov    %edi,%ebx
f0103193:	e8 01 cf ff ff       	call   f0100099 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0103198:	8d 87 bc ac fe ff    	lea    -0x15344(%edi),%eax
f010319e:	50                   	push   %eax
f010319f:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f01031a5:	50                   	push   %eax
f01031a6:	68 ca 03 00 00       	push   $0x3ca
f01031ab:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f01031b1:	50                   	push   %eax
f01031b2:	89 fb                	mov    %edi,%ebx
f01031b4:	e8 e0 ce ff ff       	call   f0100099 <_panic>
	assert(pp0->pp_ref == 1);
f01031b9:	8d 87 f4 b3 fe ff    	lea    -0x14c0c(%edi),%eax
f01031bf:	50                   	push   %eax
f01031c0:	8d 87 1f b2 fe ff    	lea    -0x14de1(%edi),%eax
f01031c6:	50                   	push   %eax
f01031c7:	68 cc 03 00 00       	push   $0x3cc
f01031cc:	8d 87 f9 b1 fe ff    	lea    -0x14e07(%edi),%eax
f01031d2:	50                   	push   %eax
f01031d3:	89 fb                	mov    %edi,%ebx
f01031d5:	e8 bf ce ff ff       	call   f0100099 <_panic>

f01031da <tlb_invalidate>:
{
f01031da:	55                   	push   %ebp
f01031db:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01031dd:	8b 45 0c             	mov    0xc(%ebp),%eax
f01031e0:	0f 01 38             	invlpg (%eax)
}
f01031e3:	5d                   	pop    %ebp
f01031e4:	c3                   	ret    

f01031e5 <__x86.get_pc_thunk.dx>:
f01031e5:	8b 14 24             	mov    (%esp),%edx
f01031e8:	c3                   	ret    

f01031e9 <__x86.get_pc_thunk.cx>:
f01031e9:	8b 0c 24             	mov    (%esp),%ecx
f01031ec:	c3                   	ret    

f01031ed <__x86.get_pc_thunk.si>:
f01031ed:	8b 34 24             	mov    (%esp),%esi
f01031f0:	c3                   	ret    

f01031f1 <__x86.get_pc_thunk.di>:
f01031f1:	8b 3c 24             	mov    (%esp),%edi
f01031f4:	c3                   	ret    

f01031f5 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01031f5:	55                   	push   %ebp
f01031f6:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01031f8:	8b 45 08             	mov    0x8(%ebp),%eax
f01031fb:	ba 70 00 00 00       	mov    $0x70,%edx
f0103200:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103201:	ba 71 00 00 00       	mov    $0x71,%edx
f0103206:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103207:	0f b6 c0             	movzbl %al,%eax
}
f010320a:	5d                   	pop    %ebp
f010320b:	c3                   	ret    

f010320c <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f010320c:	55                   	push   %ebp
f010320d:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010320f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103212:	ba 70 00 00 00       	mov    $0x70,%edx
f0103217:	ee                   	out    %al,(%dx)
f0103218:	8b 45 0c             	mov    0xc(%ebp),%eax
f010321b:	ba 71 00 00 00       	mov    $0x71,%edx
f0103220:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103221:	5d                   	pop    %ebp
f0103222:	c3                   	ret    

f0103223 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103223:	55                   	push   %ebp
f0103224:	89 e5                	mov    %esp,%ebp
f0103226:	53                   	push   %ebx
f0103227:	83 ec 10             	sub    $0x10,%esp
f010322a:	e8 20 cf ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010322f:	81 c3 45 6e 01 00    	add    $0x16e45,%ebx
	cputchar(ch);
f0103235:	ff 75 08             	pushl  0x8(%ebp)
f0103238:	e8 5c d4 ff ff       	call   f0100699 <cputchar>
	*cnt++;
}
f010323d:	83 c4 10             	add    $0x10,%esp
f0103240:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103243:	c9                   	leave  
f0103244:	c3                   	ret    

f0103245 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103245:	55                   	push   %ebp
f0103246:	89 e5                	mov    %esp,%ebp
f0103248:	53                   	push   %ebx
f0103249:	83 ec 14             	sub    $0x14,%esp
f010324c:	e8 fe ce ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103251:	81 c3 23 6e 01 00    	add    $0x16e23,%ebx
	int cnt = 0;
f0103257:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010325e:	ff 75 0c             	pushl  0xc(%ebp)
f0103261:	ff 75 08             	pushl  0x8(%ebp)
f0103264:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103267:	50                   	push   %eax
f0103268:	8d 83 af 91 fe ff    	lea    -0x16e51(%ebx),%eax
f010326e:	50                   	push   %eax
f010326f:	e8 f3 05 00 00       	call   f0103867 <vprintfmt>
	return cnt;
}
f0103274:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103277:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010327a:	c9                   	leave  
f010327b:	c3                   	ret    

f010327c <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010327c:	55                   	push   %ebp
f010327d:	89 e5                	mov    %esp,%ebp
f010327f:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103282:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103285:	50                   	push   %eax
f0103286:	ff 75 08             	pushl  0x8(%ebp)
f0103289:	e8 b7 ff ff ff       	call   f0103245 <vcprintf>
	va_end(ap);

	return cnt;
}
f010328e:	c9                   	leave  
f010328f:	c3                   	ret    

f0103290 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0103290:	55                   	push   %ebp
f0103291:	89 e5                	mov    %esp,%ebp
f0103293:	57                   	push   %edi
f0103294:	56                   	push   %esi
f0103295:	53                   	push   %ebx
f0103296:	83 ec 14             	sub    $0x14,%esp
f0103299:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010329c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010329f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01032a2:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f01032a5:	8b 1a                	mov    (%edx),%ebx
f01032a7:	8b 01                	mov    (%ecx),%eax
f01032a9:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01032ac:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01032b3:	eb 23                	jmp    f01032d8 <stab_binsearch+0x48>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01032b5:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f01032b8:	eb 1e                	jmp    f01032d8 <stab_binsearch+0x48>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01032ba:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01032bd:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01032c0:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01032c4:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01032c7:	73 41                	jae    f010330a <stab_binsearch+0x7a>
			*region_left = m;
f01032c9:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01032cc:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01032ce:	8d 5f 01             	lea    0x1(%edi),%ebx
		any_matches = 1;
f01032d1:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f01032d8:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01032db:	7f 5a                	jg     f0103337 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f01032dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01032e0:	01 d8                	add    %ebx,%eax
f01032e2:	89 c7                	mov    %eax,%edi
f01032e4:	c1 ef 1f             	shr    $0x1f,%edi
f01032e7:	01 c7                	add    %eax,%edi
f01032e9:	d1 ff                	sar    %edi
f01032eb:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f01032ee:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01032f1:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f01032f5:	89 f8                	mov    %edi,%eax
		while (m >= l && stabs[m].n_type != type)
f01032f7:	39 c3                	cmp    %eax,%ebx
f01032f9:	7f ba                	jg     f01032b5 <stab_binsearch+0x25>
f01032fb:	0f b6 0a             	movzbl (%edx),%ecx
f01032fe:	83 ea 0c             	sub    $0xc,%edx
f0103301:	39 f1                	cmp    %esi,%ecx
f0103303:	74 b5                	je     f01032ba <stab_binsearch+0x2a>
			m--;
f0103305:	83 e8 01             	sub    $0x1,%eax
f0103308:	eb ed                	jmp    f01032f7 <stab_binsearch+0x67>
		} else if (stabs[m].n_value > addr) {
f010330a:	3b 55 0c             	cmp    0xc(%ebp),%edx
f010330d:	76 14                	jbe    f0103323 <stab_binsearch+0x93>
			*region_right = m - 1;
f010330f:	83 e8 01             	sub    $0x1,%eax
f0103312:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103315:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103318:	89 07                	mov    %eax,(%edi)
		any_matches = 1;
f010331a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103321:	eb b5                	jmp    f01032d8 <stab_binsearch+0x48>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103323:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103326:	89 07                	mov    %eax,(%edi)
			l = m;
			addr++;
f0103328:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010332c:	89 c3                	mov    %eax,%ebx
		any_matches = 1;
f010332e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103335:	eb a1                	jmp    f01032d8 <stab_binsearch+0x48>
		}
	}

	if (!any_matches)
f0103337:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010333b:	75 15                	jne    f0103352 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f010333d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103340:	8b 00                	mov    (%eax),%eax
f0103342:	83 e8 01             	sub    $0x1,%eax
f0103345:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103348:	89 06                	mov    %eax,(%esi)
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f010334a:	83 c4 14             	add    $0x14,%esp
f010334d:	5b                   	pop    %ebx
f010334e:	5e                   	pop    %esi
f010334f:	5f                   	pop    %edi
f0103350:	5d                   	pop    %ebp
f0103351:	c3                   	ret    
		for (l = *region_right;
f0103352:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103355:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103357:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010335a:	8b 0f                	mov    (%edi),%ecx
f010335c:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010335f:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0103362:	8d 54 97 04          	lea    0x4(%edi,%edx,4),%edx
		for (l = *region_right;
f0103366:	eb 03                	jmp    f010336b <stab_binsearch+0xdb>
		     l--)
f0103368:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f010336b:	39 c1                	cmp    %eax,%ecx
f010336d:	7d 0a                	jge    f0103379 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f010336f:	0f b6 1a             	movzbl (%edx),%ebx
f0103372:	83 ea 0c             	sub    $0xc,%edx
f0103375:	39 f3                	cmp    %esi,%ebx
f0103377:	75 ef                	jne    f0103368 <stab_binsearch+0xd8>
		*region_left = l;
f0103379:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010337c:	89 06                	mov    %eax,(%esi)
}
f010337e:	eb ca                	jmp    f010334a <stab_binsearch+0xba>

f0103380 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103380:	55                   	push   %ebp
f0103381:	89 e5                	mov    %esp,%ebp
f0103383:	57                   	push   %edi
f0103384:	56                   	push   %esi
f0103385:	53                   	push   %ebx
f0103386:	83 ec 3c             	sub    $0x3c,%esp
f0103389:	e8 c1 cd ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010338e:	81 c3 e6 6c 01 00    	add    $0x16ce6,%ebx
f0103394:	89 5d bc             	mov    %ebx,-0x44(%ebp)
f0103397:	8b 7d 08             	mov    0x8(%ebp),%edi
f010339a:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010339d:	8d 83 0f b5 fe ff    	lea    -0x14af1(%ebx),%eax
f01033a3:	89 06                	mov    %eax,(%esi)
	info->eip_line = 0;
f01033a5:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f01033ac:	89 46 08             	mov    %eax,0x8(%esi)
	info->eip_fn_namelen = 9;
f01033af:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f01033b6:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f01033b9:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01033c0:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f01033c6:	0f 86 42 01 00 00    	jbe    f010350e <debuginfo_eip+0x18e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01033cc:	c7 c0 b5 d0 10 f0    	mov    $0xf010d0b5,%eax
f01033d2:	39 83 fc ff ff ff    	cmp    %eax,-0x4(%ebx)
f01033d8:	0f 86 04 02 00 00    	jbe    f01035e2 <debuginfo_eip+0x262>
f01033de:	8b 5d bc             	mov    -0x44(%ebp),%ebx
f01033e1:	c7 c0 8f ef 10 f0    	mov    $0xf010ef8f,%eax
f01033e7:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f01033eb:	0f 85 f8 01 00 00    	jne    f01035e9 <debuginfo_eip+0x269>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01033f1:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01033f8:	c7 c0 18 58 10 f0    	mov    $0xf0105818,%eax
f01033fe:	c7 c2 b4 d0 10 f0    	mov    $0xf010d0b4,%edx
f0103404:	29 c2                	sub    %eax,%edx
f0103406:	c1 fa 02             	sar    $0x2,%edx
f0103409:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f010340f:	83 ea 01             	sub    $0x1,%edx
f0103412:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103415:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0103418:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010341b:	83 ec 08             	sub    $0x8,%esp
f010341e:	57                   	push   %edi
f010341f:	6a 64                	push   $0x64
f0103421:	e8 6a fe ff ff       	call   f0103290 <stab_binsearch>
	if (lfile == 0)
f0103426:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103429:	83 c4 10             	add    $0x10,%esp
f010342c:	85 c0                	test   %eax,%eax
f010342e:	0f 84 bc 01 00 00    	je     f01035f0 <debuginfo_eip+0x270>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103434:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103437:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010343a:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010343d:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0103440:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103443:	83 ec 08             	sub    $0x8,%esp
f0103446:	57                   	push   %edi
f0103447:	6a 24                	push   $0x24
f0103449:	c7 c0 18 58 10 f0    	mov    $0xf0105818,%eax
f010344f:	e8 3c fe ff ff       	call   f0103290 <stab_binsearch>

	if (lfun <= rfun) {
f0103454:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103457:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f010345a:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
f010345d:	83 c4 10             	add    $0x10,%esp
f0103460:	39 c8                	cmp    %ecx,%eax
f0103462:	0f 8f c1 00 00 00    	jg     f0103529 <debuginfo_eip+0x1a9>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103468:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010346b:	c7 c1 18 58 10 f0    	mov    $0xf0105818,%ecx
f0103471:	8d 0c 91             	lea    (%ecx,%edx,4),%ecx
f0103474:	8b 11                	mov    (%ecx),%edx
f0103476:	89 55 c0             	mov    %edx,-0x40(%ebp)
f0103479:	c7 c2 8f ef 10 f0    	mov    $0xf010ef8f,%edx
f010347f:	89 5d bc             	mov    %ebx,-0x44(%ebp)
f0103482:	81 ea b5 d0 10 f0    	sub    $0xf010d0b5,%edx
f0103488:	8b 5d c0             	mov    -0x40(%ebp),%ebx
f010348b:	39 d3                	cmp    %edx,%ebx
f010348d:	73 0c                	jae    f010349b <debuginfo_eip+0x11b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010348f:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0103492:	81 c3 b5 d0 10 f0    	add    $0xf010d0b5,%ebx
f0103498:	89 5e 08             	mov    %ebx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f010349b:	8b 51 08             	mov    0x8(%ecx),%edx
f010349e:	89 56 10             	mov    %edx,0x10(%esi)
		addr -= info->eip_fn_addr;
f01034a1:	29 d7                	sub    %edx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f01034a3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01034a6:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01034a9:	89 45 d0             	mov    %eax,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01034ac:	83 ec 08             	sub    $0x8,%esp
f01034af:	6a 3a                	push   $0x3a
f01034b1:	ff 76 08             	pushl  0x8(%esi)
f01034b4:	8b 5d bc             	mov    -0x44(%ebp),%ebx
f01034b7:	e8 5a 0c 00 00       	call   f0104116 <strfind>
f01034bc:	2b 46 08             	sub    0x8(%esi),%eax
f01034bf:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01034c2:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01034c5:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01034c8:	83 c4 08             	add    $0x8,%esp
f01034cb:	57                   	push   %edi
f01034cc:	6a 44                	push   $0x44
f01034ce:	8b 7d bc             	mov    -0x44(%ebp),%edi
f01034d1:	c7 c0 18 58 10 f0    	mov    $0xf0105818,%eax
f01034d7:	e8 b4 fd ff ff       	call   f0103290 <stab_binsearch>
	if (lline <= rline) {
f01034dc:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01034df:	83 c4 10             	add    $0x10,%esp
f01034e2:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f01034e5:	0f 8f 0c 01 00 00    	jg     f01035f7 <debuginfo_eip+0x277>
		info->eip_line = stabs[lline].n_desc;
f01034eb:	89 d0                	mov    %edx,%eax
f01034ed:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01034f0:	c1 e2 02             	shl    $0x2,%edx
f01034f3:	c7 c1 18 58 10 f0    	mov    $0xf0105818,%ecx
f01034f9:	0f b7 5c 0a 06       	movzwl 0x6(%edx,%ecx,1),%ebx
f01034fe:	89 5e 04             	mov    %ebx,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103501:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103504:	8d 54 0a 04          	lea    0x4(%edx,%ecx,1),%edx
f0103508:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f010350c:	eb 39                	jmp    f0103547 <debuginfo_eip+0x1c7>
  	        panic("User address");
f010350e:	83 ec 04             	sub    $0x4,%esp
f0103511:	8b 5d bc             	mov    -0x44(%ebp),%ebx
f0103514:	8d 83 19 b5 fe ff    	lea    -0x14ae7(%ebx),%eax
f010351a:	50                   	push   %eax
f010351b:	6a 7f                	push   $0x7f
f010351d:	8d 83 26 b5 fe ff    	lea    -0x14ada(%ebx),%eax
f0103523:	50                   	push   %eax
f0103524:	e8 70 cb ff ff       	call   f0100099 <_panic>
		info->eip_fn_addr = addr;
f0103529:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f010352c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010352f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103532:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103535:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103538:	e9 6f ff ff ff       	jmp    f01034ac <debuginfo_eip+0x12c>
f010353d:	83 e8 01             	sub    $0x1,%eax
f0103540:	83 ea 0c             	sub    $0xc,%edx
f0103543:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0103547:	89 45 c0             	mov    %eax,-0x40(%ebp)
	while (lline >= lfile
f010354a:	39 c7                	cmp    %eax,%edi
f010354c:	7f 51                	jg     f010359f <debuginfo_eip+0x21f>
	       && stabs[lline].n_type != N_SOL
f010354e:	0f b6 0a             	movzbl (%edx),%ecx
f0103551:	80 f9 84             	cmp    $0x84,%cl
f0103554:	74 19                	je     f010356f <debuginfo_eip+0x1ef>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103556:	80 f9 64             	cmp    $0x64,%cl
f0103559:	75 e2                	jne    f010353d <debuginfo_eip+0x1bd>
f010355b:	83 7a 04 00          	cmpl   $0x0,0x4(%edx)
f010355f:	74 dc                	je     f010353d <debuginfo_eip+0x1bd>
f0103561:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103565:	74 11                	je     f0103578 <debuginfo_eip+0x1f8>
f0103567:	8b 7d c0             	mov    -0x40(%ebp),%edi
f010356a:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010356d:	eb 09                	jmp    f0103578 <debuginfo_eip+0x1f8>
f010356f:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103573:	74 03                	je     f0103578 <debuginfo_eip+0x1f8>
f0103575:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103578:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010357b:	8b 7d bc             	mov    -0x44(%ebp),%edi
f010357e:	c7 c0 18 58 10 f0    	mov    $0xf0105818,%eax
f0103584:	8b 14 90             	mov    (%eax,%edx,4),%edx
f0103587:	c7 c0 8f ef 10 f0    	mov    $0xf010ef8f,%eax
f010358d:	81 e8 b5 d0 10 f0    	sub    $0xf010d0b5,%eax
f0103593:	39 c2                	cmp    %eax,%edx
f0103595:	73 08                	jae    f010359f <debuginfo_eip+0x21f>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103597:	81 c2 b5 d0 10 f0    	add    $0xf010d0b5,%edx
f010359d:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010359f:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01035a2:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01035a5:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f01035aa:	39 da                	cmp    %ebx,%edx
f01035ac:	7d 55                	jge    f0103603 <debuginfo_eip+0x283>
		for (lline = lfun + 1;
f01035ae:	83 c2 01             	add    $0x1,%edx
f01035b1:	89 d0                	mov    %edx,%eax
f01035b3:	8d 0c 52             	lea    (%edx,%edx,2),%ecx
f01035b6:	8b 7d bc             	mov    -0x44(%ebp),%edi
f01035b9:	c7 c2 18 58 10 f0    	mov    $0xf0105818,%edx
f01035bf:	8d 54 8a 04          	lea    0x4(%edx,%ecx,4),%edx
f01035c3:	eb 04                	jmp    f01035c9 <debuginfo_eip+0x249>
			info->eip_fn_narg++;
f01035c5:	83 46 14 01          	addl   $0x1,0x14(%esi)
		for (lline = lfun + 1;
f01035c9:	39 c3                	cmp    %eax,%ebx
f01035cb:	7e 31                	jle    f01035fe <debuginfo_eip+0x27e>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01035cd:	0f b6 0a             	movzbl (%edx),%ecx
f01035d0:	83 c0 01             	add    $0x1,%eax
f01035d3:	83 c2 0c             	add    $0xc,%edx
f01035d6:	80 f9 a0             	cmp    $0xa0,%cl
f01035d9:	74 ea                	je     f01035c5 <debuginfo_eip+0x245>
	return 0;
f01035db:	b8 00 00 00 00       	mov    $0x0,%eax
f01035e0:	eb 21                	jmp    f0103603 <debuginfo_eip+0x283>
		return -1;
f01035e2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01035e7:	eb 1a                	jmp    f0103603 <debuginfo_eip+0x283>
f01035e9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01035ee:	eb 13                	jmp    f0103603 <debuginfo_eip+0x283>
		return -1;
f01035f0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01035f5:	eb 0c                	jmp    f0103603 <debuginfo_eip+0x283>
		return -1;
f01035f7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01035fc:	eb 05                	jmp    f0103603 <debuginfo_eip+0x283>
	return 0;
f01035fe:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103603:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103606:	5b                   	pop    %ebx
f0103607:	5e                   	pop    %esi
f0103608:	5f                   	pop    %edi
f0103609:	5d                   	pop    %ebp
f010360a:	c3                   	ret    

f010360b <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f010360b:	55                   	push   %ebp
f010360c:	89 e5                	mov    %esp,%ebp
f010360e:	57                   	push   %edi
f010360f:	56                   	push   %esi
f0103610:	53                   	push   %ebx
f0103611:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
f0103617:	e8 33 cb ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f010361c:	81 c3 58 6a 01 00    	add    $0x16a58,%ebx
f0103622:	89 85 74 ff ff ff    	mov    %eax,-0x8c(%ebp)
f0103628:	89 95 70 ff ff ff    	mov    %edx,-0x90(%ebp)
f010362e:	8b 75 08             	mov    0x8(%ebp),%esi
f0103631:	8b 7d 0c             	mov    0xc(%ebp),%edi
	if(padc=='-'){ 
f0103634:	83 7d 18 2d          	cmpl   $0x2d,0x18(%ebp)
f0103638:	74 54                	je     f010368e <printnum+0x83>
    		putch(' ', putdat);
    	}		
    	return ;
  	}
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010363a:	8b 45 10             	mov    0x10(%ebp),%eax
f010363d:	ba 00 00 00 00       	mov    $0x0,%edx
f0103642:	89 85 68 ff ff ff    	mov    %eax,-0x98(%ebp)
f0103648:	89 95 6c ff ff ff    	mov    %edx,-0x94(%ebp)
f010364e:	3b 75 10             	cmp    0x10(%ebp),%esi
f0103651:	89 f9                	mov    %edi,%ecx
f0103653:	19 d1                	sbb    %edx,%ecx
f0103655:	0f 83 47 01 00 00    	jae    f01037a2 <printnum+0x197>
f010365b:	89 b5 60 ff ff ff    	mov    %esi,-0xa0(%ebp)
f0103661:	89 bd 64 ff ff ff    	mov    %edi,-0x9c(%ebp)
f0103667:	8b 7d 14             	mov    0x14(%ebp),%edi
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f010366a:	83 ef 01             	sub    $0x1,%edi
f010366d:	85 ff                	test   %edi,%edi
f010366f:	0f 8e 6e 01 00 00    	jle    f01037e3 <printnum+0x1d8>
			putch(padc, putdat);
f0103675:	83 ec 08             	sub    $0x8,%esp
f0103678:	ff b5 70 ff ff ff    	pushl  -0x90(%ebp)
f010367e:	ff 75 18             	pushl  0x18(%ebp)
f0103681:	8b 85 74 ff ff ff    	mov    -0x8c(%ebp),%eax
f0103687:	ff d0                	call   *%eax
f0103689:	83 c4 10             	add    $0x10,%esp
f010368c:	eb dc                	jmp    f010366a <printnum+0x5f>
    	int numlen = 0;
f010368e:	c7 85 60 ff ff ff 00 	movl   $0x0,-0xa0(%ebp)
f0103695:	00 00 00 
    	for(; num >= base; numlen++ , num /= base){	//计算每一位
f0103698:	8b 45 10             	mov    0x10(%ebp),%eax
f010369b:	ba 00 00 00 00       	mov    $0x0,%edx
f01036a0:	89 85 68 ff ff ff    	mov    %eax,-0x98(%ebp)
f01036a6:	89 95 6c ff ff ff    	mov    %edx,-0x94(%ebp)
f01036ac:	3b 75 10             	cmp    0x10(%ebp),%esi
f01036af:	89 f8                	mov    %edi,%eax
f01036b1:	1b 85 6c ff ff ff    	sbb    -0x94(%ebp),%eax
f01036b7:	72 45                	jb     f01036fe <printnum+0xf3>
      		renum[numlen]= num % base;
f01036b9:	ff b5 6c ff ff ff    	pushl  -0x94(%ebp)
f01036bf:	ff b5 68 ff ff ff    	pushl  -0x98(%ebp)
f01036c5:	57                   	push   %edi
f01036c6:	56                   	push   %esi
f01036c7:	e8 74 0d 00 00       	call   f0104440 <__umoddi3>
f01036cc:	83 c4 10             	add    $0x10,%esp
f01036cf:	8b 8d 60 ff ff ff    	mov    -0xa0(%ebp),%ecx
f01036d5:	88 44 0d 84          	mov    %al,-0x7c(%ebp,%ecx,1)
    	for(; num >= base; numlen++ , num /= base){	//计算每一位
f01036d9:	83 c1 01             	add    $0x1,%ecx
f01036dc:	89 8d 60 ff ff ff    	mov    %ecx,-0xa0(%ebp)
f01036e2:	ff b5 6c ff ff ff    	pushl  -0x94(%ebp)
f01036e8:	ff b5 68 ff ff ff    	pushl  -0x98(%ebp)
f01036ee:	57                   	push   %edi
f01036ef:	56                   	push   %esi
f01036f0:	e8 3b 0c 00 00       	call   f0104330 <__udivdi3>
f01036f5:	83 c4 10             	add    $0x10,%esp
f01036f8:	89 c6                	mov    %eax,%esi
f01036fa:	89 d7                	mov    %edx,%edi
f01036fc:	eb ae                	jmp    f01036ac <printnum+0xa1>
    	putch("0123456789abcdef"[num % base],putdat);	//输出数字的第一位
f01036fe:	83 ec 08             	sub    $0x8,%esp
f0103701:	ff b5 70 ff ff ff    	pushl  -0x90(%ebp)
f0103707:	83 ec 04             	sub    $0x4,%esp
f010370a:	ff b5 6c ff ff ff    	pushl  -0x94(%ebp)
f0103710:	ff b5 68 ff ff ff    	pushl  -0x98(%ebp)
f0103716:	57                   	push   %edi
f0103717:	56                   	push   %esi
f0103718:	e8 23 0d 00 00       	call   f0104440 <__umoddi3>
f010371d:	83 c4 14             	add    $0x14,%esp
f0103720:	0f be 84 03 34 b5 fe 	movsbl -0x14acc(%ebx,%eax,1),%eax
f0103727:	ff 
f0103728:	50                   	push   %eax
f0103729:	8b 85 74 ff ff ff    	mov    -0x8c(%ebp),%eax
f010372f:	ff d0                	call   *%eax
    	for(; numlen > 0 ; --numlen){	//按序输出其他位
f0103731:	83 c4 10             	add    $0x10,%esp
f0103734:	8b b5 60 ff ff ff    	mov    -0xa0(%ebp),%esi
    		int index = renum[numlen-1];
f010373a:	8d 7d 84             	lea    -0x7c(%ebp),%edi
    	for(; numlen > 0 ; --numlen){	//按序输出其他位
f010373d:	eb 24                	jmp    f0103763 <printnum+0x158>
    		int index = renum[numlen-1];
f010373f:	83 ee 01             	sub    $0x1,%esi
      		putch("0123456789abcdef"[index],putdat);
f0103742:	83 ec 08             	sub    $0x8,%esp
f0103745:	ff b5 70 ff ff ff    	pushl  -0x90(%ebp)
    		int index = renum[numlen-1];
f010374b:	0f be 04 3e          	movsbl (%esi,%edi,1),%eax
      		putch("0123456789abcdef"[index],putdat);
f010374f:	0f be 84 03 34 b5 fe 	movsbl -0x14acc(%ebx,%eax,1),%eax
f0103756:	ff 
f0103757:	50                   	push   %eax
f0103758:	8b 85 74 ff ff ff    	mov    -0x8c(%ebp),%eax
f010375e:	ff d0                	call   *%eax
    	for(; numlen > 0 ; --numlen){	//按序输出其他位
f0103760:	83 c4 10             	add    $0x10,%esp
f0103763:	85 f6                	test   %esi,%esi
f0103765:	7f d8                	jg     f010373f <printnum+0x134>
f0103767:	8b 95 60 ff ff ff    	mov    -0xa0(%ebp),%edx
f010376d:	85 d2                	test   %edx,%edx
f010376f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103774:	0f 49 c2             	cmovns %edx,%eax
		width -= numlen;	//计算需要补充空格的数量
f0103777:	29 c2                	sub    %eax,%edx
f0103779:	8b 5d 14             	mov    0x14(%ebp),%ebx
f010377c:	29 d3                	sub    %edx,%ebx
f010377e:	8b b5 74 ff ff ff    	mov    -0x8c(%ebp),%esi
f0103784:	8b bd 70 ff ff ff    	mov    -0x90(%ebp),%edi
    	while (--width > 0){	//补充空格
f010378a:	83 eb 01             	sub    $0x1,%ebx
f010378d:	85 db                	test   %ebx,%ebx
f010378f:	0f 8e 90 00 00 00    	jle    f0103825 <printnum+0x21a>
    		putch(' ', putdat);
f0103795:	83 ec 08             	sub    $0x8,%esp
f0103798:	57                   	push   %edi
f0103799:	6a 20                	push   $0x20
f010379b:	ff d6                	call   *%esi
f010379d:	83 c4 10             	add    $0x10,%esp
f01037a0:	eb e8                	jmp    f010378a <printnum+0x17f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01037a2:	83 ec 0c             	sub    $0xc,%esp
f01037a5:	ff 75 18             	pushl  0x18(%ebp)
f01037a8:	8b 45 14             	mov    0x14(%ebp),%eax
f01037ab:	83 e8 01             	sub    $0x1,%eax
f01037ae:	50                   	push   %eax
f01037af:	ff 75 10             	pushl  0x10(%ebp)
f01037b2:	83 ec 08             	sub    $0x8,%esp
f01037b5:	ff b5 6c ff ff ff    	pushl  -0x94(%ebp)
f01037bb:	ff b5 68 ff ff ff    	pushl  -0x98(%ebp)
f01037c1:	57                   	push   %edi
f01037c2:	56                   	push   %esi
f01037c3:	e8 68 0b 00 00       	call   f0104330 <__udivdi3>
f01037c8:	83 c4 18             	add    $0x18,%esp
f01037cb:	52                   	push   %edx
f01037cc:	50                   	push   %eax
f01037cd:	8b 95 70 ff ff ff    	mov    -0x90(%ebp),%edx
f01037d3:	8b 85 74 ff ff ff    	mov    -0x8c(%ebp),%eax
f01037d9:	e8 2d fe ff ff       	call   f010360b <printnum>
f01037de:	83 c4 20             	add    $0x20,%esp
f01037e1:	eb 0c                	jmp    f01037ef <printnum+0x1e4>
f01037e3:	8b b5 60 ff ff ff    	mov    -0xa0(%ebp),%esi
f01037e9:	8b bd 64 ff ff ff    	mov    -0x9c(%ebp),%edi
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01037ef:	83 ec 08             	sub    $0x8,%esp
f01037f2:	ff b5 70 ff ff ff    	pushl  -0x90(%ebp)
f01037f8:	83 ec 04             	sub    $0x4,%esp
f01037fb:	ff b5 6c ff ff ff    	pushl  -0x94(%ebp)
f0103801:	ff b5 68 ff ff ff    	pushl  -0x98(%ebp)
f0103807:	57                   	push   %edi
f0103808:	56                   	push   %esi
f0103809:	e8 32 0c 00 00       	call   f0104440 <__umoddi3>
f010380e:	83 c4 14             	add    $0x14,%esp
f0103811:	0f be 84 03 34 b5 fe 	movsbl -0x14acc(%ebx,%eax,1),%eax
f0103818:	ff 
f0103819:	50                   	push   %eax
f010381a:	8b 85 74 ff ff ff    	mov    -0x8c(%ebp),%eax
f0103820:	ff d0                	call   *%eax
f0103822:	83 c4 10             	add    $0x10,%esp
}
f0103825:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103828:	5b                   	pop    %ebx
f0103829:	5e                   	pop    %esi
f010382a:	5f                   	pop    %edi
f010382b:	5d                   	pop    %ebp
f010382c:	c3                   	ret    

f010382d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f010382d:	55                   	push   %ebp
f010382e:	89 e5                	mov    %esp,%ebp
f0103830:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103833:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103837:	8b 10                	mov    (%eax),%edx
f0103839:	3b 50 04             	cmp    0x4(%eax),%edx
f010383c:	73 0a                	jae    f0103848 <sprintputch+0x1b>
		*b->buf++ = ch;
f010383e:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103841:	89 08                	mov    %ecx,(%eax)
f0103843:	8b 45 08             	mov    0x8(%ebp),%eax
f0103846:	88 02                	mov    %al,(%edx)
}
f0103848:	5d                   	pop    %ebp
f0103849:	c3                   	ret    

f010384a <printfmt>:
{
f010384a:	55                   	push   %ebp
f010384b:	89 e5                	mov    %esp,%ebp
f010384d:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0103850:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103853:	50                   	push   %eax
f0103854:	ff 75 10             	pushl  0x10(%ebp)
f0103857:	ff 75 0c             	pushl  0xc(%ebp)
f010385a:	ff 75 08             	pushl  0x8(%ebp)
f010385d:	e8 05 00 00 00       	call   f0103867 <vprintfmt>
}
f0103862:	83 c4 10             	add    $0x10,%esp
f0103865:	c9                   	leave  
f0103866:	c3                   	ret    

f0103867 <vprintfmt>:
{
f0103867:	55                   	push   %ebp
f0103868:	89 e5                	mov    %esp,%ebp
f010386a:	57                   	push   %edi
f010386b:	56                   	push   %esi
f010386c:	53                   	push   %ebx
f010386d:	83 ec 3c             	sub    $0x3c,%esp
f0103870:	e8 4b ce ff ff       	call   f01006c0 <__x86.get_pc_thunk.ax>
f0103875:	05 ff 67 01 00       	add    $0x167ff,%eax
f010387a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010387d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103880:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0103883:	89 fe                	mov    %edi,%esi
f0103885:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0103888:	e9 84 04 00 00       	jmp    f0103d11 <.L40+0x76>
		int ifsign = 0;
f010388d:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%ebp)
		padc = ' ';
f0103894:	c6 45 d3 20          	movb   $0x20,-0x2d(%ebp)
		altflag = 0;
f0103898:	c7 45 c8 00 00 00 00 	movl   $0x0,-0x38(%ebp)
		precision = -1;
f010389f:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		width = -1;
f01038a6:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		lflag = 0;
f01038ad:	b9 00 00 00 00       	mov    $0x0,%ecx
f01038b2:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
f01038b5:	89 75 08             	mov    %esi,0x8(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01038b8:	8d 43 01             	lea    0x1(%ebx),%eax
f01038bb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01038be:	0f b6 13             	movzbl (%ebx),%edx
f01038c1:	8d 42 dd             	lea    -0x23(%edx),%eax
f01038c4:	3c 55                	cmp    $0x55,%al
f01038c6:	0f 87 46 05 00 00    	ja     f0103e12 <.L34>
f01038cc:	0f b6 c0             	movzbl %al,%eax
f01038cf:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01038d2:	89 ce                	mov    %ecx,%esi
f01038d4:	03 b4 81 3c b6 fe ff 	add    -0x149c4(%ecx,%eax,4),%esi
f01038db:	ff e6                	jmp    *%esi

f01038dd <.L86>:
f01038dd:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			padc = '-';
f01038e0:	c6 45 d3 2d          	movb   $0x2d,-0x2d(%ebp)
f01038e4:	eb d2                	jmp    f01038b8 <vprintfmt+0x51>

f01038e6 <.L49>:
		switch (ch = *(unsigned char *) fmt++) {
f01038e6:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			ifsign = 1;
f01038e9:	c7 45 c0 01 00 00 00 	movl   $0x1,-0x40(%ebp)
f01038f0:	eb c6                	jmp    f01038b8 <vprintfmt+0x51>

f01038f2 <.L46>:
		switch (ch = *(unsigned char *) fmt++) {
f01038f2:	0f b6 d2             	movzbl %dl,%edx
f01038f5:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			for (precision = 0; ; ++fmt) {
f01038f8:	b8 00 00 00 00       	mov    $0x0,%eax
f01038fd:	8b 75 08             	mov    0x8(%ebp),%esi
f0103900:	e9 8b 00 00 00       	jmp    f0103990 <.L47+0xf>

f0103905 <.L41>:
f0103905:	8b 75 08             	mov    0x8(%ebp),%esi
			argptr = va_arg(ap, char *);
f0103908:	8b 45 14             	mov    0x14(%ebp),%eax
f010390b:	83 c0 04             	add    $0x4,%eax
f010390e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103911:	8b 45 14             	mov    0x14(%ebp),%eax
f0103914:	8b 18                	mov    (%eax),%ebx
  			if (argptr == NULL){
f0103916:	85 db                	test   %ebx,%ebx
f0103918:	74 18                	je     f0103932 <.L41+0x2d>
  			}else if(*((int *)putdat) >= 255 ){
f010391a:	81 3f fe 00 00 00    	cmpl   $0xfe,(%edi)
f0103920:	7f 36                	jg     f0103958 <.L41+0x53>
    			*argptr = *(char *)putdat;
f0103922:	0f b6 07             	movzbl (%edi),%eax
f0103925:	88 03                	mov    %al,(%ebx)
			argptr = va_arg(ap, char *);
f0103927:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010392a:	89 45 14             	mov    %eax,0x14(%ebp)
f010392d:	e9 dc 03 00 00       	jmp    f0103d0e <.L40+0x73>
    			printfmt(putch,putdat,"%s", null_error);
f0103932:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103935:	8d 82 c0 b5 fe ff    	lea    -0x14a40(%edx),%eax
f010393b:	50                   	push   %eax
f010393c:	8d 82 31 b2 fe ff    	lea    -0x14dcf(%edx),%eax
f0103942:	50                   	push   %eax
f0103943:	57                   	push   %edi
f0103944:	56                   	push   %esi
f0103945:	e8 00 ff ff ff       	call   f010384a <printfmt>
f010394a:	83 c4 10             	add    $0x10,%esp
			argptr = va_arg(ap, char *);
f010394d:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103950:	89 45 14             	mov    %eax,0x14(%ebp)
f0103953:	e9 b6 03 00 00       	jmp    f0103d0e <.L40+0x73>
    			printfmt(putch,putdat,"%s", overflow_error);
f0103958:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010395b:	8d 82 f8 b5 fe ff    	lea    -0x14a08(%edx),%eax
f0103961:	50                   	push   %eax
f0103962:	8d 82 31 b2 fe ff    	lea    -0x14dcf(%edx),%eax
f0103968:	50                   	push   %eax
f0103969:	57                   	push   %edi
f010396a:	56                   	push   %esi
f010396b:	e8 da fe ff ff       	call   f010384a <printfmt>
  				*argptr = -1;
f0103970:	c6 03 ff             	movb   $0xff,(%ebx)
f0103973:	83 c4 10             	add    $0x10,%esp
			argptr = va_arg(ap, char *);
f0103976:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103979:	89 45 14             	mov    %eax,0x14(%ebp)
f010397c:	e9 8d 03 00 00       	jmp    f0103d0e <.L40+0x73>

f0103981 <.L47>:
		switch (ch = *(unsigned char *) fmt++) {
f0103981:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			padc = '0';
f0103984:	c6 45 d3 30          	movb   $0x30,-0x2d(%ebp)
			goto reswitch;
f0103988:	e9 2b ff ff ff       	jmp    f01038b8 <vprintfmt+0x51>
			for (precision = 0; ; ++fmt) {
f010398d:	83 c3 01             	add    $0x1,%ebx
				precision = precision * 10 + ch - '0';
f0103990:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103993:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0103997:	0f be 13             	movsbl (%ebx),%edx
				if (ch < '0' || ch > '9')
f010399a:	8d 4a d0             	lea    -0x30(%edx),%ecx
f010399d:	83 f9 09             	cmp    $0x9,%ecx
f01039a0:	76 eb                	jbe    f010398d <.L47+0xc>
f01039a2:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01039a5:	89 75 08             	mov    %esi,0x8(%ebp)
f01039a8:	eb 14                	jmp    f01039be <.L50+0x14>

f01039aa <.L50>:
			precision = va_arg(ap, int);
f01039aa:	8b 45 14             	mov    0x14(%ebp),%eax
f01039ad:	8b 00                	mov    (%eax),%eax
f01039af:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01039b2:	8b 45 14             	mov    0x14(%ebp),%eax
f01039b5:	8d 40 04             	lea    0x4(%eax),%eax
f01039b8:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01039bb:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			if (width < 0)
f01039be:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f01039c2:	0f 89 f0 fe ff ff    	jns    f01038b8 <vprintfmt+0x51>
				width = precision, precision = -1;
f01039c8:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01039cb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01039ce:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f01039d5:	e9 de fe ff ff       	jmp    f01038b8 <vprintfmt+0x51>

f01039da <.L48>:
f01039da:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01039dd:	85 c0                	test   %eax,%eax
f01039df:	ba 00 00 00 00       	mov    $0x0,%edx
f01039e4:	0f 49 d0             	cmovns %eax,%edx
f01039e7:	89 55 d4             	mov    %edx,-0x2c(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01039ea:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01039ed:	e9 c6 fe ff ff       	jmp    f01038b8 <vprintfmt+0x51>

f01039f2 <.L52>:
f01039f2:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			altflag = 1;
f01039f5:	c7 45 c8 01 00 00 00 	movl   $0x1,-0x38(%ebp)
			goto reswitch;
f01039fc:	e9 b7 fe ff ff       	jmp    f01038b8 <vprintfmt+0x51>

f0103a01 <.L42>:
			lflag++;
f0103a01:	83 45 c4 01          	addl   $0x1,-0x3c(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0103a05:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			goto reswitch;
f0103a08:	e9 ab fe ff ff       	jmp    f01038b8 <vprintfmt+0x51>

f0103a0d <.L45>:
f0103a0d:	8b 75 08             	mov    0x8(%ebp),%esi
			putch(va_arg(ap, int), putdat);
f0103a10:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a13:	8d 58 04             	lea    0x4(%eax),%ebx
f0103a16:	83 ec 08             	sub    $0x8,%esp
f0103a19:	57                   	push   %edi
f0103a1a:	ff 30                	pushl  (%eax)
f0103a1c:	ff d6                	call   *%esi
			break;
f0103a1e:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0103a21:	89 5d 14             	mov    %ebx,0x14(%ebp)
			break;
f0103a24:	e9 e5 02 00 00       	jmp    f0103d0e <.L40+0x73>

f0103a29 <.L43>:
f0103a29:	8b 75 08             	mov    0x8(%ebp),%esi
			err = va_arg(ap, int);
f0103a2c:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a2f:	8d 58 04             	lea    0x4(%eax),%ebx
f0103a32:	8b 00                	mov    (%eax),%eax
f0103a34:	99                   	cltd   
f0103a35:	31 d0                	xor    %edx,%eax
f0103a37:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103a39:	83 f8 06             	cmp    $0x6,%eax
f0103a3c:	7f 2b                	jg     f0103a69 <.L43+0x40>
f0103a3e:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103a41:	8b 94 82 dc ff ff ff 	mov    -0x24(%edx,%eax,4),%edx
f0103a48:	85 d2                	test   %edx,%edx
f0103a4a:	74 1d                	je     f0103a69 <.L43+0x40>
				printfmt(putch, putdat, "%s", p);
f0103a4c:	52                   	push   %edx
f0103a4d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103a50:	8d 80 31 b2 fe ff    	lea    -0x14dcf(%eax),%eax
f0103a56:	50                   	push   %eax
f0103a57:	57                   	push   %edi
f0103a58:	56                   	push   %esi
f0103a59:	e8 ec fd ff ff       	call   f010384a <printfmt>
f0103a5e:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0103a61:	89 5d 14             	mov    %ebx,0x14(%ebp)
f0103a64:	e9 a5 02 00 00       	jmp    f0103d0e <.L40+0x73>
				printfmt(putch, putdat, "error %d", err);
f0103a69:	50                   	push   %eax
f0103a6a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103a6d:	8d 80 4c b5 fe ff    	lea    -0x14ab4(%eax),%eax
f0103a73:	50                   	push   %eax
f0103a74:	57                   	push   %edi
f0103a75:	56                   	push   %esi
f0103a76:	e8 cf fd ff ff       	call   f010384a <printfmt>
f0103a7b:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0103a7e:	89 5d 14             	mov    %ebx,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f0103a81:	e9 88 02 00 00       	jmp    f0103d0e <.L40+0x73>

f0103a86 <.L38>:
f0103a86:	8b 75 08             	mov    0x8(%ebp),%esi
			if ((p = va_arg(ap, char *)) == NULL)
f0103a89:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a8c:	83 c0 04             	add    $0x4,%eax
f0103a8f:	89 45 c0             	mov    %eax,-0x40(%ebp)
f0103a92:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a95:	8b 10                	mov    (%eax),%edx
				p = "(null)";
f0103a97:	85 d2                	test   %edx,%edx
f0103a99:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103a9c:	8d 80 45 b5 fe ff    	lea    -0x14abb(%eax),%eax
f0103aa2:	0f 45 c2             	cmovne %edx,%eax
f0103aa5:	89 45 c4             	mov    %eax,-0x3c(%ebp)
			if (width > 0 && padc != '-')
f0103aa8:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0103aac:	7e 06                	jle    f0103ab4 <.L38+0x2e>
f0103aae:	80 7d d3 2d          	cmpb   $0x2d,-0x2d(%ebp)
f0103ab2:	75 0d                	jne    f0103ac1 <.L38+0x3b>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103ab4:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0103ab7:	89 c3                	mov    %eax,%ebx
f0103ab9:	03 45 d4             	add    -0x2c(%ebp),%eax
f0103abc:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103abf:	eb 56                	jmp    f0103b17 <.L38+0x91>
f0103ac1:	83 ec 08             	sub    $0x8,%esp
f0103ac4:	ff 75 d8             	pushl  -0x28(%ebp)
f0103ac7:	50                   	push   %eax
f0103ac8:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103acb:	e8 fb 04 00 00       	call   f0103fcb <strnlen>
f0103ad0:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0103ad3:	29 c2                	sub    %eax,%edx
f0103ad5:	89 55 bc             	mov    %edx,-0x44(%ebp)
f0103ad8:	83 c4 10             	add    $0x10,%esp
f0103adb:	89 d3                	mov    %edx,%ebx
					putch(padc, putdat);
f0103add:	0f be 45 d3          	movsbl -0x2d(%ebp),%eax
f0103ae1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0103ae4:	eb 0f                	jmp    f0103af5 <.L38+0x6f>
					putch(padc, putdat);
f0103ae6:	83 ec 08             	sub    $0x8,%esp
f0103ae9:	57                   	push   %edi
f0103aea:	ff 75 d4             	pushl  -0x2c(%ebp)
f0103aed:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f0103aef:	83 eb 01             	sub    $0x1,%ebx
f0103af2:	83 c4 10             	add    $0x10,%esp
f0103af5:	85 db                	test   %ebx,%ebx
f0103af7:	7f ed                	jg     f0103ae6 <.L38+0x60>
f0103af9:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0103afc:	85 d2                	test   %edx,%edx
f0103afe:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b03:	0f 49 c2             	cmovns %edx,%eax
f0103b06:	29 c2                	sub    %eax,%edx
f0103b08:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103b0b:	eb a7                	jmp    f0103ab4 <.L38+0x2e>
					putch(ch, putdat);
f0103b0d:	83 ec 08             	sub    $0x8,%esp
f0103b10:	57                   	push   %edi
f0103b11:	52                   	push   %edx
f0103b12:	ff d6                	call   *%esi
f0103b14:	83 c4 10             	add    $0x10,%esp
f0103b17:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0103b1a:	29 d9                	sub    %ebx,%ecx
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103b1c:	83 c3 01             	add    $0x1,%ebx
f0103b1f:	0f b6 43 ff          	movzbl -0x1(%ebx),%eax
f0103b23:	0f be d0             	movsbl %al,%edx
f0103b26:	85 d2                	test   %edx,%edx
f0103b28:	74 4b                	je     f0103b75 <.L38+0xef>
f0103b2a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103b2e:	78 06                	js     f0103b36 <.L38+0xb0>
f0103b30:	83 6d d8 01          	subl   $0x1,-0x28(%ebp)
f0103b34:	78 1e                	js     f0103b54 <.L38+0xce>
				if (altflag && (ch < ' ' || ch > '~'))
f0103b36:	83 7d c8 00          	cmpl   $0x0,-0x38(%ebp)
f0103b3a:	74 d1                	je     f0103b0d <.L38+0x87>
f0103b3c:	0f be c0             	movsbl %al,%eax
f0103b3f:	83 e8 20             	sub    $0x20,%eax
f0103b42:	83 f8 5e             	cmp    $0x5e,%eax
f0103b45:	76 c6                	jbe    f0103b0d <.L38+0x87>
					putch('?', putdat);
f0103b47:	83 ec 08             	sub    $0x8,%esp
f0103b4a:	57                   	push   %edi
f0103b4b:	6a 3f                	push   $0x3f
f0103b4d:	ff d6                	call   *%esi
f0103b4f:	83 c4 10             	add    $0x10,%esp
f0103b52:	eb c3                	jmp    f0103b17 <.L38+0x91>
f0103b54:	89 cb                	mov    %ecx,%ebx
f0103b56:	eb 0e                	jmp    f0103b66 <.L38+0xe0>
				putch(' ', putdat);
f0103b58:	83 ec 08             	sub    $0x8,%esp
f0103b5b:	57                   	push   %edi
f0103b5c:	6a 20                	push   $0x20
f0103b5e:	ff d6                	call   *%esi
			for (; width > 0; width--)
f0103b60:	83 eb 01             	sub    $0x1,%ebx
f0103b63:	83 c4 10             	add    $0x10,%esp
f0103b66:	85 db                	test   %ebx,%ebx
f0103b68:	7f ee                	jg     f0103b58 <.L38+0xd2>
			if ((p = va_arg(ap, char *)) == NULL)
f0103b6a:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0103b6d:	89 45 14             	mov    %eax,0x14(%ebp)
f0103b70:	e9 99 01 00 00       	jmp    f0103d0e <.L40+0x73>
f0103b75:	89 cb                	mov    %ecx,%ebx
f0103b77:	eb ed                	jmp    f0103b66 <.L38+0xe0>

f0103b79 <.L44>:
f0103b79:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0103b7c:	8b 75 08             	mov    0x8(%ebp),%esi
	if (lflag >= 2)
f0103b7f:	83 f9 01             	cmp    $0x1,%ecx
f0103b82:	7f 1b                	jg     f0103b9f <.L44+0x26>
	else if (lflag)
f0103b84:	85 c9                	test   %ecx,%ecx
f0103b86:	74 64                	je     f0103bec <.L44+0x73>
		return va_arg(*ap, long);
f0103b88:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b8b:	8b 00                	mov    (%eax),%eax
f0103b8d:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0103b90:	99                   	cltd   
f0103b91:	89 55 cc             	mov    %edx,-0x34(%ebp)
f0103b94:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b97:	8d 40 04             	lea    0x4(%eax),%eax
f0103b9a:	89 45 14             	mov    %eax,0x14(%ebp)
f0103b9d:	eb 17                	jmp    f0103bb6 <.L44+0x3d>
		return va_arg(*ap, long long);
f0103b9f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ba2:	8b 50 04             	mov    0x4(%eax),%edx
f0103ba5:	8b 00                	mov    (%eax),%eax
f0103ba7:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0103baa:	89 55 cc             	mov    %edx,-0x34(%ebp)
f0103bad:	8b 45 14             	mov    0x14(%ebp),%eax
f0103bb0:	8d 40 08             	lea    0x8(%eax),%eax
f0103bb3:	89 45 14             	mov    %eax,0x14(%ebp)
			num = getint(&ap, lflag);
f0103bb6:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0103bb9:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0103bbc:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103bbf:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
f0103bc2:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0103bc6:	78 3b                	js     f0103c03 <.L44+0x8a>
			base = 10;
f0103bc8:	b8 0a 00 00 00       	mov    $0xa,%eax
			else if(ifsign){
f0103bcd:	83 7d c0 00          	cmpl   $0x0,-0x40(%ebp)
f0103bd1:	0f 84 19 01 00 00    	je     f0103cf0 <.L40+0x55>
				putch('+', putdat);
f0103bd7:	83 ec 08             	sub    $0x8,%esp
f0103bda:	57                   	push   %edi
f0103bdb:	6a 2b                	push   $0x2b
f0103bdd:	ff d6                	call   *%esi
f0103bdf:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0103be2:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103be7:	e9 04 01 00 00       	jmp    f0103cf0 <.L40+0x55>
		return va_arg(*ap, int);
f0103bec:	8b 45 14             	mov    0x14(%ebp),%eax
f0103bef:	8b 00                	mov    (%eax),%eax
f0103bf1:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0103bf4:	99                   	cltd   
f0103bf5:	89 55 cc             	mov    %edx,-0x34(%ebp)
f0103bf8:	8b 45 14             	mov    0x14(%ebp),%eax
f0103bfb:	8d 40 04             	lea    0x4(%eax),%eax
f0103bfe:	89 45 14             	mov    %eax,0x14(%ebp)
f0103c01:	eb b3                	jmp    f0103bb6 <.L44+0x3d>
				putch('-', putdat);
f0103c03:	83 ec 08             	sub    $0x8,%esp
f0103c06:	57                   	push   %edi
f0103c07:	6a 2d                	push   $0x2d
f0103c09:	ff d6                	call   *%esi
				num = -(long long) num;
f0103c0b:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0103c0e:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0103c11:	f7 d8                	neg    %eax
f0103c13:	83 d2 00             	adc    $0x0,%edx
f0103c16:	f7 da                	neg    %edx
f0103c18:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103c1b:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103c1e:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0103c21:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103c26:	e9 c5 00 00 00       	jmp    f0103cf0 <.L40+0x55>

f0103c2b <.L37>:
f0103c2b:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0103c2e:	8b 75 08             	mov    0x8(%ebp),%esi
	if (lflag >= 2)
f0103c31:	83 f9 01             	cmp    $0x1,%ecx
f0103c34:	7f 27                	jg     f0103c5d <.L37+0x32>
	else if (lflag)
f0103c36:	85 c9                	test   %ecx,%ecx
f0103c38:	74 41                	je     f0103c7b <.L37+0x50>
		return va_arg(*ap, unsigned long);
f0103c3a:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c3d:	8b 00                	mov    (%eax),%eax
f0103c3f:	ba 00 00 00 00       	mov    $0x0,%edx
f0103c44:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103c47:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103c4a:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c4d:	8d 40 04             	lea    0x4(%eax),%eax
f0103c50:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0103c53:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103c58:	e9 93 00 00 00       	jmp    f0103cf0 <.L40+0x55>
		return va_arg(*ap, unsigned long long);
f0103c5d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c60:	8b 50 04             	mov    0x4(%eax),%edx
f0103c63:	8b 00                	mov    (%eax),%eax
f0103c65:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103c68:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103c6b:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c6e:	8d 40 08             	lea    0x8(%eax),%eax
f0103c71:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0103c74:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103c79:	eb 75                	jmp    f0103cf0 <.L40+0x55>
		return va_arg(*ap, unsigned int);
f0103c7b:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c7e:	8b 00                	mov    (%eax),%eax
f0103c80:	ba 00 00 00 00       	mov    $0x0,%edx
f0103c85:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103c88:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103c8b:	8b 45 14             	mov    0x14(%ebp),%eax
f0103c8e:	8d 40 04             	lea    0x4(%eax),%eax
f0103c91:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0103c94:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103c99:	eb 55                	jmp    f0103cf0 <.L40+0x55>

f0103c9b <.L40>:
f0103c9b:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0103c9e:	8b 75 08             	mov    0x8(%ebp),%esi
	if (lflag >= 2)
f0103ca1:	83 f9 01             	cmp    $0x1,%ecx
f0103ca4:	7f 23                	jg     f0103cc9 <.L40+0x2e>
	else if (lflag)
f0103ca6:	85 c9                	test   %ecx,%ecx
f0103ca8:	0f 84 87 00 00 00    	je     f0103d35 <.L40+0x9a>
		return va_arg(*ap, unsigned long);
f0103cae:	8b 45 14             	mov    0x14(%ebp),%eax
f0103cb1:	8b 00                	mov    (%eax),%eax
f0103cb3:	ba 00 00 00 00       	mov    $0x0,%edx
f0103cb8:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103cbb:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103cbe:	8b 45 14             	mov    0x14(%ebp),%eax
f0103cc1:	8d 40 04             	lea    0x4(%eax),%eax
f0103cc4:	89 45 14             	mov    %eax,0x14(%ebp)
f0103cc7:	eb 17                	jmp    f0103ce0 <.L40+0x45>
		return va_arg(*ap, unsigned long long);
f0103cc9:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ccc:	8b 50 04             	mov    0x4(%eax),%edx
f0103ccf:	8b 00                	mov    (%eax),%eax
f0103cd1:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103cd4:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103cd7:	8b 45 14             	mov    0x14(%ebp),%eax
f0103cda:	8d 40 08             	lea    0x8(%eax),%eax
f0103cdd:	89 45 14             	mov    %eax,0x14(%ebp)
			putch('0', putdat);
f0103ce0:	83 ec 08             	sub    $0x8,%esp
f0103ce3:	57                   	push   %edi
f0103ce4:	6a 30                	push   $0x30
f0103ce6:	ff d6                	call   *%esi
			goto number;
f0103ce8:	83 c4 10             	add    $0x10,%esp
			base = 8;
f0103ceb:	b8 08 00 00 00       	mov    $0x8,%eax
			printnum(putch, putdat, num, base, width, padc);
f0103cf0:	83 ec 0c             	sub    $0xc,%esp
f0103cf3:	0f be 5d d3          	movsbl -0x2d(%ebp),%ebx
f0103cf7:	53                   	push   %ebx
f0103cf8:	ff 75 d4             	pushl  -0x2c(%ebp)
f0103cfb:	50                   	push   %eax
f0103cfc:	ff 75 dc             	pushl  -0x24(%ebp)
f0103cff:	ff 75 d8             	pushl  -0x28(%ebp)
f0103d02:	89 fa                	mov    %edi,%edx
f0103d04:	89 f0                	mov    %esi,%eax
f0103d06:	e8 00 f9 ff ff       	call   f010360b <printnum>
			break;
f0103d0b:	83 c4 20             	add    $0x20,%esp
			if ((p = va_arg(ap, char *)) == NULL)
f0103d0e:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103d11:	83 c3 01             	add    $0x1,%ebx
f0103d14:	0f b6 43 ff          	movzbl -0x1(%ebx),%eax
f0103d18:	83 f8 25             	cmp    $0x25,%eax
f0103d1b:	0f 84 6c fb ff ff    	je     f010388d <vprintfmt+0x26>
			if (ch == '\0')
f0103d21:	85 c0                	test   %eax,%eax
f0103d23:	0f 84 0c 01 00 00    	je     f0103e35 <.L34+0x23>
			putch(ch, putdat);
f0103d29:	83 ec 08             	sub    $0x8,%esp
f0103d2c:	57                   	push   %edi
f0103d2d:	50                   	push   %eax
f0103d2e:	ff d6                	call   *%esi
f0103d30:	83 c4 10             	add    $0x10,%esp
f0103d33:	eb dc                	jmp    f0103d11 <.L40+0x76>
		return va_arg(*ap, unsigned int);
f0103d35:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d38:	8b 00                	mov    (%eax),%eax
f0103d3a:	ba 00 00 00 00       	mov    $0x0,%edx
f0103d3f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103d42:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103d45:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d48:	8d 40 04             	lea    0x4(%eax),%eax
f0103d4b:	89 45 14             	mov    %eax,0x14(%ebp)
f0103d4e:	eb 90                	jmp    f0103ce0 <.L40+0x45>

f0103d50 <.L39>:
f0103d50:	8b 75 08             	mov    0x8(%ebp),%esi
			putch('0', putdat);
f0103d53:	83 ec 08             	sub    $0x8,%esp
f0103d56:	57                   	push   %edi
f0103d57:	6a 30                	push   $0x30
f0103d59:	ff d6                	call   *%esi
			putch('x', putdat);
f0103d5b:	83 c4 08             	add    $0x8,%esp
f0103d5e:	57                   	push   %edi
f0103d5f:	6a 78                	push   $0x78
f0103d61:	ff d6                	call   *%esi
			num = (unsigned long long)
f0103d63:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d66:	8b 00                	mov    (%eax),%eax
f0103d68:	ba 00 00 00 00       	mov    $0x0,%edx
f0103d6d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103d70:	89 55 dc             	mov    %edx,-0x24(%ebp)
			goto number;
f0103d73:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0103d76:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d79:	8d 40 04             	lea    0x4(%eax),%eax
f0103d7c:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103d7f:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0103d84:	e9 67 ff ff ff       	jmp    f0103cf0 <.L40+0x55>

f0103d89 <.L35>:
f0103d89:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0103d8c:	8b 75 08             	mov    0x8(%ebp),%esi
	if (lflag >= 2)
f0103d8f:	83 f9 01             	cmp    $0x1,%ecx
f0103d92:	7f 27                	jg     f0103dbb <.L35+0x32>
	else if (lflag)
f0103d94:	85 c9                	test   %ecx,%ecx
f0103d96:	74 44                	je     f0103ddc <.L35+0x53>
		return va_arg(*ap, unsigned long);
f0103d98:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d9b:	8b 00                	mov    (%eax),%eax
f0103d9d:	ba 00 00 00 00       	mov    $0x0,%edx
f0103da2:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103da5:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103da8:	8b 45 14             	mov    0x14(%ebp),%eax
f0103dab:	8d 40 04             	lea    0x4(%eax),%eax
f0103dae:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103db1:	b8 10 00 00 00       	mov    $0x10,%eax
f0103db6:	e9 35 ff ff ff       	jmp    f0103cf0 <.L40+0x55>
		return va_arg(*ap, unsigned long long);
f0103dbb:	8b 45 14             	mov    0x14(%ebp),%eax
f0103dbe:	8b 50 04             	mov    0x4(%eax),%edx
f0103dc1:	8b 00                	mov    (%eax),%eax
f0103dc3:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103dc6:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103dc9:	8b 45 14             	mov    0x14(%ebp),%eax
f0103dcc:	8d 40 08             	lea    0x8(%eax),%eax
f0103dcf:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103dd2:	b8 10 00 00 00       	mov    $0x10,%eax
f0103dd7:	e9 14 ff ff ff       	jmp    f0103cf0 <.L40+0x55>
		return va_arg(*ap, unsigned int);
f0103ddc:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ddf:	8b 00                	mov    (%eax),%eax
f0103de1:	ba 00 00 00 00       	mov    $0x0,%edx
f0103de6:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103de9:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0103dec:	8b 45 14             	mov    0x14(%ebp),%eax
f0103def:	8d 40 04             	lea    0x4(%eax),%eax
f0103df2:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0103df5:	b8 10 00 00 00       	mov    $0x10,%eax
f0103dfa:	e9 f1 fe ff ff       	jmp    f0103cf0 <.L40+0x55>

f0103dff <.L51>:
f0103dff:	8b 75 08             	mov    0x8(%ebp),%esi
			putch(ch, putdat);
f0103e02:	83 ec 08             	sub    $0x8,%esp
f0103e05:	57                   	push   %edi
f0103e06:	6a 25                	push   $0x25
f0103e08:	ff d6                	call   *%esi
			break;
f0103e0a:	83 c4 10             	add    $0x10,%esp
f0103e0d:	e9 fc fe ff ff       	jmp    f0103d0e <.L40+0x73>

f0103e12 <.L34>:
f0103e12:	8b 75 08             	mov    0x8(%ebp),%esi
			putch('%', putdat);
f0103e15:	83 ec 08             	sub    $0x8,%esp
f0103e18:	57                   	push   %edi
f0103e19:	6a 25                	push   $0x25
f0103e1b:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103e1d:	83 c4 10             	add    $0x10,%esp
f0103e20:	89 d8                	mov    %ebx,%eax
f0103e22:	eb 03                	jmp    f0103e27 <.L34+0x15>
f0103e24:	83 e8 01             	sub    $0x1,%eax
f0103e27:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0103e2b:	75 f7                	jne    f0103e24 <.L34+0x12>
f0103e2d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103e30:	e9 d9 fe ff ff       	jmp    f0103d0e <.L40+0x73>
}
f0103e35:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103e38:	5b                   	pop    %ebx
f0103e39:	5e                   	pop    %esi
f0103e3a:	5f                   	pop    %edi
f0103e3b:	5d                   	pop    %ebp
f0103e3c:	c3                   	ret    

f0103e3d <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103e3d:	55                   	push   %ebp
f0103e3e:	89 e5                	mov    %esp,%ebp
f0103e40:	53                   	push   %ebx
f0103e41:	83 ec 14             	sub    $0x14,%esp
f0103e44:	e8 06 c3 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103e49:	81 c3 2b 62 01 00    	add    $0x1622b,%ebx
f0103e4f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e52:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103e55:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103e58:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103e5c:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103e5f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103e66:	85 c0                	test   %eax,%eax
f0103e68:	74 2b                	je     f0103e95 <vsnprintf+0x58>
f0103e6a:	85 d2                	test   %edx,%edx
f0103e6c:	7e 27                	jle    f0103e95 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103e6e:	ff 75 14             	pushl  0x14(%ebp)
f0103e71:	ff 75 10             	pushl  0x10(%ebp)
f0103e74:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103e77:	50                   	push   %eax
f0103e78:	8d 83 b9 97 fe ff    	lea    -0x16847(%ebx),%eax
f0103e7e:	50                   	push   %eax
f0103e7f:	e8 e3 f9 ff ff       	call   f0103867 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103e84:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103e87:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103e8a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103e8d:	83 c4 10             	add    $0x10,%esp
}
f0103e90:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103e93:	c9                   	leave  
f0103e94:	c3                   	ret    
		return -E_INVAL;
f0103e95:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0103e9a:	eb f4                	jmp    f0103e90 <vsnprintf+0x53>

f0103e9c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103e9c:	55                   	push   %ebp
f0103e9d:	89 e5                	mov    %esp,%ebp
f0103e9f:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103ea2:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103ea5:	50                   	push   %eax
f0103ea6:	ff 75 10             	pushl  0x10(%ebp)
f0103ea9:	ff 75 0c             	pushl  0xc(%ebp)
f0103eac:	ff 75 08             	pushl  0x8(%ebp)
f0103eaf:	e8 89 ff ff ff       	call   f0103e3d <vsnprintf>
	va_end(ap);

	return rc;
}
f0103eb4:	c9                   	leave  
f0103eb5:	c3                   	ret    

f0103eb6 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103eb6:	55                   	push   %ebp
f0103eb7:	89 e5                	mov    %esp,%ebp
f0103eb9:	57                   	push   %edi
f0103eba:	56                   	push   %esi
f0103ebb:	53                   	push   %ebx
f0103ebc:	83 ec 1c             	sub    $0x1c,%esp
f0103ebf:	e8 8b c2 ff ff       	call   f010014f <__x86.get_pc_thunk.bx>
f0103ec4:	81 c3 b0 61 01 00    	add    $0x161b0,%ebx
f0103eca:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103ecd:	85 c0                	test   %eax,%eax
f0103ecf:	74 13                	je     f0103ee4 <readline+0x2e>
		cprintf("%s", prompt);
f0103ed1:	83 ec 08             	sub    $0x8,%esp
f0103ed4:	50                   	push   %eax
f0103ed5:	8d 83 31 b2 fe ff    	lea    -0x14dcf(%ebx),%eax
f0103edb:	50                   	push   %eax
f0103edc:	e8 9b f3 ff ff       	call   f010327c <cprintf>
f0103ee1:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103ee4:	83 ec 0c             	sub    $0xc,%esp
f0103ee7:	6a 00                	push   $0x0
f0103ee9:	e8 cc c7 ff ff       	call   f01006ba <iscons>
f0103eee:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103ef1:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0103ef4:	bf 00 00 00 00       	mov    $0x0,%edi
f0103ef9:	eb 52                	jmp    f0103f4d <readline+0x97>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f0103efb:	83 ec 08             	sub    $0x8,%esp
f0103efe:	50                   	push   %eax
f0103eff:	8d 83 94 b7 fe ff    	lea    -0x1486c(%ebx),%eax
f0103f05:	50                   	push   %eax
f0103f06:	e8 71 f3 ff ff       	call   f010327c <cprintf>
			return NULL;
f0103f0b:	83 c4 10             	add    $0x10,%esp
f0103f0e:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0103f13:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103f16:	5b                   	pop    %ebx
f0103f17:	5e                   	pop    %esi
f0103f18:	5f                   	pop    %edi
f0103f19:	5d                   	pop    %ebp
f0103f1a:	c3                   	ret    
			if (echoing)
f0103f1b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103f1f:	75 05                	jne    f0103f26 <readline+0x70>
			i--;
f0103f21:	83 ef 01             	sub    $0x1,%edi
f0103f24:	eb 27                	jmp    f0103f4d <readline+0x97>
				cputchar('\b');
f0103f26:	83 ec 0c             	sub    $0xc,%esp
f0103f29:	6a 08                	push   $0x8
f0103f2b:	e8 69 c7 ff ff       	call   f0100699 <cputchar>
f0103f30:	83 c4 10             	add    $0x10,%esp
f0103f33:	eb ec                	jmp    f0103f21 <readline+0x6b>
				cputchar(c);
f0103f35:	83 ec 0c             	sub    $0xc,%esp
f0103f38:	56                   	push   %esi
f0103f39:	e8 5b c7 ff ff       	call   f0100699 <cputchar>
f0103f3e:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0103f41:	89 f0                	mov    %esi,%eax
f0103f43:	88 84 3b 6c 02 00 00 	mov    %al,0x26c(%ebx,%edi,1)
f0103f4a:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0103f4d:	e8 57 c7 ff ff       	call   f01006a9 <getchar>
f0103f52:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f0103f54:	85 c0                	test   %eax,%eax
f0103f56:	78 a3                	js     f0103efb <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103f58:	83 f8 08             	cmp    $0x8,%eax
f0103f5b:	0f 94 c2             	sete   %dl
f0103f5e:	83 f8 7f             	cmp    $0x7f,%eax
f0103f61:	0f 94 c0             	sete   %al
f0103f64:	08 c2                	or     %al,%dl
f0103f66:	74 04                	je     f0103f6c <readline+0xb6>
f0103f68:	85 ff                	test   %edi,%edi
f0103f6a:	7f af                	jg     f0103f1b <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103f6c:	83 fe 1f             	cmp    $0x1f,%esi
f0103f6f:	7e 10                	jle    f0103f81 <readline+0xcb>
f0103f71:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0103f77:	7f 08                	jg     f0103f81 <readline+0xcb>
			if (echoing)
f0103f79:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103f7d:	74 c2                	je     f0103f41 <readline+0x8b>
f0103f7f:	eb b4                	jmp    f0103f35 <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f0103f81:	83 fe 0a             	cmp    $0xa,%esi
f0103f84:	74 05                	je     f0103f8b <readline+0xd5>
f0103f86:	83 fe 0d             	cmp    $0xd,%esi
f0103f89:	75 c2                	jne    f0103f4d <readline+0x97>
			if (echoing)
f0103f8b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103f8f:	75 13                	jne    f0103fa4 <readline+0xee>
			buf[i] = 0;
f0103f91:	c6 84 3b 6c 02 00 00 	movb   $0x0,0x26c(%ebx,%edi,1)
f0103f98:	00 
			return buf;
f0103f99:	8d 83 6c 02 00 00    	lea    0x26c(%ebx),%eax
f0103f9f:	e9 6f ff ff ff       	jmp    f0103f13 <readline+0x5d>
				cputchar('\n');
f0103fa4:	83 ec 0c             	sub    $0xc,%esp
f0103fa7:	6a 0a                	push   $0xa
f0103fa9:	e8 eb c6 ff ff       	call   f0100699 <cputchar>
f0103fae:	83 c4 10             	add    $0x10,%esp
f0103fb1:	eb de                	jmp    f0103f91 <readline+0xdb>

f0103fb3 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103fb3:	55                   	push   %ebp
f0103fb4:	89 e5                	mov    %esp,%ebp
f0103fb6:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103fb9:	b8 00 00 00 00       	mov    $0x0,%eax
f0103fbe:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103fc2:	74 05                	je     f0103fc9 <strlen+0x16>
		n++;
f0103fc4:	83 c0 01             	add    $0x1,%eax
f0103fc7:	eb f5                	jmp    f0103fbe <strlen+0xb>
	return n;
}
f0103fc9:	5d                   	pop    %ebp
f0103fca:	c3                   	ret    

f0103fcb <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103fcb:	55                   	push   %ebp
f0103fcc:	89 e5                	mov    %esp,%ebp
f0103fce:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103fd1:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103fd4:	ba 00 00 00 00       	mov    $0x0,%edx
f0103fd9:	39 c2                	cmp    %eax,%edx
f0103fdb:	74 0d                	je     f0103fea <strnlen+0x1f>
f0103fdd:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0103fe1:	74 05                	je     f0103fe8 <strnlen+0x1d>
		n++;
f0103fe3:	83 c2 01             	add    $0x1,%edx
f0103fe6:	eb f1                	jmp    f0103fd9 <strnlen+0xe>
f0103fe8:	89 d0                	mov    %edx,%eax
	return n;
}
f0103fea:	5d                   	pop    %ebp
f0103feb:	c3                   	ret    

f0103fec <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103fec:	55                   	push   %ebp
f0103fed:	89 e5                	mov    %esp,%ebp
f0103fef:	53                   	push   %ebx
f0103ff0:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ff3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103ff6:	ba 00 00 00 00       	mov    $0x0,%edx
f0103ffb:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0103fff:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0104002:	83 c2 01             	add    $0x1,%edx
f0104005:	84 c9                	test   %cl,%cl
f0104007:	75 f2                	jne    f0103ffb <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0104009:	5b                   	pop    %ebx
f010400a:	5d                   	pop    %ebp
f010400b:	c3                   	ret    

f010400c <strcat>:

char *
strcat(char *dst, const char *src)
{
f010400c:	55                   	push   %ebp
f010400d:	89 e5                	mov    %esp,%ebp
f010400f:	53                   	push   %ebx
f0104010:	83 ec 10             	sub    $0x10,%esp
f0104013:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104016:	53                   	push   %ebx
f0104017:	e8 97 ff ff ff       	call   f0103fb3 <strlen>
f010401c:	83 c4 08             	add    $0x8,%esp
	strcpy(dst + len, src);
f010401f:	ff 75 0c             	pushl  0xc(%ebp)
f0104022:	01 d8                	add    %ebx,%eax
f0104024:	50                   	push   %eax
f0104025:	e8 c2 ff ff ff       	call   f0103fec <strcpy>
	return dst;
}
f010402a:	89 d8                	mov    %ebx,%eax
f010402c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010402f:	c9                   	leave  
f0104030:	c3                   	ret    

f0104031 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104031:	55                   	push   %ebp
f0104032:	89 e5                	mov    %esp,%ebp
f0104034:	56                   	push   %esi
f0104035:	53                   	push   %ebx
f0104036:	8b 45 08             	mov    0x8(%ebp),%eax
f0104039:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010403c:	89 c6                	mov    %eax,%esi
f010403e:	03 75 10             	add    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104041:	89 c2                	mov    %eax,%edx
f0104043:	39 f2                	cmp    %esi,%edx
f0104045:	74 11                	je     f0104058 <strncpy+0x27>
		*dst++ = *src;
f0104047:	83 c2 01             	add    $0x1,%edx
f010404a:	0f b6 19             	movzbl (%ecx),%ebx
f010404d:	88 5a ff             	mov    %bl,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104050:	80 fb 01             	cmp    $0x1,%bl
f0104053:	83 d9 ff             	sbb    $0xffffffff,%ecx
f0104056:	eb eb                	jmp    f0104043 <strncpy+0x12>
	}
	return ret;
}
f0104058:	5b                   	pop    %ebx
f0104059:	5e                   	pop    %esi
f010405a:	5d                   	pop    %ebp
f010405b:	c3                   	ret    

f010405c <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010405c:	55                   	push   %ebp
f010405d:	89 e5                	mov    %esp,%ebp
f010405f:	56                   	push   %esi
f0104060:	53                   	push   %ebx
f0104061:	8b 75 08             	mov    0x8(%ebp),%esi
f0104064:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104067:	8b 55 10             	mov    0x10(%ebp),%edx
f010406a:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010406c:	85 d2                	test   %edx,%edx
f010406e:	74 21                	je     f0104091 <strlcpy+0x35>
f0104070:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0104074:	89 f2                	mov    %esi,%edx
		while (--size > 0 && *src != '\0')
f0104076:	39 c2                	cmp    %eax,%edx
f0104078:	74 14                	je     f010408e <strlcpy+0x32>
f010407a:	0f b6 19             	movzbl (%ecx),%ebx
f010407d:	84 db                	test   %bl,%bl
f010407f:	74 0b                	je     f010408c <strlcpy+0x30>
			*dst++ = *src++;
f0104081:	83 c1 01             	add    $0x1,%ecx
f0104084:	83 c2 01             	add    $0x1,%edx
f0104087:	88 5a ff             	mov    %bl,-0x1(%edx)
f010408a:	eb ea                	jmp    f0104076 <strlcpy+0x1a>
f010408c:	89 d0                	mov    %edx,%eax
		*dst = '\0';
f010408e:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104091:	29 f0                	sub    %esi,%eax
}
f0104093:	5b                   	pop    %ebx
f0104094:	5e                   	pop    %esi
f0104095:	5d                   	pop    %ebp
f0104096:	c3                   	ret    

f0104097 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104097:	55                   	push   %ebp
f0104098:	89 e5                	mov    %esp,%ebp
f010409a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010409d:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01040a0:	0f b6 01             	movzbl (%ecx),%eax
f01040a3:	84 c0                	test   %al,%al
f01040a5:	74 0c                	je     f01040b3 <strcmp+0x1c>
f01040a7:	3a 02                	cmp    (%edx),%al
f01040a9:	75 08                	jne    f01040b3 <strcmp+0x1c>
		p++, q++;
f01040ab:	83 c1 01             	add    $0x1,%ecx
f01040ae:	83 c2 01             	add    $0x1,%edx
f01040b1:	eb ed                	jmp    f01040a0 <strcmp+0x9>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01040b3:	0f b6 c0             	movzbl %al,%eax
f01040b6:	0f b6 12             	movzbl (%edx),%edx
f01040b9:	29 d0                	sub    %edx,%eax
}
f01040bb:	5d                   	pop    %ebp
f01040bc:	c3                   	ret    

f01040bd <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01040bd:	55                   	push   %ebp
f01040be:	89 e5                	mov    %esp,%ebp
f01040c0:	53                   	push   %ebx
f01040c1:	8b 45 08             	mov    0x8(%ebp),%eax
f01040c4:	8b 55 0c             	mov    0xc(%ebp),%edx
f01040c7:	89 c3                	mov    %eax,%ebx
f01040c9:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01040cc:	eb 06                	jmp    f01040d4 <strncmp+0x17>
		n--, p++, q++;
f01040ce:	83 c0 01             	add    $0x1,%eax
f01040d1:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f01040d4:	39 d8                	cmp    %ebx,%eax
f01040d6:	74 16                	je     f01040ee <strncmp+0x31>
f01040d8:	0f b6 08             	movzbl (%eax),%ecx
f01040db:	84 c9                	test   %cl,%cl
f01040dd:	74 04                	je     f01040e3 <strncmp+0x26>
f01040df:	3a 0a                	cmp    (%edx),%cl
f01040e1:	74 eb                	je     f01040ce <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01040e3:	0f b6 00             	movzbl (%eax),%eax
f01040e6:	0f b6 12             	movzbl (%edx),%edx
f01040e9:	29 d0                	sub    %edx,%eax
}
f01040eb:	5b                   	pop    %ebx
f01040ec:	5d                   	pop    %ebp
f01040ed:	c3                   	ret    
		return 0;
f01040ee:	b8 00 00 00 00       	mov    $0x0,%eax
f01040f3:	eb f6                	jmp    f01040eb <strncmp+0x2e>

f01040f5 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01040f5:	55                   	push   %ebp
f01040f6:	89 e5                	mov    %esp,%ebp
f01040f8:	8b 45 08             	mov    0x8(%ebp),%eax
f01040fb:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01040ff:	0f b6 10             	movzbl (%eax),%edx
f0104102:	84 d2                	test   %dl,%dl
f0104104:	74 09                	je     f010410f <strchr+0x1a>
		if (*s == c)
f0104106:	38 ca                	cmp    %cl,%dl
f0104108:	74 0a                	je     f0104114 <strchr+0x1f>
	for (; *s; s++)
f010410a:	83 c0 01             	add    $0x1,%eax
f010410d:	eb f0                	jmp    f01040ff <strchr+0xa>
			return (char *) s;
	return 0;
f010410f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104114:	5d                   	pop    %ebp
f0104115:	c3                   	ret    

f0104116 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104116:	55                   	push   %ebp
f0104117:	89 e5                	mov    %esp,%ebp
f0104119:	8b 45 08             	mov    0x8(%ebp),%eax
f010411c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104120:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0104123:	38 ca                	cmp    %cl,%dl
f0104125:	74 09                	je     f0104130 <strfind+0x1a>
f0104127:	84 d2                	test   %dl,%dl
f0104129:	74 05                	je     f0104130 <strfind+0x1a>
	for (; *s; s++)
f010412b:	83 c0 01             	add    $0x1,%eax
f010412e:	eb f0                	jmp    f0104120 <strfind+0xa>
			break;
	return (char *) s;
}
f0104130:	5d                   	pop    %ebp
f0104131:	c3                   	ret    

f0104132 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104132:	55                   	push   %ebp
f0104133:	89 e5                	mov    %esp,%ebp
f0104135:	57                   	push   %edi
f0104136:	56                   	push   %esi
f0104137:	53                   	push   %ebx
f0104138:	8b 7d 08             	mov    0x8(%ebp),%edi
f010413b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010413e:	85 c9                	test   %ecx,%ecx
f0104140:	74 31                	je     f0104173 <memset+0x41>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104142:	89 f8                	mov    %edi,%eax
f0104144:	09 c8                	or     %ecx,%eax
f0104146:	a8 03                	test   $0x3,%al
f0104148:	75 23                	jne    f010416d <memset+0x3b>
		c &= 0xFF;
f010414a:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010414e:	89 d3                	mov    %edx,%ebx
f0104150:	c1 e3 08             	shl    $0x8,%ebx
f0104153:	89 d0                	mov    %edx,%eax
f0104155:	c1 e0 18             	shl    $0x18,%eax
f0104158:	89 d6                	mov    %edx,%esi
f010415a:	c1 e6 10             	shl    $0x10,%esi
f010415d:	09 f0                	or     %esi,%eax
f010415f:	09 c2                	or     %eax,%edx
f0104161:	09 da                	or     %ebx,%edx
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0104163:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0104166:	89 d0                	mov    %edx,%eax
f0104168:	fc                   	cld    
f0104169:	f3 ab                	rep stos %eax,%es:(%edi)
f010416b:	eb 06                	jmp    f0104173 <memset+0x41>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010416d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104170:	fc                   	cld    
f0104171:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104173:	89 f8                	mov    %edi,%eax
f0104175:	5b                   	pop    %ebx
f0104176:	5e                   	pop    %esi
f0104177:	5f                   	pop    %edi
f0104178:	5d                   	pop    %ebp
f0104179:	c3                   	ret    

f010417a <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010417a:	55                   	push   %ebp
f010417b:	89 e5                	mov    %esp,%ebp
f010417d:	57                   	push   %edi
f010417e:	56                   	push   %esi
f010417f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104182:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104185:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104188:	39 c6                	cmp    %eax,%esi
f010418a:	73 32                	jae    f01041be <memmove+0x44>
f010418c:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010418f:	39 c2                	cmp    %eax,%edx
f0104191:	76 2b                	jbe    f01041be <memmove+0x44>
		s += n;
		d += n;
f0104193:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104196:	89 fe                	mov    %edi,%esi
f0104198:	09 ce                	or     %ecx,%esi
f010419a:	09 d6                	or     %edx,%esi
f010419c:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01041a2:	75 0e                	jne    f01041b2 <memmove+0x38>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01041a4:	83 ef 04             	sub    $0x4,%edi
f01041a7:	8d 72 fc             	lea    -0x4(%edx),%esi
f01041aa:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f01041ad:	fd                   	std    
f01041ae:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01041b0:	eb 09                	jmp    f01041bb <memmove+0x41>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01041b2:	83 ef 01             	sub    $0x1,%edi
f01041b5:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f01041b8:	fd                   	std    
f01041b9:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01041bb:	fc                   	cld    
f01041bc:	eb 1a                	jmp    f01041d8 <memmove+0x5e>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01041be:	89 c2                	mov    %eax,%edx
f01041c0:	09 ca                	or     %ecx,%edx
f01041c2:	09 f2                	or     %esi,%edx
f01041c4:	f6 c2 03             	test   $0x3,%dl
f01041c7:	75 0a                	jne    f01041d3 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01041c9:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f01041cc:	89 c7                	mov    %eax,%edi
f01041ce:	fc                   	cld    
f01041cf:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01041d1:	eb 05                	jmp    f01041d8 <memmove+0x5e>
		else
			asm volatile("cld; rep movsb\n"
f01041d3:	89 c7                	mov    %eax,%edi
f01041d5:	fc                   	cld    
f01041d6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01041d8:	5e                   	pop    %esi
f01041d9:	5f                   	pop    %edi
f01041da:	5d                   	pop    %ebp
f01041db:	c3                   	ret    

f01041dc <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01041dc:	55                   	push   %ebp
f01041dd:	89 e5                	mov    %esp,%ebp
f01041df:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01041e2:	ff 75 10             	pushl  0x10(%ebp)
f01041e5:	ff 75 0c             	pushl  0xc(%ebp)
f01041e8:	ff 75 08             	pushl  0x8(%ebp)
f01041eb:	e8 8a ff ff ff       	call   f010417a <memmove>
}
f01041f0:	c9                   	leave  
f01041f1:	c3                   	ret    

f01041f2 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01041f2:	55                   	push   %ebp
f01041f3:	89 e5                	mov    %esp,%ebp
f01041f5:	56                   	push   %esi
f01041f6:	53                   	push   %ebx
f01041f7:	8b 45 08             	mov    0x8(%ebp),%eax
f01041fa:	8b 55 0c             	mov    0xc(%ebp),%edx
f01041fd:	89 c6                	mov    %eax,%esi
f01041ff:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104202:	39 f0                	cmp    %esi,%eax
f0104204:	74 1c                	je     f0104222 <memcmp+0x30>
		if (*s1 != *s2)
f0104206:	0f b6 08             	movzbl (%eax),%ecx
f0104209:	0f b6 1a             	movzbl (%edx),%ebx
f010420c:	38 d9                	cmp    %bl,%cl
f010420e:	75 08                	jne    f0104218 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0104210:	83 c0 01             	add    $0x1,%eax
f0104213:	83 c2 01             	add    $0x1,%edx
f0104216:	eb ea                	jmp    f0104202 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f0104218:	0f b6 c1             	movzbl %cl,%eax
f010421b:	0f b6 db             	movzbl %bl,%ebx
f010421e:	29 d8                	sub    %ebx,%eax
f0104220:	eb 05                	jmp    f0104227 <memcmp+0x35>
	}

	return 0;
f0104222:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104227:	5b                   	pop    %ebx
f0104228:	5e                   	pop    %esi
f0104229:	5d                   	pop    %ebp
f010422a:	c3                   	ret    

f010422b <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010422b:	55                   	push   %ebp
f010422c:	89 e5                	mov    %esp,%ebp
f010422e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104231:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0104234:	89 c2                	mov    %eax,%edx
f0104236:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0104239:	39 d0                	cmp    %edx,%eax
f010423b:	73 09                	jae    f0104246 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f010423d:	38 08                	cmp    %cl,(%eax)
f010423f:	74 05                	je     f0104246 <memfind+0x1b>
	for (; s < ends; s++)
f0104241:	83 c0 01             	add    $0x1,%eax
f0104244:	eb f3                	jmp    f0104239 <memfind+0xe>
			break;
	return (void *) s;
}
f0104246:	5d                   	pop    %ebp
f0104247:	c3                   	ret    

f0104248 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104248:	55                   	push   %ebp
f0104249:	89 e5                	mov    %esp,%ebp
f010424b:	57                   	push   %edi
f010424c:	56                   	push   %esi
f010424d:	53                   	push   %ebx
f010424e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104251:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104254:	eb 03                	jmp    f0104259 <strtol+0x11>
		s++;
f0104256:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0104259:	0f b6 01             	movzbl (%ecx),%eax
f010425c:	3c 20                	cmp    $0x20,%al
f010425e:	74 f6                	je     f0104256 <strtol+0xe>
f0104260:	3c 09                	cmp    $0x9,%al
f0104262:	74 f2                	je     f0104256 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0104264:	3c 2b                	cmp    $0x2b,%al
f0104266:	74 2a                	je     f0104292 <strtol+0x4a>
	int neg = 0;
f0104268:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f010426d:	3c 2d                	cmp    $0x2d,%al
f010426f:	74 2b                	je     f010429c <strtol+0x54>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104271:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0104277:	75 0f                	jne    f0104288 <strtol+0x40>
f0104279:	80 39 30             	cmpb   $0x30,(%ecx)
f010427c:	74 28                	je     f01042a6 <strtol+0x5e>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010427e:	85 db                	test   %ebx,%ebx
f0104280:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104285:	0f 44 d8             	cmove  %eax,%ebx
f0104288:	b8 00 00 00 00       	mov    $0x0,%eax
f010428d:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0104290:	eb 50                	jmp    f01042e2 <strtol+0x9a>
		s++;
f0104292:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0104295:	bf 00 00 00 00       	mov    $0x0,%edi
f010429a:	eb d5                	jmp    f0104271 <strtol+0x29>
		s++, neg = 1;
f010429c:	83 c1 01             	add    $0x1,%ecx
f010429f:	bf 01 00 00 00       	mov    $0x1,%edi
f01042a4:	eb cb                	jmp    f0104271 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01042a6:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01042aa:	74 0e                	je     f01042ba <strtol+0x72>
	else if (base == 0 && s[0] == '0')
f01042ac:	85 db                	test   %ebx,%ebx
f01042ae:	75 d8                	jne    f0104288 <strtol+0x40>
		s++, base = 8;
f01042b0:	83 c1 01             	add    $0x1,%ecx
f01042b3:	bb 08 00 00 00       	mov    $0x8,%ebx
f01042b8:	eb ce                	jmp    f0104288 <strtol+0x40>
		s += 2, base = 16;
f01042ba:	83 c1 02             	add    $0x2,%ecx
f01042bd:	bb 10 00 00 00       	mov    $0x10,%ebx
f01042c2:	eb c4                	jmp    f0104288 <strtol+0x40>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f01042c4:	8d 72 9f             	lea    -0x61(%edx),%esi
f01042c7:	89 f3                	mov    %esi,%ebx
f01042c9:	80 fb 19             	cmp    $0x19,%bl
f01042cc:	77 29                	ja     f01042f7 <strtol+0xaf>
			dig = *s - 'a' + 10;
f01042ce:	0f be d2             	movsbl %dl,%edx
f01042d1:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f01042d4:	3b 55 10             	cmp    0x10(%ebp),%edx
f01042d7:	7d 30                	jge    f0104309 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f01042d9:	83 c1 01             	add    $0x1,%ecx
f01042dc:	0f af 45 10          	imul   0x10(%ebp),%eax
f01042e0:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f01042e2:	0f b6 11             	movzbl (%ecx),%edx
f01042e5:	8d 72 d0             	lea    -0x30(%edx),%esi
f01042e8:	89 f3                	mov    %esi,%ebx
f01042ea:	80 fb 09             	cmp    $0x9,%bl
f01042ed:	77 d5                	ja     f01042c4 <strtol+0x7c>
			dig = *s - '0';
f01042ef:	0f be d2             	movsbl %dl,%edx
f01042f2:	83 ea 30             	sub    $0x30,%edx
f01042f5:	eb dd                	jmp    f01042d4 <strtol+0x8c>
		else if (*s >= 'A' && *s <= 'Z')
f01042f7:	8d 72 bf             	lea    -0x41(%edx),%esi
f01042fa:	89 f3                	mov    %esi,%ebx
f01042fc:	80 fb 19             	cmp    $0x19,%bl
f01042ff:	77 08                	ja     f0104309 <strtol+0xc1>
			dig = *s - 'A' + 10;
f0104301:	0f be d2             	movsbl %dl,%edx
f0104304:	83 ea 37             	sub    $0x37,%edx
f0104307:	eb cb                	jmp    f01042d4 <strtol+0x8c>
		// we don't properly detect overflow!
	}

	if (endptr)
f0104309:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010430d:	74 05                	je     f0104314 <strtol+0xcc>
		*endptr = (char *) s;
f010430f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104312:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0104314:	89 c2                	mov    %eax,%edx
f0104316:	f7 da                	neg    %edx
f0104318:	85 ff                	test   %edi,%edi
f010431a:	0f 45 c2             	cmovne %edx,%eax
}
f010431d:	5b                   	pop    %ebx
f010431e:	5e                   	pop    %esi
f010431f:	5f                   	pop    %edi
f0104320:	5d                   	pop    %ebp
f0104321:	c3                   	ret    
f0104322:	66 90                	xchg   %ax,%ax
f0104324:	66 90                	xchg   %ax,%ax
f0104326:	66 90                	xchg   %ax,%ax
f0104328:	66 90                	xchg   %ax,%ax
f010432a:	66 90                	xchg   %ax,%ax
f010432c:	66 90                	xchg   %ax,%ax
f010432e:	66 90                	xchg   %ax,%ax

f0104330 <__udivdi3>:
f0104330:	55                   	push   %ebp
f0104331:	57                   	push   %edi
f0104332:	56                   	push   %esi
f0104333:	53                   	push   %ebx
f0104334:	83 ec 1c             	sub    $0x1c,%esp
f0104337:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010433b:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f010433f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0104343:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0104347:	85 d2                	test   %edx,%edx
f0104349:	75 4d                	jne    f0104398 <__udivdi3+0x68>
f010434b:	39 f3                	cmp    %esi,%ebx
f010434d:	76 19                	jbe    f0104368 <__udivdi3+0x38>
f010434f:	31 ff                	xor    %edi,%edi
f0104351:	89 e8                	mov    %ebp,%eax
f0104353:	89 f2                	mov    %esi,%edx
f0104355:	f7 f3                	div    %ebx
f0104357:	89 fa                	mov    %edi,%edx
f0104359:	83 c4 1c             	add    $0x1c,%esp
f010435c:	5b                   	pop    %ebx
f010435d:	5e                   	pop    %esi
f010435e:	5f                   	pop    %edi
f010435f:	5d                   	pop    %ebp
f0104360:	c3                   	ret    
f0104361:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104368:	89 d9                	mov    %ebx,%ecx
f010436a:	85 db                	test   %ebx,%ebx
f010436c:	75 0b                	jne    f0104379 <__udivdi3+0x49>
f010436e:	b8 01 00 00 00       	mov    $0x1,%eax
f0104373:	31 d2                	xor    %edx,%edx
f0104375:	f7 f3                	div    %ebx
f0104377:	89 c1                	mov    %eax,%ecx
f0104379:	31 d2                	xor    %edx,%edx
f010437b:	89 f0                	mov    %esi,%eax
f010437d:	f7 f1                	div    %ecx
f010437f:	89 c6                	mov    %eax,%esi
f0104381:	89 e8                	mov    %ebp,%eax
f0104383:	89 f7                	mov    %esi,%edi
f0104385:	f7 f1                	div    %ecx
f0104387:	89 fa                	mov    %edi,%edx
f0104389:	83 c4 1c             	add    $0x1c,%esp
f010438c:	5b                   	pop    %ebx
f010438d:	5e                   	pop    %esi
f010438e:	5f                   	pop    %edi
f010438f:	5d                   	pop    %ebp
f0104390:	c3                   	ret    
f0104391:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104398:	39 f2                	cmp    %esi,%edx
f010439a:	77 1c                	ja     f01043b8 <__udivdi3+0x88>
f010439c:	0f bd fa             	bsr    %edx,%edi
f010439f:	83 f7 1f             	xor    $0x1f,%edi
f01043a2:	75 2c                	jne    f01043d0 <__udivdi3+0xa0>
f01043a4:	39 f2                	cmp    %esi,%edx
f01043a6:	72 06                	jb     f01043ae <__udivdi3+0x7e>
f01043a8:	31 c0                	xor    %eax,%eax
f01043aa:	39 eb                	cmp    %ebp,%ebx
f01043ac:	77 a9                	ja     f0104357 <__udivdi3+0x27>
f01043ae:	b8 01 00 00 00       	mov    $0x1,%eax
f01043b3:	eb a2                	jmp    f0104357 <__udivdi3+0x27>
f01043b5:	8d 76 00             	lea    0x0(%esi),%esi
f01043b8:	31 ff                	xor    %edi,%edi
f01043ba:	31 c0                	xor    %eax,%eax
f01043bc:	89 fa                	mov    %edi,%edx
f01043be:	83 c4 1c             	add    $0x1c,%esp
f01043c1:	5b                   	pop    %ebx
f01043c2:	5e                   	pop    %esi
f01043c3:	5f                   	pop    %edi
f01043c4:	5d                   	pop    %ebp
f01043c5:	c3                   	ret    
f01043c6:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01043cd:	8d 76 00             	lea    0x0(%esi),%esi
f01043d0:	89 f9                	mov    %edi,%ecx
f01043d2:	b8 20 00 00 00       	mov    $0x20,%eax
f01043d7:	29 f8                	sub    %edi,%eax
f01043d9:	d3 e2                	shl    %cl,%edx
f01043db:	89 54 24 08          	mov    %edx,0x8(%esp)
f01043df:	89 c1                	mov    %eax,%ecx
f01043e1:	89 da                	mov    %ebx,%edx
f01043e3:	d3 ea                	shr    %cl,%edx
f01043e5:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f01043e9:	09 d1                	or     %edx,%ecx
f01043eb:	89 f2                	mov    %esi,%edx
f01043ed:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01043f1:	89 f9                	mov    %edi,%ecx
f01043f3:	d3 e3                	shl    %cl,%ebx
f01043f5:	89 c1                	mov    %eax,%ecx
f01043f7:	d3 ea                	shr    %cl,%edx
f01043f9:	89 f9                	mov    %edi,%ecx
f01043fb:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01043ff:	89 eb                	mov    %ebp,%ebx
f0104401:	d3 e6                	shl    %cl,%esi
f0104403:	89 c1                	mov    %eax,%ecx
f0104405:	d3 eb                	shr    %cl,%ebx
f0104407:	09 de                	or     %ebx,%esi
f0104409:	89 f0                	mov    %esi,%eax
f010440b:	f7 74 24 08          	divl   0x8(%esp)
f010440f:	89 d6                	mov    %edx,%esi
f0104411:	89 c3                	mov    %eax,%ebx
f0104413:	f7 64 24 0c          	mull   0xc(%esp)
f0104417:	39 d6                	cmp    %edx,%esi
f0104419:	72 15                	jb     f0104430 <__udivdi3+0x100>
f010441b:	89 f9                	mov    %edi,%ecx
f010441d:	d3 e5                	shl    %cl,%ebp
f010441f:	39 c5                	cmp    %eax,%ebp
f0104421:	73 04                	jae    f0104427 <__udivdi3+0xf7>
f0104423:	39 d6                	cmp    %edx,%esi
f0104425:	74 09                	je     f0104430 <__udivdi3+0x100>
f0104427:	89 d8                	mov    %ebx,%eax
f0104429:	31 ff                	xor    %edi,%edi
f010442b:	e9 27 ff ff ff       	jmp    f0104357 <__udivdi3+0x27>
f0104430:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0104433:	31 ff                	xor    %edi,%edi
f0104435:	e9 1d ff ff ff       	jmp    f0104357 <__udivdi3+0x27>
f010443a:	66 90                	xchg   %ax,%ax
f010443c:	66 90                	xchg   %ax,%ax
f010443e:	66 90                	xchg   %ax,%ax

f0104440 <__umoddi3>:
f0104440:	55                   	push   %ebp
f0104441:	57                   	push   %edi
f0104442:	56                   	push   %esi
f0104443:	53                   	push   %ebx
f0104444:	83 ec 1c             	sub    $0x1c,%esp
f0104447:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f010444b:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f010444f:	8b 74 24 30          	mov    0x30(%esp),%esi
f0104453:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0104457:	89 da                	mov    %ebx,%edx
f0104459:	85 c0                	test   %eax,%eax
f010445b:	75 43                	jne    f01044a0 <__umoddi3+0x60>
f010445d:	39 df                	cmp    %ebx,%edi
f010445f:	76 17                	jbe    f0104478 <__umoddi3+0x38>
f0104461:	89 f0                	mov    %esi,%eax
f0104463:	f7 f7                	div    %edi
f0104465:	89 d0                	mov    %edx,%eax
f0104467:	31 d2                	xor    %edx,%edx
f0104469:	83 c4 1c             	add    $0x1c,%esp
f010446c:	5b                   	pop    %ebx
f010446d:	5e                   	pop    %esi
f010446e:	5f                   	pop    %edi
f010446f:	5d                   	pop    %ebp
f0104470:	c3                   	ret    
f0104471:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104478:	89 fd                	mov    %edi,%ebp
f010447a:	85 ff                	test   %edi,%edi
f010447c:	75 0b                	jne    f0104489 <__umoddi3+0x49>
f010447e:	b8 01 00 00 00       	mov    $0x1,%eax
f0104483:	31 d2                	xor    %edx,%edx
f0104485:	f7 f7                	div    %edi
f0104487:	89 c5                	mov    %eax,%ebp
f0104489:	89 d8                	mov    %ebx,%eax
f010448b:	31 d2                	xor    %edx,%edx
f010448d:	f7 f5                	div    %ebp
f010448f:	89 f0                	mov    %esi,%eax
f0104491:	f7 f5                	div    %ebp
f0104493:	89 d0                	mov    %edx,%eax
f0104495:	eb d0                	jmp    f0104467 <__umoddi3+0x27>
f0104497:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f010449e:	66 90                	xchg   %ax,%ax
f01044a0:	89 f1                	mov    %esi,%ecx
f01044a2:	39 d8                	cmp    %ebx,%eax
f01044a4:	76 0a                	jbe    f01044b0 <__umoddi3+0x70>
f01044a6:	89 f0                	mov    %esi,%eax
f01044a8:	83 c4 1c             	add    $0x1c,%esp
f01044ab:	5b                   	pop    %ebx
f01044ac:	5e                   	pop    %esi
f01044ad:	5f                   	pop    %edi
f01044ae:	5d                   	pop    %ebp
f01044af:	c3                   	ret    
f01044b0:	0f bd e8             	bsr    %eax,%ebp
f01044b3:	83 f5 1f             	xor    $0x1f,%ebp
f01044b6:	75 20                	jne    f01044d8 <__umoddi3+0x98>
f01044b8:	39 d8                	cmp    %ebx,%eax
f01044ba:	0f 82 b0 00 00 00    	jb     f0104570 <__umoddi3+0x130>
f01044c0:	39 f7                	cmp    %esi,%edi
f01044c2:	0f 86 a8 00 00 00    	jbe    f0104570 <__umoddi3+0x130>
f01044c8:	89 c8                	mov    %ecx,%eax
f01044ca:	83 c4 1c             	add    $0x1c,%esp
f01044cd:	5b                   	pop    %ebx
f01044ce:	5e                   	pop    %esi
f01044cf:	5f                   	pop    %edi
f01044d0:	5d                   	pop    %ebp
f01044d1:	c3                   	ret    
f01044d2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01044d8:	89 e9                	mov    %ebp,%ecx
f01044da:	ba 20 00 00 00       	mov    $0x20,%edx
f01044df:	29 ea                	sub    %ebp,%edx
f01044e1:	d3 e0                	shl    %cl,%eax
f01044e3:	89 44 24 08          	mov    %eax,0x8(%esp)
f01044e7:	89 d1                	mov    %edx,%ecx
f01044e9:	89 f8                	mov    %edi,%eax
f01044eb:	d3 e8                	shr    %cl,%eax
f01044ed:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f01044f1:	89 54 24 04          	mov    %edx,0x4(%esp)
f01044f5:	8b 54 24 04          	mov    0x4(%esp),%edx
f01044f9:	09 c1                	or     %eax,%ecx
f01044fb:	89 d8                	mov    %ebx,%eax
f01044fd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104501:	89 e9                	mov    %ebp,%ecx
f0104503:	d3 e7                	shl    %cl,%edi
f0104505:	89 d1                	mov    %edx,%ecx
f0104507:	d3 e8                	shr    %cl,%eax
f0104509:	89 e9                	mov    %ebp,%ecx
f010450b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010450f:	d3 e3                	shl    %cl,%ebx
f0104511:	89 c7                	mov    %eax,%edi
f0104513:	89 d1                	mov    %edx,%ecx
f0104515:	89 f0                	mov    %esi,%eax
f0104517:	d3 e8                	shr    %cl,%eax
f0104519:	89 e9                	mov    %ebp,%ecx
f010451b:	89 fa                	mov    %edi,%edx
f010451d:	d3 e6                	shl    %cl,%esi
f010451f:	09 d8                	or     %ebx,%eax
f0104521:	f7 74 24 08          	divl   0x8(%esp)
f0104525:	89 d1                	mov    %edx,%ecx
f0104527:	89 f3                	mov    %esi,%ebx
f0104529:	f7 64 24 0c          	mull   0xc(%esp)
f010452d:	89 c6                	mov    %eax,%esi
f010452f:	89 d7                	mov    %edx,%edi
f0104531:	39 d1                	cmp    %edx,%ecx
f0104533:	72 06                	jb     f010453b <__umoddi3+0xfb>
f0104535:	75 10                	jne    f0104547 <__umoddi3+0x107>
f0104537:	39 c3                	cmp    %eax,%ebx
f0104539:	73 0c                	jae    f0104547 <__umoddi3+0x107>
f010453b:	2b 44 24 0c          	sub    0xc(%esp),%eax
f010453f:	1b 54 24 08          	sbb    0x8(%esp),%edx
f0104543:	89 d7                	mov    %edx,%edi
f0104545:	89 c6                	mov    %eax,%esi
f0104547:	89 ca                	mov    %ecx,%edx
f0104549:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010454e:	29 f3                	sub    %esi,%ebx
f0104550:	19 fa                	sbb    %edi,%edx
f0104552:	89 d0                	mov    %edx,%eax
f0104554:	d3 e0                	shl    %cl,%eax
f0104556:	89 e9                	mov    %ebp,%ecx
f0104558:	d3 eb                	shr    %cl,%ebx
f010455a:	d3 ea                	shr    %cl,%edx
f010455c:	09 d8                	or     %ebx,%eax
f010455e:	83 c4 1c             	add    $0x1c,%esp
f0104561:	5b                   	pop    %ebx
f0104562:	5e                   	pop    %esi
f0104563:	5f                   	pop    %edi
f0104564:	5d                   	pop    %ebp
f0104565:	c3                   	ret    
f0104566:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f010456d:	8d 76 00             	lea    0x0(%esi),%esi
f0104570:	89 da                	mov    %ebx,%edx
f0104572:	29 fe                	sub    %edi,%esi
f0104574:	19 c2                	sbb    %eax,%edx
f0104576:	89 f1                	mov    %esi,%ecx
f0104578:	89 c8                	mov    %ecx,%eax
f010457a:	e9 4b ff ff ff       	jmp    f01044ca <__umoddi3+0x8a>
