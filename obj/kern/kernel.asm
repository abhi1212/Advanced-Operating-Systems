
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
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
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
f0100034:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

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
f0100043:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 70 79 11 f0       	mov    $0xf0117970,%eax
f010004b:	2d 00 73 11 f0       	sub    $0xf0117300,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 00 73 11 f0 	movl   $0xf0117300,(%esp)
f0100063:	e8 4f 38 00 00       	call   f01038b7 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 a2 04 00 00       	call   f010050f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828); 
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 60 3d 10 f0 	movl   $0xf0103d60,(%esp)
f010007c:	e8 e5 2c 00 00       	call   f0102d66 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 46 11 00 00       	call   f01011cc <mem_init>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 69 07 00 00       	call   f01007fb <monitor>
f0100092:	eb f2                	jmp    f0100086 <i386_init+0x46>

f0100094 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	56                   	push   %esi
f0100098:	53                   	push   %ebx
f0100099:	83 ec 10             	sub    $0x10,%esp
f010009c:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010009f:	83 3d 60 79 11 f0 00 	cmpl   $0x0,0xf0117960
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 60 79 11 f0    	mov    %esi,0xf0117960

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000ae:	fa                   	cli    
f01000af:	fc                   	cld    

	va_start(ap, fmt);
f01000b0:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000b3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01000bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000c1:	c7 04 24 7b 3d 10 f0 	movl   $0xf0103d7b,(%esp)
f01000c8:	e8 99 2c 00 00       	call   f0102d66 <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 5a 2c 00 00       	call   f0102d33 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 5c 43 10 f0 	movl   $0xf010435c,(%esp)
f01000e0:	e8 81 2c 00 00       	call   f0102d66 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 0a 07 00 00       	call   f01007fb <monitor>
f01000f1:	eb f2                	jmp    f01000e5 <_panic+0x51>

f01000f3 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f3:	55                   	push   %ebp
f01000f4:	89 e5                	mov    %esp,%ebp
f01000f6:	53                   	push   %ebx
f01000f7:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fa:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100100:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100104:	8b 45 08             	mov    0x8(%ebp),%eax
f0100107:	89 44 24 04          	mov    %eax,0x4(%esp)
f010010b:	c7 04 24 93 3d 10 f0 	movl   $0xf0103d93,(%esp)
f0100112:	e8 4f 2c 00 00       	call   f0102d66 <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 0d 2c 00 00       	call   f0102d33 <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 5c 43 10 f0 	movl   $0xf010435c,(%esp)
f010012d:	e8 34 2c 00 00       	call   f0102d66 <cprintf>
	va_end(ap);
}
f0100132:	83 c4 14             	add    $0x14,%esp
f0100135:	5b                   	pop    %ebx
f0100136:	5d                   	pop    %ebp
f0100137:	c3                   	ret    
f0100138:	66 90                	xchg   %ax,%ax
f010013a:	66 90                	xchg   %ax,%ax
f010013c:	66 90                	xchg   %ax,%ax
f010013e:	66 90                	xchg   %ax,%ax

f0100140 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100140:	55                   	push   %ebp
f0100141:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100143:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100148:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100149:	a8 01                	test   $0x1,%al
f010014b:	74 08                	je     f0100155 <serial_proc_data+0x15>
f010014d:	b2 f8                	mov    $0xf8,%dl
f010014f:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100150:	0f b6 c0             	movzbl %al,%eax
f0100153:	eb 05                	jmp    f010015a <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100155:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010015a:	5d                   	pop    %ebp
f010015b:	c3                   	ret    

f010015c <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010015c:	55                   	push   %ebp
f010015d:	89 e5                	mov    %esp,%ebp
f010015f:	53                   	push   %ebx
f0100160:	83 ec 04             	sub    $0x4,%esp
f0100163:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100165:	eb 2a                	jmp    f0100191 <cons_intr+0x35>
		if (c == 0)
f0100167:	85 d2                	test   %edx,%edx
f0100169:	74 26                	je     f0100191 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f010016b:	a1 24 75 11 f0       	mov    0xf0117524,%eax
f0100170:	8d 48 01             	lea    0x1(%eax),%ecx
f0100173:	89 0d 24 75 11 f0    	mov    %ecx,0xf0117524
f0100179:	88 90 20 73 11 f0    	mov    %dl,-0xfee8ce0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f010017f:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100185:	75 0a                	jne    f0100191 <cons_intr+0x35>
			cons.wpos = 0;
f0100187:	c7 05 24 75 11 f0 00 	movl   $0x0,0xf0117524
f010018e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100191:	ff d3                	call   *%ebx
f0100193:	89 c2                	mov    %eax,%edx
f0100195:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100198:	75 cd                	jne    f0100167 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010019a:	83 c4 04             	add    $0x4,%esp
f010019d:	5b                   	pop    %ebx
f010019e:	5d                   	pop    %ebp
f010019f:	c3                   	ret    

f01001a0 <kbd_proc_data>:
f01001a0:	ba 64 00 00 00       	mov    $0x64,%edx
f01001a5:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01001a6:	a8 01                	test   $0x1,%al
f01001a8:	0f 84 f7 00 00 00    	je     f01002a5 <kbd_proc_data+0x105>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01001ae:	a8 20                	test   $0x20,%al
f01001b0:	0f 85 f5 00 00 00    	jne    f01002ab <kbd_proc_data+0x10b>
f01001b6:	b2 60                	mov    $0x60,%dl
f01001b8:	ec                   	in     (%dx),%al
f01001b9:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001bb:	3c e0                	cmp    $0xe0,%al
f01001bd:	75 0d                	jne    f01001cc <kbd_proc_data+0x2c>
		// E0 escape character
		shift |= E0ESC;
f01001bf:	83 0d 00 73 11 f0 40 	orl    $0x40,0xf0117300
		return 0;
f01001c6:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001cb:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001cc:	55                   	push   %ebp
f01001cd:	89 e5                	mov    %esp,%ebp
f01001cf:	53                   	push   %ebx
f01001d0:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001d3:	84 c0                	test   %al,%al
f01001d5:	79 37                	jns    f010020e <kbd_proc_data+0x6e>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001d7:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001dd:	89 cb                	mov    %ecx,%ebx
f01001df:	83 e3 40             	and    $0x40,%ebx
f01001e2:	83 e0 7f             	and    $0x7f,%eax
f01001e5:	85 db                	test   %ebx,%ebx
f01001e7:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001ea:	0f b6 d2             	movzbl %dl,%edx
f01001ed:	0f b6 82 00 3f 10 f0 	movzbl -0xfefc100(%edx),%eax
f01001f4:	83 c8 40             	or     $0x40,%eax
f01001f7:	0f b6 c0             	movzbl %al,%eax
f01001fa:	f7 d0                	not    %eax
f01001fc:	21 c1                	and    %eax,%ecx
f01001fe:	89 0d 00 73 11 f0    	mov    %ecx,0xf0117300
		return 0;
f0100204:	b8 00 00 00 00       	mov    $0x0,%eax
f0100209:	e9 a3 00 00 00       	jmp    f01002b1 <kbd_proc_data+0x111>
	} else if (shift & E0ESC) {
f010020e:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f0100214:	f6 c1 40             	test   $0x40,%cl
f0100217:	74 0e                	je     f0100227 <kbd_proc_data+0x87>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100219:	83 c8 80             	or     $0xffffff80,%eax
f010021c:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010021e:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100221:	89 0d 00 73 11 f0    	mov    %ecx,0xf0117300
	}

	shift |= shiftcode[data];
f0100227:	0f b6 d2             	movzbl %dl,%edx
f010022a:	0f b6 82 00 3f 10 f0 	movzbl -0xfefc100(%edx),%eax
f0100231:	0b 05 00 73 11 f0    	or     0xf0117300,%eax
	shift ^= togglecode[data];
f0100237:	0f b6 8a 00 3e 10 f0 	movzbl -0xfefc200(%edx),%ecx
f010023e:	31 c8                	xor    %ecx,%eax
f0100240:	a3 00 73 11 f0       	mov    %eax,0xf0117300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100245:	89 c1                	mov    %eax,%ecx
f0100247:	83 e1 03             	and    $0x3,%ecx
f010024a:	8b 0c 8d e0 3d 10 f0 	mov    -0xfefc220(,%ecx,4),%ecx
f0100251:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100255:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100258:	a8 08                	test   $0x8,%al
f010025a:	74 1b                	je     f0100277 <kbd_proc_data+0xd7>
		if ('a' <= c && c <= 'z')
f010025c:	89 da                	mov    %ebx,%edx
f010025e:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100261:	83 f9 19             	cmp    $0x19,%ecx
f0100264:	77 05                	ja     f010026b <kbd_proc_data+0xcb>
			c += 'A' - 'a';
f0100266:	83 eb 20             	sub    $0x20,%ebx
f0100269:	eb 0c                	jmp    f0100277 <kbd_proc_data+0xd7>
		else if ('A' <= c && c <= 'Z')
f010026b:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010026e:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100271:	83 fa 19             	cmp    $0x19,%edx
f0100274:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100277:	f7 d0                	not    %eax
f0100279:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f010027b:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010027d:	f6 c2 06             	test   $0x6,%dl
f0100280:	75 2f                	jne    f01002b1 <kbd_proc_data+0x111>
f0100282:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100288:	75 27                	jne    f01002b1 <kbd_proc_data+0x111>
		cprintf("Rebooting!\n");
f010028a:	c7 04 24 ad 3d 10 f0 	movl   $0xf0103dad,(%esp)
f0100291:	e8 d0 2a 00 00       	call   f0102d66 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100296:	ba 92 00 00 00       	mov    $0x92,%edx
f010029b:	b8 03 00 00 00       	mov    $0x3,%eax
f01002a0:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002a1:	89 d8                	mov    %ebx,%eax
f01002a3:	eb 0c                	jmp    f01002b1 <kbd_proc_data+0x111>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01002a5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002aa:	c3                   	ret    
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01002ab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002b0:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002b1:	83 c4 14             	add    $0x14,%esp
f01002b4:	5b                   	pop    %ebx
f01002b5:	5d                   	pop    %ebp
f01002b6:	c3                   	ret    

f01002b7 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002b7:	55                   	push   %ebp
f01002b8:	89 e5                	mov    %esp,%ebp
f01002ba:	57                   	push   %edi
f01002bb:	56                   	push   %esi
f01002bc:	53                   	push   %ebx
f01002bd:	83 ec 1c             	sub    $0x1c,%esp
f01002c0:	89 c7                	mov    %eax,%edi
f01002c2:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002c7:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002cc:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002d1:	eb 06                	jmp    f01002d9 <cons_putc+0x22>
f01002d3:	89 ca                	mov    %ecx,%edx
f01002d5:	ec                   	in     (%dx),%al
f01002d6:	ec                   	in     (%dx),%al
f01002d7:	ec                   	in     (%dx),%al
f01002d8:	ec                   	in     (%dx),%al
f01002d9:	89 f2                	mov    %esi,%edx
f01002db:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002dc:	a8 20                	test   $0x20,%al
f01002de:	75 05                	jne    f01002e5 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002e0:	83 eb 01             	sub    $0x1,%ebx
f01002e3:	75 ee                	jne    f01002d3 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f01002e5:	89 f8                	mov    %edi,%eax
f01002e7:	0f b6 c0             	movzbl %al,%eax
f01002ea:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ed:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002f2:	ee                   	out    %al,(%dx)
f01002f3:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002f8:	be 79 03 00 00       	mov    $0x379,%esi
f01002fd:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100302:	eb 06                	jmp    f010030a <cons_putc+0x53>
f0100304:	89 ca                	mov    %ecx,%edx
f0100306:	ec                   	in     (%dx),%al
f0100307:	ec                   	in     (%dx),%al
f0100308:	ec                   	in     (%dx),%al
f0100309:	ec                   	in     (%dx),%al
f010030a:	89 f2                	mov    %esi,%edx
f010030c:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010030d:	84 c0                	test   %al,%al
f010030f:	78 05                	js     f0100316 <cons_putc+0x5f>
f0100311:	83 eb 01             	sub    $0x1,%ebx
f0100314:	75 ee                	jne    f0100304 <cons_putc+0x4d>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100316:	ba 78 03 00 00       	mov    $0x378,%edx
f010031b:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f010031f:	ee                   	out    %al,(%dx)
f0100320:	b2 7a                	mov    $0x7a,%dl
f0100322:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100327:	ee                   	out    %al,(%dx)
f0100328:	b8 08 00 00 00       	mov    $0x8,%eax
f010032d:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010032e:	89 fa                	mov    %edi,%edx
f0100330:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100336:	89 f8                	mov    %edi,%eax
f0100338:	80 cc 07             	or     $0x7,%ah
f010033b:	85 d2                	test   %edx,%edx
f010033d:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100340:	89 f8                	mov    %edi,%eax
f0100342:	0f b6 c0             	movzbl %al,%eax
f0100345:	83 f8 09             	cmp    $0x9,%eax
f0100348:	74 78                	je     f01003c2 <cons_putc+0x10b>
f010034a:	83 f8 09             	cmp    $0x9,%eax
f010034d:	7f 0a                	jg     f0100359 <cons_putc+0xa2>
f010034f:	83 f8 08             	cmp    $0x8,%eax
f0100352:	74 18                	je     f010036c <cons_putc+0xb5>
f0100354:	e9 9d 00 00 00       	jmp    f01003f6 <cons_putc+0x13f>
f0100359:	83 f8 0a             	cmp    $0xa,%eax
f010035c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100360:	74 3a                	je     f010039c <cons_putc+0xe5>
f0100362:	83 f8 0d             	cmp    $0xd,%eax
f0100365:	74 3d                	je     f01003a4 <cons_putc+0xed>
f0100367:	e9 8a 00 00 00       	jmp    f01003f6 <cons_putc+0x13f>
	case '\b':
		if (crt_pos > 0) {
f010036c:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f0100373:	66 85 c0             	test   %ax,%ax
f0100376:	0f 84 e5 00 00 00    	je     f0100461 <cons_putc+0x1aa>
			crt_pos--;
f010037c:	83 e8 01             	sub    $0x1,%eax
f010037f:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100385:	0f b7 c0             	movzwl %ax,%eax
f0100388:	66 81 e7 00 ff       	and    $0xff00,%di
f010038d:	83 cf 20             	or     $0x20,%edi
f0100390:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f0100396:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f010039a:	eb 78                	jmp    f0100414 <cons_putc+0x15d>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010039c:	66 83 05 28 75 11 f0 	addw   $0x50,0xf0117528
f01003a3:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003a4:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f01003ab:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003b1:	c1 e8 16             	shr    $0x16,%eax
f01003b4:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003b7:	c1 e0 04             	shl    $0x4,%eax
f01003ba:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
f01003c0:	eb 52                	jmp    f0100414 <cons_putc+0x15d>
		break;
	case '\t':
		cons_putc(' ');
f01003c2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c7:	e8 eb fe ff ff       	call   f01002b7 <cons_putc>
		cons_putc(' ');
f01003cc:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d1:	e8 e1 fe ff ff       	call   f01002b7 <cons_putc>
		cons_putc(' ');
f01003d6:	b8 20 00 00 00       	mov    $0x20,%eax
f01003db:	e8 d7 fe ff ff       	call   f01002b7 <cons_putc>
		cons_putc(' ');
f01003e0:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e5:	e8 cd fe ff ff       	call   f01002b7 <cons_putc>
		cons_putc(' ');
f01003ea:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ef:	e8 c3 fe ff ff       	call   f01002b7 <cons_putc>
f01003f4:	eb 1e                	jmp    f0100414 <cons_putc+0x15d>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003f6:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f01003fd:	8d 50 01             	lea    0x1(%eax),%edx
f0100400:	66 89 15 28 75 11 f0 	mov    %dx,0xf0117528
f0100407:	0f b7 c0             	movzwl %ax,%eax
f010040a:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f0100410:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100414:	66 81 3d 28 75 11 f0 	cmpw   $0x7cf,0xf0117528
f010041b:	cf 07 
f010041d:	76 42                	jbe    f0100461 <cons_putc+0x1aa>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010041f:	a1 2c 75 11 f0       	mov    0xf011752c,%eax
f0100424:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010042b:	00 
f010042c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100432:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100436:	89 04 24             	mov    %eax,(%esp)
f0100439:	e8 c6 34 00 00       	call   f0103904 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010043e:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100444:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100449:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010044f:	83 c0 01             	add    $0x1,%eax
f0100452:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100457:	75 f0                	jne    f0100449 <cons_putc+0x192>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100459:	66 83 2d 28 75 11 f0 	subw   $0x50,0xf0117528
f0100460:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100461:	8b 0d 30 75 11 f0    	mov    0xf0117530,%ecx
f0100467:	b8 0e 00 00 00       	mov    $0xe,%eax
f010046c:	89 ca                	mov    %ecx,%edx
f010046e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010046f:	0f b7 1d 28 75 11 f0 	movzwl 0xf0117528,%ebx
f0100476:	8d 71 01             	lea    0x1(%ecx),%esi
f0100479:	89 d8                	mov    %ebx,%eax
f010047b:	66 c1 e8 08          	shr    $0x8,%ax
f010047f:	89 f2                	mov    %esi,%edx
f0100481:	ee                   	out    %al,(%dx)
f0100482:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100487:	89 ca                	mov    %ecx,%edx
f0100489:	ee                   	out    %al,(%dx)
f010048a:	89 d8                	mov    %ebx,%eax
f010048c:	89 f2                	mov    %esi,%edx
f010048e:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010048f:	83 c4 1c             	add    $0x1c,%esp
f0100492:	5b                   	pop    %ebx
f0100493:	5e                   	pop    %esi
f0100494:	5f                   	pop    %edi
f0100495:	5d                   	pop    %ebp
f0100496:	c3                   	ret    

f0100497 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100497:	80 3d 34 75 11 f0 00 	cmpb   $0x0,0xf0117534
f010049e:	74 11                	je     f01004b1 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004a0:	55                   	push   %ebp
f01004a1:	89 e5                	mov    %esp,%ebp
f01004a3:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004a6:	b8 40 01 10 f0       	mov    $0xf0100140,%eax
f01004ab:	e8 ac fc ff ff       	call   f010015c <cons_intr>
}
f01004b0:	c9                   	leave  
f01004b1:	f3 c3                	repz ret 

f01004b3 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004b3:	55                   	push   %ebp
f01004b4:	89 e5                	mov    %esp,%ebp
f01004b6:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004b9:	b8 a0 01 10 f0       	mov    $0xf01001a0,%eax
f01004be:	e8 99 fc ff ff       	call   f010015c <cons_intr>
}
f01004c3:	c9                   	leave  
f01004c4:	c3                   	ret    

f01004c5 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004c5:	55                   	push   %ebp
f01004c6:	89 e5                	mov    %esp,%ebp
f01004c8:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004cb:	e8 c7 ff ff ff       	call   f0100497 <serial_intr>
	kbd_intr();
f01004d0:	e8 de ff ff ff       	call   f01004b3 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004d5:	a1 20 75 11 f0       	mov    0xf0117520,%eax
f01004da:	3b 05 24 75 11 f0    	cmp    0xf0117524,%eax
f01004e0:	74 26                	je     f0100508 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004e2:	8d 50 01             	lea    0x1(%eax),%edx
f01004e5:	89 15 20 75 11 f0    	mov    %edx,0xf0117520
f01004eb:	0f b6 88 20 73 11 f0 	movzbl -0xfee8ce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004f2:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004f4:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004fa:	75 11                	jne    f010050d <cons_getc+0x48>
			cons.rpos = 0;
f01004fc:	c7 05 20 75 11 f0 00 	movl   $0x0,0xf0117520
f0100503:	00 00 00 
f0100506:	eb 05                	jmp    f010050d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100508:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010050d:	c9                   	leave  
f010050e:	c3                   	ret    

f010050f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010050f:	55                   	push   %ebp
f0100510:	89 e5                	mov    %esp,%ebp
f0100512:	57                   	push   %edi
f0100513:	56                   	push   %esi
f0100514:	53                   	push   %ebx
f0100515:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100518:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010051f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100526:	5a a5 
	if (*cp != 0xA55A) {
f0100528:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010052f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100533:	74 11                	je     f0100546 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100535:	c7 05 30 75 11 f0 b4 	movl   $0x3b4,0xf0117530
f010053c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010053f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f0100544:	eb 16                	jmp    f010055c <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100546:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010054d:	c7 05 30 75 11 f0 d4 	movl   $0x3d4,0xf0117530
f0100554:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100557:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010055c:	8b 0d 30 75 11 f0    	mov    0xf0117530,%ecx
f0100562:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100567:	89 ca                	mov    %ecx,%edx
f0100569:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010056a:	8d 59 01             	lea    0x1(%ecx),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056d:	89 da                	mov    %ebx,%edx
f010056f:	ec                   	in     (%dx),%al
f0100570:	0f b6 f0             	movzbl %al,%esi
f0100573:	c1 e6 08             	shl    $0x8,%esi
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100576:	b8 0f 00 00 00       	mov    $0xf,%eax
f010057b:	89 ca                	mov    %ecx,%edx
f010057d:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010057e:	89 da                	mov    %ebx,%edx
f0100580:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100581:	89 3d 2c 75 11 f0    	mov    %edi,0xf011752c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100587:	0f b6 d8             	movzbl %al,%ebx
f010058a:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f010058c:	66 89 35 28 75 11 f0 	mov    %si,0xf0117528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100593:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100598:	b8 00 00 00 00       	mov    $0x0,%eax
f010059d:	89 f2                	mov    %esi,%edx
f010059f:	ee                   	out    %al,(%dx)
f01005a0:	b2 fb                	mov    $0xfb,%dl
f01005a2:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005a7:	ee                   	out    %al,(%dx)
f01005a8:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005ad:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005b2:	89 da                	mov    %ebx,%edx
f01005b4:	ee                   	out    %al,(%dx)
f01005b5:	b2 f9                	mov    $0xf9,%dl
f01005b7:	b8 00 00 00 00       	mov    $0x0,%eax
f01005bc:	ee                   	out    %al,(%dx)
f01005bd:	b2 fb                	mov    $0xfb,%dl
f01005bf:	b8 03 00 00 00       	mov    $0x3,%eax
f01005c4:	ee                   	out    %al,(%dx)
f01005c5:	b2 fc                	mov    $0xfc,%dl
f01005c7:	b8 00 00 00 00       	mov    $0x0,%eax
f01005cc:	ee                   	out    %al,(%dx)
f01005cd:	b2 f9                	mov    $0xf9,%dl
f01005cf:	b8 01 00 00 00       	mov    $0x1,%eax
f01005d4:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005d5:	b2 fd                	mov    $0xfd,%dl
f01005d7:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005d8:	3c ff                	cmp    $0xff,%al
f01005da:	0f 95 c1             	setne  %cl
f01005dd:	88 0d 34 75 11 f0    	mov    %cl,0xf0117534
f01005e3:	89 f2                	mov    %esi,%edx
f01005e5:	ec                   	in     (%dx),%al
f01005e6:	89 da                	mov    %ebx,%edx
f01005e8:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005e9:	84 c9                	test   %cl,%cl
f01005eb:	75 0c                	jne    f01005f9 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f01005ed:	c7 04 24 b9 3d 10 f0 	movl   $0xf0103db9,(%esp)
f01005f4:	e8 6d 27 00 00       	call   f0102d66 <cprintf>
}
f01005f9:	83 c4 1c             	add    $0x1c,%esp
f01005fc:	5b                   	pop    %ebx
f01005fd:	5e                   	pop    %esi
f01005fe:	5f                   	pop    %edi
f01005ff:	5d                   	pop    %ebp
f0100600:	c3                   	ret    

f0100601 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100601:	55                   	push   %ebp
f0100602:	89 e5                	mov    %esp,%ebp
f0100604:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100607:	8b 45 08             	mov    0x8(%ebp),%eax
f010060a:	e8 a8 fc ff ff       	call   f01002b7 <cons_putc>
}
f010060f:	c9                   	leave  
f0100610:	c3                   	ret    

f0100611 <getchar>:

