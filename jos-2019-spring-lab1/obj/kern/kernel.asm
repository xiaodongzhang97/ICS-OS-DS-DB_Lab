
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
f0100015:	b8 00 30 11 00       	mov    $0x113000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

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
f0100034:	bc 00 10 11 f0       	mov    $0xf0111000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 68 00 00 00       	call   f01000a6 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	56                   	push   %esi
f0100044:	53                   	push   %ebx
f0100045:	e8 36 02 00 00       	call   f0100280 <__x86.get_pc_thunk.bx>
f010004a:	81 c3 2a 40 01 00    	add    $0x1402a,%ebx
f0100050:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("entering test_backtrace %d\n", x);
f0100053:	83 ec 08             	sub    $0x8,%esp
f0100056:	56                   	push   %esi
f0100057:	8d 83 0c e0 fe ff    	lea    -0x11ff4(%ebx),%eax
f010005d:	50                   	push   %eax
f010005e:	e8 15 0d 00 00       	call   f0100d78 <cprintf>
	if (x > 0)
f0100063:	83 c4 10             	add    $0x10,%esp
f0100066:	85 f6                	test   %esi,%esi
f0100068:	7e 29                	jle    f0100093 <test_backtrace+0x53>
		test_backtrace(x-1);
f010006a:	83 ec 0c             	sub    $0xc,%esp
f010006d:	8d 46 ff             	lea    -0x1(%esi),%eax
f0100070:	50                   	push   %eax
f0100071:	e8 ca ff ff ff       	call   f0100040 <test_backtrace>
f0100076:	83 c4 10             	add    $0x10,%esp
	else
		mon_backtrace(0, 0, 0);
	cprintf("leaving test_backtrace %d\n", x);
f0100079:	83 ec 08             	sub    $0x8,%esp
f010007c:	56                   	push   %esi
f010007d:	8d 83 28 e0 fe ff    	lea    -0x11fd8(%ebx),%eax
f0100083:	50                   	push   %eax
f0100084:	e8 ef 0c 00 00       	call   f0100d78 <cprintf>
}
f0100089:	83 c4 10             	add    $0x10,%esp
f010008c:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010008f:	5b                   	pop    %ebx
f0100090:	5e                   	pop    %esi
f0100091:	5d                   	pop    %ebp
f0100092:	c3                   	ret    
		mon_backtrace(0, 0, 0);
f0100093:	83 ec 04             	sub    $0x4,%esp
f0100096:	6a 00                	push   $0x0
f0100098:	6a 00                	push   $0x0
f010009a:	6a 00                	push   $0x0
f010009c:	e8 42 0a 00 00       	call   f0100ae3 <mon_backtrace>
f01000a1:	83 c4 10             	add    $0x10,%esp
f01000a4:	eb d3                	jmp    f0100079 <test_backtrace+0x39>

f01000a6 <i386_init>:

void
i386_init(void)
{
f01000a6:	55                   	push   %ebp
f01000a7:	89 e5                	mov    %esp,%ebp
f01000a9:	57                   	push   %edi
f01000aa:	56                   	push   %esi
f01000ab:	53                   	push   %ebx
f01000ac:	81 ec 20 01 00 00    	sub    $0x120,%esp
f01000b2:	e8 c9 01 00 00       	call   f0100280 <__x86.get_pc_thunk.bx>
f01000b7:	81 c3 bd 3f 01 00    	add    $0x13fbd,%ebx
	extern char edata[], end[];
   	// Lab1 only
	char chnum1 = 0, chnum2 = 0, ntest[256] = {};
f01000bd:	c6 45 e7 00          	movb   $0x0,-0x19(%ebp)
f01000c1:	c6 45 e6 00          	movb   $0x0,-0x1a(%ebp)
f01000c5:	c7 85 e6 fe ff ff 00 	movl   $0x0,-0x11a(%ebp)
f01000cc:	00 00 00 
f01000cf:	c7 45 e2 00 00 00 00 	movl   $0x0,-0x1e(%ebp)
f01000d6:	8d bd e8 fe ff ff    	lea    -0x118(%ebp),%edi
f01000dc:	b9 3f 00 00 00       	mov    $0x3f,%ecx
f01000e1:	b8 00 00 00 00       	mov    $0x0,%eax
f01000e6:	f3 ab                	rep stos %eax,%es:(%edi)

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000e8:	c7 c2 80 40 11 f0    	mov    $0xf0114080,%edx
f01000ee:	c7 c0 c0 46 11 f0    	mov    $0xf01146c0,%eax
f01000f4:	29 d0                	sub    %edx,%eax
f01000f6:	50                   	push   %eax
f01000f7:	6a 00                	push   $0x0
f01000f9:	52                   	push   %edx
f01000fa:	e8 2f 1b 00 00       	call   f0101c2e <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000ff:	e8 a4 05 00 00       	call   f01006a8 <cons_init>

	cprintf("6828 decimal is %o octal!%n\n%n", 6828, &chnum1, &chnum2);
f0100104:	8d 45 e6             	lea    -0x1a(%ebp),%eax
f0100107:	50                   	push   %eax
f0100108:	8d 7d e7             	lea    -0x19(%ebp),%edi
f010010b:	57                   	push   %edi
f010010c:	68 ac 1a 00 00       	push   $0x1aac
f0100111:	8d 83 bc e0 fe ff    	lea    -0x11f44(%ebx),%eax
f0100117:	50                   	push   %eax
f0100118:	e8 5b 0c 00 00       	call   f0100d78 <cprintf>
	cprintf("pading space in the right to number 22: %-8d.\n", 22);
f010011d:	83 c4 18             	add    $0x18,%esp
f0100120:	6a 16                	push   $0x16
f0100122:	8d 83 dc e0 fe ff    	lea    -0x11f24(%ebx),%eax
f0100128:	50                   	push   %eax
f0100129:	e8 4a 0c 00 00       	call   f0100d78 <cprintf>
	cprintf("chnum1: %d chnum2: %d\n", chnum1, chnum2);
f010012e:	83 c4 0c             	add    $0xc,%esp
f0100131:	0f be 45 e6          	movsbl -0x1a(%ebp),%eax
f0100135:	50                   	push   %eax
f0100136:	0f be 45 e7          	movsbl -0x19(%ebp),%eax
f010013a:	50                   	push   %eax
f010013b:	8d 83 43 e0 fe ff    	lea    -0x11fbd(%ebx),%eax
f0100141:	50                   	push   %eax
f0100142:	e8 31 0c 00 00       	call   f0100d78 <cprintf>
	cprintf("%n", NULL);
f0100147:	83 c4 08             	add    $0x8,%esp
f010014a:	6a 00                	push   $0x0
f010014c:	8d 83 5c e0 fe ff    	lea    -0x11fa4(%ebx),%eax
f0100152:	50                   	push   %eax
f0100153:	e8 20 0c 00 00       	call   f0100d78 <cprintf>
	memset(ntest, 0xd, sizeof(ntest) - 1);
f0100158:	83 c4 0c             	add    $0xc,%esp
f010015b:	68 ff 00 00 00       	push   $0xff
f0100160:	6a 0d                	push   $0xd
f0100162:	8d b5 e6 fe ff ff    	lea    -0x11a(%ebp),%esi
f0100168:	56                   	push   %esi
f0100169:	e8 c0 1a 00 00       	call   f0101c2e <memset>
	cprintf("%s%n", ntest, &chnum1); 
f010016e:	83 c4 0c             	add    $0xc,%esp
f0100171:	57                   	push   %edi
f0100172:	56                   	push   %esi
f0100173:	8d 83 5a e0 fe ff    	lea    -0x11fa6(%ebx),%eax
f0100179:	50                   	push   %eax
f010017a:	e8 f9 0b 00 00       	call   f0100d78 <cprintf>
	cprintf("chnum1: %d\n", chnum1);
f010017f:	83 c4 08             	add    $0x8,%esp
f0100182:	0f be 45 e7          	movsbl -0x19(%ebp),%eax
f0100186:	50                   	push   %eax
f0100187:	8d 83 5f e0 fe ff    	lea    -0x11fa1(%ebx),%eax
f010018d:	50                   	push   %eax
f010018e:	e8 e5 0b 00 00       	call   f0100d78 <cprintf>
	cprintf("show me the sign: %+d, %+d\n", 1024, -1024);
f0100193:	83 c4 0c             	add    $0xc,%esp
f0100196:	68 00 fc ff ff       	push   $0xfffffc00
f010019b:	68 00 04 00 00       	push   $0x400
f01001a0:	8d 83 6b e0 fe ff    	lea    -0x11f95(%ebx),%eax
f01001a6:	50                   	push   %eax
f01001a7:	e8 cc 0b 00 00       	call   f0100d78 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01001ac:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01001b3:	e8 88 fe ff ff       	call   f0100040 <test_backtrace>
f01001b8:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01001bb:	83 ec 0c             	sub    $0xc,%esp
f01001be:	6a 00                	push   $0x0
f01001c0:	e8 ef 09 00 00       	call   f0100bb4 <monitor>
f01001c5:	83 c4 10             	add    $0x10,%esp
f01001c8:	eb f1                	jmp    f01001bb <i386_init+0x115>

f01001ca <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01001ca:	55                   	push   %ebp
f01001cb:	89 e5                	mov    %esp,%ebp
f01001cd:	57                   	push   %edi
f01001ce:	56                   	push   %esi
f01001cf:	53                   	push   %ebx
f01001d0:	83 ec 0c             	sub    $0xc,%esp
f01001d3:	e8 a8 00 00 00       	call   f0100280 <__x86.get_pc_thunk.bx>
f01001d8:	81 c3 9c 3e 01 00    	add    $0x13e9c,%ebx
f01001de:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
f01001e1:	c7 c0 c4 46 11 f0    	mov    $0xf01146c4,%eax
f01001e7:	83 38 00             	cmpl   $0x0,(%eax)
f01001ea:	74 0f                	je     f01001fb <_panic+0x31>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01001ec:	83 ec 0c             	sub    $0xc,%esp
f01001ef:	6a 00                	push   $0x0
f01001f1:	e8 be 09 00 00       	call   f0100bb4 <monitor>
f01001f6:	83 c4 10             	add    $0x10,%esp
f01001f9:	eb f1                	jmp    f01001ec <_panic+0x22>
	panicstr = fmt;
f01001fb:	89 38                	mov    %edi,(%eax)
	asm volatile("cli; cld");
f01001fd:	fa                   	cli    
f01001fe:	fc                   	cld    
	va_start(ap, fmt);
f01001ff:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel panic at %s:%d: ", file, line);
f0100202:	83 ec 04             	sub    $0x4,%esp
f0100205:	ff 75 0c             	pushl  0xc(%ebp)
f0100208:	ff 75 08             	pushl  0x8(%ebp)
f010020b:	8d 83 87 e0 fe ff    	lea    -0x11f79(%ebx),%eax
f0100211:	50                   	push   %eax
f0100212:	e8 61 0b 00 00       	call   f0100d78 <cprintf>
	vcprintf(fmt, ap);
f0100217:	83 c4 08             	add    $0x8,%esp
f010021a:	56                   	push   %esi
f010021b:	57                   	push   %edi
f010021c:	e8 20 0b 00 00       	call   f0100d41 <vcprintf>
	cprintf("\n");
f0100221:	8d 83 15 e1 fe ff    	lea    -0x11eeb(%ebx),%eax
f0100227:	89 04 24             	mov    %eax,(%esp)
f010022a:	e8 49 0b 00 00       	call   f0100d78 <cprintf>
f010022f:	83 c4 10             	add    $0x10,%esp
f0100232:	eb b8                	jmp    f01001ec <_panic+0x22>

f0100234 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100234:	55                   	push   %ebp
f0100235:	89 e5                	mov    %esp,%ebp
f0100237:	56                   	push   %esi
f0100238:	53                   	push   %ebx
f0100239:	e8 42 00 00 00       	call   f0100280 <__x86.get_pc_thunk.bx>
f010023e:	81 c3 36 3e 01 00    	add    $0x13e36,%ebx
	va_list ap;

	va_start(ap, fmt);
f0100244:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f0100247:	83 ec 04             	sub    $0x4,%esp
f010024a:	ff 75 0c             	pushl  0xc(%ebp)
f010024d:	ff 75 08             	pushl  0x8(%ebp)
f0100250:	8d 83 9f e0 fe ff    	lea    -0x11f61(%ebx),%eax
f0100256:	50                   	push   %eax
f0100257:	e8 1c 0b 00 00       	call   f0100d78 <cprintf>
	vcprintf(fmt, ap);
f010025c:	83 c4 08             	add    $0x8,%esp
f010025f:	56                   	push   %esi
f0100260:	ff 75 10             	pushl  0x10(%ebp)
f0100263:	e8 d9 0a 00 00       	call   f0100d41 <vcprintf>
	cprintf("\n");
f0100268:	8d 83 15 e1 fe ff    	lea    -0x11eeb(%ebx),%eax
f010026e:	89 04 24             	mov    %eax,(%esp)
f0100271:	e8 02 0b 00 00       	call   f0100d78 <cprintf>
	va_end(ap);
}
f0100276:	83 c4 10             	add    $0x10,%esp
f0100279:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010027c:	5b                   	pop    %ebx
f010027d:	5e                   	pop    %esi
f010027e:	5d                   	pop    %ebp
f010027f:	c3                   	ret    

f0100280 <__x86.get_pc_thunk.bx>:
f0100280:	8b 1c 24             	mov    (%esp),%ebx
f0100283:	c3                   	ret    

f0100284 <serial_proc_data>:

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100284:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100289:	ec                   	in     (%dx),%al
static bool serial_exists;

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010028a:	a8 01                	test   $0x1,%al
f010028c:	74 0a                	je     f0100298 <serial_proc_data+0x14>
f010028e:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100293:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100294:	0f b6 c0             	movzbl %al,%eax
f0100297:	c3                   	ret    
		return -1;
f0100298:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f010029d:	c3                   	ret    

f010029e <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010029e:	55                   	push   %ebp
f010029f:	89 e5                	mov    %esp,%ebp
f01002a1:	56                   	push   %esi
f01002a2:	53                   	push   %ebx
f01002a3:	e8 d8 ff ff ff       	call   f0100280 <__x86.get_pc_thunk.bx>
f01002a8:	81 c3 cc 3d 01 00    	add    $0x13dcc,%ebx
f01002ae:	89 c6                	mov    %eax,%esi
	int c;

	while ((c = (*proc)()) != -1) {
f01002b0:	ff d6                	call   *%esi
f01002b2:	83 f8 ff             	cmp    $0xffffffff,%eax
f01002b5:	74 2a                	je     f01002e1 <cons_intr+0x43>
		if (c == 0)
f01002b7:	85 c0                	test   %eax,%eax
f01002b9:	74 f5                	je     f01002b0 <cons_intr+0x12>
			continue;
		cons.buf[cons.wpos++] = c;
f01002bb:	8b 8b 30 02 00 00    	mov    0x230(%ebx),%ecx
f01002c1:	8d 51 01             	lea    0x1(%ecx),%edx
f01002c4:	88 84 0b 2c 00 00 00 	mov    %al,0x2c(%ebx,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f01002cb:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.wpos = 0;
f01002d1:	b8 00 00 00 00       	mov    $0x0,%eax
f01002d6:	0f 44 d0             	cmove  %eax,%edx
f01002d9:	89 93 30 02 00 00    	mov    %edx,0x230(%ebx)
f01002df:	eb cf                	jmp    f01002b0 <cons_intr+0x12>
	}
}
f01002e1:	5b                   	pop    %ebx
f01002e2:	5e                   	pop    %esi
f01002e3:	5d                   	pop    %ebp
f01002e4:	c3                   	ret    

