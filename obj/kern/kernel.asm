
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
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
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
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

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
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 c0 19 10 f0 	movl   $0xf01019c0,(%esp)
f0100055:	e8 84 09 00 00       	call   f01009de <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 34 07 00 00       	call   f01007bb <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 dc 19 10 f0 	movl   $0xf01019dc,(%esp)
f0100092:	e8 47 09 00 00       	call   f01009de <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 62 14 00 00       	call   f0101527 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 a5 04 00 00       	call   f010056f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828); 
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 f7 19 10 f0 	movl   $0xf01019f7,(%esp)
f01000d9:	e8 00 09 00 00       	call   f01009de <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 6f 07 00 00       	call   f0100865 <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 12 1a 10 f0 	movl   $0xf0101a12,(%esp)
f010012c:	e8 ad 08 00 00       	call   f01009de <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 6e 08 00 00       	call   f01009ab <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 4e 1a 10 f0 	movl   $0xf0101a4e,(%esp)
f0100144:	e8 95 08 00 00       	call   f01009de <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 10 07 00 00       	call   f0100865 <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 2a 1a 10 f0 	movl   $0xf0101a2a,(%esp)
f0100176:	e8 63 08 00 00       	call   f01009de <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 21 08 00 00       	call   f01009ab <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 4e 1a 10 f0 	movl   $0xf0101a4e,(%esp)
f0100191:	e8 48 08 00 00       	call   f01009de <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	66 90                	xchg   %ax,%ax
f010019e:	66 90                	xchg   %ax,%ax

f01001a0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001a8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001a9:	a8 01                	test   $0x1,%al
f01001ab:	74 08                	je     f01001b5 <serial_proc_data+0x15>
f01001ad:	b2 f8                	mov    $0xf8,%dl
f01001af:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001b0:	0f b6 c0             	movzbl %al,%eax
f01001b3:	eb 05                	jmp    f01001ba <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001ba:	5d                   	pop    %ebp
f01001bb:	c3                   	ret    

f01001bc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001bc:	55                   	push   %ebp
f01001bd:	89 e5                	mov    %esp,%ebp
f01001bf:	53                   	push   %ebx
f01001c0:	83 ec 04             	sub    $0x4,%esp
f01001c3:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001c5:	eb 2a                	jmp    f01001f1 <cons_intr+0x35>
		if (c == 0)
f01001c7:	85 d2                	test   %edx,%edx
f01001c9:	74 26                	je     f01001f1 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01001cb:	a1 24 25 11 f0       	mov    0xf0112524,%eax
f01001d0:	8d 48 01             	lea    0x1(%eax),%ecx
f01001d3:	89 0d 24 25 11 f0    	mov    %ecx,0xf0112524
f01001d9:	88 90 20 23 11 f0    	mov    %dl,-0xfeedce0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01001df:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001e5:	75 0a                	jne    f01001f1 <cons_intr+0x35>
			cons.wpos = 0;
f01001e7:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001ee:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001f1:	ff d3                	call   *%ebx
f01001f3:	89 c2                	mov    %eax,%edx
f01001f5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001f8:	75 cd                	jne    f01001c7 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001fa:	83 c4 04             	add    $0x4,%esp
f01001fd:	5b                   	pop    %ebx
f01001fe:	5d                   	pop    %ebp
f01001ff:	c3                   	ret    

f0100200 <kbd_proc_data>:
f0100200:	ba 64 00 00 00       	mov    $0x64,%edx
f0100205:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f0100206:	a8 01                	test   $0x1,%al
f0100208:	0f 84 f7 00 00 00    	je     f0100305 <kbd_proc_data+0x105>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f010020e:	a8 20                	test   $0x20,%al
f0100210:	0f 85 f5 00 00 00    	jne    f010030b <kbd_proc_data+0x10b>
f0100216:	b2 60                	mov    $0x60,%dl
f0100218:	ec                   	in     (%dx),%al
f0100219:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010021b:	3c e0                	cmp    $0xe0,%al
f010021d:	75 0d                	jne    f010022c <kbd_proc_data+0x2c>
		// E0 escape character
		shift |= E0ESC;
f010021f:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f0100226:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f010022b:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010022c:	55                   	push   %ebp
f010022d:	89 e5                	mov    %esp,%ebp
f010022f:	53                   	push   %ebx
f0100230:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f0100233:	84 c0                	test   %al,%al
f0100235:	79 37                	jns    f010026e <kbd_proc_data+0x6e>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100237:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f010023d:	89 cb                	mov    %ecx,%ebx
f010023f:	83 e3 40             	and    $0x40,%ebx
f0100242:	83 e0 7f             	and    $0x7f,%eax
f0100245:	85 db                	test   %ebx,%ebx
f0100247:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010024a:	0f b6 d2             	movzbl %dl,%edx
f010024d:	0f b6 82 a0 1b 10 f0 	movzbl -0xfefe460(%edx),%eax
f0100254:	83 c8 40             	or     $0x40,%eax
f0100257:	0f b6 c0             	movzbl %al,%eax
f010025a:	f7 d0                	not    %eax
f010025c:	21 c1                	and    %eax,%ecx
f010025e:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
		return 0;
f0100264:	b8 00 00 00 00       	mov    $0x0,%eax
f0100269:	e9 a3 00 00 00       	jmp    f0100311 <kbd_proc_data+0x111>
	} else if (shift & E0ESC) {
f010026e:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100274:	f6 c1 40             	test   $0x40,%cl
f0100277:	74 0e                	je     f0100287 <kbd_proc_data+0x87>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100279:	83 c8 80             	or     $0xffffff80,%eax
f010027c:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010027e:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100281:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f0100287:	0f b6 d2             	movzbl %dl,%edx
f010028a:	0f b6 82 a0 1b 10 f0 	movzbl -0xfefe460(%edx),%eax
f0100291:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
	shift ^= togglecode[data];
f0100297:	0f b6 8a a0 1a 10 f0 	movzbl -0xfefe560(%edx),%ecx
f010029e:	31 c8                	xor    %ecx,%eax
f01002a0:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f01002a5:	89 c1                	mov    %eax,%ecx
f01002a7:	83 e1 03             	and    $0x3,%ecx
f01002aa:	8b 0c 8d 80 1a 10 f0 	mov    -0xfefe580(,%ecx,4),%ecx
f01002b1:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002b5:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01002b8:	a8 08                	test   $0x8,%al
f01002ba:	74 1b                	je     f01002d7 <kbd_proc_data+0xd7>
		if ('a' <= c && c <= 'z')
f01002bc:	89 da                	mov    %ebx,%edx
f01002be:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01002c1:	83 f9 19             	cmp    $0x19,%ecx
f01002c4:	77 05                	ja     f01002cb <kbd_proc_data+0xcb>
			c += 'A' - 'a';
f01002c6:	83 eb 20             	sub    $0x20,%ebx
f01002c9:	eb 0c                	jmp    f01002d7 <kbd_proc_data+0xd7>
		else if ('A' <= c && c <= 'Z')
f01002cb:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002ce:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002d1:	83 fa 19             	cmp    $0x19,%edx
f01002d4:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002d7:	f7 d0                	not    %eax
f01002d9:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002db:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002dd:	f6 c2 06             	test   $0x6,%dl
f01002e0:	75 2f                	jne    f0100311 <kbd_proc_data+0x111>
f01002e2:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002e8:	75 27                	jne    f0100311 <kbd_proc_data+0x111>
		cprintf("Rebooting!\n");
f01002ea:	c7 04 24 44 1a 10 f0 	movl   $0xf0101a44,(%esp)
f01002f1:	e8 e8 06 00 00       	call   f01009de <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002f6:	ba 92 00 00 00       	mov    $0x92,%edx
f01002fb:	b8 03 00 00 00       	mov    $0x3,%eax
f0100300:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100301:	89 d8                	mov    %ebx,%eax
f0100303:	eb 0c                	jmp    f0100311 <kbd_proc_data+0x111>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100305:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010030a:	c3                   	ret    
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f010030b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100310:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100311:	83 c4 14             	add    $0x14,%esp
f0100314:	5b                   	pop    %ebx
f0100315:	5d                   	pop    %ebp
f0100316:	c3                   	ret    

f0100317 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100317:	55                   	push   %ebp
f0100318:	89 e5                	mov    %esp,%ebp
f010031a:	57                   	push   %edi
f010031b:	56                   	push   %esi
f010031c:	53                   	push   %ebx
f010031d:	83 ec 1c             	sub    $0x1c,%esp
f0100320:	89 c7                	mov    %eax,%edi
f0100322:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100327:	be fd 03 00 00       	mov    $0x3fd,%esi
f010032c:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100331:	eb 06                	jmp    f0100339 <cons_putc+0x22>
f0100333:	89 ca                	mov    %ecx,%edx
f0100335:	ec                   	in     (%dx),%al
f0100336:	ec                   	in     (%dx),%al
f0100337:	ec                   	in     (%dx),%al
f0100338:	ec                   	in     (%dx),%al
f0100339:	89 f2                	mov    %esi,%edx
f010033b:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f010033c:	a8 20                	test   $0x20,%al
f010033e:	75 05                	jne    f0100345 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100340:	83 eb 01             	sub    $0x1,%ebx
f0100343:	75 ee                	jne    f0100333 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f0100345:	89 f8                	mov    %edi,%eax
f0100347:	0f b6 c0             	movzbl %al,%eax
f010034a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010034d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100352:	ee                   	out    %al,(%dx)
f0100353:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100358:	be 79 03 00 00       	mov    $0x379,%esi
f010035d:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100362:	eb 06                	jmp    f010036a <cons_putc+0x53>
f0100364:	89 ca                	mov    %ecx,%edx
f0100366:	ec                   	in     (%dx),%al
f0100367:	ec                   	in     (%dx),%al
f0100368:	ec                   	in     (%dx),%al
f0100369:	ec                   	in     (%dx),%al
f010036a:	89 f2                	mov    %esi,%edx
f010036c:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010036d:	84 c0                	test   %al,%al
f010036f:	78 05                	js     f0100376 <cons_putc+0x5f>
f0100371:	83 eb 01             	sub    $0x1,%ebx
f0100374:	75 ee                	jne    f0100364 <cons_putc+0x4d>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100376:	ba 78 03 00 00       	mov    $0x378,%edx
f010037b:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f010037f:	ee                   	out    %al,(%dx)
f0100380:	b2 7a                	mov    $0x7a,%dl
f0100382:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100387:	ee                   	out    %al,(%dx)
f0100388:	b8 08 00 00 00       	mov    $0x8,%eax
f010038d:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010038e:	89 fa                	mov    %edi,%edx
f0100390:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100396:	89 f8                	mov    %edi,%eax
f0100398:	80 cc 07             	or     $0x7,%ah
f010039b:	85 d2                	test   %edx,%edx
f010039d:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f01003a0:	89 f8                	mov    %edi,%eax
f01003a2:	0f b6 c0             	movzbl %al,%eax
f01003a5:	83 f8 09             	cmp    $0x9,%eax
f01003a8:	74 78                	je     f0100422 <cons_putc+0x10b>
f01003aa:	83 f8 09             	cmp    $0x9,%eax
f01003ad:	7f 0a                	jg     f01003b9 <cons_putc+0xa2>
f01003af:	83 f8 08             	cmp    $0x8,%eax
f01003b2:	74 18                	je     f01003cc <cons_putc+0xb5>
f01003b4:	e9 9d 00 00 00       	jmp    f0100456 <cons_putc+0x13f>
f01003b9:	83 f8 0a             	cmp    $0xa,%eax
f01003bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01003c0:	74 3a                	je     f01003fc <cons_putc+0xe5>
f01003c2:	83 f8 0d             	cmp    $0xd,%eax
f01003c5:	74 3d                	je     f0100404 <cons_putc+0xed>
f01003c7:	e9 8a 00 00 00       	jmp    f0100456 <cons_putc+0x13f>
	case '\b':
		if (crt_pos > 0) {
f01003cc:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003d3:	66 85 c0             	test   %ax,%ax
f01003d6:	0f 84 e5 00 00 00    	je     f01004c1 <cons_putc+0x1aa>
			crt_pos--;
f01003dc:	83 e8 01             	sub    $0x1,%eax
f01003df:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003e5:	0f b7 c0             	movzwl %ax,%eax
f01003e8:	66 81 e7 00 ff       	and    $0xff00,%di
f01003ed:	83 cf 20             	or     $0x20,%edi
f01003f0:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01003f6:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003fa:	eb 78                	jmp    f0100474 <cons_putc+0x15d>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003fc:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f0100403:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100404:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f010040b:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100411:	c1 e8 16             	shr    $0x16,%eax
f0100414:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100417:	c1 e0 04             	shl    $0x4,%eax
f010041a:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f0100420:	eb 52                	jmp    f0100474 <cons_putc+0x15d>
		break;
	case '\t':
		cons_putc(' ');
f0100422:	b8 20 00 00 00       	mov    $0x20,%eax
f0100427:	e8 eb fe ff ff       	call   f0100317 <cons_putc>
		cons_putc(' ');
f010042c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100431:	e8 e1 fe ff ff       	call   f0100317 <cons_putc>
		cons_putc(' ');
f0100436:	b8 20 00 00 00       	mov    $0x20,%eax
f010043b:	e8 d7 fe ff ff       	call   f0100317 <cons_putc>
		cons_putc(' ');
f0100440:	b8 20 00 00 00       	mov    $0x20,%eax
f0100445:	e8 cd fe ff ff       	call   f0100317 <cons_putc>
		cons_putc(' ');
f010044a:	b8 20 00 00 00       	mov    $0x20,%eax
f010044f:	e8 c3 fe ff ff       	call   f0100317 <cons_putc>
f0100454:	eb 1e                	jmp    f0100474 <cons_putc+0x15d>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100456:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f010045d:	8d 50 01             	lea    0x1(%eax),%edx
f0100460:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f0100467:	0f b7 c0             	movzwl %ax,%eax
f010046a:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100470:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100474:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f010047b:	cf 07 
f010047d:	76 42                	jbe    f01004c1 <cons_putc+0x1aa>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010047f:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f0100484:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010048b:	00 
f010048c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100492:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100496:	89 04 24             	mov    %eax,(%esp)
f0100499:	e8 d6 10 00 00       	call   f0101574 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010049e:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004a4:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f01004a9:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01004af:	83 c0 01             	add    $0x1,%eax
f01004b2:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01004b7:	75 f0                	jne    f01004a9 <cons_putc+0x192>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01004b9:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f01004c0:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004c1:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01004c7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004cc:	89 ca                	mov    %ecx,%edx
f01004ce:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004cf:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004d6:	8d 71 01             	lea    0x1(%ecx),%esi
f01004d9:	89 d8                	mov    %ebx,%eax
f01004db:	66 c1 e8 08          	shr    $0x8,%ax
f01004df:	89 f2                	mov    %esi,%edx
f01004e1:	ee                   	out    %al,(%dx)
f01004e2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004e7:	89 ca                	mov    %ecx,%edx
f01004e9:	ee                   	out    %al,(%dx)
f01004ea:	89 d8                	mov    %ebx,%eax
f01004ec:	89 f2                	mov    %esi,%edx
f01004ee:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004ef:	83 c4 1c             	add    $0x1c,%esp
f01004f2:	5b                   	pop    %ebx
f01004f3:	5e                   	pop    %esi
f01004f4:	5f                   	pop    %edi
f01004f5:	5d                   	pop    %ebp
f01004f6:	c3                   	ret    

f01004f7 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004f7:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004fe:	74 11                	je     f0100511 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100500:	55                   	push   %ebp
f0100501:	89 e5                	mov    %esp,%ebp
f0100503:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100506:	b8 a0 01 10 f0       	mov    $0xf01001a0,%eax
f010050b:	e8 ac fc ff ff       	call   f01001bc <cons_intr>
}
f0100510:	c9                   	leave  
f0100511:	f3 c3                	repz ret 

f0100513 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100513:	55                   	push   %ebp
f0100514:	89 e5                	mov    %esp,%ebp
f0100516:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100519:	b8 00 02 10 f0       	mov    $0xf0100200,%eax
f010051e:	e8 99 fc ff ff       	call   f01001bc <cons_intr>
}
f0100523:	c9                   	leave  
f0100524:	c3                   	ret    