int
getchar(void)
{
f0100611:	55                   	push   %ebp
f0100612:	89 e5                	mov    %esp,%ebp
f0100614:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100617:	e8 a9 fe ff ff       	call   f01004c5 <cons_getc>
f010061c:	85 c0                	test   %eax,%eax
f010061e:	74 f7                	je     f0100617 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100620:	c9                   	leave  
f0100621:	c3                   	ret    

f0100622 <iscons>:

int
iscons(int fdnum)
{
f0100622:	55                   	push   %ebp
f0100623:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100625:	b8 01 00 00 00       	mov    $0x1,%eax
f010062a:	5d                   	pop    %ebp
f010062b:	c3                   	ret    
f010062c:	66 90                	xchg   %ax,%ax
f010062e:	66 90                	xchg   %ax,%ax

f0100630 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100630:	55                   	push   %ebp
f0100631:	89 e5                	mov    %esp,%ebp
f0100633:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100636:	c7 44 24 08 00 40 10 	movl   $0xf0104000,0x8(%esp)
f010063d:	f0 
f010063e:	c7 44 24 04 1e 40 10 	movl   $0xf010401e,0x4(%esp)
f0100645:	f0 
f0100646:	c7 04 24 23 40 10 f0 	movl   $0xf0104023,(%esp)
f010064d:	e8 14 27 00 00       	call   f0102d66 <cprintf>
f0100652:	c7 44 24 08 c4 40 10 	movl   $0xf01040c4,0x8(%esp)
f0100659:	f0 
f010065a:	c7 44 24 04 2c 40 10 	movl   $0xf010402c,0x4(%esp)
f0100661:	f0 
f0100662:	c7 04 24 23 40 10 f0 	movl   $0xf0104023,(%esp)
f0100669:	e8 f8 26 00 00       	call   f0102d66 <cprintf>
f010066e:	c7 44 24 08 35 40 10 	movl   $0xf0104035,0x8(%esp)
f0100675:	f0 
f0100676:	c7 44 24 04 53 40 10 	movl   $0xf0104053,0x4(%esp)
f010067d:	f0 
f010067e:	c7 04 24 23 40 10 f0 	movl   $0xf0104023,(%esp)
f0100685:	e8 dc 26 00 00       	call   f0102d66 <cprintf>
	return 0;
}
f010068a:	b8 00 00 00 00       	mov    $0x0,%eax
f010068f:	c9                   	leave  
f0100690:	c3                   	ret    

f0100691 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100691:	55                   	push   %ebp
f0100692:	89 e5                	mov    %esp,%ebp
f0100694:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100697:	c7 04 24 5d 40 10 f0 	movl   $0xf010405d,(%esp)
f010069e:	e8 c3 26 00 00       	call   f0102d66 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006a3:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006aa:	00 
f01006ab:	c7 04 24 ec 40 10 f0 	movl   $0xf01040ec,(%esp)
f01006b2:	e8 af 26 00 00       	call   f0102d66 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006b7:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006be:	00 
f01006bf:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006c6:	f0 
f01006c7:	c7 04 24 14 41 10 f0 	movl   $0xf0104114,(%esp)
f01006ce:	e8 93 26 00 00       	call   f0102d66 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006d3:	c7 44 24 08 47 3d 10 	movl   $0x103d47,0x8(%esp)
f01006da:	00 
f01006db:	c7 44 24 04 47 3d 10 	movl   $0xf0103d47,0x4(%esp)
f01006e2:	f0 
f01006e3:	c7 04 24 38 41 10 f0 	movl   $0xf0104138,(%esp)
f01006ea:	e8 77 26 00 00       	call   f0102d66 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ef:	c7 44 24 08 00 73 11 	movl   $0x117300,0x8(%esp)
f01006f6:	00 
f01006f7:	c7 44 24 04 00 73 11 	movl   $0xf0117300,0x4(%esp)
f01006fe:	f0 
f01006ff:	c7 04 24 5c 41 10 f0 	movl   $0xf010415c,(%esp)
f0100706:	e8 5b 26 00 00       	call   f0102d66 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010070b:	c7 44 24 08 70 79 11 	movl   $0x117970,0x8(%esp)
f0100712:	00 
f0100713:	c7 44 24 04 70 79 11 	movl   $0xf0117970,0x4(%esp)
f010071a:	f0 
f010071b:	c7 04 24 80 41 10 f0 	movl   $0xf0104180,(%esp)
f0100722:	e8 3f 26 00 00       	call   f0102d66 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100727:	b8 6f 7d 11 f0       	mov    $0xf0117d6f,%eax
f010072c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100731:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100736:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010073c:	85 c0                	test   %eax,%eax
f010073e:	0f 48 c2             	cmovs  %edx,%eax
f0100741:	c1 f8 0a             	sar    $0xa,%eax
f0100744:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100748:	c7 04 24 a4 41 10 f0 	movl   $0xf01041a4,(%esp)
f010074f:	e8 12 26 00 00       	call   f0102d66 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100754:	b8 00 00 00 00       	mov    $0x0,%eax
f0100759:	c9                   	leave  
f010075a:	c3                   	ret    

f010075b <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010075b:	55                   	push   %ebp
f010075c:	89 e5                	mov    %esp,%ebp
f010075e:	56                   	push   %esi
f010075f:	53                   	push   %ebx
f0100760:	83 ec 40             	sub    $0x40,%esp
      uint32_t  *x;
      x= (uint32_t *) read_ebp();   
f0100763:	89 eb                	mov    %ebp,%ebx
      struct Eipdebuginfo info;
      while(x)
     {

	 cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", x, x[1], x[2],x[3],x[4],x[5],x[6]);
         debuginfo_eip(x[1], &info);
f0100765:	8d 75 e0             	lea    -0x20(%ebp),%esi
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
      uint32_t  *x;
      x= (uint32_t *) read_ebp();   
      struct Eipdebuginfo info;
      while(x)
f0100768:	eb 7d                	jmp    f01007e7 <mon_backtrace+0x8c>
     {

	 cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", x, x[1], x[2],x[3],x[4],x[5],x[6]);
f010076a:	8b 43 18             	mov    0x18(%ebx),%eax
f010076d:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f0100771:	8b 43 14             	mov    0x14(%ebx),%eax
f0100774:	89 44 24 18          	mov    %eax,0x18(%esp)
f0100778:	8b 43 10             	mov    0x10(%ebx),%eax
f010077b:	89 44 24 14          	mov    %eax,0x14(%esp)
f010077f:	8b 43 0c             	mov    0xc(%ebx),%eax
f0100782:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100786:	8b 43 08             	mov    0x8(%ebx),%eax
f0100789:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010078d:	8b 43 04             	mov    0x4(%ebx),%eax
f0100790:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100794:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100798:	c7 04 24 d0 41 10 f0 	movl   $0xf01041d0,(%esp)
f010079f:	e8 c2 25 00 00       	call   f0102d66 <cprintf>
         debuginfo_eip(x[1], &info);
f01007a4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01007a8:	8b 43 04             	mov    0x4(%ebx),%eax
f01007ab:	89 04 24             	mov    %eax,(%esp)
f01007ae:	e8 aa 26 00 00       	call   f0102e5d <debuginfo_eip>
         cprintf("%s:%d:%.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,(x[1]- info.eip_fn_addr));
f01007b3:	8b 43 04             	mov    0x4(%ebx),%eax
f01007b6:	2b 45 f0             	sub    -0x10(%ebp),%eax
f01007b9:	89 44 24 14          	mov    %eax,0x14(%esp)
f01007bd:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01007c0:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007c4:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01007c7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007cb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01007ce:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007d2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01007d5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007d9:	c7 04 24 76 40 10 f0 	movl   $0xf0104076,(%esp)
f01007e0:	e8 81 25 00 00       	call   f0102d66 <cprintf>
         
	 x=(uint32_t *)x[0];
f01007e5:	8b 1b                	mov    (%ebx),%ebx
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
      uint32_t  *x;
      x= (uint32_t *) read_ebp();   
      struct Eipdebuginfo info;
      while(x)
f01007e7:	85 db                	test   %ebx,%ebx
f01007e9:	0f 85 7b ff ff ff    	jne    f010076a <mon_backtrace+0xf>
	 x=(uint32_t *)x[0];

	}	      
     // Your code here.
	return 0;
}
f01007ef:	b8 00 00 00 00       	mov    $0x0,%eax
f01007f4:	83 c4 40             	add    $0x40,%esp
f01007f7:	5b                   	pop    %ebx
f01007f8:	5e                   	pop    %esi
f01007f9:	5d                   	pop    %ebp
f01007fa:	c3                   	ret    

f01007fb <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007fb:	55                   	push   %ebp
f01007fc:	89 e5                	mov    %esp,%ebp
f01007fe:	57                   	push   %edi
f01007ff:	56                   	push   %esi
f0100800:	53                   	push   %ebx
f0100801:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100804:	c7 04 24 04 42 10 f0 	movl   $0xf0104204,(%esp)
f010080b:	e8 56 25 00 00       	call   f0102d66 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100810:	c7 04 24 28 42 10 f0 	movl   $0xf0104228,(%esp)
f0100817:	e8 4a 25 00 00       	call   f0102d66 <cprintf>


	while (1) {
		buf = readline("K> ");
f010081c:	c7 04 24 85 40 10 f0 	movl   $0xf0104085,(%esp)
f0100823:	e8 38 2e 00 00       	call   f0103660 <readline>
f0100828:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f010082a:	85 c0                	test   %eax,%eax
f010082c:	74 ee                	je     f010081c <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010082e:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100835:	be 00 00 00 00       	mov    $0x0,%esi
f010083a:	eb 0a                	jmp    f0100846 <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010083c:	c6 03 00             	movb   $0x0,(%ebx)
f010083f:	89 f7                	mov    %esi,%edi
f0100841:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100844:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100846:	0f b6 03             	movzbl (%ebx),%eax
f0100849:	84 c0                	test   %al,%al
f010084b:	74 63                	je     f01008b0 <monitor+0xb5>
f010084d:	0f be c0             	movsbl %al,%eax
f0100850:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100854:	c7 04 24 89 40 10 f0 	movl   $0xf0104089,(%esp)
f010085b:	e8 1a 30 00 00       	call   f010387a <strchr>
f0100860:	85 c0                	test   %eax,%eax
f0100862:	75 d8                	jne    f010083c <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f0100864:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100867:	74 47                	je     f01008b0 <monitor+0xb5>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100869:	83 fe 0f             	cmp    $0xf,%esi
f010086c:	75 16                	jne    f0100884 <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010086e:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100875:	00 
f0100876:	c7 04 24 8e 40 10 f0 	movl   $0xf010408e,(%esp)
f010087d:	e8 e4 24 00 00       	call   f0102d66 <cprintf>
f0100882:	eb 98                	jmp    f010081c <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f0100884:	8d 7e 01             	lea    0x1(%esi),%edi
f0100887:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010088b:	eb 03                	jmp    f0100890 <monitor+0x95>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010088d:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100890:	0f b6 03             	movzbl (%ebx),%eax
f0100893:	84 c0                	test   %al,%al
f0100895:	74 ad                	je     f0100844 <monitor+0x49>
f0100897:	0f be c0             	movsbl %al,%eax
f010089a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010089e:	c7 04 24 89 40 10 f0 	movl   $0xf0104089,(%esp)
f01008a5:	e8 d0 2f 00 00       	call   f010387a <strchr>
f01008aa:	85 c0                	test   %eax,%eax
f01008ac:	74 df                	je     f010088d <monitor+0x92>
f01008ae:	eb 94                	jmp    f0100844 <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f01008b0:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008b7:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008b8:	85 f6                	test   %esi,%esi
f01008ba:	0f 84 5c ff ff ff    	je     f010081c <monitor+0x21>
f01008c0:	bb 00 00 00 00       	mov    $0x0,%ebx
f01008c5:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008c8:	8b 04 85 60 42 10 f0 	mov    -0xfefbda0(,%eax,4),%eax
f01008cf:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008d3:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008d6:	89 04 24             	mov    %eax,(%esp)
f01008d9:	e8 3e 2f 00 00       	call   f010381c <strcmp>
f01008de:	85 c0                	test   %eax,%eax
f01008e0:	75 24                	jne    f0100906 <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f01008e2:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008e5:	8b 55 08             	mov    0x8(%ebp),%edx
f01008e8:	89 54 24 08          	mov    %edx,0x8(%esp)
f01008ec:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f01008ef:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01008f3:	89 34 24             	mov    %esi,(%esp)
f01008f6:	ff 14 85 68 42 10 f0 	call   *-0xfefbd98(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008fd:	85 c0                	test   %eax,%eax
f01008ff:	78 25                	js     f0100926 <monitor+0x12b>
f0100901:	e9 16 ff ff ff       	jmp    f010081c <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100906:	83 c3 01             	add    $0x1,%ebx
f0100909:	83 fb 03             	cmp    $0x3,%ebx
f010090c:	75 b7                	jne    f01008c5 <monitor+0xca>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f010090e:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100911:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100915:	c7 04 24 ab 40 10 f0 	movl   $0xf01040ab,(%esp)
f010091c:	e8 45 24 00 00       	call   f0102d66 <cprintf>
f0100921:	e9 f6 fe ff ff       	jmp    f010081c <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100926:	83 c4 5c             	add    $0x5c,%esp
f0100929:	5b                   	pop    %ebx
f010092a:	5e                   	pop    %esi
f010092b:	5f                   	pop    %edi
f010092c:	5d                   	pop    %ebp
f010092d:	c3                   	ret    

f010092e <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f010092e:	55                   	push   %ebp
f010092f:	89 e5                	mov    %esp,%ebp
f0100931:	56                   	push   %esi
f0100932:	53                   	push   %ebx
f0100933:	83 ec 10             	sub    $0x10,%esp
f0100936:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100938:	89 04 24             	mov    %eax,(%esp)
f010093b:	e8 b6 23 00 00       	call   f0102cf6 <mc146818_read>
f0100940:	89 c6                	mov    %eax,%esi
f0100942:	83 c3 01             	add    $0x1,%ebx
f0100945:	89 1c 24             	mov    %ebx,(%esp)
f0100948:	e8 a9 23 00 00       	call   f0102cf6 <mc146818_read>
f010094d:	c1 e0 08             	shl    $0x8,%eax
f0100950:	09 f0                	or     %esi,%eax
}
f0100952:	83 c4 10             	add    $0x10,%esp
f0100955:	5b                   	pop    %ebx
f0100956:	5e                   	pop    %esi
f0100957:	5d                   	pop    %ebp
f0100958:	c3                   	ret    

f0100959 <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100959:	83 3d 38 75 11 f0 00 	cmpl   $0x0,0xf0117538
f0100960:	75 11                	jne    f0100973 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100962:	ba 6f 89 11 f0       	mov    $0xf011896f,%edx
f0100967:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010096d:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
	//
	// LAB 2: Your code here.
	
	
	
	if(n>0)
f0100973:	85 c0                	test   %eax,%eax
f0100975:	74 2e                	je     f01009a5 <boot_alloc+0x4c>
	{
	result=nextfree;
f0100977:	8b 0d 38 75 11 f0    	mov    0xf0117538,%ecx
	nextfree +=ROUNDUP(n, PGSIZE);
f010097d:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100983:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100989:	01 ca                	add    %ecx,%edx
f010098b:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
	else
	{
	return nextfree;	
    }
    
    if ((uint32_t) nextfree> ((npages * PGSIZE)+KERNBASE))
f0100991:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0100996:	05 00 00 0f 00       	add    $0xf0000,%eax
f010099b:	c1 e0 0c             	shl    $0xc,%eax
f010099e:	39 c2                	cmp    %eax,%edx
f01009a0:	77 09                	ja     f01009ab <boot_alloc+0x52>
    {
    panic("Out of memory \n");
    }

	return result;
f01009a2:	89 c8                	mov    %ecx,%eax
f01009a4:	c3                   	ret    
	nextfree +=ROUNDUP(n, PGSIZE);
	
	}
	else
	{
	return nextfree;	
f01009a5:	a1 38 75 11 f0       	mov    0xf0117538,%eax
f01009aa:	c3                   	ret    
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01009ab:	55                   	push   %ebp
f01009ac:	89 e5                	mov    %esp,%ebp
f01009ae:	83 ec 18             	sub    $0x18,%esp
	return nextfree;	
    }
    
    if ((uint32_t) nextfree> ((npages * PGSIZE)+KERNBASE))
    {
    panic("Out of memory \n");
f01009b1:	c7 44 24 08 84 42 10 	movl   $0xf0104284,0x8(%esp)
f01009b8:	f0 
f01009b9:	c7 44 24 04 7b 00 00 	movl   $0x7b,0x4(%esp)
f01009c0:	00 
f01009c1:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f01009c8:	e8 c7 f6 ff ff       	call   f0100094 <_panic>

f01009cd <page2kva>:
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01009cd:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01009d3:	c1 f8 03             	sar    $0x3,%eax
f01009d6:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01009d9:	89 c2                	mov    %eax,%edx
f01009db:	c1 ea 0c             	shr    $0xc,%edx
f01009de:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f01009e4:	72 26                	jb     f0100a0c <page2kva+0x3f>
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f01009e6:	55                   	push   %ebp
f01009e7:	89 e5                	mov    %esp,%ebp
f01009e9:	83 ec 18             	sub    $0x18,%esp

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01009ec:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009f0:	c7 44 24 08 8c 45 10 	movl   $0xf010458c,0x8(%esp)
f01009f7:	f0 
f01009f8:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01009ff:	00 
f0100a00:	c7 04 24 a0 42 10 f0 	movl   $0xf01042a0,(%esp)
f0100a07:	e8 88 f6 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100a0c:	2d 00 00 00 10       	sub    $0x10000000,%eax

static inline void*
page2kva(struct PageInfo *pp)
{
	return KADDR(page2pa(pp));
}
f0100a11:	c3                   	ret    

f0100a12 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100a12:	89 d1                	mov    %edx,%ecx
f0100a14:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100a17:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100a1a:	a8 01                	test   $0x1,%al
f0100a1c:	74 5d                	je     f0100a7b <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100a1e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a23:	89 c1                	mov    %eax,%ecx
f0100a25:	c1 e9 0c             	shr    $0xc,%ecx
f0100a28:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f0100a2e:	72 26                	jb     f0100a56 <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100a30:	55                   	push   %ebp
f0100a31:	89 e5                	mov    %esp,%ebp
f0100a33:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a36:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a3a:	c7 44 24 08 8c 45 10 	movl   $0xf010458c,0x8(%esp)
f0100a41:	f0 
f0100a42:	c7 44 24 04 f3 02 00 	movl   $0x2f3,0x4(%esp)
f0100a49:	00 
f0100a4a:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0100a51:	e8 3e f6 ff ff       	call   f0100094 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100a56:	c1 ea 0c             	shr    $0xc,%edx
f0100a59:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100a5f:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100a66:	89 c2                	mov    %eax,%edx
f0100a68:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100a6b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a70:	85 d2                	test   %edx,%edx
f0100a72:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100a77:	0f 44 c2             	cmove  %edx,%eax
f0100a7a:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100a7b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100a80:	c3                   	ret    

f0100a81 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a81:	55                   	push   %ebp
f0100a82:	89 e5                	mov    %esp,%ebp
f0100a84:	57                   	push   %edi
f0100a85:	56                   	push   %esi
f0100a86:	53                   	push   %ebx
f0100a87:	83 ec 4c             	sub    $0x4c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a8a:	84 c0                	test   %al,%al
f0100a8c:	0f 85 07 03 00 00    	jne    f0100d99 <check_page_free_list+0x318>
f0100a92:	e9 14 03 00 00       	jmp    f0100dab <check_page_free_list+0x32a>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100a97:	c7 44 24 08 b0 45 10 	movl   $0xf01045b0,0x8(%esp)
f0100a9e:	f0 
f0100a9f:	c7 44 24 04 36 02 00 	movl   $0x236,0x4(%esp)
f0100aa6:	00 
f0100aa7:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0100aae:	e8 e1 f5 ff ff       	call   f0100094 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100ab3:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100ab6:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100ab9:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100abc:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100abf:	89 c2                	mov    %eax,%edx
f0100ac1:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100ac7:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100acd:	0f 95 c2             	setne  %dl
f0100ad0:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100ad3:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100ad7:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100ad9:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100add:	8b 00                	mov    (%eax),%eax
f0100adf:	85 c0                	test   %eax,%eax
f0100ae1:	75 dc                	jne    f0100abf <check_page_free_list+0x3e>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100ae3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ae6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100aec:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100aef:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100af2:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100af4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100af7:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100afc:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b01:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100b07:	eb 63                	jmp    f0100b6c <check_page_free_list+0xeb>
f0100b09:	89 d8                	mov    %ebx,%eax
f0100b0b:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100b11:	c1 f8 03             	sar    $0x3,%eax
f0100b14:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100b17:	89 c2                	mov    %eax,%edx
f0100b19:	c1 ea 16             	shr    $0x16,%edx
f0100b1c:	39 f2                	cmp    %esi,%edx
f0100b1e:	73 4a                	jae    f0100b6a <check_page_free_list+0xe9>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b20:	89 c2                	mov    %eax,%edx
f0100b22:	c1 ea 0c             	shr    $0xc,%edx
f0100b25:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100b2b:	72 20                	jb     f0100b4d <check_page_free_list+0xcc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b2d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b31:	c7 44 24 08 8c 45 10 	movl   $0xf010458c,0x8(%esp)
f0100b38:	f0 
f0100b39:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100b40:	00 
f0100b41:	c7 04 24 a0 42 10 f0 	movl   $0xf01042a0,(%esp)
f0100b48:	e8 47 f5 ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b4d:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100b54:	00 
f0100b55:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100b5c:	00 
	return (void *)(pa + KERNBASE);
f0100b5d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b62:	89 04 24             	mov    %eax,(%esp)
f0100b65:	e8 4d 2d 00 00       	call   f01038b7 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b6a:	8b 1b                	mov    (%ebx),%ebx
f0100b6c:	85 db                	test   %ebx,%ebx
f0100b6e:	75 99                	jne    f0100b09 <check_page_free_list+0x88>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100b70:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b75:	e8 df fd ff ff       	call   f0100959 <boot_alloc>
f0100b7a:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b7d:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b83:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
		assert(pp < pages + npages);
f0100b89:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0100b8e:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100b91:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100b94:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b97:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100b9a:	bf 00 00 00 00       	mov    $0x0,%edi
f0100b9f:	89 5d cc             	mov    %ebx,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ba2:	e9 97 01 00 00       	jmp    f0100d3e <check_page_free_list+0x2bd>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ba7:	39 ca                	cmp    %ecx,%edx
f0100ba9:	73 24                	jae    f0100bcf <check_page_free_list+0x14e>
f0100bab:	c7 44 24 0c ae 42 10 	movl   $0xf01042ae,0xc(%esp)
f0100bb2:	f0 
f0100bb3:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0100bba:	f0 
f0100bbb:	c7 44 24 04 50 02 00 	movl   $0x250,0x4(%esp)
f0100bc2:	00 
f0100bc3:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0100bca:	e8 c5 f4 ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0100bcf:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100bd2:	72 24                	jb     f0100bf8 <check_page_free_list+0x177>
f0100bd4:	c7 44 24 0c cf 42 10 	movl   $0xf01042cf,0xc(%esp)
f0100bdb:	f0 
f0100bdc:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0100be3:	f0 
f0100be4:	c7 44 24 04 51 02 00 	movl   $0x251,0x4(%esp)
f0100beb:	00 
f0100bec:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0100bf3:	e8 9c f4 ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100bf8:	89 d0                	mov    %edx,%eax
f0100bfa:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100bfd:	a8 07                	test   $0x7,%al
f0100bff:	74 24                	je     f0100c25 <check_page_free_list+0x1a4>
f0100c01:	c7 44 24 0c d4 45 10 	movl   $0xf01045d4,0xc(%esp)
f0100c08:	f0 
f0100c09:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0100c10:	f0 
f0100c11:	c7 44 24 04 52 02 00 	movl   $0x252,0x4(%esp)
f0100c18:	00 
f0100c19:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0100c20:	e8 6f f4 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c25:	c1 f8 03             	sar    $0x3,%eax
f0100c28:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c2b:	85 c0                	test   %eax,%eax
f0100c2d:	75 24                	jne    f0100c53 <check_page_free_list+0x1d2>
f0100c2f:	c7 44 24 0c e3 42 10 	movl   $0xf01042e3,0xc(%esp)
f0100c36:	f0 
f0100c37:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0100c3e:	f0 
f0100c3f:	c7 44 24 04 55 02 00 	movl   $0x255,0x4(%esp)
f0100c46:	00 
f0100c47:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0100c4e:	e8 41 f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c53:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c58:	75 24                	jne    f0100c7e <check_page_free_list+0x1fd>
f0100c5a:	c7 44 24 0c f4 42 10 	movl   $0xf01042f4,0xc(%esp)
f0100c61:	f0 
f0100c62:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0100c69:	f0 
f0100c6a:	c7 44 24 04 56 02 00 	movl   $0x256,0x4(%esp)
f0100c71:	00 
f0100c72:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0100c79:	e8 16 f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c7e:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c83:	75 24                	jne    f0100ca9 <check_page_free_list+0x228>
f0100c85:	c7 44 24 0c 08 46 10 	movl   $0xf0104608,0xc(%esp)
f0100c8c:	f0 
f0100c8d:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0100c94:	f0 
f0100c95:	c7 44 24 04 57 02 00 	movl   $0x257,0x4(%esp)
f0100c9c:	00 
f0100c9d:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0100ca4:	e8 eb f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100ca9:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100cae:	75 24                	jne    f0100cd4 <check_page_free_list+0x253>
f0100cb0:	c7 44 24 0c 0d 43 10 	movl   $0xf010430d,0xc(%esp)
f0100cb7:	f0 
f0100cb8:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0100cbf:	f0 
f0100cc0:	c7 44 24 04 58 02 00 	movl   $0x258,0x4(%esp)
f0100cc7:	00 
f0100cc8:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0100ccf:	e8 c0 f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100cd4:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100cd9:	76 58                	jbe    f0100d33 <check_page_free_list+0x2b2>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100cdb:	89 c3                	mov    %eax,%ebx
f0100cdd:	c1 eb 0c             	shr    $0xc,%ebx
f0100ce0:	39 5d c4             	cmp    %ebx,-0x3c(%ebp)
f0100ce3:	77 20                	ja     f0100d05 <check_page_free_list+0x284>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ce5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ce9:	c7 44 24 08 8c 45 10 	movl   $0xf010458c,0x8(%esp)
f0100cf0:	f0 
f0100cf1:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100cf8:	00 
f0100cf9:	c7 04 24 a0 42 10 f0 	movl   $0xf01042a0,(%esp)
f0100d00:	e8 8f f3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100d05:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d0a:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100d0d:	76 2a                	jbe    f0100d39 <check_page_free_list+0x2b8>
f0100d0f:	c7 44 24 0c 2c 46 10 	movl   $0xf010462c,0xc(%esp)
f0100d16:	f0 
f0100d17:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0100d1e:	f0 
f0100d1f:	c7 44 24 04 59 02 00 	movl   $0x259,0x4(%esp)
f0100d26:	00 
f0100d27:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0100d2e:	e8 61 f3 ff ff       	call   f0100094 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d33:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
f0100d37:	eb 03                	jmp    f0100d3c <check_page_free_list+0x2bb>
		else
			++nfree_extmem;
f0100d39:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d3c:	8b 12                	mov    (%edx),%edx
f0100d3e:	85 d2                	test   %edx,%edx
f0100d40:	0f 85 61 fe ff ff    	jne    f0100ba7 <check_page_free_list+0x126>
f0100d46:	8b 5d cc             	mov    -0x34(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100d49:	85 db                	test   %ebx,%ebx
f0100d4b:	7f 24                	jg     f0100d71 <check_page_free_list+0x2f0>
f0100d4d:	c7 44 24 0c 27 43 10 	movl   $0xf0104327,0xc(%esp)
f0100d54:	f0 
f0100d55:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0100d5c:	f0 
f0100d5d:	c7 44 24 04 61 02 00 	movl   $0x261,0x4(%esp)
f0100d64:	00 
f0100d65:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0100d6c:	e8 23 f3 ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f0100d71:	85 ff                	test   %edi,%edi
f0100d73:	7f 4d                	jg     f0100dc2 <check_page_free_list+0x341>
f0100d75:	c7 44 24 0c 39 43 10 	movl   $0xf0104339,0xc(%esp)
f0100d7c:	f0 
f0100d7d:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0100d84:	f0 
f0100d85:	c7 44 24 04 62 02 00 	movl   $0x262,0x4(%esp)
f0100d8c:	00 
f0100d8d:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0100d94:	e8 fb f2 ff ff       	call   f0100094 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100d99:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0100d9e:	85 c0                	test   %eax,%eax
f0100da0:	0f 85 0d fd ff ff    	jne    f0100ab3 <check_page_free_list+0x32>
f0100da6:	e9 ec fc ff ff       	jmp    f0100a97 <check_page_free_list+0x16>
f0100dab:	83 3d 3c 75 11 f0 00 	cmpl   $0x0,0xf011753c
f0100db2:	0f 84 df fc ff ff    	je     f0100a97 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100db8:	be 00 04 00 00       	mov    $0x400,%esi
f0100dbd:	e9 3f fd ff ff       	jmp    f0100b01 <check_page_free_list+0x80>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100dc2:	83 c4 4c             	add    $0x4c,%esp
f0100dc5:	5b                   	pop    %ebx
f0100dc6:	5e                   	pop    %esi
f0100dc7:	5f                   	pop    %edi
f0100dc8:	5d                   	pop    %ebp
f0100dc9:	c3                   	ret    

f0100dca <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100dca:	55                   	push   %ebp
f0100dcb:	89 e5                	mov    %esp,%ebp
f0100dcd:	53                   	push   %ebx
f0100dce:	83 ec 04             	sub    $0x4,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100dd1:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100dd6:	eb 4d                	jmp    f0100e25 <page_init+0x5b>
	if(i==0 ||(i>=(IOPHYSMEM/PGSIZE)&&i<=(((uint32_t)boot_alloc(0)-KERNBASE)/PGSIZE)))
f0100dd8:	85 db                	test   %ebx,%ebx
f0100dda:	74 46                	je     f0100e22 <page_init+0x58>
f0100ddc:	81 fb 9f 00 00 00    	cmp    $0x9f,%ebx
f0100de2:	76 16                	jbe    f0100dfa <page_init+0x30>
f0100de4:	b8 00 00 00 00       	mov    $0x0,%eax
f0100de9:	e8 6b fb ff ff       	call   f0100959 <boot_alloc>
f0100dee:	05 00 00 00 10       	add    $0x10000000,%eax
f0100df3:	c1 e8 0c             	shr    $0xc,%eax
f0100df6:	39 c3                	cmp    %eax,%ebx
f0100df8:	76 28                	jbe    f0100e22 <page_init+0x58>
f0100dfa:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
	continue;

		pages[i].pp_ref = 0;
f0100e01:	89 c2                	mov    %eax,%edx
f0100e03:	03 15 6c 79 11 f0    	add    0xf011796c,%edx
f0100e09:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
		pages[i].pp_link = page_free_list;
f0100e0f:	8b 0d 3c 75 11 f0    	mov    0xf011753c,%ecx
f0100e15:	89 0a                	mov    %ecx,(%edx)
		page_free_list = &pages[i];
f0100e17:	03 05 6c 79 11 f0    	add    0xf011796c,%eax
f0100e1d:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100e22:	83 c3 01             	add    $0x1,%ebx
f0100e25:	3b 1d 64 79 11 f0    	cmp    0xf0117964,%ebx
f0100e2b:	72 ab                	jb     f0100dd8 <page_init+0xe>
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	
	}
}
f0100e2d:	83 c4 04             	add    $0x4,%esp
f0100e30:	5b                   	pop    %ebx
f0100e31:	5d                   	pop    %ebp
f0100e32:	c3                   	ret    

f0100e33 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100e33:	55                   	push   %ebp
f0100e34:	89 e5                	mov    %esp,%ebp
f0100e36:	53                   	push   %ebx
f0100e37:	83 ec 14             	sub    $0x14,%esp
	struct PageInfo *tempage;
	
	if (page_free_list == NULL)
f0100e3a:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100e40:	85 db                	test   %ebx,%ebx
f0100e42:	74 6f                	je     f0100eb3 <page_alloc+0x80>
		return NULL;

  	tempage= page_free_list;
  	page_free_list = tempage->pp_link;
f0100e44:	8b 03                	mov    (%ebx),%eax
f0100e46:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
  	tempage->pp_link = NULL;
f0100e4b:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)

	if (alloc_flags & ALLOC_ZERO)
		memset(page2kva(tempage), 0, PGSIZE); 

  	return tempage;
f0100e51:	89 d8                	mov    %ebx,%eax

  	tempage= page_free_list;
  	page_free_list = tempage->pp_link;
  	tempage->pp_link = NULL;

	if (alloc_flags & ALLOC_ZERO)
f0100e53:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100e57:	74 5f                	je     f0100eb8 <page_alloc+0x85>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100e59:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100e5f:	c1 f8 03             	sar    $0x3,%eax
f0100e62:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e65:	89 c2                	mov    %eax,%edx
f0100e67:	c1 ea 0c             	shr    $0xc,%edx
f0100e6a:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100e70:	72 20                	jb     f0100e92 <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e72:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e76:	c7 44 24 08 8c 45 10 	movl   $0xf010458c,0x8(%esp)
f0100e7d:	f0 
f0100e7e:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100e85:	00 
f0100e86:	c7 04 24 a0 42 10 f0 	movl   $0xf01042a0,(%esp)
f0100e8d:	e8 02 f2 ff ff       	call   f0100094 <_panic>
		memset(page2kva(tempage), 0, PGSIZE); 
f0100e92:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100e99:	00 
f0100e9a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100ea1:	00 
	return (void *)(pa + KERNBASE);
f0100ea2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ea7:	89 04 24             	mov    %eax,(%esp)
f0100eaa:	e8 08 2a 00 00       	call   f01038b7 <memset>

  	return tempage;
f0100eaf:	89 d8                	mov    %ebx,%eax
f0100eb1:	eb 05                	jmp    f0100eb8 <page_alloc+0x85>
page_alloc(int alloc_flags)
{
	struct PageInfo *tempage;
	
	if (page_free_list == NULL)
		return NULL;
f0100eb3:	b8 00 00 00 00       	mov    $0x0,%eax
		memset(page2kva(tempage), 0, PGSIZE); 

  	return tempage;
	

}
f0100eb8:	83 c4 14             	add    $0x14,%esp
f0100ebb:	5b                   	pop    %ebx
f0100ebc:	5d                   	pop    %ebp
f0100ebd:	c3                   	ret    

f0100ebe <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100ebe:	55                   	push   %ebp
f0100ebf:	89 e5                	mov    %esp,%ebp
f0100ec1:	83 ec 18             	sub    $0x18,%esp
f0100ec4:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if(pp->pp_ref==0)
f0100ec7:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100ecc:	75 0f                	jne    f0100edd <page_free+0x1f>
	{
	pp->pp_link=page_free_list;
f0100ece:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100ed4:	89 10                	mov    %edx,(%eax)
	page_free_list=pp;	
f0100ed6:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
f0100edb:	eb 1c                	jmp    f0100ef9 <page_free+0x3b>
	}
	else
	panic("page ref not zero \n");
f0100edd:	c7 44 24 08 4a 43 10 	movl   $0xf010434a,0x8(%esp)
f0100ee4:	f0 
f0100ee5:	c7 44 24 04 59 01 00 	movl   $0x159,0x4(%esp)
f0100eec:	00 
f0100eed:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0100ef4:	e8 9b f1 ff ff       	call   f0100094 <_panic>
}
f0100ef9:	c9                   	leave  
f0100efa:	c3                   	ret    

f0100efb <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100efb:	55                   	push   %ebp
f0100efc:	89 e5                	mov    %esp,%ebp
f0100efe:	83 ec 18             	sub    $0x18,%esp
f0100f01:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100f04:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f0100f08:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0100f0b:	66 89 50 04          	mov    %dx,0x4(%eax)
f0100f0f:	66 85 d2             	test   %dx,%dx
f0100f12:	75 08                	jne    f0100f1c <page_decref+0x21>
		page_free(pp);
f0100f14:	89 04 24             	mov    %eax,(%esp)
f0100f17:	e8 a2 ff ff ff       	call   f0100ebe <page_free>
}
f0100f1c:	c9                   	leave  
f0100f1d:	c3                   	ret    