f01002e5 <kbd_proc_data>:
{
f01002e5:	55                   	push   %ebp
f01002e6:	89 e5                	mov    %esp,%ebp
f01002e8:	56                   	push   %esi
f01002e9:	53                   	push   %ebx
f01002ea:	e8 91 ff ff ff       	call   f0100280 <__x86.get_pc_thunk.bx>
f01002ef:	81 c3 85 3d 01 00    	add    $0x13d85,%ebx
f01002f5:	ba 64 00 00 00       	mov    $0x64,%edx
f01002fa:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f01002fb:	a8 01                	test   $0x1,%al
f01002fd:	0f 84 fb 00 00 00    	je     f01003fe <kbd_proc_data+0x119>
	if (stat & KBS_TERR)
f0100303:	a8 20                	test   $0x20,%al
f0100305:	0f 85 fa 00 00 00    	jne    f0100405 <kbd_proc_data+0x120>
f010030b:	ba 60 00 00 00       	mov    $0x60,%edx
f0100310:	ec                   	in     (%dx),%al
f0100311:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f0100313:	3c e0                	cmp    $0xe0,%al
f0100315:	74 64                	je     f010037b <kbd_proc_data+0x96>
	} else if (data & 0x80) {
f0100317:	84 c0                	test   %al,%al
f0100319:	78 75                	js     f0100390 <kbd_proc_data+0xab>
	} else if (shift & E0ESC) {
f010031b:	8b 8b 0c 00 00 00    	mov    0xc(%ebx),%ecx
f0100321:	f6 c1 40             	test   $0x40,%cl
f0100324:	74 0e                	je     f0100334 <kbd_proc_data+0x4f>
		data |= 0x80;
f0100326:	83 c8 80             	or     $0xffffff80,%eax
f0100329:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010032b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010032e:	89 8b 0c 00 00 00    	mov    %ecx,0xc(%ebx)
	shift |= shiftcode[data];
f0100334:	0f b6 d2             	movzbl %dl,%edx
f0100337:	0f b6 84 13 4c e2 fe 	movzbl -0x11db4(%ebx,%edx,1),%eax
f010033e:	ff 
f010033f:	0b 83 0c 00 00 00    	or     0xc(%ebx),%eax
	shift ^= togglecode[data];
f0100345:	0f b6 8c 13 4c e1 fe 	movzbl -0x11eb4(%ebx,%edx,1),%ecx
f010034c:	ff 
f010034d:	31 c8                	xor    %ecx,%eax
f010034f:	89 83 0c 00 00 00    	mov    %eax,0xc(%ebx)
	c = charcode[shift & (CTL | SHIFT)][data];
f0100355:	89 c1                	mov    %eax,%ecx
f0100357:	83 e1 03             	and    $0x3,%ecx
f010035a:	8b 8c 8b 8c ff ff ff 	mov    -0x74(%ebx,%ecx,4),%ecx
f0100361:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100365:	0f b6 f2             	movzbl %dl,%esi
	if (shift & CAPSLOCK) {
f0100368:	a8 08                	test   $0x8,%al
f010036a:	74 65                	je     f01003d1 <kbd_proc_data+0xec>
		if ('a' <= c && c <= 'z')
f010036c:	89 f2                	mov    %esi,%edx
f010036e:	8d 4e 9f             	lea    -0x61(%esi),%ecx
f0100371:	83 f9 19             	cmp    $0x19,%ecx
f0100374:	77 4f                	ja     f01003c5 <kbd_proc_data+0xe0>
			c += 'A' - 'a';
f0100376:	83 ee 20             	sub    $0x20,%esi
f0100379:	eb 0c                	jmp    f0100387 <kbd_proc_data+0xa2>
		shift |= E0ESC;
f010037b:	83 8b 0c 00 00 00 40 	orl    $0x40,0xc(%ebx)
		return 0;
f0100382:	be 00 00 00 00       	mov    $0x0,%esi
}
f0100387:	89 f0                	mov    %esi,%eax
f0100389:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010038c:	5b                   	pop    %ebx
f010038d:	5e                   	pop    %esi
f010038e:	5d                   	pop    %ebp
f010038f:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f0100390:	8b 8b 0c 00 00 00    	mov    0xc(%ebx),%ecx
f0100396:	89 ce                	mov    %ecx,%esi
f0100398:	83 e6 40             	and    $0x40,%esi
f010039b:	83 e0 7f             	and    $0x7f,%eax
f010039e:	85 f6                	test   %esi,%esi
f01003a0:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01003a3:	0f b6 d2             	movzbl %dl,%edx
f01003a6:	0f b6 84 13 4c e2 fe 	movzbl -0x11db4(%ebx,%edx,1),%eax
f01003ad:	ff 
f01003ae:	83 c8 40             	or     $0x40,%eax
f01003b1:	0f b6 c0             	movzbl %al,%eax
f01003b4:	f7 d0                	not    %eax
f01003b6:	21 c8                	and    %ecx,%eax
f01003b8:	89 83 0c 00 00 00    	mov    %eax,0xc(%ebx)
		return 0;
f01003be:	be 00 00 00 00       	mov    $0x0,%esi
f01003c3:	eb c2                	jmp    f0100387 <kbd_proc_data+0xa2>
		else if ('A' <= c && c <= 'Z')
f01003c5:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01003c8:	8d 4e 20             	lea    0x20(%esi),%ecx
f01003cb:	83 fa 1a             	cmp    $0x1a,%edx
f01003ce:	0f 42 f1             	cmovb  %ecx,%esi
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01003d1:	f7 d0                	not    %eax
f01003d3:	a8 06                	test   $0x6,%al
f01003d5:	75 b0                	jne    f0100387 <kbd_proc_data+0xa2>
f01003d7:	81 fe e9 00 00 00    	cmp    $0xe9,%esi
f01003dd:	75 a8                	jne    f0100387 <kbd_proc_data+0xa2>
		cprintf("Rebooting!\n");
f01003df:	83 ec 0c             	sub    $0xc,%esp
f01003e2:	8d 83 0b e1 fe ff    	lea    -0x11ef5(%ebx),%eax
f01003e8:	50                   	push   %eax
f01003e9:	e8 8a 09 00 00       	call   f0100d78 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003ee:	b8 03 00 00 00       	mov    $0x3,%eax
f01003f3:	ba 92 00 00 00       	mov    $0x92,%edx
f01003f8:	ee                   	out    %al,(%dx)
f01003f9:	83 c4 10             	add    $0x10,%esp
f01003fc:	eb 89                	jmp    f0100387 <kbd_proc_data+0xa2>
		return -1;
f01003fe:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0100403:	eb 82                	jmp    f0100387 <kbd_proc_data+0xa2>
		return -1;
f0100405:	be ff ff ff ff       	mov    $0xffffffff,%esi
f010040a:	e9 78 ff ff ff       	jmp    f0100387 <kbd_proc_data+0xa2>

f010040f <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010040f:	55                   	push   %ebp
f0100410:	89 e5                	mov    %esp,%ebp
f0100412:	57                   	push   %edi
f0100413:	56                   	push   %esi
f0100414:	53                   	push   %ebx
f0100415:	83 ec 1c             	sub    $0x1c,%esp
f0100418:	e8 63 fe ff ff       	call   f0100280 <__x86.get_pc_thunk.bx>
f010041d:	81 c3 57 3c 01 00    	add    $0x13c57,%ebx
f0100423:	89 c7                	mov    %eax,%edi
	for (i = 0;
f0100425:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010042a:	b9 84 00 00 00       	mov    $0x84,%ecx
f010042f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100434:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100435:	a8 20                	test   $0x20,%al
f0100437:	75 13                	jne    f010044c <cons_putc+0x3d>
f0100439:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f010043f:	7f 0b                	jg     f010044c <cons_putc+0x3d>
f0100441:	89 ca                	mov    %ecx,%edx
f0100443:	ec                   	in     (%dx),%al
f0100444:	ec                   	in     (%dx),%al
f0100445:	ec                   	in     (%dx),%al
f0100446:	ec                   	in     (%dx),%al
	     i++)
f0100447:	83 c6 01             	add    $0x1,%esi
f010044a:	eb e3                	jmp    f010042f <cons_putc+0x20>
	outb(COM1 + COM_TX, c);
f010044c:	89 f8                	mov    %edi,%eax
f010044e:	88 45 e7             	mov    %al,-0x19(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100451:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100456:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100457:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010045c:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100461:	ba 79 03 00 00       	mov    $0x379,%edx
f0100466:	ec                   	in     (%dx),%al
f0100467:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f010046d:	7f 0f                	jg     f010047e <cons_putc+0x6f>
f010046f:	84 c0                	test   %al,%al
f0100471:	78 0b                	js     f010047e <cons_putc+0x6f>
f0100473:	89 ca                	mov    %ecx,%edx
f0100475:	ec                   	in     (%dx),%al
f0100476:	ec                   	in     (%dx),%al
f0100477:	ec                   	in     (%dx),%al
f0100478:	ec                   	in     (%dx),%al
f0100479:	83 c6 01             	add    $0x1,%esi
f010047c:	eb e3                	jmp    f0100461 <cons_putc+0x52>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010047e:	ba 78 03 00 00       	mov    $0x378,%edx
f0100483:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100487:	ee                   	out    %al,(%dx)
f0100488:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010048d:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100492:	ee                   	out    %al,(%dx)
f0100493:	b8 08 00 00 00       	mov    $0x8,%eax
f0100498:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f0100499:	89 fa                	mov    %edi,%edx
f010049b:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f01004a1:	89 f8                	mov    %edi,%eax
f01004a3:	80 cc 07             	or     $0x7,%ah
f01004a6:	85 d2                	test   %edx,%edx
f01004a8:	0f 44 f8             	cmove  %eax,%edi
	switch (c & 0xff) {
f01004ab:	89 f8                	mov    %edi,%eax
f01004ad:	0f b6 c0             	movzbl %al,%eax
f01004b0:	83 f8 09             	cmp    $0x9,%eax
f01004b3:	0f 84 b4 00 00 00    	je     f010056d <cons_putc+0x15e>
f01004b9:	7e 74                	jle    f010052f <cons_putc+0x120>
f01004bb:	83 f8 0a             	cmp    $0xa,%eax
f01004be:	0f 84 9c 00 00 00    	je     f0100560 <cons_putc+0x151>
f01004c4:	83 f8 0d             	cmp    $0xd,%eax
f01004c7:	0f 85 d7 00 00 00    	jne    f01005a4 <cons_putc+0x195>
		crt_pos -= (crt_pos % CRT_COLS);
f01004cd:	0f b7 83 34 02 00 00 	movzwl 0x234(%ebx),%eax
f01004d4:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004da:	c1 e8 16             	shr    $0x16,%eax
f01004dd:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01004e0:	c1 e0 04             	shl    $0x4,%eax
f01004e3:	66 89 83 34 02 00 00 	mov    %ax,0x234(%ebx)
	if (crt_pos >= CRT_SIZE) {
f01004ea:	66 81 bb 34 02 00 00 	cmpw   $0x7cf,0x234(%ebx)
f01004f1:	cf 07 
f01004f3:	0f 87 ce 00 00 00    	ja     f01005c7 <cons_putc+0x1b8>
	outb(addr_6845, 14);
f01004f9:	8b 8b 3c 02 00 00    	mov    0x23c(%ebx),%ecx
f01004ff:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100504:	89 ca                	mov    %ecx,%edx
f0100506:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100507:	0f b7 9b 34 02 00 00 	movzwl 0x234(%ebx),%ebx
f010050e:	8d 71 01             	lea    0x1(%ecx),%esi
f0100511:	89 d8                	mov    %ebx,%eax
f0100513:	66 c1 e8 08          	shr    $0x8,%ax
f0100517:	89 f2                	mov    %esi,%edx
f0100519:	ee                   	out    %al,(%dx)
f010051a:	b8 0f 00 00 00       	mov    $0xf,%eax
f010051f:	89 ca                	mov    %ecx,%edx
f0100521:	ee                   	out    %al,(%dx)
f0100522:	89 d8                	mov    %ebx,%eax
f0100524:	89 f2                	mov    %esi,%edx
f0100526:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100527:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010052a:	5b                   	pop    %ebx
f010052b:	5e                   	pop    %esi
f010052c:	5f                   	pop    %edi
f010052d:	5d                   	pop    %ebp
f010052e:	c3                   	ret    
f010052f:	83 f8 08             	cmp    $0x8,%eax
f0100532:	75 70                	jne    f01005a4 <cons_putc+0x195>
		if (crt_pos > 0) {
f0100534:	0f b7 83 34 02 00 00 	movzwl 0x234(%ebx),%eax
f010053b:	66 85 c0             	test   %ax,%ax
f010053e:	74 b9                	je     f01004f9 <cons_putc+0xea>
			crt_pos--;
f0100540:	83 e8 01             	sub    $0x1,%eax
f0100543:	66 89 83 34 02 00 00 	mov    %ax,0x234(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010054a:	0f b7 c0             	movzwl %ax,%eax
f010054d:	89 fa                	mov    %edi,%edx
f010054f:	b2 00                	mov    $0x0,%dl
f0100551:	83 ca 20             	or     $0x20,%edx
f0100554:	8b 8b 38 02 00 00    	mov    0x238(%ebx),%ecx
f010055a:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f010055e:	eb 8a                	jmp    f01004ea <cons_putc+0xdb>
		crt_pos += CRT_COLS;
f0100560:	66 83 83 34 02 00 00 	addw   $0x50,0x234(%ebx)
f0100567:	50 
f0100568:	e9 60 ff ff ff       	jmp    f01004cd <cons_putc+0xbe>
		cons_putc(' ');
f010056d:	b8 20 00 00 00       	mov    $0x20,%eax
f0100572:	e8 98 fe ff ff       	call   f010040f <cons_putc>
		cons_putc(' ');
f0100577:	b8 20 00 00 00       	mov    $0x20,%eax
f010057c:	e8 8e fe ff ff       	call   f010040f <cons_putc>
		cons_putc(' ');
f0100581:	b8 20 00 00 00       	mov    $0x20,%eax
f0100586:	e8 84 fe ff ff       	call   f010040f <cons_putc>
		cons_putc(' ');
f010058b:	b8 20 00 00 00       	mov    $0x20,%eax
f0100590:	e8 7a fe ff ff       	call   f010040f <cons_putc>
		cons_putc(' ');
f0100595:	b8 20 00 00 00       	mov    $0x20,%eax
f010059a:	e8 70 fe ff ff       	call   f010040f <cons_putc>
f010059f:	e9 46 ff ff ff       	jmp    f01004ea <cons_putc+0xdb>
		crt_buf[crt_pos++] = c;		/* write the character */
f01005a4:	0f b7 83 34 02 00 00 	movzwl 0x234(%ebx),%eax
f01005ab:	8d 50 01             	lea    0x1(%eax),%edx
f01005ae:	66 89 93 34 02 00 00 	mov    %dx,0x234(%ebx)
f01005b5:	0f b7 c0             	movzwl %ax,%eax
f01005b8:	8b 93 38 02 00 00    	mov    0x238(%ebx),%edx
f01005be:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01005c2:	e9 23 ff ff ff       	jmp    f01004ea <cons_putc+0xdb>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01005c7:	8b 83 38 02 00 00    	mov    0x238(%ebx),%eax
f01005cd:	83 ec 04             	sub    $0x4,%esp
f01005d0:	68 00 0f 00 00       	push   $0xf00
f01005d5:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01005db:	52                   	push   %edx
f01005dc:	50                   	push   %eax
f01005dd:	e8 94 16 00 00       	call   f0101c76 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f01005e2:	8b 93 38 02 00 00    	mov    0x238(%ebx),%edx
f01005e8:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01005ee:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01005f4:	83 c4 10             	add    $0x10,%esp
f01005f7:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01005fc:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005ff:	39 d0                	cmp    %edx,%eax
f0100601:	75 f4                	jne    f01005f7 <cons_putc+0x1e8>
		crt_pos -= CRT_COLS;
f0100603:	66 83 ab 34 02 00 00 	subw   $0x50,0x234(%ebx)
f010060a:	50 
f010060b:	e9 e9 fe ff ff       	jmp    f01004f9 <cons_putc+0xea>

f0100610 <serial_intr>:
{
f0100610:	e8 dc 01 00 00       	call   f01007f1 <__x86.get_pc_thunk.ax>
f0100615:	05 5f 3a 01 00       	add    $0x13a5f,%eax
	if (serial_exists)
f010061a:	80 b8 40 02 00 00 00 	cmpb   $0x0,0x240(%eax)
f0100621:	75 01                	jne    f0100624 <serial_intr+0x14>
f0100623:	c3                   	ret    
{
f0100624:	55                   	push   %ebp
f0100625:	89 e5                	mov    %esp,%ebp
f0100627:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f010062a:	8d 80 10 c2 fe ff    	lea    -0x13df0(%eax),%eax
f0100630:	e8 69 fc ff ff       	call   f010029e <cons_intr>
}
f0100635:	c9                   	leave  
f0100636:	c3                   	ret    

f0100637 <kbd_intr>:
{
f0100637:	55                   	push   %ebp
f0100638:	89 e5                	mov    %esp,%ebp
f010063a:	83 ec 08             	sub    $0x8,%esp
f010063d:	e8 af 01 00 00       	call   f01007f1 <__x86.get_pc_thunk.ax>
f0100642:	05 32 3a 01 00       	add    $0x13a32,%eax
	cons_intr(kbd_proc_data);
f0100647:	8d 80 71 c2 fe ff    	lea    -0x13d8f(%eax),%eax
f010064d:	e8 4c fc ff ff       	call   f010029e <cons_intr>
}
f0100652:	c9                   	leave  
f0100653:	c3                   	ret    

f0100654 <cons_getc>:
{
f0100654:	55                   	push   %ebp
f0100655:	89 e5                	mov    %esp,%ebp
f0100657:	53                   	push   %ebx
f0100658:	83 ec 04             	sub    $0x4,%esp
f010065b:	e8 20 fc ff ff       	call   f0100280 <__x86.get_pc_thunk.bx>
f0100660:	81 c3 14 3a 01 00    	add    $0x13a14,%ebx
	serial_intr();
f0100666:	e8 a5 ff ff ff       	call   f0100610 <serial_intr>
	kbd_intr();
f010066b:	e8 c7 ff ff ff       	call   f0100637 <kbd_intr>
	if (cons.rpos != cons.wpos) {
f0100670:	8b 8b 2c 02 00 00    	mov    0x22c(%ebx),%ecx
	return 0;
f0100676:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f010067b:	3b 8b 30 02 00 00    	cmp    0x230(%ebx),%ecx
f0100681:	74 1f                	je     f01006a2 <cons_getc+0x4e>
		c = cons.buf[cons.rpos++];
f0100683:	8d 51 01             	lea    0x1(%ecx),%edx
f0100686:	0f b6 84 0b 2c 00 00 	movzbl 0x2c(%ebx,%ecx,1),%eax
f010068d:	00 
		if (cons.rpos == CONSBUFSIZE)
f010068e:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.rpos = 0;
f0100694:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100699:	0f 44 d1             	cmove  %ecx,%edx
f010069c:	89 93 2c 02 00 00    	mov    %edx,0x22c(%ebx)
}
f01006a2:	83 c4 04             	add    $0x4,%esp
f01006a5:	5b                   	pop    %ebx
f01006a6:	5d                   	pop    %ebp
f01006a7:	c3                   	ret    

f01006a8 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f01006a8:	55                   	push   %ebp
f01006a9:	89 e5                	mov    %esp,%ebp
f01006ab:	57                   	push   %edi
f01006ac:	56                   	push   %esi
f01006ad:	53                   	push   %ebx
f01006ae:	83 ec 1c             	sub    $0x1c,%esp
f01006b1:	e8 ca fb ff ff       	call   f0100280 <__x86.get_pc_thunk.bx>
f01006b6:	81 c3 be 39 01 00    	add    $0x139be,%ebx
	was = *cp;
f01006bc:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01006c3:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01006ca:	5a a5 
	if (*cp != 0xA55A) {
f01006cc:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01006d3:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01006d7:	0f 84 bc 00 00 00    	je     f0100799 <cons_init+0xf1>
		addr_6845 = MONO_BASE;
f01006dd:	c7 83 3c 02 00 00 b4 	movl   $0x3b4,0x23c(%ebx)
f01006e4:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01006e7:	c7 45 e4 00 00 0b f0 	movl   $0xf00b0000,-0x1c(%ebp)
	outb(addr_6845, 14);
f01006ee:	8b bb 3c 02 00 00    	mov    0x23c(%ebx),%edi
f01006f4:	b8 0e 00 00 00       	mov    $0xe,%eax
f01006f9:	89 fa                	mov    %edi,%edx
f01006fb:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01006fc:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006ff:	89 ca                	mov    %ecx,%edx
f0100701:	ec                   	in     (%dx),%al
f0100702:	0f b6 f0             	movzbl %al,%esi
f0100705:	c1 e6 08             	shl    $0x8,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100708:	b8 0f 00 00 00       	mov    $0xf,%eax
f010070d:	89 fa                	mov    %edi,%edx
f010070f:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100710:	89 ca                	mov    %ecx,%edx
f0100712:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f0100713:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100716:	89 bb 38 02 00 00    	mov    %edi,0x238(%ebx)
	pos |= inb(addr_6845 + 1);
f010071c:	0f b6 c0             	movzbl %al,%eax
f010071f:	09 c6                	or     %eax,%esi
	crt_pos = pos;
f0100721:	66 89 b3 34 02 00 00 	mov    %si,0x234(%ebx)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100728:	b9 00 00 00 00       	mov    $0x0,%ecx
f010072d:	89 c8                	mov    %ecx,%eax
f010072f:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100734:	ee                   	out    %al,(%dx)
f0100735:	bf fb 03 00 00       	mov    $0x3fb,%edi
f010073a:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f010073f:	89 fa                	mov    %edi,%edx
f0100741:	ee                   	out    %al,(%dx)
f0100742:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100747:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010074c:	ee                   	out    %al,(%dx)
f010074d:	be f9 03 00 00       	mov    $0x3f9,%esi
f0100752:	89 c8                	mov    %ecx,%eax
f0100754:	89 f2                	mov    %esi,%edx
f0100756:	ee                   	out    %al,(%dx)
f0100757:	b8 03 00 00 00       	mov    $0x3,%eax
f010075c:	89 fa                	mov    %edi,%edx
f010075e:	ee                   	out    %al,(%dx)
f010075f:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100764:	89 c8                	mov    %ecx,%eax
f0100766:	ee                   	out    %al,(%dx)
f0100767:	b8 01 00 00 00       	mov    $0x1,%eax
f010076c:	89 f2                	mov    %esi,%edx
f010076e:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010076f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100774:	ec                   	in     (%dx),%al
f0100775:	89 c1                	mov    %eax,%ecx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100777:	3c ff                	cmp    $0xff,%al
f0100779:	0f 95 83 40 02 00 00 	setne  0x240(%ebx)
f0100780:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100785:	ec                   	in     (%dx),%al
f0100786:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010078b:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010078c:	80 f9 ff             	cmp    $0xff,%cl
f010078f:	74 25                	je     f01007b6 <cons_init+0x10e>
		cprintf("Serial port does not exist!\n");
}
f0100791:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100794:	5b                   	pop    %ebx
f0100795:	5e                   	pop    %esi
f0100796:	5f                   	pop    %edi
f0100797:	5d                   	pop    %ebp
f0100798:	c3                   	ret    
		*cp = was;
f0100799:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01007a0:	c7 83 3c 02 00 00 d4 	movl   $0x3d4,0x23c(%ebx)
f01007a7:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01007aa:	c7 45 e4 00 80 0b f0 	movl   $0xf00b8000,-0x1c(%ebp)
f01007b1:	e9 38 ff ff ff       	jmp    f01006ee <cons_init+0x46>
		cprintf("Serial port does not exist!\n");
f01007b6:	83 ec 0c             	sub    $0xc,%esp
f01007b9:	8d 83 17 e1 fe ff    	lea    -0x11ee9(%ebx),%eax
f01007bf:	50                   	push   %eax
f01007c0:	e8 b3 05 00 00       	call   f0100d78 <cprintf>
f01007c5:	83 c4 10             	add    $0x10,%esp
}
f01007c8:	eb c7                	jmp    f0100791 <cons_init+0xe9>

f01007ca <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01007ca:	55                   	push   %ebp
f01007cb:	89 e5                	mov    %esp,%ebp
f01007cd:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01007d0:	8b 45 08             	mov    0x8(%ebp),%eax
f01007d3:	e8 37 fc ff ff       	call   f010040f <cons_putc>
}
f01007d8:	c9                   	leave  
f01007d9:	c3                   	ret    

f01007da <getchar>:

int
getchar(void)
{
f01007da:	55                   	push   %ebp
f01007db:	89 e5                	mov    %esp,%ebp
f01007dd:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01007e0:	e8 6f fe ff ff       	call   f0100654 <cons_getc>
f01007e5:	85 c0                	test   %eax,%eax
f01007e7:	74 f7                	je     f01007e0 <getchar+0x6>
		/* do nothing */;
	return c;
}
f01007e9:	c9                   	leave  
f01007ea:	c3                   	ret    

f01007eb <iscons>:
int
iscons(int fdnum)
{
	// used by readline
	return 1;
}
f01007eb:	b8 01 00 00 00       	mov    $0x1,%eax
f01007f0:	c3                   	ret    

f01007f1 <__x86.get_pc_thunk.ax>:
f01007f1:	8b 04 24             	mov    (%esp),%eax
f01007f4:	c3                   	ret    

f01007f5 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01007f5:	55                   	push   %ebp
f01007f6:	89 e5                	mov    %esp,%ebp
f01007f8:	56                   	push   %esi
f01007f9:	53                   	push   %ebx
f01007fa:	e8 81 fa ff ff       	call   f0100280 <__x86.get_pc_thunk.bx>
f01007ff:	81 c3 75 38 01 00    	add    $0x13875,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100805:	83 ec 04             	sub    $0x4,%esp
f0100808:	8d 83 4c e3 fe ff    	lea    -0x11cb4(%ebx),%eax
f010080e:	50                   	push   %eax
f010080f:	8d 83 6a e3 fe ff    	lea    -0x11c96(%ebx),%eax
f0100815:	50                   	push   %eax
f0100816:	8d b3 6f e3 fe ff    	lea    -0x11c91(%ebx),%esi
f010081c:	56                   	push   %esi
f010081d:	e8 56 05 00 00       	call   f0100d78 <cprintf>
f0100822:	83 c4 0c             	add    $0xc,%esp
f0100825:	8d 83 44 e4 fe ff    	lea    -0x11bbc(%ebx),%eax
f010082b:	50                   	push   %eax
f010082c:	8d 83 78 e3 fe ff    	lea    -0x11c88(%ebx),%eax
f0100832:	50                   	push   %eax
f0100833:	56                   	push   %esi
f0100834:	e8 3f 05 00 00       	call   f0100d78 <cprintf>
f0100839:	83 c4 0c             	add    $0xc,%esp
f010083c:	8d 83 6c e4 fe ff    	lea    -0x11b94(%ebx),%eax
f0100842:	50                   	push   %eax
f0100843:	8d 83 81 e3 fe ff    	lea    -0x11c7f(%ebx),%eax
f0100849:	50                   	push   %eax
f010084a:	56                   	push   %esi
f010084b:	e8 28 05 00 00       	call   f0100d78 <cprintf>
f0100850:	83 c4 0c             	add    $0xc,%esp
f0100853:	8d 83 94 e4 fe ff    	lea    -0x11b6c(%ebx),%eax
f0100859:	50                   	push   %eax
f010085a:	8d 83 8b e3 fe ff    	lea    -0x11c75(%ebx),%eax
f0100860:	50                   	push   %eax
f0100861:	56                   	push   %esi
f0100862:	e8 11 05 00 00       	call   f0100d78 <cprintf>
	return 0;
}
f0100867:	b8 00 00 00 00       	mov    $0x0,%eax
f010086c:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010086f:	5b                   	pop    %ebx
f0100870:	5e                   	pop    %esi
f0100871:	5d                   	pop    %ebp
f0100872:	c3                   	ret    

f0100873 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100873:	55                   	push   %ebp
f0100874:	89 e5                	mov    %esp,%ebp
f0100876:	57                   	push   %edi
f0100877:	56                   	push   %esi
f0100878:	53                   	push   %ebx
f0100879:	83 ec 18             	sub    $0x18,%esp
f010087c:	e8 ff f9 ff ff       	call   f0100280 <__x86.get_pc_thunk.bx>
f0100881:	81 c3 f3 37 01 00    	add    $0x137f3,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100887:	8d 83 90 e3 fe ff    	lea    -0x11c70(%ebx),%eax
f010088d:	50                   	push   %eax
f010088e:	e8 e5 04 00 00       	call   f0100d78 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100893:	83 c4 08             	add    $0x8,%esp
f0100896:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f010089c:	8d 83 b8 e4 fe ff    	lea    -0x11b48(%ebx),%eax
f01008a2:	50                   	push   %eax
f01008a3:	e8 d0 04 00 00       	call   f0100d78 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01008a8:	83 c4 0c             	add    $0xc,%esp
f01008ab:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f01008b1:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f01008b7:	50                   	push   %eax
f01008b8:	57                   	push   %edi
f01008b9:	8d 83 e0 e4 fe ff    	lea    -0x11b20(%ebx),%eax
f01008bf:	50                   	push   %eax
f01008c0:	e8 b3 04 00 00       	call   f0100d78 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01008c5:	83 c4 0c             	add    $0xc,%esp
f01008c8:	c7 c0 6f 20 10 f0    	mov    $0xf010206f,%eax
f01008ce:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01008d4:	52                   	push   %edx
f01008d5:	50                   	push   %eax
f01008d6:	8d 83 04 e5 fe ff    	lea    -0x11afc(%ebx),%eax
f01008dc:	50                   	push   %eax
f01008dd:	e8 96 04 00 00       	call   f0100d78 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01008e2:	83 c4 0c             	add    $0xc,%esp
f01008e5:	c7 c0 80 40 11 f0    	mov    $0xf0114080,%eax
f01008eb:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01008f1:	52                   	push   %edx
f01008f2:	50                   	push   %eax
f01008f3:	8d 83 28 e5 fe ff    	lea    -0x11ad8(%ebx),%eax
f01008f9:	50                   	push   %eax
f01008fa:	e8 79 04 00 00       	call   f0100d78 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01008ff:	83 c4 0c             	add    $0xc,%esp
f0100902:	c7 c6 c0 46 11 f0    	mov    $0xf01146c0,%esi
f0100908:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f010090e:	50                   	push   %eax
f010090f:	56                   	push   %esi
f0100910:	8d 83 4c e5 fe ff    	lea    -0x11ab4(%ebx),%eax
f0100916:	50                   	push   %eax
f0100917:	e8 5c 04 00 00       	call   f0100d78 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f010091c:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f010091f:	29 fe                	sub    %edi,%esi
f0100921:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100927:	c1 fe 0a             	sar    $0xa,%esi
f010092a:	56                   	push   %esi
f010092b:	8d 83 70 e5 fe ff    	lea    -0x11a90(%ebx),%eax
f0100931:	50                   	push   %eax
f0100932:	e8 41 04 00 00       	call   f0100d78 <cprintf>
	return 0;
}
f0100937:	b8 00 00 00 00       	mov    $0x0,%eax
f010093c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010093f:	5b                   	pop    %ebx
f0100940:	5e                   	pop    %esi
f0100941:	5f                   	pop    %edi
f0100942:	5d                   	pop    %ebp
f0100943:	c3                   	ret    

f0100944 <do_overflow>:
    return pretaddr;
}

void
do_overflow(void)
{
f0100944:	55                   	push   %ebp
f0100945:	89 e5                	mov    %esp,%ebp
f0100947:	53                   	push   %ebx
f0100948:	83 ec 10             	sub    $0x10,%esp
f010094b:	e8 30 f9 ff ff       	call   f0100280 <__x86.get_pc_thunk.bx>
f0100950:	81 c3 24 37 01 00    	add    $0x13724,%ebx
    cprintf("Overflow success\n");
f0100956:	8d 83 a9 e3 fe ff    	lea    -0x11c57(%ebx),%eax
f010095c:	50                   	push   %eax
f010095d:	e8 16 04 00 00       	call   f0100d78 <cprintf>
}
f0100962:	83 c4 10             	add    $0x10,%esp
f0100965:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100968:	c9                   	leave  
f0100969:	c3                   	ret    

f010096a <mon_time>:
        return (uint64_t)hi<<32 | lo;
}

int
mon_time(int argc, char **argv, struct Trapframe *tf)
{
f010096a:	55                   	push   %ebp
f010096b:	89 e5                	mov    %esp,%ebp
f010096d:	57                   	push   %edi
f010096e:	56                   	push   %esi
f010096f:	53                   	push   %ebx
f0100970:	83 ec 2c             	sub    $0x2c,%esp
f0100973:	e8 08 f9 ff ff       	call   f0100280 <__x86.get_pc_thunk.bx>
f0100978:	81 c3 fc 36 01 00    	add    $0x136fc,%ebx
f010097e:	8b 45 0c             	mov    0xc(%ebp),%eax
	uint64_t begin = 0, end = 1;
	int res = -1;
	char *targetcmd = argv[1];
f0100981:	8b 78 04             	mov    0x4(%eax),%edi
f0100984:	8d b3 ac ff ff ff    	lea    -0x54(%ebx),%esi
f010098a:	8d 4e 30             	lea    0x30(%esi),%ecx
f010098d:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	int res = -1;
f0100990:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
	uint64_t begin = 0, end = 1;
f0100997:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
f010099e:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
f01009a5:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f01009ac:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	for (int i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(targetcmd, commands[i].name) == 0) {
			begin = rdtsc();
			res = commands[i].func(argc-1, argv+1, tf);
f01009b3:	83 c0 04             	add    $0x4,%eax
f01009b6:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01009b9:	8b 45 08             	mov    0x8(%ebp),%eax
f01009bc:	83 e8 01             	sub    $0x1,%eax
f01009bf:	89 45 c8             	mov    %eax,-0x38(%ebp)
f01009c2:	eb 2d                	jmp    f01009f1 <mon_time+0x87>
        __asm__ __volatile__("rdtsc":"=a"(lo),"=d"(hi));
f01009c4:	0f 31                	rdtsc  
        return (uint64_t)hi<<32 | lo;
f01009c6:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01009c9:	89 55 dc             	mov    %edx,-0x24(%ebp)
			res = commands[i].func(argc-1, argv+1, tf);
f01009cc:	83 ec 04             	sub    $0x4,%esp
f01009cf:	ff 75 10             	pushl  0x10(%ebp)
f01009d2:	ff 75 cc             	pushl  -0x34(%ebp)
f01009d5:	ff 75 c8             	pushl  -0x38(%ebp)
f01009d8:	ff 56 08             	call   *0x8(%esi)
f01009db:	89 45 e0             	mov    %eax,-0x20(%ebp)
        __asm__ __volatile__("rdtsc":"=a"(lo),"=d"(hi));
f01009de:	0f 31                	rdtsc  
        return (uint64_t)hi<<32 | lo;
f01009e0:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01009e3:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f01009e6:	83 c4 10             	add    $0x10,%esp
f01009e9:	83 c6 0c             	add    $0xc,%esi
	for (int i = 0; i < ARRAY_SIZE(commands); i++) {
f01009ec:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f01009ef:	74 14                	je     f0100a05 <mon_time+0x9b>
		if (strcmp(targetcmd, commands[i].name) == 0) {
f01009f1:	83 ec 08             	sub    $0x8,%esp
f01009f4:	ff 36                	pushl  (%esi)
f01009f6:	57                   	push   %edi
f01009f7:	e8 97 11 00 00       	call   f0101b93 <strcmp>
f01009fc:	83 c4 10             	add    $0x10,%esp
f01009ff:	85 c0                	test   %eax,%eax
f0100a01:	75 e6                	jne    f01009e9 <mon_time+0x7f>
f0100a03:	eb bf                	jmp    f01009c4 <mon_time+0x5a>
			end = rdtsc();
		}
	}
	if (res < 0)
f0100a05:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100a09:	78 29                	js     f0100a34 <mon_time+0xca>
		cprintf("Unknown command '%s'\n", targetcmd);
	else
		cprintf("%s cycles: %llu\n", targetcmd, end - begin);
f0100a0b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100a0e:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100a11:	2b 45 d8             	sub    -0x28(%ebp),%eax
f0100a14:	1b 55 dc             	sbb    -0x24(%ebp),%edx
f0100a17:	52                   	push   %edx
f0100a18:	50                   	push   %eax
f0100a19:	57                   	push   %edi
f0100a1a:	8d 83 d1 e3 fe ff    	lea    -0x11c2f(%ebx),%eax
f0100a20:	50                   	push   %eax
f0100a21:	e8 52 03 00 00       	call   f0100d78 <cprintf>
f0100a26:	83 c4 10             	add    $0x10,%esp

	return res;
}
f0100a29:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a2c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a2f:	5b                   	pop    %ebx
f0100a30:	5e                   	pop    %esi
f0100a31:	5f                   	pop    %edi
f0100a32:	5d                   	pop    %ebp
f0100a33:	c3                   	ret    
		cprintf("Unknown command '%s'\n", targetcmd);
f0100a34:	83 ec 08             	sub    $0x8,%esp
f0100a37:	57                   	push   %edi
f0100a38:	8d 83 bb e3 fe ff    	lea    -0x11c45(%ebx),%eax
f0100a3e:	50                   	push   %eax
f0100a3f:	e8 34 03 00 00       	call   f0100d78 <cprintf>
f0100a44:	83 c4 10             	add    $0x10,%esp
f0100a47:	eb e0                	jmp    f0100a29 <mon_time+0xbf>

f0100a49 <start_overflow>:
{
f0100a49:	55                   	push   %ebp
f0100a4a:	89 e5                	mov    %esp,%ebp
f0100a4c:	57                   	push   %edi
f0100a4d:	56                   	push   %esi
f0100a4e:	53                   	push   %ebx
f0100a4f:	83 ec 1c             	sub    $0x1c,%esp
f0100a52:	e8 29 f8 ff ff       	call   f0100280 <__x86.get_pc_thunk.bx>
f0100a57:	81 c3 1d 36 01 00    	add    $0x1361d,%ebx
    __asm __volatile("leal 4(%%ebp), %0" : "=r" (pretaddr)); 
f0100a5d:	8d 75 04             	lea    0x4(%ebp),%esi
f0100a60:	89 75 e0             	mov    %esi,-0x20(%ebp)
	target_addr = (uint32_t)do_overflow;	
f0100a63:	8d 83 d0 c8 fe ff    	lea    -0x13730(%ebx),%eax
f0100a69:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100a6c:	8d 46 04             	lea    0x4(%esi),%eax
f0100a6f:	89 45 dc             	mov    %eax,-0x24(%ebp)
    	cprintf("%*s%n\n", pret_addr[i] & 0xFF, "", pret_addr + 4 + i);
f0100a72:	8d bb 16 e1 fe ff    	lea    -0x11eea(%ebx),%edi
f0100a78:	8d 83 e2 e3 fe ff    	lea    -0x11c1e(%ebx),%eax
f0100a7e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100a81:	8d 46 04             	lea    0x4(%esi),%eax
f0100a84:	50                   	push   %eax
f0100a85:	57                   	push   %edi
f0100a86:	0f b6 06             	movzbl (%esi),%eax
f0100a89:	50                   	push   %eax
f0100a8a:	ff 75 d8             	pushl  -0x28(%ebp)
f0100a8d:	e8 e6 02 00 00       	call   f0100d78 <cprintf>
f0100a92:	83 c6 01             	add    $0x1,%esi
	for (int i = 0; i < 4; i++){
f0100a95:	83 c4 10             	add    $0x10,%esp
f0100a98:	3b 75 dc             	cmp    -0x24(%ebp),%esi
f0100a9b:	75 e4                	jne    f0100a81 <start_overflow+0x38>
	for (int i = 0; i < 4; i++){
f0100a9d:	be 00 00 00 00       	mov    $0x0,%esi
		cprintf("%*s%n\n", (target_addr >> (8*i)) & 0xFF, "", pret_addr + i);
f0100aa2:	8d bb 16 e1 fe ff    	lea    -0x11eea(%ebx),%edi
f0100aa8:	8d 83 e2 e3 fe ff    	lea    -0x11c1e(%ebx),%eax
f0100aae:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100ab1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ab4:	01 f0                	add    %esi,%eax
f0100ab6:	50                   	push   %eax
f0100ab7:	57                   	push   %edi
f0100ab8:	8d 0c f5 00 00 00 00 	lea    0x0(,%esi,8),%ecx
f0100abf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ac2:	d3 e8                	shr    %cl,%eax
f0100ac4:	0f b6 c0             	movzbl %al,%eax
f0100ac7:	50                   	push   %eax
f0100ac8:	ff 75 dc             	pushl  -0x24(%ebp)
f0100acb:	e8 a8 02 00 00       	call   f0100d78 <cprintf>
	for (int i = 0; i < 4; i++){
f0100ad0:	83 c6 01             	add    $0x1,%esi
f0100ad3:	83 c4 10             	add    $0x10,%esp
f0100ad6:	83 fe 04             	cmp    $0x4,%esi
f0100ad9:	75 d6                	jne    f0100ab1 <start_overflow+0x68>
}
f0100adb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ade:	5b                   	pop    %ebx
f0100adf:	5e                   	pop    %esi
f0100ae0:	5f                   	pop    %edi
f0100ae1:	5d                   	pop    %ebp
f0100ae2:	c3                   	ret    

f0100ae3 <mon_backtrace>:
{
f0100ae3:	55                   	push   %ebp
f0100ae4:	89 e5                	mov    %esp,%ebp
f0100ae6:	57                   	push   %edi
f0100ae7:	56                   	push   %esi
f0100ae8:	53                   	push   %ebx
f0100ae9:	83 ec 4c             	sub    $0x4c,%esp
f0100aec:	e8 8f f7 ff ff       	call   f0100280 <__x86.get_pc_thunk.bx>
f0100af1:	81 c3 83 35 01 00    	add    $0x13583,%ebx
        start_overflow();
f0100af7:	e8 4d ff ff ff       	call   f0100a49 <start_overflow>
    cprintf("Stack backtrace:\n");
f0100afc:	83 ec 0c             	sub    $0xc,%esp
f0100aff:	8d 83 e9 e3 fe ff    	lea    -0x11c17(%ebx),%eax
f0100b05:	50                   	push   %eax
f0100b06:	e8 6d 02 00 00       	call   f0100d78 <cprintf>

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100b0b:	89 ee                	mov    %ebp,%esi
    while((uint32_t)ebp != 0){
f0100b0d:	83 c4 10             	add    $0x10,%esp
    	cprintf("  eip %x ebp %x args %08x %08x %08x %08x %08x\n", eip, ebp, args[0], args[1], args[2], args[3], args[4]);
f0100b10:	8d 83 9c e5 fe ff    	lea    -0x11a64(%ebx),%eax
f0100b16:	89 45 b4             	mov    %eax,-0x4c(%ebp)
    	debuginfo_eip(eip, &info);
f0100b19:	8d 45 bc             	lea    -0x44(%ebp),%eax
f0100b1c:	89 45 b0             	mov    %eax,-0x50(%ebp)
    while((uint32_t)ebp != 0){
f0100b1f:	eb 49                	jmp    f0100b6a <mon_backtrace+0x87>
    	cprintf("  eip %x ebp %x args %08x %08x %08x %08x %08x\n", eip, ebp, args[0], args[1], args[2], args[3], args[4]);
f0100b21:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100b24:	ff 75 e0             	pushl  -0x20(%ebp)
f0100b27:	ff 75 dc             	pushl  -0x24(%ebp)
f0100b2a:	ff 75 d8             	pushl  -0x28(%ebp)
f0100b2d:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100b30:	56                   	push   %esi
f0100b31:	57                   	push   %edi
f0100b32:	ff 75 b4             	pushl  -0x4c(%ebp)
f0100b35:	e8 3e 02 00 00       	call   f0100d78 <cprintf>
    	debuginfo_eip(eip, &info);
f0100b3a:	83 c4 18             	add    $0x18,%esp
f0100b3d:	ff 75 b0             	pushl  -0x50(%ebp)
f0100b40:	57                   	push   %edi
f0100b41:	e8 36 03 00 00       	call   f0100e7c <debuginfo_eip>
    	cprintf("\t%s:%d %.*s+%x\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, (uint32_t)eip - (uint32_t)info.eip_fn_addr);
f0100b46:	83 c4 08             	add    $0x8,%esp
f0100b49:	2b 7d cc             	sub    -0x34(%ebp),%edi
f0100b4c:	57                   	push   %edi
f0100b4d:	ff 75 c4             	pushl  -0x3c(%ebp)
f0100b50:	ff 75 c8             	pushl  -0x38(%ebp)
f0100b53:	ff 75 c0             	pushl  -0x40(%ebp)
f0100b56:	ff 75 bc             	pushl  -0x44(%ebp)
f0100b59:	8d 83 fb e3 fe ff    	lea    -0x11c05(%ebx),%eax
f0100b5f:	50                   	push   %eax
f0100b60:	e8 13 02 00 00       	call   f0100d78 <cprintf>
    	ebp = (uint32_t *)ebp[0];
f0100b65:	8b 36                	mov    (%esi),%esi
f0100b67:	83 c4 20             	add    $0x20,%esp
    while((uint32_t)ebp != 0){
f0100b6a:	85 f6                	test   %esi,%esi
f0100b6c:	74 1a                	je     f0100b88 <mon_backtrace+0xa5>
    	eip = ebp[1];
f0100b6e:	8b 7e 04             	mov    0x4(%esi),%edi
    	for(int i=0; i<5; i++){
f0100b71:	b8 00 00 00 00       	mov    $0x0,%eax
    		args[i] = ebp[i+2];
f0100b76:	8b 54 86 08          	mov    0x8(%esi,%eax,4),%edx
f0100b7a:	89 54 85 d4          	mov    %edx,-0x2c(%ebp,%eax,4)
    	for(int i=0; i<5; i++){
f0100b7e:	83 c0 01             	add    $0x1,%eax
f0100b81:	83 f8 05             	cmp    $0x5,%eax
f0100b84:	75 f0                	jne    f0100b76 <mon_backtrace+0x93>
f0100b86:	eb 99                	jmp    f0100b21 <mon_backtrace+0x3e>
    cprintf("Backtrace success\n");
f0100b88:	83 ec 0c             	sub    $0xc,%esp
f0100b8b:	8d 83 0b e4 fe ff    	lea    -0x11bf5(%ebx),%eax
f0100b91:	50                   	push   %eax
f0100b92:	e8 e1 01 00 00       	call   f0100d78 <cprintf>
}
f0100b97:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b9c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100b9f:	5b                   	pop    %ebx
f0100ba0:	5e                   	pop    %esi
f0100ba1:	5f                   	pop    %edi
f0100ba2:	5d                   	pop    %ebp
f0100ba3:	c3                   	ret    

f0100ba4 <overflow_me>:
{
f0100ba4:	55                   	push   %ebp
f0100ba5:	89 e5                	mov    %esp,%ebp
f0100ba7:	83 ec 08             	sub    $0x8,%esp
        start_overflow();
f0100baa:	e8 9a fe ff ff       	call   f0100a49 <start_overflow>
}
f0100baf:	c9                   	leave  
f0100bb0:	c3                   	ret    

f0100bb1 <rdtsc>:
        __asm__ __volatile__("rdtsc":"=a"(lo),"=d"(hi));
f0100bb1:	0f 31                	rdtsc  
}
f0100bb3:	c3                   	ret    

f0100bb4 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100bb4:	55                   	push   %ebp
f0100bb5:	89 e5                	mov    %esp,%ebp
f0100bb7:	57                   	push   %edi
f0100bb8:	56                   	push   %esi
f0100bb9:	53                   	push   %ebx
f0100bba:	83 ec 68             	sub    $0x68,%esp
f0100bbd:	e8 be f6 ff ff       	call   f0100280 <__x86.get_pc_thunk.bx>
f0100bc2:	81 c3 b2 34 01 00    	add    $0x134b2,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100bc8:	8d 83 cc e5 fe ff    	lea    -0x11a34(%ebx),%eax
f0100bce:	50                   	push   %eax
f0100bcf:	e8 a4 01 00 00       	call   f0100d78 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100bd4:	8d 83 f0 e5 fe ff    	lea    -0x11a10(%ebx),%eax
f0100bda:	89 04 24             	mov    %eax,(%esp)
f0100bdd:	e8 96 01 00 00       	call   f0100d78 <cprintf>
f0100be2:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100be5:	8d 83 22 e4 fe ff    	lea    -0x11bde(%ebx),%eax
f0100beb:	89 45 a0             	mov    %eax,-0x60(%ebp)
f0100bee:	e9 d1 00 00 00       	jmp    f0100cc4 <monitor+0x110>
f0100bf3:	83 ec 08             	sub    $0x8,%esp
f0100bf6:	0f be c0             	movsbl %al,%eax
f0100bf9:	50                   	push   %eax
f0100bfa:	ff 75 a0             	pushl  -0x60(%ebp)
f0100bfd:	e8 ef 0f 00 00       	call   f0101bf1 <strchr>
f0100c02:	83 c4 10             	add    $0x10,%esp
f0100c05:	85 c0                	test   %eax,%eax
f0100c07:	74 6d                	je     f0100c76 <monitor+0xc2>
			*buf++ = 0;
f0100c09:	c6 06 00             	movb   $0x0,(%esi)
f0100c0c:	89 7d a4             	mov    %edi,-0x5c(%ebp)
f0100c0f:	8d 76 01             	lea    0x1(%esi),%esi
f0100c12:	8b 7d a4             	mov    -0x5c(%ebp),%edi
		while (*buf && strchr(WHITESPACE, *buf))
f0100c15:	0f b6 06             	movzbl (%esi),%eax
f0100c18:	84 c0                	test   %al,%al
f0100c1a:	75 d7                	jne    f0100bf3 <monitor+0x3f>
	argv[argc] = 0;
f0100c1c:	c7 44 bd a8 00 00 00 	movl   $0x0,-0x58(%ebp,%edi,4)
f0100c23:	00 
	if (argc == 0)
f0100c24:	85 ff                	test   %edi,%edi
f0100c26:	0f 84 98 00 00 00    	je     f0100cc4 <monitor+0x110>
f0100c2c:	8d b3 ac ff ff ff    	lea    -0x54(%ebx),%esi
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100c32:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c37:	89 7d a4             	mov    %edi,-0x5c(%ebp)
f0100c3a:	89 c7                	mov    %eax,%edi
		if (strcmp(argv[0], commands[i].name) == 0)
f0100c3c:	83 ec 08             	sub    $0x8,%esp
f0100c3f:	ff 36                	pushl  (%esi)
f0100c41:	ff 75 a8             	pushl  -0x58(%ebp)
f0100c44:	e8 4a 0f 00 00       	call   f0101b93 <strcmp>
f0100c49:	83 c4 10             	add    $0x10,%esp
f0100c4c:	85 c0                	test   %eax,%eax
f0100c4e:	0f 84 99 00 00 00    	je     f0100ced <monitor+0x139>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100c54:	83 c7 01             	add    $0x1,%edi
f0100c57:	83 c6 0c             	add    $0xc,%esi
f0100c5a:	83 ff 04             	cmp    $0x4,%edi
f0100c5d:	75 dd                	jne    f0100c3c <monitor+0x88>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100c5f:	83 ec 08             	sub    $0x8,%esp
f0100c62:	ff 75 a8             	pushl  -0x58(%ebp)
f0100c65:	8d 83 bb e3 fe ff    	lea    -0x11c45(%ebx),%eax
f0100c6b:	50                   	push   %eax
f0100c6c:	e8 07 01 00 00       	call   f0100d78 <cprintf>
f0100c71:	83 c4 10             	add    $0x10,%esp
f0100c74:	eb 4e                	jmp    f0100cc4 <monitor+0x110>
		if (*buf == 0)
f0100c76:	80 3e 00             	cmpb   $0x0,(%esi)
f0100c79:	74 a1                	je     f0100c1c <monitor+0x68>
		if (argc == MAXARGS-1) {
f0100c7b:	83 ff 0f             	cmp    $0xf,%edi
f0100c7e:	74 30                	je     f0100cb0 <monitor+0xfc>
		argv[argc++] = buf;
f0100c80:	8d 47 01             	lea    0x1(%edi),%eax
f0100c83:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f0100c86:	89 74 bd a8          	mov    %esi,-0x58(%ebp,%edi,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f0100c8a:	0f b6 06             	movzbl (%esi),%eax
f0100c8d:	84 c0                	test   %al,%al
f0100c8f:	74 81                	je     f0100c12 <monitor+0x5e>
f0100c91:	83 ec 08             	sub    $0x8,%esp
f0100c94:	0f be c0             	movsbl %al,%eax
f0100c97:	50                   	push   %eax
f0100c98:	ff 75 a0             	pushl  -0x60(%ebp)
f0100c9b:	e8 51 0f 00 00       	call   f0101bf1 <strchr>
f0100ca0:	83 c4 10             	add    $0x10,%esp
f0100ca3:	85 c0                	test   %eax,%eax
f0100ca5:	0f 85 67 ff ff ff    	jne    f0100c12 <monitor+0x5e>
			buf++;
f0100cab:	83 c6 01             	add    $0x1,%esi
f0100cae:	eb da                	jmp    f0100c8a <monitor+0xd6>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100cb0:	83 ec 08             	sub    $0x8,%esp
f0100cb3:	6a 10                	push   $0x10
f0100cb5:	8d 83 27 e4 fe ff    	lea    -0x11bd9(%ebx),%eax
f0100cbb:	50                   	push   %eax
f0100cbc:	e8 b7 00 00 00       	call   f0100d78 <cprintf>
f0100cc1:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100cc4:	8d bb 1e e4 fe ff    	lea    -0x11be2(%ebx),%edi
f0100cca:	83 ec 0c             	sub    $0xc,%esp
f0100ccd:	57                   	push   %edi
f0100cce:	e8 df 0c 00 00       	call   f01019b2 <readline>
		if (buf != NULL)
f0100cd3:	83 c4 10             	add    $0x10,%esp
f0100cd6:	85 c0                	test   %eax,%eax
f0100cd8:	74 f0                	je     f0100cca <monitor+0x116>
f0100cda:	89 c6                	mov    %eax,%esi
	argv[argc] = 0;
f0100cdc:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f0100ce3:	bf 00 00 00 00       	mov    $0x0,%edi
f0100ce8:	e9 28 ff ff ff       	jmp    f0100c15 <monitor+0x61>
f0100ced:	89 f8                	mov    %edi,%eax
f0100cef:	8b 7d a4             	mov    -0x5c(%ebp),%edi
			return commands[i].func(argc, argv, tf);
f0100cf2:	83 ec 04             	sub    $0x4,%esp
f0100cf5:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100cf8:	ff 75 08             	pushl  0x8(%ebp)
f0100cfb:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100cfe:	52                   	push   %edx
f0100cff:	57                   	push   %edi
f0100d00:	ff 94 83 b4 ff ff ff 	call   *-0x4c(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100d07:	83 c4 10             	add    $0x10,%esp
f0100d0a:	85 c0                	test   %eax,%eax
f0100d0c:	79 b6                	jns    f0100cc4 <monitor+0x110>
				break;
	}
}
f0100d0e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d11:	5b                   	pop    %ebx
f0100d12:	5e                   	pop    %esi
f0100d13:	5f                   	pop    %edi
f0100d14:	5d                   	pop    %ebp
f0100d15:	c3                   	ret    

f0100d16 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100d16:	55                   	push   %ebp
f0100d17:	89 e5                	mov    %esp,%ebp
f0100d19:	56                   	push   %esi
f0100d1a:	53                   	push   %ebx
f0100d1b:	e8 60 f5 ff ff       	call   f0100280 <__x86.get_pc_thunk.bx>
f0100d20:	81 c3 54 33 01 00    	add    $0x13354,%ebx
f0100d26:	8b 75 0c             	mov    0xc(%ebp),%esi
	cputchar(ch);
f0100d29:	83 ec 0c             	sub    $0xc,%esp
f0100d2c:	ff 75 08             	pushl  0x8(%ebp)
f0100d2f:	e8 96 fa ff ff       	call   f01007ca <cputchar>
	(*cnt)++;
f0100d34:	83 06 01             	addl   $0x1,(%esi)
}
f0100d37:	83 c4 10             	add    $0x10,%esp
f0100d3a:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100d3d:	5b                   	pop    %ebx
f0100d3e:	5e                   	pop    %esi
f0100d3f:	5d                   	pop    %ebp
f0100d40:	c3                   	ret    

f0100d41 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100d41:	55                   	push   %ebp
f0100d42:	89 e5                	mov    %esp,%ebp
f0100d44:	53                   	push   %ebx
f0100d45:	83 ec 14             	sub    $0x14,%esp
f0100d48:	e8 33 f5 ff ff       	call   f0100280 <__x86.get_pc_thunk.bx>
f0100d4d:	81 c3 27 33 01 00    	add    $0x13327,%ebx
	int cnt = 0;
f0100d53:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100d5a:	ff 75 0c             	pushl  0xc(%ebp)
f0100d5d:	ff 75 08             	pushl  0x8(%ebp)
f0100d60:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100d63:	50                   	push   %eax
f0100d64:	8d 83 a2 cc fe ff    	lea    -0x1335e(%ebx),%eax
f0100d6a:	50                   	push   %eax
f0100d6b:	e8 f3 05 00 00       	call   f0101363 <vprintfmt>
	return cnt;
}
f0100d70:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100d73:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100d76:	c9                   	leave  
f0100d77:	c3                   	ret    

f0100d78 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100d78:	55                   	push   %ebp
f0100d79:	89 e5                	mov    %esp,%ebp
f0100d7b:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100d7e:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100d81:	50                   	push   %eax
f0100d82:	ff 75 08             	pushl  0x8(%ebp)
f0100d85:	e8 b7 ff ff ff       	call   f0100d41 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100d8a:	c9                   	leave  
f0100d8b:	c3                   	ret    

f0100d8c <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100d8c:	55                   	push   %ebp
f0100d8d:	89 e5                	mov    %esp,%ebp
f0100d8f:	57                   	push   %edi
f0100d90:	56                   	push   %esi
f0100d91:	53                   	push   %ebx
f0100d92:	83 ec 14             	sub    $0x14,%esp
f0100d95:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100d98:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100d9b:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100d9e:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100da1:	8b 1a                	mov    (%edx),%ebx
f0100da3:	8b 01                	mov    (%ecx),%eax
f0100da5:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100da8:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100daf:	eb 23                	jmp    f0100dd4 <stab_binsearch+0x48>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100db1:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0100db4:	eb 1e                	jmp    f0100dd4 <stab_binsearch+0x48>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100db6:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100db9:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100dbc:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100dc0:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100dc3:	73 41                	jae    f0100e06 <stab_binsearch+0x7a>
			*region_left = m;
f0100dc5:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100dc8:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0100dca:	8d 5f 01             	lea    0x1(%edi),%ebx
		any_matches = 1;
f0100dcd:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0100dd4:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100dd7:	7f 5a                	jg     f0100e33 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f0100dd9:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100ddc:	01 d8                	add    %ebx,%eax
f0100dde:	89 c7                	mov    %eax,%edi
f0100de0:	c1 ef 1f             	shr    $0x1f,%edi
f0100de3:	01 c7                	add    %eax,%edi
f0100de5:	d1 ff                	sar    %edi
f0100de7:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0100dea:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100ded:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0100df1:	89 f8                	mov    %edi,%eax
		while (m >= l && stabs[m].n_type != type)
f0100df3:	39 c3                	cmp    %eax,%ebx
f0100df5:	7f ba                	jg     f0100db1 <stab_binsearch+0x25>
f0100df7:	0f b6 0a             	movzbl (%edx),%ecx
f0100dfa:	83 ea 0c             	sub    $0xc,%edx
f0100dfd:	39 f1                	cmp    %esi,%ecx
f0100dff:	74 b5                	je     f0100db6 <stab_binsearch+0x2a>
			m--;
f0100e01:	83 e8 01             	sub    $0x1,%eax
f0100e04:	eb ed                	jmp    f0100df3 <stab_binsearch+0x67>
		} else if (stabs[m].n_value > addr) {
f0100e06:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100e09:	76 14                	jbe    f0100e1f <stab_binsearch+0x93>
			*region_right = m - 1;
f0100e0b:	83 e8 01             	sub    $0x1,%eax
f0100e0e:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100e11:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100e14:	89 07                	mov    %eax,(%edi)
		any_matches = 1;
f0100e16:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100e1d:	eb b5                	jmp    f0100dd4 <stab_binsearch+0x48>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100e1f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e22:	89 07                	mov    %eax,(%edi)
			l = m;
			addr++;
f0100e24:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100e28:	89 c3                	mov    %eax,%ebx
		any_matches = 1;
f0100e2a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100e31:	eb a1                	jmp    f0100dd4 <stab_binsearch+0x48>
		}
	}

	if (!any_matches)
f0100e33:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100e37:	75 15                	jne    f0100e4e <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0100e39:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e3c:	8b 00                	mov    (%eax),%eax
f0100e3e:	83 e8 01             	sub    $0x1,%eax
f0100e41:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100e44:	89 06                	mov    %eax,(%esi)
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0100e46:	83 c4 14             	add    $0x14,%esp
f0100e49:	5b                   	pop    %ebx
f0100e4a:	5e                   	pop    %esi
f0100e4b:	5f                   	pop    %edi
f0100e4c:	5d                   	pop    %ebp
f0100e4d:	c3                   	ret    
		for (l = *region_right;
f0100e4e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e51:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100e53:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e56:	8b 0f                	mov    (%edi),%ecx
f0100e58:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100e5b:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100e5e:	8d 54 97 04          	lea    0x4(%edi,%edx,4),%edx
		for (l = *region_right;
f0100e62:	eb 03                	jmp    f0100e67 <stab_binsearch+0xdb>
		     l--)
f0100e64:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0100e67:	39 c1                	cmp    %eax,%ecx
f0100e69:	7d 0a                	jge    f0100e75 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0100e6b:	0f b6 1a             	movzbl (%edx),%ebx
f0100e6e:	83 ea 0c             	sub    $0xc,%edx
f0100e71:	39 f3                	cmp    %esi,%ebx
f0100e73:	75 ef                	jne    f0100e64 <stab_binsearch+0xd8>
		*region_left = l;
f0100e75:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100e78:	89 06                	mov    %eax,(%esi)
}
f0100e7a:	eb ca                	jmp    f0100e46 <stab_binsearch+0xba>

f0100e7c <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100e7c:	55                   	push   %ebp
f0100e7d:	89 e5                	mov    %esp,%ebp
f0100e7f:	57                   	push   %edi
f0100e80:	56                   	push   %esi
f0100e81:	53                   	push   %ebx
f0100e82:	83 ec 3c             	sub    $0x3c,%esp
f0100e85:	e8 f6 f3 ff ff       	call   f0100280 <__x86.get_pc_thunk.bx>
f0100e8a:	81 c3 ea 31 01 00    	add    $0x131ea,%ebx
f0100e90:	89 5d bc             	mov    %ebx,-0x44(%ebp)
f0100e93:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100e96:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100e99:	8d 83 15 e6 fe ff    	lea    -0x119eb(%ebx),%eax
f0100e9f:	89 06                	mov    %eax,(%esi)
	info->eip_line = 0;
f0100ea1:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0100ea8:	89 46 08             	mov    %eax,0x8(%esi)
	info->eip_fn_namelen = 9;
f0100eab:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0100eb2:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0100eb5:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100ebc:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0100ec2:	0f 86 42 01 00 00    	jbe    f010100a <debuginfo_eip+0x18e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100ec8:	c7 c0 b9 72 10 f0    	mov    $0xf01072b9,%eax
f0100ece:	39 83 fc ff ff ff    	cmp    %eax,-0x4(%ebx)
f0100ed4:	0f 86 04 02 00 00    	jbe    f01010de <debuginfo_eip+0x262>
f0100eda:	8b 5d bc             	mov    -0x44(%ebp),%ebx
f0100edd:	c7 c0 91 8d 10 f0    	mov    $0xf0108d91,%eax
f0100ee3:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0100ee7:	0f 85 f8 01 00 00    	jne    f01010e5 <debuginfo_eip+0x269>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100eed:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100ef4:	c7 c0 20 29 10 f0    	mov    $0xf0102920,%eax
f0100efa:	c7 c2 b8 72 10 f0    	mov    $0xf01072b8,%edx
f0100f00:	29 c2                	sub    %eax,%edx
f0100f02:	c1 fa 02             	sar    $0x2,%edx
f0100f05:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0100f0b:	83 ea 01             	sub    $0x1,%edx
f0100f0e:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100f11:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100f14:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100f17:	83 ec 08             	sub    $0x8,%esp
f0100f1a:	57                   	push   %edi
f0100f1b:	6a 64                	push   $0x64
f0100f1d:	e8 6a fe ff ff       	call   f0100d8c <stab_binsearch>
	if (lfile == 0)
f0100f22:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100f25:	83 c4 10             	add    $0x10,%esp
f0100f28:	85 c0                	test   %eax,%eax
f0100f2a:	0f 84 bc 01 00 00    	je     f01010ec <debuginfo_eip+0x270>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100f30:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100f33:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f36:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100f39:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100f3c:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100f3f:	83 ec 08             	sub    $0x8,%esp
f0100f42:	57                   	push   %edi
f0100f43:	6a 24                	push   $0x24
f0100f45:	c7 c0 20 29 10 f0    	mov    $0xf0102920,%eax
f0100f4b:	e8 3c fe ff ff       	call   f0100d8c <stab_binsearch>

	if (lfun <= rfun) {
f0100f50:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100f53:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0100f56:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
f0100f59:	83 c4 10             	add    $0x10,%esp
f0100f5c:	39 c8                	cmp    %ecx,%eax
f0100f5e:	0f 8f c1 00 00 00    	jg     f0101025 <debuginfo_eip+0x1a9>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100f64:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100f67:	c7 c1 20 29 10 f0    	mov    $0xf0102920,%ecx
f0100f6d:	8d 0c 91             	lea    (%ecx,%edx,4),%ecx
f0100f70:	8b 11                	mov    (%ecx),%edx
f0100f72:	89 55 c0             	mov    %edx,-0x40(%ebp)
f0100f75:	c7 c2 91 8d 10 f0    	mov    $0xf0108d91,%edx
f0100f7b:	89 5d bc             	mov    %ebx,-0x44(%ebp)
f0100f7e:	81 ea b9 72 10 f0    	sub    $0xf01072b9,%edx
f0100f84:	8b 5d c0             	mov    -0x40(%ebp),%ebx
f0100f87:	39 d3                	cmp    %edx,%ebx
f0100f89:	73 0c                	jae    f0100f97 <debuginfo_eip+0x11b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100f8b:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0100f8e:	81 c3 b9 72 10 f0    	add    $0xf01072b9,%ebx
f0100f94:	89 5e 08             	mov    %ebx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100f97:	8b 51 08             	mov    0x8(%ecx),%edx
f0100f9a:	89 56 10             	mov    %edx,0x10(%esi)
		addr -= info->eip_fn_addr;
f0100f9d:	29 d7                	sub    %edx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f0100f9f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100fa2:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100fa5:	89 45 d0             	mov    %eax,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100fa8:	83 ec 08             	sub    $0x8,%esp
f0100fab:	6a 3a                	push   $0x3a
f0100fad:	ff 76 08             	pushl  0x8(%esi)
f0100fb0:	8b 5d bc             	mov    -0x44(%ebp),%ebx
f0100fb3:	e8 5a 0c 00 00       	call   f0101c12 <strfind>
f0100fb8:	2b 46 08             	sub    0x8(%esi),%eax
f0100fbb:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100fbe:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100fc1:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100fc4:	83 c4 08             	add    $0x8,%esp
f0100fc7:	57                   	push   %edi
f0100fc8:	6a 44                	push   $0x44
f0100fca:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0100fcd:	c7 c0 20 29 10 f0    	mov    $0xf0102920,%eax
f0100fd3:	e8 b4 fd ff ff       	call   f0100d8c <stab_binsearch>
	if (lline <= rline) {
f0100fd8:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100fdb:	83 c4 10             	add    $0x10,%esp
f0100fde:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0100fe1:	0f 8f 0c 01 00 00    	jg     f01010f3 <debuginfo_eip+0x277>
		info->eip_line = stabs[lline].n_desc;
f0100fe7:	89 d0                	mov    %edx,%eax
f0100fe9:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100fec:	c1 e2 02             	shl    $0x2,%edx
f0100fef:	c7 c1 20 29 10 f0    	mov    $0xf0102920,%ecx
f0100ff5:	0f b7 5c 0a 06       	movzwl 0x6(%edx,%ecx,1),%ebx
f0100ffa:	89 5e 04             	mov    %ebx,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100ffd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101000:	8d 54 0a 04          	lea    0x4(%edx,%ecx,1),%edx
f0101004:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0101008:	eb 39                	jmp    f0101043 <debuginfo_eip+0x1c7>
  	        panic("User address");
f010100a:	83 ec 04             	sub    $0x4,%esp
f010100d:	8b 5d bc             	mov    -0x44(%ebp),%ebx
f0101010:	8d 83 1f e6 fe ff    	lea    -0x119e1(%ebx),%eax
f0101016:	50                   	push   %eax
f0101017:	6a 7f                	push   $0x7f
f0101019:	8d 83 2c e6 fe ff    	lea    -0x119d4(%ebx),%eax
f010101f:	50                   	push   %eax
f0101020:	e8 a5 f1 ff ff       	call   f01001ca <_panic>
		info->eip_fn_addr = addr;
f0101025:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0101028:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010102b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f010102e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101031:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101034:	e9 6f ff ff ff       	jmp    f0100fa8 <debuginfo_eip+0x12c>
f0101039:	83 e8 01             	sub    $0x1,%eax
f010103c:	83 ea 0c             	sub    $0xc,%edx
f010103f:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0101043:	89 45 c0             	mov    %eax,-0x40(%ebp)
	while (lline >= lfile
f0101046:	39 c7                	cmp    %eax,%edi
f0101048:	7f 51                	jg     f010109b <debuginfo_eip+0x21f>
	       && stabs[lline].n_type != N_SOL
f010104a:	0f b6 0a             	movzbl (%edx),%ecx
f010104d:	80 f9 84             	cmp    $0x84,%cl
f0101050:	74 19                	je     f010106b <debuginfo_eip+0x1ef>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0101052:	80 f9 64             	cmp    $0x64,%cl
f0101055:	75 e2                	jne    f0101039 <debuginfo_eip+0x1bd>
f0101057:	83 7a 04 00          	cmpl   $0x0,0x4(%edx)
f010105b:	74 dc                	je     f0101039 <debuginfo_eip+0x1bd>
f010105d:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0101061:	74 11                	je     f0101074 <debuginfo_eip+0x1f8>
f0101063:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0101066:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101069:	eb 09                	jmp    f0101074 <debuginfo_eip+0x1f8>
f010106b:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f010106f:	74 03                	je     f0101074 <debuginfo_eip+0x1f8>
f0101071:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0101074:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0101077:	8b 7d bc             	mov    -0x44(%ebp),%edi
f010107a:	c7 c0 20 29 10 f0    	mov    $0xf0102920,%eax
f0101080:	8b 14 90             	mov    (%eax,%edx,4),%edx
f0101083:	c7 c0 91 8d 10 f0    	mov    $0xf0108d91,%eax
f0101089:	81 e8 b9 72 10 f0    	sub    $0xf01072b9,%eax
f010108f:	39 c2                	cmp    %eax,%edx
f0101091:	73 08                	jae    f010109b <debuginfo_eip+0x21f>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0101093:	81 c2 b9 72 10 f0    	add    $0xf01072b9,%edx
f0101099:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010109b:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010109e:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01010a1:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f01010a6:	39 da                	cmp    %ebx,%edx
f01010a8:	7d 55                	jge    f01010ff <debuginfo_eip+0x283>
		for (lline = lfun + 1;
f01010aa:	83 c2 01             	add    $0x1,%edx
f01010ad:	89 d0                	mov    %edx,%eax
f01010af:	8d 0c 52             	lea    (%edx,%edx,2),%ecx
f01010b2:	8b 7d bc             	mov    -0x44(%ebp),%edi
f01010b5:	c7 c2 20 29 10 f0    	mov    $0xf0102920,%edx
f01010bb:	8d 54 8a 04          	lea    0x4(%edx,%ecx,4),%edx
f01010bf:	eb 04                	jmp    f01010c5 <debuginfo_eip+0x249>
			info->eip_fn_narg++;
f01010c1:	83 46 14 01          	addl   $0x1,0x14(%esi)
		for (lline = lfun + 1;
f01010c5:	39 c3                	cmp    %eax,%ebx
f01010c7:	7e 31                	jle    f01010fa <debuginfo_eip+0x27e>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01010c9:	0f b6 0a             	movzbl (%edx),%ecx
f01010cc:	83 c0 01             	add    $0x1,%eax
f01010cf:	83 c2 0c             	add    $0xc,%edx
f01010d2:	80 f9 a0             	cmp    $0xa0,%cl
f01010d5:	74 ea                	je     f01010c1 <debuginfo_eip+0x245>
	return 0;
f01010d7:	b8 00 00 00 00       	mov    $0x0,%eax
f01010dc:	eb 21                	jmp    f01010ff <debuginfo_eip+0x283>
		return -1;
f01010de:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01010e3:	eb 1a                	jmp    f01010ff <debuginfo_eip+0x283>
f01010e5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01010ea:	eb 13                	jmp    f01010ff <debuginfo_eip+0x283>
		return -1;
f01010ec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01010f1:	eb 0c                	jmp    f01010ff <debuginfo_eip+0x283>
		return -1;
f01010f3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01010f8:	eb 05                	jmp    f01010ff <debuginfo_eip+0x283>
	return 0;
f01010fa:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01010ff:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101102:	5b                   	pop    %ebx
f0101103:	5e                   	pop    %esi
f0101104:	5f                   	pop    %edi
f0101105:	5d                   	pop    %ebp
f0101106:	c3                   	ret    

f0101107 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0101107:	55                   	push   %ebp
f0101108:	89 e5                	mov    %esp,%ebp
f010110a:	57                   	push   %edi
f010110b:	56                   	push   %esi
f010110c:	53                   	push   %ebx
f010110d:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
f0101113:	e8 68 f1 ff ff       	call   f0100280 <__x86.get_pc_thunk.bx>
f0101118:	81 c3 5c 2f 01 00    	add    $0x12f5c,%ebx
f010111e:	89 85 74 ff ff ff    	mov    %eax,-0x8c(%ebp)
f0101124:	89 95 70 ff ff ff    	mov    %edx,-0x90(%ebp)
f010112a:	8b 75 08             	mov    0x8(%ebp),%esi
f010112d:	8b 7d 0c             	mov    0xc(%ebp),%edi
	if(padc=='-'){ 
f0101130:	83 7d 18 2d          	cmpl   $0x2d,0x18(%ebp)
f0101134:	74 54                	je     f010118a <printnum+0x83>
    		putch(' ', putdat);
    	}		
    	return ;
  	}
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0101136:	8b 45 10             	mov    0x10(%ebp),%eax
f0101139:	ba 00 00 00 00       	mov    $0x0,%edx
f010113e:	89 85 68 ff ff ff    	mov    %eax,-0x98(%ebp)
f0101144:	89 95 6c ff ff ff    	mov    %edx,-0x94(%ebp)
f010114a:	3b 75 10             	cmp    0x10(%ebp),%esi
f010114d:	89 f9                	mov    %edi,%ecx
f010114f:	19 d1                	sbb    %edx,%ecx
f0101151:	0f 83 47 01 00 00    	jae    f010129e <printnum+0x197>
f0101157:	89 b5 60 ff ff ff    	mov    %esi,-0xa0(%ebp)
f010115d:	89 bd 64 ff ff ff    	mov    %edi,-0x9c(%ebp)
f0101163:	8b 7d 14             	mov    0x14(%ebp),%edi
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0101166:	83 ef 01             	sub    $0x1,%edi
f0101169:	85 ff                	test   %edi,%edi
f010116b:	0f 8e 6e 01 00 00    	jle    f01012df <printnum+0x1d8>
			putch(padc, putdat);
f0101171:	83 ec 08             	sub    $0x8,%esp
f0101174:	ff b5 70 ff ff ff    	pushl  -0x90(%ebp)
f010117a:	ff 75 18             	pushl  0x18(%ebp)
f010117d:	8b 85 74 ff ff ff    	mov    -0x8c(%ebp),%eax
f0101183:	ff d0                	call   *%eax
f0101185:	83 c4 10             	add    $0x10,%esp
f0101188:	eb dc                	jmp    f0101166 <printnum+0x5f>
    	int numlen = 0;
f010118a:	c7 85 60 ff ff ff 00 	movl   $0x0,-0xa0(%ebp)
f0101191:	00 00 00 
    	for(; num >= base; numlen++ , num /= base){	//计算每一位
f0101194:	8b 45 10             	mov    0x10(%ebp),%eax
f0101197:	ba 00 00 00 00       	mov    $0x0,%edx
f010119c:	89 85 68 ff ff ff    	mov    %eax,-0x98(%ebp)
f01011a2:	89 95 6c ff ff ff    	mov    %edx,-0x94(%ebp)
f01011a8:	3b 75 10             	cmp    0x10(%ebp),%esi
f01011ab:	89 f8                	mov    %edi,%eax
f01011ad:	1b 85 6c ff ff ff    	sbb    -0x94(%ebp),%eax
f01011b3:	72 45                	jb     f01011fa <printnum+0xf3>
      		renum[numlen]= num % base;
f01011b5:	ff b5 6c ff ff ff    	pushl  -0x94(%ebp)
f01011bb:	ff b5 68 ff ff ff    	pushl  -0x98(%ebp)
f01011c1:	57                   	push   %edi
f01011c2:	56                   	push   %esi
f01011c3:	e8 68 0d 00 00       	call   f0101f30 <__umoddi3>
f01011c8:	83 c4 10             	add    $0x10,%esp
f01011cb:	8b 8d 60 ff ff ff    	mov    -0xa0(%ebp),%ecx
f01011d1:	88 44 0d 84          	mov    %al,-0x7c(%ebp,%ecx,1)
    	for(; num >= base; numlen++ , num /= base){	//计算每一位
f01011d5:	83 c1 01             	add    $0x1,%ecx
f01011d8:	89 8d 60 ff ff ff    	mov    %ecx,-0xa0(%ebp)
f01011de:	ff b5 6c ff ff ff    	pushl  -0x94(%ebp)
f01011e4:	ff b5 68 ff ff ff    	pushl  -0x98(%ebp)
f01011ea:	57                   	push   %edi
f01011eb:	56                   	push   %esi
f01011ec:	e8 2f 0c 00 00       	call   f0101e20 <__udivdi3>
f01011f1:	83 c4 10             	add    $0x10,%esp
f01011f4:	89 c6                	mov    %eax,%esi
f01011f6:	89 d7                	mov    %edx,%edi
f01011f8:	eb ae                	jmp    f01011a8 <printnum+0xa1>
    	putch("0123456789abcdef"[num % base],putdat);	//输出数字的第一位
f01011fa:	83 ec 08             	sub    $0x8,%esp
f01011fd:	ff b5 70 ff ff ff    	pushl  -0x90(%ebp)
f0101203:	83 ec 04             	sub    $0x4,%esp
f0101206:	ff b5 6c ff ff ff    	pushl  -0x94(%ebp)
f010120c:	ff b5 68 ff ff ff    	pushl  -0x98(%ebp)
f0101212:	57                   	push   %edi
f0101213:	56                   	push   %esi
f0101214:	e8 17 0d 00 00       	call   f0101f30 <__umoddi3>
f0101219:	83 c4 14             	add    $0x14,%esp
f010121c:	0f be 84 03 3a e6 fe 	movsbl -0x119c6(%ebx,%eax,1),%eax
f0101223:	ff 
f0101224:	50                   	push   %eax
f0101225:	8b 85 74 ff ff ff    	mov    -0x8c(%ebp),%eax
f010122b:	ff d0                	call   *%eax
    	for(; numlen > 0 ; --numlen){	//按序输出其他位
f010122d:	83 c4 10             	add    $0x10,%esp
f0101230:	8b b5 60 ff ff ff    	mov    -0xa0(%ebp),%esi
    		int index = renum[numlen-1];
f0101236:	8d 7d 84             	lea    -0x7c(%ebp),%edi
    	for(; numlen > 0 ; --numlen){	//按序输出其他位
f0101239:	eb 24                	jmp    f010125f <printnum+0x158>
    		int index = renum[numlen-1];
f010123b:	83 ee 01             	sub    $0x1,%esi
      		putch("0123456789abcdef"[index],putdat);
f010123e:	83 ec 08             	sub    $0x8,%esp
f0101241:	ff b5 70 ff ff ff    	pushl  -0x90(%ebp)
    		int index = renum[numlen-1];
f0101247:	0f be 04 3e          	movsbl (%esi,%edi,1),%eax
      		putch("0123456789abcdef"[index],putdat);
f010124b:	0f be 84 03 3a e6 fe 	movsbl -0x119c6(%ebx,%eax,1),%eax
f0101252:	ff 
f0101253:	50                   	push   %eax
f0101254:	8b 85 74 ff ff ff    	mov    -0x8c(%ebp),%eax
f010125a:	ff d0                	call   *%eax
    	for(; numlen > 0 ; --numlen){	//按序输出其他位
f010125c:	83 c4 10             	add    $0x10,%esp
f010125f:	85 f6                	test   %esi,%esi
f0101261:	7f d8                	jg     f010123b <printnum+0x134>
f0101263:	8b 95 60 ff ff ff    	mov    -0xa0(%ebp),%edx
f0101269:	85 d2                	test   %edx,%edx
f010126b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101270:	0f 49 c2             	cmovns %edx,%eax
		width -= numlen;	//计算需要补充空格的数量
f0101273:	29 c2                	sub    %eax,%edx
f0101275:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0101278:	29 d3                	sub    %edx,%ebx
f010127a:	8b b5 74 ff ff ff    	mov    -0x8c(%ebp),%esi
f0101280:	8b bd 70 ff ff ff    	mov    -0x90(%ebp),%edi
    	while (--width > 0){	//补充空格
f0101286:	83 eb 01             	sub    $0x1,%ebx
f0101289:	85 db                	test   %ebx,%ebx
f010128b:	0f 8e 90 00 00 00    	jle    f0101321 <printnum+0x21a>
    		putch(' ', putdat);
f0101291:	83 ec 08             	sub    $0x8,%esp
f0101294:	57                   	push   %edi
f0101295:	6a 20                	push   $0x20
f0101297:	ff d6                	call   *%esi
f0101299:	83 c4 10             	add    $0x10,%esp
f010129c:	eb e8                	jmp    f0101286 <printnum+0x17f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010129e:	83 ec 0c             	sub    $0xc,%esp
f01012a1:	ff 75 18             	pushl  0x18(%ebp)
f01012a4:	8b 45 14             	mov    0x14(%ebp),%eax
f01012a7:	83 e8 01             	sub    $0x1,%eax
f01012aa:	50                   	push   %eax
f01012ab:	ff 75 10             	pushl  0x10(%ebp)
f01012ae:	83 ec 08             	sub    $0x8,%esp
f01012b1:	ff b5 6c ff ff ff    	pushl  -0x94(%ebp)
f01012b7:	ff b5 68 ff ff ff    	pushl  -0x98(%ebp)
f01012bd:	57                   	push   %edi
f01012be:	56                   	push   %esi
f01012bf:	e8 5c 0b 00 00       	call   f0101e20 <__udivdi3>
f01012c4:	83 c4 18             	add    $0x18,%esp
f01012c7:	52                   	push   %edx
f01012c8:	50                   	push   %eax
f01012c9:	8b 95 70 ff ff ff    	mov    -0x90(%ebp),%edx
f01012cf:	8b 85 74 ff ff ff    	mov    -0x8c(%ebp),%eax
f01012d5:	e8 2d fe ff ff       	call   f0101107 <printnum>
f01012da:	83 c4 20             	add    $0x20,%esp
f01012dd:	eb 0c                	jmp    f01012eb <printnum+0x1e4>
f01012df:	8b b5 60 ff ff ff    	mov    -0xa0(%ebp),%esi
f01012e5:	8b bd 64 ff ff ff    	mov    -0x9c(%ebp),%edi
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01012eb:	83 ec 08             	sub    $0x8,%esp
f01012ee:	ff b5 70 ff ff ff    	pushl  -0x90(%ebp)
f01012f4:	83 ec 04             	sub    $0x4,%esp
f01012f7:	ff b5 6c ff ff ff    	pushl  -0x94(%ebp)
f01012fd:	ff b5 68 ff ff ff    	pushl  -0x98(%ebp)
f0101303:	57                   	push   %edi
f0101304:	56                   	push   %esi
f0101305:	e8 26 0c 00 00       	call   f0101f30 <__umoddi3>
f010130a:	83 c4 14             	add    $0x14,%esp
f010130d:	0f be 84 03 3a e6 fe 	movsbl -0x119c6(%ebx,%eax,1),%eax
f0101314:	ff 
f0101315:	50                   	push   %eax
f0101316:	8b 85 74 ff ff ff    	mov    -0x8c(%ebp),%eax
f010131c:	ff d0                	call   *%eax
f010131e:	83 c4 10             	add    $0x10,%esp
}
f0101321:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101324:	5b                   	pop    %ebx
f0101325:	5e                   	pop    %esi
f0101326:	5f                   	pop    %edi
f0101327:	5d                   	pop    %ebp
f0101328:	c3                   	ret    

f0101329 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0101329:	55                   	push   %ebp
f010132a:	89 e5                	mov    %esp,%ebp
f010132c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010132f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0101333:	8b 10                	mov    (%eax),%edx
f0101335:	3b 50 04             	cmp    0x4(%eax),%edx
f0101338:	73 0a                	jae    f0101344 <sprintputch+0x1b>
		*b->buf++ = ch;
f010133a:	8d 4a 01             	lea    0x1(%edx),%ecx
f010133d:	89 08                	mov    %ecx,(%eax)
f010133f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101342:	88 02                	mov    %al,(%edx)
}
f0101344:	5d                   	pop    %ebp
f0101345:	c3                   	ret    

f0101346 <printfmt>:
{
f0101346:	55                   	push   %ebp
f0101347:	89 e5                	mov    %esp,%ebp
f0101349:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f010134c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010134f:	50                   	push   %eax
f0101350:	ff 75 10             	pushl  0x10(%ebp)
f0101353:	ff 75 0c             	pushl  0xc(%ebp)
f0101356:	ff 75 08             	pushl  0x8(%ebp)
f0101359:	e8 05 00 00 00       	call   f0101363 <vprintfmt>
}
f010135e:	83 c4 10             	add    $0x10,%esp
f0101361:	c9                   	leave  
f0101362:	c3                   	ret    

f0101363 <vprintfmt>:
{
f0101363:	55                   	push   %ebp
f0101364:	89 e5                	mov    %esp,%ebp
f0101366:	57                   	push   %edi
f0101367:	56                   	push   %esi
f0101368:	53                   	push   %ebx
f0101369:	83 ec 3c             	sub    $0x3c,%esp
f010136c:	e8 80 f4 ff ff       	call   f01007f1 <__x86.get_pc_thunk.ax>
f0101371:	05 03 2d 01 00       	add    $0x12d03,%eax
f0101376:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101379:	8b 7d 08             	mov    0x8(%ebp),%edi
f010137c:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010137f:	89 fe                	mov    %edi,%esi
f0101381:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101384:	e9 84 04 00 00       	jmp    f010180d <.L40+0x76>
		int ifsign = 0;
f0101389:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%ebp)
		padc = ' ';
f0101390:	c6 45 d3 20          	movb   $0x20,-0x2d(%ebp)
		altflag = 0;
f0101394:	c7 45 c8 00 00 00 00 	movl   $0x0,-0x38(%ebp)
		precision = -1;
f010139b:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		width = -1;
f01013a2:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		lflag = 0;
f01013a9:	b9 00 00 00 00       	mov    $0x0,%ecx
f01013ae:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
f01013b1:	89 75 08             	mov    %esi,0x8(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01013b4:	8d 43 01             	lea    0x1(%ebx),%eax
f01013b7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01013ba:	0f b6 13             	movzbl (%ebx),%edx
f01013bd:	8d 42 dd             	lea    -0x23(%edx),%eax
f01013c0:	3c 55                	cmp    $0x55,%al
f01013c2:	0f 87 46 05 00 00    	ja     f010190e <.L34>
f01013c8:	0f b6 c0             	movzbl %al,%eax
f01013cb:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01013ce:	89 ce                	mov    %ecx,%esi
f01013d0:	03 b4 81 44 e7 fe ff 	add    -0x118bc(%ecx,%eax,4),%esi
f01013d7:	ff e6                	jmp    *%esi

f01013d9 <.L86>:
f01013d9:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			padc = '-';
f01013dc:	c6 45 d3 2d          	movb   $0x2d,-0x2d(%ebp)
f01013e0:	eb d2                	jmp    f01013b4 <vprintfmt+0x51>

f01013e2 <.L49>:
		switch (ch = *(unsigned char *) fmt++) {
f01013e2:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			ifsign = 1;
f01013e5:	c7 45 c0 01 00 00 00 	movl   $0x1,-0x40(%ebp)
f01013ec:	eb c6                	jmp    f01013b4 <vprintfmt+0x51>

f01013ee <.L46>:
		switch (ch = *(unsigned char *) fmt++) {
f01013ee:	0f b6 d2             	movzbl %dl,%edx
f01013f1:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			for (precision = 0; ; ++fmt) {
f01013f4:	b8 00 00 00 00       	mov    $0x0,%eax
f01013f9:	8b 75 08             	mov    0x8(%ebp),%esi
f01013fc:	e9 8b 00 00 00       	jmp    f010148c <.L47+0xf>

f0101401 <.L41>:
f0101401:	8b 75 08             	mov    0x8(%ebp),%esi
			argptr = va_arg(ap, char *);
f0101404:	8b 45 14             	mov    0x14(%ebp),%eax
f0101407:	83 c0 04             	add    $0x4,%eax
f010140a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010140d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101410:	8b 18                	mov    (%eax),%ebx
  			if (argptr == NULL){
f0101412:	85 db                	test   %ebx,%ebx
f0101414:	74 18                	je     f010142e <.L41+0x2d>
  			}else if(*((int *)putdat) >= 255 ){
f0101416:	81 3f fe 00 00 00    	cmpl   $0xfe,(%edi)
f010141c:	7f 36                	jg     f0101454 <.L41+0x53>
    			*argptr = *(char *)putdat;
f010141e:	0f b6 07             	movzbl (%edi),%eax
f0101421:	88 03                	mov    %al,(%ebx)
			argptr = va_arg(ap, char *);
f0101423:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101426:	89 45 14             	mov    %eax,0x14(%ebp)
f0101429:	e9 dc 03 00 00       	jmp    f010180a <.L40+0x73>
    			printfmt(putch,putdat,"%s", null_error);
f010142e:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101431:	8d 82 c8 e6 fe ff    	lea    -0x11938(%edx),%eax
f0101437:	50                   	push   %eax
f0101438:	8d 82 52 e6 fe ff    	lea    -0x119ae(%edx),%eax
f010143e:	50                   	push   %eax
f010143f:	57                   	push   %edi
f0101440:	56                   	push   %esi
f0101441:	e8 00 ff ff ff       	call   f0101346 <printfmt>
f0101446:	83 c4 10             	add    $0x10,%esp
			argptr = va_arg(ap, char *);
f0101449:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010144c:	89 45 14             	mov    %eax,0x14(%ebp)
f010144f:	e9 b6 03 00 00       	jmp    f010180a <.L40+0x73>
    			printfmt(putch,putdat,"%s", overflow_error);
f0101454:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101457:	8d 82 00 e7 fe ff    	lea    -0x11900(%edx),%eax
f010145d:	50                   	push   %eax
f010145e:	8d 82 52 e6 fe ff    	lea    -0x119ae(%edx),%eax
f0101464:	50                   	push   %eax
f0101465:	57                   	push   %edi
f0101466:	56                   	push   %esi
f0101467:	e8 da fe ff ff       	call   f0101346 <printfmt>
  				*argptr = -1;
f010146c:	c6 03 ff             	movb   $0xff,(%ebx)
f010146f:	83 c4 10             	add    $0x10,%esp
			argptr = va_arg(ap, char *);
f0101472:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101475:	89 45 14             	mov    %eax,0x14(%ebp)
f0101478:	e9 8d 03 00 00       	jmp    f010180a <.L40+0x73>

f010147d <.L47>:
		switch (ch = *(unsigned char *) fmt++) {
f010147d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			padc = '0';
f0101480:	c6 45 d3 30          	movb   $0x30,-0x2d(%ebp)
			goto reswitch;
f0101484:	e9 2b ff ff ff       	jmp    f01013b4 <vprintfmt+0x51>
			for (precision = 0; ; ++fmt) {
f0101489:	83 c3 01             	add    $0x1,%ebx
				precision = precision * 10 + ch - '0';
f010148c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010148f:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0101493:	0f be 13             	movsbl (%ebx),%edx
				if (ch < '0' || ch > '9')
f0101496:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0101499:	83 f9 09             	cmp    $0x9,%ecx
f010149c:	76 eb                	jbe    f0101489 <.L47+0xc>
f010149e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01014a1:	89 75 08             	mov    %esi,0x8(%ebp)
f01014a4:	eb 14                	jmp    f01014ba <.L50+0x14>

f01014a6 <.L50>:
			precision = va_arg(ap, int);
f01014a6:	8b 45 14             	mov    0x14(%ebp),%eax
f01014a9:	8b 00                	mov    (%eax),%eax
f01014ab:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01014ae:	8b 45 14             	mov    0x14(%ebp),%eax
f01014b1:	8d 40 04             	lea    0x4(%eax),%eax
f01014b4:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01014b7:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			if (width < 0)
f01014ba:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f01014be:	0f 89 f0 fe ff ff    	jns    f01013b4 <vprintfmt+0x51>
				width = precision, precision = -1;
f01014c4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01014c7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01014ca:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f01014d1:	e9 de fe ff ff       	jmp    f01013b4 <vprintfmt+0x51>

f01014d6 <.L48>:
f01014d6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01014d9:	85 c0                	test   %eax,%eax
f01014db:	ba 00 00 00 00       	mov    $0x0,%edx
f01014e0:	0f 49 d0             	cmovns %eax,%edx
f01014e3:	89 55 d4             	mov    %edx,-0x2c(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01014e6:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01014e9:	e9 c6 fe ff ff       	jmp    f01013b4 <vprintfmt+0x51>

f01014ee <.L52>:
f01014ee:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			altflag = 1;
f01014f1:	c7 45 c8 01 00 00 00 	movl   $0x1,-0x38(%ebp)
			goto reswitch;
f01014f8:	e9 b7 fe ff ff       	jmp    f01013b4 <vprintfmt+0x51>

f01014fd <.L42>:
			lflag++;
f01014fd:	83 45 c4 01          	addl   $0x1,-0x3c(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0101501:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
			goto reswitch;
f0101504:	e9 ab fe ff ff       	jmp    f01013b4 <vprintfmt+0x51>

f0101509 <.L45>:
f0101509:	8b 75 08             	mov    0x8(%ebp),%esi
			putch(va_arg(ap, int), putdat);
f010150c:	8b 45 14             	mov    0x14(%ebp),%eax
f010150f:	8d 58 04             	lea    0x4(%eax),%ebx
f0101512:	83 ec 08             	sub    $0x8,%esp
f0101515:	57                   	push   %edi
f0101516:	ff 30                	pushl  (%eax)
f0101518:	ff d6                	call   *%esi
			break;
f010151a:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f010151d:	89 5d 14             	mov    %ebx,0x14(%ebp)
			break;
f0101520:	e9 e5 02 00 00       	jmp    f010180a <.L40+0x73>

f0101525 <.L43>:
f0101525:	8b 75 08             	mov    0x8(%ebp),%esi
			err = va_arg(ap, int);
f0101528:	8b 45 14             	mov    0x14(%ebp),%eax
f010152b:	8d 58 04             	lea    0x4(%eax),%ebx
f010152e:	8b 00                	mov    (%eax),%eax
f0101530:	99                   	cltd   
f0101531:	31 d0                	xor    %edx,%eax
f0101533:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0101535:	83 f8 06             	cmp    $0x6,%eax
f0101538:	7f 2b                	jg     f0101565 <.L43+0x40>
f010153a:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010153d:	8b 94 82 dc ff ff ff 	mov    -0x24(%edx,%eax,4),%edx
f0101544:	85 d2                	test   %edx,%edx
f0101546:	74 1d                	je     f0101565 <.L43+0x40>
				printfmt(putch, putdat, "%s", p);
f0101548:	52                   	push   %edx
f0101549:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010154c:	8d 80 52 e6 fe ff    	lea    -0x119ae(%eax),%eax
f0101552:	50                   	push   %eax
f0101553:	57                   	push   %edi
f0101554:	56                   	push   %esi
f0101555:	e8 ec fd ff ff       	call   f0101346 <printfmt>
f010155a:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f010155d:	89 5d 14             	mov    %ebx,0x14(%ebp)
f0101560:	e9 a5 02 00 00       	jmp    f010180a <.L40+0x73>
				printfmt(putch, putdat, "error %d", err);
f0101565:	50                   	push   %eax
f0101566:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101569:	8d 80 55 e6 fe ff    	lea    -0x119ab(%eax),%eax
f010156f:	50                   	push   %eax
f0101570:	57                   	push   %edi
f0101571:	56                   	push   %esi
f0101572:	e8 cf fd ff ff       	call   f0101346 <printfmt>
f0101577:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f010157a:	89 5d 14             	mov    %ebx,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f010157d:	e9 88 02 00 00       	jmp    f010180a <.L40+0x73>

f0101582 <.L38>:
f0101582:	8b 75 08             	mov    0x8(%ebp),%esi
			if ((p = va_arg(ap, char *)) == NULL)
f0101585:	8b 45 14             	mov    0x14(%ebp),%eax
f0101588:	83 c0 04             	add    $0x4,%eax
f010158b:	89 45 c0             	mov    %eax,-0x40(%ebp)
f010158e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101591:	8b 10                	mov    (%eax),%edx
				p = "(null)";
f0101593:	85 d2                	test   %edx,%edx
f0101595:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101598:	8d 80 4b e6 fe ff    	lea    -0x119b5(%eax),%eax
f010159e:	0f 45 c2             	cmovne %edx,%eax
f01015a1:	89 45 c4             	mov    %eax,-0x3c(%ebp)
			if (width > 0 && padc != '-')
f01015a4:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f01015a8:	7e 06                	jle    f01015b0 <.L38+0x2e>
f01015aa:	80 7d d3 2d          	cmpb   $0x2d,-0x2d(%ebp)
f01015ae:	75 0d                	jne    f01015bd <.L38+0x3b>
				for (width -= strnlen(p, precision); width > 0; width--)
f01015b0:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01015b3:	89 c3                	mov    %eax,%ebx
f01015b5:	03 45 d4             	add    -0x2c(%ebp),%eax
f01015b8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015bb:	eb 56                	jmp    f0101613 <.L38+0x91>
f01015bd:	83 ec 08             	sub    $0x8,%esp
f01015c0:	ff 75 d8             	pushl  -0x28(%ebp)
f01015c3:	50                   	push   %eax
f01015c4:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01015c7:	e8 fb 04 00 00       	call   f0101ac7 <strnlen>
f01015cc:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01015cf:	29 c2                	sub    %eax,%edx
f01015d1:	89 55 bc             	mov    %edx,-0x44(%ebp)
f01015d4:	83 c4 10             	add    $0x10,%esp
f01015d7:	89 d3                	mov    %edx,%ebx
					putch(padc, putdat);
f01015d9:	0f be 45 d3          	movsbl -0x2d(%ebp),%eax
f01015dd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f01015e0:	eb 0f                	jmp    f01015f1 <.L38+0x6f>
					putch(padc, putdat);
f01015e2:	83 ec 08             	sub    $0x8,%esp
f01015e5:	57                   	push   %edi
f01015e6:	ff 75 d4             	pushl  -0x2c(%ebp)
f01015e9:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f01015eb:	83 eb 01             	sub    $0x1,%ebx
f01015ee:	83 c4 10             	add    $0x10,%esp
f01015f1:	85 db                	test   %ebx,%ebx
f01015f3:	7f ed                	jg     f01015e2 <.L38+0x60>
f01015f5:	8b 55 bc             	mov    -0x44(%ebp),%edx
f01015f8:	85 d2                	test   %edx,%edx
f01015fa:	b8 00 00 00 00       	mov    $0x0,%eax
f01015ff:	0f 49 c2             	cmovns %edx,%eax
f0101602:	29 c2                	sub    %eax,%edx
f0101604:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0101607:	eb a7                	jmp    f01015b0 <.L38+0x2e>
					putch(ch, putdat);
f0101609:	83 ec 08             	sub    $0x8,%esp
f010160c:	57                   	push   %edi
f010160d:	52                   	push   %edx
f010160e:	ff d6                	call   *%esi
f0101610:	83 c4 10             	add    $0x10,%esp
f0101613:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101616:	29 d9                	sub    %ebx,%ecx
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101618:	83 c3 01             	add    $0x1,%ebx
f010161b:	0f b6 43 ff          	movzbl -0x1(%ebx),%eax
f010161f:	0f be d0             	movsbl %al,%edx
f0101622:	85 d2                	test   %edx,%edx
f0101624:	74 4b                	je     f0101671 <.L38+0xef>
f0101626:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010162a:	78 06                	js     f0101632 <.L38+0xb0>
f010162c:	83 6d d8 01          	subl   $0x1,-0x28(%ebp)
f0101630:	78 1e                	js     f0101650 <.L38+0xce>
				if (altflag && (ch < ' ' || ch > '~'))
f0101632:	83 7d c8 00          	cmpl   $0x0,-0x38(%ebp)
f0101636:	74 d1                	je     f0101609 <.L38+0x87>
f0101638:	0f be c0             	movsbl %al,%eax
f010163b:	83 e8 20             	sub    $0x20,%eax
f010163e:	83 f8 5e             	cmp    $0x5e,%eax
f0101641:	76 c6                	jbe    f0101609 <.L38+0x87>
					putch('?', putdat);
f0101643:	83 ec 08             	sub    $0x8,%esp
f0101646:	57                   	push   %edi
f0101647:	6a 3f                	push   $0x3f
f0101649:	ff d6                	call   *%esi
f010164b:	83 c4 10             	add    $0x10,%esp
f010164e:	eb c3                	jmp    f0101613 <.L38+0x91>
f0101650:	89 cb                	mov    %ecx,%ebx
f0101652:	eb 0e                	jmp    f0101662 <.L38+0xe0>
				putch(' ', putdat);
f0101654:	83 ec 08             	sub    $0x8,%esp
f0101657:	57                   	push   %edi
f0101658:	6a 20                	push   $0x20
f010165a:	ff d6                	call   *%esi
			for (; width > 0; width--)
f010165c:	83 eb 01             	sub    $0x1,%ebx
f010165f:	83 c4 10             	add    $0x10,%esp
f0101662:	85 db                	test   %ebx,%ebx
f0101664:	7f ee                	jg     f0101654 <.L38+0xd2>
			if ((p = va_arg(ap, char *)) == NULL)
f0101666:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0101669:	89 45 14             	mov    %eax,0x14(%ebp)
f010166c:	e9 99 01 00 00       	jmp    f010180a <.L40+0x73>
f0101671:	89 cb                	mov    %ecx,%ebx
f0101673:	eb ed                	jmp    f0101662 <.L38+0xe0>

f0101675 <.L44>:
f0101675:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0101678:	8b 75 08             	mov    0x8(%ebp),%esi
	if (lflag >= 2)
f010167b:	83 f9 01             	cmp    $0x1,%ecx
f010167e:	7f 1b                	jg     f010169b <.L44+0x26>
	else if (lflag)
f0101680:	85 c9                	test   %ecx,%ecx
f0101682:	74 64                	je     f01016e8 <.L44+0x73>
		return va_arg(*ap, long);
f0101684:	8b 45 14             	mov    0x14(%ebp),%eax
f0101687:	8b 00                	mov    (%eax),%eax
f0101689:	89 45 c8             	mov    %eax,-0x38(%ebp)
f010168c:	99                   	cltd   
f010168d:	89 55 cc             	mov    %edx,-0x34(%ebp)
f0101690:	8b 45 14             	mov    0x14(%ebp),%eax
f0101693:	8d 40 04             	lea    0x4(%eax),%eax
f0101696:	89 45 14             	mov    %eax,0x14(%ebp)
f0101699:	eb 17                	jmp    f01016b2 <.L44+0x3d>
		return va_arg(*ap, long long);
f010169b:	8b 45 14             	mov    0x14(%ebp),%eax
f010169e:	8b 50 04             	mov    0x4(%eax),%edx
f01016a1:	8b 00                	mov    (%eax),%eax
f01016a3:	89 45 c8             	mov    %eax,-0x38(%ebp)
f01016a6:	89 55 cc             	mov    %edx,-0x34(%ebp)
f01016a9:	8b 45 14             	mov    0x14(%ebp),%eax
f01016ac:	8d 40 08             	lea    0x8(%eax),%eax
f01016af:	89 45 14             	mov    %eax,0x14(%ebp)
			num = getint(&ap, lflag);
f01016b2:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01016b5:	8b 55 cc             	mov    -0x34(%ebp),%edx
f01016b8:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01016bb:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
f01016be:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f01016c2:	78 3b                	js     f01016ff <.L44+0x8a>
			base = 10;
f01016c4:	b8 0a 00 00 00       	mov    $0xa,%eax
			else if(ifsign){
f01016c9:	83 7d c0 00          	cmpl   $0x0,-0x40(%ebp)
f01016cd:	0f 84 19 01 00 00    	je     f01017ec <.L40+0x55>
				putch('+', putdat);
f01016d3:	83 ec 08             	sub    $0x8,%esp
f01016d6:	57                   	push   %edi
f01016d7:	6a 2b                	push   $0x2b
f01016d9:	ff d6                	call   *%esi
f01016db:	83 c4 10             	add    $0x10,%esp
			base = 10;
f01016de:	b8 0a 00 00 00       	mov    $0xa,%eax
f01016e3:	e9 04 01 00 00       	jmp    f01017ec <.L40+0x55>
		return va_arg(*ap, int);
f01016e8:	8b 45 14             	mov    0x14(%ebp),%eax
f01016eb:	8b 00                	mov    (%eax),%eax
f01016ed:	89 45 c8             	mov    %eax,-0x38(%ebp)
f01016f0:	99                   	cltd   
f01016f1:	89 55 cc             	mov    %edx,-0x34(%ebp)
f01016f4:	8b 45 14             	mov    0x14(%ebp),%eax
f01016f7:	8d 40 04             	lea    0x4(%eax),%eax
f01016fa:	89 45 14             	mov    %eax,0x14(%ebp)
f01016fd:	eb b3                	jmp    f01016b2 <.L44+0x3d>
				putch('-', putdat);
f01016ff:	83 ec 08             	sub    $0x8,%esp
f0101702:	57                   	push   %edi
f0101703:	6a 2d                	push   $0x2d
f0101705:	ff d6                	call   *%esi
				num = -(long long) num;
f0101707:	8b 45 c8             	mov    -0x38(%ebp),%eax
f010170a:	8b 55 cc             	mov    -0x34(%ebp),%edx
f010170d:	f7 d8                	neg    %eax
f010170f:	83 d2 00             	adc    $0x0,%edx
f0101712:	f7 da                	neg    %edx
f0101714:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101717:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010171a:	83 c4 10             	add    $0x10,%esp
			base = 10;
f010171d:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101722:	e9 c5 00 00 00       	jmp    f01017ec <.L40+0x55>

f0101727 <.L37>:
f0101727:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f010172a:	8b 75 08             	mov    0x8(%ebp),%esi
	if (lflag >= 2)
f010172d:	83 f9 01             	cmp    $0x1,%ecx
f0101730:	7f 27                	jg     f0101759 <.L37+0x32>
	else if (lflag)
f0101732:	85 c9                	test   %ecx,%ecx
f0101734:	74 41                	je     f0101777 <.L37+0x50>
		return va_arg(*ap, unsigned long);
f0101736:	8b 45 14             	mov    0x14(%ebp),%eax
f0101739:	8b 00                	mov    (%eax),%eax
f010173b:	ba 00 00 00 00       	mov    $0x0,%edx
f0101740:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101743:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101746:	8b 45 14             	mov    0x14(%ebp),%eax
f0101749:	8d 40 04             	lea    0x4(%eax),%eax
f010174c:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f010174f:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101754:	e9 93 00 00 00       	jmp    f01017ec <.L40+0x55>
		return va_arg(*ap, unsigned long long);
f0101759:	8b 45 14             	mov    0x14(%ebp),%eax
f010175c:	8b 50 04             	mov    0x4(%eax),%edx
f010175f:	8b 00                	mov    (%eax),%eax
f0101761:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101764:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101767:	8b 45 14             	mov    0x14(%ebp),%eax
f010176a:	8d 40 08             	lea    0x8(%eax),%eax
f010176d:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101770:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101775:	eb 75                	jmp    f01017ec <.L40+0x55>
		return va_arg(*ap, unsigned int);
f0101777:	8b 45 14             	mov    0x14(%ebp),%eax
f010177a:	8b 00                	mov    (%eax),%eax
f010177c:	ba 00 00 00 00       	mov    $0x0,%edx
f0101781:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101784:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101787:	8b 45 14             	mov    0x14(%ebp),%eax
f010178a:	8d 40 04             	lea    0x4(%eax),%eax
f010178d:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101790:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101795:	eb 55                	jmp    f01017ec <.L40+0x55>

f0101797 <.L40>:
f0101797:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f010179a:	8b 75 08             	mov    0x8(%ebp),%esi
	if (lflag >= 2)
f010179d:	83 f9 01             	cmp    $0x1,%ecx
f01017a0:	7f 23                	jg     f01017c5 <.L40+0x2e>
	else if (lflag)
f01017a2:	85 c9                	test   %ecx,%ecx
f01017a4:	0f 84 87 00 00 00    	je     f0101831 <.L40+0x9a>
		return va_arg(*ap, unsigned long);
f01017aa:	8b 45 14             	mov    0x14(%ebp),%eax
f01017ad:	8b 00                	mov    (%eax),%eax
f01017af:	ba 00 00 00 00       	mov    $0x0,%edx
f01017b4:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01017b7:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01017ba:	8b 45 14             	mov    0x14(%ebp),%eax
f01017bd:	8d 40 04             	lea    0x4(%eax),%eax
f01017c0:	89 45 14             	mov    %eax,0x14(%ebp)
f01017c3:	eb 17                	jmp    f01017dc <.L40+0x45>
		return va_arg(*ap, unsigned long long);
f01017c5:	8b 45 14             	mov    0x14(%ebp),%eax
f01017c8:	8b 50 04             	mov    0x4(%eax),%edx
f01017cb:	8b 00                	mov    (%eax),%eax
f01017cd:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01017d0:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01017d3:	8b 45 14             	mov    0x14(%ebp),%eax
f01017d6:	8d 40 08             	lea    0x8(%eax),%eax
f01017d9:	89 45 14             	mov    %eax,0x14(%ebp)
			putch('0', putdat);
f01017dc:	83 ec 08             	sub    $0x8,%esp
f01017df:	57                   	push   %edi
f01017e0:	6a 30                	push   $0x30
f01017e2:	ff d6                	call   *%esi
			goto number;
f01017e4:	83 c4 10             	add    $0x10,%esp
			base = 8;
f01017e7:	b8 08 00 00 00       	mov    $0x8,%eax
			printnum(putch, putdat, num, base, width, padc);
f01017ec:	83 ec 0c             	sub    $0xc,%esp
f01017ef:	0f be 5d d3          	movsbl -0x2d(%ebp),%ebx
f01017f3:	53                   	push   %ebx
f01017f4:	ff 75 d4             	pushl  -0x2c(%ebp)
f01017f7:	50                   	push   %eax
f01017f8:	ff 75 dc             	pushl  -0x24(%ebp)
f01017fb:	ff 75 d8             	pushl  -0x28(%ebp)
f01017fe:	89 fa                	mov    %edi,%edx
f0101800:	89 f0                	mov    %esi,%eax
f0101802:	e8 00 f9 ff ff       	call   f0101107 <printnum>
			break;
f0101807:	83 c4 20             	add    $0x20,%esp
			if ((p = va_arg(ap, char *)) == NULL)
f010180a:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010180d:	83 c3 01             	add    $0x1,%ebx
f0101810:	0f b6 43 ff          	movzbl -0x1(%ebx),%eax
f0101814:	83 f8 25             	cmp    $0x25,%eax
f0101817:	0f 84 6c fb ff ff    	je     f0101389 <vprintfmt+0x26>
			if (ch == '\0')
f010181d:	85 c0                	test   %eax,%eax
f010181f:	0f 84 0c 01 00 00    	je     f0101931 <.L34+0x23>
			putch(ch, putdat);
f0101825:	83 ec 08             	sub    $0x8,%esp
f0101828:	57                   	push   %edi
f0101829:	50                   	push   %eax
f010182a:	ff d6                	call   *%esi
f010182c:	83 c4 10             	add    $0x10,%esp
f010182f:	eb dc                	jmp    f010180d <.L40+0x76>
		return va_arg(*ap, unsigned int);
f0101831:	8b 45 14             	mov    0x14(%ebp),%eax
f0101834:	8b 00                	mov    (%eax),%eax
f0101836:	ba 00 00 00 00       	mov    $0x0,%edx
f010183b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010183e:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101841:	8b 45 14             	mov    0x14(%ebp),%eax
f0101844:	8d 40 04             	lea    0x4(%eax),%eax
f0101847:	89 45 14             	mov    %eax,0x14(%ebp)
f010184a:	eb 90                	jmp    f01017dc <.L40+0x45>

f010184c <.L39>:
f010184c:	8b 75 08             	mov    0x8(%ebp),%esi
			putch('0', putdat);
f010184f:	83 ec 08             	sub    $0x8,%esp
f0101852:	57                   	push   %edi
f0101853:	6a 30                	push   $0x30
f0101855:	ff d6                	call   *%esi
			putch('x', putdat);
f0101857:	83 c4 08             	add    $0x8,%esp
f010185a:	57                   	push   %edi
f010185b:	6a 78                	push   $0x78
f010185d:	ff d6                	call   *%esi
			num = (unsigned long long)
f010185f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101862:	8b 00                	mov    (%eax),%eax
f0101864:	ba 00 00 00 00       	mov    $0x0,%edx
f0101869:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010186c:	89 55 dc             	mov    %edx,-0x24(%ebp)
			goto number;
f010186f:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0101872:	8b 45 14             	mov    0x14(%ebp),%eax
f0101875:	8d 40 04             	lea    0x4(%eax),%eax
f0101878:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010187b:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0101880:	e9 67 ff ff ff       	jmp    f01017ec <.L40+0x55>

f0101885 <.L35>:
f0101885:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0101888:	8b 75 08             	mov    0x8(%ebp),%esi
	if (lflag >= 2)
f010188b:	83 f9 01             	cmp    $0x1,%ecx
f010188e:	7f 27                	jg     f01018b7 <.L35+0x32>
	else if (lflag)
f0101890:	85 c9                	test   %ecx,%ecx
f0101892:	74 44                	je     f01018d8 <.L35+0x53>
		return va_arg(*ap, unsigned long);
f0101894:	8b 45 14             	mov    0x14(%ebp),%eax
f0101897:	8b 00                	mov    (%eax),%eax
f0101899:	ba 00 00 00 00       	mov    $0x0,%edx
f010189e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01018a1:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01018a4:	8b 45 14             	mov    0x14(%ebp),%eax
f01018a7:	8d 40 04             	lea    0x4(%eax),%eax
f01018aa:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01018ad:	b8 10 00 00 00       	mov    $0x10,%eax
f01018b2:	e9 35 ff ff ff       	jmp    f01017ec <.L40+0x55>
		return va_arg(*ap, unsigned long long);
f01018b7:	8b 45 14             	mov    0x14(%ebp),%eax
f01018ba:	8b 50 04             	mov    0x4(%eax),%edx
f01018bd:	8b 00                	mov    (%eax),%eax
f01018bf:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01018c2:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01018c5:	8b 45 14             	mov    0x14(%ebp),%eax
f01018c8:	8d 40 08             	lea    0x8(%eax),%eax
f01018cb:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01018ce:	b8 10 00 00 00       	mov    $0x10,%eax
f01018d3:	e9 14 ff ff ff       	jmp    f01017ec <.L40+0x55>
		return va_arg(*ap, unsigned int);
f01018d8:	8b 45 14             	mov    0x14(%ebp),%eax
f01018db:	8b 00                	mov    (%eax),%eax
f01018dd:	ba 00 00 00 00       	mov    $0x0,%edx
f01018e2:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01018e5:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01018e8:	8b 45 14             	mov    0x14(%ebp),%eax
f01018eb:	8d 40 04             	lea    0x4(%eax),%eax
f01018ee:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01018f1:	b8 10 00 00 00       	mov    $0x10,%eax
f01018f6:	e9 f1 fe ff ff       	jmp    f01017ec <.L40+0x55>

f01018fb <.L51>:
f01018fb:	8b 75 08             	mov    0x8(%ebp),%esi
			putch(ch, putdat);
f01018fe:	83 ec 08             	sub    $0x8,%esp
f0101901:	57                   	push   %edi
f0101902:	6a 25                	push   $0x25
f0101904:	ff d6                	call   *%esi
			break;
f0101906:	83 c4 10             	add    $0x10,%esp
f0101909:	e9 fc fe ff ff       	jmp    f010180a <.L40+0x73>

f010190e <.L34>:
f010190e:	8b 75 08             	mov    0x8(%ebp),%esi
			putch('%', putdat);
f0101911:	83 ec 08             	sub    $0x8,%esp
f0101914:	57                   	push   %edi
f0101915:	6a 25                	push   $0x25
f0101917:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101919:	83 c4 10             	add    $0x10,%esp
f010191c:	89 d8                	mov    %ebx,%eax
f010191e:	eb 03                	jmp    f0101923 <.L34+0x15>
f0101920:	83 e8 01             	sub    $0x1,%eax
f0101923:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0101927:	75 f7                	jne    f0101920 <.L34+0x12>
f0101929:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010192c:	e9 d9 fe ff ff       	jmp    f010180a <.L40+0x73>
}
f0101931:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101934:	5b                   	pop    %ebx
f0101935:	5e                   	pop    %esi
f0101936:	5f                   	pop    %edi
f0101937:	5d                   	pop    %ebp
f0101938:	c3                   	ret    

f0101939 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101939:	55                   	push   %ebp
f010193a:	89 e5                	mov    %esp,%ebp
f010193c:	53                   	push   %ebx
f010193d:	83 ec 14             	sub    $0x14,%esp
f0101940:	e8 3b e9 ff ff       	call   f0100280 <__x86.get_pc_thunk.bx>
f0101945:	81 c3 2f 27 01 00    	add    $0x1272f,%ebx
f010194b:	8b 45 08             	mov    0x8(%ebp),%eax
f010194e:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101951:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101954:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101958:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010195b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101962:	85 c0                	test   %eax,%eax
f0101964:	74 2b                	je     f0101991 <vsnprintf+0x58>
f0101966:	85 d2                	test   %edx,%edx
f0101968:	7e 27                	jle    f0101991 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010196a:	ff 75 14             	pushl  0x14(%ebp)
f010196d:	ff 75 10             	pushl  0x10(%ebp)
f0101970:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101973:	50                   	push   %eax
f0101974:	8d 83 b5 d2 fe ff    	lea    -0x12d4b(%ebx),%eax
f010197a:	50                   	push   %eax
f010197b:	e8 e3 f9 ff ff       	call   f0101363 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101980:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101983:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101986:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101989:	83 c4 10             	add    $0x10,%esp
}
f010198c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010198f:	c9                   	leave  
f0101990:	c3                   	ret    
		return -E_INVAL;
f0101991:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0101996:	eb f4                	jmp    f010198c <vsnprintf+0x53>

f0101998 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101998:	55                   	push   %ebp
f0101999:	89 e5                	mov    %esp,%ebp
f010199b:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010199e:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01019a1:	50                   	push   %eax
f01019a2:	ff 75 10             	pushl  0x10(%ebp)
f01019a5:	ff 75 0c             	pushl  0xc(%ebp)
f01019a8:	ff 75 08             	pushl  0x8(%ebp)
f01019ab:	e8 89 ff ff ff       	call   f0101939 <vsnprintf>
	va_end(ap);

	return rc;
}
f01019b0:	c9                   	leave  
f01019b1:	c3                   	ret    

f01019b2 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01019b2:	55                   	push   %ebp
f01019b3:	89 e5                	mov    %esp,%ebp
f01019b5:	57                   	push   %edi
f01019b6:	56                   	push   %esi
f01019b7:	53                   	push   %ebx
f01019b8:	83 ec 1c             	sub    $0x1c,%esp
f01019bb:	e8 c0 e8 ff ff       	call   f0100280 <__x86.get_pc_thunk.bx>
f01019c0:	81 c3 b4 26 01 00    	add    $0x126b4,%ebx
f01019c6:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01019c9:	85 c0                	test   %eax,%eax
f01019cb:	74 13                	je     f01019e0 <readline+0x2e>
		cprintf("%s", prompt);
f01019cd:	83 ec 08             	sub    $0x8,%esp
f01019d0:	50                   	push   %eax
f01019d1:	8d 83 52 e6 fe ff    	lea    -0x119ae(%ebx),%eax
f01019d7:	50                   	push   %eax
f01019d8:	e8 9b f3 ff ff       	call   f0100d78 <cprintf>
f01019dd:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01019e0:	83 ec 0c             	sub    $0xc,%esp
f01019e3:	6a 00                	push   $0x0
f01019e5:	e8 01 ee ff ff       	call   f01007eb <iscons>
f01019ea:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01019ed:	83 c4 10             	add    $0x10,%esp
	i = 0;
f01019f0:	bf 00 00 00 00       	mov    $0x0,%edi
f01019f5:	eb 52                	jmp    f0101a49 <readline+0x97>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f01019f7:	83 ec 08             	sub    $0x8,%esp
f01019fa:	50                   	push   %eax
f01019fb:	8d 83 9c e8 fe ff    	lea    -0x11764(%ebx),%eax
f0101a01:	50                   	push   %eax
f0101a02:	e8 71 f3 ff ff       	call   f0100d78 <cprintf>
			return NULL;
f0101a07:	83 c4 10             	add    $0x10,%esp
f0101a0a:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0101a0f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101a12:	5b                   	pop    %ebx
f0101a13:	5e                   	pop    %esi
f0101a14:	5f                   	pop    %edi
f0101a15:	5d                   	pop    %ebp
f0101a16:	c3                   	ret    
			if (echoing)
f0101a17:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101a1b:	75 05                	jne    f0101a22 <readline+0x70>
			i--;
f0101a1d:	83 ef 01             	sub    $0x1,%edi
f0101a20:	eb 27                	jmp    f0101a49 <readline+0x97>
				cputchar('\b');
f0101a22:	83 ec 0c             	sub    $0xc,%esp
f0101a25:	6a 08                	push   $0x8
f0101a27:	e8 9e ed ff ff       	call   f01007ca <cputchar>
f0101a2c:	83 c4 10             	add    $0x10,%esp
f0101a2f:	eb ec                	jmp    f0101a1d <readline+0x6b>
				cputchar(c);
f0101a31:	83 ec 0c             	sub    $0xc,%esp
f0101a34:	56                   	push   %esi
f0101a35:	e8 90 ed ff ff       	call   f01007ca <cputchar>
f0101a3a:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0101a3d:	89 f0                	mov    %esi,%eax
f0101a3f:	88 84 3b 4c 02 00 00 	mov    %al,0x24c(%ebx,%edi,1)
f0101a46:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0101a49:	e8 8c ed ff ff       	call   f01007da <getchar>
f0101a4e:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f0101a50:	85 c0                	test   %eax,%eax
f0101a52:	78 a3                	js     f01019f7 <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101a54:	83 f8 08             	cmp    $0x8,%eax
f0101a57:	0f 94 c2             	sete   %dl
f0101a5a:	83 f8 7f             	cmp    $0x7f,%eax
f0101a5d:	0f 94 c0             	sete   %al
f0101a60:	08 c2                	or     %al,%dl
f0101a62:	74 04                	je     f0101a68 <readline+0xb6>
f0101a64:	85 ff                	test   %edi,%edi
f0101a66:	7f af                	jg     f0101a17 <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101a68:	83 fe 1f             	cmp    $0x1f,%esi
f0101a6b:	7e 10                	jle    f0101a7d <readline+0xcb>
f0101a6d:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0101a73:	7f 08                	jg     f0101a7d <readline+0xcb>
			if (echoing)
f0101a75:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101a79:	74 c2                	je     f0101a3d <readline+0x8b>
f0101a7b:	eb b4                	jmp    f0101a31 <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f0101a7d:	83 fe 0a             	cmp    $0xa,%esi
f0101a80:	74 05                	je     f0101a87 <readline+0xd5>
f0101a82:	83 fe 0d             	cmp    $0xd,%esi
f0101a85:	75 c2                	jne    f0101a49 <readline+0x97>
			if (echoing)
f0101a87:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101a8b:	75 13                	jne    f0101aa0 <readline+0xee>
			buf[i] = 0;
f0101a8d:	c6 84 3b 4c 02 00 00 	movb   $0x0,0x24c(%ebx,%edi,1)
f0101a94:	00 
			return buf;
f0101a95:	8d 83 4c 02 00 00    	lea    0x24c(%ebx),%eax
f0101a9b:	e9 6f ff ff ff       	jmp    f0101a0f <readline+0x5d>
				cputchar('\n');
f0101aa0:	83 ec 0c             	sub    $0xc,%esp
f0101aa3:	6a 0a                	push   $0xa
f0101aa5:	e8 20 ed ff ff       	call   f01007ca <cputchar>
f0101aaa:	83 c4 10             	add    $0x10,%esp
f0101aad:	eb de                	jmp    f0101a8d <readline+0xdb>

f0101aaf <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101aaf:	55                   	push   %ebp
f0101ab0:	89 e5                	mov    %esp,%ebp
f0101ab2:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101ab5:	b8 00 00 00 00       	mov    $0x0,%eax
f0101aba:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101abe:	74 05                	je     f0101ac5 <strlen+0x16>
		n++;
f0101ac0:	83 c0 01             	add    $0x1,%eax
f0101ac3:	eb f5                	jmp    f0101aba <strlen+0xb>
	return n;
}
f0101ac5:	5d                   	pop    %ebp
f0101ac6:	c3                   	ret    

f0101ac7 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101ac7:	55                   	push   %ebp
f0101ac8:	89 e5                	mov    %esp,%ebp
f0101aca:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101acd:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101ad0:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ad5:	39 c2                	cmp    %eax,%edx
f0101ad7:	74 0d                	je     f0101ae6 <strnlen+0x1f>
f0101ad9:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0101add:	74 05                	je     f0101ae4 <strnlen+0x1d>
		n++;
f0101adf:	83 c2 01             	add    $0x1,%edx
f0101ae2:	eb f1                	jmp    f0101ad5 <strnlen+0xe>
f0101ae4:	89 d0                	mov    %edx,%eax
	return n;
}
f0101ae6:	5d                   	pop    %ebp
f0101ae7:	c3                   	ret    

f0101ae8 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101ae8:	55                   	push   %ebp
f0101ae9:	89 e5                	mov    %esp,%ebp
f0101aeb:	53                   	push   %ebx
f0101aec:	8b 45 08             	mov    0x8(%ebp),%eax
f0101aef:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101af2:	ba 00 00 00 00       	mov    $0x0,%edx
f0101af7:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0101afb:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0101afe:	83 c2 01             	add    $0x1,%edx
f0101b01:	84 c9                	test   %cl,%cl
f0101b03:	75 f2                	jne    f0101af7 <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0101b05:	5b                   	pop    %ebx
f0101b06:	5d                   	pop    %ebp
f0101b07:	c3                   	ret    

f0101b08 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101b08:	55                   	push   %ebp
f0101b09:	89 e5                	mov    %esp,%ebp
f0101b0b:	53                   	push   %ebx
f0101b0c:	83 ec 10             	sub    $0x10,%esp
f0101b0f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101b12:	53                   	push   %ebx
f0101b13:	e8 97 ff ff ff       	call   f0101aaf <strlen>
f0101b18:	83 c4 08             	add    $0x8,%esp
	strcpy(dst + len, src);
f0101b1b:	ff 75 0c             	pushl  0xc(%ebp)
f0101b1e:	01 d8                	add    %ebx,%eax
f0101b20:	50                   	push   %eax
f0101b21:	e8 c2 ff ff ff       	call   f0101ae8 <strcpy>
	return dst;
}
f0101b26:	89 d8                	mov    %ebx,%eax
f0101b28:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101b2b:	c9                   	leave  
f0101b2c:	c3                   	ret    

f0101b2d <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101b2d:	55                   	push   %ebp
f0101b2e:	89 e5                	mov    %esp,%ebp
f0101b30:	56                   	push   %esi
f0101b31:	53                   	push   %ebx
f0101b32:	8b 45 08             	mov    0x8(%ebp),%eax
f0101b35:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101b38:	89 c6                	mov    %eax,%esi
f0101b3a:	03 75 10             	add    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101b3d:	89 c2                	mov    %eax,%edx
f0101b3f:	39 f2                	cmp    %esi,%edx
f0101b41:	74 11                	je     f0101b54 <strncpy+0x27>
		*dst++ = *src;
f0101b43:	83 c2 01             	add    $0x1,%edx
f0101b46:	0f b6 19             	movzbl (%ecx),%ebx
f0101b49:	88 5a ff             	mov    %bl,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101b4c:	80 fb 01             	cmp    $0x1,%bl
f0101b4f:	83 d9 ff             	sbb    $0xffffffff,%ecx
f0101b52:	eb eb                	jmp    f0101b3f <strncpy+0x12>
	}
	return ret;
}
f0101b54:	5b                   	pop    %ebx
f0101b55:	5e                   	pop    %esi
f0101b56:	5d                   	pop    %ebp
f0101b57:	c3                   	ret    

f0101b58 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101b58:	55                   	push   %ebp
f0101b59:	89 e5                	mov    %esp,%ebp
f0101b5b:	56                   	push   %esi
f0101b5c:	53                   	push   %ebx
f0101b5d:	8b 75 08             	mov    0x8(%ebp),%esi
f0101b60:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101b63:	8b 55 10             	mov    0x10(%ebp),%edx
f0101b66:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101b68:	85 d2                	test   %edx,%edx
f0101b6a:	74 21                	je     f0101b8d <strlcpy+0x35>
f0101b6c:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0101b70:	89 f2                	mov    %esi,%edx
		while (--size > 0 && *src != '\0')
f0101b72:	39 c2                	cmp    %eax,%edx
f0101b74:	74 14                	je     f0101b8a <strlcpy+0x32>
f0101b76:	0f b6 19             	movzbl (%ecx),%ebx
f0101b79:	84 db                	test   %bl,%bl
f0101b7b:	74 0b                	je     f0101b88 <strlcpy+0x30>
			*dst++ = *src++;
f0101b7d:	83 c1 01             	add    $0x1,%ecx
f0101b80:	83 c2 01             	add    $0x1,%edx
f0101b83:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101b86:	eb ea                	jmp    f0101b72 <strlcpy+0x1a>
f0101b88:	89 d0                	mov    %edx,%eax
		*dst = '\0';
f0101b8a:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101b8d:	29 f0                	sub    %esi,%eax
}
f0101b8f:	5b                   	pop    %ebx
f0101b90:	5e                   	pop    %esi
f0101b91:	5d                   	pop    %ebp
f0101b92:	c3                   	ret    

f0101b93 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101b93:	55                   	push   %ebp
f0101b94:	89 e5                	mov    %esp,%ebp
f0101b96:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101b99:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101b9c:	0f b6 01             	movzbl (%ecx),%eax
f0101b9f:	84 c0                	test   %al,%al
f0101ba1:	74 0c                	je     f0101baf <strcmp+0x1c>
f0101ba3:	3a 02                	cmp    (%edx),%al
f0101ba5:	75 08                	jne    f0101baf <strcmp+0x1c>
		p++, q++;
f0101ba7:	83 c1 01             	add    $0x1,%ecx
f0101baa:	83 c2 01             	add    $0x1,%edx
f0101bad:	eb ed                	jmp    f0101b9c <strcmp+0x9>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101baf:	0f b6 c0             	movzbl %al,%eax
f0101bb2:	0f b6 12             	movzbl (%edx),%edx
f0101bb5:	29 d0                	sub    %edx,%eax
}
f0101bb7:	5d                   	pop    %ebp
f0101bb8:	c3                   	ret    

f0101bb9 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101bb9:	55                   	push   %ebp
f0101bba:	89 e5                	mov    %esp,%ebp
f0101bbc:	53                   	push   %ebx
f0101bbd:	8b 45 08             	mov    0x8(%ebp),%eax
f0101bc0:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101bc3:	89 c3                	mov    %eax,%ebx
f0101bc5:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101bc8:	eb 06                	jmp    f0101bd0 <strncmp+0x17>
		n--, p++, q++;
f0101bca:	83 c0 01             	add    $0x1,%eax
f0101bcd:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0101bd0:	39 d8                	cmp    %ebx,%eax
f0101bd2:	74 16                	je     f0101bea <strncmp+0x31>
f0101bd4:	0f b6 08             	movzbl (%eax),%ecx
f0101bd7:	84 c9                	test   %cl,%cl
f0101bd9:	74 04                	je     f0101bdf <strncmp+0x26>
f0101bdb:	3a 0a                	cmp    (%edx),%cl
f0101bdd:	74 eb                	je     f0101bca <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101bdf:	0f b6 00             	movzbl (%eax),%eax
f0101be2:	0f b6 12             	movzbl (%edx),%edx
f0101be5:	29 d0                	sub    %edx,%eax
}
f0101be7:	5b                   	pop    %ebx
f0101be8:	5d                   	pop    %ebp
f0101be9:	c3                   	ret    
		return 0;
f0101bea:	b8 00 00 00 00       	mov    $0x0,%eax
f0101bef:	eb f6                	jmp    f0101be7 <strncmp+0x2e>

f0101bf1 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101bf1:	55                   	push   %ebp
f0101bf2:	89 e5                	mov    %esp,%ebp
f0101bf4:	8b 45 08             	mov    0x8(%ebp),%eax
f0101bf7:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101bfb:	0f b6 10             	movzbl (%eax),%edx
f0101bfe:	84 d2                	test   %dl,%dl
f0101c00:	74 09                	je     f0101c0b <strchr+0x1a>
		if (*s == c)
f0101c02:	38 ca                	cmp    %cl,%dl
f0101c04:	74 0a                	je     f0101c10 <strchr+0x1f>
	for (; *s; s++)
f0101c06:	83 c0 01             	add    $0x1,%eax
f0101c09:	eb f0                	jmp    f0101bfb <strchr+0xa>
			return (char *) s;
	return 0;
f0101c0b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101c10:	5d                   	pop    %ebp
f0101c11:	c3                   	ret    

f0101c12 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101c12:	55                   	push   %ebp
f0101c13:	89 e5                	mov    %esp,%ebp
f0101c15:	8b 45 08             	mov    0x8(%ebp),%eax
f0101c18:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101c1c:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101c1f:	38 ca                	cmp    %cl,%dl
f0101c21:	74 09                	je     f0101c2c <strfind+0x1a>
f0101c23:	84 d2                	test   %dl,%dl
f0101c25:	74 05                	je     f0101c2c <strfind+0x1a>
	for (; *s; s++)
f0101c27:	83 c0 01             	add    $0x1,%eax
f0101c2a:	eb f0                	jmp    f0101c1c <strfind+0xa>
			break;
	return (char *) s;
}
f0101c2c:	5d                   	pop    %ebp
f0101c2d:	c3                   	ret    

f0101c2e <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101c2e:	55                   	push   %ebp
f0101c2f:	89 e5                	mov    %esp,%ebp
f0101c31:	57                   	push   %edi
f0101c32:	56                   	push   %esi
f0101c33:	53                   	push   %ebx
f0101c34:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101c37:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101c3a:	85 c9                	test   %ecx,%ecx
f0101c3c:	74 31                	je     f0101c6f <memset+0x41>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101c3e:	89 f8                	mov    %edi,%eax
f0101c40:	09 c8                	or     %ecx,%eax
f0101c42:	a8 03                	test   $0x3,%al
f0101c44:	75 23                	jne    f0101c69 <memset+0x3b>
		c &= 0xFF;
f0101c46:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101c4a:	89 d3                	mov    %edx,%ebx
f0101c4c:	c1 e3 08             	shl    $0x8,%ebx
f0101c4f:	89 d0                	mov    %edx,%eax
f0101c51:	c1 e0 18             	shl    $0x18,%eax
f0101c54:	89 d6                	mov    %edx,%esi
f0101c56:	c1 e6 10             	shl    $0x10,%esi
f0101c59:	09 f0                	or     %esi,%eax
f0101c5b:	09 c2                	or     %eax,%edx
f0101c5d:	09 da                	or     %ebx,%edx
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0101c5f:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0101c62:	89 d0                	mov    %edx,%eax
f0101c64:	fc                   	cld    
f0101c65:	f3 ab                	rep stos %eax,%es:(%edi)
f0101c67:	eb 06                	jmp    f0101c6f <memset+0x41>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101c69:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101c6c:	fc                   	cld    
f0101c6d:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101c6f:	89 f8                	mov    %edi,%eax
f0101c71:	5b                   	pop    %ebx
f0101c72:	5e                   	pop    %esi
f0101c73:	5f                   	pop    %edi
f0101c74:	5d                   	pop    %ebp
f0101c75:	c3                   	ret    

f0101c76 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101c76:	55                   	push   %ebp
f0101c77:	89 e5                	mov    %esp,%ebp
f0101c79:	57                   	push   %edi
f0101c7a:	56                   	push   %esi
f0101c7b:	8b 45 08             	mov    0x8(%ebp),%eax
f0101c7e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101c81:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101c84:	39 c6                	cmp    %eax,%esi
f0101c86:	73 32                	jae    f0101cba <memmove+0x44>
f0101c88:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101c8b:	39 c2                	cmp    %eax,%edx
f0101c8d:	76 2b                	jbe    f0101cba <memmove+0x44>
		s += n;
		d += n;
f0101c8f:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101c92:	89 fe                	mov    %edi,%esi
f0101c94:	09 ce                	or     %ecx,%esi
f0101c96:	09 d6                	or     %edx,%esi
f0101c98:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101c9e:	75 0e                	jne    f0101cae <memmove+0x38>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101ca0:	83 ef 04             	sub    $0x4,%edi
f0101ca3:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101ca6:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0101ca9:	fd                   	std    
f0101caa:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101cac:	eb 09                	jmp    f0101cb7 <memmove+0x41>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101cae:	83 ef 01             	sub    $0x1,%edi
f0101cb1:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0101cb4:	fd                   	std    
f0101cb5:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101cb7:	fc                   	cld    
f0101cb8:	eb 1a                	jmp    f0101cd4 <memmove+0x5e>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101cba:	89 c2                	mov    %eax,%edx
f0101cbc:	09 ca                	or     %ecx,%edx
f0101cbe:	09 f2                	or     %esi,%edx
f0101cc0:	f6 c2 03             	test   $0x3,%dl
f0101cc3:	75 0a                	jne    f0101ccf <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101cc5:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0101cc8:	89 c7                	mov    %eax,%edi
f0101cca:	fc                   	cld    
f0101ccb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101ccd:	eb 05                	jmp    f0101cd4 <memmove+0x5e>
		else
			asm volatile("cld; rep movsb\n"
f0101ccf:	89 c7                	mov    %eax,%edi
f0101cd1:	fc                   	cld    
f0101cd2:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101cd4:	5e                   	pop    %esi
f0101cd5:	5f                   	pop    %edi
f0101cd6:	5d                   	pop    %ebp
f0101cd7:	c3                   	ret    

f0101cd8 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101cd8:	55                   	push   %ebp
f0101cd9:	89 e5                	mov    %esp,%ebp
f0101cdb:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101cde:	ff 75 10             	pushl  0x10(%ebp)
f0101ce1:	ff 75 0c             	pushl  0xc(%ebp)
f0101ce4:	ff 75 08             	pushl  0x8(%ebp)
f0101ce7:	e8 8a ff ff ff       	call   f0101c76 <memmove>
}
f0101cec:	c9                   	leave  
f0101ced:	c3                   	ret    

f0101cee <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101cee:	55                   	push   %ebp
f0101cef:	89 e5                	mov    %esp,%ebp
f0101cf1:	56                   	push   %esi
f0101cf2:	53                   	push   %ebx
f0101cf3:	8b 45 08             	mov    0x8(%ebp),%eax
f0101cf6:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101cf9:	89 c6                	mov    %eax,%esi
f0101cfb:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101cfe:	39 f0                	cmp    %esi,%eax
f0101d00:	74 1c                	je     f0101d1e <memcmp+0x30>
		if (*s1 != *s2)
f0101d02:	0f b6 08             	movzbl (%eax),%ecx
f0101d05:	0f b6 1a             	movzbl (%edx),%ebx
f0101d08:	38 d9                	cmp    %bl,%cl
f0101d0a:	75 08                	jne    f0101d14 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0101d0c:	83 c0 01             	add    $0x1,%eax
f0101d0f:	83 c2 01             	add    $0x1,%edx
f0101d12:	eb ea                	jmp    f0101cfe <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f0101d14:	0f b6 c1             	movzbl %cl,%eax
f0101d17:	0f b6 db             	movzbl %bl,%ebx
f0101d1a:	29 d8                	sub    %ebx,%eax
f0101d1c:	eb 05                	jmp    f0101d23 <memcmp+0x35>
	}

	return 0;
f0101d1e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101d23:	5b                   	pop    %ebx
f0101d24:	5e                   	pop    %esi
f0101d25:	5d                   	pop    %ebp
f0101d26:	c3                   	ret    

f0101d27 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101d27:	55                   	push   %ebp
f0101d28:	89 e5                	mov    %esp,%ebp
f0101d2a:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d2d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0101d30:	89 c2                	mov    %eax,%edx
f0101d32:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101d35:	39 d0                	cmp    %edx,%eax
f0101d37:	73 09                	jae    f0101d42 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101d39:	38 08                	cmp    %cl,(%eax)
f0101d3b:	74 05                	je     f0101d42 <memfind+0x1b>
	for (; s < ends; s++)
f0101d3d:	83 c0 01             	add    $0x1,%eax
f0101d40:	eb f3                	jmp    f0101d35 <memfind+0xe>
			break;
	return (void *) s;
}
f0101d42:	5d                   	pop    %ebp
f0101d43:	c3                   	ret    

f0101d44 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101d44:	55                   	push   %ebp
f0101d45:	89 e5                	mov    %esp,%ebp
f0101d47:	57                   	push   %edi
f0101d48:	56                   	push   %esi
f0101d49:	53                   	push   %ebx
f0101d4a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101d4d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101d50:	eb 03                	jmp    f0101d55 <strtol+0x11>
		s++;
f0101d52:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0101d55:	0f b6 01             	movzbl (%ecx),%eax
f0101d58:	3c 20                	cmp    $0x20,%al
f0101d5a:	74 f6                	je     f0101d52 <strtol+0xe>
f0101d5c:	3c 09                	cmp    $0x9,%al
f0101d5e:	74 f2                	je     f0101d52 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0101d60:	3c 2b                	cmp    $0x2b,%al
f0101d62:	74 2a                	je     f0101d8e <strtol+0x4a>
	int neg = 0;
f0101d64:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0101d69:	3c 2d                	cmp    $0x2d,%al
f0101d6b:	74 2b                	je     f0101d98 <strtol+0x54>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101d6d:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101d73:	75 0f                	jne    f0101d84 <strtol+0x40>
f0101d75:	80 39 30             	cmpb   $0x30,(%ecx)
f0101d78:	74 28                	je     f0101da2 <strtol+0x5e>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101d7a:	85 db                	test   %ebx,%ebx
f0101d7c:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101d81:	0f 44 d8             	cmove  %eax,%ebx
f0101d84:	b8 00 00 00 00       	mov    $0x0,%eax
f0101d89:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101d8c:	eb 50                	jmp    f0101dde <strtol+0x9a>
		s++;
f0101d8e:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0101d91:	bf 00 00 00 00       	mov    $0x0,%edi
f0101d96:	eb d5                	jmp    f0101d6d <strtol+0x29>
		s++, neg = 1;
f0101d98:	83 c1 01             	add    $0x1,%ecx
f0101d9b:	bf 01 00 00 00       	mov    $0x1,%edi
f0101da0:	eb cb                	jmp    f0101d6d <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101da2:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0101da6:	74 0e                	je     f0101db6 <strtol+0x72>
	else if (base == 0 && s[0] == '0')
f0101da8:	85 db                	test   %ebx,%ebx
f0101daa:	75 d8                	jne    f0101d84 <strtol+0x40>
		s++, base = 8;
f0101dac:	83 c1 01             	add    $0x1,%ecx
f0101daf:	bb 08 00 00 00       	mov    $0x8,%ebx
f0101db4:	eb ce                	jmp    f0101d84 <strtol+0x40>
		s += 2, base = 16;
f0101db6:	83 c1 02             	add    $0x2,%ecx
f0101db9:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101dbe:	eb c4                	jmp    f0101d84 <strtol+0x40>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0101dc0:	8d 72 9f             	lea    -0x61(%edx),%esi
f0101dc3:	89 f3                	mov    %esi,%ebx
f0101dc5:	80 fb 19             	cmp    $0x19,%bl
f0101dc8:	77 29                	ja     f0101df3 <strtol+0xaf>
			dig = *s - 'a' + 10;
f0101dca:	0f be d2             	movsbl %dl,%edx
f0101dcd:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0101dd0:	3b 55 10             	cmp    0x10(%ebp),%edx
f0101dd3:	7d 30                	jge    f0101e05 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f0101dd5:	83 c1 01             	add    $0x1,%ecx
f0101dd8:	0f af 45 10          	imul   0x10(%ebp),%eax
f0101ddc:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0101dde:	0f b6 11             	movzbl (%ecx),%edx
f0101de1:	8d 72 d0             	lea    -0x30(%edx),%esi
f0101de4:	89 f3                	mov    %esi,%ebx
f0101de6:	80 fb 09             	cmp    $0x9,%bl
f0101de9:	77 d5                	ja     f0101dc0 <strtol+0x7c>
			dig = *s - '0';
f0101deb:	0f be d2             	movsbl %dl,%edx
f0101dee:	83 ea 30             	sub    $0x30,%edx
f0101df1:	eb dd                	jmp    f0101dd0 <strtol+0x8c>
		else if (*s >= 'A' && *s <= 'Z')
f0101df3:	8d 72 bf             	lea    -0x41(%edx),%esi
f0101df6:	89 f3                	mov    %esi,%ebx
f0101df8:	80 fb 19             	cmp    $0x19,%bl
f0101dfb:	77 08                	ja     f0101e05 <strtol+0xc1>
			dig = *s - 'A' + 10;
f0101dfd:	0f be d2             	movsbl %dl,%edx
f0101e00:	83 ea 37             	sub    $0x37,%edx
f0101e03:	eb cb                	jmp    f0101dd0 <strtol+0x8c>
		// we don't properly detect overflow!
	}

	if (endptr)
f0101e05:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101e09:	74 05                	je     f0101e10 <strtol+0xcc>
		*endptr = (char *) s;
f0101e0b:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101e0e:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0101e10:	89 c2                	mov    %eax,%edx
f0101e12:	f7 da                	neg    %edx
f0101e14:	85 ff                	test   %edi,%edi
f0101e16:	0f 45 c2             	cmovne %edx,%eax
}
f0101e19:	5b                   	pop    %ebx
f0101e1a:	5e                   	pop    %esi
f0101e1b:	5f                   	pop    %edi
f0101e1c:	5d                   	pop    %ebp
f0101e1d:	c3                   	ret    
f0101e1e:	66 90                	xchg   %ax,%ax

f0101e20 <__udivdi3>:
f0101e20:	55                   	push   %ebp
f0101e21:	57                   	push   %edi
f0101e22:	56                   	push   %esi
f0101e23:	53                   	push   %ebx
f0101e24:	83 ec 1c             	sub    $0x1c,%esp
f0101e27:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0101e2b:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f0101e2f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101e33:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0101e37:	85 d2                	test   %edx,%edx
f0101e39:	75 4d                	jne    f0101e88 <__udivdi3+0x68>
f0101e3b:	39 f3                	cmp    %esi,%ebx
f0101e3d:	76 19                	jbe    f0101e58 <__udivdi3+0x38>
f0101e3f:	31 ff                	xor    %edi,%edi
f0101e41:	89 e8                	mov    %ebp,%eax
f0101e43:	89 f2                	mov    %esi,%edx
f0101e45:	f7 f3                	div    %ebx
f0101e47:	89 fa                	mov    %edi,%edx
f0101e49:	83 c4 1c             	add    $0x1c,%esp
f0101e4c:	5b                   	pop    %ebx
f0101e4d:	5e                   	pop    %esi
f0101e4e:	5f                   	pop    %edi
f0101e4f:	5d                   	pop    %ebp
f0101e50:	c3                   	ret    
f0101e51:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101e58:	89 d9                	mov    %ebx,%ecx
f0101e5a:	85 db                	test   %ebx,%ebx
f0101e5c:	75 0b                	jne    f0101e69 <__udivdi3+0x49>
f0101e5e:	b8 01 00 00 00       	mov    $0x1,%eax
f0101e63:	31 d2                	xor    %edx,%edx
f0101e65:	f7 f3                	div    %ebx
f0101e67:	89 c1                	mov    %eax,%ecx
f0101e69:	31 d2                	xor    %edx,%edx
f0101e6b:	89 f0                	mov    %esi,%eax
f0101e6d:	f7 f1                	div    %ecx
f0101e6f:	89 c6                	mov    %eax,%esi
f0101e71:	89 e8                	mov    %ebp,%eax
f0101e73:	89 f7                	mov    %esi,%edi
f0101e75:	f7 f1                	div    %ecx
f0101e77:	89 fa                	mov    %edi,%edx
f0101e79:	83 c4 1c             	add    $0x1c,%esp
f0101e7c:	5b                   	pop    %ebx
f0101e7d:	5e                   	pop    %esi
f0101e7e:	5f                   	pop    %edi
f0101e7f:	5d                   	pop    %ebp
f0101e80:	c3                   	ret    
f0101e81:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101e88:	39 f2                	cmp    %esi,%edx
f0101e8a:	77 1c                	ja     f0101ea8 <__udivdi3+0x88>
f0101e8c:	0f bd fa             	bsr    %edx,%edi
f0101e8f:	83 f7 1f             	xor    $0x1f,%edi
f0101e92:	75 2c                	jne    f0101ec0 <__udivdi3+0xa0>
f0101e94:	39 f2                	cmp    %esi,%edx
f0101e96:	72 06                	jb     f0101e9e <__udivdi3+0x7e>
f0101e98:	31 c0                	xor    %eax,%eax
f0101e9a:	39 eb                	cmp    %ebp,%ebx
f0101e9c:	77 a9                	ja     f0101e47 <__udivdi3+0x27>
f0101e9e:	b8 01 00 00 00       	mov    $0x1,%eax
f0101ea3:	eb a2                	jmp    f0101e47 <__udivdi3+0x27>
f0101ea5:	8d 76 00             	lea    0x0(%esi),%esi
f0101ea8:	31 ff                	xor    %edi,%edi
f0101eaa:	31 c0                	xor    %eax,%eax
f0101eac:	89 fa                	mov    %edi,%edx
f0101eae:	83 c4 1c             	add    $0x1c,%esp
f0101eb1:	5b                   	pop    %ebx
f0101eb2:	5e                   	pop    %esi
f0101eb3:	5f                   	pop    %edi
f0101eb4:	5d                   	pop    %ebp
f0101eb5:	c3                   	ret    
f0101eb6:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101ebd:	8d 76 00             	lea    0x0(%esi),%esi
f0101ec0:	89 f9                	mov    %edi,%ecx
f0101ec2:	b8 20 00 00 00       	mov    $0x20,%eax
f0101ec7:	29 f8                	sub    %edi,%eax
f0101ec9:	d3 e2                	shl    %cl,%edx
f0101ecb:	89 54 24 08          	mov    %edx,0x8(%esp)
f0101ecf:	89 c1                	mov    %eax,%ecx
f0101ed1:	89 da                	mov    %ebx,%edx
f0101ed3:	d3 ea                	shr    %cl,%edx
f0101ed5:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0101ed9:	09 d1                	or     %edx,%ecx
f0101edb:	89 f2                	mov    %esi,%edx
f0101edd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101ee1:	89 f9                	mov    %edi,%ecx
f0101ee3:	d3 e3                	shl    %cl,%ebx
f0101ee5:	89 c1                	mov    %eax,%ecx
f0101ee7:	d3 ea                	shr    %cl,%edx
f0101ee9:	89 f9                	mov    %edi,%ecx
f0101eeb:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0101eef:	89 eb                	mov    %ebp,%ebx
f0101ef1:	d3 e6                	shl    %cl,%esi
f0101ef3:	89 c1                	mov    %eax,%ecx
f0101ef5:	d3 eb                	shr    %cl,%ebx
f0101ef7:	09 de                	or     %ebx,%esi
f0101ef9:	89 f0                	mov    %esi,%eax
f0101efb:	f7 74 24 08          	divl   0x8(%esp)
f0101eff:	89 d6                	mov    %edx,%esi
f0101f01:	89 c3                	mov    %eax,%ebx
f0101f03:	f7 64 24 0c          	mull   0xc(%esp)
f0101f07:	39 d6                	cmp    %edx,%esi
f0101f09:	72 15                	jb     f0101f20 <__udivdi3+0x100>
f0101f0b:	89 f9                	mov    %edi,%ecx
f0101f0d:	d3 e5                	shl    %cl,%ebp
f0101f0f:	39 c5                	cmp    %eax,%ebp
f0101f11:	73 04                	jae    f0101f17 <__udivdi3+0xf7>
f0101f13:	39 d6                	cmp    %edx,%esi
f0101f15:	74 09                	je     f0101f20 <__udivdi3+0x100>
f0101f17:	89 d8                	mov    %ebx,%eax
f0101f19:	31 ff                	xor    %edi,%edi
f0101f1b:	e9 27 ff ff ff       	jmp    f0101e47 <__udivdi3+0x27>
f0101f20:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0101f23:	31 ff                	xor    %edi,%edi
f0101f25:	e9 1d ff ff ff       	jmp    f0101e47 <__udivdi3+0x27>
f0101f2a:	66 90                	xchg   %ax,%ax
f0101f2c:	66 90                	xchg   %ax,%ax
f0101f2e:	66 90                	xchg   %ax,%ax

f0101f30 <__umoddi3>:
f0101f30:	55                   	push   %ebp
f0101f31:	57                   	push   %edi
f0101f32:	56                   	push   %esi
f0101f33:	53                   	push   %ebx
f0101f34:	83 ec 1c             	sub    $0x1c,%esp
f0101f37:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0101f3b:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f0101f3f:	8b 74 24 30          	mov    0x30(%esp),%esi
f0101f43:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101f47:	89 da                	mov    %ebx,%edx
f0101f49:	85 c0                	test   %eax,%eax
f0101f4b:	75 43                	jne    f0101f90 <__umoddi3+0x60>
f0101f4d:	39 df                	cmp    %ebx,%edi
f0101f4f:	76 17                	jbe    f0101f68 <__umoddi3+0x38>
f0101f51:	89 f0                	mov    %esi,%eax
f0101f53:	f7 f7                	div    %edi
f0101f55:	89 d0                	mov    %edx,%eax
f0101f57:	31 d2                	xor    %edx,%edx
f0101f59:	83 c4 1c             	add    $0x1c,%esp
f0101f5c:	5b                   	pop    %ebx
f0101f5d:	5e                   	pop    %esi
f0101f5e:	5f                   	pop    %edi
f0101f5f:	5d                   	pop    %ebp
f0101f60:	c3                   	ret    
f0101f61:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101f68:	89 fd                	mov    %edi,%ebp
f0101f6a:	85 ff                	test   %edi,%edi
f0101f6c:	75 0b                	jne    f0101f79 <__umoddi3+0x49>
f0101f6e:	b8 01 00 00 00       	mov    $0x1,%eax
f0101f73:	31 d2                	xor    %edx,%edx
f0101f75:	f7 f7                	div    %edi
f0101f77:	89 c5                	mov    %eax,%ebp
f0101f79:	89 d8                	mov    %ebx,%eax
f0101f7b:	31 d2                	xor    %edx,%edx
f0101f7d:	f7 f5                	div    %ebp
f0101f7f:	89 f0                	mov    %esi,%eax
f0101f81:	f7 f5                	div    %ebp
f0101f83:	89 d0                	mov    %edx,%eax
f0101f85:	eb d0                	jmp    f0101f57 <__umoddi3+0x27>
f0101f87:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101f8e:	66 90                	xchg   %ax,%ax
f0101f90:	89 f1                	mov    %esi,%ecx
f0101f92:	39 d8                	cmp    %ebx,%eax
f0101f94:	76 0a                	jbe    f0101fa0 <__umoddi3+0x70>
f0101f96:	89 f0                	mov    %esi,%eax
f0101f98:	83 c4 1c             	add    $0x1c,%esp
f0101f9b:	5b                   	pop    %ebx
f0101f9c:	5e                   	pop    %esi
f0101f9d:	5f                   	pop    %edi
f0101f9e:	5d                   	pop    %ebp
f0101f9f:	c3                   	ret    
f0101fa0:	0f bd e8             	bsr    %eax,%ebp
f0101fa3:	83 f5 1f             	xor    $0x1f,%ebp
f0101fa6:	75 20                	jne    f0101fc8 <__umoddi3+0x98>
f0101fa8:	39 d8                	cmp    %ebx,%eax
f0101faa:	0f 82 b0 00 00 00    	jb     f0102060 <__umoddi3+0x130>
f0101fb0:	39 f7                	cmp    %esi,%edi
f0101fb2:	0f 86 a8 00 00 00    	jbe    f0102060 <__umoddi3+0x130>
f0101fb8:	89 c8                	mov    %ecx,%eax
f0101fba:	83 c4 1c             	add    $0x1c,%esp
f0101fbd:	5b                   	pop    %ebx
f0101fbe:	5e                   	pop    %esi
f0101fbf:	5f                   	pop    %edi
f0101fc0:	5d                   	pop    %ebp
f0101fc1:	c3                   	ret    
f0101fc2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101fc8:	89 e9                	mov    %ebp,%ecx
f0101fca:	ba 20 00 00 00       	mov    $0x20,%edx
f0101fcf:	29 ea                	sub    %ebp,%edx
f0101fd1:	d3 e0                	shl    %cl,%eax
f0101fd3:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101fd7:	89 d1                	mov    %edx,%ecx
f0101fd9:	89 f8                	mov    %edi,%eax
f0101fdb:	d3 e8                	shr    %cl,%eax
f0101fdd:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0101fe1:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101fe5:	8b 54 24 04          	mov    0x4(%esp),%edx
f0101fe9:	09 c1                	or     %eax,%ecx
f0101feb:	89 d8                	mov    %ebx,%eax
f0101fed:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101ff1:	89 e9                	mov    %ebp,%ecx
f0101ff3:	d3 e7                	shl    %cl,%edi
f0101ff5:	89 d1                	mov    %edx,%ecx
f0101ff7:	d3 e8                	shr    %cl,%eax
f0101ff9:	89 e9                	mov    %ebp,%ecx
f0101ffb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101fff:	d3 e3                	shl    %cl,%ebx
f0102001:	89 c7                	mov    %eax,%edi
f0102003:	89 d1                	mov    %edx,%ecx
f0102005:	89 f0                	mov    %esi,%eax
f0102007:	d3 e8                	shr    %cl,%eax
f0102009:	89 e9                	mov    %ebp,%ecx
f010200b:	89 fa                	mov    %edi,%edx
f010200d:	d3 e6                	shl    %cl,%esi
f010200f:	09 d8                	or     %ebx,%eax
f0102011:	f7 74 24 08          	divl   0x8(%esp)
f0102015:	89 d1                	mov    %edx,%ecx
f0102017:	89 f3                	mov    %esi,%ebx
f0102019:	f7 64 24 0c          	mull   0xc(%esp)
f010201d:	89 c6                	mov    %eax,%esi
f010201f:	89 d7                	mov    %edx,%edi
f0102021:	39 d1                	cmp    %edx,%ecx
f0102023:	72 06                	jb     f010202b <__umoddi3+0xfb>
f0102025:	75 10                	jne    f0102037 <__umoddi3+0x107>
f0102027:	39 c3                	cmp    %eax,%ebx
f0102029:	73 0c                	jae    f0102037 <__umoddi3+0x107>
f010202b:	2b 44 24 0c          	sub    0xc(%esp),%eax
f010202f:	1b 54 24 08          	sbb    0x8(%esp),%edx
f0102033:	89 d7                	mov    %edx,%edi
f0102035:	89 c6                	mov    %eax,%esi
f0102037:	89 ca                	mov    %ecx,%edx
f0102039:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010203e:	29 f3                	sub    %esi,%ebx
f0102040:	19 fa                	sbb    %edi,%edx
f0102042:	89 d0                	mov    %edx,%eax
f0102044:	d3 e0                	shl    %cl,%eax
f0102046:	89 e9                	mov    %ebp,%ecx
f0102048:	d3 eb                	shr    %cl,%ebx
f010204a:	d3 ea                	shr    %cl,%edx
f010204c:	09 d8                	or     %ebx,%eax
f010204e:	83 c4 1c             	add    $0x1c,%esp
f0102051:	5b                   	pop    %ebx
f0102052:	5e                   	pop    %esi
f0102053:	5f                   	pop    %edi
f0102054:	5d                   	pop    %ebp
f0102055:	c3                   	ret    
f0102056:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f010205d:	8d 76 00             	lea    0x0(%esi),%esi
f0102060:	89 da                	mov    %ebx,%edx
f0102062:	29 fe                	sub    %edi,%esi
f0102064:	19 c2                	sbb    %eax,%edx
f0102066:	89 f1                	mov    %esi,%ecx
f0102068:	89 c8                	mov    %ecx,%eax
f010206a:	e9 4b ff ff ff       	jmp    f0101fba <__umoddi3+0x8a>