f0100525 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100525:	55                   	push   %ebp
f0100526:	89 e5                	mov    %esp,%ebp
f0100528:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010052b:	e8 c7 ff ff ff       	call   f01004f7 <serial_intr>
	kbd_intr();
f0100530:	e8 de ff ff ff       	call   f0100513 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100535:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f010053a:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100540:	74 26                	je     f0100568 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100542:	8d 50 01             	lea    0x1(%eax),%edx
f0100545:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f010054b:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100552:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100554:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010055a:	75 11                	jne    f010056d <cons_getc+0x48>
			cons.rpos = 0;
f010055c:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100563:	00 00 00 
f0100566:	eb 05                	jmp    f010056d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100568:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010056d:	c9                   	leave  
f010056e:	c3                   	ret    

f010056f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010056f:	55                   	push   %ebp
f0100570:	89 e5                	mov    %esp,%ebp
f0100572:	57                   	push   %edi
f0100573:	56                   	push   %esi
f0100574:	53                   	push   %ebx
f0100575:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100578:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010057f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100586:	5a a5 
	if (*cp != 0xA55A) {
f0100588:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010058f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100593:	74 11                	je     f01005a6 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100595:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f010059c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010059f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f01005a4:	eb 16                	jmp    f01005bc <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01005a6:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005ad:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f01005b4:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005b7:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005bc:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01005c2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005c7:	89 ca                	mov    %ecx,%edx
f01005c9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005ca:	8d 59 01             	lea    0x1(%ecx),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cd:	89 da                	mov    %ebx,%edx
f01005cf:	ec                   	in     (%dx),%al
f01005d0:	0f b6 f0             	movzbl %al,%esi
f01005d3:	c1 e6 08             	shl    $0x8,%esi
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005d6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005db:	89 ca                	mov    %ecx,%edx
f01005dd:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005de:	89 da                	mov    %ebx,%edx
f01005e0:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005e1:	89 3d 2c 25 11 f0    	mov    %edi,0xf011252c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005e7:	0f b6 d8             	movzbl %al,%ebx
f01005ea:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005ec:	66 89 35 28 25 11 f0 	mov    %si,0xf0112528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005f3:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005f8:	b8 00 00 00 00       	mov    $0x0,%eax
f01005fd:	89 f2                	mov    %esi,%edx
f01005ff:	ee                   	out    %al,(%dx)
f0100600:	b2 fb                	mov    $0xfb,%dl
f0100602:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100607:	ee                   	out    %al,(%dx)
f0100608:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f010060d:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100612:	89 da                	mov    %ebx,%edx
f0100614:	ee                   	out    %al,(%dx)
f0100615:	b2 f9                	mov    $0xf9,%dl
f0100617:	b8 00 00 00 00       	mov    $0x0,%eax
f010061c:	ee                   	out    %al,(%dx)
f010061d:	b2 fb                	mov    $0xfb,%dl
f010061f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100624:	ee                   	out    %al,(%dx)
f0100625:	b2 fc                	mov    $0xfc,%dl
f0100627:	b8 00 00 00 00       	mov    $0x0,%eax
f010062c:	ee                   	out    %al,(%dx)
f010062d:	b2 f9                	mov    $0xf9,%dl
f010062f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100634:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100635:	b2 fd                	mov    $0xfd,%dl
f0100637:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100638:	3c ff                	cmp    $0xff,%al
f010063a:	0f 95 c1             	setne  %cl
f010063d:	88 0d 34 25 11 f0    	mov    %cl,0xf0112534
f0100643:	89 f2                	mov    %esi,%edx
f0100645:	ec                   	in     (%dx),%al
f0100646:	89 da                	mov    %ebx,%edx
f0100648:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100649:	84 c9                	test   %cl,%cl
f010064b:	75 0c                	jne    f0100659 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f010064d:	c7 04 24 50 1a 10 f0 	movl   $0xf0101a50,(%esp)
f0100654:	e8 85 03 00 00       	call   f01009de <cprintf>
}
f0100659:	83 c4 1c             	add    $0x1c,%esp
f010065c:	5b                   	pop    %ebx
f010065d:	5e                   	pop    %esi
f010065e:	5f                   	pop    %edi
f010065f:	5d                   	pop    %ebp
f0100660:	c3                   	ret    

f0100661 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100661:	55                   	push   %ebp
f0100662:	89 e5                	mov    %esp,%ebp
f0100664:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100667:	8b 45 08             	mov    0x8(%ebp),%eax
f010066a:	e8 a8 fc ff ff       	call   f0100317 <cons_putc>
}
f010066f:	c9                   	leave  
f0100670:	c3                   	ret    

f0100671 <getchar>:

int
getchar(void)
{
f0100671:	55                   	push   %ebp
f0100672:	89 e5                	mov    %esp,%ebp
f0100674:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100677:	e8 a9 fe ff ff       	call   f0100525 <cons_getc>
f010067c:	85 c0                	test   %eax,%eax
f010067e:	74 f7                	je     f0100677 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100680:	c9                   	leave  
f0100681:	c3                   	ret    

f0100682 <iscons>:

int
iscons(int fdnum)
{
f0100682:	55                   	push   %ebp
f0100683:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100685:	b8 01 00 00 00       	mov    $0x1,%eax
f010068a:	5d                   	pop    %ebp
f010068b:	c3                   	ret    
f010068c:	66 90                	xchg   %ax,%ax
f010068e:	66 90                	xchg   %ax,%ax

f0100690 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100690:	55                   	push   %ebp
f0100691:	89 e5                	mov    %esp,%ebp
f0100693:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100696:	c7 44 24 08 a0 1c 10 	movl   $0xf0101ca0,0x8(%esp)
f010069d:	f0 
f010069e:	c7 44 24 04 be 1c 10 	movl   $0xf0101cbe,0x4(%esp)
f01006a5:	f0 
f01006a6:	c7 04 24 c3 1c 10 f0 	movl   $0xf0101cc3,(%esp)
f01006ad:	e8 2c 03 00 00       	call   f01009de <cprintf>
f01006b2:	c7 44 24 08 64 1d 10 	movl   $0xf0101d64,0x8(%esp)
f01006b9:	f0 
f01006ba:	c7 44 24 04 cc 1c 10 	movl   $0xf0101ccc,0x4(%esp)
f01006c1:	f0 
f01006c2:	c7 04 24 c3 1c 10 f0 	movl   $0xf0101cc3,(%esp)
f01006c9:	e8 10 03 00 00       	call   f01009de <cprintf>
f01006ce:	c7 44 24 08 d5 1c 10 	movl   $0xf0101cd5,0x8(%esp)
f01006d5:	f0 
f01006d6:	c7 44 24 04 f3 1c 10 	movl   $0xf0101cf3,0x4(%esp)
f01006dd:	f0 
f01006de:	c7 04 24 c3 1c 10 f0 	movl   $0xf0101cc3,(%esp)
f01006e5:	e8 f4 02 00 00       	call   f01009de <cprintf>
	return 0;
}
f01006ea:	b8 00 00 00 00       	mov    $0x0,%eax
f01006ef:	c9                   	leave  
f01006f0:	c3                   	ret    

f01006f1 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006f1:	55                   	push   %ebp
f01006f2:	89 e5                	mov    %esp,%ebp
f01006f4:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006f7:	c7 04 24 fd 1c 10 f0 	movl   $0xf0101cfd,(%esp)
f01006fe:	e8 db 02 00 00       	call   f01009de <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100703:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f010070a:	00 
f010070b:	c7 04 24 8c 1d 10 f0 	movl   $0xf0101d8c,(%esp)
f0100712:	e8 c7 02 00 00       	call   f01009de <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100717:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010071e:	00 
f010071f:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100726:	f0 
f0100727:	c7 04 24 b4 1d 10 f0 	movl   $0xf0101db4,(%esp)
f010072e:	e8 ab 02 00 00       	call   f01009de <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100733:	c7 44 24 08 b7 19 10 	movl   $0x1019b7,0x8(%esp)
f010073a:	00 
f010073b:	c7 44 24 04 b7 19 10 	movl   $0xf01019b7,0x4(%esp)
f0100742:	f0 
f0100743:	c7 04 24 d8 1d 10 f0 	movl   $0xf0101dd8,(%esp)
f010074a:	e8 8f 02 00 00       	call   f01009de <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010074f:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f0100756:	00 
f0100757:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f010075e:	f0 
f010075f:	c7 04 24 fc 1d 10 f0 	movl   $0xf0101dfc,(%esp)
f0100766:	e8 73 02 00 00       	call   f01009de <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010076b:	c7 44 24 08 44 29 11 	movl   $0x112944,0x8(%esp)
f0100772:	00 
f0100773:	c7 44 24 04 44 29 11 	movl   $0xf0112944,0x4(%esp)
f010077a:	f0 
f010077b:	c7 04 24 20 1e 10 f0 	movl   $0xf0101e20,(%esp)
f0100782:	e8 57 02 00 00       	call   f01009de <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100787:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f010078c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100791:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100796:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010079c:	85 c0                	test   %eax,%eax
f010079e:	0f 48 c2             	cmovs  %edx,%eax
f01007a1:	c1 f8 0a             	sar    $0xa,%eax
f01007a4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007a8:	c7 04 24 44 1e 10 f0 	movl   $0xf0101e44,(%esp)
f01007af:	e8 2a 02 00 00       	call   f01009de <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01007b4:	b8 00 00 00 00       	mov    $0x0,%eax
f01007b9:	c9                   	leave  
f01007ba:	c3                   	ret    

f01007bb <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01007bb:	55                   	push   %ebp
f01007bc:	89 e5                	mov    %esp,%ebp
f01007be:	56                   	push   %esi
f01007bf:	53                   	push   %ebx
f01007c0:	83 ec 40             	sub    $0x40,%esp
      uint32_t  *x;
      x= (uint32_t *) read_ebp();   
f01007c3:	89 eb                	mov    %ebp,%ebx
      struct Eipdebuginfo info;
      while(x)
     {

	 cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", x, x[1], x[2],x[3],x[4],x[5],x[6]);
         debuginfo_eip(x[1], &info);
f01007c5:	8d 75 e0             	lea    -0x20(%ebp),%esi
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
      uint32_t  *x;
      x= (uint32_t *) read_ebp();   
      struct Eipdebuginfo info;
      while(x)
f01007c8:	e9 84 00 00 00       	jmp    f0100851 <mon_backtrace+0x96>
     {

	 cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", x, x[1], x[2],x[3],x[4],x[5],x[6]);
f01007cd:	8b 43 18             	mov    0x18(%ebx),%eax
f01007d0:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f01007d4:	8b 43 14             	mov    0x14(%ebx),%eax
f01007d7:	89 44 24 18          	mov    %eax,0x18(%esp)
f01007db:	8b 43 10             	mov    0x10(%ebx),%eax
f01007de:	89 44 24 14          	mov    %eax,0x14(%esp)
f01007e2:	8b 43 0c             	mov    0xc(%ebx),%eax
f01007e5:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007e9:	8b 43 08             	mov    0x8(%ebx),%eax
f01007ec:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007f0:	8b 43 04             	mov    0x4(%ebx),%eax
f01007f3:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007f7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01007fb:	c7 04 24 70 1e 10 f0 	movl   $0xf0101e70,(%esp)
f0100802:	e8 d7 01 00 00       	call   f01009de <cprintf>
         debuginfo_eip(x[1], &info);
f0100807:	89 74 24 04          	mov    %esi,0x4(%esp)
f010080b:	8b 43 04             	mov    0x4(%ebx),%eax
f010080e:	89 04 24             	mov    %eax,(%esp)
f0100811:	e8 bf 02 00 00       	call   f0100ad5 <debuginfo_eip>
         cprintf("%s:%d:%.*s+%d%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,(x[1]- info.eip_fn_addr),info.eip_fn_narg);
f0100816:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100819:	89 44 24 18          	mov    %eax,0x18(%esp)
f010081d:	8b 43 04             	mov    0x4(%ebx),%eax
f0100820:	2b 45 f0             	sub    -0x10(%ebp),%eax
f0100823:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100827:	8b 45 e8             	mov    -0x18(%ebp),%eax
f010082a:	89 44 24 10          	mov    %eax,0x10(%esp)
f010082e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100831:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100835:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100838:	89 44 24 08          	mov    %eax,0x8(%esp)
f010083c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010083f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100843:	c7 04 24 16 1d 10 f0 	movl   $0xf0101d16,(%esp)
f010084a:	e8 8f 01 00 00       	call   f01009de <cprintf>
         
	 x=(uint32_t *)x[0];
f010084f:	8b 1b                	mov    (%ebx),%ebx
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
      uint32_t  *x;
      x= (uint32_t *) read_ebp();   
      struct Eipdebuginfo info;
      while(x)
f0100851:	85 db                	test   %ebx,%ebx
f0100853:	0f 85 74 ff ff ff    	jne    f01007cd <mon_backtrace+0x12>
	 x=(uint32_t *)x[0];

	}	      
     // Your code here.
	return 0;
}
f0100859:	b8 00 00 00 00       	mov    $0x0,%eax
f010085e:	83 c4 40             	add    $0x40,%esp
f0100861:	5b                   	pop    %ebx
f0100862:	5e                   	pop    %esi
f0100863:	5d                   	pop    %ebp
f0100864:	c3                   	ret    

f0100865 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100865:	55                   	push   %ebp
f0100866:	89 e5                	mov    %esp,%ebp
f0100868:	57                   	push   %edi
f0100869:	56                   	push   %esi
f010086a:	53                   	push   %ebx
f010086b:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010086e:	c7 04 24 a4 1e 10 f0 	movl   $0xf0101ea4,(%esp)
f0100875:	e8 64 01 00 00       	call   f01009de <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010087a:	c7 04 24 c8 1e 10 f0 	movl   $0xf0101ec8,(%esp)
f0100881:	e8 58 01 00 00       	call   f01009de <cprintf>


	while (1) {
		buf = readline("K> ");
f0100886:	c7 04 24 27 1d 10 f0 	movl   $0xf0101d27,(%esp)
f010088d:	e8 3e 0a 00 00       	call   f01012d0 <readline>
f0100892:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100894:	85 c0                	test   %eax,%eax
f0100896:	74 ee                	je     f0100886 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100898:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010089f:	be 00 00 00 00       	mov    $0x0,%esi
f01008a4:	eb 0a                	jmp    f01008b0 <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01008a6:	c6 03 00             	movb   $0x0,(%ebx)
f01008a9:	89 f7                	mov    %esi,%edi
f01008ab:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01008ae:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01008b0:	0f b6 03             	movzbl (%ebx),%eax
f01008b3:	84 c0                	test   %al,%al
f01008b5:	74 63                	je     f010091a <monitor+0xb5>
f01008b7:	0f be c0             	movsbl %al,%eax
f01008ba:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008be:	c7 04 24 2b 1d 10 f0 	movl   $0xf0101d2b,(%esp)
f01008c5:	e8 20 0c 00 00       	call   f01014ea <strchr>
f01008ca:	85 c0                	test   %eax,%eax
f01008cc:	75 d8                	jne    f01008a6 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f01008ce:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008d1:	74 47                	je     f010091a <monitor+0xb5>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008d3:	83 fe 0f             	cmp    $0xf,%esi
f01008d6:	75 16                	jne    f01008ee <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008d8:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01008df:	00 
f01008e0:	c7 04 24 30 1d 10 f0 	movl   $0xf0101d30,(%esp)
f01008e7:	e8 f2 00 00 00       	call   f01009de <cprintf>
f01008ec:	eb 98                	jmp    f0100886 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f01008ee:	8d 7e 01             	lea    0x1(%esi),%edi
f01008f1:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008f5:	eb 03                	jmp    f01008fa <monitor+0x95>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01008f7:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008fa:	0f b6 03             	movzbl (%ebx),%eax
f01008fd:	84 c0                	test   %al,%al
f01008ff:	74 ad                	je     f01008ae <monitor+0x49>
f0100901:	0f be c0             	movsbl %al,%eax
f0100904:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100908:	c7 04 24 2b 1d 10 f0 	movl   $0xf0101d2b,(%esp)
f010090f:	e8 d6 0b 00 00       	call   f01014ea <strchr>
f0100914:	85 c0                	test   %eax,%eax
f0100916:	74 df                	je     f01008f7 <monitor+0x92>
f0100918:	eb 94                	jmp    f01008ae <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f010091a:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100921:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100922:	85 f6                	test   %esi,%esi
f0100924:	0f 84 5c ff ff ff    	je     f0100886 <monitor+0x21>
f010092a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010092f:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100932:	8b 04 85 00 1f 10 f0 	mov    -0xfefe100(,%eax,4),%eax
f0100939:	89 44 24 04          	mov    %eax,0x4(%esp)
f010093d:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100940:	89 04 24             	mov    %eax,(%esp)
f0100943:	e8 44 0b 00 00       	call   f010148c <strcmp>
f0100948:	85 c0                	test   %eax,%eax
f010094a:	75 24                	jne    f0100970 <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f010094c:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010094f:	8b 55 08             	mov    0x8(%ebp),%edx
f0100952:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100956:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100959:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010095d:	89 34 24             	mov    %esi,(%esp)
f0100960:	ff 14 85 08 1f 10 f0 	call   *-0xfefe0f8(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100967:	85 c0                	test   %eax,%eax
f0100969:	78 25                	js     f0100990 <monitor+0x12b>
f010096b:	e9 16 ff ff ff       	jmp    f0100886 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100970:	83 c3 01             	add    $0x1,%ebx
f0100973:	83 fb 03             	cmp    $0x3,%ebx
f0100976:	75 b7                	jne    f010092f <monitor+0xca>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100978:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010097b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010097f:	c7 04 24 4d 1d 10 f0 	movl   $0xf0101d4d,(%esp)
f0100986:	e8 53 00 00 00       	call   f01009de <cprintf>
f010098b:	e9 f6 fe ff ff       	jmp    f0100886 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100990:	83 c4 5c             	add    $0x5c,%esp
f0100993:	5b                   	pop    %ebx
f0100994:	5e                   	pop    %esi
f0100995:	5f                   	pop    %edi
f0100996:	5d                   	pop    %ebp
f0100997:	c3                   	ret    

f0100998 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100998:	55                   	push   %ebp
f0100999:	89 e5                	mov    %esp,%ebp
f010099b:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f010099e:	8b 45 08             	mov    0x8(%ebp),%eax
f01009a1:	89 04 24             	mov    %eax,(%esp)
f01009a4:	e8 b8 fc ff ff       	call   f0100661 <cputchar>
	*cnt++;
}
f01009a9:	c9                   	leave  
f01009aa:	c3                   	ret    

f01009ab <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01009ab:	55                   	push   %ebp
f01009ac:	89 e5                	mov    %esp,%ebp
f01009ae:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01009b1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01009b8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01009bb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009bf:	8b 45 08             	mov    0x8(%ebp),%eax
f01009c2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009c6:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01009c9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009cd:	c7 04 24 98 09 10 f0 	movl   $0xf0100998,(%esp)
f01009d4:	e8 95 04 00 00       	call   f0100e6e <vprintfmt>
	return cnt;
}
f01009d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01009dc:	c9                   	leave  
f01009dd:	c3                   	ret    

f01009de <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009de:	55                   	push   %ebp
f01009df:	89 e5                	mov    %esp,%ebp
f01009e1:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01009e4:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01009e7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009eb:	8b 45 08             	mov    0x8(%ebp),%eax
f01009ee:	89 04 24             	mov    %eax,(%esp)
f01009f1:	e8 b5 ff ff ff       	call   f01009ab <vcprintf>
	va_end(ap);

	return cnt;
}
f01009f6:	c9                   	leave  
f01009f7:	c3                   	ret    

f01009f8 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01009f8:	55                   	push   %ebp
f01009f9:	89 e5                	mov    %esp,%ebp
f01009fb:	57                   	push   %edi
f01009fc:	56                   	push   %esi
f01009fd:	53                   	push   %ebx
f01009fe:	83 ec 10             	sub    $0x10,%esp
f0100a01:	89 c6                	mov    %eax,%esi
f0100a03:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100a06:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100a09:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a0c:	8b 1a                	mov    (%edx),%ebx
f0100a0e:	8b 01                	mov    (%ecx),%eax
f0100a10:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a13:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0100a1a:	eb 77                	jmp    f0100a93 <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0100a1c:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a1f:	01 d8                	add    %ebx,%eax
f0100a21:	b9 02 00 00 00       	mov    $0x2,%ecx
f0100a26:	99                   	cltd   
f0100a27:	f7 f9                	idiv   %ecx
f0100a29:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a2b:	eb 01                	jmp    f0100a2e <stab_binsearch+0x36>
			m--;
f0100a2d:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a2e:	39 d9                	cmp    %ebx,%ecx
f0100a30:	7c 1d                	jl     f0100a4f <stab_binsearch+0x57>
f0100a32:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a35:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a3a:	39 fa                	cmp    %edi,%edx
f0100a3c:	75 ef                	jne    f0100a2d <stab_binsearch+0x35>
f0100a3e:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a41:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a44:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0100a48:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100a4b:	73 18                	jae    f0100a65 <stab_binsearch+0x6d>
f0100a4d:	eb 05                	jmp    f0100a54 <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a4f:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0100a52:	eb 3f                	jmp    f0100a93 <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100a54:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a57:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0100a59:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a5c:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a63:	eb 2e                	jmp    f0100a93 <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a65:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a68:	73 15                	jae    f0100a7f <stab_binsearch+0x87>
			*region_right = m - 1;
f0100a6a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100a6d:	48                   	dec    %eax
f0100a6e:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a71:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100a74:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a76:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a7d:	eb 14                	jmp    f0100a93 <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a7f:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100a82:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0100a85:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0100a87:	ff 45 0c             	incl   0xc(%ebp)
f0100a8a:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a8c:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100a93:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a96:	7e 84                	jle    f0100a1c <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a98:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100a9c:	75 0d                	jne    f0100aab <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0100a9e:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100aa1:	8b 00                	mov    (%eax),%eax
f0100aa3:	48                   	dec    %eax
f0100aa4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100aa7:	89 07                	mov    %eax,(%edi)
f0100aa9:	eb 22                	jmp    f0100acd <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100aab:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100aae:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100ab0:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100ab3:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ab5:	eb 01                	jmp    f0100ab8 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100ab7:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ab8:	39 c1                	cmp    %eax,%ecx
f0100aba:	7d 0c                	jge    f0100ac8 <stab_binsearch+0xd0>
f0100abc:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0100abf:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100ac4:	39 fa                	cmp    %edi,%edx
f0100ac6:	75 ef                	jne    f0100ab7 <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100ac8:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0100acb:	89 07                	mov    %eax,(%edi)
	}
}
f0100acd:	83 c4 10             	add    $0x10,%esp
f0100ad0:	5b                   	pop    %ebx
f0100ad1:	5e                   	pop    %esi
f0100ad2:	5f                   	pop    %edi
f0100ad3:	5d                   	pop    %ebp
f0100ad4:	c3                   	ret    

f0100ad5 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100ad5:	55                   	push   %ebp
f0100ad6:	89 e5                	mov    %esp,%ebp
f0100ad8:	57                   	push   %edi
f0100ad9:	56                   	push   %esi
f0100ada:	53                   	push   %ebx
f0100adb:	83 ec 3c             	sub    $0x3c,%esp
f0100ade:	8b 75 08             	mov    0x8(%ebp),%esi
f0100ae1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100ae4:	c7 03 24 1f 10 f0    	movl   $0xf0101f24,(%ebx)
	info->eip_line = 0;