f0100f1e <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100f1e:	55                   	push   %ebp
f0100f1f:	89 e5                	mov    %esp,%ebp
f0100f21:	57                   	push   %edi
f0100f22:	56                   	push   %esi
f0100f23:	53                   	push   %ebx
f0100f24:	83 ec 1c             	sub    $0x1c,%esp
f0100f27:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	  pde_t * pde; //va(virtual address) point to pa(physical address)
	  pte_t * pgtable; //same as pde
	  struct PageInfo *pp;

	  pde = &pgdir[PDX(va)]; // va->pgdir
f0100f2a:	89 de                	mov    %ebx,%esi
f0100f2c:	c1 ee 16             	shr    $0x16,%esi
f0100f2f:	c1 e6 02             	shl    $0x2,%esi
f0100f32:	03 75 08             	add    0x8(%ebp),%esi
	  if(*pde & PTE_P) { 
f0100f35:	8b 06                	mov    (%esi),%eax
f0100f37:	a8 01                	test   $0x1,%al
f0100f39:	74 3d                	je     f0100f78 <pgdir_walk+0x5a>
	  	pgtable = (KADDR(PTE_ADDR(*pde)));
f0100f3b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f40:	89 c2                	mov    %eax,%edx
f0100f42:	c1 ea 0c             	shr    $0xc,%edx
f0100f45:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100f4b:	72 20                	jb     f0100f6d <pgdir_walk+0x4f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f4d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f51:	c7 44 24 08 8c 45 10 	movl   $0xf010458c,0x8(%esp)
f0100f58:	f0 
f0100f59:	c7 44 24 04 86 01 00 	movl   $0x186,0x4(%esp)
f0100f60:	00 
f0100f61:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0100f68:	e8 27 f1 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100f6d:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx
f0100f73:	e9 97 00 00 00       	jmp    f010100f <pgdir_walk+0xf1>
	  } else {
		//page table page not exist
		if(!create || 
f0100f78:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100f7c:	0f 84 9b 00 00 00    	je     f010101d <pgdir_walk+0xff>
f0100f82:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0100f89:	e8 a5 fe ff ff       	call   f0100e33 <page_alloc>
f0100f8e:	85 c0                	test   %eax,%eax
f0100f90:	0f 84 8e 00 00 00    	je     f0101024 <pgdir_walk+0x106>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f96:	89 c1                	mov    %eax,%ecx
f0100f98:	2b 0d 6c 79 11 f0    	sub    0xf011796c,%ecx
f0100f9e:	c1 f9 03             	sar    $0x3,%ecx
f0100fa1:	c1 e1 0c             	shl    $0xc,%ecx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fa4:	89 ca                	mov    %ecx,%edx
f0100fa6:	c1 ea 0c             	shr    $0xc,%edx
f0100fa9:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100faf:	72 20                	jb     f0100fd1 <pgdir_walk+0xb3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fb1:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100fb5:	c7 44 24 08 8c 45 10 	movl   $0xf010458c,0x8(%esp)
f0100fbc:	f0 
f0100fbd:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100fc4:	00 
f0100fc5:	c7 04 24 a0 42 10 f0 	movl   $0xf01042a0,(%esp)
f0100fcc:	e8 c3 f0 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100fd1:	8d b9 00 00 00 f0    	lea    -0x10000000(%ecx),%edi
f0100fd7:	89 fa                	mov    %edi,%edx
		   !(pp = page_alloc(ALLOC_ZERO)) ||
f0100fd9:	85 ff                	test   %edi,%edi
f0100fdb:	74 4e                	je     f010102b <pgdir_walk+0x10d>
		   !(pgtable = (pte_t*)page2kva(pp))) 
			return NULL;
		    
		pp->pp_ref++;
f0100fdd:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100fe2:	81 ff ff ff ff ef    	cmp    $0xefffffff,%edi
f0100fe8:	77 20                	ja     f010100a <pgdir_walk+0xec>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100fea:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0100fee:	c7 44 24 08 74 46 10 	movl   $0xf0104674,0x8(%esp)
f0100ff5:	f0 
f0100ff6:	c7 44 24 04 8f 01 00 	movl   $0x18f,0x4(%esp)
f0100ffd:	00 
f0100ffe:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101005:	e8 8a f0 ff ff       	call   f0100094 <_panic>
		*pde = PADDR(pgtable) | PTE_P | PTE_W | PTE_U;
f010100a:	83 c9 07             	or     $0x7,%ecx
f010100d:	89 0e                	mov    %ecx,(%esi)
	}

	return &pgtable[PTX(va)];
f010100f:	c1 eb 0a             	shr    $0xa,%ebx
f0101012:	89 d8                	mov    %ebx,%eax
f0101014:	25 fc 0f 00 00       	and    $0xffc,%eax
f0101019:	01 d0                	add    %edx,%eax
f010101b:	eb 13                	jmp    f0101030 <pgdir_walk+0x112>
	  } else {
		//page table page not exist
		if(!create || 
		   !(pp = page_alloc(ALLOC_ZERO)) ||
		   !(pgtable = (pte_t*)page2kva(pp))) 
			return NULL;
f010101d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101022:	eb 0c                	jmp    f0101030 <pgdir_walk+0x112>
f0101024:	b8 00 00 00 00       	mov    $0x0,%eax
f0101029:	eb 05                	jmp    f0101030 <pgdir_walk+0x112>
f010102b:	b8 00 00 00 00       	mov    $0x0,%eax
		pp->pp_ref++;
		*pde = PADDR(pgtable) | PTE_P | PTE_W | PTE_U;
	}

	return &pgtable[PTX(va)];
}
f0101030:	83 c4 1c             	add    $0x1c,%esp
f0101033:	5b                   	pop    %ebx
f0101034:	5e                   	pop    %esi
f0101035:	5f                   	pop    %edi
f0101036:	5d                   	pop    %ebp
f0101037:	c3                   	ret    

f0101038 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0101038:	55                   	push   %ebp
f0101039:	89 e5                	mov    %esp,%ebp
f010103b:	57                   	push   %edi
f010103c:	56                   	push   %esi
f010103d:	53                   	push   %ebx
f010103e:	83 ec 2c             	sub    $0x2c,%esp
f0101041:	89 45 dc             	mov    %eax,-0x24(%ebp)
	uint32_t x;
	uint32_t i=0;
	pte_t * pt; 
	x=size/PGSIZE;
f0101044:	c1 e9 0c             	shr    $0xc,%ecx
f0101047:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	while(i<x)
f010104a:	89 d3                	mov    %edx,%ebx
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	uint32_t x;
	uint32_t i=0;
f010104c:	be 00 00 00 00       	mov    $0x0,%esi
f0101051:	8b 45 08             	mov    0x8(%ebp),%eax
f0101054:	29 d0                	sub    %edx,%eax
f0101056:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pte_t * pt; 
	x=size/PGSIZE;
	while(i<x)
	{
		pt=pgdir_walk(pgdir,(void*)va,1);
		*pt=(PTE_ADDR(pa) | perm | PTE_P);
f0101059:	8b 45 0c             	mov    0xc(%ebp),%eax
f010105c:	83 c8 01             	or     $0x1,%eax
f010105f:	89 45 d8             	mov    %eax,-0x28(%ebp)
{
	uint32_t x;
	uint32_t i=0;
	pte_t * pt; 
	x=size/PGSIZE;
	while(i<x)
f0101062:	eb 2b                	jmp    f010108f <boot_map_region+0x57>
	{
		pt=pgdir_walk(pgdir,(void*)va,1);
f0101064:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010106b:	00 
f010106c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101070:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101073:	89 04 24             	mov    %eax,(%esp)
f0101076:	e8 a3 fe ff ff       	call   f0100f1e <pgdir_walk>
		*pt=(PTE_ADDR(pa) | perm | PTE_P);
f010107b:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
f0101081:	0b 7d d8             	or     -0x28(%ebp),%edi
f0101084:	89 38                	mov    %edi,(%eax)
		va+=PGSIZE;
f0101086:	81 c3 00 10 00 00    	add    $0x1000,%ebx
		pa+=PGSIZE;
		i++;
f010108c:	83 c6 01             	add    $0x1,%esi
f010108f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101092:	8d 3c 18             	lea    (%eax,%ebx,1),%edi
{
	uint32_t x;
	uint32_t i=0;
	pte_t * pt; 
	x=size/PGSIZE;
	while(i<x)
f0101095:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0101098:	75 ca                	jne    f0101064 <boot_map_region+0x2c>
		va+=PGSIZE;
		pa+=PGSIZE;
		i++;
	}
	// Fill this function in
}
f010109a:	83 c4 2c             	add    $0x2c,%esp
f010109d:	5b                   	pop    %ebx
f010109e:	5e                   	pop    %esi
f010109f:	5f                   	pop    %edi
f01010a0:	5d                   	pop    %ebp
f01010a1:	c3                   	ret    

f01010a2 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01010a2:	55                   	push   %ebp
f01010a3:	89 e5                	mov    %esp,%ebp
f01010a5:	83 ec 18             	sub    $0x18,%esp
	pte_t * pt = pgdir_walk(pgdir, va, 0);
f01010a8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01010af:	00 
f01010b0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010b3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01010b7:	8b 45 08             	mov    0x8(%ebp),%eax
f01010ba:	89 04 24             	mov    %eax,(%esp)
f01010bd:	e8 5c fe ff ff       	call   f0100f1e <pgdir_walk>
	
	if(pt == NULL)
f01010c2:	85 c0                	test   %eax,%eax
f01010c4:	74 39                	je     f01010ff <page_lookup+0x5d>
	return NULL;
	
	*pte_store = pt;
f01010c6:	8b 55 10             	mov    0x10(%ebp),%edx
f01010c9:	89 02                	mov    %eax,(%edx)
	
  return pa2page(PTE_ADDR(*pt));	
f01010cb:	8b 00                	mov    (%eax),%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010cd:	c1 e8 0c             	shr    $0xc,%eax
f01010d0:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f01010d6:	72 1c                	jb     f01010f4 <page_lookup+0x52>
		panic("pa2page called with invalid pa");
f01010d8:	c7 44 24 08 98 46 10 	movl   $0xf0104698,0x8(%esp)
f01010df:	f0 
f01010e0:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f01010e7:	00 
f01010e8:	c7 04 24 a0 42 10 f0 	movl   $0xf01042a0,(%esp)
f01010ef:	e8 a0 ef ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f01010f4:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
f01010fa:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f01010fd:	eb 05                	jmp    f0101104 <page_lookup+0x62>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t * pt = pgdir_walk(pgdir, va, 0);
	
	if(pt == NULL)
	return NULL;
f01010ff:	b8 00 00 00 00       	mov    $0x0,%eax
	
	*pte_store = pt;
	
  return pa2page(PTE_ADDR(*pt));	

}
f0101104:	c9                   	leave  
f0101105:	c3                   	ret    

f0101106 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101106:	55                   	push   %ebp
f0101107:	89 e5                	mov    %esp,%ebp
f0101109:	53                   	push   %ebx
f010110a:	83 ec 24             	sub    $0x24,%esp
f010110d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	struct PageInfo *page = NULL;
	pte_t *pt = NULL;
f0101110:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	if ((page = page_lookup(pgdir, va, &pt)) != NULL){
f0101117:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010111a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010111e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101122:	8b 45 08             	mov    0x8(%ebp),%eax
f0101125:	89 04 24             	mov    %eax,(%esp)
f0101128:	e8 75 ff ff ff       	call   f01010a2 <page_lookup>
f010112d:	85 c0                	test   %eax,%eax
f010112f:	74 0b                	je     f010113c <page_remove+0x36>
		page_decref(page);
f0101131:	89 04 24             	mov    %eax,(%esp)
f0101134:	e8 c2 fd ff ff       	call   f0100efb <page_decref>
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101139:	0f 01 3b             	invlpg (%ebx)
		tlb_invalidate(pgdir, va);
	}
	*pt=0;
f010113c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010113f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
f0101145:	83 c4 24             	add    $0x24,%esp
f0101148:	5b                   	pop    %ebx
f0101149:	5d                   	pop    %ebp
f010114a:	c3                   	ret    

f010114b <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010114b:	55                   	push   %ebp
f010114c:	89 e5                	mov    %esp,%ebp
f010114e:	57                   	push   %edi
f010114f:	56                   	push   %esi
f0101150:	53                   	push   %ebx
f0101151:	83 ec 1c             	sub    $0x1c,%esp
f0101154:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101157:	8b 7d 10             	mov    0x10(%ebp),%edi
pte_t *pte = pgdir_walk(pgdir, va, 1);
f010115a:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101161:	00 
f0101162:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101166:	8b 45 08             	mov    0x8(%ebp),%eax
f0101169:	89 04 24             	mov    %eax,(%esp)
f010116c:	e8 ad fd ff ff       	call   f0100f1e <pgdir_walk>
f0101171:	89 c6                	mov    %eax,%esi
 

    if (pte != NULL) {
f0101173:	85 c0                	test   %eax,%eax
f0101175:	74 48                	je     f01011bf <page_insert+0x74>
     
        if (*pte & PTE_P)
f0101177:	f6 00 01             	testb  $0x1,(%eax)
f010117a:	74 0f                	je     f010118b <page_insert+0x40>
            page_remove(pgdir, va);
f010117c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101180:	8b 45 08             	mov    0x8(%ebp),%eax
f0101183:	89 04 24             	mov    %eax,(%esp)
f0101186:	e8 7b ff ff ff       	call   f0101106 <page_remove>
   
       if (page_free_list == pp)
f010118b:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101190:	39 d8                	cmp    %ebx,%eax
f0101192:	75 07                	jne    f010119b <page_insert+0x50>
            page_free_list = page_free_list->pp_link;
f0101194:	8b 00                	mov    (%eax),%eax
f0101196:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
    else {
     //   pte = pgdir_walk(pgdir, va, 1);
       // if (!pte)
            return -E_NO_MEM;
    }
    *pte = page2pa(pp) | perm | PTE_P;
f010119b:	8b 55 14             	mov    0x14(%ebp),%edx
f010119e:	83 ca 01             	or     $0x1,%edx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01011a1:	89 d8                	mov    %ebx,%eax
f01011a3:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01011a9:	c1 f8 03             	sar    $0x3,%eax
f01011ac:	c1 e0 0c             	shl    $0xc,%eax
f01011af:	09 d0                	or     %edx,%eax
f01011b1:	89 06                	mov    %eax,(%esi)
    pp->pp_ref++;
f01011b3:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)

return 0;
f01011b8:	b8 00 00 00 00       	mov    $0x0,%eax
f01011bd:	eb 05                	jmp    f01011c4 <page_insert+0x79>
            page_free_list = page_free_list->pp_link;
    }
    else {
     //   pte = pgdir_walk(pgdir, va, 1);
       // if (!pte)
            return -E_NO_MEM;
f01011bf:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
    *pte = page2pa(pp) | perm | PTE_P;
    pp->pp_ref++;

return 0;
	
}
f01011c4:	83 c4 1c             	add    $0x1c,%esp
f01011c7:	5b                   	pop    %ebx
f01011c8:	5e                   	pop    %esi
f01011c9:	5f                   	pop    %edi
f01011ca:	5d                   	pop    %ebp
f01011cb:	c3                   	ret    

f01011cc <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01011cc:	55                   	push   %ebp
f01011cd:	89 e5                	mov    %esp,%ebp
f01011cf:	57                   	push   %edi
f01011d0:	56                   	push   %esi
f01011d1:	53                   	push   %ebx
f01011d2:	83 ec 4c             	sub    $0x4c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f01011d5:	b8 15 00 00 00       	mov    $0x15,%eax
f01011da:	e8 4f f7 ff ff       	call   f010092e <nvram_read>
f01011df:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f01011e1:	b8 17 00 00 00       	mov    $0x17,%eax
f01011e6:	e8 43 f7 ff ff       	call   f010092e <nvram_read>
f01011eb:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01011ed:	b8 34 00 00 00       	mov    $0x34,%eax
f01011f2:	e8 37 f7 ff ff       	call   f010092e <nvram_read>
f01011f7:	c1 e0 06             	shl    $0x6,%eax
f01011fa:	89 c2                	mov    %eax,%edx

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
		totalmem = 16 * 1024 + ext16mem;
f01011fc:	8d 80 00 40 00 00    	lea    0x4000(%eax),%eax
	extmem = nvram_read(NVRAM_EXTLO);
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0101202:	85 d2                	test   %edx,%edx
f0101204:	75 0b                	jne    f0101211 <mem_init+0x45>
		totalmem = 16 * 1024 + ext16mem;
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0101206:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f010120c:	85 f6                	test   %esi,%esi
f010120e:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0101211:	89 c2                	mov    %eax,%edx
f0101213:	c1 ea 02             	shr    $0x2,%edx
f0101216:	89 15 64 79 11 f0    	mov    %edx,0xf0117964
	npages_basemem = basemem / (PGSIZE / 1024);
f010121c:	89 da                	mov    %ebx,%edx
f010121e:	c1 ea 02             	shr    $0x2,%edx
f0101221:	89 15 40 75 11 f0    	mov    %edx,0xf0117540
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101227:	89 c2                	mov    %eax,%edx
f0101229:	29 da                	sub    %ebx,%edx
f010122b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010122f:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101233:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101237:	c7 04 24 b8 46 10 f0 	movl   $0xf01046b8,(%esp)
f010123e:	e8 23 1b 00 00       	call   f0102d66 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101243:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101248:	e8 0c f7 ff ff       	call   f0100959 <boot_alloc>
f010124d:	a3 68 79 11 f0       	mov    %eax,0xf0117968
	memset(kern_pgdir, 0, PGSIZE);
f0101252:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101259:	00 
f010125a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101261:	00 
f0101262:	89 04 24             	mov    %eax,(%esp)
f0101265:	e8 4d 26 00 00       	call   f01038b7 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010126a:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010126f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101274:	77 20                	ja     f0101296 <mem_init+0xca>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101276:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010127a:	c7 44 24 08 74 46 10 	movl   $0xf0104674,0x8(%esp)
f0101281:	f0 
f0101282:	c7 44 24 04 a2 00 00 	movl   $0xa2,0x4(%esp)
f0101289:	00 
f010128a:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101291:	e8 fe ed ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101296:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010129c:	83 ca 05             	or     $0x5,%edx
f010129f:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages=boot_alloc(sizeof(struct PageInfo)*npages);
f01012a5:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f01012aa:	c1 e0 03             	shl    $0x3,%eax
f01012ad:	e8 a7 f6 ff ff       	call   f0100959 <boot_alloc>
f01012b2:	a3 6c 79 11 f0       	mov    %eax,0xf011796c
	memset(pages,0,sizeof(struct PageInfo)*npages);
f01012b7:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f01012bd:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f01012c4:	89 54 24 08          	mov    %edx,0x8(%esp)
f01012c8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01012cf:	00 
f01012d0:	89 04 24             	mov    %eax,(%esp)
f01012d3:	e8 df 25 00 00       	call   f01038b7 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01012d8:	e8 ed fa ff ff       	call   f0100dca <page_init>

	check_page_free_list(1);
f01012dd:	b8 01 00 00 00       	mov    $0x1,%eax
f01012e2:	e8 9a f7 ff ff       	call   f0100a81 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01012e7:	83 3d 6c 79 11 f0 00 	cmpl   $0x0,0xf011796c
f01012ee:	75 1c                	jne    f010130c <mem_init+0x140>
		panic("'pages' is a null pointer!");
f01012f0:	c7 44 24 08 5e 43 10 	movl   $0xf010435e,0x8(%esp)
f01012f7:	f0 
f01012f8:	c7 44 24 04 73 02 00 	movl   $0x273,0x4(%esp)
f01012ff:	00 
f0101300:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101307:	e8 88 ed ff ff       	call   f0100094 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010130c:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101311:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101316:	eb 05                	jmp    f010131d <mem_init+0x151>
		++nfree;
f0101318:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010131b:	8b 00                	mov    (%eax),%eax
f010131d:	85 c0                	test   %eax,%eax
f010131f:	75 f7                	jne    f0101318 <mem_init+0x14c>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101321:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101328:	e8 06 fb ff ff       	call   f0100e33 <page_alloc>
f010132d:	89 c7                	mov    %eax,%edi
f010132f:	85 c0                	test   %eax,%eax
f0101331:	75 24                	jne    f0101357 <mem_init+0x18b>
f0101333:	c7 44 24 0c 79 43 10 	movl   $0xf0104379,0xc(%esp)
f010133a:	f0 
f010133b:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0101342:	f0 
f0101343:	c7 44 24 04 7b 02 00 	movl   $0x27b,0x4(%esp)
f010134a:	00 
f010134b:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101352:	e8 3d ed ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101357:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010135e:	e8 d0 fa ff ff       	call   f0100e33 <page_alloc>
f0101363:	89 c6                	mov    %eax,%esi
f0101365:	85 c0                	test   %eax,%eax
f0101367:	75 24                	jne    f010138d <mem_init+0x1c1>
f0101369:	c7 44 24 0c 8f 43 10 	movl   $0xf010438f,0xc(%esp)
f0101370:	f0 
f0101371:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0101378:	f0 
f0101379:	c7 44 24 04 7c 02 00 	movl   $0x27c,0x4(%esp)
f0101380:	00 
f0101381:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101388:	e8 07 ed ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f010138d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101394:	e8 9a fa ff ff       	call   f0100e33 <page_alloc>
f0101399:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010139c:	85 c0                	test   %eax,%eax
f010139e:	75 24                	jne    f01013c4 <mem_init+0x1f8>
f01013a0:	c7 44 24 0c a5 43 10 	movl   $0xf01043a5,0xc(%esp)
f01013a7:	f0 
f01013a8:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f01013af:	f0 
f01013b0:	c7 44 24 04 7d 02 00 	movl   $0x27d,0x4(%esp)
f01013b7:	00 
f01013b8:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f01013bf:	e8 d0 ec ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013c4:	39 f7                	cmp    %esi,%edi
f01013c6:	75 24                	jne    f01013ec <mem_init+0x220>
f01013c8:	c7 44 24 0c bb 43 10 	movl   $0xf01043bb,0xc(%esp)
f01013cf:	f0 
f01013d0:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f01013d7:	f0 
f01013d8:	c7 44 24 04 80 02 00 	movl   $0x280,0x4(%esp)
f01013df:	00 
f01013e0:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f01013e7:	e8 a8 ec ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013ec:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01013ef:	39 c6                	cmp    %eax,%esi
f01013f1:	74 04                	je     f01013f7 <mem_init+0x22b>
f01013f3:	39 c7                	cmp    %eax,%edi
f01013f5:	75 24                	jne    f010141b <mem_init+0x24f>
f01013f7:	c7 44 24 0c f4 46 10 	movl   $0xf01046f4,0xc(%esp)
f01013fe:	f0 
f01013ff:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0101406:	f0 
f0101407:	c7 44 24 04 81 02 00 	movl   $0x281,0x4(%esp)
f010140e:	00 
f010140f:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101416:	e8 79 ec ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010141b:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101421:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0101426:	c1 e0 0c             	shl    $0xc,%eax
f0101429:	89 f9                	mov    %edi,%ecx
f010142b:	29 d1                	sub    %edx,%ecx
f010142d:	c1 f9 03             	sar    $0x3,%ecx
f0101430:	c1 e1 0c             	shl    $0xc,%ecx
f0101433:	39 c1                	cmp    %eax,%ecx
f0101435:	72 24                	jb     f010145b <mem_init+0x28f>
f0101437:	c7 44 24 0c cd 43 10 	movl   $0xf01043cd,0xc(%esp)
f010143e:	f0 
f010143f:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0101446:	f0 
f0101447:	c7 44 24 04 82 02 00 	movl   $0x282,0x4(%esp)
f010144e:	00 
f010144f:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101456:	e8 39 ec ff ff       	call   f0100094 <_panic>
f010145b:	89 f1                	mov    %esi,%ecx
f010145d:	29 d1                	sub    %edx,%ecx
f010145f:	c1 f9 03             	sar    $0x3,%ecx
f0101462:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101465:	39 c8                	cmp    %ecx,%eax
f0101467:	77 24                	ja     f010148d <mem_init+0x2c1>
f0101469:	c7 44 24 0c ea 43 10 	movl   $0xf01043ea,0xc(%esp)
f0101470:	f0 
f0101471:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0101478:	f0 
f0101479:	c7 44 24 04 83 02 00 	movl   $0x283,0x4(%esp)
f0101480:	00 
f0101481:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101488:	e8 07 ec ff ff       	call   f0100094 <_panic>
f010148d:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101490:	29 d1                	sub    %edx,%ecx
f0101492:	89 ca                	mov    %ecx,%edx
f0101494:	c1 fa 03             	sar    $0x3,%edx
f0101497:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f010149a:	39 d0                	cmp    %edx,%eax
f010149c:	77 24                	ja     f01014c2 <mem_init+0x2f6>
f010149e:	c7 44 24 0c 07 44 10 	movl   $0xf0104407,0xc(%esp)
f01014a5:	f0 
f01014a6:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f01014ad:	f0 
f01014ae:	c7 44 24 04 84 02 00 	movl   $0x284,0x4(%esp)
f01014b5:	00 
f01014b6:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f01014bd:	e8 d2 eb ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01014c2:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01014c7:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01014ca:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f01014d1:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01014d4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014db:	e8 53 f9 ff ff       	call   f0100e33 <page_alloc>
f01014e0:	85 c0                	test   %eax,%eax
f01014e2:	74 24                	je     f0101508 <mem_init+0x33c>
f01014e4:	c7 44 24 0c 24 44 10 	movl   $0xf0104424,0xc(%esp)
f01014eb:	f0 
f01014ec:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f01014f3:	f0 
f01014f4:	c7 44 24 04 8b 02 00 	movl   $0x28b,0x4(%esp)
f01014fb:	00 
f01014fc:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101503:	e8 8c eb ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101508:	89 3c 24             	mov    %edi,(%esp)
f010150b:	e8 ae f9 ff ff       	call   f0100ebe <page_free>
	page_free(pp1);
f0101510:	89 34 24             	mov    %esi,(%esp)
f0101513:	e8 a6 f9 ff ff       	call   f0100ebe <page_free>
	page_free(pp2);
f0101518:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010151b:	89 04 24             	mov    %eax,(%esp)
f010151e:	e8 9b f9 ff ff       	call   f0100ebe <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101523:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010152a:	e8 04 f9 ff ff       	call   f0100e33 <page_alloc>
f010152f:	89 c6                	mov    %eax,%esi
f0101531:	85 c0                	test   %eax,%eax
f0101533:	75 24                	jne    f0101559 <mem_init+0x38d>
f0101535:	c7 44 24 0c 79 43 10 	movl   $0xf0104379,0xc(%esp)
f010153c:	f0 
f010153d:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0101544:	f0 
f0101545:	c7 44 24 04 92 02 00 	movl   $0x292,0x4(%esp)
f010154c:	00 
f010154d:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101554:	e8 3b eb ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101559:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101560:	e8 ce f8 ff ff       	call   f0100e33 <page_alloc>
f0101565:	89 c7                	mov    %eax,%edi
f0101567:	85 c0                	test   %eax,%eax
f0101569:	75 24                	jne    f010158f <mem_init+0x3c3>
f010156b:	c7 44 24 0c 8f 43 10 	movl   $0xf010438f,0xc(%esp)
f0101572:	f0 
f0101573:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f010157a:	f0 
f010157b:	c7 44 24 04 93 02 00 	movl   $0x293,0x4(%esp)
f0101582:	00 
f0101583:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f010158a:	e8 05 eb ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f010158f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101596:	e8 98 f8 ff ff       	call   f0100e33 <page_alloc>
f010159b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010159e:	85 c0                	test   %eax,%eax
f01015a0:	75 24                	jne    f01015c6 <mem_init+0x3fa>
f01015a2:	c7 44 24 0c a5 43 10 	movl   $0xf01043a5,0xc(%esp)
f01015a9:	f0 
f01015aa:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f01015b1:	f0 
f01015b2:	c7 44 24 04 94 02 00 	movl   $0x294,0x4(%esp)
f01015b9:	00 
f01015ba:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f01015c1:	e8 ce ea ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01015c6:	39 fe                	cmp    %edi,%esi
f01015c8:	75 24                	jne    f01015ee <mem_init+0x422>
f01015ca:	c7 44 24 0c bb 43 10 	movl   $0xf01043bb,0xc(%esp)
f01015d1:	f0 
f01015d2:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f01015d9:	f0 
f01015da:	c7 44 24 04 96 02 00 	movl   $0x296,0x4(%esp)
f01015e1:	00 
f01015e2:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f01015e9:	e8 a6 ea ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015ee:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015f1:	39 c7                	cmp    %eax,%edi
f01015f3:	74 04                	je     f01015f9 <mem_init+0x42d>
f01015f5:	39 c6                	cmp    %eax,%esi
f01015f7:	75 24                	jne    f010161d <mem_init+0x451>
f01015f9:	c7 44 24 0c f4 46 10 	movl   $0xf01046f4,0xc(%esp)
f0101600:	f0 
f0101601:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0101608:	f0 
f0101609:	c7 44 24 04 97 02 00 	movl   $0x297,0x4(%esp)
f0101610:	00 
f0101611:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101618:	e8 77 ea ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f010161d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101624:	e8 0a f8 ff ff       	call   f0100e33 <page_alloc>
f0101629:	85 c0                	test   %eax,%eax
f010162b:	74 24                	je     f0101651 <mem_init+0x485>
f010162d:	c7 44 24 0c 24 44 10 	movl   $0xf0104424,0xc(%esp)
f0101634:	f0 
f0101635:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f010163c:	f0 
f010163d:	c7 44 24 04 98 02 00 	movl   $0x298,0x4(%esp)
f0101644:	00 
f0101645:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f010164c:	e8 43 ea ff ff       	call   f0100094 <_panic>
f0101651:	89 f0                	mov    %esi,%eax
f0101653:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101659:	c1 f8 03             	sar    $0x3,%eax
f010165c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010165f:	89 c2                	mov    %eax,%edx
f0101661:	c1 ea 0c             	shr    $0xc,%edx
f0101664:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f010166a:	72 20                	jb     f010168c <mem_init+0x4c0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010166c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101670:	c7 44 24 08 8c 45 10 	movl   $0xf010458c,0x8(%esp)
f0101677:	f0 
f0101678:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010167f:	00 
f0101680:	c7 04 24 a0 42 10 f0 	movl   $0xf01042a0,(%esp)
f0101687:	e8 08 ea ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010168c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101693:	00 
f0101694:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f010169b:	00 
	return (void *)(pa + KERNBASE);
f010169c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01016a1:	89 04 24             	mov    %eax,(%esp)
f01016a4:	e8 0e 22 00 00       	call   f01038b7 <memset>
	page_free(pp0);
f01016a9:	89 34 24             	mov    %esi,(%esp)
f01016ac:	e8 0d f8 ff ff       	call   f0100ebe <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01016b1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01016b8:	e8 76 f7 ff ff       	call   f0100e33 <page_alloc>
f01016bd:	85 c0                	test   %eax,%eax
f01016bf:	75 24                	jne    f01016e5 <mem_init+0x519>
f01016c1:	c7 44 24 0c 33 44 10 	movl   $0xf0104433,0xc(%esp)
f01016c8:	f0 
f01016c9:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f01016d0:	f0 
f01016d1:	c7 44 24 04 9d 02 00 	movl   $0x29d,0x4(%esp)
f01016d8:	00 
f01016d9:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f01016e0:	e8 af e9 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f01016e5:	39 c6                	cmp    %eax,%esi
f01016e7:	74 24                	je     f010170d <mem_init+0x541>
f01016e9:	c7 44 24 0c 51 44 10 	movl   $0xf0104451,0xc(%esp)
f01016f0:	f0 
f01016f1:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f01016f8:	f0 
f01016f9:	c7 44 24 04 9e 02 00 	movl   $0x29e,0x4(%esp)
f0101700:	00 
f0101701:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101708:	e8 87 e9 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010170d:	89 f0                	mov    %esi,%eax
f010170f:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101715:	c1 f8 03             	sar    $0x3,%eax
f0101718:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010171b:	89 c2                	mov    %eax,%edx
f010171d:	c1 ea 0c             	shr    $0xc,%edx
f0101720:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0101726:	72 20                	jb     f0101748 <mem_init+0x57c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101728:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010172c:	c7 44 24 08 8c 45 10 	movl   $0xf010458c,0x8(%esp)
f0101733:	f0 
f0101734:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010173b:	00 
f010173c:	c7 04 24 a0 42 10 f0 	movl   $0xf01042a0,(%esp)
f0101743:	e8 4c e9 ff ff       	call   f0100094 <_panic>
f0101748:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f010174e:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101754:	80 38 00             	cmpb   $0x0,(%eax)
f0101757:	74 24                	je     f010177d <mem_init+0x5b1>
f0101759:	c7 44 24 0c 61 44 10 	movl   $0xf0104461,0xc(%esp)
f0101760:	f0 
f0101761:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0101768:	f0 
f0101769:	c7 44 24 04 a1 02 00 	movl   $0x2a1,0x4(%esp)
f0101770:	00 
f0101771:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101778:	e8 17 e9 ff ff       	call   f0100094 <_panic>
f010177d:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101780:	39 d0                	cmp    %edx,%eax
f0101782:	75 d0                	jne    f0101754 <mem_init+0x588>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101784:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101787:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

	// free the pages we took
	page_free(pp0);
f010178c:	89 34 24             	mov    %esi,(%esp)
f010178f:	e8 2a f7 ff ff       	call   f0100ebe <page_free>
	page_free(pp1);
f0101794:	89 3c 24             	mov    %edi,(%esp)
f0101797:	e8 22 f7 ff ff       	call   f0100ebe <page_free>
	page_free(pp2);
f010179c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010179f:	89 04 24             	mov    %eax,(%esp)
f01017a2:	e8 17 f7 ff ff       	call   f0100ebe <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01017a7:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01017ac:	eb 05                	jmp    f01017b3 <mem_init+0x5e7>
		--nfree;
f01017ae:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01017b1:	8b 00                	mov    (%eax),%eax
f01017b3:	85 c0                	test   %eax,%eax
f01017b5:	75 f7                	jne    f01017ae <mem_init+0x5e2>
		--nfree;
	assert(nfree == 0);
f01017b7:	85 db                	test   %ebx,%ebx
f01017b9:	74 24                	je     f01017df <mem_init+0x613>
f01017bb:	c7 44 24 0c 6b 44 10 	movl   $0xf010446b,0xc(%esp)
f01017c2:	f0 
f01017c3:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f01017ca:	f0 
f01017cb:	c7 44 24 04 ae 02 00 	movl   $0x2ae,0x4(%esp)
f01017d2:	00 
f01017d3:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f01017da:	e8 b5 e8 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01017df:	c7 04 24 14 47 10 f0 	movl   $0xf0104714,(%esp)
f01017e6:	e8 7b 15 00 00       	call   f0102d66 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01017eb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017f2:	e8 3c f6 ff ff       	call   f0100e33 <page_alloc>
f01017f7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01017fa:	85 c0                	test   %eax,%eax
f01017fc:	75 24                	jne    f0101822 <mem_init+0x656>
f01017fe:	c7 44 24 0c 79 43 10 	movl   $0xf0104379,0xc(%esp)
f0101805:	f0 
f0101806:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f010180d:	f0 
f010180e:	c7 44 24 04 07 03 00 	movl   $0x307,0x4(%esp)
f0101815:	00 
f0101816:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f010181d:	e8 72 e8 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101822:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101829:	e8 05 f6 ff ff       	call   f0100e33 <page_alloc>
f010182e:	89 c3                	mov    %eax,%ebx
f0101830:	85 c0                	test   %eax,%eax
f0101832:	75 24                	jne    f0101858 <mem_init+0x68c>
f0101834:	c7 44 24 0c 8f 43 10 	movl   $0xf010438f,0xc(%esp)
f010183b:	f0 
f010183c:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0101843:	f0 
f0101844:	c7 44 24 04 08 03 00 	movl   $0x308,0x4(%esp)
f010184b:	00 
f010184c:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101853:	e8 3c e8 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101858:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010185f:	e8 cf f5 ff ff       	call   f0100e33 <page_alloc>
f0101864:	89 c6                	mov    %eax,%esi
f0101866:	85 c0                	test   %eax,%eax
f0101868:	75 24                	jne    f010188e <mem_init+0x6c2>
f010186a:	c7 44 24 0c a5 43 10 	movl   $0xf01043a5,0xc(%esp)
f0101871:	f0 
f0101872:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0101879:	f0 
f010187a:	c7 44 24 04 09 03 00 	movl   $0x309,0x4(%esp)
f0101881:	00 
f0101882:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101889:	e8 06 e8 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010188e:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101891:	75 24                	jne    f01018b7 <mem_init+0x6eb>
f0101893:	c7 44 24 0c bb 43 10 	movl   $0xf01043bb,0xc(%esp)
f010189a:	f0 
f010189b:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f01018a2:	f0 
f01018a3:	c7 44 24 04 0c 03 00 	movl   $0x30c,0x4(%esp)
f01018aa:	00 
f01018ab:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f01018b2:	e8 dd e7 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01018b7:	39 c3                	cmp    %eax,%ebx
f01018b9:	74 05                	je     f01018c0 <mem_init+0x6f4>
f01018bb:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01018be:	75 24                	jne    f01018e4 <mem_init+0x718>
f01018c0:	c7 44 24 0c f4 46 10 	movl   $0xf01046f4,0xc(%esp)
f01018c7:	f0 
f01018c8:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f01018cf:	f0 
f01018d0:	c7 44 24 04 0d 03 00 	movl   $0x30d,0x4(%esp)
f01018d7:	00 
f01018d8:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f01018df:	e8 b0 e7 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01018e4:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01018e9:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01018ec:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f01018f3:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01018f6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018fd:	e8 31 f5 ff ff       	call   f0100e33 <page_alloc>
f0101902:	85 c0                	test   %eax,%eax
f0101904:	74 24                	je     f010192a <mem_init+0x75e>
f0101906:	c7 44 24 0c 24 44 10 	movl   $0xf0104424,0xc(%esp)
f010190d:	f0 
f010190e:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0101915:	f0 
f0101916:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
f010191d:	00 
f010191e:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101925:	e8 6a e7 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010192a:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010192d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101931:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101938:	00 
f0101939:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010193e:	89 04 24             	mov    %eax,(%esp)
f0101941:	e8 5c f7 ff ff       	call   f01010a2 <page_lookup>
f0101946:	85 c0                	test   %eax,%eax
f0101948:	74 24                	je     f010196e <mem_init+0x7a2>
f010194a:	c7 44 24 0c 34 47 10 	movl   $0xf0104734,0xc(%esp)
f0101951:	f0 
f0101952:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0101959:	f0 
f010195a:	c7 44 24 04 17 03 00 	movl   $0x317,0x4(%esp)
f0101961:	00 
f0101962:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101969:	e8 26 e7 ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010196e:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101975:	00 
f0101976:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010197d:	00 
f010197e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101982:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101987:	89 04 24             	mov    %eax,(%esp)
f010198a:	e8 bc f7 ff ff       	call   f010114b <page_insert>
f010198f:	85 c0                	test   %eax,%eax
f0101991:	78 24                	js     f01019b7 <mem_init+0x7eb>
f0101993:	c7 44 24 0c 6c 47 10 	movl   $0xf010476c,0xc(%esp)
f010199a:	f0 
f010199b:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f01019a2:	f0 
f01019a3:	c7 44 24 04 1a 03 00 	movl   $0x31a,0x4(%esp)
f01019aa:	00 
f01019ab:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f01019b2:	e8 dd e6 ff ff       	call   f0100094 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01019b7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019ba:	89 04 24             	mov    %eax,(%esp)
f01019bd:	e8 fc f4 ff ff       	call   f0100ebe <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01019c2:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01019c9:	00 
f01019ca:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01019d1:	00 
f01019d2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01019d6:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01019db:	89 04 24             	mov    %eax,(%esp)
f01019de:	e8 68 f7 ff ff       	call   f010114b <page_insert>
f01019e3:	85 c0                	test   %eax,%eax
f01019e5:	74 24                	je     f0101a0b <mem_init+0x83f>
f01019e7:	c7 44 24 0c 9c 47 10 	movl   $0xf010479c,0xc(%esp)
f01019ee:	f0 
f01019ef:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f01019f6:	f0 
f01019f7:	c7 44 24 04 1e 03 00 	movl   $0x31e,0x4(%esp)
f01019fe:	00 
f01019ff:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101a06:	e8 89 e6 ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101a0b:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101a11:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101a16:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101a19:	8b 17                	mov    (%edi),%edx
f0101a1b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a21:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101a24:	29 c1                	sub    %eax,%ecx
f0101a26:	89 c8                	mov    %ecx,%eax
f0101a28:	c1 f8 03             	sar    $0x3,%eax
f0101a2b:	c1 e0 0c             	shl    $0xc,%eax
f0101a2e:	39 c2                	cmp    %eax,%edx
f0101a30:	74 24                	je     f0101a56 <mem_init+0x88a>
f0101a32:	c7 44 24 0c cc 47 10 	movl   $0xf01047cc,0xc(%esp)
f0101a39:	f0 
f0101a3a:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0101a41:	f0 
f0101a42:	c7 44 24 04 1f 03 00 	movl   $0x31f,0x4(%esp)
f0101a49:	00 
f0101a4a:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101a51:	e8 3e e6 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101a56:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a5b:	89 f8                	mov    %edi,%eax
f0101a5d:	e8 b0 ef ff ff       	call   f0100a12 <check_va2pa>
f0101a62:	89 da                	mov    %ebx,%edx
f0101a64:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101a67:	c1 fa 03             	sar    $0x3,%edx
f0101a6a:	c1 e2 0c             	shl    $0xc,%edx
f0101a6d:	39 d0                	cmp    %edx,%eax
f0101a6f:	74 24                	je     f0101a95 <mem_init+0x8c9>
f0101a71:	c7 44 24 0c f4 47 10 	movl   $0xf01047f4,0xc(%esp)
f0101a78:	f0 
f0101a79:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0101a80:	f0 
f0101a81:	c7 44 24 04 20 03 00 	movl   $0x320,0x4(%esp)
f0101a88:	00 
f0101a89:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101a90:	e8 ff e5 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0101a95:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101a9a:	74 24                	je     f0101ac0 <mem_init+0x8f4>
f0101a9c:	c7 44 24 0c 76 44 10 	movl   $0xf0104476,0xc(%esp)
f0101aa3:	f0 
f0101aa4:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0101aab:	f0 
f0101aac:	c7 44 24 04 21 03 00 	movl   $0x321,0x4(%esp)
f0101ab3:	00 
f0101ab4:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101abb:	e8 d4 e5 ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0101ac0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ac3:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ac8:	74 24                	je     f0101aee <mem_init+0x922>
f0101aca:	c7 44 24 0c 87 44 10 	movl   $0xf0104487,0xc(%esp)
f0101ad1:	f0 
f0101ad2:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0101ad9:	f0 
f0101ada:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f0101ae1:	00 
f0101ae2:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101ae9:	e8 a6 e5 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101aee:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101af5:	00 
f0101af6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101afd:	00 
f0101afe:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101b02:	89 3c 24             	mov    %edi,(%esp)
f0101b05:	e8 41 f6 ff ff       	call   f010114b <page_insert>
f0101b0a:	85 c0                	test   %eax,%eax
f0101b0c:	74 24                	je     f0101b32 <mem_init+0x966>
f0101b0e:	c7 44 24 0c 24 48 10 	movl   $0xf0104824,0xc(%esp)
f0101b15:	f0 
f0101b16:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0101b1d:	f0 
f0101b1e:	c7 44 24 04 25 03 00 	movl   $0x325,0x4(%esp)
f0101b25:	00 
f0101b26:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101b2d:	e8 62 e5 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b32:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b37:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101b3c:	e8 d1 ee ff ff       	call   f0100a12 <check_va2pa>
f0101b41:	89 f2                	mov    %esi,%edx
f0101b43:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101b49:	c1 fa 03             	sar    $0x3,%edx
f0101b4c:	c1 e2 0c             	shl    $0xc,%edx
f0101b4f:	39 d0                	cmp    %edx,%eax
f0101b51:	74 24                	je     f0101b77 <mem_init+0x9ab>
f0101b53:	c7 44 24 0c 60 48 10 	movl   $0xf0104860,0xc(%esp)
f0101b5a:	f0 
f0101b5b:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0101b62:	f0 
f0101b63:	c7 44 24 04 26 03 00 	movl   $0x326,0x4(%esp)
f0101b6a:	00 
f0101b6b:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101b72:	e8 1d e5 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101b77:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101b7c:	74 24                	je     f0101ba2 <mem_init+0x9d6>
f0101b7e:	c7 44 24 0c 98 44 10 	movl   $0xf0104498,0xc(%esp)
f0101b85:	f0 
f0101b86:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0101b8d:	f0 
f0101b8e:	c7 44 24 04 27 03 00 	movl   $0x327,0x4(%esp)
f0101b95:	00 
f0101b96:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101b9d:	e8 f2 e4 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101ba2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ba9:	e8 85 f2 ff ff       	call   f0100e33 <page_alloc>
f0101bae:	85 c0                	test   %eax,%eax
f0101bb0:	74 24                	je     f0101bd6 <mem_init+0xa0a>
f0101bb2:	c7 44 24 0c 24 44 10 	movl   $0xf0104424,0xc(%esp)
f0101bb9:	f0 
f0101bba:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0101bc1:	f0 
f0101bc2:	c7 44 24 04 2a 03 00 	movl   $0x32a,0x4(%esp)
f0101bc9:	00 
f0101bca:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101bd1:	e8 be e4 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101bd6:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101bdd:	00 
f0101bde:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101be5:	00 
f0101be6:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101bea:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101bef:	89 04 24             	mov    %eax,(%esp)
f0101bf2:	e8 54 f5 ff ff       	call   f010114b <page_insert>
f0101bf7:	85 c0                	test   %eax,%eax
f0101bf9:	74 24                	je     f0101c1f <mem_init+0xa53>
f0101bfb:	c7 44 24 0c 24 48 10 	movl   $0xf0104824,0xc(%esp)
f0101c02:	f0 
f0101c03:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0101c0a:	f0 
f0101c0b:	c7 44 24 04 2d 03 00 	movl   $0x32d,0x4(%esp)
f0101c12:	00 
f0101c13:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101c1a:	e8 75 e4 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c1f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c24:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101c29:	e8 e4 ed ff ff       	call   f0100a12 <check_va2pa>
f0101c2e:	89 f2                	mov    %esi,%edx
f0101c30:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101c36:	c1 fa 03             	sar    $0x3,%edx
f0101c39:	c1 e2 0c             	shl    $0xc,%edx
f0101c3c:	39 d0                	cmp    %edx,%eax
f0101c3e:	74 24                	je     f0101c64 <mem_init+0xa98>
f0101c40:	c7 44 24 0c 60 48 10 	movl   $0xf0104860,0xc(%esp)
f0101c47:	f0 
f0101c48:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0101c4f:	f0 
f0101c50:	c7 44 24 04 2e 03 00 	movl   $0x32e,0x4(%esp)
f0101c57:	00 
f0101c58:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101c5f:	e8 30 e4 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101c64:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c69:	74 24                	je     f0101c8f <mem_init+0xac3>
f0101c6b:	c7 44 24 0c 98 44 10 	movl   $0xf0104498,0xc(%esp)
f0101c72:	f0 
f0101c73:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0101c7a:	f0 
f0101c7b:	c7 44 24 04 2f 03 00 	movl   $0x32f,0x4(%esp)
f0101c82:	00 
f0101c83:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101c8a:	e8 05 e4 ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101c8f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c96:	e8 98 f1 ff ff       	call   f0100e33 <page_alloc>
f0101c9b:	85 c0                	test   %eax,%eax
f0101c9d:	74 24                	je     f0101cc3 <mem_init+0xaf7>
f0101c9f:	c7 44 24 0c 24 44 10 	movl   $0xf0104424,0xc(%esp)
f0101ca6:	f0 
f0101ca7:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0101cae:	f0 
f0101caf:	c7 44 24 04 33 03 00 	movl   $0x333,0x4(%esp)
f0101cb6:	00 
f0101cb7:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101cbe:	e8 d1 e3 ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101cc3:	8b 15 68 79 11 f0    	mov    0xf0117968,%edx
f0101cc9:	8b 02                	mov    (%edx),%eax
f0101ccb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101cd0:	89 c1                	mov    %eax,%ecx
f0101cd2:	c1 e9 0c             	shr    $0xc,%ecx
f0101cd5:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f0101cdb:	72 20                	jb     f0101cfd <mem_init+0xb31>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101cdd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101ce1:	c7 44 24 08 8c 45 10 	movl   $0xf010458c,0x8(%esp)
f0101ce8:	f0 
f0101ce9:	c7 44 24 04 36 03 00 	movl   $0x336,0x4(%esp)
f0101cf0:	00 
f0101cf1:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101cf8:	e8 97 e3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101cfd:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101d02:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101d05:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101d0c:	00 
f0101d0d:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101d14:	00 
f0101d15:	89 14 24             	mov    %edx,(%esp)
f0101d18:	e8 01 f2 ff ff       	call   f0100f1e <pgdir_walk>
f0101d1d:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101d20:	8d 51 04             	lea    0x4(%ecx),%edx
f0101d23:	39 d0                	cmp    %edx,%eax
f0101d25:	74 24                	je     f0101d4b <mem_init+0xb7f>
f0101d27:	c7 44 24 0c 90 48 10 	movl   $0xf0104890,0xc(%esp)
f0101d2e:	f0 
f0101d2f:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0101d36:	f0 
f0101d37:	c7 44 24 04 37 03 00 	movl   $0x337,0x4(%esp)
f0101d3e:	00 
f0101d3f:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101d46:	e8 49 e3 ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101d4b:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101d52:	00 
f0101d53:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101d5a:	00 
f0101d5b:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101d5f:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101d64:	89 04 24             	mov    %eax,(%esp)
f0101d67:	e8 df f3 ff ff       	call   f010114b <page_insert>
f0101d6c:	85 c0                	test   %eax,%eax
f0101d6e:	74 24                	je     f0101d94 <mem_init+0xbc8>
f0101d70:	c7 44 24 0c d0 48 10 	movl   $0xf01048d0,0xc(%esp)
f0101d77:	f0 
f0101d78:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0101d7f:	f0 
f0101d80:	c7 44 24 04 3a 03 00 	movl   $0x33a,0x4(%esp)
f0101d87:	00 
f0101d88:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101d8f:	e8 00 e3 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101d94:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101d9a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d9f:	89 f8                	mov    %edi,%eax
f0101da1:	e8 6c ec ff ff       	call   f0100a12 <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101da6:	89 f2                	mov    %esi,%edx
f0101da8:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101dae:	c1 fa 03             	sar    $0x3,%edx
f0101db1:	c1 e2 0c             	shl    $0xc,%edx
f0101db4:	39 d0                	cmp    %edx,%eax
f0101db6:	74 24                	je     f0101ddc <mem_init+0xc10>
f0101db8:	c7 44 24 0c 60 48 10 	movl   $0xf0104860,0xc(%esp)
f0101dbf:	f0 
f0101dc0:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0101dc7:	f0 
f0101dc8:	c7 44 24 04 3b 03 00 	movl   $0x33b,0x4(%esp)
f0101dcf:	00 
f0101dd0:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101dd7:	e8 b8 e2 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101ddc:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101de1:	74 24                	je     f0101e07 <mem_init+0xc3b>
f0101de3:	c7 44 24 0c 98 44 10 	movl   $0xf0104498,0xc(%esp)
f0101dea:	f0 
f0101deb:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0101df2:	f0 
f0101df3:	c7 44 24 04 3c 03 00 	movl   $0x33c,0x4(%esp)
f0101dfa:	00 
f0101dfb:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101e02:	e8 8d e2 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101e07:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101e0e:	00 
f0101e0f:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101e16:	00 
f0101e17:	89 3c 24             	mov    %edi,(%esp)
f0101e1a:	e8 ff f0 ff ff       	call   f0100f1e <pgdir_walk>
f0101e1f:	f6 00 04             	testb  $0x4,(%eax)
f0101e22:	75 24                	jne    f0101e48 <mem_init+0xc7c>
f0101e24:	c7 44 24 0c 10 49 10 	movl   $0xf0104910,0xc(%esp)
f0101e2b:	f0 
f0101e2c:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0101e33:	f0 
f0101e34:	c7 44 24 04 3d 03 00 	movl   $0x33d,0x4(%esp)
f0101e3b:	00 
f0101e3c:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101e43:	e8 4c e2 ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101e48:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101e4d:	f6 00 04             	testb  $0x4,(%eax)
f0101e50:	75 24                	jne    f0101e76 <mem_init+0xcaa>
f0101e52:	c7 44 24 0c a9 44 10 	movl   $0xf01044a9,0xc(%esp)
f0101e59:	f0 
f0101e5a:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0101e61:	f0 
f0101e62:	c7 44 24 04 3e 03 00 	movl   $0x33e,0x4(%esp)
f0101e69:	00 
f0101e6a:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101e71:	e8 1e e2 ff ff       	call   f0100094 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101e76:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101e7d:	00 
f0101e7e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101e85:	00 
f0101e86:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101e8a:	89 04 24             	mov    %eax,(%esp)
f0101e8d:	e8 b9 f2 ff ff       	call   f010114b <page_insert>
f0101e92:	85 c0                	test   %eax,%eax
f0101e94:	74 24                	je     f0101eba <mem_init+0xcee>
f0101e96:	c7 44 24 0c 24 48 10 	movl   $0xf0104824,0xc(%esp)
f0101e9d:	f0 
f0101e9e:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0101ea5:	f0 
f0101ea6:	c7 44 24 04 41 03 00 	movl   $0x341,0x4(%esp)
f0101ead:	00 
f0101eae:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101eb5:	e8 da e1 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101eba:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101ec1:	00 
f0101ec2:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101ec9:	00 
f0101eca:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101ecf:	89 04 24             	mov    %eax,(%esp)
f0101ed2:	e8 47 f0 ff ff       	call   f0100f1e <pgdir_walk>
f0101ed7:	f6 00 02             	testb  $0x2,(%eax)
f0101eda:	75 24                	jne    f0101f00 <mem_init+0xd34>
f0101edc:	c7 44 24 0c 44 49 10 	movl   $0xf0104944,0xc(%esp)
f0101ee3:	f0 
f0101ee4:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0101eeb:	f0 
f0101eec:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f0101ef3:	00 
f0101ef4:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101efb:	e8 94 e1 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101f00:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f07:	00 
f0101f08:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f0f:	00 
f0101f10:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101f15:	89 04 24             	mov    %eax,(%esp)
f0101f18:	e8 01 f0 ff ff       	call   f0100f1e <pgdir_walk>
f0101f1d:	f6 00 04             	testb  $0x4,(%eax)
f0101f20:	74 24                	je     f0101f46 <mem_init+0xd7a>
f0101f22:	c7 44 24 0c 78 49 10 	movl   $0xf0104978,0xc(%esp)
f0101f29:	f0 
f0101f2a:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0101f31:	f0 
f0101f32:	c7 44 24 04 43 03 00 	movl   $0x343,0x4(%esp)
f0101f39:	00 
f0101f3a:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101f41:	e8 4e e1 ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101f46:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f4d:	00 
f0101f4e:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0101f55:	00 
f0101f56:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f59:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101f5d:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101f62:	89 04 24             	mov    %eax,(%esp)
f0101f65:	e8 e1 f1 ff ff       	call   f010114b <page_insert>
f0101f6a:	85 c0                	test   %eax,%eax
f0101f6c:	78 24                	js     f0101f92 <mem_init+0xdc6>
f0101f6e:	c7 44 24 0c b0 49 10 	movl   $0xf01049b0,0xc(%esp)
f0101f75:	f0 
f0101f76:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0101f7d:	f0 
f0101f7e:	c7 44 24 04 46 03 00 	movl   $0x346,0x4(%esp)
f0101f85:	00 
f0101f86:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101f8d:	e8 02 e1 ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101f92:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f99:	00 
f0101f9a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101fa1:	00 
f0101fa2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101fa6:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101fab:	89 04 24             	mov    %eax,(%esp)
f0101fae:	e8 98 f1 ff ff       	call   f010114b <page_insert>
f0101fb3:	85 c0                	test   %eax,%eax
f0101fb5:	74 24                	je     f0101fdb <mem_init+0xe0f>
f0101fb7:	c7 44 24 0c e8 49 10 	movl   $0xf01049e8,0xc(%esp)
f0101fbe:	f0 
f0101fbf:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0101fc6:	f0 
f0101fc7:	c7 44 24 04 49 03 00 	movl   $0x349,0x4(%esp)
f0101fce:	00 
f0101fcf:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0101fd6:	e8 b9 e0 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101fdb:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101fe2:	00 
f0101fe3:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101fea:	00 
f0101feb:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101ff0:	89 04 24             	mov    %eax,(%esp)
f0101ff3:	e8 26 ef ff ff       	call   f0100f1e <pgdir_walk>
f0101ff8:	f6 00 04             	testb  $0x4,(%eax)
f0101ffb:	74 24                	je     f0102021 <mem_init+0xe55>
f0101ffd:	c7 44 24 0c 78 49 10 	movl   $0xf0104978,0xc(%esp)
f0102004:	f0 
f0102005:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f010200c:	f0 
f010200d:	c7 44 24 04 4a 03 00 	movl   $0x34a,0x4(%esp)
f0102014:	00 
f0102015:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f010201c:	e8 73 e0 ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0102021:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0102027:	ba 00 00 00 00       	mov    $0x0,%edx
f010202c:	89 f8                	mov    %edi,%eax
f010202e:	e8 df e9 ff ff       	call   f0100a12 <check_va2pa>
f0102033:	89 c1                	mov    %eax,%ecx
f0102035:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102038:	89 d8                	mov    %ebx,%eax
f010203a:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0102040:	c1 f8 03             	sar    $0x3,%eax
f0102043:	c1 e0 0c             	shl    $0xc,%eax
f0102046:	39 c1                	cmp    %eax,%ecx
f0102048:	74 24                	je     f010206e <mem_init+0xea2>
f010204a:	c7 44 24 0c 24 4a 10 	movl   $0xf0104a24,0xc(%esp)
f0102051:	f0 
f0102052:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0102059:	f0 
f010205a:	c7 44 24 04 4d 03 00 	movl   $0x34d,0x4(%esp)
f0102061:	00 
f0102062:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0102069:	e8 26 e0 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010206e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102073:	89 f8                	mov    %edi,%eax
f0102075:	e8 98 e9 ff ff       	call   f0100a12 <check_va2pa>
f010207a:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f010207d:	74 24                	je     f01020a3 <mem_init+0xed7>
f010207f:	c7 44 24 0c 50 4a 10 	movl   $0xf0104a50,0xc(%esp)
f0102086:	f0 
f0102087:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f010208e:	f0 
f010208f:	c7 44 24 04 4e 03 00 	movl   $0x34e,0x4(%esp)
f0102096:	00 
f0102097:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f010209e:	e8 f1 df ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f01020a3:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f01020a8:	74 24                	je     f01020ce <mem_init+0xf02>
f01020aa:	c7 44 24 0c bf 44 10 	movl   $0xf01044bf,0xc(%esp)
f01020b1:	f0 
f01020b2:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f01020b9:	f0 
f01020ba:	c7 44 24 04 50 03 00 	movl   $0x350,0x4(%esp)
f01020c1:	00 
f01020c2:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f01020c9:	e8 c6 df ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01020ce:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01020d3:	74 24                	je     f01020f9 <mem_init+0xf2d>
f01020d5:	c7 44 24 0c d0 44 10 	movl   $0xf01044d0,0xc(%esp)
f01020dc:	f0 
f01020dd:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f01020e4:	f0 
f01020e5:	c7 44 24 04 51 03 00 	movl   $0x351,0x4(%esp)
f01020ec:	00 
f01020ed:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f01020f4:	e8 9b df ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f01020f9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102100:	e8 2e ed ff ff       	call   f0100e33 <page_alloc>
f0102105:	85 c0                	test   %eax,%eax
f0102107:	74 04                	je     f010210d <mem_init+0xf41>
f0102109:	39 c6                	cmp    %eax,%esi
f010210b:	74 24                	je     f0102131 <mem_init+0xf65>
f010210d:	c7 44 24 0c 80 4a 10 	movl   $0xf0104a80,0xc(%esp)
f0102114:	f0 
f0102115:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f010211c:	f0 
f010211d:	c7 44 24 04 54 03 00 	movl   $0x354,0x4(%esp)
f0102124:	00 
f0102125:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f010212c:	e8 63 df ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0102131:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102138:	00 
f0102139:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010213e:	89 04 24             	mov    %eax,(%esp)
f0102141:	e8 c0 ef ff ff       	call   f0101106 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102146:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f010214c:	ba 00 00 00 00       	mov    $0x0,%edx
f0102151:	89 f8                	mov    %edi,%eax
f0102153:	e8 ba e8 ff ff       	call   f0100a12 <check_va2pa>
f0102158:	83 f8 ff             	cmp    $0xffffffff,%eax
f010215b:	74 24                	je     f0102181 <mem_init+0xfb5>
f010215d:	c7 44 24 0c a4 4a 10 	movl   $0xf0104aa4,0xc(%esp)
f0102164:	f0 
f0102165:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f010216c:	f0 
f010216d:	c7 44 24 04 58 03 00 	movl   $0x358,0x4(%esp)
f0102174:	00 
f0102175:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f010217c:	e8 13 df ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102181:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102186:	89 f8                	mov    %edi,%eax
f0102188:	e8 85 e8 ff ff       	call   f0100a12 <check_va2pa>
f010218d:	89 da                	mov    %ebx,%edx
f010218f:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0102195:	c1 fa 03             	sar    $0x3,%edx
f0102198:	c1 e2 0c             	shl    $0xc,%edx
f010219b:	39 d0                	cmp    %edx,%eax
f010219d:	74 24                	je     f01021c3 <mem_init+0xff7>
f010219f:	c7 44 24 0c 50 4a 10 	movl   $0xf0104a50,0xc(%esp)
f01021a6:	f0 
f01021a7:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f01021ae:	f0 
f01021af:	c7 44 24 04 59 03 00 	movl   $0x359,0x4(%esp)
f01021b6:	00 
f01021b7:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f01021be:	e8 d1 de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f01021c3:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01021c8:	74 24                	je     f01021ee <mem_init+0x1022>
f01021ca:	c7 44 24 0c 76 44 10 	movl   $0xf0104476,0xc(%esp)
f01021d1:	f0 
f01021d2:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f01021d9:	f0 
f01021da:	c7 44 24 04 5a 03 00 	movl   $0x35a,0x4(%esp)
f01021e1:	00 
f01021e2:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f01021e9:	e8 a6 de ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01021ee:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01021f3:	74 24                	je     f0102219 <mem_init+0x104d>
f01021f5:	c7 44 24 0c d0 44 10 	movl   $0xf01044d0,0xc(%esp)
f01021fc:	f0 
f01021fd:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0102204:	f0 
f0102205:	c7 44 24 04 5b 03 00 	movl   $0x35b,0x4(%esp)
f010220c:	00 
f010220d:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0102214:	e8 7b de ff ff       	call   f0100094 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102219:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0102220:	00 
f0102221:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102228:	00 
f0102229:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010222d:	89 3c 24             	mov    %edi,(%esp)
f0102230:	e8 16 ef ff ff       	call   f010114b <page_insert>
f0102235:	85 c0                	test   %eax,%eax
f0102237:	74 24                	je     f010225d <mem_init+0x1091>
f0102239:	c7 44 24 0c c8 4a 10 	movl   $0xf0104ac8,0xc(%esp)
f0102240:	f0 
f0102241:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0102248:	f0 
f0102249:	c7 44 24 04 5e 03 00 	movl   $0x35e,0x4(%esp)
f0102250:	00 
f0102251:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0102258:	e8 37 de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref);
f010225d:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102262:	75 24                	jne    f0102288 <mem_init+0x10bc>
f0102264:	c7 44 24 0c e1 44 10 	movl   $0xf01044e1,0xc(%esp)
f010226b:	f0 
f010226c:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0102273:	f0 
f0102274:	c7 44 24 04 5f 03 00 	movl   $0x35f,0x4(%esp)
f010227b:	00 
f010227c:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0102283:	e8 0c de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_link == NULL);
f0102288:	83 3b 00             	cmpl   $0x0,(%ebx)
f010228b:	74 24                	je     f01022b1 <mem_init+0x10e5>
f010228d:	c7 44 24 0c ed 44 10 	movl   $0xf01044ed,0xc(%esp)
f0102294:	f0 
f0102295:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f010229c:	f0 
f010229d:	c7 44 24 04 60 03 00 	movl   $0x360,0x4(%esp)
f01022a4:	00 
f01022a5:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f01022ac:	e8 e3 dd ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01022b1:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01022b8:	00 
f01022b9:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01022be:	89 04 24             	mov    %eax,(%esp)
f01022c1:	e8 40 ee ff ff       	call   f0101106 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01022c6:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f01022cc:	ba 00 00 00 00       	mov    $0x0,%edx
f01022d1:	89 f8                	mov    %edi,%eax
f01022d3:	e8 3a e7 ff ff       	call   f0100a12 <check_va2pa>
f01022d8:	83 f8 ff             	cmp    $0xffffffff,%eax
f01022db:	74 24                	je     f0102301 <mem_init+0x1135>
f01022dd:	c7 44 24 0c a4 4a 10 	movl   $0xf0104aa4,0xc(%esp)
f01022e4:	f0 
f01022e5:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f01022ec:	f0 
f01022ed:	c7 44 24 04 64 03 00 	movl   $0x364,0x4(%esp)
f01022f4:	00 
f01022f5:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f01022fc:	e8 93 dd ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102301:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102306:	89 f8                	mov    %edi,%eax
f0102308:	e8 05 e7 ff ff       	call   f0100a12 <check_va2pa>
f010230d:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102310:	74 24                	je     f0102336 <mem_init+0x116a>
f0102312:	c7 44 24 0c 00 4b 10 	movl   $0xf0104b00,0xc(%esp)
f0102319:	f0 
f010231a:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0102321:	f0 
f0102322:	c7 44 24 04 65 03 00 	movl   $0x365,0x4(%esp)
f0102329:	00 
f010232a:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0102331:	e8 5e dd ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102336:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010233b:	74 24                	je     f0102361 <mem_init+0x1195>
f010233d:	c7 44 24 0c 02 45 10 	movl   $0xf0104502,0xc(%esp)
f0102344:	f0 
f0102345:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f010234c:	f0 
f010234d:	c7 44 24 04 66 03 00 	movl   $0x366,0x4(%esp)
f0102354:	00 
f0102355:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f010235c:	e8 33 dd ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102361:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102366:	74 24                	je     f010238c <mem_init+0x11c0>
f0102368:	c7 44 24 0c d0 44 10 	movl   $0xf01044d0,0xc(%esp)
f010236f:	f0 
f0102370:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0102377:	f0 
f0102378:	c7 44 24 04 67 03 00 	movl   $0x367,0x4(%esp)
f010237f:	00 
f0102380:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0102387:	e8 08 dd ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f010238c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102393:	e8 9b ea ff ff       	call   f0100e33 <page_alloc>
f0102398:	85 c0                	test   %eax,%eax
f010239a:	74 04                	je     f01023a0 <mem_init+0x11d4>
f010239c:	39 c3                	cmp    %eax,%ebx
f010239e:	74 24                	je     f01023c4 <mem_init+0x11f8>
f01023a0:	c7 44 24 0c 28 4b 10 	movl   $0xf0104b28,0xc(%esp)
f01023a7:	f0 
f01023a8:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f01023af:	f0 
f01023b0:	c7 44 24 04 6a 03 00 	movl   $0x36a,0x4(%esp)
f01023b7:	00 
f01023b8:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f01023bf:	e8 d0 dc ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01023c4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01023cb:	e8 63 ea ff ff       	call   f0100e33 <page_alloc>
f01023d0:	85 c0                	test   %eax,%eax
f01023d2:	74 24                	je     f01023f8 <mem_init+0x122c>
f01023d4:	c7 44 24 0c 24 44 10 	movl   $0xf0104424,0xc(%esp)
f01023db:	f0 
f01023dc:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f01023e3:	f0 
f01023e4:	c7 44 24 04 6d 03 00 	movl   $0x36d,0x4(%esp)
f01023eb:	00 
f01023ec:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f01023f3:	e8 9c dc ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01023f8:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01023fd:	8b 08                	mov    (%eax),%ecx
f01023ff:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102405:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102408:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f010240e:	c1 fa 03             	sar    $0x3,%edx
f0102411:	c1 e2 0c             	shl    $0xc,%edx
f0102414:	39 d1                	cmp    %edx,%ecx
f0102416:	74 24                	je     f010243c <mem_init+0x1270>
f0102418:	c7 44 24 0c cc 47 10 	movl   $0xf01047cc,0xc(%esp)
f010241f:	f0 
f0102420:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0102427:	f0 
f0102428:	c7 44 24 04 70 03 00 	movl   $0x370,0x4(%esp)
f010242f:	00 
f0102430:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0102437:	e8 58 dc ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f010243c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102442:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102445:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010244a:	74 24                	je     f0102470 <mem_init+0x12a4>
f010244c:	c7 44 24 0c 87 44 10 	movl   $0xf0104487,0xc(%esp)
f0102453:	f0 
f0102454:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f010245b:	f0 
f010245c:	c7 44 24 04 72 03 00 	movl   $0x372,0x4(%esp)
f0102463:	00 
f0102464:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f010246b:	e8 24 dc ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102470:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102473:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102479:	89 04 24             	mov    %eax,(%esp)
f010247c:	e8 3d ea ff ff       	call   f0100ebe <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102481:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102488:	00 
f0102489:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f0102490:	00 
f0102491:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102496:	89 04 24             	mov    %eax,(%esp)
f0102499:	e8 80 ea ff ff       	call   f0100f1e <pgdir_walk>
f010249e:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01024a1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01024a4:	8b 15 68 79 11 f0    	mov    0xf0117968,%edx
f01024aa:	8b 7a 04             	mov    0x4(%edx),%edi
f01024ad:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024b3:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f01024b9:	89 f8                	mov    %edi,%eax
f01024bb:	c1 e8 0c             	shr    $0xc,%eax
f01024be:	39 c8                	cmp    %ecx,%eax
f01024c0:	72 20                	jb     f01024e2 <mem_init+0x1316>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024c2:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01024c6:	c7 44 24 08 8c 45 10 	movl   $0xf010458c,0x8(%esp)
f01024cd:	f0 
f01024ce:	c7 44 24 04 79 03 00 	movl   $0x379,0x4(%esp)
f01024d5:	00 
f01024d6:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f01024dd:	e8 b2 db ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01024e2:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f01024e8:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f01024eb:	74 24                	je     f0102511 <mem_init+0x1345>
f01024ed:	c7 44 24 0c 13 45 10 	movl   $0xf0104513,0xc(%esp)
f01024f4:	f0 
f01024f5:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f01024fc:	f0 
f01024fd:	c7 44 24 04 7a 03 00 	movl   $0x37a,0x4(%esp)
f0102504:	00 
f0102505:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f010250c:	e8 83 db ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102511:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f0102518:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010251b:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102521:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0102527:	c1 f8 03             	sar    $0x3,%eax
f010252a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010252d:	89 c2                	mov    %eax,%edx
f010252f:	c1 ea 0c             	shr    $0xc,%edx
f0102532:	39 d1                	cmp    %edx,%ecx
f0102534:	77 20                	ja     f0102556 <mem_init+0x138a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102536:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010253a:	c7 44 24 08 8c 45 10 	movl   $0xf010458c,0x8(%esp)
f0102541:	f0 
f0102542:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102549:	00 
f010254a:	c7 04 24 a0 42 10 f0 	movl   $0xf01042a0,(%esp)
f0102551:	e8 3e db ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102556:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010255d:	00 
f010255e:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f0102565:	00 
	return (void *)(pa + KERNBASE);