f0100aea:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100af1:	c7 43 08 24 1f 10 f0 	movl   $0xf0101f24,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100af8:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100aff:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100b02:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b09:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100b0f:	76 12                	jbe    f0100b23 <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b11:	b8 79 73 10 f0       	mov    $0xf0107379,%eax
f0100b16:	3d 69 5a 10 f0       	cmp    $0xf0105a69,%eax
f0100b1b:	0f 86 ba 01 00 00    	jbe    f0100cdb <debuginfo_eip+0x206>
f0100b21:	eb 1c                	jmp    f0100b3f <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100b23:	c7 44 24 08 2e 1f 10 	movl   $0xf0101f2e,0x8(%esp)
f0100b2a:	f0 
f0100b2b:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100b32:	00 
f0100b33:	c7 04 24 3b 1f 10 f0 	movl   $0xf0101f3b,(%esp)
f0100b3a:	e8 b9 f5 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b3f:	80 3d 78 73 10 f0 00 	cmpb   $0x0,0xf0107378
f0100b46:	0f 85 96 01 00 00    	jne    f0100ce2 <debuginfo_eip+0x20d>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b4c:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b53:	b8 68 5a 10 f0       	mov    $0xf0105a68,%eax
f0100b58:	2d 5c 21 10 f0       	sub    $0xf010215c,%eax
f0100b5d:	c1 f8 02             	sar    $0x2,%eax
f0100b60:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b66:	83 e8 01             	sub    $0x1,%eax
f0100b69:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b6c:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b70:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100b77:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b7a:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b7d:	b8 5c 21 10 f0       	mov    $0xf010215c,%eax
f0100b82:	e8 71 fe ff ff       	call   f01009f8 <stab_binsearch>
	if (lfile == 0)
f0100b87:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b8a:	85 c0                	test   %eax,%eax
f0100b8c:	0f 84 57 01 00 00    	je     f0100ce9 <debuginfo_eip+0x214>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b92:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b95:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b98:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b9b:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b9f:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100ba6:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100ba9:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100bac:	b8 5c 21 10 f0       	mov    $0xf010215c,%eax
f0100bb1:	e8 42 fe ff ff       	call   f01009f8 <stab_binsearch>

	if (lfun <= rfun) {
f0100bb6:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100bb9:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100bbc:	39 d0                	cmp    %edx,%eax
f0100bbe:	7f 3d                	jg     f0100bfd <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100bc0:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100bc3:	8d b9 5c 21 10 f0    	lea    -0xfefdea4(%ecx),%edi
f0100bc9:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100bcc:	8b 89 5c 21 10 f0    	mov    -0xfefdea4(%ecx),%ecx
f0100bd2:	bf 79 73 10 f0       	mov    $0xf0107379,%edi
f0100bd7:	81 ef 69 5a 10 f0    	sub    $0xf0105a69,%edi
f0100bdd:	39 f9                	cmp    %edi,%ecx
f0100bdf:	73 09                	jae    f0100bea <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100be1:	81 c1 69 5a 10 f0    	add    $0xf0105a69,%ecx
f0100be7:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100bea:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100bed:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100bf0:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100bf3:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100bf5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100bf8:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100bfb:	eb 0f                	jmp    f0100c0c <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100bfd:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100c00:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c03:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100c06:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c09:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c0c:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100c13:	00 
f0100c14:	8b 43 08             	mov    0x8(%ebx),%eax
f0100c17:	89 04 24             	mov    %eax,(%esp)
f0100c1a:	e8 ec 08 00 00       	call   f010150b <strfind>
f0100c1f:	2b 43 08             	sub    0x8(%ebx),%eax
f0100c22:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

          stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); 
f0100c25:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c29:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100c30:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100c33:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100c36:	b8 5c 21 10 f0       	mov    $0xf010215c,%eax
f0100c3b:	e8 b8 fd ff ff       	call   f01009f8 <stab_binsearch>
          info->eip_line = stabs[lline].n_desc;
f0100c40:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100c43:	6b c2 0c             	imul   $0xc,%edx,%eax
f0100c46:	05 5c 21 10 f0       	add    $0xf010215c,%eax
f0100c4b:	0f b7 48 06          	movzwl 0x6(%eax),%ecx
f0100c4f:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c52:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100c55:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100c58:	eb 06                	jmp    f0100c60 <debuginfo_eip+0x18b>
f0100c5a:	83 ea 01             	sub    $0x1,%edx
f0100c5d:	83 e8 0c             	sub    $0xc,%eax
f0100c60:	89 d6                	mov    %edx,%esi
f0100c62:	39 55 c4             	cmp    %edx,-0x3c(%ebp)
f0100c65:	7f 33                	jg     f0100c9a <debuginfo_eip+0x1c5>
	       && stabs[lline].n_type != N_SOL
f0100c67:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0100c6b:	80 f9 84             	cmp    $0x84,%cl
f0100c6e:	74 0b                	je     f0100c7b <debuginfo_eip+0x1a6>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c70:	80 f9 64             	cmp    $0x64,%cl
f0100c73:	75 e5                	jne    f0100c5a <debuginfo_eip+0x185>
f0100c75:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100c79:	74 df                	je     f0100c5a <debuginfo_eip+0x185>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c7b:	6b f6 0c             	imul   $0xc,%esi,%esi
f0100c7e:	8b 86 5c 21 10 f0    	mov    -0xfefdea4(%esi),%eax
f0100c84:	ba 79 73 10 f0       	mov    $0xf0107379,%edx
f0100c89:	81 ea 69 5a 10 f0    	sub    $0xf0105a69,%edx
f0100c8f:	39 d0                	cmp    %edx,%eax
f0100c91:	73 07                	jae    f0100c9a <debuginfo_eip+0x1c5>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c93:	05 69 5a 10 f0       	add    $0xf0105a69,%eax
f0100c98:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c9a:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c9d:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100ca0:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100ca5:	39 ca                	cmp    %ecx,%edx
f0100ca7:	7d 4c                	jge    f0100cf5 <debuginfo_eip+0x220>
		for (lline = lfun + 1;
f0100ca9:	8d 42 01             	lea    0x1(%edx),%eax
f0100cac:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100caf:	89 c2                	mov    %eax,%edx
f0100cb1:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100cb4:	05 5c 21 10 f0       	add    $0xf010215c,%eax
f0100cb9:	89 ce                	mov    %ecx,%esi
f0100cbb:	eb 04                	jmp    f0100cc1 <debuginfo_eip+0x1ec>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100cbd:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100cc1:	39 d6                	cmp    %edx,%esi
f0100cc3:	7e 2b                	jle    f0100cf0 <debuginfo_eip+0x21b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100cc5:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0100cc9:	83 c2 01             	add    $0x1,%edx
f0100ccc:	83 c0 0c             	add    $0xc,%eax
f0100ccf:	80 f9 a0             	cmp    $0xa0,%cl
f0100cd2:	74 e9                	je     f0100cbd <debuginfo_eip+0x1e8>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100cd4:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cd9:	eb 1a                	jmp    f0100cf5 <debuginfo_eip+0x220>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100cdb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ce0:	eb 13                	jmp    f0100cf5 <debuginfo_eip+0x220>
f0100ce2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ce7:	eb 0c                	jmp    f0100cf5 <debuginfo_eip+0x220>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100ce9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cee:	eb 05                	jmp    f0100cf5 <debuginfo_eip+0x220>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100cf0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100cf5:	83 c4 3c             	add    $0x3c,%esp
f0100cf8:	5b                   	pop    %ebx
f0100cf9:	5e                   	pop    %esi
f0100cfa:	5f                   	pop    %edi
f0100cfb:	5d                   	pop    %ebp
f0100cfc:	c3                   	ret    
f0100cfd:	66 90                	xchg   %ax,%ax
f0100cff:	90                   	nop

f0100d00 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d00:	55                   	push   %ebp
f0100d01:	89 e5                	mov    %esp,%ebp
f0100d03:	57                   	push   %edi
f0100d04:	56                   	push   %esi
f0100d05:	53                   	push   %ebx
f0100d06:	83 ec 3c             	sub    $0x3c,%esp
f0100d09:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100d0c:	89 d7                	mov    %edx,%edi
f0100d0e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d11:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d14:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d17:	89 c3                	mov    %eax,%ebx
f0100d19:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100d1c:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d1f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100d22:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d27:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100d2a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100d2d:	39 d9                	cmp    %ebx,%ecx
f0100d2f:	72 05                	jb     f0100d36 <printnum+0x36>
f0100d31:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100d34:	77 69                	ja     f0100d9f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100d36:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0100d39:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0100d3d:	83 ee 01             	sub    $0x1,%esi
f0100d40:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100d44:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d48:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100d4c:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100d50:	89 c3                	mov    %eax,%ebx
f0100d52:	89 d6                	mov    %edx,%esi
f0100d54:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100d57:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100d5a:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100d5e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100d62:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d65:	89 04 24             	mov    %eax,(%esp)
f0100d68:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100d6b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d6f:	e8 bc 09 00 00       	call   f0101730 <__udivdi3>
f0100d74:	89 d9                	mov    %ebx,%ecx
f0100d76:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100d7a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100d7e:	89 04 24             	mov    %eax,(%esp)
f0100d81:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100d85:	89 fa                	mov    %edi,%edx
f0100d87:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d8a:	e8 71 ff ff ff       	call   f0100d00 <printnum>
f0100d8f:	eb 1b                	jmp    f0100dac <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d91:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d95:	8b 45 18             	mov    0x18(%ebp),%eax
f0100d98:	89 04 24             	mov    %eax,(%esp)
f0100d9b:	ff d3                	call   *%ebx
f0100d9d:	eb 03                	jmp    f0100da2 <printnum+0xa2>
f0100d9f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100da2:	83 ee 01             	sub    $0x1,%esi
f0100da5:	85 f6                	test   %esi,%esi
f0100da7:	7f e8                	jg     f0100d91 <printnum+0x91>
f0100da9:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100dac:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100db0:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100db4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100db7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100dba:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100dbe:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100dc2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100dc5:	89 04 24             	mov    %eax,(%esp)
f0100dc8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100dcb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100dcf:	e8 8c 0a 00 00       	call   f0101860 <__umoddi3>
f0100dd4:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100dd8:	0f be 80 49 1f 10 f0 	movsbl -0xfefe0b7(%eax),%eax
f0100ddf:	89 04 24             	mov    %eax,(%esp)
f0100de2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100de5:	ff d0                	call   *%eax
}
f0100de7:	83 c4 3c             	add    $0x3c,%esp
f0100dea:	5b                   	pop    %ebx
f0100deb:	5e                   	pop    %esi
f0100dec:	5f                   	pop    %edi
f0100ded:	5d                   	pop    %ebp
f0100dee:	c3                   	ret    

f0100def <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100def:	55                   	push   %ebp
f0100df0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100df2:	83 fa 01             	cmp    $0x1,%edx
f0100df5:	7e 0e                	jle    f0100e05 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100df7:	8b 10                	mov    (%eax),%edx
f0100df9:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100dfc:	89 08                	mov    %ecx,(%eax)
f0100dfe:	8b 02                	mov    (%edx),%eax
f0100e00:	8b 52 04             	mov    0x4(%edx),%edx
f0100e03:	eb 22                	jmp    f0100e27 <getuint+0x38>
	else if (lflag)
f0100e05:	85 d2                	test   %edx,%edx
f0100e07:	74 10                	je     f0100e19 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100e09:	8b 10                	mov    (%eax),%edx
f0100e0b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e0e:	89 08                	mov    %ecx,(%eax)
f0100e10:	8b 02                	mov    (%edx),%eax
f0100e12:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e17:	eb 0e                	jmp    f0100e27 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100e19:	8b 10                	mov    (%eax),%edx
f0100e1b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e1e:	89 08                	mov    %ecx,(%eax)
f0100e20:	8b 02                	mov    (%edx),%eax
f0100e22:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100e27:	5d                   	pop    %ebp
f0100e28:	c3                   	ret    

f0100e29 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100e29:	55                   	push   %ebp
f0100e2a:	89 e5                	mov    %esp,%ebp
f0100e2c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100e2f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100e33:	8b 10                	mov    (%eax),%edx
f0100e35:	3b 50 04             	cmp    0x4(%eax),%edx
f0100e38:	73 0a                	jae    f0100e44 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100e3a:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100e3d:	89 08                	mov    %ecx,(%eax)
f0100e3f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e42:	88 02                	mov    %al,(%edx)
}
f0100e44:	5d                   	pop    %ebp
f0100e45:	c3                   	ret    

f0100e46 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100e46:	55                   	push   %ebp
f0100e47:	89 e5                	mov    %esp,%ebp
f0100e49:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100e4c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100e4f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e53:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e56:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e5a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e5d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e61:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e64:	89 04 24             	mov    %eax,(%esp)
f0100e67:	e8 02 00 00 00       	call   f0100e6e <vprintfmt>
	va_end(ap);
}
f0100e6c:	c9                   	leave  
f0100e6d:	c3                   	ret    