f0102566:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010256b:	89 04 24             	mov    %eax,(%esp)
f010256e:	e8 44 13 00 00       	call   f01038b7 <memset>
	page_free(pp0);
f0102573:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102576:	89 3c 24             	mov    %edi,(%esp)
f0102579:	e8 40 e9 ff ff       	call   f0100ebe <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010257e:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102585:	00 
f0102586:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010258d:	00 
f010258e:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102593:	89 04 24             	mov    %eax,(%esp)
f0102596:	e8 83 e9 ff ff       	call   f0100f1e <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010259b:	89 fa                	mov    %edi,%edx
f010259d:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f01025a3:	c1 fa 03             	sar    $0x3,%edx
f01025a6:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025a9:	89 d0                	mov    %edx,%eax
f01025ab:	c1 e8 0c             	shr    $0xc,%eax
f01025ae:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f01025b4:	72 20                	jb     f01025d6 <mem_init+0x140a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025b6:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01025ba:	c7 44 24 08 8c 45 10 	movl   $0xf010458c,0x8(%esp)
f01025c1:	f0 
f01025c2:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01025c9:	00 
f01025ca:	c7 04 24 a0 42 10 f0 	movl   $0xf01042a0,(%esp)
f01025d1:	e8 be da ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f01025d6:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01025dc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01025df:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01025e5:	f6 00 01             	testb  $0x1,(%eax)
f01025e8:	74 24                	je     f010260e <mem_init+0x1442>
f01025ea:	c7 44 24 0c 2b 45 10 	movl   $0xf010452b,0xc(%esp)
f01025f1:	f0 
f01025f2:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f01025f9:	f0 
f01025fa:	c7 44 24 04 84 03 00 	movl   $0x384,0x4(%esp)
f0102601:	00 
f0102602:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0102609:	e8 86 da ff ff       	call   f0100094 <_panic>
f010260e:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102611:	39 d0                	cmp    %edx,%eax
f0102613:	75 d0                	jne    f01025e5 <mem_init+0x1419>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102615:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010261a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102620:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102623:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102629:	8b 7d d0             	mov    -0x30(%ebp),%edi
f010262c:	89 3d 3c 75 11 f0    	mov    %edi,0xf011753c

	// free the pages we took
	page_free(pp0);
f0102632:	89 04 24             	mov    %eax,(%esp)
f0102635:	e8 84 e8 ff ff       	call   f0100ebe <page_free>
	page_free(pp1);
f010263a:	89 1c 24             	mov    %ebx,(%esp)
f010263d:	e8 7c e8 ff ff       	call   f0100ebe <page_free>
	page_free(pp2);
f0102642:	89 34 24             	mov    %esi,(%esp)
f0102645:	e8 74 e8 ff ff       	call   f0100ebe <page_free>

	cprintf("check_page() succeeded!\n");
f010264a:	c7 04 24 42 45 10 f0 	movl   $0xf0104542,(%esp)
f0102651:	e8 10 07 00 00       	call   f0102d66 <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	//static void boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm);
boot_map_region(kern_pgdir, UPAGES, PTSIZE,PADDR(pages), PTE_U | PTE_P);
f0102656:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010265b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102660:	77 20                	ja     f0102682 <mem_init+0x14b6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102662:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102666:	c7 44 24 08 74 46 10 	movl   $0xf0104674,0x8(%esp)
f010266d:	f0 
f010266e:	c7 44 24 04 c6 00 00 	movl   $0xc6,0x4(%esp)
f0102675:	00 
f0102676:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f010267d:	e8 12 da ff ff       	call   f0100094 <_panic>
f0102682:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102689:	00 
	return (physaddr_t)kva - KERNBASE;
f010268a:	05 00 00 00 10       	add    $0x10000000,%eax
f010268f:	89 04 24             	mov    %eax,(%esp)
f0102692:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102697:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010269c:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01026a1:	e8 92 e9 ff ff       	call   f0101038 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026a6:	bb 00 d0 10 f0       	mov    $0xf010d000,%ebx
f01026ab:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f01026b1:	77 20                	ja     f01026d3 <mem_init+0x1507>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026b3:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01026b7:	c7 44 24 08 74 46 10 	movl   $0xf0104674,0x8(%esp)
f01026be:	f0 
f01026bf:	c7 44 24 04 d6 00 00 	movl   $0xd6,0x4(%esp)
f01026c6:	00 
f01026c7:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f01026ce:	e8 c1 d9 ff ff       	call   f0100094 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE,PADDR(bootstack), PTE_W );
f01026d3:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f01026da:	00 
f01026db:	c7 04 24 00 d0 10 00 	movl   $0x10d000,(%esp)
f01026e2:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01026e7:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01026ec:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01026f1:	e8 42 e9 ff ff       	call   f0101038 <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	uint64_t kern_map_length = 0x100000000 - (uint64_t) KERNBASE;
    boot_map_region(kern_pgdir, KERNBASE,kern_map_length ,0, PTE_W | PTE_P);