f0100e6e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100e6e:	55                   	push   %ebp
f0100e6f:	89 e5                	mov    %esp,%ebp
f0100e71:	57                   	push   %edi
f0100e72:	56                   	push   %esi
f0100e73:	53                   	push   %ebx
f0100e74:	83 ec 3c             	sub    $0x3c,%esp
f0100e77:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100e7a:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100e7d:	eb 14                	jmp    f0100e93 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100e7f:	85 c0                	test   %eax,%eax
f0100e81:	0f 84 b3 03 00 00    	je     f010123a <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f0100e87:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e8b:	89 04 24             	mov    %eax,(%esp)
f0100e8e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100e91:	89 f3                	mov    %esi,%ebx
f0100e93:	8d 73 01             	lea    0x1(%ebx),%esi
f0100e96:	0f b6 03             	movzbl (%ebx),%eax
f0100e99:	83 f8 25             	cmp    $0x25,%eax
f0100e9c:	75 e1                	jne    f0100e7f <vprintfmt+0x11>
f0100e9e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0100ea2:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0100ea9:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0100eb0:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0100eb7:	ba 00 00 00 00       	mov    $0x0,%edx
f0100ebc:	eb 1d                	jmp    f0100edb <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ebe:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100ec0:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0100ec4:	eb 15                	jmp    f0100edb <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ec6:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100ec8:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0100ecc:	eb 0d                	jmp    f0100edb <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100ece:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100ed1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100ed4:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100edb:	8d 5e 01             	lea    0x1(%esi),%ebx
f0100ede:	0f b6 0e             	movzbl (%esi),%ecx
f0100ee1:	0f b6 c1             	movzbl %cl,%eax
f0100ee4:	83 e9 23             	sub    $0x23,%ecx
f0100ee7:	80 f9 55             	cmp    $0x55,%cl
f0100eea:	0f 87 2a 03 00 00    	ja     f010121a <vprintfmt+0x3ac>
f0100ef0:	0f b6 c9             	movzbl %cl,%ecx
f0100ef3:	ff 24 8d d8 1f 10 f0 	jmp    *-0xfefe028(,%ecx,4)
f0100efa:	89 de                	mov    %ebx,%esi
f0100efc:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100f01:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0100f04:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0100f08:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100f0b:	8d 58 d0             	lea    -0x30(%eax),%ebx
f0100f0e:	83 fb 09             	cmp    $0x9,%ebx
f0100f11:	77 36                	ja     f0100f49 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100f13:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100f16:	eb e9                	jmp    f0100f01 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100f18:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f1b:	8d 48 04             	lea    0x4(%eax),%ecx
f0100f1e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100f21:	8b 00                	mov    (%eax),%eax
f0100f23:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f26:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100f28:	eb 22                	jmp    f0100f4c <vprintfmt+0xde>
f0100f2a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100f2d:	85 c9                	test   %ecx,%ecx
f0100f2f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f34:	0f 49 c1             	cmovns %ecx,%eax
f0100f37:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f3a:	89 de                	mov    %ebx,%esi
f0100f3c:	eb 9d                	jmp    f0100edb <vprintfmt+0x6d>
f0100f3e:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100f40:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0100f47:	eb 92                	jmp    f0100edb <vprintfmt+0x6d>
f0100f49:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f0100f4c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100f50:	79 89                	jns    f0100edb <vprintfmt+0x6d>
f0100f52:	e9 77 ff ff ff       	jmp    f0100ece <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100f57:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f5a:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100f5c:	e9 7a ff ff ff       	jmp    f0100edb <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100f61:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f64:	8d 50 04             	lea    0x4(%eax),%edx
f0100f67:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f6a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100f6e:	8b 00                	mov    (%eax),%eax
f0100f70:	89 04 24             	mov    %eax,(%esp)
f0100f73:	ff 55 08             	call   *0x8(%ebp)
			break;
f0100f76:	e9 18 ff ff ff       	jmp    f0100e93 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100f7b:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f7e:	8d 50 04             	lea    0x4(%eax),%edx
f0100f81:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f84:	8b 00                	mov    (%eax),%eax
f0100f86:	99                   	cltd   
f0100f87:	31 d0                	xor    %edx,%eax
f0100f89:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f8b:	83 f8 06             	cmp    $0x6,%eax
f0100f8e:	7f 0b                	jg     f0100f9b <vprintfmt+0x12d>
f0100f90:	8b 14 85 30 21 10 f0 	mov    -0xfefded0(,%eax,4),%edx
f0100f97:	85 d2                	test   %edx,%edx
f0100f99:	75 20                	jne    f0100fbb <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f0100f9b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f9f:	c7 44 24 08 61 1f 10 	movl   $0xf0101f61,0x8(%esp)
f0100fa6:	f0 
f0100fa7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100fab:	8b 45 08             	mov    0x8(%ebp),%eax
f0100fae:	89 04 24             	mov    %eax,(%esp)
f0100fb1:	e8 90 fe ff ff       	call   f0100e46 <printfmt>
f0100fb6:	e9 d8 fe ff ff       	jmp    f0100e93 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f0100fbb:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100fbf:	c7 44 24 08 6a 1f 10 	movl   $0xf0101f6a,0x8(%esp)
f0100fc6:	f0 
f0100fc7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100fcb:	8b 45 08             	mov    0x8(%ebp),%eax
f0100fce:	89 04 24             	mov    %eax,(%esp)
f0100fd1:	e8 70 fe ff ff       	call   f0100e46 <printfmt>
f0100fd6:	e9 b8 fe ff ff       	jmp    f0100e93 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fdb:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100fde:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100fe1:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100fe4:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fe7:	8d 50 04             	lea    0x4(%eax),%edx
f0100fea:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fed:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f0100fef:	85 f6                	test   %esi,%esi
f0100ff1:	b8 5a 1f 10 f0       	mov    $0xf0101f5a,%eax
f0100ff6:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0100ff9:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f0100ffd:	0f 84 97 00 00 00    	je     f010109a <vprintfmt+0x22c>
f0101003:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0101007:	0f 8e 9b 00 00 00    	jle    f01010a8 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f010100d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101011:	89 34 24             	mov    %esi,(%esp)
f0101014:	e8 9f 03 00 00       	call   f01013b8 <strnlen>
f0101019:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010101c:	29 c2                	sub    %eax,%edx
f010101e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0101021:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0101025:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0101028:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010102b:	8b 75 08             	mov    0x8(%ebp),%esi
f010102e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101031:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101033:	eb 0f                	jmp    f0101044 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0101035:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101039:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010103c:	89 04 24             	mov    %eax,(%esp)
f010103f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101041:	83 eb 01             	sub    $0x1,%ebx
f0101044:	85 db                	test   %ebx,%ebx
f0101046:	7f ed                	jg     f0101035 <vprintfmt+0x1c7>
f0101048:	8b 75 d8             	mov    -0x28(%ebp),%esi
f010104b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010104e:	85 d2                	test   %edx,%edx
f0101050:	b8 00 00 00 00       	mov    $0x0,%eax
f0101055:	0f 49 c2             	cmovns %edx,%eax
f0101058:	29 c2                	sub    %eax,%edx
f010105a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010105d:	89 d7                	mov    %edx,%edi
f010105f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101062:	eb 50                	jmp    f01010b4 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0101064:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101068:	74 1e                	je     f0101088 <vprintfmt+0x21a>
f010106a:	0f be d2             	movsbl %dl,%edx
f010106d:	83 ea 20             	sub    $0x20,%edx
f0101070:	83 fa 5e             	cmp    $0x5e,%edx
f0101073:	76 13                	jbe    f0101088 <vprintfmt+0x21a>
					putch('?', putdat);
f0101075:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101078:	89 44 24 04          	mov    %eax,0x4(%esp)
f010107c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0101083:	ff 55 08             	call   *0x8(%ebp)
f0101086:	eb 0d                	jmp    f0101095 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f0101088:	8b 55 0c             	mov    0xc(%ebp),%edx
f010108b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010108f:	89 04 24             	mov    %eax,(%esp)
f0101092:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101095:	83 ef 01             	sub    $0x1,%edi
f0101098:	eb 1a                	jmp    f01010b4 <vprintfmt+0x246>
f010109a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010109d:	8b 7d dc             	mov    -0x24(%ebp),%edi
f01010a0:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01010a3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01010a6:	eb 0c                	jmp    f01010b4 <vprintfmt+0x246>
f01010a8:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01010ab:	8b 7d dc             	mov    -0x24(%ebp),%edi
f01010ae:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01010b1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01010b4:	83 c6 01             	add    $0x1,%esi
f01010b7:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f01010bb:	0f be c2             	movsbl %dl,%eax
f01010be:	85 c0                	test   %eax,%eax
f01010c0:	74 27                	je     f01010e9 <vprintfmt+0x27b>
f01010c2:	85 db                	test   %ebx,%ebx
f01010c4:	78 9e                	js     f0101064 <vprintfmt+0x1f6>
f01010c6:	83 eb 01             	sub    $0x1,%ebx
f01010c9:	79 99                	jns    f0101064 <vprintfmt+0x1f6>
f01010cb:	89 f8                	mov    %edi,%eax
f01010cd:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01010d0:	8b 75 08             	mov    0x8(%ebp),%esi
f01010d3:	89 c3                	mov    %eax,%ebx
f01010d5:	eb 1a                	jmp    f01010f1 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01010d7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01010db:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01010e2:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01010e4:	83 eb 01             	sub    $0x1,%ebx
f01010e7:	eb 08                	jmp    f01010f1 <vprintfmt+0x283>
f01010e9:	89 fb                	mov    %edi,%ebx
f01010eb:	8b 75 08             	mov    0x8(%ebp),%esi
f01010ee:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01010f1:	85 db                	test   %ebx,%ebx
f01010f3:	7f e2                	jg     f01010d7 <vprintfmt+0x269>
f01010f5:	89 75 08             	mov    %esi,0x8(%ebp)
f01010f8:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01010fb:	e9 93 fd ff ff       	jmp    f0100e93 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101100:	83 fa 01             	cmp    $0x1,%edx
f0101103:	7e 16                	jle    f010111b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f0101105:	8b 45 14             	mov    0x14(%ebp),%eax
f0101108:	8d 50 08             	lea    0x8(%eax),%edx
f010110b:	89 55 14             	mov    %edx,0x14(%ebp)
f010110e:	8b 50 04             	mov    0x4(%eax),%edx
f0101111:	8b 00                	mov    (%eax),%eax
f0101113:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101116:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101119:	eb 32                	jmp    f010114d <vprintfmt+0x2df>
	else if (lflag)
f010111b:	85 d2                	test   %edx,%edx
f010111d:	74 18                	je     f0101137 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f010111f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101122:	8d 50 04             	lea    0x4(%eax),%edx
f0101125:	89 55 14             	mov    %edx,0x14(%ebp)
f0101128:	8b 30                	mov    (%eax),%esi
f010112a:	89 75 e0             	mov    %esi,-0x20(%ebp)
f010112d:	89 f0                	mov    %esi,%eax
f010112f:	c1 f8 1f             	sar    $0x1f,%eax
f0101132:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101135:	eb 16                	jmp    f010114d <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f0101137:	8b 45 14             	mov    0x14(%ebp),%eax
f010113a:	8d 50 04             	lea    0x4(%eax),%edx
f010113d:	89 55 14             	mov    %edx,0x14(%ebp)
f0101140:	8b 30                	mov    (%eax),%esi
f0101142:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0101145:	89 f0                	mov    %esi,%eax
f0101147:	c1 f8 1f             	sar    $0x1f,%eax
f010114a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010114d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101150:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101153:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101158:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010115c:	0f 89 80 00 00 00    	jns    f01011e2 <vprintfmt+0x374>
				putch('-', putdat);
f0101162:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101166:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010116d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0101170:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101173:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101176:	f7 d8                	neg    %eax
f0101178:	83 d2 00             	adc    $0x0,%edx
f010117b:	f7 da                	neg    %edx
			}
			base = 10;
f010117d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101182:	eb 5e                	jmp    f01011e2 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101184:	8d 45 14             	lea    0x14(%ebp),%eax
f0101187:	e8 63 fc ff ff       	call   f0100def <getuint>
			base = 10;
f010118c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0101191:	eb 4f                	jmp    f01011e2 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0101193:	8d 45 14             	lea    0x14(%ebp),%eax
f0101196:	e8 54 fc ff ff       	call   f0100def <getuint>
			base = 8;
f010119b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01011a0:	eb 40                	jmp    f01011e2 <vprintfmt+0x374>

		// pointer
		case 'p':
			putch('0', putdat);
f01011a2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011a6:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01011ad:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01011b0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011b4:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01011bb:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01011be:	8b 45 14             	mov    0x14(%ebp),%eax
f01011c1:	8d 50 04             	lea    0x4(%eax),%edx
f01011c4:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01011c7:	8b 00                	mov    (%eax),%eax
f01011c9:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01011ce:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01011d3:	eb 0d                	jmp    f01011e2 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01011d5:	8d 45 14             	lea    0x14(%ebp),%eax
f01011d8:	e8 12 fc ff ff       	call   f0100def <getuint>
			base = 16;
f01011dd:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01011e2:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f01011e6:	89 74 24 10          	mov    %esi,0x10(%esp)
f01011ea:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01011ed:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01011f1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01011f5:	89 04 24             	mov    %eax,(%esp)
f01011f8:	89 54 24 04          	mov    %edx,0x4(%esp)
f01011fc:	89 fa                	mov    %edi,%edx
f01011fe:	8b 45 08             	mov    0x8(%ebp),%eax
f0101201:	e8 fa fa ff ff       	call   f0100d00 <printnum>
			break;
f0101206:	e9 88 fc ff ff       	jmp    f0100e93 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010120b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010120f:	89 04 24             	mov    %eax,(%esp)
f0101212:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101215:	e9 79 fc ff ff       	jmp    f0100e93 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010121a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010121e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101225:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101228:	89 f3                	mov    %esi,%ebx
f010122a:	eb 03                	jmp    f010122f <vprintfmt+0x3c1>
f010122c:	83 eb 01             	sub    $0x1,%ebx
f010122f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0101233:	75 f7                	jne    f010122c <vprintfmt+0x3be>
f0101235:	e9 59 fc ff ff       	jmp    f0100e93 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f010123a:	83 c4 3c             	add    $0x3c,%esp
f010123d:	5b                   	pop    %ebx
f010123e:	5e                   	pop    %esi
f010123f:	5f                   	pop    %edi
f0101240:	5d                   	pop    %ebp
f0101241:	c3                   	ret    

f0101242 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101242:	55                   	push   %ebp
f0101243:	89 e5                	mov    %esp,%ebp
f0101245:	83 ec 28             	sub    $0x28,%esp
f0101248:	8b 45 08             	mov    0x8(%ebp),%eax
f010124b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010124e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101251:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101255:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101258:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010125f:	85 c0                	test   %eax,%eax
f0101261:	74 30                	je     f0101293 <vsnprintf+0x51>
f0101263:	85 d2                	test   %edx,%edx
f0101265:	7e 2c                	jle    f0101293 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101267:	8b 45 14             	mov    0x14(%ebp),%eax
f010126a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010126e:	8b 45 10             	mov    0x10(%ebp),%eax
f0101271:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101275:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101278:	89 44 24 04          	mov    %eax,0x4(%esp)
f010127c:	c7 04 24 29 0e 10 f0 	movl   $0xf0100e29,(%esp)
f0101283:	e8 e6 fb ff ff       	call   f0100e6e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101288:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010128b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010128e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101291:	eb 05                	jmp    f0101298 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101293:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101298:	c9                   	leave  
f0101299:	c3                   	ret    

f010129a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010129a:	55                   	push   %ebp
f010129b:	89 e5                	mov    %esp,%ebp
f010129d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01012a0:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01012a3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012a7:	8b 45 10             	mov    0x10(%ebp),%eax
f01012aa:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012ae:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012b1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012b5:	8b 45 08             	mov    0x8(%ebp),%eax
f01012b8:	89 04 24             	mov    %eax,(%esp)
f01012bb:	e8 82 ff ff ff       	call   f0101242 <vsnprintf>
	va_end(ap);

	return rc;
}
f01012c0:	c9                   	leave  
f01012c1:	c3                   	ret    
f01012c2:	66 90                	xchg   %ax,%ax
f01012c4:	66 90                	xchg   %ax,%ax
f01012c6:	66 90                	xchg   %ax,%ax
f01012c8:	66 90                	xchg   %ax,%ax
f01012ca:	66 90                	xchg   %ax,%ax
f01012cc:	66 90                	xchg   %ax,%ax
f01012ce:	66 90                	xchg   %ax,%ax

f01012d0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01012d0:	55                   	push   %ebp
f01012d1:	89 e5                	mov    %esp,%ebp
f01012d3:	57                   	push   %edi
f01012d4:	56                   	push   %esi
f01012d5:	53                   	push   %ebx
f01012d6:	83 ec 1c             	sub    $0x1c,%esp
f01012d9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01012dc:	85 c0                	test   %eax,%eax
f01012de:	74 10                	je     f01012f0 <readline+0x20>
		cprintf("%s", prompt);
f01012e0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012e4:	c7 04 24 6a 1f 10 f0 	movl   $0xf0101f6a,(%esp)
f01012eb:	e8 ee f6 ff ff       	call   f01009de <cprintf>

	i = 0;
	echoing = iscons(0);
f01012f0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01012f7:	e8 86 f3 ff ff       	call   f0100682 <iscons>
f01012fc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01012fe:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101303:	e8 69 f3 ff ff       	call   f0100671 <getchar>
f0101308:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010130a:	85 c0                	test   %eax,%eax
f010130c:	79 17                	jns    f0101325 <readline+0x55>
			cprintf("read error: %e\n", c);
f010130e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101312:	c7 04 24 4c 21 10 f0 	movl   $0xf010214c,(%esp)
f0101319:	e8 c0 f6 ff ff       	call   f01009de <cprintf>
			return NULL;
f010131e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101323:	eb 6d                	jmp    f0101392 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101325:	83 f8 7f             	cmp    $0x7f,%eax
f0101328:	74 05                	je     f010132f <readline+0x5f>
f010132a:	83 f8 08             	cmp    $0x8,%eax
f010132d:	75 19                	jne    f0101348 <readline+0x78>
f010132f:	85 f6                	test   %esi,%esi
f0101331:	7e 15                	jle    f0101348 <readline+0x78>
			if (echoing)
f0101333:	85 ff                	test   %edi,%edi
f0101335:	74 0c                	je     f0101343 <readline+0x73>
				cputchar('\b');
f0101337:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010133e:	e8 1e f3 ff ff       	call   f0100661 <cputchar>
			i--;
f0101343:	83 ee 01             	sub    $0x1,%esi
f0101346:	eb bb                	jmp    f0101303 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101348:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010134e:	7f 1c                	jg     f010136c <readline+0x9c>
f0101350:	83 fb 1f             	cmp    $0x1f,%ebx
f0101353:	7e 17                	jle    f010136c <readline+0x9c>
			if (echoing)
f0101355:	85 ff                	test   %edi,%edi
f0101357:	74 08                	je     f0101361 <readline+0x91>
				cputchar(c);
f0101359:	89 1c 24             	mov    %ebx,(%esp)
f010135c:	e8 00 f3 ff ff       	call   f0100661 <cputchar>
			buf[i++] = c;
f0101361:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f0101367:	8d 76 01             	lea    0x1(%esi),%esi
f010136a:	eb 97                	jmp    f0101303 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010136c:	83 fb 0d             	cmp    $0xd,%ebx
f010136f:	74 05                	je     f0101376 <readline+0xa6>
f0101371:	83 fb 0a             	cmp    $0xa,%ebx
f0101374:	75 8d                	jne    f0101303 <readline+0x33>
			if (echoing)
f0101376:	85 ff                	test   %edi,%edi
f0101378:	74 0c                	je     f0101386 <readline+0xb6>
				cputchar('\n');
f010137a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101381:	e8 db f2 ff ff       	call   f0100661 <cputchar>
			buf[i] = 0;
f0101386:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f010138d:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f0101392:	83 c4 1c             	add    $0x1c,%esp
f0101395:	5b                   	pop    %ebx
f0101396:	5e                   	pop    %esi
f0101397:	5f                   	pop    %edi
f0101398:	5d                   	pop    %ebp
f0101399:	c3                   	ret    
f010139a:	66 90                	xchg   %ax,%ax
f010139c:	66 90                	xchg   %ax,%ax
f010139e:	66 90                	xchg   %ax,%ax

f01013a0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01013a0:	55                   	push   %ebp
f01013a1:	89 e5                	mov    %esp,%ebp
f01013a3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01013a6:	b8 00 00 00 00       	mov    $0x0,%eax
f01013ab:	eb 03                	jmp    f01013b0 <strlen+0x10>
		n++;
f01013ad:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01013b0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01013b4:	75 f7                	jne    f01013ad <strlen+0xd>
		n++;
	return n;
}
f01013b6:	5d                   	pop    %ebp
f01013b7:	c3                   	ret    

f01013b8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01013b8:	55                   	push   %ebp
f01013b9:	89 e5                	mov    %esp,%ebp
f01013bb:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01013be:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013c1:	b8 00 00 00 00       	mov    $0x0,%eax
f01013c6:	eb 03                	jmp    f01013cb <strnlen+0x13>
		n++;
f01013c8:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013cb:	39 d0                	cmp    %edx,%eax
f01013cd:	74 06                	je     f01013d5 <strnlen+0x1d>
f01013cf:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01013d3:	75 f3                	jne    f01013c8 <strnlen+0x10>
		n++;
	return n;
}
f01013d5:	5d                   	pop    %ebp
f01013d6:	c3                   	ret    

f01013d7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01013d7:	55                   	push   %ebp
f01013d8:	89 e5                	mov    %esp,%ebp
f01013da:	53                   	push   %ebx
f01013db:	8b 45 08             	mov    0x8(%ebp),%eax
f01013de:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01013e1:	89 c2                	mov    %eax,%edx
f01013e3:	83 c2 01             	add    $0x1,%edx
f01013e6:	83 c1 01             	add    $0x1,%ecx
f01013e9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01013ed:	88 5a ff             	mov    %bl,-0x1(%edx)
f01013f0:	84 db                	test   %bl,%bl
f01013f2:	75 ef                	jne    f01013e3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01013f4:	5b                   	pop    %ebx
f01013f5:	5d                   	pop    %ebp
f01013f6:	c3                   	ret    

f01013f7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01013f7:	55                   	push   %ebp
f01013f8:	89 e5                	mov    %esp,%ebp
f01013fa:	53                   	push   %ebx
f01013fb:	83 ec 08             	sub    $0x8,%esp
f01013fe:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101401:	89 1c 24             	mov    %ebx,(%esp)
f0101404:	e8 97 ff ff ff       	call   f01013a0 <strlen>
	strcpy(dst + len, src);
f0101409:	8b 55 0c             	mov    0xc(%ebp),%edx
f010140c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101410:	01 d8                	add    %ebx,%eax
f0101412:	89 04 24             	mov    %eax,(%esp)
f0101415:	e8 bd ff ff ff       	call   f01013d7 <strcpy>
	return dst;
}
f010141a:	89 d8                	mov    %ebx,%eax
f010141c:	83 c4 08             	add    $0x8,%esp
f010141f:	5b                   	pop    %ebx
f0101420:	5d                   	pop    %ebp
f0101421:	c3                   	ret    

f0101422 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101422:	55                   	push   %ebp
f0101423:	89 e5                	mov    %esp,%ebp
f0101425:	56                   	push   %esi
f0101426:	53                   	push   %ebx
f0101427:	8b 75 08             	mov    0x8(%ebp),%esi
f010142a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010142d:	89 f3                	mov    %esi,%ebx
f010142f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101432:	89 f2                	mov    %esi,%edx
f0101434:	eb 0f                	jmp    f0101445 <strncpy+0x23>
		*dst++ = *src;
f0101436:	83 c2 01             	add    $0x1,%edx
f0101439:	0f b6 01             	movzbl (%ecx),%eax
f010143c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010143f:	80 39 01             	cmpb   $0x1,(%ecx)
f0101442:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101445:	39 da                	cmp    %ebx,%edx
f0101447:	75 ed                	jne    f0101436 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101449:	89 f0                	mov    %esi,%eax
f010144b:	5b                   	pop    %ebx
f010144c:	5e                   	pop    %esi
f010144d:	5d                   	pop    %ebp
f010144e:	c3                   	ret    

f010144f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010144f:	55                   	push   %ebp
f0101450:	89 e5                	mov    %esp,%ebp
f0101452:	56                   	push   %esi
f0101453:	53                   	push   %ebx
f0101454:	8b 75 08             	mov    0x8(%ebp),%esi
f0101457:	8b 55 0c             	mov    0xc(%ebp),%edx
f010145a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010145d:	89 f0                	mov    %esi,%eax
f010145f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101463:	85 c9                	test   %ecx,%ecx
f0101465:	75 0b                	jne    f0101472 <strlcpy+0x23>
f0101467:	eb 1d                	jmp    f0101486 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101469:	83 c0 01             	add    $0x1,%eax
f010146c:	83 c2 01             	add    $0x1,%edx
f010146f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101472:	39 d8                	cmp    %ebx,%eax
f0101474:	74 0b                	je     f0101481 <strlcpy+0x32>
f0101476:	0f b6 0a             	movzbl (%edx),%ecx
f0101479:	84 c9                	test   %cl,%cl
f010147b:	75 ec                	jne    f0101469 <strlcpy+0x1a>
f010147d:	89 c2                	mov    %eax,%edx
f010147f:	eb 02                	jmp    f0101483 <strlcpy+0x34>
f0101481:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0101483:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0101486:	29 f0                	sub    %esi,%eax
}
f0101488:	5b                   	pop    %ebx
f0101489:	5e                   	pop    %esi
f010148a:	5d                   	pop    %ebp
f010148b:	c3                   	ret    

f010148c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010148c:	55                   	push   %ebp
f010148d:	89 e5                	mov    %esp,%ebp
f010148f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101492:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101495:	eb 06                	jmp    f010149d <strcmp+0x11>
		p++, q++;
f0101497:	83 c1 01             	add    $0x1,%ecx
f010149a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010149d:	0f b6 01             	movzbl (%ecx),%eax
f01014a0:	84 c0                	test   %al,%al
f01014a2:	74 04                	je     f01014a8 <strcmp+0x1c>
f01014a4:	3a 02                	cmp    (%edx),%al
f01014a6:	74 ef                	je     f0101497 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01014a8:	0f b6 c0             	movzbl %al,%eax
f01014ab:	0f b6 12             	movzbl (%edx),%edx
f01014ae:	29 d0                	sub    %edx,%eax
}
f01014b0:	5d                   	pop    %ebp
f01014b1:	c3                   	ret    

f01014b2 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01014b2:	55                   	push   %ebp
f01014b3:	89 e5                	mov    %esp,%ebp
f01014b5:	53                   	push   %ebx
f01014b6:	8b 45 08             	mov    0x8(%ebp),%eax
f01014b9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014bc:	89 c3                	mov    %eax,%ebx
f01014be:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01014c1:	eb 06                	jmp    f01014c9 <strncmp+0x17>
		n--, p++, q++;
f01014c3:	83 c0 01             	add    $0x1,%eax
f01014c6:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01014c9:	39 d8                	cmp    %ebx,%eax
f01014cb:	74 15                	je     f01014e2 <strncmp+0x30>
f01014cd:	0f b6 08             	movzbl (%eax),%ecx
f01014d0:	84 c9                	test   %cl,%cl
f01014d2:	74 04                	je     f01014d8 <strncmp+0x26>
f01014d4:	3a 0a                	cmp    (%edx),%cl
f01014d6:	74 eb                	je     f01014c3 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01014d8:	0f b6 00             	movzbl (%eax),%eax
f01014db:	0f b6 12             	movzbl (%edx),%edx
f01014de:	29 d0                	sub    %edx,%eax
f01014e0:	eb 05                	jmp    f01014e7 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01014e2:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01014e7:	5b                   	pop    %ebx
f01014e8:	5d                   	pop    %ebp
f01014e9:	c3                   	ret    

f01014ea <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01014ea:	55                   	push   %ebp
f01014eb:	89 e5                	mov    %esp,%ebp
f01014ed:	8b 45 08             	mov    0x8(%ebp),%eax
f01014f0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01014f4:	eb 07                	jmp    f01014fd <strchr+0x13>
		if (*s == c)