f01026f6:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f01026fd:	00 
f01026fe:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102705:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f010270a:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f010270f:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102714:	e8 1f e9 ff ff       	call   f0101038 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102719:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010271f:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0102724:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102727:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010272e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102733:	89 45 d0             	mov    %eax,-0x30(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102736:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f010273b:	89 45 cc             	mov    %eax,-0x34(%ebp)
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010273e:	89 45 c8             	mov    %eax,-0x38(%ebp)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
f0102741:	05 00 00 00 10       	add    $0x10000000,%eax
f0102746:	89 45 c4             	mov    %eax,-0x3c(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102749:	be 00 00 00 00       	mov    $0x0,%esi
f010274e:	eb 6d                	jmp    f01027bd <mem_init+0x15f1>
f0102750:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102756:	89 f8                	mov    %edi,%eax
f0102758:	e8 b5 e2 ff ff       	call   f0100a12 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010275d:	81 7d c8 ff ff ff ef 	cmpl   $0xefffffff,-0x38(%ebp)
f0102764:	77 23                	ja     f0102789 <mem_init+0x15bd>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102766:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102769:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010276d:	c7 44 24 08 74 46 10 	movl   $0xf0104674,0x8(%esp)
f0102774:	f0 
f0102775:	c7 44 24 04 c6 02 00 	movl   $0x2c6,0x4(%esp)
f010277c:	00 
f010277d:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0102784:	e8 0b d9 ff ff       	call   f0100094 <_panic>
f0102789:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f010278c:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010278f:	39 c2                	cmp    %eax,%edx
f0102791:	74 24                	je     f01027b7 <mem_init+0x15eb>
f0102793:	c7 44 24 0c 4c 4b 10 	movl   $0xf0104b4c,0xc(%esp)
f010279a:	f0 
f010279b:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f01027a2:	f0 
f01027a3:	c7 44 24 04 c6 02 00 	movl   $0x2c6,0x4(%esp)
f01027aa:	00 
f01027ab:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f01027b2:	e8 dd d8 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01027b7:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01027bd:	39 75 d0             	cmp    %esi,-0x30(%ebp)
f01027c0:	77 8e                	ja     f0102750 <mem_init+0x1584>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01027c2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01027c5:	c1 e0 0c             	shl    $0xc,%eax
f01027c8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01027cb:	be 00 00 00 00       	mov    $0x0,%esi
f01027d0:	eb 3b                	jmp    f010280d <mem_init+0x1641>
f01027d2:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01027d8:	89 f8                	mov    %edi,%eax
f01027da:	e8 33 e2 ff ff       	call   f0100a12 <check_va2pa>
f01027df:	39 c6                	cmp    %eax,%esi
f01027e1:	74 24                	je     f0102807 <mem_init+0x163b>
f01027e3:	c7 44 24 0c 80 4b 10 	movl   $0xf0104b80,0xc(%esp)
f01027ea:	f0 
f01027eb:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f01027f2:	f0 
f01027f3:	c7 44 24 04 cb 02 00 	movl   $0x2cb,0x4(%esp)
f01027fa:	00 
f01027fb:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0102802:	e8 8d d8 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102807:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010280d:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0102810:	72 c0                	jb     f01027d2 <mem_init+0x1606>
f0102812:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f0102817:	81 c3 00 80 00 20    	add    $0x20008000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010281d:	89 f2                	mov    %esi,%edx
f010281f:	89 f8                	mov    %edi,%eax
f0102821:	e8 ec e1 ff ff       	call   f0100a12 <check_va2pa>
f0102826:	8d 14 33             	lea    (%ebx,%esi,1),%edx
f0102829:	39 d0                	cmp    %edx,%eax
f010282b:	74 24                	je     f0102851 <mem_init+0x1685>
f010282d:	c7 44 24 0c a8 4b 10 	movl   $0xf0104ba8,0xc(%esp)
f0102834:	f0 
f0102835:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f010283c:	f0 
f010283d:	c7 44 24 04 cf 02 00 	movl   $0x2cf,0x4(%esp)
f0102844:	00 
f0102845:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f010284c:	e8 43 d8 ff ff       	call   f0100094 <_panic>
f0102851:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102857:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f010285d:	75 be                	jne    f010281d <mem_init+0x1651>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010285f:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102864:	89 f8                	mov    %edi,%eax
f0102866:	e8 a7 e1 ff ff       	call   f0100a12 <check_va2pa>
f010286b:	83 f8 ff             	cmp    $0xffffffff,%eax
f010286e:	75 0a                	jne    f010287a <mem_init+0x16ae>
f0102870:	b8 00 00 00 00       	mov    $0x0,%eax
f0102875:	e9 f0 00 00 00       	jmp    f010296a <mem_init+0x179e>
f010287a:	c7 44 24 0c f0 4b 10 	movl   $0xf0104bf0,0xc(%esp)
f0102881:	f0 
f0102882:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0102889:	f0 
f010288a:	c7 44 24 04 d0 02 00 	movl   $0x2d0,0x4(%esp)
f0102891:	00 
f0102892:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0102899:	e8 f6 d7 ff ff       	call   f0100094 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f010289e:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f01028a3:	72 3c                	jb     f01028e1 <mem_init+0x1715>
f01028a5:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f01028aa:	76 07                	jbe    f01028b3 <mem_init+0x16e7>
f01028ac:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01028b1:	75 2e                	jne    f01028e1 <mem_init+0x1715>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f01028b3:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f01028b7:	0f 85 aa 00 00 00    	jne    f0102967 <mem_init+0x179b>
f01028bd:	c7 44 24 0c 5b 45 10 	movl   $0xf010455b,0xc(%esp)
f01028c4:	f0 
f01028c5:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f01028cc:	f0 
f01028cd:	c7 44 24 04 d8 02 00 	movl   $0x2d8,0x4(%esp)
f01028d4:	00 
f01028d5:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f01028dc:	e8 b3 d7 ff ff       	call   f0100094 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01028e1:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01028e6:	76 55                	jbe    f010293d <mem_init+0x1771>
				assert(pgdir[i] & PTE_P);
f01028e8:	8b 14 87             	mov    (%edi,%eax,4),%edx
f01028eb:	f6 c2 01             	test   $0x1,%dl
f01028ee:	75 24                	jne    f0102914 <mem_init+0x1748>
f01028f0:	c7 44 24 0c 5b 45 10 	movl   $0xf010455b,0xc(%esp)
f01028f7:	f0 
f01028f8:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f01028ff:	f0 
f0102900:	c7 44 24 04 dc 02 00 	movl   $0x2dc,0x4(%esp)
f0102907:	00 
f0102908:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f010290f:	e8 80 d7 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f0102914:	f6 c2 02             	test   $0x2,%dl
f0102917:	75 4e                	jne    f0102967 <mem_init+0x179b>
f0102919:	c7 44 24 0c 6c 45 10 	movl   $0xf010456c,0xc(%esp)
f0102920:	f0 
f0102921:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0102928:	f0 
f0102929:	c7 44 24 04 dd 02 00 	movl   $0x2dd,0x4(%esp)
f0102930:	00 
f0102931:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0102938:	e8 57 d7 ff ff       	call   f0100094 <_panic>
			} else
				assert(pgdir[i] == 0);
f010293d:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f0102941:	74 24                	je     f0102967 <mem_init+0x179b>
f0102943:	c7 44 24 0c 7d 45 10 	movl   $0xf010457d,0xc(%esp)
f010294a:	f0 
f010294b:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0102952:	f0 
f0102953:	c7 44 24 04 df 02 00 	movl   $0x2df,0x4(%esp)
f010295a:	00 
f010295b:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0102962:	e8 2d d7 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102967:	83 c0 01             	add    $0x1,%eax
f010296a:	3d 00 04 00 00       	cmp    $0x400,%eax
f010296f:	0f 85 29 ff ff ff    	jne    f010289e <mem_init+0x16d2>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102975:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f010297c:	e8 e5 03 00 00       	call   f0102d66 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102981:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102986:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010298b:	77 20                	ja     f01029ad <mem_init+0x17e1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010298d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102991:	c7 44 24 08 74 46 10 	movl   $0xf0104674,0x8(%esp)
f0102998:	f0 
f0102999:	c7 44 24 04 ee 00 00 	movl   $0xee,0x4(%esp)
f01029a0:	00 
f01029a1:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f01029a8:	e8 e7 d6 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01029ad:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01029b2:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01029b5:	b8 00 00 00 00       	mov    $0x0,%eax
f01029ba:	e8 c2 e0 ff ff       	call   f0100a81 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f01029bf:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f01029c2:	83 e0 f3             	and    $0xfffffff3,%eax
f01029c5:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f01029ca:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01029cd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01029d4:	e8 5a e4 ff ff       	call   f0100e33 <page_alloc>
f01029d9:	89 c3                	mov    %eax,%ebx
f01029db:	85 c0                	test   %eax,%eax
f01029dd:	75 24                	jne    f0102a03 <mem_init+0x1837>
f01029df:	c7 44 24 0c 79 43 10 	movl   $0xf0104379,0xc(%esp)
f01029e6:	f0 
f01029e7:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f01029ee:	f0 
f01029ef:	c7 44 24 04 9f 03 00 	movl   $0x39f,0x4(%esp)
f01029f6:	00 
f01029f7:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f01029fe:	e8 91 d6 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0102a03:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a0a:	e8 24 e4 ff ff       	call   f0100e33 <page_alloc>
f0102a0f:	89 c7                	mov    %eax,%edi
f0102a11:	85 c0                	test   %eax,%eax
f0102a13:	75 24                	jne    f0102a39 <mem_init+0x186d>
f0102a15:	c7 44 24 0c 8f 43 10 	movl   $0xf010438f,0xc(%esp)
f0102a1c:	f0 
f0102a1d:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0102a24:	f0 
f0102a25:	c7 44 24 04 a0 03 00 	movl   $0x3a0,0x4(%esp)
f0102a2c:	00 
f0102a2d:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0102a34:	e8 5b d6 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0102a39:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a40:	e8 ee e3 ff ff       	call   f0100e33 <page_alloc>
f0102a45:	89 c6                	mov    %eax,%esi
f0102a47:	85 c0                	test   %eax,%eax
f0102a49:	75 24                	jne    f0102a6f <mem_init+0x18a3>
f0102a4b:	c7 44 24 0c a5 43 10 	movl   $0xf01043a5,0xc(%esp)
f0102a52:	f0 
f0102a53:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0102a5a:	f0 
f0102a5b:	c7 44 24 04 a1 03 00 	movl   $0x3a1,0x4(%esp)
f0102a62:	00 
f0102a63:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0102a6a:	e8 25 d6 ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f0102a6f:	89 1c 24             	mov    %ebx,(%esp)
f0102a72:	e8 47 e4 ff ff       	call   f0100ebe <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f0102a77:	89 f8                	mov    %edi,%eax
f0102a79:	e8 4f df ff ff       	call   f01009cd <page2kva>
f0102a7e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102a85:	00 
f0102a86:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102a8d:	00 
f0102a8e:	89 04 24             	mov    %eax,(%esp)
f0102a91:	e8 21 0e 00 00       	call   f01038b7 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f0102a96:	89 f0                	mov    %esi,%eax
f0102a98:	e8 30 df ff ff       	call   f01009cd <page2kva>
f0102a9d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102aa4:	00 
f0102aa5:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102aac:	00 
f0102aad:	89 04 24             	mov    %eax,(%esp)
f0102ab0:	e8 02 0e 00 00       	call   f01038b7 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102ab5:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102abc:	00 
f0102abd:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102ac4:	00 
f0102ac5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102ac9:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102ace:	89 04 24             	mov    %eax,(%esp)
f0102ad1:	e8 75 e6 ff ff       	call   f010114b <page_insert>
	assert(pp1->pp_ref == 1);
f0102ad6:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102adb:	74 24                	je     f0102b01 <mem_init+0x1935>
f0102add:	c7 44 24 0c 76 44 10 	movl   $0xf0104476,0xc(%esp)
f0102ae4:	f0 
f0102ae5:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0102aec:	f0 
f0102aed:	c7 44 24 04 a6 03 00 	movl   $0x3a6,0x4(%esp)
f0102af4:	00 
f0102af5:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0102afc:	e8 93 d5 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102b01:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102b08:	01 01 01 
f0102b0b:	74 24                	je     f0102b31 <mem_init+0x1965>
f0102b0d:	c7 44 24 0c 40 4c 10 	movl   $0xf0104c40,0xc(%esp)
f0102b14:	f0 
f0102b15:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0102b1c:	f0 
f0102b1d:	c7 44 24 04 a7 03 00 	movl   $0x3a7,0x4(%esp)
f0102b24:	00 
f0102b25:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0102b2c:	e8 63 d5 ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102b31:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102b38:	00 
f0102b39:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102b40:	00 
f0102b41:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102b45:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102b4a:	89 04 24             	mov    %eax,(%esp)
f0102b4d:	e8 f9 e5 ff ff       	call   f010114b <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102b52:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102b59:	02 02 02 
f0102b5c:	74 24                	je     f0102b82 <mem_init+0x19b6>
f0102b5e:	c7 44 24 0c 64 4c 10 	movl   $0xf0104c64,0xc(%esp)
f0102b65:	f0 
f0102b66:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0102b6d:	f0 
f0102b6e:	c7 44 24 04 a9 03 00 	movl   $0x3a9,0x4(%esp)
f0102b75:	00 
f0102b76:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0102b7d:	e8 12 d5 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102b82:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102b87:	74 24                	je     f0102bad <mem_init+0x19e1>
f0102b89:	c7 44 24 0c 98 44 10 	movl   $0xf0104498,0xc(%esp)
f0102b90:	f0 
f0102b91:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0102b98:	f0 
f0102b99:	c7 44 24 04 aa 03 00 	movl   $0x3aa,0x4(%esp)
f0102ba0:	00 
f0102ba1:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0102ba8:	e8 e7 d4 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102bad:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102bb2:	74 24                	je     f0102bd8 <mem_init+0x1a0c>
f0102bb4:	c7 44 24 0c 02 45 10 	movl   $0xf0104502,0xc(%esp)
f0102bbb:	f0 
f0102bbc:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0102bc3:	f0 
f0102bc4:	c7 44 24 04 ab 03 00 	movl   $0x3ab,0x4(%esp)
f0102bcb:	00 
f0102bcc:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0102bd3:	e8 bc d4 ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102bd8:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102bdf:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102be2:	89 f0                	mov    %esi,%eax
f0102be4:	e8 e4 dd ff ff       	call   f01009cd <page2kva>
f0102be9:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f0102bef:	74 24                	je     f0102c15 <mem_init+0x1a49>
f0102bf1:	c7 44 24 0c 88 4c 10 	movl   $0xf0104c88,0xc(%esp)
f0102bf8:	f0 
f0102bf9:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0102c00:	f0 
f0102c01:	c7 44 24 04 ad 03 00 	movl   $0x3ad,0x4(%esp)
f0102c08:	00 
f0102c09:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0102c10:	e8 7f d4 ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102c15:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102c1c:	00 
f0102c1d:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102c22:	89 04 24             	mov    %eax,(%esp)
f0102c25:	e8 dc e4 ff ff       	call   f0101106 <page_remove>
	assert(pp2->pp_ref == 0);
f0102c2a:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102c2f:	74 24                	je     f0102c55 <mem_init+0x1a89>
f0102c31:	c7 44 24 0c d0 44 10 	movl   $0xf01044d0,0xc(%esp)
f0102c38:	f0 
f0102c39:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0102c40:	f0 
f0102c41:	c7 44 24 04 af 03 00 	movl   $0x3af,0x4(%esp)
f0102c48:	00 
f0102c49:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0102c50:	e8 3f d4 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102c55:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102c5a:	8b 08                	mov    (%eax),%ecx
f0102c5c:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102c62:	89 da                	mov    %ebx,%edx
f0102c64:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0102c6a:	c1 fa 03             	sar    $0x3,%edx
f0102c6d:	c1 e2 0c             	shl    $0xc,%edx
f0102c70:	39 d1                	cmp    %edx,%ecx
f0102c72:	74 24                	je     f0102c98 <mem_init+0x1acc>
f0102c74:	c7 44 24 0c cc 47 10 	movl   $0xf01047cc,0xc(%esp)
f0102c7b:	f0 
f0102c7c:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0102c83:	f0 
f0102c84:	c7 44 24 04 b2 03 00 	movl   $0x3b2,0x4(%esp)
f0102c8b:	00 
f0102c8c:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0102c93:	e8 fc d3 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102c98:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102c9e:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102ca3:	74 24                	je     f0102cc9 <mem_init+0x1afd>
f0102ca5:	c7 44 24 0c 87 44 10 	movl   $0xf0104487,0xc(%esp)
f0102cac:	f0 
f0102cad:	c7 44 24 08 ba 42 10 	movl   $0xf01042ba,0x8(%esp)
f0102cb4:	f0 
f0102cb5:	c7 44 24 04 b4 03 00 	movl   $0x3b4,0x4(%esp)
f0102cbc:	00 
f0102cbd:	c7 04 24 94 42 10 f0 	movl   $0xf0104294,(%esp)
f0102cc4:	e8 cb d3 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102cc9:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102ccf:	89 1c 24             	mov    %ebx,(%esp)
f0102cd2:	e8 e7 e1 ff ff       	call   f0100ebe <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102cd7:	c7 04 24 b4 4c 10 f0 	movl   $0xf0104cb4,(%esp)
f0102cde:	e8 83 00 00 00       	call   f0102d66 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102ce3:	83 c4 4c             	add    $0x4c,%esp
f0102ce6:	5b                   	pop    %ebx
f0102ce7:	5e                   	pop    %esi
f0102ce8:	5f                   	pop    %edi
f0102ce9:	5d                   	pop    %ebp
f0102cea:	c3                   	ret    

f0102ceb <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102ceb:	55                   	push   %ebp
f0102cec:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102cee:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102cf1:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102cf4:	5d                   	pop    %ebp
f0102cf5:	c3                   	ret    

f0102cf6 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102cf6:	55                   	push   %ebp
f0102cf7:	89 e5                	mov    %esp,%ebp
f0102cf9:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102cfd:	ba 70 00 00 00       	mov    $0x70,%edx
f0102d02:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102d03:	b2 71                	mov    $0x71,%dl
f0102d05:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102d06:	0f b6 c0             	movzbl %al,%eax
}
f0102d09:	5d                   	pop    %ebp
f0102d0a:	c3                   	ret    

f0102d0b <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102d0b:	55                   	push   %ebp
f0102d0c:	89 e5                	mov    %esp,%ebp
f0102d0e:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102d12:	ba 70 00 00 00       	mov    $0x70,%edx
f0102d17:	ee                   	out    %al,(%dx)
f0102d18:	b2 71                	mov    $0x71,%dl
f0102d1a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d1d:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102d1e:	5d                   	pop    %ebp
f0102d1f:	c3                   	ret    

f0102d20 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102d20:	55                   	push   %ebp
f0102d21:	89 e5                	mov    %esp,%ebp
f0102d23:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0102d26:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d29:	89 04 24             	mov    %eax,(%esp)
f0102d2c:	e8 d0 d8 ff ff       	call   f0100601 <cputchar>
	*cnt++;
}
f0102d31:	c9                   	leave  
f0102d32:	c3                   	ret    

f0102d33 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102d33:	55                   	push   %ebp
f0102d34:	89 e5                	mov    %esp,%ebp
f0102d36:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0102d39:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102d40:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d43:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102d47:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d4a:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102d4e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102d51:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d55:	c7 04 24 20 2d 10 f0 	movl   $0xf0102d20,(%esp)
f0102d5c:	e8 9d 04 00 00       	call   f01031fe <vprintfmt>
	return cnt;
}
f0102d61:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102d64:	c9                   	leave  
f0102d65:	c3                   	ret    

f0102d66 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102d66:	55                   	push   %ebp
f0102d67:	89 e5                	mov    %esp,%ebp
f0102d69:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102d6c:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102d6f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d73:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d76:	89 04 24             	mov    %eax,(%esp)
f0102d79:	e8 b5 ff ff ff       	call   f0102d33 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102d7e:	c9                   	leave  
f0102d7f:	c3                   	ret    

f0102d80 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102d80:	55                   	push   %ebp
f0102d81:	89 e5                	mov    %esp,%ebp
f0102d83:	57                   	push   %edi
f0102d84:	56                   	push   %esi
f0102d85:	53                   	push   %ebx
f0102d86:	83 ec 10             	sub    $0x10,%esp
f0102d89:	89 c6                	mov    %eax,%esi
f0102d8b:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0102d8e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0102d91:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102d94:	8b 1a                	mov    (%edx),%ebx
f0102d96:	8b 01                	mov    (%ecx),%eax
f0102d98:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102d9b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0102da2:	eb 77                	jmp    f0102e1b <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0102da4:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102da7:	01 d8                	add    %ebx,%eax
f0102da9:	b9 02 00 00 00       	mov    $0x2,%ecx
f0102dae:	99                   	cltd   
f0102daf:	f7 f9                	idiv   %ecx
f0102db1:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102db3:	eb 01                	jmp    f0102db6 <stab_binsearch+0x36>
			m--;
f0102db5:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102db6:	39 d9                	cmp    %ebx,%ecx
f0102db8:	7c 1d                	jl     f0102dd7 <stab_binsearch+0x57>
f0102dba:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0102dbd:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0102dc2:	39 fa                	cmp    %edi,%edx
f0102dc4:	75 ef                	jne    f0102db5 <stab_binsearch+0x35>
f0102dc6:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102dc9:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0102dcc:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0102dd0:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102dd3:	73 18                	jae    f0102ded <stab_binsearch+0x6d>
f0102dd5:	eb 05                	jmp    f0102ddc <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102dd7:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0102dda:	eb 3f                	jmp    f0102e1b <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0102ddc:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0102ddf:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0102de1:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102de4:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102deb:	eb 2e                	jmp    f0102e1b <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102ded:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102df0:	73 15                	jae    f0102e07 <stab_binsearch+0x87>
			*region_right = m - 1;
f0102df2:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102df5:	48                   	dec    %eax
f0102df6:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102df9:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102dfc:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102dfe:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102e05:	eb 14                	jmp    f0102e1b <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102e07:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102e0a:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0102e0d:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0102e0f:	ff 45 0c             	incl   0xc(%ebp)
f0102e12:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102e14:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0102e1b:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102e1e:	7e 84                	jle    f0102da4 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102e20:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0102e24:	75 0d                	jne    f0102e33 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0102e26:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102e29:	8b 00                	mov    (%eax),%eax
f0102e2b:	48                   	dec    %eax
f0102e2c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102e2f:	89 07                	mov    %eax,(%edi)
f0102e31:	eb 22                	jmp    f0102e55 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102e33:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102e36:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102e38:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0102e3b:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102e3d:	eb 01                	jmp    f0102e40 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102e3f:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102e40:	39 c1                	cmp    %eax,%ecx
f0102e42:	7d 0c                	jge    f0102e50 <stab_binsearch+0xd0>
f0102e44:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0102e47:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0102e4c:	39 fa                	cmp    %edi,%edx
f0102e4e:	75 ef                	jne    f0102e3f <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102e50:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0102e53:	89 07                	mov    %eax,(%edi)
	}
}
f0102e55:	83 c4 10             	add    $0x10,%esp
f0102e58:	5b                   	pop    %ebx
f0102e59:	5e                   	pop    %esi
f0102e5a:	5f                   	pop    %edi
f0102e5b:	5d                   	pop    %ebp
f0102e5c:	c3                   	ret    

f0102e5d <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102e5d:	55                   	push   %ebp
f0102e5e:	89 e5                	mov    %esp,%ebp
f0102e60:	57                   	push   %edi
f0102e61:	56                   	push   %esi
f0102e62:	53                   	push   %ebx
f0102e63:	83 ec 3c             	sub    $0x3c,%esp
f0102e66:	8b 75 08             	mov    0x8(%ebp),%esi
f0102e69:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102e6c:	c7 03 e0 4c 10 f0    	movl   $0xf0104ce0,(%ebx)
	info->eip_line = 0;
f0102e72:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102e79:	c7 43 08 e0 4c 10 f0 	movl   $0xf0104ce0,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102e80:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102e87:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102e8a:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102e91:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102e97:	76 12                	jbe    f0102eab <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102e99:	b8 f3 c8 10 f0       	mov    $0xf010c8f3,%eax
f0102e9e:	3d 01 ab 10 f0       	cmp    $0xf010ab01,%eax
f0102ea3:	0f 86 ba 01 00 00    	jbe    f0103063 <debuginfo_eip+0x206>
f0102ea9:	eb 1c                	jmp    f0102ec7 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102eab:	c7 44 24 08 ea 4c 10 	movl   $0xf0104cea,0x8(%esp)
f0102eb2:	f0 
f0102eb3:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0102eba:	00 
f0102ebb:	c7 04 24 f7 4c 10 f0 	movl   $0xf0104cf7,(%esp)
f0102ec2:	e8 cd d1 ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102ec7:	80 3d f2 c8 10 f0 00 	cmpb   $0x0,0xf010c8f2
f0102ece:	0f 85 96 01 00 00    	jne    f010306a <debuginfo_eip+0x20d>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102ed4:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102edb:	b8 00 ab 10 f0       	mov    $0xf010ab00,%eax
f0102ee0:	2d 14 4f 10 f0       	sub    $0xf0104f14,%eax
f0102ee5:	c1 f8 02             	sar    $0x2,%eax
f0102ee8:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102eee:	83 e8 01             	sub    $0x1,%eax
f0102ef1:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102ef4:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102ef8:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0102eff:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102f02:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102f05:	b8 14 4f 10 f0       	mov    $0xf0104f14,%eax
f0102f0a:	e8 71 fe ff ff       	call   f0102d80 <stab_binsearch>
	if (lfile == 0)
f0102f0f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102f12:	85 c0                	test   %eax,%eax
f0102f14:	0f 84 57 01 00 00    	je     f0103071 <debuginfo_eip+0x214>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102f1a:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102f1d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102f20:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102f23:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102f27:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0102f2e:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102f31:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102f34:	b8 14 4f 10 f0       	mov    $0xf0104f14,%eax
f0102f39:	e8 42 fe ff ff       	call   f0102d80 <stab_binsearch>

	if (lfun <= rfun) {
f0102f3e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102f41:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102f44:	39 d0                	cmp    %edx,%eax
f0102f46:	7f 3d                	jg     f0102f85 <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102f48:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0102f4b:	8d b9 14 4f 10 f0    	lea    -0xfefb0ec(%ecx),%edi
f0102f51:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0102f54:	8b 89 14 4f 10 f0    	mov    -0xfefb0ec(%ecx),%ecx
f0102f5a:	bf f3 c8 10 f0       	mov    $0xf010c8f3,%edi
f0102f5f:	81 ef 01 ab 10 f0    	sub    $0xf010ab01,%edi
f0102f65:	39 f9                	cmp    %edi,%ecx
f0102f67:	73 09                	jae    f0102f72 <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102f69:	81 c1 01 ab 10 f0    	add    $0xf010ab01,%ecx
f0102f6f:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102f72:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102f75:	8b 4f 08             	mov    0x8(%edi),%ecx
f0102f78:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0102f7b:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0102f7d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0102f80:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102f83:	eb 0f                	jmp    f0102f94 <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102f85:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102f88:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102f8b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0102f8e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102f91:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102f94:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0102f9b:	00 
f0102f9c:	8b 43 08             	mov    0x8(%ebx),%eax
f0102f9f:	89 04 24             	mov    %eax,(%esp)
f0102fa2:	e8 f4 08 00 00       	call   f010389b <strfind>
f0102fa7:	2b 43 08             	sub    0x8(%ebx),%eax
f0102faa:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

          stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); 
f0102fad:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102fb1:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0102fb8:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0102fbb:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0102fbe:	b8 14 4f 10 f0       	mov    $0xf0104f14,%eax
f0102fc3:	e8 b8 fd ff ff       	call   f0102d80 <stab_binsearch>
          info->eip_line = stabs[lline].n_desc;
f0102fc8:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102fcb:	6b c2 0c             	imul   $0xc,%edx,%eax
f0102fce:	05 14 4f 10 f0       	add    $0xf0104f14,%eax
f0102fd3:	0f b7 48 06          	movzwl 0x6(%eax),%ecx
f0102fd7:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102fda:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102fdd:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0102fe0:	eb 06                	jmp    f0102fe8 <debuginfo_eip+0x18b>
f0102fe2:	83 ea 01             	sub    $0x1,%edx
f0102fe5:	83 e8 0c             	sub    $0xc,%eax
f0102fe8:	89 d6                	mov    %edx,%esi
f0102fea:	39 55 c4             	cmp    %edx,-0x3c(%ebp)
f0102fed:	7f 33                	jg     f0103022 <debuginfo_eip+0x1c5>
	       && stabs[lline].n_type != N_SOL
f0102fef:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0102ff3:	80 f9 84             	cmp    $0x84,%cl
f0102ff6:	74 0b                	je     f0103003 <debuginfo_eip+0x1a6>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102ff8:	80 f9 64             	cmp    $0x64,%cl
f0102ffb:	75 e5                	jne    f0102fe2 <debuginfo_eip+0x185>
f0102ffd:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0103001:	74 df                	je     f0102fe2 <debuginfo_eip+0x185>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103003:	6b f6 0c             	imul   $0xc,%esi,%esi
f0103006:	8b 86 14 4f 10 f0    	mov    -0xfefb0ec(%esi),%eax
f010300c:	ba f3 c8 10 f0       	mov    $0xf010c8f3,%edx
f0103011:	81 ea 01 ab 10 f0    	sub    $0xf010ab01,%edx
f0103017:	39 d0                	cmp    %edx,%eax
f0103019:	73 07                	jae    f0103022 <debuginfo_eip+0x1c5>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010301b:	05 01 ab 10 f0       	add    $0xf010ab01,%eax
f0103020:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103022:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103025:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103028:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010302d:	39 ca                	cmp    %ecx,%edx
f010302f:	7d 4c                	jge    f010307d <debuginfo_eip+0x220>
		for (lline = lfun + 1;
f0103031:	8d 42 01             	lea    0x1(%edx),%eax
f0103034:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103037:	89 c2                	mov    %eax,%edx
f0103039:	6b c0 0c             	imul   $0xc,%eax,%eax
f010303c:	05 14 4f 10 f0       	add    $0xf0104f14,%eax
f0103041:	89 ce                	mov    %ecx,%esi
f0103043:	eb 04                	jmp    f0103049 <debuginfo_eip+0x1ec>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0103045:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103049:	39 d6                	cmp    %edx,%esi
f010304b:	7e 2b                	jle    f0103078 <debuginfo_eip+0x21b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010304d:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0103051:	83 c2 01             	add    $0x1,%edx
f0103054:	83 c0 0c             	add    $0xc,%eax
f0103057:	80 f9 a0             	cmp    $0xa0,%cl
f010305a:	74 e9                	je     f0103045 <debuginfo_eip+0x1e8>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010305c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103061:	eb 1a                	jmp    f010307d <debuginfo_eip+0x220>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103063:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103068:	eb 13                	jmp    f010307d <debuginfo_eip+0x220>
f010306a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010306f:	eb 0c                	jmp    f010307d <debuginfo_eip+0x220>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0103071:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103076:	eb 05                	jmp    f010307d <debuginfo_eip+0x220>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103078:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010307d:	83 c4 3c             	add    $0x3c,%esp
f0103080:	5b                   	pop    %ebx
f0103081:	5e                   	pop    %esi
f0103082:	5f                   	pop    %edi
f0103083:	5d                   	pop    %ebp
f0103084:	c3                   	ret    
f0103085:	66 90                	xchg   %ax,%ax
f0103087:	66 90                	xchg   %ax,%ax
f0103089:	66 90                	xchg   %ax,%ax
f010308b:	66 90                	xchg   %ax,%ax
f010308d:	66 90                	xchg   %ax,%ax
f010308f:	90                   	nop

f0103090 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103090:	55                   	push   %ebp
f0103091:	89 e5                	mov    %esp,%ebp
f0103093:	57                   	push   %edi
f0103094:	56                   	push   %esi
f0103095:	53                   	push   %ebx
f0103096:	83 ec 3c             	sub    $0x3c,%esp
f0103099:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010309c:	89 d7                	mov    %edx,%edi
f010309e:	8b 45 08             	mov    0x8(%ebp),%eax
f01030a1:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01030a4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030a7:	89 c3                	mov    %eax,%ebx
f01030a9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01030ac:	8b 45 10             	mov    0x10(%ebp),%eax
f01030af:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01030b2:	b9 00 00 00 00       	mov    $0x0,%ecx
f01030b7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01030ba:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01030bd:	39 d9                	cmp    %ebx,%ecx
f01030bf:	72 05                	jb     f01030c6 <printnum+0x36>
f01030c1:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f01030c4:	77 69                	ja     f010312f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01030c6:	8b 4d 18             	mov    0x18(%ebp),%ecx
f01030c9:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01030cd:	83 ee 01             	sub    $0x1,%esi
f01030d0:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01030d4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01030d8:	8b 44 24 08          	mov    0x8(%esp),%eax
f01030dc:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01030e0:	89 c3                	mov    %eax,%ebx
f01030e2:	89 d6                	mov    %edx,%esi
f01030e4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01030e7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01030ea:	89 54 24 08          	mov    %edx,0x8(%esp)
f01030ee:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01030f2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01030f5:	89 04 24             	mov    %eax,(%esp)
f01030f8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01030fb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01030ff:	e8 bc 09 00 00       	call   f0103ac0 <__udivdi3>
f0103104:	89 d9                	mov    %ebx,%ecx
f0103106:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010310a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010310e:	89 04 24             	mov    %eax,(%esp)
f0103111:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103115:	89 fa                	mov    %edi,%edx
f0103117:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010311a:	e8 71 ff ff ff       	call   f0103090 <printnum>
f010311f:	eb 1b                	jmp    f010313c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103121:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103125:	8b 45 18             	mov    0x18(%ebp),%eax
f0103128:	89 04 24             	mov    %eax,(%esp)
f010312b:	ff d3                	call   *%ebx
f010312d:	eb 03                	jmp    f0103132 <printnum+0xa2>
f010312f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103132:	83 ee 01             	sub    $0x1,%esi
f0103135:	85 f6                	test   %esi,%esi
f0103137:	7f e8                	jg     f0103121 <printnum+0x91>
f0103139:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010313c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103140:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103144:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103147:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010314a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010314e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103152:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103155:	89 04 24             	mov    %eax,(%esp)
f0103158:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010315b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010315f:	e8 8c 0a 00 00       	call   f0103bf0 <__umoddi3>
f0103164:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103168:	0f be 80 05 4d 10 f0 	movsbl -0xfefb2fb(%eax),%eax
f010316f:	89 04 24             	mov    %eax,(%esp)
f0103172:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103175:	ff d0                	call   *%eax
}
f0103177:	83 c4 3c             	add    $0x3c,%esp
f010317a:	5b                   	pop    %ebx
f010317b:	5e                   	pop    %esi
f010317c:	5f                   	pop    %edi
f010317d:	5d                   	pop    %ebp
f010317e:	c3                   	ret    

f010317f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f010317f:	55                   	push   %ebp
f0103180:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103182:	83 fa 01             	cmp    $0x1,%edx
f0103185:	7e 0e                	jle    f0103195 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103187:	8b 10                	mov    (%eax),%edx
f0103189:	8d 4a 08             	lea    0x8(%edx),%ecx
f010318c:	89 08                	mov    %ecx,(%eax)
f010318e:	8b 02                	mov    (%edx),%eax
f0103190:	8b 52 04             	mov    0x4(%edx),%edx
f0103193:	eb 22                	jmp    f01031b7 <getuint+0x38>
	else if (lflag)
f0103195:	85 d2                	test   %edx,%edx
f0103197:	74 10                	je     f01031a9 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103199:	8b 10                	mov    (%eax),%edx
f010319b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010319e:	89 08                	mov    %ecx,(%eax)
f01031a0:	8b 02                	mov    (%edx),%eax
f01031a2:	ba 00 00 00 00       	mov    $0x0,%edx
f01031a7:	eb 0e                	jmp    f01031b7 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01031a9:	8b 10                	mov    (%eax),%edx
f01031ab:	8d 4a 04             	lea    0x4(%edx),%ecx
f01031ae:	89 08                	mov    %ecx,(%eax)
f01031b0:	8b 02                	mov    (%edx),%eax
f01031b2:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01031b7:	5d                   	pop    %ebp
f01031b8:	c3                   	ret    