f01014f6:	38 ca                	cmp    %cl,%dl
f01014f8:	74 0f                	je     f0101509 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01014fa:	83 c0 01             	add    $0x1,%eax
f01014fd:	0f b6 10             	movzbl (%eax),%edx
f0101500:	84 d2                	test   %dl,%dl
f0101502:	75 f2                	jne    f01014f6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101504:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101509:	5d                   	pop    %ebp
f010150a:	c3                   	ret    

f010150b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010150b:	55                   	push   %ebp
f010150c:	89 e5                	mov    %esp,%ebp
f010150e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101511:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101515:	eb 07                	jmp    f010151e <strfind+0x13>
		if (*s == c)
f0101517:	38 ca                	cmp    %cl,%dl
f0101519:	74 0a                	je     f0101525 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010151b:	83 c0 01             	add    $0x1,%eax
f010151e:	0f b6 10             	movzbl (%eax),%edx
f0101521:	84 d2                	test   %dl,%dl
f0101523:	75 f2                	jne    f0101517 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0101525:	5d                   	pop    %ebp
f0101526:	c3                   	ret    

f0101527 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101527:	55                   	push   %ebp
f0101528:	89 e5                	mov    %esp,%ebp
f010152a:	57                   	push   %edi
f010152b:	56                   	push   %esi
f010152c:	53                   	push   %ebx
f010152d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101530:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101533:	85 c9                	test   %ecx,%ecx
f0101535:	74 36                	je     f010156d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101537:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010153d:	75 28                	jne    f0101567 <memset+0x40>
f010153f:	f6 c1 03             	test   $0x3,%cl
f0101542:	75 23                	jne    f0101567 <memset+0x40>
		c &= 0xFF;
f0101544:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101548:	89 d3                	mov    %edx,%ebx
f010154a:	c1 e3 08             	shl    $0x8,%ebx
f010154d:	89 d6                	mov    %edx,%esi
f010154f:	c1 e6 18             	shl    $0x18,%esi
f0101552:	89 d0                	mov    %edx,%eax
f0101554:	c1 e0 10             	shl    $0x10,%eax
f0101557:	09 f0                	or     %esi,%eax
f0101559:	09 c2                	or     %eax,%edx
f010155b:	89 d0                	mov    %edx,%eax
f010155d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010155f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0101562:	fc                   	cld    
f0101563:	f3 ab                	rep stos %eax,%es:(%edi)
f0101565:	eb 06                	jmp    f010156d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101567:	8b 45 0c             	mov    0xc(%ebp),%eax
f010156a:	fc                   	cld    
f010156b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010156d:	89 f8                	mov    %edi,%eax
f010156f:	5b                   	pop    %ebx
f0101570:	5e                   	pop    %esi
f0101571:	5f                   	pop    %edi
f0101572:	5d                   	pop    %ebp
f0101573:	c3                   	ret    

f0101574 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101574:	55                   	push   %ebp
f0101575:	89 e5                	mov    %esp,%ebp
f0101577:	57                   	push   %edi
f0101578:	56                   	push   %esi
f0101579:	8b 45 08             	mov    0x8(%ebp),%eax
f010157c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010157f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101582:	39 c6                	cmp    %eax,%esi
f0101584:	73 35                	jae    f01015bb <memmove+0x47>
f0101586:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101589:	39 d0                	cmp    %edx,%eax
f010158b:	73 2e                	jae    f01015bb <memmove+0x47>
		s += n;
		d += n;
f010158d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0101590:	89 d6                	mov    %edx,%esi
f0101592:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101594:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010159a:	75 13                	jne    f01015af <memmove+0x3b>
f010159c:	f6 c1 03             	test   $0x3,%cl
f010159f:	75 0e                	jne    f01015af <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01015a1:	83 ef 04             	sub    $0x4,%edi
f01015a4:	8d 72 fc             	lea    -0x4(%edx),%esi
f01015a7:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01015aa:	fd                   	std    
f01015ab:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01015ad:	eb 09                	jmp    f01015b8 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01015af:	83 ef 01             	sub    $0x1,%edi
f01015b2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01015b5:	fd                   	std    
f01015b6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01015b8:	fc                   	cld    
f01015b9:	eb 1d                	jmp    f01015d8 <memmove+0x64>
f01015bb:	89 f2                	mov    %esi,%edx
f01015bd:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015bf:	f6 c2 03             	test   $0x3,%dl
f01015c2:	75 0f                	jne    f01015d3 <memmove+0x5f>
f01015c4:	f6 c1 03             	test   $0x3,%cl
f01015c7:	75 0a                	jne    f01015d3 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01015c9:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01015cc:	89 c7                	mov    %eax,%edi
f01015ce:	fc                   	cld    
f01015cf:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01015d1:	eb 05                	jmp    f01015d8 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01015d3:	89 c7                	mov    %eax,%edi
f01015d5:	fc                   	cld    
f01015d6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01015d8:	5e                   	pop    %esi
f01015d9:	5f                   	pop    %edi
f01015da:	5d                   	pop    %ebp
f01015db:	c3                   	ret    

f01015dc <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01015dc:	55                   	push   %ebp
f01015dd:	89 e5                	mov    %esp,%ebp
f01015df:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01015e2:	8b 45 10             	mov    0x10(%ebp),%eax
f01015e5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01015e9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015ec:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015f0:	8b 45 08             	mov    0x8(%ebp),%eax
f01015f3:	89 04 24             	mov    %eax,(%esp)
f01015f6:	e8 79 ff ff ff       	call   f0101574 <memmove>
}
f01015fb:	c9                   	leave  
f01015fc:	c3                   	ret    

f01015fd <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01015fd:	55                   	push   %ebp
f01015fe:	89 e5                	mov    %esp,%ebp
f0101600:	56                   	push   %esi
f0101601:	53                   	push   %ebx
f0101602:	8b 55 08             	mov    0x8(%ebp),%edx
f0101605:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101608:	89 d6                	mov    %edx,%esi
f010160a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010160d:	eb 1a                	jmp    f0101629 <memcmp+0x2c>
		if (*s1 != *s2)
f010160f:	0f b6 02             	movzbl (%edx),%eax
f0101612:	0f b6 19             	movzbl (%ecx),%ebx
f0101615:	38 d8                	cmp    %bl,%al
f0101617:	74 0a                	je     f0101623 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101619:	0f b6 c0             	movzbl %al,%eax
f010161c:	0f b6 db             	movzbl %bl,%ebx
f010161f:	29 d8                	sub    %ebx,%eax
f0101621:	eb 0f                	jmp    f0101632 <memcmp+0x35>
		s1++, s2++;
f0101623:	83 c2 01             	add    $0x1,%edx
f0101626:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101629:	39 f2                	cmp    %esi,%edx
f010162b:	75 e2                	jne    f010160f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010162d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101632:	5b                   	pop    %ebx
f0101633:	5e                   	pop    %esi
f0101634:	5d                   	pop    %ebp
f0101635:	c3                   	ret    

f0101636 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101636:	55                   	push   %ebp
f0101637:	89 e5                	mov    %esp,%ebp
f0101639:	8b 45 08             	mov    0x8(%ebp),%eax
f010163c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010163f:	89 c2                	mov    %eax,%edx
f0101641:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101644:	eb 07                	jmp    f010164d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101646:	38 08                	cmp    %cl,(%eax)
f0101648:	74 07                	je     f0101651 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010164a:	83 c0 01             	add    $0x1,%eax
f010164d:	39 d0                	cmp    %edx,%eax
f010164f:	72 f5                	jb     f0101646 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101651:	5d                   	pop    %ebp
f0101652:	c3                   	ret    

f0101653 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101653:	55                   	push   %ebp
f0101654:	89 e5                	mov    %esp,%ebp
f0101656:	57                   	push   %edi
f0101657:	56                   	push   %esi
f0101658:	53                   	push   %ebx
f0101659:	8b 55 08             	mov    0x8(%ebp),%edx
f010165c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010165f:	eb 03                	jmp    f0101664 <strtol+0x11>
		s++;
f0101661:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101664:	0f b6 0a             	movzbl (%edx),%ecx
f0101667:	80 f9 09             	cmp    $0x9,%cl
f010166a:	74 f5                	je     f0101661 <strtol+0xe>
f010166c:	80 f9 20             	cmp    $0x20,%cl
f010166f:	74 f0                	je     f0101661 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101671:	80 f9 2b             	cmp    $0x2b,%cl
f0101674:	75 0a                	jne    f0101680 <strtol+0x2d>
		s++;
f0101676:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101679:	bf 00 00 00 00       	mov    $0x0,%edi
f010167e:	eb 11                	jmp    f0101691 <strtol+0x3e>
f0101680:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101685:	80 f9 2d             	cmp    $0x2d,%cl
f0101688:	75 07                	jne    f0101691 <strtol+0x3e>
		s++, neg = 1;
f010168a:	8d 52 01             	lea    0x1(%edx),%edx
f010168d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101691:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0101696:	75 15                	jne    f01016ad <strtol+0x5a>
f0101698:	80 3a 30             	cmpb   $0x30,(%edx)
f010169b:	75 10                	jne    f01016ad <strtol+0x5a>
f010169d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01016a1:	75 0a                	jne    f01016ad <strtol+0x5a>
		s += 2, base = 16;
f01016a3:	83 c2 02             	add    $0x2,%edx
f01016a6:	b8 10 00 00 00       	mov    $0x10,%eax
f01016ab:	eb 10                	jmp    f01016bd <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f01016ad:	85 c0                	test   %eax,%eax
f01016af:	75 0c                	jne    f01016bd <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01016b1:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01016b3:	80 3a 30             	cmpb   $0x30,(%edx)
f01016b6:	75 05                	jne    f01016bd <strtol+0x6a>
		s++, base = 8;
f01016b8:	83 c2 01             	add    $0x1,%edx
f01016bb:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f01016bd:	bb 00 00 00 00       	mov    $0x0,%ebx
f01016c2:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01016c5:	0f b6 0a             	movzbl (%edx),%ecx
f01016c8:	8d 71 d0             	lea    -0x30(%ecx),%esi
f01016cb:	89 f0                	mov    %esi,%eax
f01016cd:	3c 09                	cmp    $0x9,%al
f01016cf:	77 08                	ja     f01016d9 <strtol+0x86>
			dig = *s - '0';
f01016d1:	0f be c9             	movsbl %cl,%ecx
f01016d4:	83 e9 30             	sub    $0x30,%ecx
f01016d7:	eb 20                	jmp    f01016f9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f01016d9:	8d 71 9f             	lea    -0x61(%ecx),%esi
f01016dc:	89 f0                	mov    %esi,%eax
f01016de:	3c 19                	cmp    $0x19,%al
f01016e0:	77 08                	ja     f01016ea <strtol+0x97>
			dig = *s - 'a' + 10;
f01016e2:	0f be c9             	movsbl %cl,%ecx
f01016e5:	83 e9 57             	sub    $0x57,%ecx
f01016e8:	eb 0f                	jmp    f01016f9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f01016ea:	8d 71 bf             	lea    -0x41(%ecx),%esi
f01016ed:	89 f0                	mov    %esi,%eax
f01016ef:	3c 19                	cmp    $0x19,%al
f01016f1:	77 16                	ja     f0101709 <strtol+0xb6>
			dig = *s - 'A' + 10;
f01016f3:	0f be c9             	movsbl %cl,%ecx
f01016f6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01016f9:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f01016fc:	7d 0f                	jge    f010170d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f01016fe:	83 c2 01             	add    $0x1,%edx
f0101701:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0101705:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0101707:	eb bc                	jmp    f01016c5 <strtol+0x72>
f0101709:	89 d8                	mov    %ebx,%eax
f010170b:	eb 02                	jmp    f010170f <strtol+0xbc>
f010170d:	89 d8                	mov    %ebx,%eax

	if (endptr)
f010170f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101713:	74 05                	je     f010171a <strtol+0xc7>
		*endptr = (char *) s;
f0101715:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101718:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f010171a:	f7 d8                	neg    %eax
f010171c:	85 ff                	test   %edi,%edi
f010171e:	0f 44 c3             	cmove  %ebx,%eax
}
f0101721:	5b                   	pop    %ebx
f0101722:	5e                   	pop    %esi
f0101723:	5f                   	pop    %edi
f0101724:	5d                   	pop    %ebp
f0101725:	c3                   	ret    
f0101726:	66 90                	xchg   %ax,%ax
f0101728:	66 90                	xchg   %ax,%ax
f010172a:	66 90                	xchg   %ax,%ax
f010172c:	66 90                	xchg   %ax,%ax
f010172e:	66 90                	xchg   %ax,%ax