f01031b9 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01031b9:	55                   	push   %ebp
f01031ba:	89 e5                	mov    %esp,%ebp
f01031bc:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01031bf:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01031c3:	8b 10                	mov    (%eax),%edx
f01031c5:	3b 50 04             	cmp    0x4(%eax),%edx
f01031c8:	73 0a                	jae    f01031d4 <sprintputch+0x1b>
		*b->buf++ = ch;
f01031ca:	8d 4a 01             	lea    0x1(%edx),%ecx
f01031cd:	89 08                	mov    %ecx,(%eax)
f01031cf:	8b 45 08             	mov    0x8(%ebp),%eax
f01031d2:	88 02                	mov    %al,(%edx)
}
f01031d4:	5d                   	pop    %ebp
f01031d5:	c3                   	ret    

f01031d6 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01031d6:	55                   	push   %ebp
f01031d7:	89 e5                	mov    %esp,%ebp
f01031d9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f01031dc:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01031df:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01031e3:	8b 45 10             	mov    0x10(%ebp),%eax
f01031e6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01031ea:	8b 45 0c             	mov    0xc(%ebp),%eax
f01031ed:	89 44 24 04          	mov    %eax,0x4(%esp)
f01031f1:	8b 45 08             	mov    0x8(%ebp),%eax
f01031f4:	89 04 24             	mov    %eax,(%esp)
f01031f7:	e8 02 00 00 00       	call   f01031fe <vprintfmt>
	va_end(ap);
}
f01031fc:	c9                   	leave  
f01031fd:	c3                   	ret    

f01031fe <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01031fe:	55                   	push   %ebp
f01031ff:	89 e5                	mov    %esp,%ebp
f0103201:	57                   	push   %edi
f0103202:	56                   	push   %esi
f0103203:	53                   	push   %ebx
f0103204:	83 ec 3c             	sub    $0x3c,%esp
f0103207:	8b 7d 0c             	mov    0xc(%ebp),%edi
f010320a:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010320d:	eb 14                	jmp    f0103223 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010320f:	85 c0                	test   %eax,%eax
f0103211:	0f 84 b3 03 00 00    	je     f01035ca <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f0103217:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010321b:	89 04 24             	mov    %eax,(%esp)
f010321e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103221:	89 f3                	mov    %esi,%ebx
f0103223:	8d 73 01             	lea    0x1(%ebx),%esi
f0103226:	0f b6 03             	movzbl (%ebx),%eax
f0103229:	83 f8 25             	cmp    $0x25,%eax
f010322c:	75 e1                	jne    f010320f <vprintfmt+0x11>
f010322e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0103232:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103239:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0103240:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0103247:	ba 00 00 00 00       	mov    $0x0,%edx
f010324c:	eb 1d                	jmp    f010326b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010324e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0103250:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0103254:	eb 15                	jmp    f010326b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103256:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103258:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f010325c:	eb 0d                	jmp    f010326b <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f010325e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103261:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103264:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010326b:	8d 5e 01             	lea    0x1(%esi),%ebx
f010326e:	0f b6 0e             	movzbl (%esi),%ecx
f0103271:	0f b6 c1             	movzbl %cl,%eax
f0103274:	83 e9 23             	sub    $0x23,%ecx
f0103277:	80 f9 55             	cmp    $0x55,%cl
f010327a:	0f 87 2a 03 00 00    	ja     f01035aa <vprintfmt+0x3ac>
f0103280:	0f b6 c9             	movzbl %cl,%ecx
f0103283:	ff 24 8d 90 4d 10 f0 	jmp    *-0xfefb270(,%ecx,4)
f010328a:	89 de                	mov    %ebx,%esi
f010328c:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103291:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0103294:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0103298:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f010329b:	8d 58 d0             	lea    -0x30(%eax),%ebx
f010329e:	83 fb 09             	cmp    $0x9,%ebx
f01032a1:	77 36                	ja     f01032d9 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01032a3:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f01032a6:	eb e9                	jmp    f0103291 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01032a8:	8b 45 14             	mov    0x14(%ebp),%eax
f01032ab:	8d 48 04             	lea    0x4(%eax),%ecx
f01032ae:	89 4d 14             	mov    %ecx,0x14(%ebp)
f01032b1:	8b 00                	mov    (%eax),%eax
f01032b3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032b6:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01032b8:	eb 22                	jmp    f01032dc <vprintfmt+0xde>
f01032ba:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01032bd:	85 c9                	test   %ecx,%ecx
f01032bf:	b8 00 00 00 00       	mov    $0x0,%eax
f01032c4:	0f 49 c1             	cmovns %ecx,%eax
f01032c7:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032ca:	89 de                	mov    %ebx,%esi
f01032cc:	eb 9d                	jmp    f010326b <vprintfmt+0x6d>
f01032ce:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01032d0:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f01032d7:	eb 92                	jmp    f010326b <vprintfmt+0x6d>
f01032d9:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f01032dc:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01032e0:	79 89                	jns    f010326b <vprintfmt+0x6d>
f01032e2:	e9 77 ff ff ff       	jmp    f010325e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01032e7:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032ea:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f01032ec:	e9 7a ff ff ff       	jmp    f010326b <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01032f1:	8b 45 14             	mov    0x14(%ebp),%eax
f01032f4:	8d 50 04             	lea    0x4(%eax),%edx
f01032f7:	89 55 14             	mov    %edx,0x14(%ebp)
f01032fa:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01032fe:	8b 00                	mov    (%eax),%eax
f0103300:	89 04 24             	mov    %eax,(%esp)
f0103303:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103306:	e9 18 ff ff ff       	jmp    f0103223 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010330b:	8b 45 14             	mov    0x14(%ebp),%eax
f010330e:	8d 50 04             	lea    0x4(%eax),%edx
f0103311:	89 55 14             	mov    %edx,0x14(%ebp)
f0103314:	8b 00                	mov    (%eax),%eax
f0103316:	99                   	cltd   
f0103317:	31 d0                	xor    %edx,%eax
f0103319:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010331b:	83 f8 06             	cmp    $0x6,%eax
f010331e:	7f 0b                	jg     f010332b <vprintfmt+0x12d>
f0103320:	8b 14 85 e8 4e 10 f0 	mov    -0xfefb118(,%eax,4),%edx
f0103327:	85 d2                	test   %edx,%edx
f0103329:	75 20                	jne    f010334b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f010332b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010332f:	c7 44 24 08 1d 4d 10 	movl   $0xf0104d1d,0x8(%esp)
f0103336:	f0 
f0103337:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010333b:	8b 45 08             	mov    0x8(%ebp),%eax
f010333e:	89 04 24             	mov    %eax,(%esp)
f0103341:	e8 90 fe ff ff       	call   f01031d6 <printfmt>
f0103346:	e9 d8 fe ff ff       	jmp    f0103223 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f010334b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010334f:	c7 44 24 08 cc 42 10 	movl   $0xf01042cc,0x8(%esp)
f0103356:	f0 
f0103357:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010335b:	8b 45 08             	mov    0x8(%ebp),%eax
f010335e:	89 04 24             	mov    %eax,(%esp)
f0103361:	e8 70 fe ff ff       	call   f01031d6 <printfmt>
f0103366:	e9 b8 fe ff ff       	jmp    f0103223 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010336b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010336e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103371:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103374:	8b 45 14             	mov    0x14(%ebp),%eax
f0103377:	8d 50 04             	lea    0x4(%eax),%edx
f010337a:	89 55 14             	mov    %edx,0x14(%ebp)
f010337d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f010337f:	85 f6                	test   %esi,%esi
f0103381:	b8 16 4d 10 f0       	mov    $0xf0104d16,%eax
f0103386:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0103389:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f010338d:	0f 84 97 00 00 00    	je     f010342a <vprintfmt+0x22c>
f0103393:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0103397:	0f 8e 9b 00 00 00    	jle    f0103438 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f010339d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01033a1:	89 34 24             	mov    %esi,(%esp)
f01033a4:	e8 9f 03 00 00       	call   f0103748 <strnlen>
f01033a9:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01033ac:	29 c2                	sub    %eax,%edx
f01033ae:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f01033b1:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f01033b5:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01033b8:	89 75 d8             	mov    %esi,-0x28(%ebp)
f01033bb:	8b 75 08             	mov    0x8(%ebp),%esi
f01033be:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01033c1:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01033c3:	eb 0f                	jmp    f01033d4 <vprintfmt+0x1d6>
					putch(padc, putdat);
f01033c5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01033c9:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01033cc:	89 04 24             	mov    %eax,(%esp)
f01033cf:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01033d1:	83 eb 01             	sub    $0x1,%ebx
f01033d4:	85 db                	test   %ebx,%ebx
f01033d6:	7f ed                	jg     f01033c5 <vprintfmt+0x1c7>
f01033d8:	8b 75 d8             	mov    -0x28(%ebp),%esi
f01033db:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01033de:	85 d2                	test   %edx,%edx
f01033e0:	b8 00 00 00 00       	mov    $0x0,%eax
f01033e5:	0f 49 c2             	cmovns %edx,%eax
f01033e8:	29 c2                	sub    %eax,%edx
f01033ea:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01033ed:	89 d7                	mov    %edx,%edi
f01033ef:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01033f2:	eb 50                	jmp    f0103444 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01033f4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01033f8:	74 1e                	je     f0103418 <vprintfmt+0x21a>
f01033fa:	0f be d2             	movsbl %dl,%edx
f01033fd:	83 ea 20             	sub    $0x20,%edx
f0103400:	83 fa 5e             	cmp    $0x5e,%edx
f0103403:	76 13                	jbe    f0103418 <vprintfmt+0x21a>
					putch('?', putdat);
f0103405:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103408:	89 44 24 04          	mov    %eax,0x4(%esp)
f010340c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0103413:	ff 55 08             	call   *0x8(%ebp)
f0103416:	eb 0d                	jmp    f0103425 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f0103418:	8b 55 0c             	mov    0xc(%ebp),%edx
f010341b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010341f:	89 04 24             	mov    %eax,(%esp)
f0103422:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103425:	83 ef 01             	sub    $0x1,%edi
f0103428:	eb 1a                	jmp    f0103444 <vprintfmt+0x246>
f010342a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010342d:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0103430:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103433:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103436:	eb 0c                	jmp    f0103444 <vprintfmt+0x246>
f0103438:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010343b:	8b 7d dc             	mov    -0x24(%ebp),%edi
f010343e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103441:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103444:	83 c6 01             	add    $0x1,%esi
f0103447:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f010344b:	0f be c2             	movsbl %dl,%eax
f010344e:	85 c0                	test   %eax,%eax
f0103450:	74 27                	je     f0103479 <vprintfmt+0x27b>
f0103452:	85 db                	test   %ebx,%ebx
f0103454:	78 9e                	js     f01033f4 <vprintfmt+0x1f6>
f0103456:	83 eb 01             	sub    $0x1,%ebx
f0103459:	79 99                	jns    f01033f4 <vprintfmt+0x1f6>
f010345b:	89 f8                	mov    %edi,%eax
f010345d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0103460:	8b 75 08             	mov    0x8(%ebp),%esi
f0103463:	89 c3                	mov    %eax,%ebx
f0103465:	eb 1a                	jmp    f0103481 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103467:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010346b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0103472:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103474:	83 eb 01             	sub    $0x1,%ebx
f0103477:	eb 08                	jmp    f0103481 <vprintfmt+0x283>
f0103479:	89 fb                	mov    %edi,%ebx
f010347b:	8b 75 08             	mov    0x8(%ebp),%esi
f010347e:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0103481:	85 db                	test   %ebx,%ebx
f0103483:	7f e2                	jg     f0103467 <vprintfmt+0x269>
f0103485:	89 75 08             	mov    %esi,0x8(%ebp)
f0103488:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010348b:	e9 93 fd ff ff       	jmp    f0103223 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103490:	83 fa 01             	cmp    $0x1,%edx
f0103493:	7e 16                	jle    f01034ab <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f0103495:	8b 45 14             	mov    0x14(%ebp),%eax
f0103498:	8d 50 08             	lea    0x8(%eax),%edx
f010349b:	89 55 14             	mov    %edx,0x14(%ebp)
f010349e:	8b 50 04             	mov    0x4(%eax),%edx
f01034a1:	8b 00                	mov    (%eax),%eax
f01034a3:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01034a6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01034a9:	eb 32                	jmp    f01034dd <vprintfmt+0x2df>
	else if (lflag)
f01034ab:	85 d2                	test   %edx,%edx
f01034ad:	74 18                	je     f01034c7 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f01034af:	8b 45 14             	mov    0x14(%ebp),%eax
f01034b2:	8d 50 04             	lea    0x4(%eax),%edx
f01034b5:	89 55 14             	mov    %edx,0x14(%ebp)
f01034b8:	8b 30                	mov    (%eax),%esi
f01034ba:	89 75 e0             	mov    %esi,-0x20(%ebp)
f01034bd:	89 f0                	mov    %esi,%eax
f01034bf:	c1 f8 1f             	sar    $0x1f,%eax
f01034c2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01034c5:	eb 16                	jmp    f01034dd <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f01034c7:	8b 45 14             	mov    0x14(%ebp),%eax
f01034ca:	8d 50 04             	lea    0x4(%eax),%edx
f01034cd:	89 55 14             	mov    %edx,0x14(%ebp)
f01034d0:	8b 30                	mov    (%eax),%esi
f01034d2:	89 75 e0             	mov    %esi,-0x20(%ebp)
f01034d5:	89 f0                	mov    %esi,%eax
f01034d7:	c1 f8 1f             	sar    $0x1f,%eax
f01034da:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01034dd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01034e0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01034e3:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01034e8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01034ec:	0f 89 80 00 00 00    	jns    f0103572 <vprintfmt+0x374>
				putch('-', putdat);
f01034f2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01034f6:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01034fd:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0103500:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103503:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103506:	f7 d8                	neg    %eax
f0103508:	83 d2 00             	adc    $0x0,%edx
f010350b:	f7 da                	neg    %edx
			}
			base = 10;
f010350d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0103512:	eb 5e                	jmp    f0103572 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103514:	8d 45 14             	lea    0x14(%ebp),%eax
f0103517:	e8 63 fc ff ff       	call   f010317f <getuint>
			base = 10;
f010351c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0103521:	eb 4f                	jmp    f0103572 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0103523:	8d 45 14             	lea    0x14(%ebp),%eax
f0103526:	e8 54 fc ff ff       	call   f010317f <getuint>
			base = 8;
f010352b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0103530:	eb 40                	jmp    f0103572 <vprintfmt+0x374>

		// pointer
		case 'p':
			putch('0', putdat);
f0103532:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103536:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010353d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0103540:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103544:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010354b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010354e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103551:	8d 50 04             	lea    0x4(%eax),%edx
f0103554:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103557:	8b 00                	mov    (%eax),%eax
f0103559:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010355e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0103563:	eb 0d                	jmp    f0103572 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103565:	8d 45 14             	lea    0x14(%ebp),%eax
f0103568:	e8 12 fc ff ff       	call   f010317f <getuint>
			base = 16;
f010356d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103572:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f0103576:	89 74 24 10          	mov    %esi,0x10(%esp)
f010357a:	8b 75 dc             	mov    -0x24(%ebp),%esi
f010357d:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103581:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103585:	89 04 24             	mov    %eax,(%esp)
f0103588:	89 54 24 04          	mov    %edx,0x4(%esp)
f010358c:	89 fa                	mov    %edi,%edx
f010358e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103591:	e8 fa fa ff ff       	call   f0103090 <printnum>
			break;
f0103596:	e9 88 fc ff ff       	jmp    f0103223 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010359b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010359f:	89 04 24             	mov    %eax,(%esp)
f01035a2:	ff 55 08             	call   *0x8(%ebp)
			break;
f01035a5:	e9 79 fc ff ff       	jmp    f0103223 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01035aa:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01035ae:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01035b5:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01035b8:	89 f3                	mov    %esi,%ebx
f01035ba:	eb 03                	jmp    f01035bf <vprintfmt+0x3c1>
f01035bc:	83 eb 01             	sub    $0x1,%ebx
f01035bf:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f01035c3:	75 f7                	jne    f01035bc <vprintfmt+0x3be>
f01035c5:	e9 59 fc ff ff       	jmp    f0103223 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f01035ca:	83 c4 3c             	add    $0x3c,%esp
f01035cd:	5b                   	pop    %ebx
f01035ce:	5e                   	pop    %esi
f01035cf:	5f                   	pop    %edi
f01035d0:	5d                   	pop    %ebp
f01035d1:	c3                   	ret    

f01035d2 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01035d2:	55                   	push   %ebp
f01035d3:	89 e5                	mov    %esp,%ebp
f01035d5:	83 ec 28             	sub    $0x28,%esp
f01035d8:	8b 45 08             	mov    0x8(%ebp),%eax
f01035db:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01035de:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01035e1:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01035e5:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01035e8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01035ef:	85 c0                	test   %eax,%eax
f01035f1:	74 30                	je     f0103623 <vsnprintf+0x51>
f01035f3:	85 d2                	test   %edx,%edx
f01035f5:	7e 2c                	jle    f0103623 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01035f7:	8b 45 14             	mov    0x14(%ebp),%eax
f01035fa:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01035fe:	8b 45 10             	mov    0x10(%ebp),%eax
f0103601:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103605:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103608:	89 44 24 04          	mov    %eax,0x4(%esp)
f010360c:	c7 04 24 b9 31 10 f0 	movl   $0xf01031b9,(%esp)
f0103613:	e8 e6 fb ff ff       	call   f01031fe <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103618:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010361b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010361e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103621:	eb 05                	jmp    f0103628 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103623:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103628:	c9                   	leave  
f0103629:	c3                   	ret    

f010362a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010362a:	55                   	push   %ebp
f010362b:	89 e5                	mov    %esp,%ebp
f010362d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103630:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103633:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103637:	8b 45 10             	mov    0x10(%ebp),%eax
f010363a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010363e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103641:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103645:	8b 45 08             	mov    0x8(%ebp),%eax
f0103648:	89 04 24             	mov    %eax,(%esp)
f010364b:	e8 82 ff ff ff       	call   f01035d2 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103650:	c9                   	leave  
f0103651:	c3                   	ret    
f0103652:	66 90                	xchg   %ax,%ax
f0103654:	66 90                	xchg   %ax,%ax
f0103656:	66 90                	xchg   %ax,%ax
f0103658:	66 90                	xchg   %ax,%ax
f010365a:	66 90                	xchg   %ax,%ax
f010365c:	66 90                	xchg   %ax,%ax
f010365e:	66 90                	xchg   %ax,%ax

f0103660 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103660:	55                   	push   %ebp
f0103661:	89 e5                	mov    %esp,%ebp
f0103663:	57                   	push   %edi
f0103664:	56                   	push   %esi
f0103665:	53                   	push   %ebx
f0103666:	83 ec 1c             	sub    $0x1c,%esp
f0103669:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010366c:	85 c0                	test   %eax,%eax
f010366e:	74 10                	je     f0103680 <readline+0x20>
		cprintf("%s", prompt);
f0103670:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103674:	c7 04 24 cc 42 10 f0 	movl   $0xf01042cc,(%esp)
f010367b:	e8 e6 f6 ff ff       	call   f0102d66 <cprintf>

	i = 0;
	echoing = iscons(0);
f0103680:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103687:	e8 96 cf ff ff       	call   f0100622 <iscons>
f010368c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010368e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103693:	e8 79 cf ff ff       	call   f0100611 <getchar>
f0103698:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010369a:	85 c0                	test   %eax,%eax
f010369c:	79 17                	jns    f01036b5 <readline+0x55>
			cprintf("read error: %e\n", c);
f010369e:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036a2:	c7 04 24 04 4f 10 f0 	movl   $0xf0104f04,(%esp)
f01036a9:	e8 b8 f6 ff ff       	call   f0102d66 <cprintf>
			return NULL;
f01036ae:	b8 00 00 00 00       	mov    $0x0,%eax
f01036b3:	eb 6d                	jmp    f0103722 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01036b5:	83 f8 7f             	cmp    $0x7f,%eax
f01036b8:	74 05                	je     f01036bf <readline+0x5f>
f01036ba:	83 f8 08             	cmp    $0x8,%eax
f01036bd:	75 19                	jne    f01036d8 <readline+0x78>
f01036bf:	85 f6                	test   %esi,%esi
f01036c1:	7e 15                	jle    f01036d8 <readline+0x78>
			if (echoing)
f01036c3:	85 ff                	test   %edi,%edi
f01036c5:	74 0c                	je     f01036d3 <readline+0x73>
				cputchar('\b');
f01036c7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01036ce:	e8 2e cf ff ff       	call   f0100601 <cputchar>
			i--;
f01036d3:	83 ee 01             	sub    $0x1,%esi
f01036d6:	eb bb                	jmp    f0103693 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01036d8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01036de:	7f 1c                	jg     f01036fc <readline+0x9c>
f01036e0:	83 fb 1f             	cmp    $0x1f,%ebx
f01036e3:	7e 17                	jle    f01036fc <readline+0x9c>
			if (echoing)
f01036e5:	85 ff                	test   %edi,%edi
f01036e7:	74 08                	je     f01036f1 <readline+0x91>
				cputchar(c);
f01036e9:	89 1c 24             	mov    %ebx,(%esp)
f01036ec:	e8 10 cf ff ff       	call   f0100601 <cputchar>
			buf[i++] = c;
f01036f1:	88 9e 60 75 11 f0    	mov    %bl,-0xfee8aa0(%esi)
f01036f7:	8d 76 01             	lea    0x1(%esi),%esi
f01036fa:	eb 97                	jmp    f0103693 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01036fc:	83 fb 0d             	cmp    $0xd,%ebx
f01036ff:	74 05                	je     f0103706 <readline+0xa6>
f0103701:	83 fb 0a             	cmp    $0xa,%ebx
f0103704:	75 8d                	jne    f0103693 <readline+0x33>
			if (echoing)
f0103706:	85 ff                	test   %edi,%edi
f0103708:	74 0c                	je     f0103716 <readline+0xb6>
				cputchar('\n');
f010370a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0103711:	e8 eb ce ff ff       	call   f0100601 <cputchar>
			buf[i] = 0;
f0103716:	c6 86 60 75 11 f0 00 	movb   $0x0,-0xfee8aa0(%esi)
			return buf;
f010371d:	b8 60 75 11 f0       	mov    $0xf0117560,%eax
		}
	}
}
f0103722:	83 c4 1c             	add    $0x1c,%esp
f0103725:	5b                   	pop    %ebx
f0103726:	5e                   	pop    %esi
f0103727:	5f                   	pop    %edi
f0103728:	5d                   	pop    %ebp
f0103729:	c3                   	ret    
f010372a:	66 90                	xchg   %ax,%ax
f010372c:	66 90                	xchg   %ax,%ax
f010372e:	66 90                	xchg   %ax,%ax

f0103730 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103730:	55                   	push   %ebp
f0103731:	89 e5                	mov    %esp,%ebp
f0103733:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103736:	b8 00 00 00 00       	mov    $0x0,%eax
f010373b:	eb 03                	jmp    f0103740 <strlen+0x10>
		n++;
f010373d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103740:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103744:	75 f7                	jne    f010373d <strlen+0xd>
		n++;
	return n;
}
f0103746:	5d                   	pop    %ebp
f0103747:	c3                   	ret    

f0103748 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103748:	55                   	push   %ebp
f0103749:	89 e5                	mov    %esp,%ebp
f010374b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010374e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103751:	b8 00 00 00 00       	mov    $0x0,%eax
f0103756:	eb 03                	jmp    f010375b <strnlen+0x13>
		n++;
f0103758:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010375b:	39 d0                	cmp    %edx,%eax
f010375d:	74 06                	je     f0103765 <strnlen+0x1d>
f010375f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0103763:	75 f3                	jne    f0103758 <strnlen+0x10>
		n++;
	return n;
}
f0103765:	5d                   	pop    %ebp
f0103766:	c3                   	ret    

f0103767 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103767:	55                   	push   %ebp
f0103768:	89 e5                	mov    %esp,%ebp
f010376a:	53                   	push   %ebx
f010376b:	8b 45 08             	mov    0x8(%ebp),%eax
f010376e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103771:	89 c2                	mov    %eax,%edx
f0103773:	83 c2 01             	add    $0x1,%edx
f0103776:	83 c1 01             	add    $0x1,%ecx
f0103779:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010377d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103780:	84 db                	test   %bl,%bl
f0103782:	75 ef                	jne    f0103773 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103784:	5b                   	pop    %ebx
f0103785:	5d                   	pop    %ebp
f0103786:	c3                   	ret    

f0103787 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103787:	55                   	push   %ebp
f0103788:	89 e5                	mov    %esp,%ebp
f010378a:	53                   	push   %ebx
f010378b:	83 ec 08             	sub    $0x8,%esp
f010378e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103791:	89 1c 24             	mov    %ebx,(%esp)
f0103794:	e8 97 ff ff ff       	call   f0103730 <strlen>
	strcpy(dst + len, src);
f0103799:	8b 55 0c             	mov    0xc(%ebp),%edx
f010379c:	89 54 24 04          	mov    %edx,0x4(%esp)
f01037a0:	01 d8                	add    %ebx,%eax
f01037a2:	89 04 24             	mov    %eax,(%esp)
f01037a5:	e8 bd ff ff ff       	call   f0103767 <strcpy>
	return dst;
}
f01037aa:	89 d8                	mov    %ebx,%eax
f01037ac:	83 c4 08             	add    $0x8,%esp
f01037af:	5b                   	pop    %ebx
f01037b0:	5d                   	pop    %ebp
f01037b1:	c3                   	ret    

f01037b2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01037b2:	55                   	push   %ebp
f01037b3:	89 e5                	mov    %esp,%ebp
f01037b5:	56                   	push   %esi
f01037b6:	53                   	push   %ebx
f01037b7:	8b 75 08             	mov    0x8(%ebp),%esi
f01037ba:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01037bd:	89 f3                	mov    %esi,%ebx
f01037bf:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01037c2:	89 f2                	mov    %esi,%edx
f01037c4:	eb 0f                	jmp    f01037d5 <strncpy+0x23>
		*dst++ = *src;
f01037c6:	83 c2 01             	add    $0x1,%edx
f01037c9:	0f b6 01             	movzbl (%ecx),%eax
f01037cc:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01037cf:	80 39 01             	cmpb   $0x1,(%ecx)
f01037d2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01037d5:	39 da                	cmp    %ebx,%edx
f01037d7:	75 ed                	jne    f01037c6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01037d9:	89 f0                	mov    %esi,%eax
f01037db:	5b                   	pop    %ebx
f01037dc:	5e                   	pop    %esi
f01037dd:	5d                   	pop    %ebp
f01037de:	c3                   	ret    

f01037df <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01037df:	55                   	push   %ebp
f01037e0:	89 e5                	mov    %esp,%ebp
f01037e2:	56                   	push   %esi
f01037e3:	53                   	push   %ebx
f01037e4:	8b 75 08             	mov    0x8(%ebp),%esi
f01037e7:	8b 55 0c             	mov    0xc(%ebp),%edx
f01037ea:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01037ed:	89 f0                	mov    %esi,%eax
f01037ef:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01037f3:	85 c9                	test   %ecx,%ecx
f01037f5:	75 0b                	jne    f0103802 <strlcpy+0x23>
f01037f7:	eb 1d                	jmp    f0103816 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01037f9:	83 c0 01             	add    $0x1,%eax
f01037fc:	83 c2 01             	add    $0x1,%edx
f01037ff:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103802:	39 d8                	cmp    %ebx,%eax
f0103804:	74 0b                	je     f0103811 <strlcpy+0x32>
f0103806:	0f b6 0a             	movzbl (%edx),%ecx
f0103809:	84 c9                	test   %cl,%cl
f010380b:	75 ec                	jne    f01037f9 <strlcpy+0x1a>
f010380d:	89 c2                	mov    %eax,%edx
f010380f:	eb 02                	jmp    f0103813 <strlcpy+0x34>
f0103811:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0103813:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0103816:	29 f0                	sub    %esi,%eax
}
f0103818:	5b                   	pop    %ebx
f0103819:	5e                   	pop    %esi
f010381a:	5d                   	pop    %ebp
f010381b:	c3                   	ret    

f010381c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010381c:	55                   	push   %ebp
f010381d:	89 e5                	mov    %esp,%ebp
f010381f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103822:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103825:	eb 06                	jmp    f010382d <strcmp+0x11>
		p++, q++;
f0103827:	83 c1 01             	add    $0x1,%ecx
f010382a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010382d:	0f b6 01             	movzbl (%ecx),%eax
f0103830:	84 c0                	test   %al,%al
f0103832:	74 04                	je     f0103838 <strcmp+0x1c>
f0103834:	3a 02                	cmp    (%edx),%al
f0103836:	74 ef                	je     f0103827 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103838:	0f b6 c0             	movzbl %al,%eax
f010383b:	0f b6 12             	movzbl (%edx),%edx
f010383e:	29 d0                	sub    %edx,%eax
}
f0103840:	5d                   	pop    %ebp
f0103841:	c3                   	ret    

f0103842 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103842:	55                   	push   %ebp
f0103843:	89 e5                	mov    %esp,%ebp
f0103845:	53                   	push   %ebx
f0103846:	8b 45 08             	mov    0x8(%ebp),%eax
f0103849:	8b 55 0c             	mov    0xc(%ebp),%edx
f010384c:	89 c3                	mov    %eax,%ebx
f010384e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103851:	eb 06                	jmp    f0103859 <strncmp+0x17>
		n--, p++, q++;
f0103853:	83 c0 01             	add    $0x1,%eax
f0103856:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103859:	39 d8                	cmp    %ebx,%eax
f010385b:	74 15                	je     f0103872 <strncmp+0x30>
f010385d:	0f b6 08             	movzbl (%eax),%ecx
f0103860:	84 c9                	test   %cl,%cl
f0103862:	74 04                	je     f0103868 <strncmp+0x26>
f0103864:	3a 0a                	cmp    (%edx),%cl
f0103866:	74 eb                	je     f0103853 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103868:	0f b6 00             	movzbl (%eax),%eax
f010386b:	0f b6 12             	movzbl (%edx),%edx
f010386e:	29 d0                	sub    %edx,%eax
f0103870:	eb 05                	jmp    f0103877 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103872:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103877:	5b                   	pop    %ebx
f0103878:	5d                   	pop    %ebp
f0103879:	c3                   	ret    

f010387a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010387a:	55                   	push   %ebp
f010387b:	89 e5                	mov    %esp,%ebp
f010387d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103880:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103884:	eb 07                	jmp    f010388d <strchr+0x13>
		if (*s == c)
f0103886:	38 ca                	cmp    %cl,%dl
f0103888:	74 0f                	je     f0103899 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010388a:	83 c0 01             	add    $0x1,%eax
f010388d:	0f b6 10             	movzbl (%eax),%edx
f0103890:	84 d2                	test   %dl,%dl
f0103892:	75 f2                	jne    f0103886 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0103894:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103899:	5d                   	pop    %ebp
f010389a:	c3                   	ret    

f010389b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010389b:	55                   	push   %ebp
f010389c:	89 e5                	mov    %esp,%ebp
f010389e:	8b 45 08             	mov    0x8(%ebp),%eax
f01038a1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01038a5:	eb 07                	jmp    f01038ae <strfind+0x13>
		if (*s == c)
f01038a7:	38 ca                	cmp    %cl,%dl
f01038a9:	74 0a                	je     f01038b5 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f01038ab:	83 c0 01             	add    $0x1,%eax
f01038ae:	0f b6 10             	movzbl (%eax),%edx
f01038b1:	84 d2                	test   %dl,%dl
f01038b3:	75 f2                	jne    f01038a7 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f01038b5:	5d                   	pop    %ebp
f01038b6:	c3                   	ret    

f01038b7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01038b7:	55                   	push   %ebp
f01038b8:	89 e5                	mov    %esp,%ebp
f01038ba:	57                   	push   %edi
f01038bb:	56                   	push   %esi
f01038bc:	53                   	push   %ebx
f01038bd:	8b 7d 08             	mov    0x8(%ebp),%edi
f01038c0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01038c3:	85 c9                	test   %ecx,%ecx
f01038c5:	74 36                	je     f01038fd <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01038c7:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01038cd:	75 28                	jne    f01038f7 <memset+0x40>
f01038cf:	f6 c1 03             	test   $0x3,%cl
f01038d2:	75 23                	jne    f01038f7 <memset+0x40>
		c &= 0xFF;
f01038d4:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01038d8:	89 d3                	mov    %edx,%ebx
f01038da:	c1 e3 08             	shl    $0x8,%ebx
f01038dd:	89 d6                	mov    %edx,%esi
f01038df:	c1 e6 18             	shl    $0x18,%esi
f01038e2:	89 d0                	mov    %edx,%eax
f01038e4:	c1 e0 10             	shl    $0x10,%eax
f01038e7:	09 f0                	or     %esi,%eax
f01038e9:	09 c2                	or     %eax,%edx
f01038eb:	89 d0                	mov    %edx,%eax
f01038ed:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01038ef:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01038f2:	fc                   	cld    
f01038f3:	f3 ab                	rep stos %eax,%es:(%edi)
f01038f5:	eb 06                	jmp    f01038fd <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01038f7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01038fa:	fc                   	cld    
f01038fb:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01038fd:	89 f8                	mov    %edi,%eax
f01038ff:	5b                   	pop    %ebx
f0103900:	5e                   	pop    %esi
f0103901:	5f                   	pop    %edi
f0103902:	5d                   	pop    %ebp
f0103903:	c3                   	ret    

f0103904 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103904:	55                   	push   %ebp
f0103905:	89 e5                	mov    %esp,%ebp
f0103907:	57                   	push   %edi
f0103908:	56                   	push   %esi
f0103909:	8b 45 08             	mov    0x8(%ebp),%eax
f010390c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010390f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103912:	39 c6                	cmp    %eax,%esi
f0103914:	73 35                	jae    f010394b <memmove+0x47>
f0103916:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103919:	39 d0                	cmp    %edx,%eax
f010391b:	73 2e                	jae    f010394b <memmove+0x47>
		s += n;
		d += n;
f010391d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0103920:	89 d6                	mov    %edx,%esi
f0103922:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103924:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010392a:	75 13                	jne    f010393f <memmove+0x3b>
f010392c:	f6 c1 03             	test   $0x3,%cl
f010392f:	75 0e                	jne    f010393f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103931:	83 ef 04             	sub    $0x4,%edi
f0103934:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103937:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010393a:	fd                   	std    
f010393b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010393d:	eb 09                	jmp    f0103948 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010393f:	83 ef 01             	sub    $0x1,%edi
f0103942:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103945:	fd                   	std    
f0103946:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103948:	fc                   	cld    
f0103949:	eb 1d                	jmp    f0103968 <memmove+0x64>
f010394b:	89 f2                	mov    %esi,%edx
f010394d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010394f:	f6 c2 03             	test   $0x3,%dl
f0103952:	75 0f                	jne    f0103963 <memmove+0x5f>
f0103954:	f6 c1 03             	test   $0x3,%cl
f0103957:	75 0a                	jne    f0103963 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103959:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010395c:	89 c7                	mov    %eax,%edi
f010395e:	fc                   	cld    
f010395f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103961:	eb 05                	jmp    f0103968 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103963:	89 c7                	mov    %eax,%edi
f0103965:	fc                   	cld    
f0103966:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103968:	5e                   	pop    %esi
f0103969:	5f                   	pop    %edi
f010396a:	5d                   	pop    %ebp
f010396b:	c3                   	ret    

f010396c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010396c:	55                   	push   %ebp
f010396d:	89 e5                	mov    %esp,%ebp
f010396f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0103972:	8b 45 10             	mov    0x10(%ebp),%eax
f0103975:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103979:	8b 45 0c             	mov    0xc(%ebp),%eax
f010397c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103980:	8b 45 08             	mov    0x8(%ebp),%eax
f0103983:	89 04 24             	mov    %eax,(%esp)
f0103986:	e8 79 ff ff ff       	call   f0103904 <memmove>
}
f010398b:	c9                   	leave  
f010398c:	c3                   	ret    

f010398d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010398d:	55                   	push   %ebp
f010398e:	89 e5                	mov    %esp,%ebp
f0103990:	56                   	push   %esi
f0103991:	53                   	push   %ebx
f0103992:	8b 55 08             	mov    0x8(%ebp),%edx
f0103995:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103998:	89 d6                	mov    %edx,%esi
f010399a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010399d:	eb 1a                	jmp    f01039b9 <memcmp+0x2c>
		if (*s1 != *s2)
f010399f:	0f b6 02             	movzbl (%edx),%eax
f01039a2:	0f b6 19             	movzbl (%ecx),%ebx
f01039a5:	38 d8                	cmp    %bl,%al
f01039a7:	74 0a                	je     f01039b3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01039a9:	0f b6 c0             	movzbl %al,%eax
f01039ac:	0f b6 db             	movzbl %bl,%ebx
f01039af:	29 d8                	sub    %ebx,%eax
f01039b1:	eb 0f                	jmp    f01039c2 <memcmp+0x35>
		s1++, s2++;
f01039b3:	83 c2 01             	add    $0x1,%edx
f01039b6:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01039b9:	39 f2                	cmp    %esi,%edx
f01039bb:	75 e2                	jne    f010399f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01039bd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01039c2:	5b                   	pop    %ebx
f01039c3:	5e                   	pop    %esi
f01039c4:	5d                   	pop    %ebp
f01039c5:	c3                   	ret    

f01039c6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01039c6:	55                   	push   %ebp
f01039c7:	89 e5                	mov    %esp,%ebp
f01039c9:	8b 45 08             	mov    0x8(%ebp),%eax
f01039cc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01039cf:	89 c2                	mov    %eax,%edx
f01039d1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01039d4:	eb 07                	jmp    f01039dd <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f01039d6:	38 08                	cmp    %cl,(%eax)
f01039d8:	74 07                	je     f01039e1 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01039da:	83 c0 01             	add    $0x1,%eax
f01039dd:	39 d0                	cmp    %edx,%eax
f01039df:	72 f5                	jb     f01039d6 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01039e1:	5d                   	pop    %ebp
f01039e2:	c3                   	ret    

f01039e3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01039e3:	55                   	push   %ebp
f01039e4:	89 e5                	mov    %esp,%ebp
f01039e6:	57                   	push   %edi
f01039e7:	56                   	push   %esi
f01039e8:	53                   	push   %ebx
f01039e9:	8b 55 08             	mov    0x8(%ebp),%edx
f01039ec:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01039ef:	eb 03                	jmp    f01039f4 <strtol+0x11>
		s++;
f01039f1:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01039f4:	0f b6 0a             	movzbl (%edx),%ecx
f01039f7:	80 f9 09             	cmp    $0x9,%cl
f01039fa:	74 f5                	je     f01039f1 <strtol+0xe>
f01039fc:	80 f9 20             	cmp    $0x20,%cl
f01039ff:	74 f0                	je     f01039f1 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103a01:	80 f9 2b             	cmp    $0x2b,%cl
f0103a04:	75 0a                	jne    f0103a10 <strtol+0x2d>
		s++;
f0103a06:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103a09:	bf 00 00 00 00       	mov    $0x0,%edi
f0103a0e:	eb 11                	jmp    f0103a21 <strtol+0x3e>
f0103a10:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103a15:	80 f9 2d             	cmp    $0x2d,%cl
f0103a18:	75 07                	jne    f0103a21 <strtol+0x3e>
		s++, neg = 1;
f0103a1a:	8d 52 01             	lea    0x1(%edx),%edx
f0103a1d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103a21:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0103a26:	75 15                	jne    f0103a3d <strtol+0x5a>
f0103a28:	80 3a 30             	cmpb   $0x30,(%edx)
f0103a2b:	75 10                	jne    f0103a3d <strtol+0x5a>
f0103a2d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0103a31:	75 0a                	jne    f0103a3d <strtol+0x5a>
		s += 2, base = 16;
f0103a33:	83 c2 02             	add    $0x2,%edx
f0103a36:	b8 10 00 00 00       	mov    $0x10,%eax
f0103a3b:	eb 10                	jmp    f0103a4d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f0103a3d:	85 c0                	test   %eax,%eax
f0103a3f:	75 0c                	jne    f0103a4d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103a41:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103a43:	80 3a 30             	cmpb   $0x30,(%edx)
f0103a46:	75 05                	jne    f0103a4d <strtol+0x6a>
		s++, base = 8;
f0103a48:	83 c2 01             	add    $0x1,%edx
f0103a4b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f0103a4d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103a52:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103a55:	0f b6 0a             	movzbl (%edx),%ecx
f0103a58:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0103a5b:	89 f0                	mov    %esi,%eax
f0103a5d:	3c 09                	cmp    $0x9,%al
f0103a5f:	77 08                	ja     f0103a69 <strtol+0x86>
			dig = *s - '0';
f0103a61:	0f be c9             	movsbl %cl,%ecx
f0103a64:	83 e9 30             	sub    $0x30,%ecx
f0103a67:	eb 20                	jmp    f0103a89 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0103a69:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0103a6c:	89 f0                	mov    %esi,%eax
f0103a6e:	3c 19                	cmp    $0x19,%al
f0103a70:	77 08                	ja     f0103a7a <strtol+0x97>
			dig = *s - 'a' + 10;
f0103a72:	0f be c9             	movsbl %cl,%ecx
f0103a75:	83 e9 57             	sub    $0x57,%ecx
f0103a78:	eb 0f                	jmp    f0103a89 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f0103a7a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0103a7d:	89 f0                	mov    %esi,%eax
f0103a7f:	3c 19                	cmp    $0x19,%al
f0103a81:	77 16                	ja     f0103a99 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0103a83:	0f be c9             	movsbl %cl,%ecx
f0103a86:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0103a89:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f0103a8c:	7d 0f                	jge    f0103a9d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f0103a8e:	83 c2 01             	add    $0x1,%edx
f0103a91:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0103a95:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0103a97:	eb bc                	jmp    f0103a55 <strtol+0x72>
f0103a99:	89 d8                	mov    %ebx,%eax
f0103a9b:	eb 02                	jmp    f0103a9f <strtol+0xbc>
f0103a9d:	89 d8                	mov    %ebx,%eax

	if (endptr)
f0103a9f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103aa3:	74 05                	je     f0103aaa <strtol+0xc7>
		*endptr = (char *) s;
f0103aa5:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103aa8:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f0103aaa:	f7 d8                	neg    %eax
f0103aac:	85 ff                	test   %edi,%edi
f0103aae:	0f 44 c3             	cmove  %ebx,%eax
}
f0103ab1:	5b                   	pop    %ebx
f0103ab2:	5e                   	pop    %esi
f0103ab3:	5f                   	pop    %edi
f0103ab4:	5d                   	pop    %ebp
f0103ab5:	c3                   	ret    
f0103ab6:	66 90                	xchg   %ax,%ax
f0103ab8:	66 90                	xchg   %ax,%ax
f0103aba:	66 90                	xchg   %ax,%ax
f0103abc:	66 90                	xchg   %ax,%ax
f0103abe:	66 90                	xchg   %ax,%ax

f0103ac0 <__udivdi3>:
f0103ac0:	55                   	push   %ebp
f0103ac1:	57                   	push   %edi
f0103ac2:	56                   	push   %esi
f0103ac3:	83 ec 0c             	sub    $0xc,%esp
f0103ac6:	8b 44 24 28          	mov    0x28(%esp),%eax
f0103aca:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0103ace:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0103ad2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0103ad6:	85 c0                	test   %eax,%eax
f0103ad8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103adc:	89 ea                	mov    %ebp,%edx
f0103ade:	89 0c 24             	mov    %ecx,(%esp)
f0103ae1:	75 2d                	jne    f0103b10 <__udivdi3+0x50>
f0103ae3:	39 e9                	cmp    %ebp,%ecx
f0103ae5:	77 61                	ja     f0103b48 <__udivdi3+0x88>
f0103ae7:	85 c9                	test   %ecx,%ecx
f0103ae9:	89 ce                	mov    %ecx,%esi
f0103aeb:	75 0b                	jne    f0103af8 <__udivdi3+0x38>
f0103aed:	b8 01 00 00 00       	mov    $0x1,%eax
f0103af2:	31 d2                	xor    %edx,%edx
f0103af4:	f7 f1                	div    %ecx
f0103af6:	89 c6                	mov    %eax,%esi
f0103af8:	31 d2                	xor    %edx,%edx
f0103afa:	89 e8                	mov    %ebp,%eax
f0103afc:	f7 f6                	div    %esi
f0103afe:	89 c5                	mov    %eax,%ebp
f0103b00:	89 f8                	mov    %edi,%eax
f0103b02:	f7 f6                	div    %esi
f0103b04:	89 ea                	mov    %ebp,%edx
f0103b06:	83 c4 0c             	add    $0xc,%esp
f0103b09:	5e                   	pop    %esi
f0103b0a:	5f                   	pop    %edi
f0103b0b:	5d                   	pop    %ebp
f0103b0c:	c3                   	ret    
f0103b0d:	8d 76 00             	lea    0x0(%esi),%esi
f0103b10:	39 e8                	cmp    %ebp,%eax
f0103b12:	77 24                	ja     f0103b38 <__udivdi3+0x78>
f0103b14:	0f bd e8             	bsr    %eax,%ebp
f0103b17:	83 f5 1f             	xor    $0x1f,%ebp
f0103b1a:	75 3c                	jne    f0103b58 <__udivdi3+0x98>
f0103b1c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0103b20:	39 34 24             	cmp    %esi,(%esp)
f0103b23:	0f 86 9f 00 00 00    	jbe    f0103bc8 <__udivdi3+0x108>
f0103b29:	39 d0                	cmp    %edx,%eax
f0103b2b:	0f 82 97 00 00 00    	jb     f0103bc8 <__udivdi3+0x108>
f0103b31:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103b38:	31 d2                	xor    %edx,%edx
f0103b3a:	31 c0                	xor    %eax,%eax
f0103b3c:	83 c4 0c             	add    $0xc,%esp
f0103b3f:	5e                   	pop    %esi
f0103b40:	5f                   	pop    %edi
f0103b41:	5d                   	pop    %ebp
f0103b42:	c3                   	ret    
f0103b43:	90                   	nop
f0103b44:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103b48:	89 f8                	mov    %edi,%eax
f0103b4a:	f7 f1                	div    %ecx
f0103b4c:	31 d2                	xor    %edx,%edx
f0103b4e:	83 c4 0c             	add    $0xc,%esp
f0103b51:	5e                   	pop    %esi
f0103b52:	5f                   	pop    %edi
f0103b53:	5d                   	pop    %ebp
f0103b54:	c3                   	ret    
f0103b55:	8d 76 00             	lea    0x0(%esi),%esi
f0103b58:	89 e9                	mov    %ebp,%ecx
f0103b5a:	8b 3c 24             	mov    (%esp),%edi
f0103b5d:	d3 e0                	shl    %cl,%eax
f0103b5f:	89 c6                	mov    %eax,%esi
f0103b61:	b8 20 00 00 00       	mov    $0x20,%eax
f0103b66:	29 e8                	sub    %ebp,%eax
f0103b68:	89 c1                	mov    %eax,%ecx
f0103b6a:	d3 ef                	shr    %cl,%edi
f0103b6c:	89 e9                	mov    %ebp,%ecx
f0103b6e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0103b72:	8b 3c 24             	mov    (%esp),%edi
f0103b75:	09 74 24 08          	or     %esi,0x8(%esp)
f0103b79:	89 d6                	mov    %edx,%esi
f0103b7b:	d3 e7                	shl    %cl,%edi
f0103b7d:	89 c1                	mov    %eax,%ecx
f0103b7f:	89 3c 24             	mov    %edi,(%esp)
f0103b82:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103b86:	d3 ee                	shr    %cl,%esi
f0103b88:	89 e9                	mov    %ebp,%ecx
f0103b8a:	d3 e2                	shl    %cl,%edx
f0103b8c:	89 c1                	mov    %eax,%ecx
f0103b8e:	d3 ef                	shr    %cl,%edi
f0103b90:	09 d7                	or     %edx,%edi
f0103b92:	89 f2                	mov    %esi,%edx
f0103b94:	89 f8                	mov    %edi,%eax
f0103b96:	f7 74 24 08          	divl   0x8(%esp)
f0103b9a:	89 d6                	mov    %edx,%esi
f0103b9c:	89 c7                	mov    %eax,%edi
f0103b9e:	f7 24 24             	mull   (%esp)
f0103ba1:	39 d6                	cmp    %edx,%esi
f0103ba3:	89 14 24             	mov    %edx,(%esp)
f0103ba6:	72 30                	jb     f0103bd8 <__udivdi3+0x118>
f0103ba8:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103bac:	89 e9                	mov    %ebp,%ecx
f0103bae:	d3 e2                	shl    %cl,%edx
f0103bb0:	39 c2                	cmp    %eax,%edx
f0103bb2:	73 05                	jae    f0103bb9 <__udivdi3+0xf9>
f0103bb4:	3b 34 24             	cmp    (%esp),%esi
f0103bb7:	74 1f                	je     f0103bd8 <__udivdi3+0x118>
f0103bb9:	89 f8                	mov    %edi,%eax
f0103bbb:	31 d2                	xor    %edx,%edx
f0103bbd:	e9 7a ff ff ff       	jmp    f0103b3c <__udivdi3+0x7c>
f0103bc2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103bc8:	31 d2                	xor    %edx,%edx
f0103bca:	b8 01 00 00 00       	mov    $0x1,%eax
f0103bcf:	e9 68 ff ff ff       	jmp    f0103b3c <__udivdi3+0x7c>
f0103bd4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103bd8:	8d 47 ff             	lea    -0x1(%edi),%eax
f0103bdb:	31 d2                	xor    %edx,%edx
f0103bdd:	83 c4 0c             	add    $0xc,%esp
f0103be0:	5e                   	pop    %esi
f0103be1:	5f                   	pop    %edi
f0103be2:	5d                   	pop    %ebp
f0103be3:	c3                   	ret    
f0103be4:	66 90                	xchg   %ax,%ax
f0103be6:	66 90                	xchg   %ax,%ax
f0103be8:	66 90                	xchg   %ax,%ax
f0103bea:	66 90                	xchg   %ax,%ax
f0103bec:	66 90                	xchg   %ax,%ax
f0103bee:	66 90                	xchg   %ax,%ax

f0103bf0 <__umoddi3>:
f0103bf0:	55                   	push   %ebp
f0103bf1:	57                   	push   %edi
f0103bf2:	56                   	push   %esi
f0103bf3:	83 ec 14             	sub    $0x14,%esp
f0103bf6:	8b 44 24 28          	mov    0x28(%esp),%eax
f0103bfa:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0103bfe:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0103c02:	89 c7                	mov    %eax,%edi
f0103c04:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c08:	8b 44 24 30          	mov    0x30(%esp),%eax
f0103c0c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0103c10:	89 34 24             	mov    %esi,(%esp)
f0103c13:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103c17:	85 c0                	test   %eax,%eax
f0103c19:	89 c2                	mov    %eax,%edx
f0103c1b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103c1f:	75 17                	jne    f0103c38 <__umoddi3+0x48>
f0103c21:	39 fe                	cmp    %edi,%esi
f0103c23:	76 4b                	jbe    f0103c70 <__umoddi3+0x80>
f0103c25:	89 c8                	mov    %ecx,%eax
f0103c27:	89 fa                	mov    %edi,%edx
f0103c29:	f7 f6                	div    %esi
f0103c2b:	89 d0                	mov    %edx,%eax
f0103c2d:	31 d2                	xor    %edx,%edx
f0103c2f:	83 c4 14             	add    $0x14,%esp
f0103c32:	5e                   	pop    %esi
f0103c33:	5f                   	pop    %edi
f0103c34:	5d                   	pop    %ebp
f0103c35:	c3                   	ret    
f0103c36:	66 90                	xchg   %ax,%ax
f0103c38:	39 f8                	cmp    %edi,%eax
f0103c3a:	77 54                	ja     f0103c90 <__umoddi3+0xa0>
f0103c3c:	0f bd e8             	bsr    %eax,%ebp
f0103c3f:	83 f5 1f             	xor    $0x1f,%ebp
f0103c42:	75 5c                	jne    f0103ca0 <__umoddi3+0xb0>
f0103c44:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0103c48:	39 3c 24             	cmp    %edi,(%esp)
f0103c4b:	0f 87 e7 00 00 00    	ja     f0103d38 <__umoddi3+0x148>
f0103c51:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103c55:	29 f1                	sub    %esi,%ecx
f0103c57:	19 c7                	sbb    %eax,%edi
f0103c59:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103c5d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103c61:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103c65:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0103c69:	83 c4 14             	add    $0x14,%esp
f0103c6c:	5e                   	pop    %esi
f0103c6d:	5f                   	pop    %edi
f0103c6e:	5d                   	pop    %ebp
f0103c6f:	c3                   	ret    
f0103c70:	85 f6                	test   %esi,%esi
f0103c72:	89 f5                	mov    %esi,%ebp
f0103c74:	75 0b                	jne    f0103c81 <__umoddi3+0x91>
f0103c76:	b8 01 00 00 00       	mov    $0x1,%eax
f0103c7b:	31 d2                	xor    %edx,%edx
f0103c7d:	f7 f6                	div    %esi
f0103c7f:	89 c5                	mov    %eax,%ebp
f0103c81:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103c85:	31 d2                	xor    %edx,%edx
f0103c87:	f7 f5                	div    %ebp
f0103c89:	89 c8                	mov    %ecx,%eax
f0103c8b:	f7 f5                	div    %ebp
f0103c8d:	eb 9c                	jmp    f0103c2b <__umoddi3+0x3b>
f0103c8f:	90                   	nop
f0103c90:	89 c8                	mov    %ecx,%eax
f0103c92:	89 fa                	mov    %edi,%edx
f0103c94:	83 c4 14             	add    $0x14,%esp
f0103c97:	5e                   	pop    %esi
f0103c98:	5f                   	pop    %edi
f0103c99:	5d                   	pop    %ebp
f0103c9a:	c3                   	ret    
f0103c9b:	90                   	nop
f0103c9c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103ca0:	8b 04 24             	mov    (%esp),%eax
f0103ca3:	be 20 00 00 00       	mov    $0x20,%esi
f0103ca8:	89 e9                	mov    %ebp,%ecx
f0103caa:	29 ee                	sub    %ebp,%esi
f0103cac:	d3 e2                	shl    %cl,%edx
f0103cae:	89 f1                	mov    %esi,%ecx
f0103cb0:	d3 e8                	shr    %cl,%eax
f0103cb2:	89 e9                	mov    %ebp,%ecx
f0103cb4:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103cb8:	8b 04 24             	mov    (%esp),%eax
f0103cbb:	09 54 24 04          	or     %edx,0x4(%esp)
f0103cbf:	89 fa                	mov    %edi,%edx
f0103cc1:	d3 e0                	shl    %cl,%eax
f0103cc3:	89 f1                	mov    %esi,%ecx
f0103cc5:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103cc9:	8b 44 24 10          	mov    0x10(%esp),%eax
f0103ccd:	d3 ea                	shr    %cl,%edx
f0103ccf:	89 e9                	mov    %ebp,%ecx
f0103cd1:	d3 e7                	shl    %cl,%edi
f0103cd3:	89 f1                	mov    %esi,%ecx
f0103cd5:	d3 e8                	shr    %cl,%eax
f0103cd7:	89 e9                	mov    %ebp,%ecx
f0103cd9:	09 f8                	or     %edi,%eax
f0103cdb:	8b 7c 24 10          	mov    0x10(%esp),%edi
f0103cdf:	f7 74 24 04          	divl   0x4(%esp)
f0103ce3:	d3 e7                	shl    %cl,%edi
f0103ce5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103ce9:	89 d7                	mov    %edx,%edi
f0103ceb:	f7 64 24 08          	mull   0x8(%esp)
f0103cef:	39 d7                	cmp    %edx,%edi
f0103cf1:	89 c1                	mov    %eax,%ecx
f0103cf3:	89 14 24             	mov    %edx,(%esp)
f0103cf6:	72 2c                	jb     f0103d24 <__umoddi3+0x134>
f0103cf8:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f0103cfc:	72 22                	jb     f0103d20 <__umoddi3+0x130>
f0103cfe:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0103d02:	29 c8                	sub    %ecx,%eax
f0103d04:	19 d7                	sbb    %edx,%edi
f0103d06:	89 e9                	mov    %ebp,%ecx
f0103d08:	89 fa                	mov    %edi,%edx
f0103d0a:	d3 e8                	shr    %cl,%eax
f0103d0c:	89 f1                	mov    %esi,%ecx
f0103d0e:	d3 e2                	shl    %cl,%edx
f0103d10:	89 e9                	mov    %ebp,%ecx
f0103d12:	d3 ef                	shr    %cl,%edi
f0103d14:	09 d0                	or     %edx,%eax
f0103d16:	89 fa                	mov    %edi,%edx
f0103d18:	83 c4 14             	add    $0x14,%esp
f0103d1b:	5e                   	pop    %esi
f0103d1c:	5f                   	pop    %edi
f0103d1d:	5d                   	pop    %ebp
f0103d1e:	c3                   	ret    
f0103d1f:	90                   	nop
f0103d20:	39 d7                	cmp    %edx,%edi
f0103d22:	75 da                	jne    f0103cfe <__umoddi3+0x10e>
f0103d24:	8b 14 24             	mov    (%esp),%edx
f0103d27:	89 c1                	mov    %eax,%ecx
f0103d29:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f0103d2d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0103d31:	eb cb                	jmp    f0103cfe <__umoddi3+0x10e>
f0103d33:	90                   	nop
f0103d34:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103d38:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f0103d3c:	0f 82 0f ff ff ff    	jb     f0103c51 <__umoddi3+0x61>
f0103d42:	e9 1a ff ff ff       	jmp    f0103c61 <__umoddi3+0x71>