f0101730 <__udivdi3>:
f0101730:	55                   	push   %ebp
f0101731:	57                   	push   %edi
f0101732:	56                   	push   %esi
f0101733:	83 ec 0c             	sub    $0xc,%esp
f0101736:	8b 44 24 28          	mov    0x28(%esp),%eax
f010173a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f010173e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0101742:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0101746:	85 c0                	test   %eax,%eax
f0101748:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010174c:	89 ea                	mov    %ebp,%edx
f010174e:	89 0c 24             	mov    %ecx,(%esp)
f0101751:	75 2d                	jne    f0101780 <__udivdi3+0x50>
f0101753:	39 e9                	cmp    %ebp,%ecx
f0101755:	77 61                	ja     f01017b8 <__udivdi3+0x88>
f0101757:	85 c9                	test   %ecx,%ecx
f0101759:	89 ce                	mov    %ecx,%esi
f010175b:	75 0b                	jne    f0101768 <__udivdi3+0x38>
f010175d:	b8 01 00 00 00       	mov    $0x1,%eax
f0101762:	31 d2                	xor    %edx,%edx
f0101764:	f7 f1                	div    %ecx
f0101766:	89 c6                	mov    %eax,%esi
f0101768:	31 d2                	xor    %edx,%edx
f010176a:	89 e8                	mov    %ebp,%eax
f010176c:	f7 f6                	div    %esi
f010176e:	89 c5                	mov    %eax,%ebp
f0101770:	89 f8                	mov    %edi,%eax
f0101772:	f7 f6                	div    %esi
f0101774:	89 ea                	mov    %ebp,%edx
f0101776:	83 c4 0c             	add    $0xc,%esp
f0101779:	5e                   	pop    %esi
f010177a:	5f                   	pop    %edi
f010177b:	5d                   	pop    %ebp
f010177c:	c3                   	ret    
f010177d:	8d 76 00             	lea    0x0(%esi),%esi
f0101780:	39 e8                	cmp    %ebp,%eax
f0101782:	77 24                	ja     f01017a8 <__udivdi3+0x78>
f0101784:	0f bd e8             	bsr    %eax,%ebp
f0101787:	83 f5 1f             	xor    $0x1f,%ebp
f010178a:	75 3c                	jne    f01017c8 <__udivdi3+0x98>
f010178c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0101790:	39 34 24             	cmp    %esi,(%esp)
f0101793:	0f 86 9f 00 00 00    	jbe    f0101838 <__udivdi3+0x108>
f0101799:	39 d0                	cmp    %edx,%eax
f010179b:	0f 82 97 00 00 00    	jb     f0101838 <__udivdi3+0x108>
f01017a1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01017a8:	31 d2                	xor    %edx,%edx
f01017aa:	31 c0                	xor    %eax,%eax
f01017ac:	83 c4 0c             	add    $0xc,%esp
f01017af:	5e                   	pop    %esi
f01017b0:	5f                   	pop    %edi
f01017b1:	5d                   	pop    %ebp
f01017b2:	c3                   	ret    
f01017b3:	90                   	nop
f01017b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01017b8:	89 f8                	mov    %edi,%eax
f01017ba:	f7 f1                	div    %ecx
f01017bc:	31 d2                	xor    %edx,%edx
f01017be:	83 c4 0c             	add    $0xc,%esp
f01017c1:	5e                   	pop    %esi
f01017c2:	5f                   	pop    %edi
f01017c3:	5d                   	pop    %ebp
f01017c4:	c3                   	ret    
f01017c5:	8d 76 00             	lea    0x0(%esi),%esi
f01017c8:	89 e9                	mov    %ebp,%ecx
f01017ca:	8b 3c 24             	mov    (%esp),%edi
f01017cd:	d3 e0                	shl    %cl,%eax
f01017cf:	89 c6                	mov    %eax,%esi
f01017d1:	b8 20 00 00 00       	mov    $0x20,%eax
f01017d6:	29 e8                	sub    %ebp,%eax
f01017d8:	89 c1                	mov    %eax,%ecx
f01017da:	d3 ef                	shr    %cl,%edi
f01017dc:	89 e9                	mov    %ebp,%ecx
f01017de:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01017e2:	8b 3c 24             	mov    (%esp),%edi
f01017e5:	09 74 24 08          	or     %esi,0x8(%esp)
f01017e9:	89 d6                	mov    %edx,%esi
f01017eb:	d3 e7                	shl    %cl,%edi
f01017ed:	89 c1                	mov    %eax,%ecx
f01017ef:	89 3c 24             	mov    %edi,(%esp)
f01017f2:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01017f6:	d3 ee                	shr    %cl,%esi
f01017f8:	89 e9                	mov    %ebp,%ecx
f01017fa:	d3 e2                	shl    %cl,%edx
f01017fc:	89 c1                	mov    %eax,%ecx
f01017fe:	d3 ef                	shr    %cl,%edi
f0101800:	09 d7                	or     %edx,%edi
f0101802:	89 f2                	mov    %esi,%edx
f0101804:	89 f8                	mov    %edi,%eax
f0101806:	f7 74 24 08          	divl   0x8(%esp)
f010180a:	89 d6                	mov    %edx,%esi
f010180c:	89 c7                	mov    %eax,%edi
f010180e:	f7 24 24             	mull   (%esp)
f0101811:	39 d6                	cmp    %edx,%esi
f0101813:	89 14 24             	mov    %edx,(%esp)
f0101816:	72 30                	jb     f0101848 <__udivdi3+0x118>
f0101818:	8b 54 24 04          	mov    0x4(%esp),%edx
f010181c:	89 e9                	mov    %ebp,%ecx
f010181e:	d3 e2                	shl    %cl,%edx
f0101820:	39 c2                	cmp    %eax,%edx
f0101822:	73 05                	jae    f0101829 <__udivdi3+0xf9>
f0101824:	3b 34 24             	cmp    (%esp),%esi
f0101827:	74 1f                	je     f0101848 <__udivdi3+0x118>
f0101829:	89 f8                	mov    %edi,%eax
f010182b:	31 d2                	xor    %edx,%edx
f010182d:	e9 7a ff ff ff       	jmp    f01017ac <__udivdi3+0x7c>
f0101832:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101838:	31 d2                	xor    %edx,%edx
f010183a:	b8 01 00 00 00       	mov    $0x1,%eax
f010183f:	e9 68 ff ff ff       	jmp    f01017ac <__udivdi3+0x7c>
f0101844:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101848:	8d 47 ff             	lea    -0x1(%edi),%eax
f010184b:	31 d2                	xor    %edx,%edx
f010184d:	83 c4 0c             	add    $0xc,%esp
f0101850:	5e                   	pop    %esi
f0101851:	5f                   	pop    %edi
f0101852:	5d                   	pop    %ebp
f0101853:	c3                   	ret    
f0101854:	66 90                	xchg   %ax,%ax
f0101856:	66 90                	xchg   %ax,%ax
f0101858:	66 90                	xchg   %ax,%ax
f010185a:	66 90                	xchg   %ax,%ax
f010185c:	66 90                	xchg   %ax,%ax
f010185e:	66 90                	xchg   %ax,%ax

f0101860 <__umoddi3>:
f0101860:	55                   	push   %ebp
f0101861:	57                   	push   %edi
f0101862:	56                   	push   %esi
f0101863:	83 ec 14             	sub    $0x14,%esp
f0101866:	8b 44 24 28          	mov    0x28(%esp),%eax
f010186a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f010186e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0101872:	89 c7                	mov    %eax,%edi
f0101874:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101878:	8b 44 24 30          	mov    0x30(%esp),%eax
f010187c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0101880:	89 34 24             	mov    %esi,(%esp)
f0101883:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101887:	85 c0                	test   %eax,%eax
f0101889:	89 c2                	mov    %eax,%edx
f010188b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010188f:	75 17                	jne    f01018a8 <__umoddi3+0x48>
f0101891:	39 fe                	cmp    %edi,%esi
f0101893:	76 4b                	jbe    f01018e0 <__umoddi3+0x80>
f0101895:	89 c8                	mov    %ecx,%eax
f0101897:	89 fa                	mov    %edi,%edx
f0101899:	f7 f6                	div    %esi
f010189b:	89 d0                	mov    %edx,%eax
f010189d:	31 d2                	xor    %edx,%edx
f010189f:	83 c4 14             	add    $0x14,%esp
f01018a2:	5e                   	pop    %esi
f01018a3:	5f                   	pop    %edi
f01018a4:	5d                   	pop    %ebp
f01018a5:	c3                   	ret    
f01018a6:	66 90                	xchg   %ax,%ax
f01018a8:	39 f8                	cmp    %edi,%eax
f01018aa:	77 54                	ja     f0101900 <__umoddi3+0xa0>
f01018ac:	0f bd e8             	bsr    %eax,%ebp
f01018af:	83 f5 1f             	xor    $0x1f,%ebp
f01018b2:	75 5c                	jne    f0101910 <__umoddi3+0xb0>
f01018b4:	8b 7c 24 08          	mov    0x8(%esp),%edi
f01018b8:	39 3c 24             	cmp    %edi,(%esp)
f01018bb:	0f 87 e7 00 00 00    	ja     f01019a8 <__umoddi3+0x148>
f01018c1:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01018c5:	29 f1                	sub    %esi,%ecx
f01018c7:	19 c7                	sbb    %eax,%edi
f01018c9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01018cd:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01018d1:	8b 44 24 08          	mov    0x8(%esp),%eax
f01018d5:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01018d9:	83 c4 14             	add    $0x14,%esp
f01018dc:	5e                   	pop    %esi
f01018dd:	5f                   	pop    %edi
f01018de:	5d                   	pop    %ebp
f01018df:	c3                   	ret    
f01018e0:	85 f6                	test   %esi,%esi
f01018e2:	89 f5                	mov    %esi,%ebp
f01018e4:	75 0b                	jne    f01018f1 <__umoddi3+0x91>
f01018e6:	b8 01 00 00 00       	mov    $0x1,%eax
f01018eb:	31 d2                	xor    %edx,%edx
f01018ed:	f7 f6                	div    %esi
f01018ef:	89 c5                	mov    %eax,%ebp
f01018f1:	8b 44 24 04          	mov    0x4(%esp),%eax
f01018f5:	31 d2                	xor    %edx,%edx
f01018f7:	f7 f5                	div    %ebp
f01018f9:	89 c8                	mov    %ecx,%eax
f01018fb:	f7 f5                	div    %ebp
f01018fd:	eb 9c                	jmp    f010189b <__umoddi3+0x3b>
f01018ff:	90                   	nop
f0101900:	89 c8                	mov    %ecx,%eax
f0101902:	89 fa                	mov    %edi,%edx
f0101904:	83 c4 14             	add    $0x14,%esp
f0101907:	5e                   	pop    %esi
f0101908:	5f                   	pop    %edi
f0101909:	5d                   	pop    %ebp
f010190a:	c3                   	ret    
f010190b:	90                   	nop
f010190c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101910:	8b 04 24             	mov    (%esp),%eax
f0101913:	be 20 00 00 00       	mov    $0x20,%esi
f0101918:	89 e9                	mov    %ebp,%ecx
f010191a:	29 ee                	sub    %ebp,%esi
f010191c:	d3 e2                	shl    %cl,%edx
f010191e:	89 f1                	mov    %esi,%ecx
f0101920:	d3 e8                	shr    %cl,%eax
f0101922:	89 e9                	mov    %ebp,%ecx
f0101924:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101928:	8b 04 24             	mov    (%esp),%eax
f010192b:	09 54 24 04          	or     %edx,0x4(%esp)
f010192f:	89 fa                	mov    %edi,%edx
f0101931:	d3 e0                	shl    %cl,%eax
f0101933:	89 f1                	mov    %esi,%ecx
f0101935:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101939:	8b 44 24 10          	mov    0x10(%esp),%eax
f010193d:	d3 ea                	shr    %cl,%edx
f010193f:	89 e9                	mov    %ebp,%ecx
f0101941:	d3 e7                	shl    %cl,%edi
f0101943:	89 f1                	mov    %esi,%ecx
f0101945:	d3 e8                	shr    %cl,%eax
f0101947:	89 e9                	mov    %ebp,%ecx
f0101949:	09 f8                	or     %edi,%eax
f010194b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f010194f:	f7 74 24 04          	divl   0x4(%esp)
f0101953:	d3 e7                	shl    %cl,%edi
f0101955:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101959:	89 d7                	mov    %edx,%edi
f010195b:	f7 64 24 08          	mull   0x8(%esp)
f010195f:	39 d7                	cmp    %edx,%edi
f0101961:	89 c1                	mov    %eax,%ecx
f0101963:	89 14 24             	mov    %edx,(%esp)
f0101966:	72 2c                	jb     f0101994 <__umoddi3+0x134>
f0101968:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f010196c:	72 22                	jb     f0101990 <__umoddi3+0x130>
f010196e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101972:	29 c8                	sub    %ecx,%eax
f0101974:	19 d7                	sbb    %edx,%edi
f0101976:	89 e9                	mov    %ebp,%ecx
f0101978:	89 fa                	mov    %edi,%edx
f010197a:	d3 e8                	shr    %cl,%eax
f010197c:	89 f1                	mov    %esi,%ecx
f010197e:	d3 e2                	shl    %cl,%edx
f0101980:	89 e9                	mov    %ebp,%ecx
f0101982:	d3 ef                	shr    %cl,%edi
f0101984:	09 d0                	or     %edx,%eax
f0101986:	89 fa                	mov    %edi,%edx
f0101988:	83 c4 14             	add    $0x14,%esp
f010198b:	5e                   	pop    %esi
f010198c:	5f                   	pop    %edi
f010198d:	5d                   	pop    %ebp
f010198e:	c3                   	ret    
f010198f:	90                   	nop
f0101990:	39 d7                	cmp    %edx,%edi
f0101992:	75 da                	jne    f010196e <__umoddi3+0x10e>
f0101994:	8b 14 24             	mov    (%esp),%edx
f0101997:	89 c1                	mov    %eax,%ecx
f0101999:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f010199d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f01019a1:	eb cb                	jmp    f010196e <__umoddi3+0x10e>
f01019a3:	90                   	nop
f01019a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019a8:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f01019ac:	0f 82 0f ff ff ff    	jb     f01018c1 <__umoddi3+0x61>
f01019b2:	e9 1a ff ff ff       	jmp    f01018d1 <__umoddi3+0x71>
