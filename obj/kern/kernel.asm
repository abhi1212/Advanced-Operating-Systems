
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
f0100034:	bc 00 90 11 f0       	mov    $0xf0119000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/trap.h>


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
f0100046:	b8 b0 de 17 f0       	mov    $0xf017deb0,%eax
f010004b:	2d 9d cf 17 f0       	sub    $0xf017cf9d,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 9d cf 17 f0 	movl   $0xf017cf9d,(%esp)
f0100063:	e8 5f 4b 00 00       	call   f0104bc7 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 c2 04 00 00       	call   f010052f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828); 
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 60 50 10 f0 	movl   $0xf0105060,(%esp)
f010007c:	e8 6d 36 00 00       	call   f01036ee <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 88 11 00 00       	call   f010120e <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100086:	e8 c9 2f 00 00       	call   f0103054 <env_init>
	trap_init();
f010008b:	90                   	nop
f010008c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100090:	e8 d8 36 00 00       	call   f010376d <trap_init>
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
f0100095:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010009c:	00 
f010009d:	c7 04 24 56 b3 11 f0 	movl   $0xf011b356,(%esp)
f01000a4:	e8 9f 31 00 00       	call   f0103248 <env_create>
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f01000a9:	a1 ec d1 17 f0       	mov    0xf017d1ec,%eax
f01000ae:	89 04 24             	mov    %eax,(%esp)
f01000b1:	e8 55 35 00 00       	call   f010360b <env_run>

f01000b6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000b6:	55                   	push   %ebp
f01000b7:	89 e5                	mov    %esp,%ebp
f01000b9:	56                   	push   %esi
f01000ba:	53                   	push   %ebx
f01000bb:	83 ec 10             	sub    $0x10,%esp
f01000be:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000c1:	83 3d a0 de 17 f0 00 	cmpl   $0x0,0xf017dea0
f01000c8:	75 3d                	jne    f0100107 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000ca:	89 35 a0 de 17 f0    	mov    %esi,0xf017dea0

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000d0:	fa                   	cli    
f01000d1:	fc                   	cld    

	va_start(ap, fmt);
f01000d2:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000d5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000d8:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000dc:	8b 45 08             	mov    0x8(%ebp),%eax
f01000df:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000e3:	c7 04 24 7b 50 10 f0 	movl   $0xf010507b,(%esp)
f01000ea:	e8 ff 35 00 00       	call   f01036ee <cprintf>
	vcprintf(fmt, ap);
f01000ef:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000f3:	89 34 24             	mov    %esi,(%esp)
f01000f6:	e8 c0 35 00 00       	call   f01036bb <vcprintf>
	cprintf("\n");
f01000fb:	c7 04 24 03 61 10 f0 	movl   $0xf0106103,(%esp)
f0100102:	e8 e7 35 00 00       	call   f01036ee <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100107:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010010e:	e8 08 07 00 00       	call   f010081b <monitor>
f0100113:	eb f2                	jmp    f0100107 <_panic+0x51>

f0100115 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100115:	55                   	push   %ebp
f0100116:	89 e5                	mov    %esp,%ebp
f0100118:	53                   	push   %ebx
f0100119:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010011c:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f010011f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100122:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100126:	8b 45 08             	mov    0x8(%ebp),%eax
f0100129:	89 44 24 04          	mov    %eax,0x4(%esp)
f010012d:	c7 04 24 93 50 10 f0 	movl   $0xf0105093,(%esp)
f0100134:	e8 b5 35 00 00       	call   f01036ee <cprintf>
	vcprintf(fmt, ap);
f0100139:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010013d:	8b 45 10             	mov    0x10(%ebp),%eax
f0100140:	89 04 24             	mov    %eax,(%esp)
f0100143:	e8 73 35 00 00       	call   f01036bb <vcprintf>
	cprintf("\n");
f0100148:	c7 04 24 03 61 10 f0 	movl   $0xf0106103,(%esp)
f010014f:	e8 9a 35 00 00       	call   f01036ee <cprintf>
	va_end(ap);
}
f0100154:	83 c4 14             	add    $0x14,%esp
f0100157:	5b                   	pop    %ebx
f0100158:	5d                   	pop    %ebp
f0100159:	c3                   	ret    
f010015a:	66 90                	xchg   %ax,%ax
f010015c:	66 90                	xchg   %ax,%ax
f010015e:	66 90                	xchg   %ax,%ax

f0100160 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100160:	55                   	push   %ebp
f0100161:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100163:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100168:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100169:	a8 01                	test   $0x1,%al
f010016b:	74 08                	je     f0100175 <serial_proc_data+0x15>
f010016d:	b2 f8                	mov    $0xf8,%dl
f010016f:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100170:	0f b6 c0             	movzbl %al,%eax
f0100173:	eb 05                	jmp    f010017a <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100175:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010017a:	5d                   	pop    %ebp
f010017b:	c3                   	ret    

f010017c <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010017c:	55                   	push   %ebp
f010017d:	89 e5                	mov    %esp,%ebp
f010017f:	53                   	push   %ebx
f0100180:	83 ec 04             	sub    $0x4,%esp
f0100183:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100185:	eb 2a                	jmp    f01001b1 <cons_intr+0x35>
		if (c == 0)
f0100187:	85 d2                	test   %edx,%edx
f0100189:	74 26                	je     f01001b1 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f010018b:	a1 c4 d1 17 f0       	mov    0xf017d1c4,%eax
f0100190:	8d 48 01             	lea    0x1(%eax),%ecx
f0100193:	89 0d c4 d1 17 f0    	mov    %ecx,0xf017d1c4
f0100199:	88 90 c0 cf 17 f0    	mov    %dl,-0xfe83040(%eax)
		if (cons.wpos == CONSBUFSIZE)
f010019f:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001a5:	75 0a                	jne    f01001b1 <cons_intr+0x35>
			cons.wpos = 0;
f01001a7:	c7 05 c4 d1 17 f0 00 	movl   $0x0,0xf017d1c4
f01001ae:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001b1:	ff d3                	call   *%ebx
f01001b3:	89 c2                	mov    %eax,%edx
f01001b5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001b8:	75 cd                	jne    f0100187 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001ba:	83 c4 04             	add    $0x4,%esp
f01001bd:	5b                   	pop    %ebx
f01001be:	5d                   	pop    %ebp
f01001bf:	c3                   	ret    

f01001c0 <kbd_proc_data>:
f01001c0:	ba 64 00 00 00       	mov    $0x64,%edx
f01001c5:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01001c6:	a8 01                	test   $0x1,%al
f01001c8:	0f 84 f7 00 00 00    	je     f01002c5 <kbd_proc_data+0x105>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01001ce:	a8 20                	test   $0x20,%al
f01001d0:	0f 85 f5 00 00 00    	jne    f01002cb <kbd_proc_data+0x10b>
f01001d6:	b2 60                	mov    $0x60,%dl
f01001d8:	ec                   	in     (%dx),%al
f01001d9:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001db:	3c e0                	cmp    $0xe0,%al
f01001dd:	75 0d                	jne    f01001ec <kbd_proc_data+0x2c>
		// E0 escape character
		shift |= E0ESC;
f01001df:	83 0d a0 cf 17 f0 40 	orl    $0x40,0xf017cfa0
		return 0;
f01001e6:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001eb:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001ec:	55                   	push   %ebp
f01001ed:	89 e5                	mov    %esp,%ebp
f01001ef:	53                   	push   %ebx
f01001f0:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001f3:	84 c0                	test   %al,%al
f01001f5:	79 37                	jns    f010022e <kbd_proc_data+0x6e>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001f7:	8b 0d a0 cf 17 f0    	mov    0xf017cfa0,%ecx
f01001fd:	89 cb                	mov    %ecx,%ebx
f01001ff:	83 e3 40             	and    $0x40,%ebx
f0100202:	83 e0 7f             	and    $0x7f,%eax
f0100205:	85 db                	test   %ebx,%ebx
f0100207:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010020a:	0f b6 d2             	movzbl %dl,%edx
f010020d:	0f b6 82 00 52 10 f0 	movzbl -0xfefae00(%edx),%eax
f0100214:	83 c8 40             	or     $0x40,%eax
f0100217:	0f b6 c0             	movzbl %al,%eax
f010021a:	f7 d0                	not    %eax
f010021c:	21 c1                	and    %eax,%ecx
f010021e:	89 0d a0 cf 17 f0    	mov    %ecx,0xf017cfa0
		return 0;
f0100224:	b8 00 00 00 00       	mov    $0x0,%eax
f0100229:	e9 a3 00 00 00       	jmp    f01002d1 <kbd_proc_data+0x111>
	} else if (shift & E0ESC) {
f010022e:	8b 0d a0 cf 17 f0    	mov    0xf017cfa0,%ecx
f0100234:	f6 c1 40             	test   $0x40,%cl
f0100237:	74 0e                	je     f0100247 <kbd_proc_data+0x87>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100239:	83 c8 80             	or     $0xffffff80,%eax
f010023c:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010023e:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100241:	89 0d a0 cf 17 f0    	mov    %ecx,0xf017cfa0
	}

	shift |= shiftcode[data];
f0100247:	0f b6 d2             	movzbl %dl,%edx
f010024a:	0f b6 82 00 52 10 f0 	movzbl -0xfefae00(%edx),%eax
f0100251:	0b 05 a0 cf 17 f0    	or     0xf017cfa0,%eax
	shift ^= togglecode[data];
f0100257:	0f b6 8a 00 51 10 f0 	movzbl -0xfefaf00(%edx),%ecx
f010025e:	31 c8                	xor    %ecx,%eax
f0100260:	a3 a0 cf 17 f0       	mov    %eax,0xf017cfa0

	c = charcode[shift & (CTL | SHIFT)][data];
f0100265:	89 c1                	mov    %eax,%ecx
f0100267:	83 e1 03             	and    $0x3,%ecx
f010026a:	8b 0c 8d e0 50 10 f0 	mov    -0xfefaf20(,%ecx,4),%ecx
f0100271:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100275:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100278:	a8 08                	test   $0x8,%al
f010027a:	74 1b                	je     f0100297 <kbd_proc_data+0xd7>
		if ('a' <= c && c <= 'z')
f010027c:	89 da                	mov    %ebx,%edx
f010027e:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100281:	83 f9 19             	cmp    $0x19,%ecx
f0100284:	77 05                	ja     f010028b <kbd_proc_data+0xcb>
			c += 'A' - 'a';
f0100286:	83 eb 20             	sub    $0x20,%ebx
f0100289:	eb 0c                	jmp    f0100297 <kbd_proc_data+0xd7>
		else if ('A' <= c && c <= 'Z')
f010028b:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010028e:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100291:	83 fa 19             	cmp    $0x19,%edx
f0100294:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100297:	f7 d0                	not    %eax
f0100299:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f010029b:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010029d:	f6 c2 06             	test   $0x6,%dl
f01002a0:	75 2f                	jne    f01002d1 <kbd_proc_data+0x111>
f01002a2:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002a8:	75 27                	jne    f01002d1 <kbd_proc_data+0x111>
		cprintf("Rebooting!\n");
f01002aa:	c7 04 24 ad 50 10 f0 	movl   $0xf01050ad,(%esp)
f01002b1:	e8 38 34 00 00       	call   f01036ee <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002b6:	ba 92 00 00 00       	mov    $0x92,%edx
f01002bb:	b8 03 00 00 00       	mov    $0x3,%eax
f01002c0:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002c1:	89 d8                	mov    %ebx,%eax
f01002c3:	eb 0c                	jmp    f01002d1 <kbd_proc_data+0x111>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01002c5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002ca:	c3                   	ret    
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01002cb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002d0:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002d1:	83 c4 14             	add    $0x14,%esp
f01002d4:	5b                   	pop    %ebx
f01002d5:	5d                   	pop    %ebp
f01002d6:	c3                   	ret    

f01002d7 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002d7:	55                   	push   %ebp
f01002d8:	89 e5                	mov    %esp,%ebp
f01002da:	57                   	push   %edi
f01002db:	56                   	push   %esi
f01002dc:	53                   	push   %ebx
f01002dd:	83 ec 1c             	sub    $0x1c,%esp
f01002e0:	89 c7                	mov    %eax,%edi
f01002e2:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002e7:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002ec:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002f1:	eb 06                	jmp    f01002f9 <cons_putc+0x22>
f01002f3:	89 ca                	mov    %ecx,%edx
f01002f5:	ec                   	in     (%dx),%al
f01002f6:	ec                   	in     (%dx),%al
f01002f7:	ec                   	in     (%dx),%al
f01002f8:	ec                   	in     (%dx),%al
f01002f9:	89 f2                	mov    %esi,%edx
f01002fb:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002fc:	a8 20                	test   $0x20,%al
f01002fe:	75 05                	jne    f0100305 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100300:	83 eb 01             	sub    $0x1,%ebx
f0100303:	75 ee                	jne    f01002f3 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f0100305:	89 f8                	mov    %edi,%eax
f0100307:	0f b6 c0             	movzbl %al,%eax
f010030a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010030d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100312:	ee                   	out    %al,(%dx)
f0100313:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100318:	be 79 03 00 00       	mov    $0x379,%esi
f010031d:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100322:	eb 06                	jmp    f010032a <cons_putc+0x53>
f0100324:	89 ca                	mov    %ecx,%edx
f0100326:	ec                   	in     (%dx),%al
f0100327:	ec                   	in     (%dx),%al
f0100328:	ec                   	in     (%dx),%al
f0100329:	ec                   	in     (%dx),%al
f010032a:	89 f2                	mov    %esi,%edx
f010032c:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010032d:	84 c0                	test   %al,%al
f010032f:	78 05                	js     f0100336 <cons_putc+0x5f>
f0100331:	83 eb 01             	sub    $0x1,%ebx
f0100334:	75 ee                	jne    f0100324 <cons_putc+0x4d>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100336:	ba 78 03 00 00       	mov    $0x378,%edx
f010033b:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f010033f:	ee                   	out    %al,(%dx)
f0100340:	b2 7a                	mov    $0x7a,%dl
f0100342:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100347:	ee                   	out    %al,(%dx)
f0100348:	b8 08 00 00 00       	mov    $0x8,%eax
f010034d:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010034e:	89 fa                	mov    %edi,%edx
f0100350:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100356:	89 f8                	mov    %edi,%eax
f0100358:	80 cc 07             	or     $0x7,%ah
f010035b:	85 d2                	test   %edx,%edx
f010035d:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100360:	89 f8                	mov    %edi,%eax
f0100362:	0f b6 c0             	movzbl %al,%eax
f0100365:	83 f8 09             	cmp    $0x9,%eax
f0100368:	74 78                	je     f01003e2 <cons_putc+0x10b>
f010036a:	83 f8 09             	cmp    $0x9,%eax
f010036d:	7f 0a                	jg     f0100379 <cons_putc+0xa2>
f010036f:	83 f8 08             	cmp    $0x8,%eax
f0100372:	74 18                	je     f010038c <cons_putc+0xb5>
f0100374:	e9 9d 00 00 00       	jmp    f0100416 <cons_putc+0x13f>
f0100379:	83 f8 0a             	cmp    $0xa,%eax
f010037c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100380:	74 3a                	je     f01003bc <cons_putc+0xe5>
f0100382:	83 f8 0d             	cmp    $0xd,%eax
f0100385:	74 3d                	je     f01003c4 <cons_putc+0xed>
f0100387:	e9 8a 00 00 00       	jmp    f0100416 <cons_putc+0x13f>
	case '\b':
		if (crt_pos > 0) {
f010038c:	0f b7 05 c8 d1 17 f0 	movzwl 0xf017d1c8,%eax
f0100393:	66 85 c0             	test   %ax,%ax
f0100396:	0f 84 e5 00 00 00    	je     f0100481 <cons_putc+0x1aa>
			crt_pos--;
f010039c:	83 e8 01             	sub    $0x1,%eax
f010039f:	66 a3 c8 d1 17 f0    	mov    %ax,0xf017d1c8
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003a5:	0f b7 c0             	movzwl %ax,%eax
f01003a8:	66 81 e7 00 ff       	and    $0xff00,%di
f01003ad:	83 cf 20             	or     $0x20,%edi
f01003b0:	8b 15 cc d1 17 f0    	mov    0xf017d1cc,%edx
f01003b6:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003ba:	eb 78                	jmp    f0100434 <cons_putc+0x15d>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003bc:	66 83 05 c8 d1 17 f0 	addw   $0x50,0xf017d1c8
f01003c3:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003c4:	0f b7 05 c8 d1 17 f0 	movzwl 0xf017d1c8,%eax
f01003cb:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003d1:	c1 e8 16             	shr    $0x16,%eax
f01003d4:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003d7:	c1 e0 04             	shl    $0x4,%eax
f01003da:	66 a3 c8 d1 17 f0    	mov    %ax,0xf017d1c8
f01003e0:	eb 52                	jmp    f0100434 <cons_putc+0x15d>
		break;
	case '\t':
		cons_putc(' ');
f01003e2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e7:	e8 eb fe ff ff       	call   f01002d7 <cons_putc>
		cons_putc(' ');
f01003ec:	b8 20 00 00 00       	mov    $0x20,%eax
f01003f1:	e8 e1 fe ff ff       	call   f01002d7 <cons_putc>
		cons_putc(' ');
f01003f6:	b8 20 00 00 00       	mov    $0x20,%eax
f01003fb:	e8 d7 fe ff ff       	call   f01002d7 <cons_putc>
		cons_putc(' ');
f0100400:	b8 20 00 00 00       	mov    $0x20,%eax
f0100405:	e8 cd fe ff ff       	call   f01002d7 <cons_putc>
		cons_putc(' ');
f010040a:	b8 20 00 00 00       	mov    $0x20,%eax
f010040f:	e8 c3 fe ff ff       	call   f01002d7 <cons_putc>
f0100414:	eb 1e                	jmp    f0100434 <cons_putc+0x15d>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100416:	0f b7 05 c8 d1 17 f0 	movzwl 0xf017d1c8,%eax
f010041d:	8d 50 01             	lea    0x1(%eax),%edx
f0100420:	66 89 15 c8 d1 17 f0 	mov    %dx,0xf017d1c8
f0100427:	0f b7 c0             	movzwl %ax,%eax
f010042a:	8b 15 cc d1 17 f0    	mov    0xf017d1cc,%edx
f0100430:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100434:	66 81 3d c8 d1 17 f0 	cmpw   $0x7cf,0xf017d1c8
f010043b:	cf 07 
f010043d:	76 42                	jbe    f0100481 <cons_putc+0x1aa>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010043f:	a1 cc d1 17 f0       	mov    0xf017d1cc,%eax
f0100444:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010044b:	00 
f010044c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100452:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100456:	89 04 24             	mov    %eax,(%esp)
f0100459:	e8 b6 47 00 00       	call   f0104c14 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010045e:	8b 15 cc d1 17 f0    	mov    0xf017d1cc,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100464:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100469:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010046f:	83 c0 01             	add    $0x1,%eax
f0100472:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100477:	75 f0                	jne    f0100469 <cons_putc+0x192>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100479:	66 83 2d c8 d1 17 f0 	subw   $0x50,0xf017d1c8
f0100480:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100481:	8b 0d d0 d1 17 f0    	mov    0xf017d1d0,%ecx
f0100487:	b8 0e 00 00 00       	mov    $0xe,%eax
f010048c:	89 ca                	mov    %ecx,%edx
f010048e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010048f:	0f b7 1d c8 d1 17 f0 	movzwl 0xf017d1c8,%ebx
f0100496:	8d 71 01             	lea    0x1(%ecx),%esi
f0100499:	89 d8                	mov    %ebx,%eax
f010049b:	66 c1 e8 08          	shr    $0x8,%ax
f010049f:	89 f2                	mov    %esi,%edx
f01004a1:	ee                   	out    %al,(%dx)
f01004a2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004a7:	89 ca                	mov    %ecx,%edx
f01004a9:	ee                   	out    %al,(%dx)
f01004aa:	89 d8                	mov    %ebx,%eax
f01004ac:	89 f2                	mov    %esi,%edx
f01004ae:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004af:	83 c4 1c             	add    $0x1c,%esp
f01004b2:	5b                   	pop    %ebx
f01004b3:	5e                   	pop    %esi
f01004b4:	5f                   	pop    %edi
f01004b5:	5d                   	pop    %ebp
f01004b6:	c3                   	ret    

f01004b7 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004b7:	80 3d d4 d1 17 f0 00 	cmpb   $0x0,0xf017d1d4
f01004be:	74 11                	je     f01004d1 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004c0:	55                   	push   %ebp
f01004c1:	89 e5                	mov    %esp,%ebp
f01004c3:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004c6:	b8 60 01 10 f0       	mov    $0xf0100160,%eax
f01004cb:	e8 ac fc ff ff       	call   f010017c <cons_intr>
}
f01004d0:	c9                   	leave  
f01004d1:	f3 c3                	repz ret 

f01004d3 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004d3:	55                   	push   %ebp
f01004d4:	89 e5                	mov    %esp,%ebp
f01004d6:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004d9:	b8 c0 01 10 f0       	mov    $0xf01001c0,%eax
f01004de:	e8 99 fc ff ff       	call   f010017c <cons_intr>
}
f01004e3:	c9                   	leave  
f01004e4:	c3                   	ret    

f01004e5 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004e5:	55                   	push   %ebp
f01004e6:	89 e5                	mov    %esp,%ebp
f01004e8:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004eb:	e8 c7 ff ff ff       	call   f01004b7 <serial_intr>
	kbd_intr();
f01004f0:	e8 de ff ff ff       	call   f01004d3 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004f5:	a1 c0 d1 17 f0       	mov    0xf017d1c0,%eax
f01004fa:	3b 05 c4 d1 17 f0    	cmp    0xf017d1c4,%eax
f0100500:	74 26                	je     f0100528 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100502:	8d 50 01             	lea    0x1(%eax),%edx
f0100505:	89 15 c0 d1 17 f0    	mov    %edx,0xf017d1c0
f010050b:	0f b6 88 c0 cf 17 f0 	movzbl -0xfe83040(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100512:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100514:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010051a:	75 11                	jne    f010052d <cons_getc+0x48>
			cons.rpos = 0;
f010051c:	c7 05 c0 d1 17 f0 00 	movl   $0x0,0xf017d1c0
f0100523:	00 00 00 
f0100526:	eb 05                	jmp    f010052d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100528:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010052d:	c9                   	leave  
f010052e:	c3                   	ret    

f010052f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010052f:	55                   	push   %ebp
f0100530:	89 e5                	mov    %esp,%ebp
f0100532:	57                   	push   %edi
f0100533:	56                   	push   %esi
f0100534:	53                   	push   %ebx
f0100535:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100538:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010053f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100546:	5a a5 
	if (*cp != 0xA55A) {
f0100548:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010054f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100553:	74 11                	je     f0100566 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100555:	c7 05 d0 d1 17 f0 b4 	movl   $0x3b4,0xf017d1d0
f010055c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010055f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f0100564:	eb 16                	jmp    f010057c <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100566:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010056d:	c7 05 d0 d1 17 f0 d4 	movl   $0x3d4,0xf017d1d0
f0100574:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100577:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010057c:	8b 0d d0 d1 17 f0    	mov    0xf017d1d0,%ecx
f0100582:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100587:	89 ca                	mov    %ecx,%edx
f0100589:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010058a:	8d 59 01             	lea    0x1(%ecx),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010058d:	89 da                	mov    %ebx,%edx
f010058f:	ec                   	in     (%dx),%al
f0100590:	0f b6 f0             	movzbl %al,%esi
f0100593:	c1 e6 08             	shl    $0x8,%esi
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100596:	b8 0f 00 00 00       	mov    $0xf,%eax
f010059b:	89 ca                	mov    %ecx,%edx
f010059d:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010059e:	89 da                	mov    %ebx,%edx
f01005a0:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005a1:	89 3d cc d1 17 f0    	mov    %edi,0xf017d1cc

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005a7:	0f b6 d8             	movzbl %al,%ebx
f01005aa:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005ac:	66 89 35 c8 d1 17 f0 	mov    %si,0xf017d1c8
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005b3:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005b8:	b8 00 00 00 00       	mov    $0x0,%eax
f01005bd:	89 f2                	mov    %esi,%edx
f01005bf:	ee                   	out    %al,(%dx)
f01005c0:	b2 fb                	mov    $0xfb,%dl
f01005c2:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005c7:	ee                   	out    %al,(%dx)
f01005c8:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005cd:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005d2:	89 da                	mov    %ebx,%edx
f01005d4:	ee                   	out    %al,(%dx)
f01005d5:	b2 f9                	mov    $0xf9,%dl
f01005d7:	b8 00 00 00 00       	mov    $0x0,%eax
f01005dc:	ee                   	out    %al,(%dx)
f01005dd:	b2 fb                	mov    $0xfb,%dl
f01005df:	b8 03 00 00 00       	mov    $0x3,%eax
f01005e4:	ee                   	out    %al,(%dx)
f01005e5:	b2 fc                	mov    $0xfc,%dl
f01005e7:	b8 00 00 00 00       	mov    $0x0,%eax
f01005ec:	ee                   	out    %al,(%dx)
f01005ed:	b2 f9                	mov    $0xf9,%dl
f01005ef:	b8 01 00 00 00       	mov    $0x1,%eax
f01005f4:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005f5:	b2 fd                	mov    $0xfd,%dl
f01005f7:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005f8:	3c ff                	cmp    $0xff,%al
f01005fa:	0f 95 c1             	setne  %cl
f01005fd:	88 0d d4 d1 17 f0    	mov    %cl,0xf017d1d4
f0100603:	89 f2                	mov    %esi,%edx
f0100605:	ec                   	in     (%dx),%al
f0100606:	89 da                	mov    %ebx,%edx
f0100608:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100609:	84 c9                	test   %cl,%cl
f010060b:	75 0c                	jne    f0100619 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f010060d:	c7 04 24 b9 50 10 f0 	movl   $0xf01050b9,(%esp)
f0100614:	e8 d5 30 00 00       	call   f01036ee <cprintf>
}
f0100619:	83 c4 1c             	add    $0x1c,%esp
f010061c:	5b                   	pop    %ebx
f010061d:	5e                   	pop    %esi
f010061e:	5f                   	pop    %edi
f010061f:	5d                   	pop    %ebp
f0100620:	c3                   	ret    

f0100621 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100621:	55                   	push   %ebp
f0100622:	89 e5                	mov    %esp,%ebp
f0100624:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100627:	8b 45 08             	mov    0x8(%ebp),%eax
f010062a:	e8 a8 fc ff ff       	call   f01002d7 <cons_putc>
}
f010062f:	c9                   	leave  
f0100630:	c3                   	ret    

f0100631 <getchar>:

int
getchar(void)
{
f0100631:	55                   	push   %ebp
f0100632:	89 e5                	mov    %esp,%ebp
f0100634:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100637:	e8 a9 fe ff ff       	call   f01004e5 <cons_getc>
f010063c:	85 c0                	test   %eax,%eax
f010063e:	74 f7                	je     f0100637 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100640:	c9                   	leave  
f0100641:	c3                   	ret    

f0100642 <iscons>:

int
iscons(int fdnum)
{
f0100642:	55                   	push   %ebp
f0100643:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100645:	b8 01 00 00 00       	mov    $0x1,%eax
f010064a:	5d                   	pop    %ebp
f010064b:	c3                   	ret    
f010064c:	66 90                	xchg   %ax,%ax
f010064e:	66 90                	xchg   %ax,%ax

f0100650 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100650:	55                   	push   %ebp
f0100651:	89 e5                	mov    %esp,%ebp
f0100653:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100656:	c7 44 24 08 00 53 10 	movl   $0xf0105300,0x8(%esp)
f010065d:	f0 
f010065e:	c7 44 24 04 1e 53 10 	movl   $0xf010531e,0x4(%esp)
f0100665:	f0 
f0100666:	c7 04 24 23 53 10 f0 	movl   $0xf0105323,(%esp)
f010066d:	e8 7c 30 00 00       	call   f01036ee <cprintf>
f0100672:	c7 44 24 08 c4 53 10 	movl   $0xf01053c4,0x8(%esp)
f0100679:	f0 
f010067a:	c7 44 24 04 2c 53 10 	movl   $0xf010532c,0x4(%esp)
f0100681:	f0 
f0100682:	c7 04 24 23 53 10 f0 	movl   $0xf0105323,(%esp)
f0100689:	e8 60 30 00 00       	call   f01036ee <cprintf>
f010068e:	c7 44 24 08 35 53 10 	movl   $0xf0105335,0x8(%esp)
f0100695:	f0 
f0100696:	c7 44 24 04 53 53 10 	movl   $0xf0105353,0x4(%esp)
f010069d:	f0 
f010069e:	c7 04 24 23 53 10 f0 	movl   $0xf0105323,(%esp)
f01006a5:	e8 44 30 00 00       	call   f01036ee <cprintf>
	return 0;
}
f01006aa:	b8 00 00 00 00       	mov    $0x0,%eax
f01006af:	c9                   	leave  
f01006b0:	c3                   	ret    

f01006b1 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006b1:	55                   	push   %ebp
f01006b2:	89 e5                	mov    %esp,%ebp
f01006b4:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006b7:	c7 04 24 5d 53 10 f0 	movl   $0xf010535d,(%esp)
f01006be:	e8 2b 30 00 00       	call   f01036ee <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006c3:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006ca:	00 
f01006cb:	c7 04 24 ec 53 10 f0 	movl   $0xf01053ec,(%esp)
f01006d2:	e8 17 30 00 00       	call   f01036ee <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006d7:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006de:	00 
f01006df:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006e6:	f0 
f01006e7:	c7 04 24 14 54 10 f0 	movl   $0xf0105414,(%esp)
f01006ee:	e8 fb 2f 00 00       	call   f01036ee <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006f3:	c7 44 24 08 57 50 10 	movl   $0x105057,0x8(%esp)
f01006fa:	00 
f01006fb:	c7 44 24 04 57 50 10 	movl   $0xf0105057,0x4(%esp)
f0100702:	f0 
f0100703:	c7 04 24 38 54 10 f0 	movl   $0xf0105438,(%esp)
f010070a:	e8 df 2f 00 00       	call   f01036ee <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010070f:	c7 44 24 08 9d cf 17 	movl   $0x17cf9d,0x8(%esp)
f0100716:	00 
f0100717:	c7 44 24 04 9d cf 17 	movl   $0xf017cf9d,0x4(%esp)
f010071e:	f0 
f010071f:	c7 04 24 5c 54 10 f0 	movl   $0xf010545c,(%esp)
f0100726:	e8 c3 2f 00 00       	call   f01036ee <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010072b:	c7 44 24 08 b0 de 17 	movl   $0x17deb0,0x8(%esp)
f0100732:	00 
f0100733:	c7 44 24 04 b0 de 17 	movl   $0xf017deb0,0x4(%esp)
f010073a:	f0 
f010073b:	c7 04 24 80 54 10 f0 	movl   $0xf0105480,(%esp)
f0100742:	e8 a7 2f 00 00       	call   f01036ee <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100747:	b8 af e2 17 f0       	mov    $0xf017e2af,%eax
f010074c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100751:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100756:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010075c:	85 c0                	test   %eax,%eax
f010075e:	0f 48 c2             	cmovs  %edx,%eax
f0100761:	c1 f8 0a             	sar    $0xa,%eax
f0100764:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100768:	c7 04 24 a4 54 10 f0 	movl   $0xf01054a4,(%esp)
f010076f:	e8 7a 2f 00 00       	call   f01036ee <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100774:	b8 00 00 00 00       	mov    $0x0,%eax
f0100779:	c9                   	leave  
f010077a:	c3                   	ret    

f010077b <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010077b:	55                   	push   %ebp
f010077c:	89 e5                	mov    %esp,%ebp
f010077e:	56                   	push   %esi
f010077f:	53                   	push   %ebx
f0100780:	83 ec 40             	sub    $0x40,%esp
      uint32_t  *x;
      x= (uint32_t *) read_ebp();   
f0100783:	89 eb                	mov    %ebp,%ebx
      struct Eipdebuginfo info;
      while(x)
     {

	 cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", x, x[1], x[2],x[3],x[4],x[5],x[6]);
         debuginfo_eip(x[1], &info);
f0100785:	8d 75 e0             	lea    -0x20(%ebp),%esi
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
      uint32_t  *x;
      x= (uint32_t *) read_ebp();   
      struct Eipdebuginfo info;
      while(x)
f0100788:	eb 7d                	jmp    f0100807 <mon_backtrace+0x8c>
     {

	 cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", x, x[1], x[2],x[3],x[4],x[5],x[6]);
f010078a:	8b 43 18             	mov    0x18(%ebx),%eax
f010078d:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f0100791:	8b 43 14             	mov    0x14(%ebx),%eax
f0100794:	89 44 24 18          	mov    %eax,0x18(%esp)
f0100798:	8b 43 10             	mov    0x10(%ebx),%eax
f010079b:	89 44 24 14          	mov    %eax,0x14(%esp)
f010079f:	8b 43 0c             	mov    0xc(%ebx),%eax
f01007a2:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007a6:	8b 43 08             	mov    0x8(%ebx),%eax
f01007a9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007ad:	8b 43 04             	mov    0x4(%ebx),%eax
f01007b0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007b4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01007b8:	c7 04 24 d0 54 10 f0 	movl   $0xf01054d0,(%esp)
f01007bf:	e8 2a 2f 00 00       	call   f01036ee <cprintf>
         debuginfo_eip(x[1], &info);
f01007c4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01007c8:	8b 43 04             	mov    0x4(%ebx),%eax
f01007cb:	89 04 24             	mov    %eax,(%esp)
f01007ce:	e8 8e 39 00 00       	call   f0104161 <debuginfo_eip>
         cprintf("%s:%d:%.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,(x[1]- info.eip_fn_addr));
f01007d3:	8b 43 04             	mov    0x4(%ebx),%eax
f01007d6:	2b 45 f0             	sub    -0x10(%ebp),%eax
f01007d9:	89 44 24 14          	mov    %eax,0x14(%esp)
f01007dd:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01007e0:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007e4:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01007e7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007eb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01007ee:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007f2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01007f5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007f9:	c7 04 24 76 53 10 f0 	movl   $0xf0105376,(%esp)
f0100800:	e8 e9 2e 00 00       	call   f01036ee <cprintf>
         
	 x=(uint32_t *)x[0];
f0100805:	8b 1b                	mov    (%ebx),%ebx
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
      uint32_t  *x;
      x= (uint32_t *) read_ebp();   
      struct Eipdebuginfo info;
      while(x)
f0100807:	85 db                	test   %ebx,%ebx
f0100809:	0f 85 7b ff ff ff    	jne    f010078a <mon_backtrace+0xf>
	 x=(uint32_t *)x[0];

	}	      
     // Your code here.
	return 0;
}
f010080f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100814:	83 c4 40             	add    $0x40,%esp
f0100817:	5b                   	pop    %ebx
f0100818:	5e                   	pop    %esi
f0100819:	5d                   	pop    %ebp
f010081a:	c3                   	ret    

f010081b <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010081b:	55                   	push   %ebp
f010081c:	89 e5                	mov    %esp,%ebp
f010081e:	57                   	push   %edi
f010081f:	56                   	push   %esi
f0100820:	53                   	push   %ebx
f0100821:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100824:	c7 04 24 04 55 10 f0 	movl   $0xf0105504,(%esp)
f010082b:	e8 be 2e 00 00       	call   f01036ee <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100830:	c7 04 24 28 55 10 f0 	movl   $0xf0105528,(%esp)
f0100837:	e8 b2 2e 00 00       	call   f01036ee <cprintf>

	if (tf != NULL)
f010083c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100840:	74 0b                	je     f010084d <monitor+0x32>
		print_trapframe(tf);
f0100842:	8b 45 08             	mov    0x8(%ebp),%eax
f0100845:	89 04 24             	mov    %eax,(%esp)
f0100848:	e8 02 33 00 00       	call   f0103b4f <print_trapframe>

	while (1) {
		buf = readline("K> ");
f010084d:	c7 04 24 85 53 10 f0 	movl   $0xf0105385,(%esp)
f0100854:	e8 17 41 00 00       	call   f0104970 <readline>
f0100859:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f010085b:	85 c0                	test   %eax,%eax
f010085d:	74 ee                	je     f010084d <monitor+0x32>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010085f:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100866:	be 00 00 00 00       	mov    $0x0,%esi
f010086b:	eb 0a                	jmp    f0100877 <monitor+0x5c>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010086d:	c6 03 00             	movb   $0x0,(%ebx)
f0100870:	89 f7                	mov    %esi,%edi
f0100872:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100875:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100877:	0f b6 03             	movzbl (%ebx),%eax
f010087a:	84 c0                	test   %al,%al
f010087c:	74 66                	je     f01008e4 <monitor+0xc9>
f010087e:	0f be c0             	movsbl %al,%eax
f0100881:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100885:	c7 04 24 89 53 10 f0 	movl   $0xf0105389,(%esp)
f010088c:	e8 f9 42 00 00       	call   f0104b8a <strchr>
f0100891:	85 c0                	test   %eax,%eax
f0100893:	75 d8                	jne    f010086d <monitor+0x52>
			*buf++ = 0;
		if (*buf == 0)
f0100895:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100898:	74 4a                	je     f01008e4 <monitor+0xc9>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010089a:	83 fe 0f             	cmp    $0xf,%esi
f010089d:	8d 76 00             	lea    0x0(%esi),%esi
f01008a0:	75 16                	jne    f01008b8 <monitor+0x9d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008a2:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01008a9:	00 
f01008aa:	c7 04 24 8e 53 10 f0 	movl   $0xf010538e,(%esp)
f01008b1:	e8 38 2e 00 00       	call   f01036ee <cprintf>
f01008b6:	eb 95                	jmp    f010084d <monitor+0x32>
			return 0;
		}
		argv[argc++] = buf;
f01008b8:	8d 7e 01             	lea    0x1(%esi),%edi
f01008bb:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008bf:	eb 03                	jmp    f01008c4 <monitor+0xa9>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01008c1:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008c4:	0f b6 03             	movzbl (%ebx),%eax
f01008c7:	84 c0                	test   %al,%al
f01008c9:	74 aa                	je     f0100875 <monitor+0x5a>
f01008cb:	0f be c0             	movsbl %al,%eax
f01008ce:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008d2:	c7 04 24 89 53 10 f0 	movl   $0xf0105389,(%esp)
f01008d9:	e8 ac 42 00 00       	call   f0104b8a <strchr>
f01008de:	85 c0                	test   %eax,%eax
f01008e0:	74 df                	je     f01008c1 <monitor+0xa6>
f01008e2:	eb 91                	jmp    f0100875 <monitor+0x5a>
			buf++;
	}
	argv[argc] = 0;
f01008e4:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008eb:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008ec:	85 f6                	test   %esi,%esi
f01008ee:	0f 84 59 ff ff ff    	je     f010084d <monitor+0x32>
f01008f4:	bb 00 00 00 00       	mov    $0x0,%ebx
f01008f9:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008fc:	8b 04 85 60 55 10 f0 	mov    -0xfefaaa0(,%eax,4),%eax
f0100903:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100907:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010090a:	89 04 24             	mov    %eax,(%esp)
f010090d:	e8 1a 42 00 00       	call   f0104b2c <strcmp>
f0100912:	85 c0                	test   %eax,%eax
f0100914:	75 24                	jne    f010093a <monitor+0x11f>
			return commands[i].func(argc, argv, tf);
f0100916:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100919:	8b 55 08             	mov    0x8(%ebp),%edx
f010091c:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100920:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100923:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100927:	89 34 24             	mov    %esi,(%esp)
f010092a:	ff 14 85 68 55 10 f0 	call   *-0xfefaa98(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100931:	85 c0                	test   %eax,%eax
f0100933:	78 25                	js     f010095a <monitor+0x13f>
f0100935:	e9 13 ff ff ff       	jmp    f010084d <monitor+0x32>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f010093a:	83 c3 01             	add    $0x1,%ebx
f010093d:	83 fb 03             	cmp    $0x3,%ebx
f0100940:	75 b7                	jne    f01008f9 <monitor+0xde>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100942:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100945:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100949:	c7 04 24 ab 53 10 f0 	movl   $0xf01053ab,(%esp)
f0100950:	e8 99 2d 00 00       	call   f01036ee <cprintf>
f0100955:	e9 f3 fe ff ff       	jmp    f010084d <monitor+0x32>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f010095a:	83 c4 5c             	add    $0x5c,%esp
f010095d:	5b                   	pop    %ebx
f010095e:	5e                   	pop    %esi
f010095f:	5f                   	pop    %edi
f0100960:	5d                   	pop    %ebp
f0100961:	c3                   	ret    
f0100962:	66 90                	xchg   %ax,%ax
f0100964:	66 90                	xchg   %ax,%ax
f0100966:	66 90                	xchg   %ax,%ax
f0100968:	66 90                	xchg   %ax,%ax
f010096a:	66 90                	xchg   %ax,%ax
f010096c:	66 90                	xchg   %ax,%ax
f010096e:	66 90                	xchg   %ax,%ax

f0100970 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100970:	55                   	push   %ebp
f0100971:	89 e5                	mov    %esp,%ebp
f0100973:	56                   	push   %esi
f0100974:	53                   	push   %ebx
f0100975:	83 ec 10             	sub    $0x10,%esp
f0100978:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010097a:	89 04 24             	mov    %eax,(%esp)
f010097d:	e8 fc 2c 00 00       	call   f010367e <mc146818_read>
f0100982:	89 c6                	mov    %eax,%esi
f0100984:	83 c3 01             	add    $0x1,%ebx
f0100987:	89 1c 24             	mov    %ebx,(%esp)
f010098a:	e8 ef 2c 00 00       	call   f010367e <mc146818_read>
f010098f:	c1 e0 08             	shl    $0x8,%eax
f0100992:	09 f0                	or     %esi,%eax
}
f0100994:	83 c4 10             	add    $0x10,%esp
f0100997:	5b                   	pop    %ebx
f0100998:	5e                   	pop    %esi
f0100999:	5d                   	pop    %ebp
f010099a:	c3                   	ret    

f010099b <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f010099b:	83 3d d8 d1 17 f0 00 	cmpl   $0x0,0xf017d1d8
f01009a2:	75 11                	jne    f01009b5 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01009a4:	ba af ee 17 f0       	mov    $0xf017eeaf,%edx
f01009a9:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009af:	89 15 d8 d1 17 f0    	mov    %edx,0xf017d1d8
	//
	// LAB 2: Your code here.
	
	
	
	if(n>0)
f01009b5:	85 c0                	test   %eax,%eax
f01009b7:	74 2e                	je     f01009e7 <boot_alloc+0x4c>
	{
	result=nextfree;
f01009b9:	8b 0d d8 d1 17 f0    	mov    0xf017d1d8,%ecx
	nextfree +=ROUNDUP(n, PGSIZE);
f01009bf:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01009c5:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009cb:	01 ca                	add    %ecx,%edx
f01009cd:	89 15 d8 d1 17 f0    	mov    %edx,0xf017d1d8
	else
	{
	return nextfree;	
    }
    
    if ((uint32_t) nextfree> ((npages * PGSIZE)+KERNBASE))
f01009d3:	a1 a4 de 17 f0       	mov    0xf017dea4,%eax
f01009d8:	05 00 00 0f 00       	add    $0xf0000,%eax
f01009dd:	c1 e0 0c             	shl    $0xc,%eax
f01009e0:	39 c2                	cmp    %eax,%edx
f01009e2:	77 09                	ja     f01009ed <boot_alloc+0x52>
    {
    panic("Out of memory \n");
    }

	return result;
f01009e4:	89 c8                	mov    %ecx,%eax
f01009e6:	c3                   	ret    
	nextfree +=ROUNDUP(n, PGSIZE);
	
	}
	else
	{
	return nextfree;	
f01009e7:	a1 d8 d1 17 f0       	mov    0xf017d1d8,%eax
f01009ec:	c3                   	ret    
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01009ed:	55                   	push   %ebp
f01009ee:	89 e5                	mov    %esp,%ebp
f01009f0:	83 ec 18             	sub    $0x18,%esp
	return nextfree;	
    }
    
    if ((uint32_t) nextfree> ((npages * PGSIZE)+KERNBASE))
    {
    panic("Out of memory \n");
f01009f3:	c7 44 24 08 84 55 10 	movl   $0xf0105584,0x8(%esp)
f01009fa:	f0 
f01009fb:	c7 44 24 04 7a 00 00 	movl   $0x7a,0x4(%esp)
f0100a02:	00 
f0100a03:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0100a0a:	e8 a7 f6 ff ff       	call   f01000b6 <_panic>

f0100a0f <page2kva>:
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a0f:	2b 05 ac de 17 f0    	sub    0xf017deac,%eax
f0100a15:	c1 f8 03             	sar    $0x3,%eax
f0100a18:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a1b:	89 c2                	mov    %eax,%edx
f0100a1d:	c1 ea 0c             	shr    $0xc,%edx
f0100a20:	3b 15 a4 de 17 f0    	cmp    0xf017dea4,%edx
f0100a26:	72 26                	jb     f0100a4e <page2kva+0x3f>
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0100a28:	55                   	push   %ebp
f0100a29:	89 e5                	mov    %esp,%ebp
f0100a2b:	83 ec 18             	sub    $0x18,%esp

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a2e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a32:	c7 44 24 08 8c 58 10 	movl   $0xf010588c,0x8(%esp)
f0100a39:	f0 
f0100a3a:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100a41:	00 
f0100a42:	c7 04 24 a0 55 10 f0 	movl   $0xf01055a0,(%esp)
f0100a49:	e8 68 f6 ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0100a4e:	2d 00 00 00 10       	sub    $0x10000000,%eax

static inline void*
page2kva(struct PageInfo *pp)
{
	return KADDR(page2pa(pp));
}
f0100a53:	c3                   	ret    

f0100a54 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100a54:	89 d1                	mov    %edx,%ecx
f0100a56:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100a59:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100a5c:	a8 01                	test   $0x1,%al
f0100a5e:	74 5d                	je     f0100abd <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100a60:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a65:	89 c1                	mov    %eax,%ecx
f0100a67:	c1 e9 0c             	shr    $0xc,%ecx
f0100a6a:	3b 0d a4 de 17 f0    	cmp    0xf017dea4,%ecx
f0100a70:	72 26                	jb     f0100a98 <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100a72:	55                   	push   %ebp
f0100a73:	89 e5                	mov    %esp,%ebp
f0100a75:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a78:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a7c:	c7 44 24 08 8c 58 10 	movl   $0xf010588c,0x8(%esp)
f0100a83:	f0 
f0100a84:	c7 44 24 04 41 03 00 	movl   $0x341,0x4(%esp)
f0100a8b:	00 
f0100a8c:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0100a93:	e8 1e f6 ff ff       	call   f01000b6 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100a98:	c1 ea 0c             	shr    $0xc,%edx
f0100a9b:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100aa1:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100aa8:	89 c2                	mov    %eax,%edx
f0100aaa:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100aad:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100ab2:	85 d2                	test   %edx,%edx
f0100ab4:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100ab9:	0f 44 c2             	cmove  %edx,%eax
f0100abc:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100abd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100ac2:	c3                   	ret    

f0100ac3 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100ac3:	55                   	push   %ebp
f0100ac4:	89 e5                	mov    %esp,%ebp
f0100ac6:	57                   	push   %edi
f0100ac7:	56                   	push   %esi
f0100ac8:	53                   	push   %ebx
f0100ac9:	83 ec 4c             	sub    $0x4c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100acc:	84 c0                	test   %al,%al
f0100ace:	0f 85 07 03 00 00    	jne    f0100ddb <check_page_free_list+0x318>
f0100ad4:	e9 14 03 00 00       	jmp    f0100ded <check_page_free_list+0x32a>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100ad9:	c7 44 24 08 b0 58 10 	movl   $0xf01058b0,0x8(%esp)
f0100ae0:	f0 
f0100ae1:	c7 44 24 04 7f 02 00 	movl   $0x27f,0x4(%esp)
f0100ae8:	00 
f0100ae9:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0100af0:	e8 c1 f5 ff ff       	call   f01000b6 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100af5:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100af8:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100afb:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100afe:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b01:	89 c2                	mov    %eax,%edx
f0100b03:	2b 15 ac de 17 f0    	sub    0xf017deac,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100b09:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100b0f:	0f 95 c2             	setne  %dl
f0100b12:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100b15:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100b19:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100b1b:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b1f:	8b 00                	mov    (%eax),%eax
f0100b21:	85 c0                	test   %eax,%eax
f0100b23:	75 dc                	jne    f0100b01 <check_page_free_list+0x3e>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100b25:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b28:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100b2e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b31:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100b34:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100b36:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100b39:	a3 e0 d1 17 f0       	mov    %eax,0xf017d1e0
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b3e:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b43:	8b 1d e0 d1 17 f0    	mov    0xf017d1e0,%ebx
f0100b49:	eb 63                	jmp    f0100bae <check_page_free_list+0xeb>
f0100b4b:	89 d8                	mov    %ebx,%eax
f0100b4d:	2b 05 ac de 17 f0    	sub    0xf017deac,%eax
f0100b53:	c1 f8 03             	sar    $0x3,%eax
f0100b56:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100b59:	89 c2                	mov    %eax,%edx
f0100b5b:	c1 ea 16             	shr    $0x16,%edx
f0100b5e:	39 f2                	cmp    %esi,%edx
f0100b60:	73 4a                	jae    f0100bac <check_page_free_list+0xe9>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b62:	89 c2                	mov    %eax,%edx
f0100b64:	c1 ea 0c             	shr    $0xc,%edx
f0100b67:	3b 15 a4 de 17 f0    	cmp    0xf017dea4,%edx
f0100b6d:	72 20                	jb     f0100b8f <check_page_free_list+0xcc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b6f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b73:	c7 44 24 08 8c 58 10 	movl   $0xf010588c,0x8(%esp)
f0100b7a:	f0 
f0100b7b:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100b82:	00 
f0100b83:	c7 04 24 a0 55 10 f0 	movl   $0xf01055a0,(%esp)
f0100b8a:	e8 27 f5 ff ff       	call   f01000b6 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b8f:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100b96:	00 
f0100b97:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100b9e:	00 
	return (void *)(pa + KERNBASE);
f0100b9f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ba4:	89 04 24             	mov    %eax,(%esp)
f0100ba7:	e8 1b 40 00 00       	call   f0104bc7 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100bac:	8b 1b                	mov    (%ebx),%ebx
f0100bae:	85 db                	test   %ebx,%ebx
f0100bb0:	75 99                	jne    f0100b4b <check_page_free_list+0x88>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100bb2:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bb7:	e8 df fd ff ff       	call   f010099b <boot_alloc>
f0100bbc:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100bbf:	8b 15 e0 d1 17 f0    	mov    0xf017d1e0,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100bc5:	8b 0d ac de 17 f0    	mov    0xf017deac,%ecx
		assert(pp < pages + npages);
f0100bcb:	a1 a4 de 17 f0       	mov    0xf017dea4,%eax
f0100bd0:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100bd3:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100bd6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100bd9:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100bdc:	bf 00 00 00 00       	mov    $0x0,%edi
f0100be1:	89 5d cc             	mov    %ebx,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100be4:	e9 97 01 00 00       	jmp    f0100d80 <check_page_free_list+0x2bd>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100be9:	39 ca                	cmp    %ecx,%edx
f0100beb:	73 24                	jae    f0100c11 <check_page_free_list+0x14e>
f0100bed:	c7 44 24 0c ae 55 10 	movl   $0xf01055ae,0xc(%esp)
f0100bf4:	f0 
f0100bf5:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0100bfc:	f0 
f0100bfd:	c7 44 24 04 99 02 00 	movl   $0x299,0x4(%esp)
f0100c04:	00 
f0100c05:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0100c0c:	e8 a5 f4 ff ff       	call   f01000b6 <_panic>
		assert(pp < pages + npages);
f0100c11:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100c14:	72 24                	jb     f0100c3a <check_page_free_list+0x177>
f0100c16:	c7 44 24 0c cf 55 10 	movl   $0xf01055cf,0xc(%esp)
f0100c1d:	f0 
f0100c1e:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0100c25:	f0 
f0100c26:	c7 44 24 04 9a 02 00 	movl   $0x29a,0x4(%esp)
f0100c2d:	00 
f0100c2e:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0100c35:	e8 7c f4 ff ff       	call   f01000b6 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c3a:	89 d0                	mov    %edx,%eax
f0100c3c:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100c3f:	a8 07                	test   $0x7,%al
f0100c41:	74 24                	je     f0100c67 <check_page_free_list+0x1a4>
f0100c43:	c7 44 24 0c d4 58 10 	movl   $0xf01058d4,0xc(%esp)
f0100c4a:	f0 
f0100c4b:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0100c52:	f0 
f0100c53:	c7 44 24 04 9b 02 00 	movl   $0x29b,0x4(%esp)
f0100c5a:	00 
f0100c5b:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0100c62:	e8 4f f4 ff ff       	call   f01000b6 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c67:	c1 f8 03             	sar    $0x3,%eax
f0100c6a:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c6d:	85 c0                	test   %eax,%eax
f0100c6f:	75 24                	jne    f0100c95 <check_page_free_list+0x1d2>
f0100c71:	c7 44 24 0c e3 55 10 	movl   $0xf01055e3,0xc(%esp)
f0100c78:	f0 
f0100c79:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0100c80:	f0 
f0100c81:	c7 44 24 04 9e 02 00 	movl   $0x29e,0x4(%esp)
f0100c88:	00 
f0100c89:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0100c90:	e8 21 f4 ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c95:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c9a:	75 24                	jne    f0100cc0 <check_page_free_list+0x1fd>
f0100c9c:	c7 44 24 0c f4 55 10 	movl   $0xf01055f4,0xc(%esp)
f0100ca3:	f0 
f0100ca4:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0100cab:	f0 
f0100cac:	c7 44 24 04 9f 02 00 	movl   $0x29f,0x4(%esp)
f0100cb3:	00 
f0100cb4:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0100cbb:	e8 f6 f3 ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100cc0:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100cc5:	75 24                	jne    f0100ceb <check_page_free_list+0x228>
f0100cc7:	c7 44 24 0c 08 59 10 	movl   $0xf0105908,0xc(%esp)
f0100cce:	f0 
f0100ccf:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0100cd6:	f0 
f0100cd7:	c7 44 24 04 a0 02 00 	movl   $0x2a0,0x4(%esp)
f0100cde:	00 
f0100cdf:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0100ce6:	e8 cb f3 ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100ceb:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100cf0:	75 24                	jne    f0100d16 <check_page_free_list+0x253>
f0100cf2:	c7 44 24 0c 0d 56 10 	movl   $0xf010560d,0xc(%esp)
f0100cf9:	f0 
f0100cfa:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0100d01:	f0 
f0100d02:	c7 44 24 04 a1 02 00 	movl   $0x2a1,0x4(%esp)
f0100d09:	00 
f0100d0a:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0100d11:	e8 a0 f3 ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d16:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100d1b:	76 58                	jbe    f0100d75 <check_page_free_list+0x2b2>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d1d:	89 c3                	mov    %eax,%ebx
f0100d1f:	c1 eb 0c             	shr    $0xc,%ebx
f0100d22:	39 5d c4             	cmp    %ebx,-0x3c(%ebp)
f0100d25:	77 20                	ja     f0100d47 <check_page_free_list+0x284>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d27:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d2b:	c7 44 24 08 8c 58 10 	movl   $0xf010588c,0x8(%esp)
f0100d32:	f0 
f0100d33:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100d3a:	00 
f0100d3b:	c7 04 24 a0 55 10 f0 	movl   $0xf01055a0,(%esp)
f0100d42:	e8 6f f3 ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0100d47:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d4c:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100d4f:	76 2a                	jbe    f0100d7b <check_page_free_list+0x2b8>
f0100d51:	c7 44 24 0c 2c 59 10 	movl   $0xf010592c,0xc(%esp)
f0100d58:	f0 
f0100d59:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0100d60:	f0 
f0100d61:	c7 44 24 04 a2 02 00 	movl   $0x2a2,0x4(%esp)
f0100d68:	00 
f0100d69:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0100d70:	e8 41 f3 ff ff       	call   f01000b6 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d75:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
f0100d79:	eb 03                	jmp    f0100d7e <check_page_free_list+0x2bb>
		else
			++nfree_extmem;
f0100d7b:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d7e:	8b 12                	mov    (%edx),%edx
f0100d80:	85 d2                	test   %edx,%edx
f0100d82:	0f 85 61 fe ff ff    	jne    f0100be9 <check_page_free_list+0x126>
f0100d88:	8b 5d cc             	mov    -0x34(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100d8b:	85 db                	test   %ebx,%ebx
f0100d8d:	7f 24                	jg     f0100db3 <check_page_free_list+0x2f0>
f0100d8f:	c7 44 24 0c 27 56 10 	movl   $0xf0105627,0xc(%esp)
f0100d96:	f0 
f0100d97:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0100d9e:	f0 
f0100d9f:	c7 44 24 04 aa 02 00 	movl   $0x2aa,0x4(%esp)
f0100da6:	00 
f0100da7:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0100dae:	e8 03 f3 ff ff       	call   f01000b6 <_panic>
	assert(nfree_extmem > 0);
f0100db3:	85 ff                	test   %edi,%edi
f0100db5:	7f 4d                	jg     f0100e04 <check_page_free_list+0x341>
f0100db7:	c7 44 24 0c 39 56 10 	movl   $0xf0105639,0xc(%esp)
f0100dbe:	f0 
f0100dbf:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0100dc6:	f0 
f0100dc7:	c7 44 24 04 ab 02 00 	movl   $0x2ab,0x4(%esp)
f0100dce:	00 
f0100dcf:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0100dd6:	e8 db f2 ff ff       	call   f01000b6 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100ddb:	a1 e0 d1 17 f0       	mov    0xf017d1e0,%eax
f0100de0:	85 c0                	test   %eax,%eax
f0100de2:	0f 85 0d fd ff ff    	jne    f0100af5 <check_page_free_list+0x32>
f0100de8:	e9 ec fc ff ff       	jmp    f0100ad9 <check_page_free_list+0x16>
f0100ded:	83 3d e0 d1 17 f0 00 	cmpl   $0x0,0xf017d1e0
f0100df4:	0f 84 df fc ff ff    	je     f0100ad9 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100dfa:	be 00 04 00 00       	mov    $0x400,%esi
f0100dff:	e9 3f fd ff ff       	jmp    f0100b43 <check_page_free_list+0x80>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100e04:	83 c4 4c             	add    $0x4c,%esp
f0100e07:	5b                   	pop    %ebx
f0100e08:	5e                   	pop    %esi
f0100e09:	5f                   	pop    %edi
f0100e0a:	5d                   	pop    %ebp
f0100e0b:	c3                   	ret    

f0100e0c <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100e0c:	55                   	push   %ebp
f0100e0d:	89 e5                	mov    %esp,%ebp
f0100e0f:	53                   	push   %ebx
f0100e10:	83 ec 04             	sub    $0x4,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100e13:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100e18:	eb 4d                	jmp    f0100e67 <page_init+0x5b>
	if(i==0 ||(i>=(IOPHYSMEM/PGSIZE)&&i<=(((uint32_t)boot_alloc(0)-KERNBASE)/PGSIZE)))
f0100e1a:	85 db                	test   %ebx,%ebx
f0100e1c:	74 46                	je     f0100e64 <page_init+0x58>
f0100e1e:	81 fb 9f 00 00 00    	cmp    $0x9f,%ebx
f0100e24:	76 16                	jbe    f0100e3c <page_init+0x30>
f0100e26:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e2b:	e8 6b fb ff ff       	call   f010099b <boot_alloc>
f0100e30:	05 00 00 00 10       	add    $0x10000000,%eax
f0100e35:	c1 e8 0c             	shr    $0xc,%eax
f0100e38:	39 c3                	cmp    %eax,%ebx
f0100e3a:	76 28                	jbe    f0100e64 <page_init+0x58>
f0100e3c:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
	continue;

		pages[i].pp_ref = 0;
f0100e43:	89 c2                	mov    %eax,%edx
f0100e45:	03 15 ac de 17 f0    	add    0xf017deac,%edx
f0100e4b:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
		pages[i].pp_link = page_free_list;
f0100e51:	8b 0d e0 d1 17 f0    	mov    0xf017d1e0,%ecx
f0100e57:	89 0a                	mov    %ecx,(%edx)
		page_free_list = &pages[i];
f0100e59:	03 05 ac de 17 f0    	add    0xf017deac,%eax
f0100e5f:	a3 e0 d1 17 f0       	mov    %eax,0xf017d1e0
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100e64:	83 c3 01             	add    $0x1,%ebx
f0100e67:	3b 1d a4 de 17 f0    	cmp    0xf017dea4,%ebx
f0100e6d:	72 ab                	jb     f0100e1a <page_init+0xe>
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	
	}
}
f0100e6f:	83 c4 04             	add    $0x4,%esp
f0100e72:	5b                   	pop    %ebx
f0100e73:	5d                   	pop    %ebp
f0100e74:	c3                   	ret    

f0100e75 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100e75:	55                   	push   %ebp
f0100e76:	89 e5                	mov    %esp,%ebp
f0100e78:	53                   	push   %ebx
f0100e79:	83 ec 14             	sub    $0x14,%esp
	struct PageInfo *tempage;
	
	if (page_free_list == NULL)
f0100e7c:	8b 1d e0 d1 17 f0    	mov    0xf017d1e0,%ebx
f0100e82:	85 db                	test   %ebx,%ebx
f0100e84:	74 6f                	je     f0100ef5 <page_alloc+0x80>
		return NULL;

  	tempage= page_free_list;
  	page_free_list = tempage->pp_link;
f0100e86:	8b 03                	mov    (%ebx),%eax
f0100e88:	a3 e0 d1 17 f0       	mov    %eax,0xf017d1e0
  	tempage->pp_link = NULL;
f0100e8d:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)

	if (alloc_flags & ALLOC_ZERO)
		memset(page2kva(tempage), 0, PGSIZE); 

  	return tempage;
f0100e93:	89 d8                	mov    %ebx,%eax

  	tempage= page_free_list;
  	page_free_list = tempage->pp_link;
  	tempage->pp_link = NULL;

	if (alloc_flags & ALLOC_ZERO)
f0100e95:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100e99:	74 5f                	je     f0100efa <page_alloc+0x85>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100e9b:	2b 05 ac de 17 f0    	sub    0xf017deac,%eax
f0100ea1:	c1 f8 03             	sar    $0x3,%eax
f0100ea4:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ea7:	89 c2                	mov    %eax,%edx
f0100ea9:	c1 ea 0c             	shr    $0xc,%edx
f0100eac:	3b 15 a4 de 17 f0    	cmp    0xf017dea4,%edx
f0100eb2:	72 20                	jb     f0100ed4 <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100eb4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100eb8:	c7 44 24 08 8c 58 10 	movl   $0xf010588c,0x8(%esp)
f0100ebf:	f0 
f0100ec0:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100ec7:	00 
f0100ec8:	c7 04 24 a0 55 10 f0 	movl   $0xf01055a0,(%esp)
f0100ecf:	e8 e2 f1 ff ff       	call   f01000b6 <_panic>
		memset(page2kva(tempage), 0, PGSIZE); 
f0100ed4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100edb:	00 
f0100edc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100ee3:	00 
	return (void *)(pa + KERNBASE);
f0100ee4:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ee9:	89 04 24             	mov    %eax,(%esp)
f0100eec:	e8 d6 3c 00 00       	call   f0104bc7 <memset>

  	return tempage;
f0100ef1:	89 d8                	mov    %ebx,%eax
f0100ef3:	eb 05                	jmp    f0100efa <page_alloc+0x85>
page_alloc(int alloc_flags)
{
	struct PageInfo *tempage;
	
	if (page_free_list == NULL)
		return NULL;
f0100ef5:	b8 00 00 00 00       	mov    $0x0,%eax
		memset(page2kva(tempage), 0, PGSIZE); 

  	return tempage;
	

}
f0100efa:	83 c4 14             	add    $0x14,%esp
f0100efd:	5b                   	pop    %ebx
f0100efe:	5d                   	pop    %ebp
f0100eff:	c3                   	ret    

f0100f00 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100f00:	55                   	push   %ebp
f0100f01:	89 e5                	mov    %esp,%ebp
f0100f03:	83 ec 18             	sub    $0x18,%esp
f0100f06:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if(pp->pp_ref==0)
f0100f09:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100f0e:	75 0f                	jne    f0100f1f <page_free+0x1f>
	{
	pp->pp_link=page_free_list;
f0100f10:	8b 15 e0 d1 17 f0    	mov    0xf017d1e0,%edx
f0100f16:	89 10                	mov    %edx,(%eax)
	page_free_list=pp;	
f0100f18:	a3 e0 d1 17 f0       	mov    %eax,0xf017d1e0
f0100f1d:	eb 1c                	jmp    f0100f3b <page_free+0x3b>
	}
	else
	panic("page ref not zero \n");
f0100f1f:	c7 44 24 08 4a 56 10 	movl   $0xf010564a,0x8(%esp)
f0100f26:	f0 
f0100f27:	c7 44 24 04 69 01 00 	movl   $0x169,0x4(%esp)
f0100f2e:	00 
f0100f2f:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0100f36:	e8 7b f1 ff ff       	call   f01000b6 <_panic>
}
f0100f3b:	c9                   	leave  
f0100f3c:	c3                   	ret    

f0100f3d <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100f3d:	55                   	push   %ebp
f0100f3e:	89 e5                	mov    %esp,%ebp
f0100f40:	83 ec 18             	sub    $0x18,%esp
f0100f43:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100f46:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f0100f4a:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0100f4d:	66 89 50 04          	mov    %dx,0x4(%eax)
f0100f51:	66 85 d2             	test   %dx,%dx
f0100f54:	75 08                	jne    f0100f5e <page_decref+0x21>
		page_free(pp);
f0100f56:	89 04 24             	mov    %eax,(%esp)
f0100f59:	e8 a2 ff ff ff       	call   f0100f00 <page_free>
}
f0100f5e:	c9                   	leave  
f0100f5f:	c3                   	ret    

f0100f60 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100f60:	55                   	push   %ebp
f0100f61:	89 e5                	mov    %esp,%ebp
f0100f63:	57                   	push   %edi
f0100f64:	56                   	push   %esi
f0100f65:	53                   	push   %ebx
f0100f66:	83 ec 1c             	sub    $0x1c,%esp
f0100f69:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	  pde_t * pde; //va(virtual address) point to pa(physical address)
	  pte_t * pgtable; //same as pde
	  struct PageInfo *pp;

	  pde = &pgdir[PDX(va)]; // va->pgdir
f0100f6c:	89 de                	mov    %ebx,%esi
f0100f6e:	c1 ee 16             	shr    $0x16,%esi
f0100f71:	c1 e6 02             	shl    $0x2,%esi
f0100f74:	03 75 08             	add    0x8(%ebp),%esi
	  if(*pde & PTE_P) { 
f0100f77:	8b 06                	mov    (%esi),%eax
f0100f79:	a8 01                	test   $0x1,%al
f0100f7b:	74 3d                	je     f0100fba <pgdir_walk+0x5a>
	  	pgtable = (KADDR(PTE_ADDR(*pde)));
f0100f7d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f82:	89 c2                	mov    %eax,%edx
f0100f84:	c1 ea 0c             	shr    $0xc,%edx
f0100f87:	3b 15 a4 de 17 f0    	cmp    0xf017dea4,%edx
f0100f8d:	72 20                	jb     f0100faf <pgdir_walk+0x4f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f8f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f93:	c7 44 24 08 8c 58 10 	movl   $0xf010588c,0x8(%esp)
f0100f9a:	f0 
f0100f9b:	c7 44 24 04 96 01 00 	movl   $0x196,0x4(%esp)
f0100fa2:	00 
f0100fa3:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0100faa:	e8 07 f1 ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0100faf:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx
f0100fb5:	e9 97 00 00 00       	jmp    f0101051 <pgdir_walk+0xf1>
	  } else {
		//page table page not exist
		if(!create || 
f0100fba:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100fbe:	0f 84 9b 00 00 00    	je     f010105f <pgdir_walk+0xff>
f0100fc4:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0100fcb:	e8 a5 fe ff ff       	call   f0100e75 <page_alloc>
f0100fd0:	85 c0                	test   %eax,%eax
f0100fd2:	0f 84 8e 00 00 00    	je     f0101066 <pgdir_walk+0x106>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100fd8:	89 c1                	mov    %eax,%ecx
f0100fda:	2b 0d ac de 17 f0    	sub    0xf017deac,%ecx
f0100fe0:	c1 f9 03             	sar    $0x3,%ecx
f0100fe3:	c1 e1 0c             	shl    $0xc,%ecx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fe6:	89 ca                	mov    %ecx,%edx
f0100fe8:	c1 ea 0c             	shr    $0xc,%edx
f0100feb:	3b 15 a4 de 17 f0    	cmp    0xf017dea4,%edx
f0100ff1:	72 20                	jb     f0101013 <pgdir_walk+0xb3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ff3:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100ff7:	c7 44 24 08 8c 58 10 	movl   $0xf010588c,0x8(%esp)
f0100ffe:	f0 
f0100fff:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0101006:	00 
f0101007:	c7 04 24 a0 55 10 f0 	movl   $0xf01055a0,(%esp)
f010100e:	e8 a3 f0 ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0101013:	8d b9 00 00 00 f0    	lea    -0x10000000(%ecx),%edi
f0101019:	89 fa                	mov    %edi,%edx
		   !(pp = page_alloc(ALLOC_ZERO)) ||
f010101b:	85 ff                	test   %edi,%edi
f010101d:	74 4e                	je     f010106d <pgdir_walk+0x10d>
		   !(pgtable = (pte_t*)page2kva(pp))) 
			return NULL;
		    
		pp->pp_ref++;
f010101f:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101024:	81 ff ff ff ff ef    	cmp    $0xefffffff,%edi
f010102a:	77 20                	ja     f010104c <pgdir_walk+0xec>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010102c:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101030:	c7 44 24 08 74 59 10 	movl   $0xf0105974,0x8(%esp)
f0101037:	f0 
f0101038:	c7 44 24 04 9f 01 00 	movl   $0x19f,0x4(%esp)
f010103f:	00 
f0101040:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101047:	e8 6a f0 ff ff       	call   f01000b6 <_panic>
		*pde = PADDR(pgtable) | PTE_P | PTE_W | PTE_U;
f010104c:	83 c9 07             	or     $0x7,%ecx
f010104f:	89 0e                	mov    %ecx,(%esi)
	}

	return &pgtable[PTX(va)];
f0101051:	c1 eb 0a             	shr    $0xa,%ebx
f0101054:	89 d8                	mov    %ebx,%eax
f0101056:	25 fc 0f 00 00       	and    $0xffc,%eax
f010105b:	01 d0                	add    %edx,%eax
f010105d:	eb 13                	jmp    f0101072 <pgdir_walk+0x112>
	  } else {
		//page table page not exist
		if(!create || 
		   !(pp = page_alloc(ALLOC_ZERO)) ||
		   !(pgtable = (pte_t*)page2kva(pp))) 
			return NULL;
f010105f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101064:	eb 0c                	jmp    f0101072 <pgdir_walk+0x112>
f0101066:	b8 00 00 00 00       	mov    $0x0,%eax
f010106b:	eb 05                	jmp    f0101072 <pgdir_walk+0x112>
f010106d:	b8 00 00 00 00       	mov    $0x0,%eax
		pp->pp_ref++;
		*pde = PADDR(pgtable) | PTE_P | PTE_W | PTE_U;
	}

	return &pgtable[PTX(va)];
}
f0101072:	83 c4 1c             	add    $0x1c,%esp
f0101075:	5b                   	pop    %ebx
f0101076:	5e                   	pop    %esi
f0101077:	5f                   	pop    %edi
f0101078:	5d                   	pop    %ebp
f0101079:	c3                   	ret    

f010107a <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f010107a:	55                   	push   %ebp
f010107b:	89 e5                	mov    %esp,%ebp
f010107d:	57                   	push   %edi
f010107e:	56                   	push   %esi
f010107f:	53                   	push   %ebx
f0101080:	83 ec 2c             	sub    $0x2c,%esp
f0101083:	89 45 dc             	mov    %eax,-0x24(%ebp)
	uint32_t x;
	uint32_t i=0;
	pte_t * pt; 
	x=size/PGSIZE;
f0101086:	c1 e9 0c             	shr    $0xc,%ecx
f0101089:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	while(i<x)
f010108c:	89 d3                	mov    %edx,%ebx
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	uint32_t x;
	uint32_t i=0;
f010108e:	be 00 00 00 00       	mov    $0x0,%esi
f0101093:	8b 45 08             	mov    0x8(%ebp),%eax
f0101096:	29 d0                	sub    %edx,%eax
f0101098:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pte_t * pt; 
	x=size/PGSIZE;
	while(i<x)
	{
		pt=pgdir_walk(pgdir,(void*)va,1);
		*pt=(PTE_ADDR(pa) | perm | PTE_P);
f010109b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010109e:	83 c8 01             	or     $0x1,%eax
f01010a1:	89 45 d8             	mov    %eax,-0x28(%ebp)
{
	uint32_t x;
	uint32_t i=0;
	pte_t * pt; 
	x=size/PGSIZE;
	while(i<x)
f01010a4:	eb 2b                	jmp    f01010d1 <boot_map_region+0x57>
	{
		pt=pgdir_walk(pgdir,(void*)va,1);
f01010a6:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01010ad:	00 
f01010ae:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010b2:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01010b5:	89 04 24             	mov    %eax,(%esp)
f01010b8:	e8 a3 fe ff ff       	call   f0100f60 <pgdir_walk>
		*pt=(PTE_ADDR(pa) | perm | PTE_P);
f01010bd:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
f01010c3:	0b 7d d8             	or     -0x28(%ebp),%edi
f01010c6:	89 38                	mov    %edi,(%eax)
		va+=PGSIZE;
f01010c8:	81 c3 00 10 00 00    	add    $0x1000,%ebx
		pa+=PGSIZE;
		i++;
f01010ce:	83 c6 01             	add    $0x1,%esi
f01010d1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01010d4:	8d 3c 18             	lea    (%eax,%ebx,1),%edi
{
	uint32_t x;
	uint32_t i=0;
	pte_t * pt; 
	x=size/PGSIZE;
	while(i<x)
f01010d7:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f01010da:	75 ca                	jne    f01010a6 <boot_map_region+0x2c>
		va+=PGSIZE;
		pa+=PGSIZE;
		i++;
	}
	// Fill this function in
}
f01010dc:	83 c4 2c             	add    $0x2c,%esp
f01010df:	5b                   	pop    %ebx
f01010e0:	5e                   	pop    %esi
f01010e1:	5f                   	pop    %edi
f01010e2:	5d                   	pop    %ebp
f01010e3:	c3                   	ret    

f01010e4 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01010e4:	55                   	push   %ebp
f01010e5:	89 e5                	mov    %esp,%ebp
f01010e7:	83 ec 18             	sub    $0x18,%esp
	pte_t * pt = pgdir_walk(pgdir, va, 0);
f01010ea:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01010f1:	00 
f01010f2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010f5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01010f9:	8b 45 08             	mov    0x8(%ebp),%eax
f01010fc:	89 04 24             	mov    %eax,(%esp)
f01010ff:	e8 5c fe ff ff       	call   f0100f60 <pgdir_walk>
	
	if(pt == NULL)
f0101104:	85 c0                	test   %eax,%eax
f0101106:	74 39                	je     f0101141 <page_lookup+0x5d>
	return NULL;
	
	*pte_store = pt;
f0101108:	8b 55 10             	mov    0x10(%ebp),%edx
f010110b:	89 02                	mov    %eax,(%edx)
	
  return pa2page(PTE_ADDR(*pt));	
f010110d:	8b 00                	mov    (%eax),%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010110f:	c1 e8 0c             	shr    $0xc,%eax
f0101112:	3b 05 a4 de 17 f0    	cmp    0xf017dea4,%eax
f0101118:	72 1c                	jb     f0101136 <page_lookup+0x52>
		panic("pa2page called with invalid pa");
f010111a:	c7 44 24 08 98 59 10 	movl   $0xf0105998,0x8(%esp)
f0101121:	f0 
f0101122:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0101129:	00 
f010112a:	c7 04 24 a0 55 10 f0 	movl   $0xf01055a0,(%esp)
f0101131:	e8 80 ef ff ff       	call   f01000b6 <_panic>
	return &pages[PGNUM(pa)];
f0101136:	8b 15 ac de 17 f0    	mov    0xf017deac,%edx
f010113c:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f010113f:	eb 05                	jmp    f0101146 <page_lookup+0x62>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t * pt = pgdir_walk(pgdir, va, 0);
	
	if(pt == NULL)
	return NULL;
f0101141:	b8 00 00 00 00       	mov    $0x0,%eax
	
	*pte_store = pt;
	
  return pa2page(PTE_ADDR(*pt));	

}
f0101146:	c9                   	leave  
f0101147:	c3                   	ret    

f0101148 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101148:	55                   	push   %ebp
f0101149:	89 e5                	mov    %esp,%ebp
f010114b:	53                   	push   %ebx
f010114c:	83 ec 24             	sub    $0x24,%esp
f010114f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	struct PageInfo *page = NULL;
	pte_t *pt = NULL;
f0101152:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	if ((page = page_lookup(pgdir, va, &pt)) != NULL){
f0101159:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010115c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101160:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101164:	8b 45 08             	mov    0x8(%ebp),%eax
f0101167:	89 04 24             	mov    %eax,(%esp)
f010116a:	e8 75 ff ff ff       	call   f01010e4 <page_lookup>
f010116f:	85 c0                	test   %eax,%eax
f0101171:	74 0b                	je     f010117e <page_remove+0x36>
		page_decref(page);
f0101173:	89 04 24             	mov    %eax,(%esp)
f0101176:	e8 c2 fd ff ff       	call   f0100f3d <page_decref>
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010117b:	0f 01 3b             	invlpg (%ebx)
		tlb_invalidate(pgdir, va);
	}
	*pt=0;
f010117e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101181:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
f0101187:	83 c4 24             	add    $0x24,%esp
f010118a:	5b                   	pop    %ebx
f010118b:	5d                   	pop    %ebp
f010118c:	c3                   	ret    

f010118d <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010118d:	55                   	push   %ebp
f010118e:	89 e5                	mov    %esp,%ebp
f0101190:	57                   	push   %edi
f0101191:	56                   	push   %esi
f0101192:	53                   	push   %ebx
f0101193:	83 ec 1c             	sub    $0x1c,%esp
f0101196:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101199:	8b 7d 10             	mov    0x10(%ebp),%edi
pte_t *pte = pgdir_walk(pgdir, va, 1);
f010119c:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01011a3:	00 
f01011a4:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011a8:	8b 45 08             	mov    0x8(%ebp),%eax
f01011ab:	89 04 24             	mov    %eax,(%esp)
f01011ae:	e8 ad fd ff ff       	call   f0100f60 <pgdir_walk>
f01011b3:	89 c6                	mov    %eax,%esi
 

    if (pte != NULL) {
f01011b5:	85 c0                	test   %eax,%eax
f01011b7:	74 48                	je     f0101201 <page_insert+0x74>
     
        if (*pte & PTE_P)
f01011b9:	f6 00 01             	testb  $0x1,(%eax)
f01011bc:	74 0f                	je     f01011cd <page_insert+0x40>
            page_remove(pgdir, va);
f01011be:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011c2:	8b 45 08             	mov    0x8(%ebp),%eax
f01011c5:	89 04 24             	mov    %eax,(%esp)
f01011c8:	e8 7b ff ff ff       	call   f0101148 <page_remove>
   
       if (page_free_list == pp)
f01011cd:	a1 e0 d1 17 f0       	mov    0xf017d1e0,%eax
f01011d2:	39 d8                	cmp    %ebx,%eax
f01011d4:	75 07                	jne    f01011dd <page_insert+0x50>
            page_free_list = page_free_list->pp_link;
f01011d6:	8b 00                	mov    (%eax),%eax
f01011d8:	a3 e0 d1 17 f0       	mov    %eax,0xf017d1e0
    }
    else {
    
            return -E_NO_MEM;
    }
    *pte = page2pa(pp) | perm | PTE_P;
f01011dd:	8b 55 14             	mov    0x14(%ebp),%edx
f01011e0:	83 ca 01             	or     $0x1,%edx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01011e3:	89 d8                	mov    %ebx,%eax
f01011e5:	2b 05 ac de 17 f0    	sub    0xf017deac,%eax
f01011eb:	c1 f8 03             	sar    $0x3,%eax
f01011ee:	c1 e0 0c             	shl    $0xc,%eax
f01011f1:	09 d0                	or     %edx,%eax
f01011f3:	89 06                	mov    %eax,(%esi)
    pp->pp_ref++;
f01011f5:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)

return 0;
f01011fa:	b8 00 00 00 00       	mov    $0x0,%eax
f01011ff:	eb 05                	jmp    f0101206 <page_insert+0x79>
       if (page_free_list == pp)
            page_free_list = page_free_list->pp_link;
    }
    else {
    
            return -E_NO_MEM;
f0101201:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
    *pte = page2pa(pp) | perm | PTE_P;
    pp->pp_ref++;

return 0;
	
}
f0101206:	83 c4 1c             	add    $0x1c,%esp
f0101209:	5b                   	pop    %ebx
f010120a:	5e                   	pop    %esi
f010120b:	5f                   	pop    %edi
f010120c:	5d                   	pop    %ebp
f010120d:	c3                   	ret    

f010120e <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f010120e:	55                   	push   %ebp
f010120f:	89 e5                	mov    %esp,%ebp
f0101211:	57                   	push   %edi
f0101212:	56                   	push   %esi
f0101213:	53                   	push   %ebx
f0101214:	83 ec 4c             	sub    $0x4c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0101217:	b8 15 00 00 00       	mov    $0x15,%eax
f010121c:	e8 4f f7 ff ff       	call   f0100970 <nvram_read>
f0101221:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0101223:	b8 17 00 00 00       	mov    $0x17,%eax
f0101228:	e8 43 f7 ff ff       	call   f0100970 <nvram_read>
f010122d:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f010122f:	b8 34 00 00 00       	mov    $0x34,%eax
f0101234:	e8 37 f7 ff ff       	call   f0100970 <nvram_read>
f0101239:	c1 e0 06             	shl    $0x6,%eax
f010123c:	89 c2                	mov    %eax,%edx

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
		totalmem = 16 * 1024 + ext16mem;
f010123e:	8d 80 00 40 00 00    	lea    0x4000(%eax),%eax
	extmem = nvram_read(NVRAM_EXTLO);
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0101244:	85 d2                	test   %edx,%edx
f0101246:	75 0b                	jne    f0101253 <mem_init+0x45>
		totalmem = 16 * 1024 + ext16mem;
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0101248:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f010124e:	85 f6                	test   %esi,%esi
f0101250:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0101253:	89 c2                	mov    %eax,%edx
f0101255:	c1 ea 02             	shr    $0x2,%edx
f0101258:	89 15 a4 de 17 f0    	mov    %edx,0xf017dea4
	npages_basemem = basemem / (PGSIZE / 1024);
f010125e:	89 da                	mov    %ebx,%edx
f0101260:	c1 ea 02             	shr    $0x2,%edx
f0101263:	89 15 e4 d1 17 f0    	mov    %edx,0xf017d1e4
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101269:	89 c2                	mov    %eax,%edx
f010126b:	29 da                	sub    %ebx,%edx
f010126d:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101271:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101275:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101279:	c7 04 24 b8 59 10 f0 	movl   $0xf01059b8,(%esp)
f0101280:	e8 69 24 00 00       	call   f01036ee <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101285:	b8 00 10 00 00       	mov    $0x1000,%eax
f010128a:	e8 0c f7 ff ff       	call   f010099b <boot_alloc>
f010128f:	a3 a8 de 17 f0       	mov    %eax,0xf017dea8
	memset(kern_pgdir, 0, PGSIZE);
f0101294:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010129b:	00 
f010129c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01012a3:	00 
f01012a4:	89 04 24             	mov    %eax,(%esp)
f01012a7:	e8 1b 39 00 00       	call   f0104bc7 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01012ac:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01012b1:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01012b6:	77 20                	ja     f01012d8 <mem_init+0xca>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01012b8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012bc:	c7 44 24 08 74 59 10 	movl   $0xf0105974,0x8(%esp)
f01012c3:	f0 
f01012c4:	c7 44 24 04 a1 00 00 	movl   $0xa1,0x4(%esp)
f01012cb:	00 
f01012cc:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f01012d3:	e8 de ed ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01012d8:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01012de:	83 ca 05             	or     $0x5,%edx
f01012e1:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages=(struct PageInfo *)boot_alloc(sizeof(struct PageInfo)*npages);
f01012e7:	a1 a4 de 17 f0       	mov    0xf017dea4,%eax
f01012ec:	c1 e0 03             	shl    $0x3,%eax
f01012ef:	e8 a7 f6 ff ff       	call   f010099b <boot_alloc>
f01012f4:	a3 ac de 17 f0       	mov    %eax,0xf017deac
	memset(pages,0,sizeof(struct PageInfo)*npages);
f01012f9:	8b 0d a4 de 17 f0    	mov    0xf017dea4,%ecx
f01012ff:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101306:	89 54 24 08          	mov    %edx,0x8(%esp)
f010130a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101311:	00 
f0101312:	89 04 24             	mov    %eax,(%esp)
f0101315:	e8 ad 38 00 00       	call   f0104bc7 <memset>
	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	
	
	envs=(struct Env *)boot_alloc(sizeof(struct Env)*NENV);
f010131a:	b8 00 80 01 00       	mov    $0x18000,%eax
f010131f:	e8 77 f6 ff ff       	call   f010099b <boot_alloc>
f0101324:	a3 ec d1 17 f0       	mov    %eax,0xf017d1ec
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101329:	e8 de fa ff ff       	call   f0100e0c <page_init>

	check_page_free_list(1);
f010132e:	b8 01 00 00 00       	mov    $0x1,%eax
f0101333:	e8 8b f7 ff ff       	call   f0100ac3 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101338:	83 3d ac de 17 f0 00 	cmpl   $0x0,0xf017deac
f010133f:	75 1c                	jne    f010135d <mem_init+0x14f>
		panic("'pages' is a null pointer!");
f0101341:	c7 44 24 08 5e 56 10 	movl   $0xf010565e,0x8(%esp)
f0101348:	f0 
f0101349:	c7 44 24 04 bc 02 00 	movl   $0x2bc,0x4(%esp)
f0101350:	00 
f0101351:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101358:	e8 59 ed ff ff       	call   f01000b6 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010135d:	a1 e0 d1 17 f0       	mov    0xf017d1e0,%eax
f0101362:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101367:	eb 05                	jmp    f010136e <mem_init+0x160>
		++nfree;
f0101369:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010136c:	8b 00                	mov    (%eax),%eax
f010136e:	85 c0                	test   %eax,%eax
f0101370:	75 f7                	jne    f0101369 <mem_init+0x15b>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101372:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101379:	e8 f7 fa ff ff       	call   f0100e75 <page_alloc>
f010137e:	89 c7                	mov    %eax,%edi
f0101380:	85 c0                	test   %eax,%eax
f0101382:	75 24                	jne    f01013a8 <mem_init+0x19a>
f0101384:	c7 44 24 0c 79 56 10 	movl   $0xf0105679,0xc(%esp)
f010138b:	f0 
f010138c:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101393:	f0 
f0101394:	c7 44 24 04 c4 02 00 	movl   $0x2c4,0x4(%esp)
f010139b:	00 
f010139c:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f01013a3:	e8 0e ed ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f01013a8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013af:	e8 c1 fa ff ff       	call   f0100e75 <page_alloc>
f01013b4:	89 c6                	mov    %eax,%esi
f01013b6:	85 c0                	test   %eax,%eax
f01013b8:	75 24                	jne    f01013de <mem_init+0x1d0>
f01013ba:	c7 44 24 0c 8f 56 10 	movl   $0xf010568f,0xc(%esp)
f01013c1:	f0 
f01013c2:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f01013c9:	f0 
f01013ca:	c7 44 24 04 c5 02 00 	movl   $0x2c5,0x4(%esp)
f01013d1:	00 
f01013d2:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f01013d9:	e8 d8 ec ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f01013de:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013e5:	e8 8b fa ff ff       	call   f0100e75 <page_alloc>
f01013ea:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01013ed:	85 c0                	test   %eax,%eax
f01013ef:	75 24                	jne    f0101415 <mem_init+0x207>
f01013f1:	c7 44 24 0c a5 56 10 	movl   $0xf01056a5,0xc(%esp)
f01013f8:	f0 
f01013f9:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101400:	f0 
f0101401:	c7 44 24 04 c6 02 00 	movl   $0x2c6,0x4(%esp)
f0101408:	00 
f0101409:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101410:	e8 a1 ec ff ff       	call   f01000b6 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101415:	39 f7                	cmp    %esi,%edi
f0101417:	75 24                	jne    f010143d <mem_init+0x22f>
f0101419:	c7 44 24 0c bb 56 10 	movl   $0xf01056bb,0xc(%esp)
f0101420:	f0 
f0101421:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101428:	f0 
f0101429:	c7 44 24 04 c9 02 00 	movl   $0x2c9,0x4(%esp)
f0101430:	00 
f0101431:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101438:	e8 79 ec ff ff       	call   f01000b6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010143d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101440:	39 c6                	cmp    %eax,%esi
f0101442:	74 04                	je     f0101448 <mem_init+0x23a>
f0101444:	39 c7                	cmp    %eax,%edi
f0101446:	75 24                	jne    f010146c <mem_init+0x25e>
f0101448:	c7 44 24 0c f4 59 10 	movl   $0xf01059f4,0xc(%esp)
f010144f:	f0 
f0101450:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101457:	f0 
f0101458:	c7 44 24 04 ca 02 00 	movl   $0x2ca,0x4(%esp)
f010145f:	00 
f0101460:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101467:	e8 4a ec ff ff       	call   f01000b6 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010146c:	8b 15 ac de 17 f0    	mov    0xf017deac,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101472:	a1 a4 de 17 f0       	mov    0xf017dea4,%eax
f0101477:	c1 e0 0c             	shl    $0xc,%eax
f010147a:	89 f9                	mov    %edi,%ecx
f010147c:	29 d1                	sub    %edx,%ecx
f010147e:	c1 f9 03             	sar    $0x3,%ecx
f0101481:	c1 e1 0c             	shl    $0xc,%ecx
f0101484:	39 c1                	cmp    %eax,%ecx
f0101486:	72 24                	jb     f01014ac <mem_init+0x29e>
f0101488:	c7 44 24 0c cd 56 10 	movl   $0xf01056cd,0xc(%esp)
f010148f:	f0 
f0101490:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101497:	f0 
f0101498:	c7 44 24 04 cb 02 00 	movl   $0x2cb,0x4(%esp)
f010149f:	00 
f01014a0:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f01014a7:	e8 0a ec ff ff       	call   f01000b6 <_panic>
f01014ac:	89 f1                	mov    %esi,%ecx
f01014ae:	29 d1                	sub    %edx,%ecx
f01014b0:	c1 f9 03             	sar    $0x3,%ecx
f01014b3:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f01014b6:	39 c8                	cmp    %ecx,%eax
f01014b8:	77 24                	ja     f01014de <mem_init+0x2d0>
f01014ba:	c7 44 24 0c ea 56 10 	movl   $0xf01056ea,0xc(%esp)
f01014c1:	f0 
f01014c2:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f01014c9:	f0 
f01014ca:	c7 44 24 04 cc 02 00 	movl   $0x2cc,0x4(%esp)
f01014d1:	00 
f01014d2:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f01014d9:	e8 d8 eb ff ff       	call   f01000b6 <_panic>
f01014de:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01014e1:	29 d1                	sub    %edx,%ecx
f01014e3:	89 ca                	mov    %ecx,%edx
f01014e5:	c1 fa 03             	sar    $0x3,%edx
f01014e8:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f01014eb:	39 d0                	cmp    %edx,%eax
f01014ed:	77 24                	ja     f0101513 <mem_init+0x305>
f01014ef:	c7 44 24 0c 07 57 10 	movl   $0xf0105707,0xc(%esp)
f01014f6:	f0 
f01014f7:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f01014fe:	f0 
f01014ff:	c7 44 24 04 cd 02 00 	movl   $0x2cd,0x4(%esp)
f0101506:	00 
f0101507:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f010150e:	e8 a3 eb ff ff       	call   f01000b6 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101513:	a1 e0 d1 17 f0       	mov    0xf017d1e0,%eax
f0101518:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010151b:	c7 05 e0 d1 17 f0 00 	movl   $0x0,0xf017d1e0
f0101522:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101525:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010152c:	e8 44 f9 ff ff       	call   f0100e75 <page_alloc>
f0101531:	85 c0                	test   %eax,%eax
f0101533:	74 24                	je     f0101559 <mem_init+0x34b>
f0101535:	c7 44 24 0c 24 57 10 	movl   $0xf0105724,0xc(%esp)
f010153c:	f0 
f010153d:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101544:	f0 
f0101545:	c7 44 24 04 d4 02 00 	movl   $0x2d4,0x4(%esp)
f010154c:	00 
f010154d:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101554:	e8 5d eb ff ff       	call   f01000b6 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101559:	89 3c 24             	mov    %edi,(%esp)
f010155c:	e8 9f f9 ff ff       	call   f0100f00 <page_free>
	page_free(pp1);
f0101561:	89 34 24             	mov    %esi,(%esp)
f0101564:	e8 97 f9 ff ff       	call   f0100f00 <page_free>
	page_free(pp2);
f0101569:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010156c:	89 04 24             	mov    %eax,(%esp)
f010156f:	e8 8c f9 ff ff       	call   f0100f00 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101574:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010157b:	e8 f5 f8 ff ff       	call   f0100e75 <page_alloc>
f0101580:	89 c6                	mov    %eax,%esi
f0101582:	85 c0                	test   %eax,%eax
f0101584:	75 24                	jne    f01015aa <mem_init+0x39c>
f0101586:	c7 44 24 0c 79 56 10 	movl   $0xf0105679,0xc(%esp)
f010158d:	f0 
f010158e:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101595:	f0 
f0101596:	c7 44 24 04 db 02 00 	movl   $0x2db,0x4(%esp)
f010159d:	00 
f010159e:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f01015a5:	e8 0c eb ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f01015aa:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015b1:	e8 bf f8 ff ff       	call   f0100e75 <page_alloc>
f01015b6:	89 c7                	mov    %eax,%edi
f01015b8:	85 c0                	test   %eax,%eax
f01015ba:	75 24                	jne    f01015e0 <mem_init+0x3d2>
f01015bc:	c7 44 24 0c 8f 56 10 	movl   $0xf010568f,0xc(%esp)
f01015c3:	f0 
f01015c4:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f01015cb:	f0 
f01015cc:	c7 44 24 04 dc 02 00 	movl   $0x2dc,0x4(%esp)
f01015d3:	00 
f01015d4:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f01015db:	e8 d6 ea ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f01015e0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015e7:	e8 89 f8 ff ff       	call   f0100e75 <page_alloc>
f01015ec:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015ef:	85 c0                	test   %eax,%eax
f01015f1:	75 24                	jne    f0101617 <mem_init+0x409>
f01015f3:	c7 44 24 0c a5 56 10 	movl   $0xf01056a5,0xc(%esp)
f01015fa:	f0 
f01015fb:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101602:	f0 
f0101603:	c7 44 24 04 dd 02 00 	movl   $0x2dd,0x4(%esp)
f010160a:	00 
f010160b:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101612:	e8 9f ea ff ff       	call   f01000b6 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101617:	39 fe                	cmp    %edi,%esi
f0101619:	75 24                	jne    f010163f <mem_init+0x431>
f010161b:	c7 44 24 0c bb 56 10 	movl   $0xf01056bb,0xc(%esp)
f0101622:	f0 
f0101623:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f010162a:	f0 
f010162b:	c7 44 24 04 df 02 00 	movl   $0x2df,0x4(%esp)
f0101632:	00 
f0101633:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f010163a:	e8 77 ea ff ff       	call   f01000b6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010163f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101642:	39 c7                	cmp    %eax,%edi
f0101644:	74 04                	je     f010164a <mem_init+0x43c>
f0101646:	39 c6                	cmp    %eax,%esi
f0101648:	75 24                	jne    f010166e <mem_init+0x460>
f010164a:	c7 44 24 0c f4 59 10 	movl   $0xf01059f4,0xc(%esp)
f0101651:	f0 
f0101652:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101659:	f0 
f010165a:	c7 44 24 04 e0 02 00 	movl   $0x2e0,0x4(%esp)
f0101661:	00 
f0101662:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101669:	e8 48 ea ff ff       	call   f01000b6 <_panic>
	assert(!page_alloc(0));
f010166e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101675:	e8 fb f7 ff ff       	call   f0100e75 <page_alloc>
f010167a:	85 c0                	test   %eax,%eax
f010167c:	74 24                	je     f01016a2 <mem_init+0x494>
f010167e:	c7 44 24 0c 24 57 10 	movl   $0xf0105724,0xc(%esp)
f0101685:	f0 
f0101686:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f010168d:	f0 
f010168e:	c7 44 24 04 e1 02 00 	movl   $0x2e1,0x4(%esp)
f0101695:	00 
f0101696:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f010169d:	e8 14 ea ff ff       	call   f01000b6 <_panic>
f01016a2:	89 f0                	mov    %esi,%eax
f01016a4:	2b 05 ac de 17 f0    	sub    0xf017deac,%eax
f01016aa:	c1 f8 03             	sar    $0x3,%eax
f01016ad:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01016b0:	89 c2                	mov    %eax,%edx
f01016b2:	c1 ea 0c             	shr    $0xc,%edx
f01016b5:	3b 15 a4 de 17 f0    	cmp    0xf017dea4,%edx
f01016bb:	72 20                	jb     f01016dd <mem_init+0x4cf>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01016bd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01016c1:	c7 44 24 08 8c 58 10 	movl   $0xf010588c,0x8(%esp)
f01016c8:	f0 
f01016c9:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01016d0:	00 
f01016d1:	c7 04 24 a0 55 10 f0 	movl   $0xf01055a0,(%esp)
f01016d8:	e8 d9 e9 ff ff       	call   f01000b6 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01016dd:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01016e4:	00 
f01016e5:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01016ec:	00 
	return (void *)(pa + KERNBASE);
f01016ed:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01016f2:	89 04 24             	mov    %eax,(%esp)
f01016f5:	e8 cd 34 00 00       	call   f0104bc7 <memset>
	page_free(pp0);
f01016fa:	89 34 24             	mov    %esi,(%esp)
f01016fd:	e8 fe f7 ff ff       	call   f0100f00 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101702:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101709:	e8 67 f7 ff ff       	call   f0100e75 <page_alloc>
f010170e:	85 c0                	test   %eax,%eax
f0101710:	75 24                	jne    f0101736 <mem_init+0x528>
f0101712:	c7 44 24 0c 33 57 10 	movl   $0xf0105733,0xc(%esp)
f0101719:	f0 
f010171a:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101721:	f0 
f0101722:	c7 44 24 04 e6 02 00 	movl   $0x2e6,0x4(%esp)
f0101729:	00 
f010172a:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101731:	e8 80 e9 ff ff       	call   f01000b6 <_panic>
	assert(pp && pp0 == pp);
f0101736:	39 c6                	cmp    %eax,%esi
f0101738:	74 24                	je     f010175e <mem_init+0x550>
f010173a:	c7 44 24 0c 51 57 10 	movl   $0xf0105751,0xc(%esp)
f0101741:	f0 
f0101742:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101749:	f0 
f010174a:	c7 44 24 04 e7 02 00 	movl   $0x2e7,0x4(%esp)
f0101751:	00 
f0101752:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101759:	e8 58 e9 ff ff       	call   f01000b6 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010175e:	89 f0                	mov    %esi,%eax
f0101760:	2b 05 ac de 17 f0    	sub    0xf017deac,%eax
f0101766:	c1 f8 03             	sar    $0x3,%eax
f0101769:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010176c:	89 c2                	mov    %eax,%edx
f010176e:	c1 ea 0c             	shr    $0xc,%edx
f0101771:	3b 15 a4 de 17 f0    	cmp    0xf017dea4,%edx
f0101777:	72 20                	jb     f0101799 <mem_init+0x58b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101779:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010177d:	c7 44 24 08 8c 58 10 	movl   $0xf010588c,0x8(%esp)
f0101784:	f0 
f0101785:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f010178c:	00 
f010178d:	c7 04 24 a0 55 10 f0 	movl   $0xf01055a0,(%esp)
f0101794:	e8 1d e9 ff ff       	call   f01000b6 <_panic>
f0101799:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f010179f:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01017a5:	80 38 00             	cmpb   $0x0,(%eax)
f01017a8:	74 24                	je     f01017ce <mem_init+0x5c0>
f01017aa:	c7 44 24 0c 61 57 10 	movl   $0xf0105761,0xc(%esp)
f01017b1:	f0 
f01017b2:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f01017b9:	f0 
f01017ba:	c7 44 24 04 ea 02 00 	movl   $0x2ea,0x4(%esp)
f01017c1:	00 
f01017c2:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f01017c9:	e8 e8 e8 ff ff       	call   f01000b6 <_panic>
f01017ce:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01017d1:	39 d0                	cmp    %edx,%eax
f01017d3:	75 d0                	jne    f01017a5 <mem_init+0x597>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01017d5:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01017d8:	a3 e0 d1 17 f0       	mov    %eax,0xf017d1e0

	// free the pages we took
	page_free(pp0);
f01017dd:	89 34 24             	mov    %esi,(%esp)
f01017e0:	e8 1b f7 ff ff       	call   f0100f00 <page_free>
	page_free(pp1);
f01017e5:	89 3c 24             	mov    %edi,(%esp)
f01017e8:	e8 13 f7 ff ff       	call   f0100f00 <page_free>
	page_free(pp2);
f01017ed:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017f0:	89 04 24             	mov    %eax,(%esp)
f01017f3:	e8 08 f7 ff ff       	call   f0100f00 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01017f8:	a1 e0 d1 17 f0       	mov    0xf017d1e0,%eax
f01017fd:	eb 05                	jmp    f0101804 <mem_init+0x5f6>
		--nfree;
f01017ff:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101802:	8b 00                	mov    (%eax),%eax
f0101804:	85 c0                	test   %eax,%eax
f0101806:	75 f7                	jne    f01017ff <mem_init+0x5f1>
		--nfree;
	assert(nfree == 0);
f0101808:	85 db                	test   %ebx,%ebx
f010180a:	74 24                	je     f0101830 <mem_init+0x622>
f010180c:	c7 44 24 0c 6b 57 10 	movl   $0xf010576b,0xc(%esp)
f0101813:	f0 
f0101814:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f010181b:	f0 
f010181c:	c7 44 24 04 f7 02 00 	movl   $0x2f7,0x4(%esp)
f0101823:	00 
f0101824:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f010182b:	e8 86 e8 ff ff       	call   f01000b6 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101830:	c7 04 24 14 5a 10 f0 	movl   $0xf0105a14,(%esp)
f0101837:	e8 b2 1e 00 00       	call   f01036ee <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010183c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101843:	e8 2d f6 ff ff       	call   f0100e75 <page_alloc>
f0101848:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010184b:	85 c0                	test   %eax,%eax
f010184d:	75 24                	jne    f0101873 <mem_init+0x665>
f010184f:	c7 44 24 0c 79 56 10 	movl   $0xf0105679,0xc(%esp)
f0101856:	f0 
f0101857:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f010185e:	f0 
f010185f:	c7 44 24 04 55 03 00 	movl   $0x355,0x4(%esp)
f0101866:	00 
f0101867:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f010186e:	e8 43 e8 ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f0101873:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010187a:	e8 f6 f5 ff ff       	call   f0100e75 <page_alloc>
f010187f:	89 c3                	mov    %eax,%ebx
f0101881:	85 c0                	test   %eax,%eax
f0101883:	75 24                	jne    f01018a9 <mem_init+0x69b>
f0101885:	c7 44 24 0c 8f 56 10 	movl   $0xf010568f,0xc(%esp)
f010188c:	f0 
f010188d:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101894:	f0 
f0101895:	c7 44 24 04 56 03 00 	movl   $0x356,0x4(%esp)
f010189c:	00 
f010189d:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f01018a4:	e8 0d e8 ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f01018a9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018b0:	e8 c0 f5 ff ff       	call   f0100e75 <page_alloc>
f01018b5:	89 c6                	mov    %eax,%esi
f01018b7:	85 c0                	test   %eax,%eax
f01018b9:	75 24                	jne    f01018df <mem_init+0x6d1>
f01018bb:	c7 44 24 0c a5 56 10 	movl   $0xf01056a5,0xc(%esp)
f01018c2:	f0 
f01018c3:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f01018ca:	f0 
f01018cb:	c7 44 24 04 57 03 00 	movl   $0x357,0x4(%esp)
f01018d2:	00 
f01018d3:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f01018da:	e8 d7 e7 ff ff       	call   f01000b6 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01018df:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01018e2:	75 24                	jne    f0101908 <mem_init+0x6fa>
f01018e4:	c7 44 24 0c bb 56 10 	movl   $0xf01056bb,0xc(%esp)
f01018eb:	f0 
f01018ec:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f01018f3:	f0 
f01018f4:	c7 44 24 04 5a 03 00 	movl   $0x35a,0x4(%esp)
f01018fb:	00 
f01018fc:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101903:	e8 ae e7 ff ff       	call   f01000b6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101908:	39 c3                	cmp    %eax,%ebx
f010190a:	74 05                	je     f0101911 <mem_init+0x703>
f010190c:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010190f:	75 24                	jne    f0101935 <mem_init+0x727>
f0101911:	c7 44 24 0c f4 59 10 	movl   $0xf01059f4,0xc(%esp)
f0101918:	f0 
f0101919:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101920:	f0 
f0101921:	c7 44 24 04 5b 03 00 	movl   $0x35b,0x4(%esp)
f0101928:	00 
f0101929:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101930:	e8 81 e7 ff ff       	call   f01000b6 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101935:	a1 e0 d1 17 f0       	mov    0xf017d1e0,%eax
f010193a:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f010193d:	c7 05 e0 d1 17 f0 00 	movl   $0x0,0xf017d1e0
f0101944:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101947:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010194e:	e8 22 f5 ff ff       	call   f0100e75 <page_alloc>
f0101953:	85 c0                	test   %eax,%eax
f0101955:	74 24                	je     f010197b <mem_init+0x76d>
f0101957:	c7 44 24 0c 24 57 10 	movl   $0xf0105724,0xc(%esp)
f010195e:	f0 
f010195f:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101966:	f0 
f0101967:	c7 44 24 04 62 03 00 	movl   $0x362,0x4(%esp)
f010196e:	00 
f010196f:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101976:	e8 3b e7 ff ff       	call   f01000b6 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010197b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010197e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101982:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101989:	00 
f010198a:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f010198f:	89 04 24             	mov    %eax,(%esp)
f0101992:	e8 4d f7 ff ff       	call   f01010e4 <page_lookup>
f0101997:	85 c0                	test   %eax,%eax
f0101999:	74 24                	je     f01019bf <mem_init+0x7b1>
f010199b:	c7 44 24 0c 34 5a 10 	movl   $0xf0105a34,0xc(%esp)
f01019a2:	f0 
f01019a3:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f01019aa:	f0 
f01019ab:	c7 44 24 04 65 03 00 	movl   $0x365,0x4(%esp)
f01019b2:	00 
f01019b3:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f01019ba:	e8 f7 e6 ff ff       	call   f01000b6 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01019bf:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01019c6:	00 
f01019c7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01019ce:	00 
f01019cf:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01019d3:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f01019d8:	89 04 24             	mov    %eax,(%esp)
f01019db:	e8 ad f7 ff ff       	call   f010118d <page_insert>
f01019e0:	85 c0                	test   %eax,%eax
f01019e2:	78 24                	js     f0101a08 <mem_init+0x7fa>
f01019e4:	c7 44 24 0c 6c 5a 10 	movl   $0xf0105a6c,0xc(%esp)
f01019eb:	f0 
f01019ec:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f01019f3:	f0 
f01019f4:	c7 44 24 04 68 03 00 	movl   $0x368,0x4(%esp)
f01019fb:	00 
f01019fc:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101a03:	e8 ae e6 ff ff       	call   f01000b6 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101a08:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a0b:	89 04 24             	mov    %eax,(%esp)
f0101a0e:	e8 ed f4 ff ff       	call   f0100f00 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101a13:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101a1a:	00 
f0101a1b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101a22:	00 
f0101a23:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101a27:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0101a2c:	89 04 24             	mov    %eax,(%esp)
f0101a2f:	e8 59 f7 ff ff       	call   f010118d <page_insert>
f0101a34:	85 c0                	test   %eax,%eax
f0101a36:	74 24                	je     f0101a5c <mem_init+0x84e>
f0101a38:	c7 44 24 0c 9c 5a 10 	movl   $0xf0105a9c,0xc(%esp)
f0101a3f:	f0 
f0101a40:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101a47:	f0 
f0101a48:	c7 44 24 04 6c 03 00 	movl   $0x36c,0x4(%esp)
f0101a4f:	00 
f0101a50:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101a57:	e8 5a e6 ff ff       	call   f01000b6 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101a5c:	8b 3d a8 de 17 f0    	mov    0xf017dea8,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101a62:	a1 ac de 17 f0       	mov    0xf017deac,%eax
f0101a67:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101a6a:	8b 17                	mov    (%edi),%edx
f0101a6c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a72:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101a75:	29 c1                	sub    %eax,%ecx
f0101a77:	89 c8                	mov    %ecx,%eax
f0101a79:	c1 f8 03             	sar    $0x3,%eax
f0101a7c:	c1 e0 0c             	shl    $0xc,%eax
f0101a7f:	39 c2                	cmp    %eax,%edx
f0101a81:	74 24                	je     f0101aa7 <mem_init+0x899>
f0101a83:	c7 44 24 0c cc 5a 10 	movl   $0xf0105acc,0xc(%esp)
f0101a8a:	f0 
f0101a8b:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101a92:	f0 
f0101a93:	c7 44 24 04 6d 03 00 	movl   $0x36d,0x4(%esp)
f0101a9a:	00 
f0101a9b:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101aa2:	e8 0f e6 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101aa7:	ba 00 00 00 00       	mov    $0x0,%edx
f0101aac:	89 f8                	mov    %edi,%eax
f0101aae:	e8 a1 ef ff ff       	call   f0100a54 <check_va2pa>
f0101ab3:	89 da                	mov    %ebx,%edx
f0101ab5:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101ab8:	c1 fa 03             	sar    $0x3,%edx
f0101abb:	c1 e2 0c             	shl    $0xc,%edx
f0101abe:	39 d0                	cmp    %edx,%eax
f0101ac0:	74 24                	je     f0101ae6 <mem_init+0x8d8>
f0101ac2:	c7 44 24 0c f4 5a 10 	movl   $0xf0105af4,0xc(%esp)
f0101ac9:	f0 
f0101aca:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101ad1:	f0 
f0101ad2:	c7 44 24 04 6e 03 00 	movl   $0x36e,0x4(%esp)
f0101ad9:	00 
f0101ada:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101ae1:	e8 d0 e5 ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 1);
f0101ae6:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101aeb:	74 24                	je     f0101b11 <mem_init+0x903>
f0101aed:	c7 44 24 0c 76 57 10 	movl   $0xf0105776,0xc(%esp)
f0101af4:	f0 
f0101af5:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101afc:	f0 
f0101afd:	c7 44 24 04 6f 03 00 	movl   $0x36f,0x4(%esp)
f0101b04:	00 
f0101b05:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101b0c:	e8 a5 e5 ff ff       	call   f01000b6 <_panic>
	assert(pp0->pp_ref == 1);
f0101b11:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b14:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b19:	74 24                	je     f0101b3f <mem_init+0x931>
f0101b1b:	c7 44 24 0c 87 57 10 	movl   $0xf0105787,0xc(%esp)
f0101b22:	f0 
f0101b23:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101b2a:	f0 
f0101b2b:	c7 44 24 04 70 03 00 	movl   $0x370,0x4(%esp)
f0101b32:	00 
f0101b33:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101b3a:	e8 77 e5 ff ff       	call   f01000b6 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b3f:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101b46:	00 
f0101b47:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101b4e:	00 
f0101b4f:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101b53:	89 3c 24             	mov    %edi,(%esp)
f0101b56:	e8 32 f6 ff ff       	call   f010118d <page_insert>
f0101b5b:	85 c0                	test   %eax,%eax
f0101b5d:	74 24                	je     f0101b83 <mem_init+0x975>
f0101b5f:	c7 44 24 0c 24 5b 10 	movl   $0xf0105b24,0xc(%esp)
f0101b66:	f0 
f0101b67:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101b6e:	f0 
f0101b6f:	c7 44 24 04 73 03 00 	movl   $0x373,0x4(%esp)
f0101b76:	00 
f0101b77:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101b7e:	e8 33 e5 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b83:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b88:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0101b8d:	e8 c2 ee ff ff       	call   f0100a54 <check_va2pa>
f0101b92:	89 f2                	mov    %esi,%edx
f0101b94:	2b 15 ac de 17 f0    	sub    0xf017deac,%edx
f0101b9a:	c1 fa 03             	sar    $0x3,%edx
f0101b9d:	c1 e2 0c             	shl    $0xc,%edx
f0101ba0:	39 d0                	cmp    %edx,%eax
f0101ba2:	74 24                	je     f0101bc8 <mem_init+0x9ba>
f0101ba4:	c7 44 24 0c 60 5b 10 	movl   $0xf0105b60,0xc(%esp)
f0101bab:	f0 
f0101bac:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101bb3:	f0 
f0101bb4:	c7 44 24 04 74 03 00 	movl   $0x374,0x4(%esp)
f0101bbb:	00 
f0101bbc:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101bc3:	e8 ee e4 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0101bc8:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101bcd:	74 24                	je     f0101bf3 <mem_init+0x9e5>
f0101bcf:	c7 44 24 0c 98 57 10 	movl   $0xf0105798,0xc(%esp)
f0101bd6:	f0 
f0101bd7:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101bde:	f0 
f0101bdf:	c7 44 24 04 75 03 00 	movl   $0x375,0x4(%esp)
f0101be6:	00 
f0101be7:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101bee:	e8 c3 e4 ff ff       	call   f01000b6 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101bf3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101bfa:	e8 76 f2 ff ff       	call   f0100e75 <page_alloc>
f0101bff:	85 c0                	test   %eax,%eax
f0101c01:	74 24                	je     f0101c27 <mem_init+0xa19>
f0101c03:	c7 44 24 0c 24 57 10 	movl   $0xf0105724,0xc(%esp)
f0101c0a:	f0 
f0101c0b:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101c12:	f0 
f0101c13:	c7 44 24 04 78 03 00 	movl   $0x378,0x4(%esp)
f0101c1a:	00 
f0101c1b:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101c22:	e8 8f e4 ff ff       	call   f01000b6 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c27:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101c2e:	00 
f0101c2f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101c36:	00 
f0101c37:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101c3b:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0101c40:	89 04 24             	mov    %eax,(%esp)
f0101c43:	e8 45 f5 ff ff       	call   f010118d <page_insert>
f0101c48:	85 c0                	test   %eax,%eax
f0101c4a:	74 24                	je     f0101c70 <mem_init+0xa62>
f0101c4c:	c7 44 24 0c 24 5b 10 	movl   $0xf0105b24,0xc(%esp)
f0101c53:	f0 
f0101c54:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101c5b:	f0 
f0101c5c:	c7 44 24 04 7b 03 00 	movl   $0x37b,0x4(%esp)
f0101c63:	00 
f0101c64:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101c6b:	e8 46 e4 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c70:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c75:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0101c7a:	e8 d5 ed ff ff       	call   f0100a54 <check_va2pa>
f0101c7f:	89 f2                	mov    %esi,%edx
f0101c81:	2b 15 ac de 17 f0    	sub    0xf017deac,%edx
f0101c87:	c1 fa 03             	sar    $0x3,%edx
f0101c8a:	c1 e2 0c             	shl    $0xc,%edx
f0101c8d:	39 d0                	cmp    %edx,%eax
f0101c8f:	74 24                	je     f0101cb5 <mem_init+0xaa7>
f0101c91:	c7 44 24 0c 60 5b 10 	movl   $0xf0105b60,0xc(%esp)
f0101c98:	f0 
f0101c99:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101ca0:	f0 
f0101ca1:	c7 44 24 04 7c 03 00 	movl   $0x37c,0x4(%esp)
f0101ca8:	00 
f0101ca9:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101cb0:	e8 01 e4 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0101cb5:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101cba:	74 24                	je     f0101ce0 <mem_init+0xad2>
f0101cbc:	c7 44 24 0c 98 57 10 	movl   $0xf0105798,0xc(%esp)
f0101cc3:	f0 
f0101cc4:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101ccb:	f0 
f0101ccc:	c7 44 24 04 7d 03 00 	movl   $0x37d,0x4(%esp)
f0101cd3:	00 
f0101cd4:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101cdb:	e8 d6 e3 ff ff       	call   f01000b6 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101ce0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ce7:	e8 89 f1 ff ff       	call   f0100e75 <page_alloc>
f0101cec:	85 c0                	test   %eax,%eax
f0101cee:	74 24                	je     f0101d14 <mem_init+0xb06>
f0101cf0:	c7 44 24 0c 24 57 10 	movl   $0xf0105724,0xc(%esp)
f0101cf7:	f0 
f0101cf8:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101cff:	f0 
f0101d00:	c7 44 24 04 81 03 00 	movl   $0x381,0x4(%esp)
f0101d07:	00 
f0101d08:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101d0f:	e8 a2 e3 ff ff       	call   f01000b6 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101d14:	8b 15 a8 de 17 f0    	mov    0xf017dea8,%edx
f0101d1a:	8b 02                	mov    (%edx),%eax
f0101d1c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101d21:	89 c1                	mov    %eax,%ecx
f0101d23:	c1 e9 0c             	shr    $0xc,%ecx
f0101d26:	3b 0d a4 de 17 f0    	cmp    0xf017dea4,%ecx
f0101d2c:	72 20                	jb     f0101d4e <mem_init+0xb40>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101d2e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101d32:	c7 44 24 08 8c 58 10 	movl   $0xf010588c,0x8(%esp)
f0101d39:	f0 
f0101d3a:	c7 44 24 04 84 03 00 	movl   $0x384,0x4(%esp)
f0101d41:	00 
f0101d42:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101d49:	e8 68 e3 ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0101d4e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101d53:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101d56:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101d5d:	00 
f0101d5e:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101d65:	00 
f0101d66:	89 14 24             	mov    %edx,(%esp)
f0101d69:	e8 f2 f1 ff ff       	call   f0100f60 <pgdir_walk>
f0101d6e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101d71:	8d 51 04             	lea    0x4(%ecx),%edx
f0101d74:	39 d0                	cmp    %edx,%eax
f0101d76:	74 24                	je     f0101d9c <mem_init+0xb8e>
f0101d78:	c7 44 24 0c 90 5b 10 	movl   $0xf0105b90,0xc(%esp)
f0101d7f:	f0 
f0101d80:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101d87:	f0 
f0101d88:	c7 44 24 04 85 03 00 	movl   $0x385,0x4(%esp)
f0101d8f:	00 
f0101d90:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101d97:	e8 1a e3 ff ff       	call   f01000b6 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101d9c:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101da3:	00 
f0101da4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101dab:	00 
f0101dac:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101db0:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0101db5:	89 04 24             	mov    %eax,(%esp)
f0101db8:	e8 d0 f3 ff ff       	call   f010118d <page_insert>
f0101dbd:	85 c0                	test   %eax,%eax
f0101dbf:	74 24                	je     f0101de5 <mem_init+0xbd7>
f0101dc1:	c7 44 24 0c d0 5b 10 	movl   $0xf0105bd0,0xc(%esp)
f0101dc8:	f0 
f0101dc9:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101dd0:	f0 
f0101dd1:	c7 44 24 04 88 03 00 	movl   $0x388,0x4(%esp)
f0101dd8:	00 
f0101dd9:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101de0:	e8 d1 e2 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101de5:	8b 3d a8 de 17 f0    	mov    0xf017dea8,%edi
f0101deb:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101df0:	89 f8                	mov    %edi,%eax
f0101df2:	e8 5d ec ff ff       	call   f0100a54 <check_va2pa>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101df7:	89 f2                	mov    %esi,%edx
f0101df9:	2b 15 ac de 17 f0    	sub    0xf017deac,%edx
f0101dff:	c1 fa 03             	sar    $0x3,%edx
f0101e02:	c1 e2 0c             	shl    $0xc,%edx
f0101e05:	39 d0                	cmp    %edx,%eax
f0101e07:	74 24                	je     f0101e2d <mem_init+0xc1f>
f0101e09:	c7 44 24 0c 60 5b 10 	movl   $0xf0105b60,0xc(%esp)
f0101e10:	f0 
f0101e11:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101e18:	f0 
f0101e19:	c7 44 24 04 89 03 00 	movl   $0x389,0x4(%esp)
f0101e20:	00 
f0101e21:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101e28:	e8 89 e2 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0101e2d:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101e32:	74 24                	je     f0101e58 <mem_init+0xc4a>
f0101e34:	c7 44 24 0c 98 57 10 	movl   $0xf0105798,0xc(%esp)
f0101e3b:	f0 
f0101e3c:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101e43:	f0 
f0101e44:	c7 44 24 04 8a 03 00 	movl   $0x38a,0x4(%esp)
f0101e4b:	00 
f0101e4c:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101e53:	e8 5e e2 ff ff       	call   f01000b6 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101e58:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101e5f:	00 
f0101e60:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101e67:	00 
f0101e68:	89 3c 24             	mov    %edi,(%esp)
f0101e6b:	e8 f0 f0 ff ff       	call   f0100f60 <pgdir_walk>
f0101e70:	f6 00 04             	testb  $0x4,(%eax)
f0101e73:	75 24                	jne    f0101e99 <mem_init+0xc8b>
f0101e75:	c7 44 24 0c 10 5c 10 	movl   $0xf0105c10,0xc(%esp)
f0101e7c:	f0 
f0101e7d:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101e84:	f0 
f0101e85:	c7 44 24 04 8b 03 00 	movl   $0x38b,0x4(%esp)
f0101e8c:	00 
f0101e8d:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101e94:	e8 1d e2 ff ff       	call   f01000b6 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101e99:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0101e9e:	f6 00 04             	testb  $0x4,(%eax)
f0101ea1:	75 24                	jne    f0101ec7 <mem_init+0xcb9>
f0101ea3:	c7 44 24 0c a9 57 10 	movl   $0xf01057a9,0xc(%esp)
f0101eaa:	f0 
f0101eab:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101eb2:	f0 
f0101eb3:	c7 44 24 04 8c 03 00 	movl   $0x38c,0x4(%esp)
f0101eba:	00 
f0101ebb:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101ec2:	e8 ef e1 ff ff       	call   f01000b6 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ec7:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101ece:	00 
f0101ecf:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101ed6:	00 
f0101ed7:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101edb:	89 04 24             	mov    %eax,(%esp)
f0101ede:	e8 aa f2 ff ff       	call   f010118d <page_insert>
f0101ee3:	85 c0                	test   %eax,%eax
f0101ee5:	74 24                	je     f0101f0b <mem_init+0xcfd>
f0101ee7:	c7 44 24 0c 24 5b 10 	movl   $0xf0105b24,0xc(%esp)
f0101eee:	f0 
f0101eef:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101ef6:	f0 
f0101ef7:	c7 44 24 04 8f 03 00 	movl   $0x38f,0x4(%esp)
f0101efe:	00 
f0101eff:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101f06:	e8 ab e1 ff ff       	call   f01000b6 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101f0b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f12:	00 
f0101f13:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f1a:	00 
f0101f1b:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0101f20:	89 04 24             	mov    %eax,(%esp)
f0101f23:	e8 38 f0 ff ff       	call   f0100f60 <pgdir_walk>
f0101f28:	f6 00 02             	testb  $0x2,(%eax)
f0101f2b:	75 24                	jne    f0101f51 <mem_init+0xd43>
f0101f2d:	c7 44 24 0c 44 5c 10 	movl   $0xf0105c44,0xc(%esp)
f0101f34:	f0 
f0101f35:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101f3c:	f0 
f0101f3d:	c7 44 24 04 90 03 00 	movl   $0x390,0x4(%esp)
f0101f44:	00 
f0101f45:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101f4c:	e8 65 e1 ff ff       	call   f01000b6 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101f51:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f58:	00 
f0101f59:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f60:	00 
f0101f61:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0101f66:	89 04 24             	mov    %eax,(%esp)
f0101f69:	e8 f2 ef ff ff       	call   f0100f60 <pgdir_walk>
f0101f6e:	f6 00 04             	testb  $0x4,(%eax)
f0101f71:	74 24                	je     f0101f97 <mem_init+0xd89>
f0101f73:	c7 44 24 0c 78 5c 10 	movl   $0xf0105c78,0xc(%esp)
f0101f7a:	f0 
f0101f7b:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101f82:	f0 
f0101f83:	c7 44 24 04 91 03 00 	movl   $0x391,0x4(%esp)
f0101f8a:	00 
f0101f8b:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101f92:	e8 1f e1 ff ff       	call   f01000b6 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101f97:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f9e:	00 
f0101f9f:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0101fa6:	00 
f0101fa7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101faa:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101fae:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0101fb3:	89 04 24             	mov    %eax,(%esp)
f0101fb6:	e8 d2 f1 ff ff       	call   f010118d <page_insert>
f0101fbb:	85 c0                	test   %eax,%eax
f0101fbd:	78 24                	js     f0101fe3 <mem_init+0xdd5>
f0101fbf:	c7 44 24 0c b0 5c 10 	movl   $0xf0105cb0,0xc(%esp)
f0101fc6:	f0 
f0101fc7:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0101fce:	f0 
f0101fcf:	c7 44 24 04 94 03 00 	movl   $0x394,0x4(%esp)
f0101fd6:	00 
f0101fd7:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0101fde:	e8 d3 e0 ff ff       	call   f01000b6 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101fe3:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101fea:	00 
f0101feb:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101ff2:	00 
f0101ff3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101ff7:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0101ffc:	89 04 24             	mov    %eax,(%esp)
f0101fff:	e8 89 f1 ff ff       	call   f010118d <page_insert>
f0102004:	85 c0                	test   %eax,%eax
f0102006:	74 24                	je     f010202c <mem_init+0xe1e>
f0102008:	c7 44 24 0c e8 5c 10 	movl   $0xf0105ce8,0xc(%esp)
f010200f:	f0 
f0102010:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0102017:	f0 
f0102018:	c7 44 24 04 97 03 00 	movl   $0x397,0x4(%esp)
f010201f:	00 
f0102020:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0102027:	e8 8a e0 ff ff       	call   f01000b6 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010202c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102033:	00 
f0102034:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010203b:	00 
f010203c:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0102041:	89 04 24             	mov    %eax,(%esp)
f0102044:	e8 17 ef ff ff       	call   f0100f60 <pgdir_walk>
f0102049:	f6 00 04             	testb  $0x4,(%eax)
f010204c:	74 24                	je     f0102072 <mem_init+0xe64>
f010204e:	c7 44 24 0c 78 5c 10 	movl   $0xf0105c78,0xc(%esp)
f0102055:	f0 
f0102056:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f010205d:	f0 
f010205e:	c7 44 24 04 98 03 00 	movl   $0x398,0x4(%esp)
f0102065:	00 
f0102066:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f010206d:	e8 44 e0 ff ff       	call   f01000b6 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0102072:	8b 3d a8 de 17 f0    	mov    0xf017dea8,%edi
f0102078:	ba 00 00 00 00       	mov    $0x0,%edx
f010207d:	89 f8                	mov    %edi,%eax
f010207f:	e8 d0 e9 ff ff       	call   f0100a54 <check_va2pa>
f0102084:	89 c1                	mov    %eax,%ecx
f0102086:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102089:	89 d8                	mov    %ebx,%eax
f010208b:	2b 05 ac de 17 f0    	sub    0xf017deac,%eax
f0102091:	c1 f8 03             	sar    $0x3,%eax
f0102094:	c1 e0 0c             	shl    $0xc,%eax
f0102097:	39 c1                	cmp    %eax,%ecx
f0102099:	74 24                	je     f01020bf <mem_init+0xeb1>
f010209b:	c7 44 24 0c 24 5d 10 	movl   $0xf0105d24,0xc(%esp)
f01020a2:	f0 
f01020a3:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f01020aa:	f0 
f01020ab:	c7 44 24 04 9b 03 00 	movl   $0x39b,0x4(%esp)
f01020b2:	00 
f01020b3:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f01020ba:	e8 f7 df ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01020bf:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020c4:	89 f8                	mov    %edi,%eax
f01020c6:	e8 89 e9 ff ff       	call   f0100a54 <check_va2pa>
f01020cb:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f01020ce:	74 24                	je     f01020f4 <mem_init+0xee6>
f01020d0:	c7 44 24 0c 50 5d 10 	movl   $0xf0105d50,0xc(%esp)
f01020d7:	f0 
f01020d8:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f01020df:	f0 
f01020e0:	c7 44 24 04 9c 03 00 	movl   $0x39c,0x4(%esp)
f01020e7:	00 
f01020e8:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f01020ef:	e8 c2 df ff ff       	call   f01000b6 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f01020f4:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f01020f9:	74 24                	je     f010211f <mem_init+0xf11>
f01020fb:	c7 44 24 0c bf 57 10 	movl   $0xf01057bf,0xc(%esp)
f0102102:	f0 
f0102103:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f010210a:	f0 
f010210b:	c7 44 24 04 9e 03 00 	movl   $0x39e,0x4(%esp)
f0102112:	00 
f0102113:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f010211a:	e8 97 df ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 0);
f010211f:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102124:	74 24                	je     f010214a <mem_init+0xf3c>
f0102126:	c7 44 24 0c d0 57 10 	movl   $0xf01057d0,0xc(%esp)
f010212d:	f0 
f010212e:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0102135:	f0 
f0102136:	c7 44 24 04 9f 03 00 	movl   $0x39f,0x4(%esp)
f010213d:	00 
f010213e:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0102145:	e8 6c df ff ff       	call   f01000b6 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f010214a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102151:	e8 1f ed ff ff       	call   f0100e75 <page_alloc>
f0102156:	85 c0                	test   %eax,%eax
f0102158:	74 04                	je     f010215e <mem_init+0xf50>
f010215a:	39 c6                	cmp    %eax,%esi
f010215c:	74 24                	je     f0102182 <mem_init+0xf74>
f010215e:	c7 44 24 0c 80 5d 10 	movl   $0xf0105d80,0xc(%esp)
f0102165:	f0 
f0102166:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f010216d:	f0 
f010216e:	c7 44 24 04 a2 03 00 	movl   $0x3a2,0x4(%esp)
f0102175:	00 
f0102176:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f010217d:	e8 34 df ff ff       	call   f01000b6 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0102182:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102189:	00 
f010218a:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f010218f:	89 04 24             	mov    %eax,(%esp)
f0102192:	e8 b1 ef ff ff       	call   f0101148 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102197:	8b 3d a8 de 17 f0    	mov    0xf017dea8,%edi
f010219d:	ba 00 00 00 00       	mov    $0x0,%edx
f01021a2:	89 f8                	mov    %edi,%eax
f01021a4:	e8 ab e8 ff ff       	call   f0100a54 <check_va2pa>
f01021a9:	83 f8 ff             	cmp    $0xffffffff,%eax
f01021ac:	74 24                	je     f01021d2 <mem_init+0xfc4>
f01021ae:	c7 44 24 0c a4 5d 10 	movl   $0xf0105da4,0xc(%esp)
f01021b5:	f0 
f01021b6:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f01021bd:	f0 
f01021be:	c7 44 24 04 a6 03 00 	movl   $0x3a6,0x4(%esp)
f01021c5:	00 
f01021c6:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f01021cd:	e8 e4 de ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01021d2:	ba 00 10 00 00       	mov    $0x1000,%edx
f01021d7:	89 f8                	mov    %edi,%eax
f01021d9:	e8 76 e8 ff ff       	call   f0100a54 <check_va2pa>
f01021de:	89 da                	mov    %ebx,%edx
f01021e0:	2b 15 ac de 17 f0    	sub    0xf017deac,%edx
f01021e6:	c1 fa 03             	sar    $0x3,%edx
f01021e9:	c1 e2 0c             	shl    $0xc,%edx
f01021ec:	39 d0                	cmp    %edx,%eax
f01021ee:	74 24                	je     f0102214 <mem_init+0x1006>
f01021f0:	c7 44 24 0c 50 5d 10 	movl   $0xf0105d50,0xc(%esp)
f01021f7:	f0 
f01021f8:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f01021ff:	f0 
f0102200:	c7 44 24 04 a7 03 00 	movl   $0x3a7,0x4(%esp)
f0102207:	00 
f0102208:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f010220f:	e8 a2 de ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 1);
f0102214:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102219:	74 24                	je     f010223f <mem_init+0x1031>
f010221b:	c7 44 24 0c 76 57 10 	movl   $0xf0105776,0xc(%esp)
f0102222:	f0 
f0102223:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f010222a:	f0 
f010222b:	c7 44 24 04 a8 03 00 	movl   $0x3a8,0x4(%esp)
f0102232:	00 
f0102233:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f010223a:	e8 77 de ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 0);
f010223f:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102244:	74 24                	je     f010226a <mem_init+0x105c>
f0102246:	c7 44 24 0c d0 57 10 	movl   $0xf01057d0,0xc(%esp)
f010224d:	f0 
f010224e:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0102255:	f0 
f0102256:	c7 44 24 04 a9 03 00 	movl   $0x3a9,0x4(%esp)
f010225d:	00 
f010225e:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0102265:	e8 4c de ff ff       	call   f01000b6 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f010226a:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0102271:	00 
f0102272:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102279:	00 
f010227a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010227e:	89 3c 24             	mov    %edi,(%esp)
f0102281:	e8 07 ef ff ff       	call   f010118d <page_insert>
f0102286:	85 c0                	test   %eax,%eax
f0102288:	74 24                	je     f01022ae <mem_init+0x10a0>
f010228a:	c7 44 24 0c c8 5d 10 	movl   $0xf0105dc8,0xc(%esp)
f0102291:	f0 
f0102292:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0102299:	f0 
f010229a:	c7 44 24 04 ac 03 00 	movl   $0x3ac,0x4(%esp)
f01022a1:	00 
f01022a2:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f01022a9:	e8 08 de ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref);
f01022ae:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01022b3:	75 24                	jne    f01022d9 <mem_init+0x10cb>
f01022b5:	c7 44 24 0c e1 57 10 	movl   $0xf01057e1,0xc(%esp)
f01022bc:	f0 
f01022bd:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f01022c4:	f0 
f01022c5:	c7 44 24 04 ad 03 00 	movl   $0x3ad,0x4(%esp)
f01022cc:	00 
f01022cd:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f01022d4:	e8 dd dd ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_link == NULL);
f01022d9:	83 3b 00             	cmpl   $0x0,(%ebx)
f01022dc:	74 24                	je     f0102302 <mem_init+0x10f4>
f01022de:	c7 44 24 0c ed 57 10 	movl   $0xf01057ed,0xc(%esp)
f01022e5:	f0 
f01022e6:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f01022ed:	f0 
f01022ee:	c7 44 24 04 ae 03 00 	movl   $0x3ae,0x4(%esp)
f01022f5:	00 
f01022f6:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f01022fd:	e8 b4 dd ff ff       	call   f01000b6 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102302:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102309:	00 
f010230a:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f010230f:	89 04 24             	mov    %eax,(%esp)
f0102312:	e8 31 ee ff ff       	call   f0101148 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102317:	8b 3d a8 de 17 f0    	mov    0xf017dea8,%edi
f010231d:	ba 00 00 00 00       	mov    $0x0,%edx
f0102322:	89 f8                	mov    %edi,%eax
f0102324:	e8 2b e7 ff ff       	call   f0100a54 <check_va2pa>
f0102329:	83 f8 ff             	cmp    $0xffffffff,%eax
f010232c:	74 24                	je     f0102352 <mem_init+0x1144>
f010232e:	c7 44 24 0c a4 5d 10 	movl   $0xf0105da4,0xc(%esp)
f0102335:	f0 
f0102336:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f010233d:	f0 
f010233e:	c7 44 24 04 b2 03 00 	movl   $0x3b2,0x4(%esp)
f0102345:	00 
f0102346:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f010234d:	e8 64 dd ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102352:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102357:	89 f8                	mov    %edi,%eax
f0102359:	e8 f6 e6 ff ff       	call   f0100a54 <check_va2pa>
f010235e:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102361:	74 24                	je     f0102387 <mem_init+0x1179>
f0102363:	c7 44 24 0c 00 5e 10 	movl   $0xf0105e00,0xc(%esp)
f010236a:	f0 
f010236b:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0102372:	f0 
f0102373:	c7 44 24 04 b3 03 00 	movl   $0x3b3,0x4(%esp)
f010237a:	00 
f010237b:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0102382:	e8 2f dd ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 0);
f0102387:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010238c:	74 24                	je     f01023b2 <mem_init+0x11a4>
f010238e:	c7 44 24 0c 02 58 10 	movl   $0xf0105802,0xc(%esp)
f0102395:	f0 
f0102396:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f010239d:	f0 
f010239e:	c7 44 24 04 b4 03 00 	movl   $0x3b4,0x4(%esp)
f01023a5:	00 
f01023a6:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f01023ad:	e8 04 dd ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 0);
f01023b2:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01023b7:	74 24                	je     f01023dd <mem_init+0x11cf>
f01023b9:	c7 44 24 0c d0 57 10 	movl   $0xf01057d0,0xc(%esp)
f01023c0:	f0 
f01023c1:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f01023c8:	f0 
f01023c9:	c7 44 24 04 b5 03 00 	movl   $0x3b5,0x4(%esp)
f01023d0:	00 
f01023d1:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f01023d8:	e8 d9 dc ff ff       	call   f01000b6 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f01023dd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01023e4:	e8 8c ea ff ff       	call   f0100e75 <page_alloc>
f01023e9:	85 c0                	test   %eax,%eax
f01023eb:	74 04                	je     f01023f1 <mem_init+0x11e3>
f01023ed:	39 c3                	cmp    %eax,%ebx
f01023ef:	74 24                	je     f0102415 <mem_init+0x1207>
f01023f1:	c7 44 24 0c 28 5e 10 	movl   $0xf0105e28,0xc(%esp)
f01023f8:	f0 
f01023f9:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0102400:	f0 
f0102401:	c7 44 24 04 b8 03 00 	movl   $0x3b8,0x4(%esp)
f0102408:	00 
f0102409:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0102410:	e8 a1 dc ff ff       	call   f01000b6 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102415:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010241c:	e8 54 ea ff ff       	call   f0100e75 <page_alloc>
f0102421:	85 c0                	test   %eax,%eax
f0102423:	74 24                	je     f0102449 <mem_init+0x123b>
f0102425:	c7 44 24 0c 24 57 10 	movl   $0xf0105724,0xc(%esp)
f010242c:	f0 
f010242d:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0102434:	f0 
f0102435:	c7 44 24 04 bb 03 00 	movl   $0x3bb,0x4(%esp)
f010243c:	00 
f010243d:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0102444:	e8 6d dc ff ff       	call   f01000b6 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102449:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f010244e:	8b 08                	mov    (%eax),%ecx
f0102450:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102456:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102459:	2b 15 ac de 17 f0    	sub    0xf017deac,%edx
f010245f:	c1 fa 03             	sar    $0x3,%edx
f0102462:	c1 e2 0c             	shl    $0xc,%edx
f0102465:	39 d1                	cmp    %edx,%ecx
f0102467:	74 24                	je     f010248d <mem_init+0x127f>
f0102469:	c7 44 24 0c cc 5a 10 	movl   $0xf0105acc,0xc(%esp)
f0102470:	f0 
f0102471:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0102478:	f0 
f0102479:	c7 44 24 04 be 03 00 	movl   $0x3be,0x4(%esp)
f0102480:	00 
f0102481:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0102488:	e8 29 dc ff ff       	call   f01000b6 <_panic>
	kern_pgdir[0] = 0;
f010248d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102493:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102496:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010249b:	74 24                	je     f01024c1 <mem_init+0x12b3>
f010249d:	c7 44 24 0c 87 57 10 	movl   $0xf0105787,0xc(%esp)
f01024a4:	f0 
f01024a5:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f01024ac:	f0 
f01024ad:	c7 44 24 04 c0 03 00 	movl   $0x3c0,0x4(%esp)
f01024b4:	00 
f01024b5:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f01024bc:	e8 f5 db ff ff       	call   f01000b6 <_panic>
	pp0->pp_ref = 0;
f01024c1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01024c4:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01024ca:	89 04 24             	mov    %eax,(%esp)
f01024cd:	e8 2e ea ff ff       	call   f0100f00 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01024d2:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01024d9:	00 
f01024da:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f01024e1:	00 
f01024e2:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f01024e7:	89 04 24             	mov    %eax,(%esp)
f01024ea:	e8 71 ea ff ff       	call   f0100f60 <pgdir_walk>
f01024ef:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01024f2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01024f5:	8b 15 a8 de 17 f0    	mov    0xf017dea8,%edx
f01024fb:	8b 7a 04             	mov    0x4(%edx),%edi
f01024fe:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102504:	8b 0d a4 de 17 f0    	mov    0xf017dea4,%ecx
f010250a:	89 f8                	mov    %edi,%eax
f010250c:	c1 e8 0c             	shr    $0xc,%eax
f010250f:	39 c8                	cmp    %ecx,%eax
f0102511:	72 20                	jb     f0102533 <mem_init+0x1325>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102513:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0102517:	c7 44 24 08 8c 58 10 	movl   $0xf010588c,0x8(%esp)
f010251e:	f0 
f010251f:	c7 44 24 04 c7 03 00 	movl   $0x3c7,0x4(%esp)
f0102526:	00 
f0102527:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f010252e:	e8 83 db ff ff       	call   f01000b6 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102533:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f0102539:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f010253c:	74 24                	je     f0102562 <mem_init+0x1354>
f010253e:	c7 44 24 0c 13 58 10 	movl   $0xf0105813,0xc(%esp)
f0102545:	f0 
f0102546:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f010254d:	f0 
f010254e:	c7 44 24 04 c8 03 00 	movl   $0x3c8,0x4(%esp)
f0102555:	00 
f0102556:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f010255d:	e8 54 db ff ff       	call   f01000b6 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102562:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f0102569:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010256c:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102572:	2b 05 ac de 17 f0    	sub    0xf017deac,%eax
f0102578:	c1 f8 03             	sar    $0x3,%eax
f010257b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010257e:	89 c2                	mov    %eax,%edx
f0102580:	c1 ea 0c             	shr    $0xc,%edx
f0102583:	39 d1                	cmp    %edx,%ecx
f0102585:	77 20                	ja     f01025a7 <mem_init+0x1399>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102587:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010258b:	c7 44 24 08 8c 58 10 	movl   $0xf010588c,0x8(%esp)
f0102592:	f0 
f0102593:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f010259a:	00 
f010259b:	c7 04 24 a0 55 10 f0 	movl   $0xf01055a0,(%esp)
f01025a2:	e8 0f db ff ff       	call   f01000b6 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01025a7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01025ae:	00 
f01025af:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f01025b6:	00 
	return (void *)(pa + KERNBASE);
f01025b7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01025bc:	89 04 24             	mov    %eax,(%esp)
f01025bf:	e8 03 26 00 00       	call   f0104bc7 <memset>
	page_free(pp0);
f01025c4:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01025c7:	89 3c 24             	mov    %edi,(%esp)
f01025ca:	e8 31 e9 ff ff       	call   f0100f00 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01025cf:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01025d6:	00 
f01025d7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01025de:	00 
f01025df:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f01025e4:	89 04 24             	mov    %eax,(%esp)
f01025e7:	e8 74 e9 ff ff       	call   f0100f60 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01025ec:	89 fa                	mov    %edi,%edx
f01025ee:	2b 15 ac de 17 f0    	sub    0xf017deac,%edx
f01025f4:	c1 fa 03             	sar    $0x3,%edx
f01025f7:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025fa:	89 d0                	mov    %edx,%eax
f01025fc:	c1 e8 0c             	shr    $0xc,%eax
f01025ff:	3b 05 a4 de 17 f0    	cmp    0xf017dea4,%eax
f0102605:	72 20                	jb     f0102627 <mem_init+0x1419>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102607:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010260b:	c7 44 24 08 8c 58 10 	movl   $0xf010588c,0x8(%esp)
f0102612:	f0 
f0102613:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f010261a:	00 
f010261b:	c7 04 24 a0 55 10 f0 	movl   $0xf01055a0,(%esp)
f0102622:	e8 8f da ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0102627:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010262d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102630:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102636:	f6 00 01             	testb  $0x1,(%eax)
f0102639:	74 24                	je     f010265f <mem_init+0x1451>
f010263b:	c7 44 24 0c 2b 58 10 	movl   $0xf010582b,0xc(%esp)
f0102642:	f0 
f0102643:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f010264a:	f0 
f010264b:	c7 44 24 04 d2 03 00 	movl   $0x3d2,0x4(%esp)
f0102652:	00 
f0102653:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f010265a:	e8 57 da ff ff       	call   f01000b6 <_panic>
f010265f:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102662:	39 d0                	cmp    %edx,%eax
f0102664:	75 d0                	jne    f0102636 <mem_init+0x1428>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102666:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f010266b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102671:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102674:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f010267a:	8b 7d d0             	mov    -0x30(%ebp),%edi
f010267d:	89 3d e0 d1 17 f0    	mov    %edi,0xf017d1e0

	// free the pages we took
	page_free(pp0);
f0102683:	89 04 24             	mov    %eax,(%esp)
f0102686:	e8 75 e8 ff ff       	call   f0100f00 <page_free>
	page_free(pp1);
f010268b:	89 1c 24             	mov    %ebx,(%esp)
f010268e:	e8 6d e8 ff ff       	call   f0100f00 <page_free>
	page_free(pp2);
f0102693:	89 34 24             	mov    %esi,(%esp)
f0102696:	e8 65 e8 ff ff       	call   f0100f00 <page_free>

	cprintf("check_page() succeeded!\n");
f010269b:	c7 04 24 42 58 10 f0 	movl   $0xf0105842,(%esp)
f01026a2:	e8 47 10 00 00       	call   f01036ee <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	//static void boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm);
	boot_map_region(kern_pgdir, UPAGES, PTSIZE,PADDR(pages), PTE_U | PTE_P);
f01026a7:	a1 ac de 17 f0       	mov    0xf017deac,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026ac:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01026b1:	77 20                	ja     f01026d3 <mem_init+0x14c5>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026b3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01026b7:	c7 44 24 08 74 59 10 	movl   $0xf0105974,0x8(%esp)
f01026be:	f0 
f01026bf:	c7 44 24 04 ce 00 00 	movl   $0xce,0x4(%esp)
f01026c6:	00 
f01026c7:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f01026ce:	e8 e3 d9 ff ff       	call   f01000b6 <_panic>
f01026d3:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f01026da:	00 
	return (physaddr_t)kva - KERNBASE;
f01026db:	05 00 00 00 10       	add    $0x10000000,%eax
f01026e0:	89 04 24             	mov    %eax,(%esp)
f01026e3:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01026e8:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01026ed:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f01026f2:	e8 83 e9 ff ff       	call   f010107a <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, PTSIZE,PADDR(envs), PTE_U | PTE_P);
f01026f7:	a1 ec d1 17 f0       	mov    0xf017d1ec,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026fc:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102701:	77 20                	ja     f0102723 <mem_init+0x1515>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102703:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102707:	c7 44 24 08 74 59 10 	movl   $0xf0105974,0x8(%esp)
f010270e:	f0 
f010270f:	c7 44 24 04 da 00 00 	movl   $0xda,0x4(%esp)
f0102716:	00 
f0102717:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f010271e:	e8 93 d9 ff ff       	call   f01000b6 <_panic>
f0102723:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f010272a:	00 
	return (physaddr_t)kva - KERNBASE;
f010272b:	05 00 00 00 10       	add    $0x10000000,%eax
f0102730:	89 04 24             	mov    %eax,(%esp)
f0102733:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102738:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f010273d:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0102742:	e8 33 e9 ff ff       	call   f010107a <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102747:	bb 00 10 11 f0       	mov    $0xf0111000,%ebx
f010274c:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102752:	77 20                	ja     f0102774 <mem_init+0x1566>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102754:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102758:	c7 44 24 08 74 59 10 	movl   $0xf0105974,0x8(%esp)
f010275f:	f0 
f0102760:	c7 44 24 04 e6 00 00 	movl   $0xe6,0x4(%esp)
f0102767:	00 
f0102768:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f010276f:	e8 42 d9 ff ff       	call   f01000b6 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE,PADDR(bootstack), PTE_W );
f0102774:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f010277b:	00 
f010277c:	c7 04 24 00 10 11 00 	movl   $0x111000,(%esp)
f0102783:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102788:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f010278d:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0102792:	e8 e3 e8 ff ff       	call   f010107a <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	uint64_t kern_map_length = 0x100000000 - (uint64_t) KERNBASE;
    boot_map_region(kern_pgdir, KERNBASE,kern_map_length ,0, PTE_W | PTE_P);
f0102797:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f010279e:	00 
f010279f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01027a6:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01027ab:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01027b0:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f01027b5:	e8 c0 e8 ff ff       	call   f010107a <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01027ba:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f01027bf:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01027c2:	a1 a4 de 17 f0       	mov    0xf017dea4,%eax
f01027c7:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01027ca:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01027d1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01027d6:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01027d9:	8b 3d ac de 17 f0    	mov    0xf017deac,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01027df:	89 7d c8             	mov    %edi,-0x38(%ebp)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
f01027e2:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f01027e8:	89 45 c4             	mov    %eax,-0x3c(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01027eb:	be 00 00 00 00       	mov    $0x0,%esi
f01027f0:	eb 6b                	jmp    f010285d <mem_init+0x164f>
f01027f2:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01027f8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01027fb:	e8 54 e2 ff ff       	call   f0100a54 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102800:	81 7d c8 ff ff ff ef 	cmpl   $0xefffffff,-0x38(%ebp)
f0102807:	77 20                	ja     f0102829 <mem_init+0x161b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102809:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010280d:	c7 44 24 08 74 59 10 	movl   $0xf0105974,0x8(%esp)
f0102814:	f0 
f0102815:	c7 44 24 04 0f 03 00 	movl   $0x30f,0x4(%esp)
f010281c:	00 
f010281d:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0102824:	e8 8d d8 ff ff       	call   f01000b6 <_panic>
f0102829:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f010282c:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010282f:	39 d0                	cmp    %edx,%eax
f0102831:	74 24                	je     f0102857 <mem_init+0x1649>
f0102833:	c7 44 24 0c 4c 5e 10 	movl   $0xf0105e4c,0xc(%esp)
f010283a:	f0 
f010283b:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0102842:	f0 
f0102843:	c7 44 24 04 0f 03 00 	movl   $0x30f,0x4(%esp)
f010284a:	00 
f010284b:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0102852:	e8 5f d8 ff ff       	call   f01000b6 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102857:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010285d:	39 75 cc             	cmp    %esi,-0x34(%ebp)
f0102860:	77 90                	ja     f01027f2 <mem_init+0x15e4>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102862:	8b 35 ec d1 17 f0    	mov    0xf017d1ec,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102868:	89 f7                	mov    %esi,%edi
f010286a:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f010286f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102872:	e8 dd e1 ff ff       	call   f0100a54 <check_va2pa>
f0102877:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f010287d:	77 20                	ja     f010289f <mem_init+0x1691>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010287f:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0102883:	c7 44 24 08 74 59 10 	movl   $0xf0105974,0x8(%esp)
f010288a:	f0 
f010288b:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
f0102892:	00 
f0102893:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f010289a:	e8 17 d8 ff ff       	call   f01000b6 <_panic>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010289f:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f01028a4:	81 c7 00 00 40 21    	add    $0x21400000,%edi
f01028aa:	8d 14 37             	lea    (%edi,%esi,1),%edx
f01028ad:	39 c2                	cmp    %eax,%edx
f01028af:	74 24                	je     f01028d5 <mem_init+0x16c7>
f01028b1:	c7 44 24 0c 80 5e 10 	movl   $0xf0105e80,0xc(%esp)
f01028b8:	f0 
f01028b9:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f01028c0:	f0 
f01028c1:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
f01028c8:	00 
f01028c9:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f01028d0:	e8 e1 d7 ff ff       	call   f01000b6 <_panic>
f01028d5:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01028db:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f01028e1:	0f 85 26 05 00 00    	jne    f0102e0d <mem_init+0x1bff>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01028e7:	8b 7d d0             	mov    -0x30(%ebp),%edi
f01028ea:	c1 e7 0c             	shl    $0xc,%edi
f01028ed:	be 00 00 00 00       	mov    $0x0,%esi
f01028f2:	eb 3c                	jmp    f0102930 <mem_init+0x1722>
f01028f4:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01028fa:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01028fd:	e8 52 e1 ff ff       	call   f0100a54 <check_va2pa>
f0102902:	39 c6                	cmp    %eax,%esi
f0102904:	74 24                	je     f010292a <mem_init+0x171c>
f0102906:	c7 44 24 0c b4 5e 10 	movl   $0xf0105eb4,0xc(%esp)
f010290d:	f0 
f010290e:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0102915:	f0 
f0102916:	c7 44 24 04 18 03 00 	movl   $0x318,0x4(%esp)
f010291d:	00 
f010291e:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0102925:	e8 8c d7 ff ff       	call   f01000b6 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010292a:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102930:	39 fe                	cmp    %edi,%esi
f0102932:	72 c0                	jb     f01028f4 <mem_init+0x16e6>
f0102934:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f0102939:	81 c3 00 80 00 20    	add    $0x20008000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010293f:	89 f2                	mov    %esi,%edx
f0102941:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102944:	e8 0b e1 ff ff       	call   f0100a54 <check_va2pa>
f0102949:	8d 14 33             	lea    (%ebx,%esi,1),%edx
f010294c:	39 d0                	cmp    %edx,%eax
f010294e:	74 24                	je     f0102974 <mem_init+0x1766>
f0102950:	c7 44 24 0c dc 5e 10 	movl   $0xf0105edc,0xc(%esp)
f0102957:	f0 
f0102958:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f010295f:	f0 
f0102960:	c7 44 24 04 1c 03 00 	movl   $0x31c,0x4(%esp)
f0102967:	00 
f0102968:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f010296f:	e8 42 d7 ff ff       	call   f01000b6 <_panic>
f0102974:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010297a:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102980:	75 bd                	jne    f010293f <mem_init+0x1731>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102982:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102987:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010298a:	89 f8                	mov    %edi,%eax
f010298c:	e8 c3 e0 ff ff       	call   f0100a54 <check_va2pa>
f0102991:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102994:	75 0c                	jne    f01029a2 <mem_init+0x1794>
f0102996:	b8 00 00 00 00       	mov    $0x0,%eax
f010299b:	89 fa                	mov    %edi,%edx
f010299d:	e9 f0 00 00 00       	jmp    f0102a92 <mem_init+0x1884>
f01029a2:	c7 44 24 0c 24 5f 10 	movl   $0xf0105f24,0xc(%esp)
f01029a9:	f0 
f01029aa:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f01029b1:	f0 
f01029b2:	c7 44 24 04 1d 03 00 	movl   $0x31d,0x4(%esp)
f01029b9:	00 
f01029ba:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f01029c1:	e8 f0 d6 ff ff       	call   f01000b6 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01029c6:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f01029cb:	72 3c                	jb     f0102a09 <mem_init+0x17fb>
f01029cd:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f01029d2:	76 07                	jbe    f01029db <mem_init+0x17cd>
f01029d4:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01029d9:	75 2e                	jne    f0102a09 <mem_init+0x17fb>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f01029db:	f6 04 82 01          	testb  $0x1,(%edx,%eax,4)
f01029df:	0f 85 aa 00 00 00    	jne    f0102a8f <mem_init+0x1881>
f01029e5:	c7 44 24 0c 5b 58 10 	movl   $0xf010585b,0xc(%esp)
f01029ec:	f0 
f01029ed:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f01029f4:	f0 
f01029f5:	c7 44 24 04 26 03 00 	movl   $0x326,0x4(%esp)
f01029fc:	00 
f01029fd:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0102a04:	e8 ad d6 ff ff       	call   f01000b6 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102a09:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102a0e:	76 55                	jbe    f0102a65 <mem_init+0x1857>
				assert(pgdir[i] & PTE_P);
f0102a10:	8b 0c 82             	mov    (%edx,%eax,4),%ecx
f0102a13:	f6 c1 01             	test   $0x1,%cl
f0102a16:	75 24                	jne    f0102a3c <mem_init+0x182e>
f0102a18:	c7 44 24 0c 5b 58 10 	movl   $0xf010585b,0xc(%esp)
f0102a1f:	f0 
f0102a20:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0102a27:	f0 
f0102a28:	c7 44 24 04 2a 03 00 	movl   $0x32a,0x4(%esp)
f0102a2f:	00 
f0102a30:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0102a37:	e8 7a d6 ff ff       	call   f01000b6 <_panic>
				assert(pgdir[i] & PTE_W);
f0102a3c:	f6 c1 02             	test   $0x2,%cl
f0102a3f:	75 4e                	jne    f0102a8f <mem_init+0x1881>
f0102a41:	c7 44 24 0c 6c 58 10 	movl   $0xf010586c,0xc(%esp)
f0102a48:	f0 
f0102a49:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0102a50:	f0 
f0102a51:	c7 44 24 04 2b 03 00 	movl   $0x32b,0x4(%esp)
f0102a58:	00 
f0102a59:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0102a60:	e8 51 d6 ff ff       	call   f01000b6 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102a65:	83 3c 82 00          	cmpl   $0x0,(%edx,%eax,4)
f0102a69:	74 24                	je     f0102a8f <mem_init+0x1881>
f0102a6b:	c7 44 24 0c 7d 58 10 	movl   $0xf010587d,0xc(%esp)
f0102a72:	f0 
f0102a73:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0102a7a:	f0 
f0102a7b:	c7 44 24 04 2d 03 00 	movl   $0x32d,0x4(%esp)
f0102a82:	00 
f0102a83:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0102a8a:	e8 27 d6 ff ff       	call   f01000b6 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102a8f:	83 c0 01             	add    $0x1,%eax
f0102a92:	3d 00 04 00 00       	cmp    $0x400,%eax
f0102a97:	0f 85 29 ff ff ff    	jne    f01029c6 <mem_init+0x17b8>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102a9d:	c7 04 24 54 5f 10 f0 	movl   $0xf0105f54,(%esp)
f0102aa4:	e8 45 0c 00 00       	call   f01036ee <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102aa9:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0102aae:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102ab3:	77 20                	ja     f0102ad5 <mem_init+0x18c7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ab5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102ab9:	c7 44 24 08 74 59 10 	movl   $0xf0105974,0x8(%esp)
f0102ac0:	f0 
f0102ac1:	c7 44 24 04 fe 00 00 	movl   $0xfe,0x4(%esp)
f0102ac8:	00 
f0102ac9:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0102ad0:	e8 e1 d5 ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102ad5:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102ada:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102add:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ae2:	e8 dc df ff ff       	call   f0100ac3 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102ae7:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f0102aea:	83 e0 f3             	and    $0xfffffff3,%eax
f0102aed:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102af2:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102af5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102afc:	e8 74 e3 ff ff       	call   f0100e75 <page_alloc>
f0102b01:	89 c3                	mov    %eax,%ebx
f0102b03:	85 c0                	test   %eax,%eax
f0102b05:	75 24                	jne    f0102b2b <mem_init+0x191d>
f0102b07:	c7 44 24 0c 79 56 10 	movl   $0xf0105679,0xc(%esp)
f0102b0e:	f0 
f0102b0f:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0102b16:	f0 
f0102b17:	c7 44 24 04 ed 03 00 	movl   $0x3ed,0x4(%esp)
f0102b1e:	00 
f0102b1f:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0102b26:	e8 8b d5 ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f0102b2b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102b32:	e8 3e e3 ff ff       	call   f0100e75 <page_alloc>
f0102b37:	89 c7                	mov    %eax,%edi
f0102b39:	85 c0                	test   %eax,%eax
f0102b3b:	75 24                	jne    f0102b61 <mem_init+0x1953>
f0102b3d:	c7 44 24 0c 8f 56 10 	movl   $0xf010568f,0xc(%esp)
f0102b44:	f0 
f0102b45:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0102b4c:	f0 
f0102b4d:	c7 44 24 04 ee 03 00 	movl   $0x3ee,0x4(%esp)
f0102b54:	00 
f0102b55:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0102b5c:	e8 55 d5 ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f0102b61:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102b68:	e8 08 e3 ff ff       	call   f0100e75 <page_alloc>
f0102b6d:	89 c6                	mov    %eax,%esi
f0102b6f:	85 c0                	test   %eax,%eax
f0102b71:	75 24                	jne    f0102b97 <mem_init+0x1989>
f0102b73:	c7 44 24 0c a5 56 10 	movl   $0xf01056a5,0xc(%esp)
f0102b7a:	f0 
f0102b7b:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0102b82:	f0 
f0102b83:	c7 44 24 04 ef 03 00 	movl   $0x3ef,0x4(%esp)
f0102b8a:	00 
f0102b8b:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0102b92:	e8 1f d5 ff ff       	call   f01000b6 <_panic>
	page_free(pp0);
f0102b97:	89 1c 24             	mov    %ebx,(%esp)
f0102b9a:	e8 61 e3 ff ff       	call   f0100f00 <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f0102b9f:	89 f8                	mov    %edi,%eax
f0102ba1:	e8 69 de ff ff       	call   f0100a0f <page2kva>
f0102ba6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102bad:	00 
f0102bae:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102bb5:	00 
f0102bb6:	89 04 24             	mov    %eax,(%esp)
f0102bb9:	e8 09 20 00 00       	call   f0104bc7 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f0102bbe:	89 f0                	mov    %esi,%eax
f0102bc0:	e8 4a de ff ff       	call   f0100a0f <page2kva>
f0102bc5:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102bcc:	00 
f0102bcd:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102bd4:	00 
f0102bd5:	89 04 24             	mov    %eax,(%esp)
f0102bd8:	e8 ea 1f 00 00       	call   f0104bc7 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102bdd:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102be4:	00 
f0102be5:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102bec:	00 
f0102bed:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102bf1:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0102bf6:	89 04 24             	mov    %eax,(%esp)
f0102bf9:	e8 8f e5 ff ff       	call   f010118d <page_insert>
	assert(pp1->pp_ref == 1);
f0102bfe:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102c03:	74 24                	je     f0102c29 <mem_init+0x1a1b>
f0102c05:	c7 44 24 0c 76 57 10 	movl   $0xf0105776,0xc(%esp)
f0102c0c:	f0 
f0102c0d:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0102c14:	f0 
f0102c15:	c7 44 24 04 f4 03 00 	movl   $0x3f4,0x4(%esp)
f0102c1c:	00 
f0102c1d:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0102c24:	e8 8d d4 ff ff       	call   f01000b6 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102c29:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102c30:	01 01 01 
f0102c33:	74 24                	je     f0102c59 <mem_init+0x1a4b>
f0102c35:	c7 44 24 0c 74 5f 10 	movl   $0xf0105f74,0xc(%esp)
f0102c3c:	f0 
f0102c3d:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0102c44:	f0 
f0102c45:	c7 44 24 04 f5 03 00 	movl   $0x3f5,0x4(%esp)
f0102c4c:	00 
f0102c4d:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0102c54:	e8 5d d4 ff ff       	call   f01000b6 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102c59:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102c60:	00 
f0102c61:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102c68:	00 
f0102c69:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102c6d:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0102c72:	89 04 24             	mov    %eax,(%esp)
f0102c75:	e8 13 e5 ff ff       	call   f010118d <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102c7a:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102c81:	02 02 02 
f0102c84:	74 24                	je     f0102caa <mem_init+0x1a9c>
f0102c86:	c7 44 24 0c 98 5f 10 	movl   $0xf0105f98,0xc(%esp)
f0102c8d:	f0 
f0102c8e:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0102c95:	f0 
f0102c96:	c7 44 24 04 f7 03 00 	movl   $0x3f7,0x4(%esp)
f0102c9d:	00 
f0102c9e:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0102ca5:	e8 0c d4 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0102caa:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102caf:	74 24                	je     f0102cd5 <mem_init+0x1ac7>
f0102cb1:	c7 44 24 0c 98 57 10 	movl   $0xf0105798,0xc(%esp)
f0102cb8:	f0 
f0102cb9:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0102cc0:	f0 
f0102cc1:	c7 44 24 04 f8 03 00 	movl   $0x3f8,0x4(%esp)
f0102cc8:	00 
f0102cc9:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0102cd0:	e8 e1 d3 ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 0);
f0102cd5:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102cda:	74 24                	je     f0102d00 <mem_init+0x1af2>
f0102cdc:	c7 44 24 0c 02 58 10 	movl   $0xf0105802,0xc(%esp)
f0102ce3:	f0 
f0102ce4:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0102ceb:	f0 
f0102cec:	c7 44 24 04 f9 03 00 	movl   $0x3f9,0x4(%esp)
f0102cf3:	00 
f0102cf4:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0102cfb:	e8 b6 d3 ff ff       	call   f01000b6 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102d00:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102d07:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102d0a:	89 f0                	mov    %esi,%eax
f0102d0c:	e8 fe dc ff ff       	call   f0100a0f <page2kva>
f0102d11:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f0102d17:	74 24                	je     f0102d3d <mem_init+0x1b2f>
f0102d19:	c7 44 24 0c bc 5f 10 	movl   $0xf0105fbc,0xc(%esp)
f0102d20:	f0 
f0102d21:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0102d28:	f0 
f0102d29:	c7 44 24 04 fb 03 00 	movl   $0x3fb,0x4(%esp)
f0102d30:	00 
f0102d31:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0102d38:	e8 79 d3 ff ff       	call   f01000b6 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102d3d:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102d44:	00 
f0102d45:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0102d4a:	89 04 24             	mov    %eax,(%esp)
f0102d4d:	e8 f6 e3 ff ff       	call   f0101148 <page_remove>
	assert(pp2->pp_ref == 0);
f0102d52:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102d57:	74 24                	je     f0102d7d <mem_init+0x1b6f>
f0102d59:	c7 44 24 0c d0 57 10 	movl   $0xf01057d0,0xc(%esp)
f0102d60:	f0 
f0102d61:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0102d68:	f0 
f0102d69:	c7 44 24 04 fd 03 00 	movl   $0x3fd,0x4(%esp)
f0102d70:	00 
f0102d71:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0102d78:	e8 39 d3 ff ff       	call   f01000b6 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102d7d:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0102d82:	8b 08                	mov    (%eax),%ecx
f0102d84:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102d8a:	89 da                	mov    %ebx,%edx
f0102d8c:	2b 15 ac de 17 f0    	sub    0xf017deac,%edx
f0102d92:	c1 fa 03             	sar    $0x3,%edx
f0102d95:	c1 e2 0c             	shl    $0xc,%edx
f0102d98:	39 d1                	cmp    %edx,%ecx
f0102d9a:	74 24                	je     f0102dc0 <mem_init+0x1bb2>
f0102d9c:	c7 44 24 0c cc 5a 10 	movl   $0xf0105acc,0xc(%esp)
f0102da3:	f0 
f0102da4:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0102dab:	f0 
f0102dac:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
f0102db3:	00 
f0102db4:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0102dbb:	e8 f6 d2 ff ff       	call   f01000b6 <_panic>
	kern_pgdir[0] = 0;
f0102dc0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102dc6:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102dcb:	74 24                	je     f0102df1 <mem_init+0x1be3>
f0102dcd:	c7 44 24 0c 87 57 10 	movl   $0xf0105787,0xc(%esp)
f0102dd4:	f0 
f0102dd5:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0102ddc:	f0 
f0102ddd:	c7 44 24 04 02 04 00 	movl   $0x402,0x4(%esp)
f0102de4:	00 
f0102de5:	c7 04 24 94 55 10 f0 	movl   $0xf0105594,(%esp)
f0102dec:	e8 c5 d2 ff ff       	call   f01000b6 <_panic>
	pp0->pp_ref = 0;
f0102df1:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102df7:	89 1c 24             	mov    %ebx,(%esp)
f0102dfa:	e8 01 e1 ff ff       	call   f0100f00 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102dff:	c7 04 24 e8 5f 10 f0 	movl   $0xf0105fe8,(%esp)
f0102e06:	e8 e3 08 00 00       	call   f01036ee <cprintf>
f0102e0b:	eb 0f                	jmp    f0102e1c <mem_init+0x1c0e>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102e0d:	89 f2                	mov    %esi,%edx
f0102e0f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102e12:	e8 3d dc ff ff       	call   f0100a54 <check_va2pa>
f0102e17:	e9 8e fa ff ff       	jmp    f01028aa <mem_init+0x169c>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102e1c:	83 c4 4c             	add    $0x4c,%esp
f0102e1f:	5b                   	pop    %ebx
f0102e20:	5e                   	pop    %esi
f0102e21:	5f                   	pop    %edi
f0102e22:	5d                   	pop    %ebp
f0102e23:	c3                   	ret    

f0102e24 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102e24:	55                   	push   %ebp
f0102e25:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102e27:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e2a:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102e2d:	5d                   	pop    %ebp
f0102e2e:	c3                   	ret    

f0102e2f <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102e2f:	55                   	push   %ebp
f0102e30:	89 e5                	mov    %esp,%ebp
f0102e32:	57                   	push   %edi
f0102e33:	56                   	push   %esi
f0102e34:	53                   	push   %ebx
f0102e35:	83 ec 1c             	sub    $0x1c,%esp
f0102e38:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	pte_t *pte;
	uint32_t addr = ROUNDDOWN((uint32_t) va, PGSIZE);
f0102e3b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102e3e:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uint32_t end = ROUNDUP((uint32_t) va + len, PGSIZE);
f0102e44:	8b 45 10             	mov    0x10(%ebp),%eax
f0102e47:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102e4a:	8d 84 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%eax
f0102e51:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102e56:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	perm |= PTE_P;
f0102e59:	8b 75 14             	mov    0x14(%ebp),%esi
f0102e5c:	83 ce 01             	or     $0x1,%esi

	for (; addr < end; addr += PGSIZE) {
f0102e5f:	eb 45                	jmp    f0102ea6 <user_mem_check+0x77>
		pte = pgdir_walk(env->env_pgdir, (void*) addr, 0); 
f0102e61:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102e68:	00 
f0102e69:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102e6d:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102e70:	89 04 24             	mov    %eax,(%esp)
f0102e73:	e8 e8 e0 ff ff       	call   f0100f60 <pgdir_walk>
		
		if (!pte|| addr >= ULIM|| ((*pte & perm) != perm) ) {
f0102e78:	85 c0                	test   %eax,%eax
f0102e7a:	74 10                	je     f0102e8c <user_mem_check+0x5d>
f0102e7c:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102e82:	77 08                	ja     f0102e8c <user_mem_check+0x5d>
f0102e84:	89 f2                	mov    %esi,%edx
f0102e86:	23 10                	and    (%eax),%edx
f0102e88:	39 d6                	cmp    %edx,%esi
f0102e8a:	74 14                	je     f0102ea0 <user_mem_check+0x71>
f0102e8c:	3b 5d 0c             	cmp    0xc(%ebp),%ebx
f0102e8f:	0f 42 5d 0c          	cmovb  0xc(%ebp),%ebx
			user_mem_check_addr = addr < (uint32_t) va ? (uintptr_t) va : addr;
f0102e93:	89 1d dc d1 17 f0    	mov    %ebx,0xf017d1dc
			return -E_FAULT;
f0102e99:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102e9e:	eb 10                	jmp    f0102eb0 <user_mem_check+0x81>
	pte_t *pte;
	uint32_t addr = ROUNDDOWN((uint32_t) va, PGSIZE);
	uint32_t end = ROUNDUP((uint32_t) va + len, PGSIZE);
	perm |= PTE_P;

	for (; addr < end; addr += PGSIZE) {
f0102ea0:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102ea6:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0102ea9:	72 b6                	jb     f0102e61 <user_mem_check+0x32>
			user_mem_check_addr = addr < (uint32_t) va ? (uintptr_t) va : addr;
			return -E_FAULT;
		}
	}

	return 0;
f0102eab:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102eb0:	83 c4 1c             	add    $0x1c,%esp
f0102eb3:	5b                   	pop    %ebx
f0102eb4:	5e                   	pop    %esi
f0102eb5:	5f                   	pop    %edi
f0102eb6:	5d                   	pop    %ebp
f0102eb7:	c3                   	ret    

f0102eb8 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102eb8:	55                   	push   %ebp
f0102eb9:	89 e5                	mov    %esp,%ebp
f0102ebb:	53                   	push   %ebx
f0102ebc:	83 ec 14             	sub    $0x14,%esp
f0102ebf:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102ec2:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ec5:	83 c8 04             	or     $0x4,%eax
f0102ec8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102ecc:	8b 45 10             	mov    0x10(%ebp),%eax
f0102ecf:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102ed3:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ed6:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102eda:	89 1c 24             	mov    %ebx,(%esp)
f0102edd:	e8 4d ff ff ff       	call   f0102e2f <user_mem_check>
f0102ee2:	85 c0                	test   %eax,%eax
f0102ee4:	79 24                	jns    f0102f0a <user_mem_assert+0x52>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102ee6:	a1 dc d1 17 f0       	mov    0xf017d1dc,%eax
f0102eeb:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102eef:	8b 43 48             	mov    0x48(%ebx),%eax
f0102ef2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102ef6:	c7 04 24 14 60 10 f0 	movl   $0xf0106014,(%esp)
f0102efd:	e8 ec 07 00 00       	call   f01036ee <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102f02:	89 1c 24             	mov    %ebx,(%esp)
f0102f05:	e8 aa 06 00 00       	call   f01035b4 <env_destroy>
	}
}
f0102f0a:	83 c4 14             	add    $0x14,%esp
f0102f0d:	5b                   	pop    %ebx
f0102f0e:	5d                   	pop    %ebp
f0102f0f:	c3                   	ret    

f0102f10 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102f10:	55                   	push   %ebp
f0102f11:	89 e5                	mov    %esp,%ebp
f0102f13:	57                   	push   %edi
f0102f14:	56                   	push   %esi
f0102f15:	53                   	push   %ebx
f0102f16:	83 ec 1c             	sub    $0x1c,%esp
f0102f19:	89 c7                	mov    %eax,%edi
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	
	uint32_t startadd=(uint32_t)ROUNDDOWN(va,PGSIZE);
f0102f1b:	89 d3                	mov    %edx,%ebx
f0102f1d:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uint32_t endadd=(uint32_t)ROUNDUP(va+len,PGSIZE);
f0102f23:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102f2a:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	
	while(startadd<endadd)
f0102f30:	eb 6e                	jmp    f0102fa0 <region_alloc+0x90>
	{
	struct PageInfo* p=page_alloc(false);	
f0102f32:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102f39:	e8 37 df ff ff       	call   f0100e75 <page_alloc>
	
	if(p==NULL)
f0102f3e:	85 c0                	test   %eax,%eax
f0102f40:	75 1c                	jne    f0102f5e <region_alloc+0x4e>
	panic("Fail to alloc a page right now in region_alloc");
f0102f42:	c7 44 24 08 4c 60 10 	movl   $0xf010604c,0x8(%esp)
f0102f49:	f0 
f0102f4a:	c7 44 24 04 33 01 00 	movl   $0x133,0x4(%esp)
f0102f51:	00 
f0102f52:	c7 04 24 b2 60 10 f0 	movl   $0xf01060b2,(%esp)
f0102f59:	e8 58 d1 ff ff       	call   f01000b6 <_panic>
	
	if(page_insert(e->env_pgdir,p,(void *)startadd,PTE_U|PTE_W)==-E_NO_MEM)
f0102f5e:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0102f65:	00 
f0102f66:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0102f6a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102f6e:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102f71:	89 04 24             	mov    %eax,(%esp)
f0102f74:	e8 14 e2 ff ff       	call   f010118d <page_insert>
f0102f79:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0102f7c:	75 1c                	jne    f0102f9a <region_alloc+0x8a>
	panic("page insert failed");
f0102f7e:	c7 44 24 08 bd 60 10 	movl   $0xf01060bd,0x8(%esp)
f0102f85:	f0 
f0102f86:	c7 44 24 04 36 01 00 	movl   $0x136,0x4(%esp)
f0102f8d:	00 
f0102f8e:	c7 04 24 b2 60 10 f0 	movl   $0xf01060b2,(%esp)
f0102f95:	e8 1c d1 ff ff       	call   f01000b6 <_panic>
	
	startadd+=PGSIZE;
f0102f9a:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	//   (Watch out for corner-cases!)
	
	uint32_t startadd=(uint32_t)ROUNDDOWN(va,PGSIZE);
	uint32_t endadd=(uint32_t)ROUNDUP(va+len,PGSIZE);
	
	while(startadd<endadd)
f0102fa0:	39 f3                	cmp    %esi,%ebx
f0102fa2:	72 8e                	jb     f0102f32 <region_alloc+0x22>
	
	startadd+=PGSIZE;
		
	}
	
}
f0102fa4:	83 c4 1c             	add    $0x1c,%esp
f0102fa7:	5b                   	pop    %ebx
f0102fa8:	5e                   	pop    %esi
f0102fa9:	5f                   	pop    %edi
f0102faa:	5d                   	pop    %ebp
f0102fab:	c3                   	ret    

f0102fac <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102fac:	55                   	push   %ebp
f0102fad:	89 e5                	mov    %esp,%ebp
f0102faf:	8b 45 08             	mov    0x8(%ebp),%eax
f0102fb2:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102fb5:	85 c0                	test   %eax,%eax
f0102fb7:	75 11                	jne    f0102fca <envid2env+0x1e>
		*env_store = curenv;
f0102fb9:	a1 e8 d1 17 f0       	mov    0xf017d1e8,%eax
f0102fbe:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102fc1:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102fc3:	b8 00 00 00 00       	mov    $0x0,%eax
f0102fc8:	eb 5e                	jmp    f0103028 <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102fca:	89 c2                	mov    %eax,%edx
f0102fcc:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0102fd2:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0102fd5:	c1 e2 05             	shl    $0x5,%edx
f0102fd8:	03 15 ec d1 17 f0    	add    0xf017d1ec,%edx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102fde:	83 7a 54 00          	cmpl   $0x0,0x54(%edx)
f0102fe2:	74 05                	je     f0102fe9 <envid2env+0x3d>
f0102fe4:	39 42 48             	cmp    %eax,0x48(%edx)
f0102fe7:	74 10                	je     f0102ff9 <envid2env+0x4d>
		*env_store = 0;
f0102fe9:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102fec:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102ff2:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102ff7:	eb 2f                	jmp    f0103028 <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102ff9:	84 c9                	test   %cl,%cl
f0102ffb:	74 21                	je     f010301e <envid2env+0x72>
f0102ffd:	a1 e8 d1 17 f0       	mov    0xf017d1e8,%eax
f0103002:	39 c2                	cmp    %eax,%edx
f0103004:	74 18                	je     f010301e <envid2env+0x72>
f0103006:	8b 40 48             	mov    0x48(%eax),%eax
f0103009:	39 42 4c             	cmp    %eax,0x4c(%edx)
f010300c:	74 10                	je     f010301e <envid2env+0x72>
		*env_store = 0;
f010300e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103011:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103017:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010301c:	eb 0a                	jmp    f0103028 <envid2env+0x7c>
	}

	*env_store = e;
f010301e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103021:	89 10                	mov    %edx,(%eax)
	return 0;
f0103023:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103028:	5d                   	pop    %ebp
f0103029:	c3                   	ret    

f010302a <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f010302a:	55                   	push   %ebp
f010302b:	89 e5                	mov    %esp,%ebp
}

static inline void
lgdt(void *p)
{
	asm volatile("lgdt (%0)" : : "r" (p));
f010302d:	b8 00 b3 11 f0       	mov    $0xf011b300,%eax
f0103032:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f0103035:	b8 23 00 00 00       	mov    $0x23,%eax
f010303a:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f010303c:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f010303e:	b0 10                	mov    $0x10,%al
f0103040:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f0103042:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f0103044:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f0103046:	ea 4d 30 10 f0 08 00 	ljmp   $0x8,$0xf010304d
}

static inline void
lldt(uint16_t sel)
{
	asm volatile("lldt %0" : : "r" (sel));
f010304d:	b0 00                	mov    $0x0,%al
f010304f:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0103052:	5d                   	pop    %ebp
f0103053:	c3                   	ret    

f0103054 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0103054:	55                   	push   %ebp
f0103055:	89 e5                	mov    %esp,%ebp
f0103057:	56                   	push   %esi
f0103058:	53                   	push   %ebx
	// LAB 3: Your code here.
	
	env_free_list = 0;
	
	for (int i = NENV - 1 ; i >= 0; i--){
		envs[i].env_link = env_free_list;
f0103059:	8b 35 ec d1 17 f0    	mov    0xf017d1ec,%esi
f010305f:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f0103065:	ba 00 04 00 00       	mov    $0x400,%edx
f010306a:	b9 00 00 00 00       	mov    $0x0,%ecx
f010306f:	89 c3                	mov    %eax,%ebx
f0103071:	89 48 44             	mov    %ecx,0x44(%eax)
		envs[i].env_status = ENV_FREE;
f0103074:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
f010307b:	83 e8 60             	sub    $0x60,%eax
	// Set up envs array
	// LAB 3: Your code here.
	
	env_free_list = 0;
	
	for (int i = NENV - 1 ; i >= 0; i--){
f010307e:	83 ea 01             	sub    $0x1,%edx
f0103081:	74 04                	je     f0103087 <env_init+0x33>
		envs[i].env_link = env_free_list;
		envs[i].env_status = ENV_FREE;
		env_free_list = &envs[i];
f0103083:	89 d9                	mov    %ebx,%ecx
f0103085:	eb e8                	jmp    f010306f <env_init+0x1b>
f0103087:	89 35 f0 d1 17 f0    	mov    %esi,0xf017d1f0
	}
	// Per-CPU part of the initialization
	env_init_percpu();
f010308d:	e8 98 ff ff ff       	call   f010302a <env_init_percpu>
	
	
}
f0103092:	5b                   	pop    %ebx
f0103093:	5e                   	pop    %esi
f0103094:	5d                   	pop    %ebp
f0103095:	c3                   	ret    

f0103096 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0103096:	55                   	push   %ebp
f0103097:	89 e5                	mov    %esp,%ebp
f0103099:	53                   	push   %ebx
f010309a:	83 ec 14             	sub    $0x14,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f010309d:	8b 1d f0 d1 17 f0    	mov    0xf017d1f0,%ebx
f01030a3:	85 db                	test   %ebx,%ebx
f01030a5:	0f 84 8b 01 00 00    	je     f0103236 <env_alloc+0x1a0>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f01030ab:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01030b2:	e8 be dd ff ff       	call   f0100e75 <page_alloc>
f01030b7:	85 c0                	test   %eax,%eax
f01030b9:	0f 84 7e 01 00 00    	je     f010323d <env_alloc+0x1a7>
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	
	p->pp_ref++;
f01030bf:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
f01030c4:	2b 05 ac de 17 f0    	sub    0xf017deac,%eax
f01030ca:	c1 f8 03             	sar    $0x3,%eax
f01030cd:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01030d0:	89 c2                	mov    %eax,%edx
f01030d2:	c1 ea 0c             	shr    $0xc,%edx
f01030d5:	3b 15 a4 de 17 f0    	cmp    0xf017dea4,%edx
f01030db:	72 20                	jb     f01030fd <env_alloc+0x67>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01030dd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01030e1:	c7 44 24 08 8c 58 10 	movl   $0xf010588c,0x8(%esp)
f01030e8:	f0 
f01030e9:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01030f0:	00 
f01030f1:	c7 04 24 a0 55 10 f0 	movl   $0xf01055a0,(%esp)
f01030f8:	e8 b9 cf ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f01030fd:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0103102:	89 43 5c             	mov    %eax,0x5c(%ebx)
	
	// set e->env_pgdir and initialize the page directory.
	e->env_pgdir = (pde_t *) page2kva(p);
	
	for (i = 0; i < PDX(UTOP); i++)
f0103105:	b8 00 00 00 00       	mov    $0x0,%eax
f010310a:	ba 00 00 00 00       	mov    $0x0,%edx
		e->env_pgdir[i] = 0;
f010310f:	8b 4b 5c             	mov    0x5c(%ebx),%ecx
f0103112:	c7 04 91 00 00 00 00 	movl   $0x0,(%ecx,%edx,4)
	p->pp_ref++;
	
	// set e->env_pgdir and initialize the page directory.
	e->env_pgdir = (pde_t *) page2kva(p);
	
	for (i = 0; i < PDX(UTOP); i++)
f0103119:	83 c0 01             	add    $0x1,%eax
f010311c:	89 c2                	mov    %eax,%edx
f010311e:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0103123:	75 ea                	jne    f010310f <env_alloc+0x79>
f0103125:	66 b8 ec 0e          	mov    $0xeec,%ax
		e->env_pgdir[i] = 0;

	for (i = PDX(UTOP); i < NPDENTRIES; i++)
		e->env_pgdir[i] = kern_pgdir[i];	
f0103129:	8b 15 a8 de 17 f0    	mov    0xf017dea8,%edx
f010312f:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f0103132:	8b 53 5c             	mov    0x5c(%ebx),%edx
f0103135:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f0103138:	83 c0 04             	add    $0x4,%eax
	e->env_pgdir = (pde_t *) page2kva(p);
	
	for (i = 0; i < PDX(UTOP); i++)
		e->env_pgdir[i] = 0;

	for (i = PDX(UTOP); i < NPDENTRIES; i++)
f010313b:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0103140:	75 e7                	jne    f0103129 <env_alloc+0x93>
		
	
	
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0103142:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103145:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010314a:	77 20                	ja     f010316c <env_alloc+0xd6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010314c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103150:	c7 44 24 08 74 59 10 	movl   $0xf0105974,0x8(%esp)
f0103157:	f0 
f0103158:	c7 44 24 04 d5 00 00 	movl   $0xd5,0x4(%esp)
f010315f:	00 
f0103160:	c7 04 24 b2 60 10 f0 	movl   $0xf01060b2,(%esp)
f0103167:	e8 4a cf ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010316c:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0103172:	83 ca 05             	or     $0x5,%edx
f0103175:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f010317b:	8b 43 48             	mov    0x48(%ebx),%eax
f010317e:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0103183:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0103188:	ba 00 10 00 00       	mov    $0x1000,%edx
f010318d:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0103190:	89 da                	mov    %ebx,%edx
f0103192:	2b 15 ec d1 17 f0    	sub    0xf017d1ec,%edx
f0103198:	c1 fa 05             	sar    $0x5,%edx
f010319b:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01031a1:	09 d0                	or     %edx,%eax
f01031a3:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f01031a6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01031a9:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f01031ac:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f01031b3:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f01031ba:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f01031c1:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f01031c8:	00 
f01031c9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01031d0:	00 
f01031d1:	89 1c 24             	mov    %ebx,(%esp)
f01031d4:	e8 ee 19 00 00       	call   f0104bc7 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f01031d9:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f01031df:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f01031e5:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f01031eb:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f01031f2:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f01031f8:	8b 43 44             	mov    0x44(%ebx),%eax
f01031fb:	a3 f0 d1 17 f0       	mov    %eax,0xf017d1f0
	*newenv_store = e;
f0103200:	8b 45 08             	mov    0x8(%ebp),%eax
f0103203:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103205:	8b 53 48             	mov    0x48(%ebx),%edx
f0103208:	a1 e8 d1 17 f0       	mov    0xf017d1e8,%eax
f010320d:	85 c0                	test   %eax,%eax
f010320f:	74 05                	je     f0103216 <env_alloc+0x180>
f0103211:	8b 40 48             	mov    0x48(%eax),%eax
f0103214:	eb 05                	jmp    f010321b <env_alloc+0x185>
f0103216:	b8 00 00 00 00       	mov    $0x0,%eax
f010321b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010321f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103223:	c7 04 24 d0 60 10 f0 	movl   $0xf01060d0,(%esp)
f010322a:	e8 bf 04 00 00       	call   f01036ee <cprintf>
	return 0;
f010322f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103234:	eb 0c                	jmp    f0103242 <env_alloc+0x1ac>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0103236:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f010323b:	eb 05                	jmp    f0103242 <env_alloc+0x1ac>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f010323d:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0103242:	83 c4 14             	add    $0x14,%esp
f0103245:	5b                   	pop    %ebx
f0103246:	5d                   	pop    %ebp
f0103247:	c3                   	ret    

f0103248 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0103248:	55                   	push   %ebp
f0103249:	89 e5                	mov    %esp,%ebp
f010324b:	57                   	push   %edi
f010324c:	56                   	push   %esi
f010324d:	53                   	push   %ebx
f010324e:	83 ec 3c             	sub    $0x3c,%esp
f0103251:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	
	struct Env *env;
	
	int check;
	check = env_alloc(&env, 0);
f0103254:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010325b:	00 
f010325c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010325f:	89 04 24             	mov    %eax,(%esp)
f0103262:	e8 2f fe ff ff       	call   f0103096 <env_alloc>
	
	if (check < 0) {
f0103267:	85 c0                	test   %eax,%eax
f0103269:	79 20                	jns    f010328b <env_create+0x43>
		panic("env_alloc: %e", check);
f010326b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010326f:	c7 44 24 08 e5 60 10 	movl   $0xf01060e5,0x8(%esp)
f0103276:	f0 
f0103277:	c7 44 24 04 bb 01 00 	movl   $0x1bb,0x4(%esp)
f010327e:	00 
f010327f:	c7 04 24 b2 60 10 f0 	movl   $0xf01060b2,(%esp)
f0103286:	e8 2b ce ff ff       	call   f01000b6 <_panic>
		return;
	}
	
	load_icode(env, binary);
f010328b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010328e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// LAB 3: Your code here.
	
		// read 1st page off disk
	//readseg((uint32_t) ELFHDR, SECTSIZE*8, 0);
	
	lcr3(PADDR(e->env_pgdir));
f0103291:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103294:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103299:	77 20                	ja     f01032bb <env_create+0x73>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010329b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010329f:	c7 44 24 08 74 59 10 	movl   $0xf0105974,0x8(%esp)
f01032a6:	f0 
f01032a7:	c7 44 24 04 7e 01 00 	movl   $0x17e,0x4(%esp)
f01032ae:	00 
f01032af:	c7 04 24 b2 60 10 f0 	movl   $0xf01060b2,(%esp)
f01032b6:	e8 fb cd ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01032bb:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01032c0:	0f 22 d8             	mov    %eax,%cr3
	struct Proghdr *ph, *eph;
	struct Elf * ELFHDR=(struct Elf *) binary;
	// is this a valid ELF?
	
	if (ELFHDR->e_magic != ELF_MAGIC)
f01032c3:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f01032c9:	74 1c                	je     f01032e7 <env_create+0x9f>
		panic("Not an elf file \n");
f01032cb:	c7 44 24 08 f3 60 10 	movl   $0xf01060f3,0x8(%esp)
f01032d2:	f0 
f01032d3:	c7 44 24 04 84 01 00 	movl   $0x184,0x4(%esp)
f01032da:	00 
f01032db:	c7 04 24 b2 60 10 f0 	movl   $0xf01060b2,(%esp)
f01032e2:	e8 cf cd ff ff       	call   f01000b6 <_panic>

	// load each program segment (ignores ph flags)
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
f01032e7:	89 fb                	mov    %edi,%ebx
f01032e9:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + ELFHDR->e_phnum;
f01032ec:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f01032f0:	c1 e6 05             	shl    $0x5,%esi
f01032f3:	01 de                	add    %ebx,%esi
	 
	e->env_tf.tf_eip = ELFHDR->e_entry;
f01032f5:	8b 47 18             	mov    0x18(%edi),%eax
f01032f8:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01032fb:	89 41 30             	mov    %eax,0x30(%ecx)
f01032fe:	eb 71                	jmp    f0103371 <env_create+0x129>
	
	
	for (; ph < eph; ph++)
{		
	
	if (ph->p_type != ELF_PROG_LOAD) 
f0103300:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103303:	75 69                	jne    f010336e <env_create+0x126>
	continue;
	
	if (ph->p_filesz > ph->p_memsz)
f0103305:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0103308:	39 4b 10             	cmp    %ecx,0x10(%ebx)
f010330b:	76 1c                	jbe    f0103329 <env_create+0xe1>
	panic("file size greater \n");
f010330d:	c7 44 24 08 05 61 10 	movl   $0xf0106105,0x8(%esp)
f0103314:	f0 
f0103315:	c7 44 24 04 96 01 00 	movl   $0x196,0x4(%esp)
f010331c:	00 
f010331d:	c7 04 24 b2 60 10 f0 	movl   $0xf01060b2,(%esp)
f0103324:	e8 8d cd ff ff       	call   f01000b6 <_panic>
	
	region_alloc(e, (void *) ph->p_va, ph->p_memsz);
f0103329:	8b 53 08             	mov    0x8(%ebx),%edx
f010332c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010332f:	e8 dc fb ff ff       	call   f0102f10 <region_alloc>
	
	memcpy((void *) ph->p_va, binary+ph->p_offset, ph->p_filesz);
f0103334:	8b 43 10             	mov    0x10(%ebx),%eax
f0103337:	89 44 24 08          	mov    %eax,0x8(%esp)
f010333b:	89 f8                	mov    %edi,%eax
f010333d:	03 43 04             	add    0x4(%ebx),%eax
f0103340:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103344:	8b 43 08             	mov    0x8(%ebx),%eax
f0103347:	89 04 24             	mov    %eax,(%esp)
f010334a:	e8 2d 19 00 00       	call   f0104c7c <memcpy>
	
	memset((void *) ph->p_va + ph->p_filesz, 0, (ph->p_memsz - ph->p_filesz));
f010334f:	8b 43 10             	mov    0x10(%ebx),%eax
f0103352:	8b 53 14             	mov    0x14(%ebx),%edx
f0103355:	29 c2                	sub    %eax,%edx
f0103357:	89 54 24 08          	mov    %edx,0x8(%esp)
f010335b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103362:	00 
f0103363:	03 43 08             	add    0x8(%ebx),%eax
f0103366:	89 04 24             	mov    %eax,(%esp)
f0103369:	e8 59 18 00 00       	call   f0104bc7 <memset>
	e->env_tf.tf_eip = ELFHDR->e_entry;

	
	
	
	for (; ph < eph; ph++)
f010336e:	83 c3 20             	add    $0x20,%ebx
f0103371:	39 de                	cmp    %ebx,%esi
f0103373:	77 8b                	ja     f0103300 <env_create+0xb8>
	
	memset((void *) ph->p_va + ph->p_filesz, 0, (ph->p_memsz - ph->p_filesz));
	
}
	
   	region_alloc(e, (void *) USTACKTOP - PGSIZE, PGSIZE);
f0103375:	b9 00 10 00 00       	mov    $0x1000,%ecx
f010337a:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f010337f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103382:	e8 89 fb ff ff       	call   f0102f10 <region_alloc>

	lcr3(PADDR(kern_pgdir));
f0103387:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010338c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103391:	77 20                	ja     f01033b3 <env_create+0x16b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103393:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103397:	c7 44 24 08 74 59 10 	movl   $0xf0105974,0x8(%esp)
f010339e:	f0 
f010339f:	c7 44 24 04 a2 01 00 	movl   $0x1a2,0x4(%esp)
f01033a6:	00 
f01033a7:	c7 04 24 b2 60 10 f0 	movl   $0xf01060b2,(%esp)
f01033ae:	e8 03 cd ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01033b3:	05 00 00 00 10       	add    $0x10000000,%eax
f01033b8:	0f 22 d8             	mov    %eax,%cr3
		panic("env_alloc: %e", check);
		return;
	}
	
	load_icode(env, binary);
	env->env_type = type;
f01033bb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01033be:	8b 55 0c             	mov    0xc(%ebp),%edx
f01033c1:	89 50 50             	mov    %edx,0x50(%eax)
}
f01033c4:	83 c4 3c             	add    $0x3c,%esp
f01033c7:	5b                   	pop    %ebx
f01033c8:	5e                   	pop    %esi
f01033c9:	5f                   	pop    %edi
f01033ca:	5d                   	pop    %ebp
f01033cb:	c3                   	ret    

f01033cc <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01033cc:	55                   	push   %ebp
f01033cd:	89 e5                	mov    %esp,%ebp
f01033cf:	57                   	push   %edi
f01033d0:	56                   	push   %esi
f01033d1:	53                   	push   %ebx
f01033d2:	83 ec 2c             	sub    $0x2c,%esp
f01033d5:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01033d8:	a1 e8 d1 17 f0       	mov    0xf017d1e8,%eax
f01033dd:	39 c7                	cmp    %eax,%edi
f01033df:	75 37                	jne    f0103418 <env_free+0x4c>
		lcr3(PADDR(kern_pgdir));
f01033e1:	8b 15 a8 de 17 f0    	mov    0xf017dea8,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01033e7:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f01033ed:	77 20                	ja     f010340f <env_free+0x43>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01033ef:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01033f3:	c7 44 24 08 74 59 10 	movl   $0xf0105974,0x8(%esp)
f01033fa:	f0 
f01033fb:	c7 44 24 04 d1 01 00 	movl   $0x1d1,0x4(%esp)
f0103402:	00 
f0103403:	c7 04 24 b2 60 10 f0 	movl   $0xf01060b2,(%esp)
f010340a:	e8 a7 cc ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010340f:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0103415:	0f 22 da             	mov    %edx,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103418:	8b 57 48             	mov    0x48(%edi),%edx
f010341b:	85 c0                	test   %eax,%eax
f010341d:	74 05                	je     f0103424 <env_free+0x58>
f010341f:	8b 40 48             	mov    0x48(%eax),%eax
f0103422:	eb 05                	jmp    f0103429 <env_free+0x5d>
f0103424:	b8 00 00 00 00       	mov    $0x0,%eax
f0103429:	89 54 24 08          	mov    %edx,0x8(%esp)
f010342d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103431:	c7 04 24 19 61 10 f0 	movl   $0xf0106119,(%esp)
f0103438:	e8 b1 02 00 00       	call   f01036ee <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f010343d:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103444:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103447:	89 c8                	mov    %ecx,%eax
f0103449:	c1 e0 02             	shl    $0x2,%eax
f010344c:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f010344f:	8b 47 5c             	mov    0x5c(%edi),%eax
f0103452:	8b 34 88             	mov    (%eax,%ecx,4),%esi
f0103455:	f7 c6 01 00 00 00    	test   $0x1,%esi
f010345b:	0f 84 b7 00 00 00    	je     f0103518 <env_free+0x14c>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103461:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103467:	89 f0                	mov    %esi,%eax
f0103469:	c1 e8 0c             	shr    $0xc,%eax
f010346c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010346f:	3b 05 a4 de 17 f0    	cmp    0xf017dea4,%eax
f0103475:	72 20                	jb     f0103497 <env_free+0xcb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103477:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010347b:	c7 44 24 08 8c 58 10 	movl   $0xf010588c,0x8(%esp)
f0103482:	f0 
f0103483:	c7 44 24 04 e0 01 00 	movl   $0x1e0,0x4(%esp)
f010348a:	00 
f010348b:	c7 04 24 b2 60 10 f0 	movl   $0xf01060b2,(%esp)
f0103492:	e8 1f cc ff ff       	call   f01000b6 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103497:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010349a:	c1 e0 16             	shl    $0x16,%eax
f010349d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01034a0:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f01034a5:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f01034ac:	01 
f01034ad:	74 17                	je     f01034c6 <env_free+0xfa>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01034af:	89 d8                	mov    %ebx,%eax
f01034b1:	c1 e0 0c             	shl    $0xc,%eax
f01034b4:	0b 45 e4             	or     -0x1c(%ebp),%eax
f01034b7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01034bb:	8b 47 5c             	mov    0x5c(%edi),%eax
f01034be:	89 04 24             	mov    %eax,(%esp)
f01034c1:	e8 82 dc ff ff       	call   f0101148 <page_remove>
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01034c6:	83 c3 01             	add    $0x1,%ebx
f01034c9:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f01034cf:	75 d4                	jne    f01034a5 <env_free+0xd9>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f01034d1:	8b 47 5c             	mov    0x5c(%edi),%eax
f01034d4:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01034d7:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01034de:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01034e1:	3b 05 a4 de 17 f0    	cmp    0xf017dea4,%eax
f01034e7:	72 1c                	jb     f0103505 <env_free+0x139>
		panic("pa2page called with invalid pa");
f01034e9:	c7 44 24 08 98 59 10 	movl   $0xf0105998,0x8(%esp)
f01034f0:	f0 
f01034f1:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f01034f8:	00 
f01034f9:	c7 04 24 a0 55 10 f0 	movl   $0xf01055a0,(%esp)
f0103500:	e8 b1 cb ff ff       	call   f01000b6 <_panic>
	return &pages[PGNUM(pa)];
f0103505:	a1 ac de 17 f0       	mov    0xf017deac,%eax
f010350a:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010350d:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		page_decref(pa2page(pa));
f0103510:	89 04 24             	mov    %eax,(%esp)
f0103513:	e8 25 da ff ff       	call   f0100f3d <page_decref>
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103518:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f010351c:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f0103523:	0f 85 1b ff ff ff    	jne    f0103444 <env_free+0x78>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103529:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010352c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103531:	77 20                	ja     f0103553 <env_free+0x187>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103533:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103537:	c7 44 24 08 74 59 10 	movl   $0xf0105974,0x8(%esp)
f010353e:	f0 
f010353f:	c7 44 24 04 ee 01 00 	movl   $0x1ee,0x4(%esp)
f0103546:	00 
f0103547:	c7 04 24 b2 60 10 f0 	movl   $0xf01060b2,(%esp)
f010354e:	e8 63 cb ff ff       	call   f01000b6 <_panic>
	e->env_pgdir = 0;
f0103553:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
	return (physaddr_t)kva - KERNBASE;
f010355a:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010355f:	c1 e8 0c             	shr    $0xc,%eax
f0103562:	3b 05 a4 de 17 f0    	cmp    0xf017dea4,%eax
f0103568:	72 1c                	jb     f0103586 <env_free+0x1ba>
		panic("pa2page called with invalid pa");
f010356a:	c7 44 24 08 98 59 10 	movl   $0xf0105998,0x8(%esp)
f0103571:	f0 
f0103572:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0103579:	00 
f010357a:	c7 04 24 a0 55 10 f0 	movl   $0xf01055a0,(%esp)
f0103581:	e8 30 cb ff ff       	call   f01000b6 <_panic>
	return &pages[PGNUM(pa)];
f0103586:	8b 15 ac de 17 f0    	mov    0xf017deac,%edx
f010358c:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	page_decref(pa2page(pa));
f010358f:	89 04 24             	mov    %eax,(%esp)
f0103592:	e8 a6 d9 ff ff       	call   f0100f3d <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103597:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f010359e:	a1 f0 d1 17 f0       	mov    0xf017d1f0,%eax
f01035a3:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f01035a6:	89 3d f0 d1 17 f0    	mov    %edi,0xf017d1f0
}
f01035ac:	83 c4 2c             	add    $0x2c,%esp
f01035af:	5b                   	pop    %ebx
f01035b0:	5e                   	pop    %esi
f01035b1:	5f                   	pop    %edi
f01035b2:	5d                   	pop    %ebp
f01035b3:	c3                   	ret    

f01035b4 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f01035b4:	55                   	push   %ebp
f01035b5:	89 e5                	mov    %esp,%ebp
f01035b7:	83 ec 18             	sub    $0x18,%esp
	env_free(e);
f01035ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01035bd:	89 04 24             	mov    %eax,(%esp)
f01035c0:	e8 07 fe ff ff       	call   f01033cc <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f01035c5:	c7 04 24 7c 60 10 f0 	movl   $0xf010607c,(%esp)
f01035cc:	e8 1d 01 00 00       	call   f01036ee <cprintf>
	while (1)
		monitor(NULL);
f01035d1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01035d8:	e8 3e d2 ff ff       	call   f010081b <monitor>
f01035dd:	eb f2                	jmp    f01035d1 <env_destroy+0x1d>

f01035df <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01035df:	55                   	push   %ebp
f01035e0:	89 e5                	mov    %esp,%ebp
f01035e2:	83 ec 18             	sub    $0x18,%esp
	asm volatile(
f01035e5:	8b 65 08             	mov    0x8(%ebp),%esp
f01035e8:	61                   	popa   
f01035e9:	07                   	pop    %es
f01035ea:	1f                   	pop    %ds
f01035eb:	83 c4 08             	add    $0x8,%esp
f01035ee:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f01035ef:	c7 44 24 08 2f 61 10 	movl   $0xf010612f,0x8(%esp)
f01035f6:	f0 
f01035f7:	c7 44 24 04 17 02 00 	movl   $0x217,0x4(%esp)
f01035fe:	00 
f01035ff:	c7 04 24 b2 60 10 f0 	movl   $0xf01060b2,(%esp)
f0103606:	e8 ab ca ff ff       	call   f01000b6 <_panic>

f010360b <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f010360b:	55                   	push   %ebp
f010360c:	89 e5                	mov    %esp,%ebp
f010360e:	83 ec 18             	sub    $0x18,%esp
f0103611:	8b 45 08             	mov    0x8(%ebp),%eax
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	// env_status : ENV_FREE, ENV_RUNNABLE, ENV_RUNNING, ENV_NOT_RUNNABLE

	if (curenv == NULL || curenv!= e) 
f0103614:	8b 15 e8 d1 17 f0    	mov    0xf017d1e8,%edx
f010361a:	85 d2                	test   %edx,%edx
f010361c:	74 11                	je     f010362f <env_run+0x24>
f010361e:	39 c2                	cmp    %eax,%edx
f0103620:	74 4f                	je     f0103671 <env_run+0x66>
	{
		if (curenv && curenv->env_status == ENV_RUNNING)
f0103622:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f0103626:	75 07                	jne    f010362f <env_run+0x24>
			
			curenv->env_status = ENV_RUNNABLE;
f0103628:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
		curenv = e;
f010362f:	a3 e8 d1 17 f0       	mov    %eax,0xf017d1e8
	
		curenv->env_status = ENV_RUNNING;
f0103634:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
		curenv->env_runs++;
f010363b:	83 40 58 01          	addl   $0x1,0x58(%eax)
		lcr3(PADDR(curenv->env_pgdir));
f010363f:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103642:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103647:	77 20                	ja     f0103669 <env_run+0x5e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103649:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010364d:	c7 44 24 08 74 59 10 	movl   $0xf0105974,0x8(%esp)
f0103654:	f0 
f0103655:	c7 44 24 04 40 02 00 	movl   $0x240,0x4(%esp)
f010365c:	00 
f010365d:	c7 04 24 b2 60 10 f0 	movl   $0xf01060b2,(%esp)
f0103664:	e8 4d ca ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103669:	05 00 00 00 10       	add    $0x10000000,%eax
f010366e:	0f 22 d8             	mov    %eax,%cr3
	}

	

	
	env_pop_tf(&(curenv->env_tf));
f0103671:	a1 e8 d1 17 f0       	mov    0xf017d1e8,%eax
f0103676:	89 04 24             	mov    %eax,(%esp)
f0103679:	e8 61 ff ff ff       	call   f01035df <env_pop_tf>

f010367e <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f010367e:	55                   	push   %ebp
f010367f:	89 e5                	mov    %esp,%ebp
f0103681:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103685:	ba 70 00 00 00       	mov    $0x70,%edx
f010368a:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010368b:	b2 71                	mov    $0x71,%dl
f010368d:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f010368e:	0f b6 c0             	movzbl %al,%eax
}
f0103691:	5d                   	pop    %ebp
f0103692:	c3                   	ret    

f0103693 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103693:	55                   	push   %ebp
f0103694:	89 e5                	mov    %esp,%ebp
f0103696:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010369a:	ba 70 00 00 00       	mov    $0x70,%edx
f010369f:	ee                   	out    %al,(%dx)
f01036a0:	b2 71                	mov    $0x71,%dl
f01036a2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01036a5:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01036a6:	5d                   	pop    %ebp
f01036a7:	c3                   	ret    

f01036a8 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01036a8:	55                   	push   %ebp
f01036a9:	89 e5                	mov    %esp,%ebp
f01036ab:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01036ae:	8b 45 08             	mov    0x8(%ebp),%eax
f01036b1:	89 04 24             	mov    %eax,(%esp)
f01036b4:	e8 68 cf ff ff       	call   f0100621 <cputchar>
	*cnt++;
}
f01036b9:	c9                   	leave  
f01036ba:	c3                   	ret    

f01036bb <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01036bb:	55                   	push   %ebp
f01036bc:	89 e5                	mov    %esp,%ebp
f01036be:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01036c1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01036c8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01036cb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01036cf:	8b 45 08             	mov    0x8(%ebp),%eax
f01036d2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01036d6:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01036d9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036dd:	c7 04 24 a8 36 10 f0 	movl   $0xf01036a8,(%esp)
f01036e4:	e8 25 0e 00 00       	call   f010450e <vprintfmt>
	return cnt;
}
f01036e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01036ec:	c9                   	leave  
f01036ed:	c3                   	ret    

f01036ee <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01036ee:	55                   	push   %ebp
f01036ef:	89 e5                	mov    %esp,%ebp
f01036f1:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01036f4:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01036f7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036fb:	8b 45 08             	mov    0x8(%ebp),%eax
f01036fe:	89 04 24             	mov    %eax,(%esp)
f0103701:	e8 b5 ff ff ff       	call   f01036bb <vcprintf>
	va_end(ap);

	return cnt;
}
f0103706:	c9                   	leave  
f0103707:	c3                   	ret    
f0103708:	66 90                	xchg   %ax,%ax
f010370a:	66 90                	xchg   %ax,%ax
f010370c:	66 90                	xchg   %ax,%ax
f010370e:	66 90                	xchg   %ax,%ax

f0103710 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103710:	55                   	push   %ebp
f0103711:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0103713:	c7 05 24 da 17 f0 00 	movl   $0xf0000000,0xf017da24
f010371a:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f010371d:	66 c7 05 28 da 17 f0 	movw   $0x10,0xf017da28
f0103724:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0103726:	66 c7 05 48 b3 11 f0 	movw   $0x67,0xf011b348
f010372d:	67 00 
f010372f:	b8 20 da 17 f0       	mov    $0xf017da20,%eax
f0103734:	66 a3 4a b3 11 f0    	mov    %ax,0xf011b34a
f010373a:	89 c2                	mov    %eax,%edx
f010373c:	c1 ea 10             	shr    $0x10,%edx
f010373f:	88 15 4c b3 11 f0    	mov    %dl,0xf011b34c
f0103745:	c6 05 4e b3 11 f0 40 	movb   $0x40,0xf011b34e
f010374c:	c1 e8 18             	shr    $0x18,%eax
f010374f:	a2 4f b3 11 f0       	mov    %al,0xf011b34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0103754:	c6 05 4d b3 11 f0 89 	movb   $0x89,0xf011b34d
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f010375b:	b8 28 00 00 00       	mov    $0x28,%eax
f0103760:	0f 00 d8             	ltr    %ax
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f0103763:	b8 50 b3 11 f0       	mov    $0xf011b350,%eax
f0103768:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f010376b:	5d                   	pop    %ebp
f010376c:	c3                   	ret    

f010376d <trap_init>:
}


void
trap_init(void)
{
f010376d:	55                   	push   %ebp
f010376e:	89 e5                	mov    %esp,%ebp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.
	SETGATE(idt[T_DIVIDE],0,GD_KT,divide_zero,DPLKERN);    //CSS=kernel text
f0103770:	b8 a2 3e 10 f0       	mov    $0xf0103ea2,%eax
f0103775:	66 a3 00 d2 17 f0    	mov    %ax,0xf017d200
f010377b:	66 c7 05 02 d2 17 f0 	movw   $0x8,0xf017d202
f0103782:	08 00 
f0103784:	c6 05 04 d2 17 f0 00 	movb   $0x0,0xf017d204
f010378b:	c6 05 05 d2 17 f0 8e 	movb   $0x8e,0xf017d205
f0103792:	c1 e8 10             	shr    $0x10,%eax
f0103795:	66 a3 06 d2 17 f0    	mov    %ax,0xf017d206
    SETGATE(idt[T_BRKPT],0,GD_KT,brkpoint,DPLUSR);
f010379b:	b8 ac 3e 10 f0       	mov    $0xf0103eac,%eax
f01037a0:	66 a3 18 d2 17 f0    	mov    %ax,0xf017d218
f01037a6:	66 c7 05 1a d2 17 f0 	movw   $0x8,0xf017d21a
f01037ad:	08 00 
f01037af:	c6 05 1c d2 17 f0 00 	movb   $0x0,0xf017d21c
f01037b6:	c6 05 1d d2 17 f0 ee 	movb   $0xee,0xf017d21d
f01037bd:	c1 e8 10             	shr    $0x10,%eax
f01037c0:	66 a3 1e d2 17 f0    	mov    %ax,0xf017d21e
    SETGATE(idt[T_SEGNP],0,GD_KT,no_seg,DPLKERN);
f01037c6:	b8 b6 3e 10 f0       	mov    $0xf0103eb6,%eax
f01037cb:	66 a3 58 d2 17 f0    	mov    %ax,0xf017d258
f01037d1:	66 c7 05 5a d2 17 f0 	movw   $0x8,0xf017d25a
f01037d8:	08 00 
f01037da:	c6 05 5c d2 17 f0 00 	movb   $0x0,0xf017d25c
f01037e1:	c6 05 5d d2 17 f0 8e 	movb   $0x8e,0xf017d25d
f01037e8:	c1 e8 10             	shr    $0x10,%eax
f01037eb:	66 a3 5e d2 17 f0    	mov    %ax,0xf017d25e
    SETGATE(idt[T_DEBUG],0,GD_KT,debug,DPLKERN);
f01037f1:	b8 be 3e 10 f0       	mov    $0xf0103ebe,%eax
f01037f6:	66 a3 08 d2 17 f0    	mov    %ax,0xf017d208
f01037fc:	66 c7 05 0a d2 17 f0 	movw   $0x8,0xf017d20a
f0103803:	08 00 
f0103805:	c6 05 0c d2 17 f0 00 	movb   $0x0,0xf017d20c
f010380c:	c6 05 0d d2 17 f0 8e 	movb   $0x8e,0xf017d20d
f0103813:	c1 e8 10             	shr    $0x10,%eax
f0103816:	66 a3 0e d2 17 f0    	mov    %ax,0xf017d20e
    SETGATE(idt[T_NMI],0,GD_KT,nmi,DPLKERN);
f010381c:	b8 c8 3e 10 f0       	mov    $0xf0103ec8,%eax
f0103821:	66 a3 10 d2 17 f0    	mov    %ax,0xf017d210
f0103827:	66 c7 05 12 d2 17 f0 	movw   $0x8,0xf017d212
f010382e:	08 00 
f0103830:	c6 05 14 d2 17 f0 00 	movb   $0x0,0xf017d214
f0103837:	c6 05 15 d2 17 f0 8e 	movb   $0x8e,0xf017d215
f010383e:	c1 e8 10             	shr    $0x10,%eax
f0103841:	66 a3 16 d2 17 f0    	mov    %ax,0xf017d216
    SETGATE(idt[T_OFLOW],0,GD_KT,oflow,DPLKERN);
f0103847:	b8 d2 3e 10 f0       	mov    $0xf0103ed2,%eax
f010384c:	66 a3 20 d2 17 f0    	mov    %ax,0xf017d220
f0103852:	66 c7 05 22 d2 17 f0 	movw   $0x8,0xf017d222
f0103859:	08 00 
f010385b:	c6 05 24 d2 17 f0 00 	movb   $0x0,0xf017d224
f0103862:	c6 05 25 d2 17 f0 8e 	movb   $0x8e,0xf017d225
f0103869:	c1 e8 10             	shr    $0x10,%eax
f010386c:	66 a3 26 d2 17 f0    	mov    %ax,0xf017d226
    SETGATE(idt[T_BOUND],0,GD_KT,bound,DPLKERN);
f0103872:	b8 dc 3e 10 f0       	mov    $0xf0103edc,%eax
f0103877:	66 a3 28 d2 17 f0    	mov    %ax,0xf017d228
f010387d:	66 c7 05 2a d2 17 f0 	movw   $0x8,0xf017d22a
f0103884:	08 00 
f0103886:	c6 05 2c d2 17 f0 00 	movb   $0x0,0xf017d22c
f010388d:	c6 05 2d d2 17 f0 8e 	movb   $0x8e,0xf017d22d
f0103894:	c1 e8 10             	shr    $0x10,%eax
f0103897:	66 a3 2e d2 17 f0    	mov    %ax,0xf017d22e
    SETGATE(idt[T_ILLOP],0,GD_KT,illop,DPLKERN);
f010389d:	b8 e6 3e 10 f0       	mov    $0xf0103ee6,%eax
f01038a2:	66 a3 30 d2 17 f0    	mov    %ax,0xf017d230
f01038a8:	66 c7 05 32 d2 17 f0 	movw   $0x8,0xf017d232
f01038af:	08 00 
f01038b1:	c6 05 34 d2 17 f0 00 	movb   $0x0,0xf017d234
f01038b8:	c6 05 35 d2 17 f0 8e 	movb   $0x8e,0xf017d235
f01038bf:	c1 e8 10             	shr    $0x10,%eax
f01038c2:	66 a3 36 d2 17 f0    	mov    %ax,0xf017d236
    SETGATE(idt[T_DEVICE],0,GD_KT,device,DPLKERN);
f01038c8:	b8 f0 3e 10 f0       	mov    $0xf0103ef0,%eax
f01038cd:	66 a3 38 d2 17 f0    	mov    %ax,0xf017d238
f01038d3:	66 c7 05 3a d2 17 f0 	movw   $0x8,0xf017d23a
f01038da:	08 00 
f01038dc:	c6 05 3c d2 17 f0 00 	movb   $0x0,0xf017d23c
f01038e3:	c6 05 3d d2 17 f0 8e 	movb   $0x8e,0xf017d23d
f01038ea:	c1 e8 10             	shr    $0x10,%eax
f01038ed:	66 a3 3e d2 17 f0    	mov    %ax,0xf017d23e
    SETGATE(idt[T_DBLFLT],0,GD_KT,dblflt,DPLKERN);
f01038f3:	b8 fa 3e 10 f0       	mov    $0xf0103efa,%eax
f01038f8:	66 a3 40 d2 17 f0    	mov    %ax,0xf017d240
f01038fe:	66 c7 05 42 d2 17 f0 	movw   $0x8,0xf017d242
f0103905:	08 00 
f0103907:	c6 05 44 d2 17 f0 00 	movb   $0x0,0xf017d244
f010390e:	c6 05 45 d2 17 f0 8e 	movb   $0x8e,0xf017d245
f0103915:	c1 e8 10             	shr    $0x10,%eax
f0103918:	66 a3 46 d2 17 f0    	mov    %ax,0xf017d246
    SETGATE(idt[T_TSS], 0, GD_KT, tss, DPLKERN);
f010391e:	b8 02 3f 10 f0       	mov    $0xf0103f02,%eax
f0103923:	66 a3 50 d2 17 f0    	mov    %ax,0xf017d250
f0103929:	66 c7 05 52 d2 17 f0 	movw   $0x8,0xf017d252
f0103930:	08 00 
f0103932:	c6 05 54 d2 17 f0 00 	movb   $0x0,0xf017d254
f0103939:	c6 05 55 d2 17 f0 8e 	movb   $0x8e,0xf017d255
f0103940:	c1 e8 10             	shr    $0x10,%eax
f0103943:	66 a3 56 d2 17 f0    	mov    %ax,0xf017d256
    SETGATE(idt[T_STACK], 0, GD_KT, stack, DPLKERN);
f0103949:	b8 0a 3f 10 f0       	mov    $0xf0103f0a,%eax
f010394e:	66 a3 60 d2 17 f0    	mov    %ax,0xf017d260
f0103954:	66 c7 05 62 d2 17 f0 	movw   $0x8,0xf017d262
f010395b:	08 00 
f010395d:	c6 05 64 d2 17 f0 00 	movb   $0x0,0xf017d264
f0103964:	c6 05 65 d2 17 f0 8e 	movb   $0x8e,0xf017d265
f010396b:	c1 e8 10             	shr    $0x10,%eax
f010396e:	66 a3 66 d2 17 f0    	mov    %ax,0xf017d266
    SETGATE(idt[T_GPFLT], 0, GD_KT, gpflt, DPLKERN);
f0103974:	b8 12 3f 10 f0       	mov    $0xf0103f12,%eax
f0103979:	66 a3 68 d2 17 f0    	mov    %ax,0xf017d268
f010397f:	66 c7 05 6a d2 17 f0 	movw   $0x8,0xf017d26a
f0103986:	08 00 
f0103988:	c6 05 6c d2 17 f0 00 	movb   $0x0,0xf017d26c
f010398f:	c6 05 6d d2 17 f0 8e 	movb   $0x8e,0xf017d26d
f0103996:	c1 e8 10             	shr    $0x10,%eax
f0103999:	66 a3 6e d2 17 f0    	mov    %ax,0xf017d26e
    SETGATE(idt[T_PGFLT], 0, GD_KT, pgflt, DPLKERN);
f010399f:	b8 1a 3f 10 f0       	mov    $0xf0103f1a,%eax
f01039a4:	66 a3 70 d2 17 f0    	mov    %ax,0xf017d270
f01039aa:	66 c7 05 72 d2 17 f0 	movw   $0x8,0xf017d272
f01039b1:	08 00 
f01039b3:	c6 05 74 d2 17 f0 00 	movb   $0x0,0xf017d274
f01039ba:	c6 05 75 d2 17 f0 8e 	movb   $0x8e,0xf017d275
f01039c1:	c1 e8 10             	shr    $0x10,%eax
f01039c4:	66 a3 76 d2 17 f0    	mov    %ax,0xf017d276
    SETGATE(idt[T_FPERR], 0, GD_KT, fperr, DPLKERN);
f01039ca:	b8 22 3f 10 f0       	mov    $0xf0103f22,%eax
f01039cf:	66 a3 80 d2 17 f0    	mov    %ax,0xf017d280
f01039d5:	66 c7 05 82 d2 17 f0 	movw   $0x8,0xf017d282
f01039dc:	08 00 
f01039de:	c6 05 84 d2 17 f0 00 	movb   $0x0,0xf017d284
f01039e5:	c6 05 85 d2 17 f0 8e 	movb   $0x8e,0xf017d285
f01039ec:	c1 e8 10             	shr    $0x10,%eax
f01039ef:	66 a3 86 d2 17 f0    	mov    %ax,0xf017d286
    SETGATE(idt[T_ALIGN], 0, GD_KT, align, DPLKERN);
f01039f5:	b8 2c 3f 10 f0       	mov    $0xf0103f2c,%eax
f01039fa:	66 a3 88 d2 17 f0    	mov    %ax,0xf017d288
f0103a00:	66 c7 05 8a d2 17 f0 	movw   $0x8,0xf017d28a
f0103a07:	08 00 
f0103a09:	c6 05 8c d2 17 f0 00 	movb   $0x0,0xf017d28c
f0103a10:	c6 05 8d d2 17 f0 8e 	movb   $0x8e,0xf017d28d
f0103a17:	c1 e8 10             	shr    $0x10,%eax
f0103a1a:	66 a3 8e d2 17 f0    	mov    %ax,0xf017d28e
    SETGATE(idt[T_MCHK], 0, GD_KT, mchk, DPLKERN);
f0103a20:	b8 34 3f 10 f0       	mov    $0xf0103f34,%eax
f0103a25:	66 a3 90 d2 17 f0    	mov    %ax,0xf017d290
f0103a2b:	66 c7 05 92 d2 17 f0 	movw   $0x8,0xf017d292
f0103a32:	08 00 
f0103a34:	c6 05 94 d2 17 f0 00 	movb   $0x0,0xf017d294
f0103a3b:	c6 05 95 d2 17 f0 8e 	movb   $0x8e,0xf017d295
f0103a42:	c1 e8 10             	shr    $0x10,%eax
f0103a45:	66 a3 96 d2 17 f0    	mov    %ax,0xf017d296
    SETGATE(idt[T_SIMDERR], 0, GD_KT, simderr, DPLKERN);
f0103a4b:	b8 3e 3f 10 f0       	mov    $0xf0103f3e,%eax
f0103a50:	66 a3 98 d2 17 f0    	mov    %ax,0xf017d298
f0103a56:	66 c7 05 9a d2 17 f0 	movw   $0x8,0xf017d29a
f0103a5d:	08 00 
f0103a5f:	c6 05 9c d2 17 f0 00 	movb   $0x0,0xf017d29c
f0103a66:	c6 05 9d d2 17 f0 8e 	movb   $0x8e,0xf017d29d
f0103a6d:	c1 e8 10             	shr    $0x10,%eax
f0103a70:	66 a3 9e d2 17 f0    	mov    %ax,0xf017d29e


    SETGATE(idt[T_SYSCALL], 0, GD_KT, syscalls, DPLUSR);
f0103a76:	b8 48 3f 10 f0       	mov    $0xf0103f48,%eax
f0103a7b:	66 a3 80 d3 17 f0    	mov    %ax,0xf017d380
f0103a81:	66 c7 05 82 d3 17 f0 	movw   $0x8,0xf017d382
f0103a88:	08 00 
f0103a8a:	c6 05 84 d3 17 f0 00 	movb   $0x0,0xf017d384
f0103a91:	c6 05 85 d3 17 f0 ee 	movb   $0xee,0xf017d385
f0103a98:	c1 e8 10             	shr    $0x10,%eax
f0103a9b:	66 a3 86 d3 17 f0    	mov    %ax,0xf017d386



	// Per-CPU setup 
	trap_init_percpu();
f0103aa1:	e8 6a fc ff ff       	call   f0103710 <trap_init_percpu>
}
f0103aa6:	5d                   	pop    %ebp
f0103aa7:	c3                   	ret    

f0103aa8 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103aa8:	55                   	push   %ebp
f0103aa9:	89 e5                	mov    %esp,%ebp
f0103aab:	53                   	push   %ebx
f0103aac:	83 ec 14             	sub    $0x14,%esp
f0103aaf:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103ab2:	8b 03                	mov    (%ebx),%eax
f0103ab4:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ab8:	c7 04 24 3b 61 10 f0 	movl   $0xf010613b,(%esp)
f0103abf:	e8 2a fc ff ff       	call   f01036ee <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103ac4:	8b 43 04             	mov    0x4(%ebx),%eax
f0103ac7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103acb:	c7 04 24 4a 61 10 f0 	movl   $0xf010614a,(%esp)
f0103ad2:	e8 17 fc ff ff       	call   f01036ee <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103ad7:	8b 43 08             	mov    0x8(%ebx),%eax
f0103ada:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ade:	c7 04 24 59 61 10 f0 	movl   $0xf0106159,(%esp)
f0103ae5:	e8 04 fc ff ff       	call   f01036ee <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103aea:	8b 43 0c             	mov    0xc(%ebx),%eax
f0103aed:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103af1:	c7 04 24 68 61 10 f0 	movl   $0xf0106168,(%esp)
f0103af8:	e8 f1 fb ff ff       	call   f01036ee <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103afd:	8b 43 10             	mov    0x10(%ebx),%eax
f0103b00:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b04:	c7 04 24 77 61 10 f0 	movl   $0xf0106177,(%esp)
f0103b0b:	e8 de fb ff ff       	call   f01036ee <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103b10:	8b 43 14             	mov    0x14(%ebx),%eax
f0103b13:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b17:	c7 04 24 86 61 10 f0 	movl   $0xf0106186,(%esp)
f0103b1e:	e8 cb fb ff ff       	call   f01036ee <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103b23:	8b 43 18             	mov    0x18(%ebx),%eax
f0103b26:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b2a:	c7 04 24 95 61 10 f0 	movl   $0xf0106195,(%esp)
f0103b31:	e8 b8 fb ff ff       	call   f01036ee <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103b36:	8b 43 1c             	mov    0x1c(%ebx),%eax
f0103b39:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b3d:	c7 04 24 a4 61 10 f0 	movl   $0xf01061a4,(%esp)
f0103b44:	e8 a5 fb ff ff       	call   f01036ee <cprintf>
}
f0103b49:	83 c4 14             	add    $0x14,%esp
f0103b4c:	5b                   	pop    %ebx
f0103b4d:	5d                   	pop    %ebp
f0103b4e:	c3                   	ret    

f0103b4f <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103b4f:	55                   	push   %ebp
f0103b50:	89 e5                	mov    %esp,%ebp
f0103b52:	56                   	push   %esi
f0103b53:	53                   	push   %ebx
f0103b54:	83 ec 10             	sub    $0x10,%esp
f0103b57:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0103b5a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103b5e:	c7 04 24 f1 62 10 f0 	movl   $0xf01062f1,(%esp)
f0103b65:	e8 84 fb ff ff       	call   f01036ee <cprintf>
	print_regs(&tf->tf_regs);
f0103b6a:	89 1c 24             	mov    %ebx,(%esp)
f0103b6d:	e8 36 ff ff ff       	call   f0103aa8 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103b72:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103b76:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b7a:	c7 04 24 f5 61 10 f0 	movl   $0xf01061f5,(%esp)
f0103b81:	e8 68 fb ff ff       	call   f01036ee <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103b86:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103b8a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b8e:	c7 04 24 08 62 10 f0 	movl   $0xf0106208,(%esp)
f0103b95:	e8 54 fb ff ff       	call   f01036ee <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103b9a:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f0103b9d:	83 f8 13             	cmp    $0x13,%eax
f0103ba0:	77 09                	ja     f0103bab <print_trapframe+0x5c>
		return excnames[trapno];
f0103ba2:	8b 14 85 c0 64 10 f0 	mov    -0xfef9b40(,%eax,4),%edx
f0103ba9:	eb 10                	jmp    f0103bbb <print_trapframe+0x6c>
	if (trapno == T_SYSCALL)
		return "System call";
f0103bab:	83 f8 30             	cmp    $0x30,%eax
f0103bae:	ba b3 61 10 f0       	mov    $0xf01061b3,%edx
f0103bb3:	b9 bf 61 10 f0       	mov    $0xf01061bf,%ecx
f0103bb8:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103bbb:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103bbf:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103bc3:	c7 04 24 1b 62 10 f0 	movl   $0xf010621b,(%esp)
f0103bca:	e8 1f fb ff ff       	call   f01036ee <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103bcf:	3b 1d 00 da 17 f0    	cmp    0xf017da00,%ebx
f0103bd5:	75 19                	jne    f0103bf0 <print_trapframe+0xa1>
f0103bd7:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103bdb:	75 13                	jne    f0103bf0 <print_trapframe+0xa1>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0103bdd:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103be0:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103be4:	c7 04 24 2d 62 10 f0 	movl   $0xf010622d,(%esp)
f0103beb:	e8 fe fa ff ff       	call   f01036ee <cprintf>
	cprintf("  err  0x%08x", tf->tf_err);
f0103bf0:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0103bf3:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103bf7:	c7 04 24 3c 62 10 f0 	movl   $0xf010623c,(%esp)
f0103bfe:	e8 eb fa ff ff       	call   f01036ee <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103c03:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103c07:	75 51                	jne    f0103c5a <print_trapframe+0x10b>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103c09:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103c0c:	89 c2                	mov    %eax,%edx
f0103c0e:	83 e2 01             	and    $0x1,%edx
f0103c11:	ba ce 61 10 f0       	mov    $0xf01061ce,%edx
f0103c16:	b9 d9 61 10 f0       	mov    $0xf01061d9,%ecx
f0103c1b:	0f 45 ca             	cmovne %edx,%ecx
f0103c1e:	89 c2                	mov    %eax,%edx
f0103c20:	83 e2 02             	and    $0x2,%edx
f0103c23:	ba e5 61 10 f0       	mov    $0xf01061e5,%edx
f0103c28:	be eb 61 10 f0       	mov    $0xf01061eb,%esi
f0103c2d:	0f 44 d6             	cmove  %esi,%edx
f0103c30:	83 e0 04             	and    $0x4,%eax
f0103c33:	b8 f0 61 10 f0       	mov    $0xf01061f0,%eax
f0103c38:	be 1c 63 10 f0       	mov    $0xf010631c,%esi
f0103c3d:	0f 44 c6             	cmove  %esi,%eax
f0103c40:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103c44:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103c48:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c4c:	c7 04 24 4a 62 10 f0 	movl   $0xf010624a,(%esp)
f0103c53:	e8 96 fa ff ff       	call   f01036ee <cprintf>
f0103c58:	eb 0c                	jmp    f0103c66 <print_trapframe+0x117>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103c5a:	c7 04 24 03 61 10 f0 	movl   $0xf0106103,(%esp)
f0103c61:	e8 88 fa ff ff       	call   f01036ee <cprintf>
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103c66:	8b 43 30             	mov    0x30(%ebx),%eax
f0103c69:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c6d:	c7 04 24 59 62 10 f0 	movl   $0xf0106259,(%esp)
f0103c74:	e8 75 fa ff ff       	call   f01036ee <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103c79:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103c7d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c81:	c7 04 24 68 62 10 f0 	movl   $0xf0106268,(%esp)
f0103c88:	e8 61 fa ff ff       	call   f01036ee <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103c8d:	8b 43 38             	mov    0x38(%ebx),%eax
f0103c90:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c94:	c7 04 24 7b 62 10 f0 	movl   $0xf010627b,(%esp)
f0103c9b:	e8 4e fa ff ff       	call   f01036ee <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103ca0:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103ca4:	74 27                	je     f0103ccd <print_trapframe+0x17e>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103ca6:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103ca9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103cad:	c7 04 24 8a 62 10 f0 	movl   $0xf010628a,(%esp)
f0103cb4:	e8 35 fa ff ff       	call   f01036ee <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103cb9:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103cbd:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103cc1:	c7 04 24 99 62 10 f0 	movl   $0xf0106299,(%esp)
f0103cc8:	e8 21 fa ff ff       	call   f01036ee <cprintf>
	}
}
f0103ccd:	83 c4 10             	add    $0x10,%esp
f0103cd0:	5b                   	pop    %ebx
f0103cd1:	5e                   	pop    %esi
f0103cd2:	5d                   	pop    %ebp
f0103cd3:	c3                   	ret    

f0103cd4 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103cd4:	55                   	push   %ebp
f0103cd5:	89 e5                	mov    %esp,%ebp
f0103cd7:	53                   	push   %ebx
f0103cd8:	83 ec 14             	sub    $0x14,%esp
f0103cdb:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103cde:	0f 20 d0             	mov    %cr2,%eax

	// Read processor's CR2 register to find the faulting address
	fault_va = rcr2();

	// Handle kernel-mode page faults.
	if((tf->tf_cs & 3)==0)
f0103ce1:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103ce5:	75 1c                	jne    f0103d03 <page_fault_handler+0x2f>
	    panic("page fault kernel mode");
f0103ce7:	c7 44 24 08 ac 62 10 	movl   $0xf01062ac,0x8(%esp)
f0103cee:	f0 
f0103cef:	c7 44 24 04 1d 01 00 	movl   $0x11d,0x4(%esp)
f0103cf6:	00 
f0103cf7:	c7 04 24 c3 62 10 f0 	movl   $0xf01062c3,(%esp)
f0103cfe:	e8 b3 c3 ff ff       	call   f01000b6 <_panic>

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103d03:	8b 53 30             	mov    0x30(%ebx),%edx
f0103d06:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103d0a:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103d0e:	a1 e8 d1 17 f0       	mov    0xf017d1e8,%eax
f0103d13:	8b 40 48             	mov    0x48(%eax),%eax
f0103d16:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d1a:	c7 04 24 68 64 10 f0 	movl   $0xf0106468,(%esp)
f0103d21:	e8 c8 f9 ff ff       	call   f01036ee <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103d26:	89 1c 24             	mov    %ebx,(%esp)
f0103d29:	e8 21 fe ff ff       	call   f0103b4f <print_trapframe>
	env_destroy(curenv);
f0103d2e:	a1 e8 d1 17 f0       	mov    0xf017d1e8,%eax
f0103d33:	89 04 24             	mov    %eax,(%esp)
f0103d36:	e8 79 f8 ff ff       	call   f01035b4 <env_destroy>
}
f0103d3b:	83 c4 14             	add    $0x14,%esp
f0103d3e:	5b                   	pop    %ebx
f0103d3f:	5d                   	pop    %ebp
f0103d40:	c3                   	ret    

f0103d41 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103d41:	55                   	push   %ebp
f0103d42:	89 e5                	mov    %esp,%ebp
f0103d44:	57                   	push   %edi
f0103d45:	56                   	push   %esi
f0103d46:	83 ec 20             	sub    $0x20,%esp
f0103d49:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103d4c:	fc                   	cld    

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0103d4d:	9c                   	pushf  
f0103d4e:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103d4f:	f6 c4 02             	test   $0x2,%ah
f0103d52:	74 24                	je     f0103d78 <trap+0x37>
f0103d54:	c7 44 24 0c cf 62 10 	movl   $0xf01062cf,0xc(%esp)
f0103d5b:	f0 
f0103d5c:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0103d63:	f0 
f0103d64:	c7 44 24 04 f6 00 00 	movl   $0xf6,0x4(%esp)
f0103d6b:	00 
f0103d6c:	c7 04 24 c3 62 10 f0 	movl   $0xf01062c3,(%esp)
f0103d73:	e8 3e c3 ff ff       	call   f01000b6 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0103d78:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103d7c:	c7 04 24 e8 62 10 f0 	movl   $0xf01062e8,(%esp)
f0103d83:	e8 66 f9 ff ff       	call   f01036ee <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103d88:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103d8c:	83 e0 03             	and    $0x3,%eax
f0103d8f:	66 83 f8 03          	cmp    $0x3,%ax
f0103d93:	75 3c                	jne    f0103dd1 <trap+0x90>
		// Trapped from user mode.
		assert(curenv);
f0103d95:	a1 e8 d1 17 f0       	mov    0xf017d1e8,%eax
f0103d9a:	85 c0                	test   %eax,%eax
f0103d9c:	75 24                	jne    f0103dc2 <trap+0x81>
f0103d9e:	c7 44 24 0c 03 63 10 	movl   $0xf0106303,0xc(%esp)
f0103da5:	f0 
f0103da6:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0103dad:	f0 
f0103dae:	c7 44 24 04 fc 00 00 	movl   $0xfc,0x4(%esp)
f0103db5:	00 
f0103db6:	c7 04 24 c3 62 10 f0 	movl   $0xf01062c3,(%esp)
f0103dbd:	e8 f4 c2 ff ff       	call   f01000b6 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103dc2:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103dc7:	89 c7                	mov    %eax,%edi
f0103dc9:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103dcb:	8b 35 e8 d1 17 f0    	mov    0xf017d1e8,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103dd1:	89 35 00 da 17 f0    	mov    %esi,0xf017da00
{
	int rval=0;
		//cprintf("error interruot %x\n", tf->tf_err);
	// Handle processor exceptions.
	// LAB 3: Your code here.
	if(tf->tf_trapno==14)
f0103dd7:	8b 46 28             	mov    0x28(%esi),%eax
f0103dda:	83 f8 0e             	cmp    $0xe,%eax
f0103ddd:	75 0a                	jne    f0103de9 <trap+0xa8>
       {
        page_fault_handler(tf);
f0103ddf:	89 34 24             	mov    %esi,(%esp)
f0103de2:	e8 ed fe ff ff       	call   f0103cd4 <page_fault_handler>
f0103de7:	eb 7e                	jmp    f0103e67 <trap+0x126>
        return;
	}
	
	if(tf->tf_trapno==3)
f0103de9:	83 f8 03             	cmp    $0x3,%eax
f0103dec:	75 0a                	jne    f0103df8 <trap+0xb7>
	{
	monitor(tf);
f0103dee:	89 34 24             	mov    %esi,(%esp)
f0103df1:	e8 25 ca ff ff       	call   f010081b <monitor>
f0103df6:	eb 6f                	jmp    f0103e67 <trap+0x126>
	return;	
		
	}
	
	if(tf->tf_trapno==T_SYSCALL)
f0103df8:	83 f8 30             	cmp    $0x30,%eax
f0103dfb:	75 32                	jne    f0103e2f <trap+0xee>
	{
	rval= syscall(tf->tf_regs.reg_eax,tf->tf_regs.reg_edx,tf->tf_regs.reg_ecx,tf->tf_regs.reg_ebx,tf->tf_regs.reg_edi,tf->tf_regs.reg_esi);
f0103dfd:	8b 46 04             	mov    0x4(%esi),%eax
f0103e00:	89 44 24 14          	mov    %eax,0x14(%esp)
f0103e04:	8b 06                	mov    (%esi),%eax
f0103e06:	89 44 24 10          	mov    %eax,0x10(%esp)
f0103e0a:	8b 46 10             	mov    0x10(%esi),%eax
f0103e0d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103e11:	8b 46 18             	mov    0x18(%esi),%eax
f0103e14:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103e18:	8b 46 14             	mov    0x14(%esi),%eax
f0103e1b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103e1f:	8b 46 1c             	mov    0x1c(%esi),%eax
f0103e22:	89 04 24             	mov    %eax,(%esp)
f0103e25:	e8 46 01 00 00       	call   f0103f70 <syscall>
	tf->tf_regs.reg_eax = rval;
f0103e2a:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103e2d:	eb 38                	jmp    f0103e67 <trap+0x126>
	}

        
        
	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103e2f:	89 34 24             	mov    %esi,(%esp)
f0103e32:	e8 18 fd ff ff       	call   f0103b4f <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103e37:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103e3c:	75 1c                	jne    f0103e5a <trap+0x119>
		panic("unhandled trap in kernel");
f0103e3e:	c7 44 24 08 0a 63 10 	movl   $0xf010630a,0x8(%esp)
f0103e45:	f0 
f0103e46:	c7 44 24 04 e5 00 00 	movl   $0xe5,0x4(%esp)
f0103e4d:	00 
f0103e4e:	c7 04 24 c3 62 10 f0 	movl   $0xf01062c3,(%esp)
f0103e55:	e8 5c c2 ff ff       	call   f01000b6 <_panic>
	else {
		env_destroy(curenv);
f0103e5a:	a1 e8 d1 17 f0       	mov    0xf017d1e8,%eax
f0103e5f:	89 04 24             	mov    %eax,(%esp)
f0103e62:	e8 4d f7 ff ff       	call   f01035b4 <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0103e67:	a1 e8 d1 17 f0       	mov    0xf017d1e8,%eax
f0103e6c:	85 c0                	test   %eax,%eax
f0103e6e:	74 06                	je     f0103e76 <trap+0x135>
f0103e70:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103e74:	74 24                	je     f0103e9a <trap+0x159>
f0103e76:	c7 44 24 0c 8c 64 10 	movl   $0xf010648c,0xc(%esp)
f0103e7d:	f0 
f0103e7e:	c7 44 24 08 ba 55 10 	movl   $0xf01055ba,0x8(%esp)
f0103e85:	f0 
f0103e86:	c7 44 24 04 0e 01 00 	movl   $0x10e,0x4(%esp)
f0103e8d:	00 
f0103e8e:	c7 04 24 c3 62 10 f0 	movl   $0xf01062c3,(%esp)
f0103e95:	e8 1c c2 ff ff       	call   f01000b6 <_panic>
	env_run(curenv);
f0103e9a:	89 04 24             	mov    %eax,(%esp)
f0103e9d:	e8 69 f7 ff ff       	call   f010360b <env_run>

f0103ea2 <divide_zero>:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(divide_zero,T_DIVIDE)
f0103ea2:	6a 00                	push   $0x0
f0103ea4:	6a 00                	push   $0x0
f0103ea6:	e9 a6 00 00 00       	jmp    f0103f51 <_alltraps>
f0103eab:	90                   	nop

f0103eac <brkpoint>:
TRAPHANDLER_NOEC(brkpoint,T_BRKPT)
f0103eac:	6a 00                	push   $0x0
f0103eae:	6a 03                	push   $0x3
f0103eb0:	e9 9c 00 00 00       	jmp    f0103f51 <_alltraps>
f0103eb5:	90                   	nop

f0103eb6 <no_seg>:
TRAPHANDLER(no_seg,T_SEGNP)
f0103eb6:	6a 0b                	push   $0xb
f0103eb8:	e9 94 00 00 00       	jmp    f0103f51 <_alltraps>
f0103ebd:	90                   	nop

f0103ebe <debug>:
TRAPHANDLER_NOEC(debug,T_DEBUG)
f0103ebe:	6a 00                	push   $0x0
f0103ec0:	6a 01                	push   $0x1
f0103ec2:	e9 8a 00 00 00       	jmp    f0103f51 <_alltraps>
f0103ec7:	90                   	nop

f0103ec8 <nmi>:
TRAPHANDLER_NOEC(nmi,T_NMI)
f0103ec8:	6a 00                	push   $0x0
f0103eca:	6a 02                	push   $0x2
f0103ecc:	e9 80 00 00 00       	jmp    f0103f51 <_alltraps>
f0103ed1:	90                   	nop

f0103ed2 <oflow>:
TRAPHANDLER_NOEC(oflow,T_OFLOW)
f0103ed2:	6a 00                	push   $0x0
f0103ed4:	6a 04                	push   $0x4
f0103ed6:	e9 76 00 00 00       	jmp    f0103f51 <_alltraps>
f0103edb:	90                   	nop

f0103edc <bound>:
TRAPHANDLER_NOEC(bound,T_BOUND)
f0103edc:	6a 00                	push   $0x0
f0103ede:	6a 05                	push   $0x5
f0103ee0:	e9 6c 00 00 00       	jmp    f0103f51 <_alltraps>
f0103ee5:	90                   	nop

f0103ee6 <illop>:
TRAPHANDLER_NOEC(illop,T_ILLOP)
f0103ee6:	6a 00                	push   $0x0
f0103ee8:	6a 06                	push   $0x6
f0103eea:	e9 62 00 00 00       	jmp    f0103f51 <_alltraps>
f0103eef:	90                   	nop

f0103ef0 <device>:
TRAPHANDLER_NOEC(device,T_DEVICE)
f0103ef0:	6a 00                	push   $0x0
f0103ef2:	6a 07                	push   $0x7
f0103ef4:	e9 58 00 00 00       	jmp    f0103f51 <_alltraps>
f0103ef9:	90                   	nop

f0103efa <dblflt>:
TRAPHANDLER(dblflt,T_DBLFLT)
f0103efa:	6a 08                	push   $0x8
f0103efc:	e9 50 00 00 00       	jmp    f0103f51 <_alltraps>
f0103f01:	90                   	nop

f0103f02 <tss>:
TRAPHANDLER(tss, T_TSS)
f0103f02:	6a 0a                	push   $0xa
f0103f04:	e9 48 00 00 00       	jmp    f0103f51 <_alltraps>
f0103f09:	90                   	nop

f0103f0a <stack>:

TRAPHANDLER(stack, T_STACK)
f0103f0a:	6a 0c                	push   $0xc
f0103f0c:	e9 40 00 00 00       	jmp    f0103f51 <_alltraps>
f0103f11:	90                   	nop

f0103f12 <gpflt>:
TRAPHANDLER(gpflt, T_GPFLT)
f0103f12:	6a 0d                	push   $0xd
f0103f14:	e9 38 00 00 00       	jmp    f0103f51 <_alltraps>
f0103f19:	90                   	nop

f0103f1a <pgflt>:
TRAPHANDLER(pgflt, T_PGFLT)
f0103f1a:	6a 0e                	push   $0xe
f0103f1c:	e9 30 00 00 00       	jmp    f0103f51 <_alltraps>
f0103f21:	90                   	nop

f0103f22 <fperr>:

TRAPHANDLER_NOEC(fperr, T_FPERR)
f0103f22:	6a 00                	push   $0x0
f0103f24:	6a 10                	push   $0x10
f0103f26:	e9 26 00 00 00       	jmp    f0103f51 <_alltraps>
f0103f2b:	90                   	nop

f0103f2c <align>:
TRAPHANDLER(align, T_ALIGN)
f0103f2c:	6a 11                	push   $0x11
f0103f2e:	e9 1e 00 00 00       	jmp    f0103f51 <_alltraps>
f0103f33:	90                   	nop

f0103f34 <mchk>:
TRAPHANDLER_NOEC(mchk, T_MCHK)
f0103f34:	6a 00                	push   $0x0
f0103f36:	6a 12                	push   $0x12
f0103f38:	e9 14 00 00 00       	jmp    f0103f51 <_alltraps>
f0103f3d:	90                   	nop

f0103f3e <simderr>:
TRAPHANDLER_NOEC(simderr, T_SIMDERR)
f0103f3e:	6a 00                	push   $0x0
f0103f40:	6a 13                	push   $0x13
f0103f42:	e9 0a 00 00 00       	jmp    f0103f51 <_alltraps>
f0103f47:	90                   	nop

f0103f48 <syscalls>:



TRAPHANDLER_NOEC(syscalls, T_SYSCALL)
f0103f48:	6a 00                	push   $0x0
f0103f4a:	6a 30                	push   $0x30
f0103f4c:	e9 00 00 00 00       	jmp    f0103f51 <_alltraps>

f0103f51 <_alltraps>:


.globl _alltraps
_alltraps:
	pushl %ds
f0103f51:	1e                   	push   %ds
    pushl %es
f0103f52:	06                   	push   %es
	pushal
f0103f53:	60                   	pusha  

	movw $GD_KD, %ax
f0103f54:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f0103f58:	8e d8                	mov    %eax,%ds
	movw %ax, %es 
f0103f5a:	8e c0                	mov    %eax,%es

    pushl %esp  /* trap(%esp) */
f0103f5c:	54                   	push   %esp
    call trap
f0103f5d:	e8 df fd ff ff       	call   f0103d41 <trap>
f0103f62:	66 90                	xchg   %ax,%ax
f0103f64:	66 90                	xchg   %ax,%ax
f0103f66:	66 90                	xchg   %ax,%ax
f0103f68:	66 90                	xchg   %ax,%ax
f0103f6a:	66 90                	xchg   %ax,%ax
f0103f6c:	66 90                	xchg   %ax,%ax
f0103f6e:	66 90                	xchg   %ax,%ax

f0103f70 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0103f70:	55                   	push   %ebp
f0103f71:	89 e5                	mov    %esp,%ebp
f0103f73:	83 ec 28             	sub    $0x28,%esp
f0103f76:	8b 45 08             	mov    0x8(%ebp),%eax
//	SYS_cputs = 0,
//	SYS_cgetc,
//	SYS_getenvid,
//	SYS_env_destroy,al
int rval=0;
	switch(syscallno){
f0103f79:	83 f8 01             	cmp    $0x1,%eax
f0103f7c:	74 5c                	je     f0103fda <syscall+0x6a>
f0103f7e:	83 f8 01             	cmp    $0x1,%eax
f0103f81:	72 12                	jb     f0103f95 <syscall+0x25>
f0103f83:	83 f8 02             	cmp    $0x2,%eax
f0103f86:	74 5a                	je     f0103fe2 <syscall+0x72>
f0103f88:	83 f8 03             	cmp    $0x3,%eax
f0103f8b:	74 5f                	je     f0103fec <syscall+0x7c>
f0103f8d:	8d 76 00             	lea    0x0(%esi),%esi
f0103f90:	e9 c3 00 00 00       	jmp    f0104058 <syscall+0xe8>
static void
sys_cputs(const char *s, size_t len)
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.
    user_mem_assert(curenv, s, len, PTE_U);
f0103f95:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f0103f9c:	00 
f0103f9d:	8b 45 10             	mov    0x10(%ebp),%eax
f0103fa0:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103fa4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103fa7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103fab:	a1 e8 d1 17 f0       	mov    0xf017d1e8,%eax
f0103fb0:	89 04 24             	mov    %eax,(%esp)
f0103fb3:	e8 00 ef ff ff       	call   f0102eb8 <user_mem_assert>
	// LAB 3: Your code here.

	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0103fb8:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103fbb:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103fbf:	8b 45 10             	mov    0x10(%ebp),%eax
f0103fc2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103fc6:	c7 04 24 10 65 10 f0 	movl   $0xf0106510,(%esp)
f0103fcd:	e8 1c f7 ff ff       	call   f01036ee <cprintf>
//	SYS_env_destroy,al
int rval=0;
	switch(syscallno){
		case SYS_cputs:
			sys_cputs((char *)a1, a2);
			rval = a2;
f0103fd2:	8b 45 10             	mov    0x10(%ebp),%eax
			break;
f0103fd5:	e9 83 00 00 00       	jmp    f010405d <syscall+0xed>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f0103fda:	e8 06 c5 ff ff       	call   f01004e5 <cons_getc>
			sys_cputs((char *)a1, a2);
			rval = a2;
			break;
		case SYS_cgetc:
			rval = sys_cgetc();
			break;
f0103fdf:	90                   	nop
f0103fe0:	eb 7b                	jmp    f010405d <syscall+0xed>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0103fe2:	a1 e8 d1 17 f0       	mov    0xf017d1e8,%eax
f0103fe7:	8b 40 48             	mov    0x48(%eax),%eax
		case SYS_cgetc:
			rval = sys_cgetc();
			break;
		case SYS_getenvid:
			rval = sys_getenvid();
			break;
f0103fea:	eb 71                	jmp    f010405d <syscall+0xed>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0103fec:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0103ff3:	00 
f0103ff4:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103ff7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ffb:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103ffe:	89 04 24             	mov    %eax,(%esp)
f0104001:	e8 a6 ef ff ff       	call   f0102fac <envid2env>
f0104006:	85 c0                	test   %eax,%eax
f0104008:	78 53                	js     f010405d <syscall+0xed>
		return r;
	if (e == curenv)
f010400a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010400d:	8b 15 e8 d1 17 f0    	mov    0xf017d1e8,%edx
f0104013:	39 d0                	cmp    %edx,%eax
f0104015:	75 15                	jne    f010402c <syscall+0xbc>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0104017:	8b 40 48             	mov    0x48(%eax),%eax
f010401a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010401e:	c7 04 24 15 65 10 f0 	movl   $0xf0106515,(%esp)
f0104025:	e8 c4 f6 ff ff       	call   f01036ee <cprintf>
f010402a:	eb 1a                	jmp    f0104046 <syscall+0xd6>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f010402c:	8b 40 48             	mov    0x48(%eax),%eax
f010402f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104033:	8b 42 48             	mov    0x48(%edx),%eax
f0104036:	89 44 24 04          	mov    %eax,0x4(%esp)
f010403a:	c7 04 24 30 65 10 f0 	movl   $0xf0106530,(%esp)
f0104041:	e8 a8 f6 ff ff       	call   f01036ee <cprintf>
	env_destroy(e);
f0104046:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104049:	89 04 24             	mov    %eax,(%esp)
f010404c:	e8 63 f5 ff ff       	call   f01035b4 <env_destroy>
	return 0;
f0104051:	b8 00 00 00 00       	mov    $0x0,%eax
f0104056:	eb 05                	jmp    f010405d <syscall+0xed>
			break;
		case SYS_env_destroy:
			rval = sys_env_destroy(a1);
			break;
		default:
			return -E_INVAL; 
f0104058:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	}
	return rval;
}
f010405d:	c9                   	leave  
f010405e:	c3                   	ret    

f010405f <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010405f:	55                   	push   %ebp
f0104060:	89 e5                	mov    %esp,%ebp
f0104062:	57                   	push   %edi
f0104063:	56                   	push   %esi
f0104064:	53                   	push   %ebx
f0104065:	83 ec 14             	sub    $0x14,%esp
f0104068:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010406b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010406e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104071:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104074:	8b 1a                	mov    (%edx),%ebx
f0104076:	8b 01                	mov    (%ecx),%eax
f0104078:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010407b:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104082:	e9 88 00 00 00       	jmp    f010410f <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f0104087:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010408a:	01 d8                	add    %ebx,%eax
f010408c:	89 c7                	mov    %eax,%edi
f010408e:	c1 ef 1f             	shr    $0x1f,%edi
f0104091:	01 c7                	add    %eax,%edi
f0104093:	d1 ff                	sar    %edi
f0104095:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0104098:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010409b:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010409e:	89 f8                	mov    %edi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01040a0:	eb 03                	jmp    f01040a5 <stab_binsearch+0x46>
			m--;
f01040a2:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01040a5:	39 c3                	cmp    %eax,%ebx
f01040a7:	7f 1f                	jg     f01040c8 <stab_binsearch+0x69>
f01040a9:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01040ad:	83 ea 0c             	sub    $0xc,%edx
f01040b0:	39 f1                	cmp    %esi,%ecx
f01040b2:	75 ee                	jne    f01040a2 <stab_binsearch+0x43>
f01040b4:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01040b7:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01040ba:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01040bd:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01040c1:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01040c4:	76 18                	jbe    f01040de <stab_binsearch+0x7f>
f01040c6:	eb 05                	jmp    f01040cd <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01040c8:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f01040cb:	eb 42                	jmp    f010410f <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f01040cd:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01040d0:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01040d2:	8d 5f 01             	lea    0x1(%edi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01040d5:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01040dc:	eb 31                	jmp    f010410f <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01040de:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01040e1:	73 17                	jae    f01040fa <stab_binsearch+0x9b>
			*region_right = m - 1;
f01040e3:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01040e6:	83 e8 01             	sub    $0x1,%eax
f01040e9:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01040ec:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01040ef:	89 07                	mov    %eax,(%edi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01040f1:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01040f8:	eb 15                	jmp    f010410f <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01040fa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01040fd:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0104100:	89 1f                	mov    %ebx,(%edi)
			l = m;
			addr++;
f0104102:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0104106:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104108:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010410f:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0104112:	0f 8e 6f ff ff ff    	jle    f0104087 <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0104118:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010411c:	75 0f                	jne    f010412d <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f010411e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104121:	8b 00                	mov    (%eax),%eax
f0104123:	83 e8 01             	sub    $0x1,%eax
f0104126:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104129:	89 07                	mov    %eax,(%edi)
f010412b:	eb 2c                	jmp    f0104159 <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010412d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104130:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104132:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104135:	8b 0f                	mov    (%edi),%ecx
f0104137:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010413a:	8b 7d ec             	mov    -0x14(%ebp),%edi
f010413d:	8d 14 97             	lea    (%edi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104140:	eb 03                	jmp    f0104145 <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0104142:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104145:	39 c8                	cmp    %ecx,%eax
f0104147:	7e 0b                	jle    f0104154 <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f0104149:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f010414d:	83 ea 0c             	sub    $0xc,%edx
f0104150:	39 f3                	cmp    %esi,%ebx
f0104152:	75 ee                	jne    f0104142 <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f0104154:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104157:	89 07                	mov    %eax,(%edi)
	}
}
f0104159:	83 c4 14             	add    $0x14,%esp
f010415c:	5b                   	pop    %ebx
f010415d:	5e                   	pop    %esi
f010415e:	5f                   	pop    %edi
f010415f:	5d                   	pop    %ebp
f0104160:	c3                   	ret    

f0104161 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104161:	55                   	push   %ebp
f0104162:	89 e5                	mov    %esp,%ebp
f0104164:	57                   	push   %edi
f0104165:	56                   	push   %esi
f0104166:	53                   	push   %ebx
f0104167:	83 ec 4c             	sub    $0x4c,%esp
f010416a:	8b 75 08             	mov    0x8(%ebp),%esi
f010416d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104170:	c7 03 48 65 10 f0    	movl   $0xf0106548,(%ebx)
	info->eip_line = 0;
f0104176:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f010417d:	c7 43 08 48 65 10 f0 	movl   $0xf0106548,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0104184:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f010418b:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f010418e:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0104195:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f010419b:	77 21                	ja     f01041be <debuginfo_eip+0x5d>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f010419d:	a1 00 00 20 00       	mov    0x200000,%eax
f01041a2:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		stab_end = usd->stab_end;
f01041a5:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f01041aa:	8b 3d 08 00 20 00    	mov    0x200008,%edi
f01041b0:	89 7d c0             	mov    %edi,-0x40(%ebp)
		stabstr_end = usd->stabstr_end;
f01041b3:	8b 3d 0c 00 20 00    	mov    0x20000c,%edi
f01041b9:	89 7d bc             	mov    %edi,-0x44(%ebp)
f01041bc:	eb 1a                	jmp    f01041d8 <debuginfo_eip+0x77>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f01041be:	c7 45 bc b4 0d 11 f0 	movl   $0xf0110db4,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f01041c5:	c7 45 c0 15 e3 10 f0 	movl   $0xf010e315,-0x40(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f01041cc:	b8 14 e3 10 f0       	mov    $0xf010e314,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f01041d1:	c7 45 c4 60 67 10 f0 	movl   $0xf0106760,-0x3c(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01041d8:	8b 7d bc             	mov    -0x44(%ebp),%edi
f01041db:	39 7d c0             	cmp    %edi,-0x40(%ebp)
f01041de:	0f 83 95 01 00 00    	jae    f0104379 <debuginfo_eip+0x218>
f01041e4:	80 7f ff 00          	cmpb   $0x0,-0x1(%edi)
f01041e8:	0f 85 92 01 00 00    	jne    f0104380 <debuginfo_eip+0x21f>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01041ee:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01041f5:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f01041f8:	29 f8                	sub    %edi,%eax
f01041fa:	c1 f8 02             	sar    $0x2,%eax
f01041fd:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0104203:	83 e8 01             	sub    $0x1,%eax
f0104206:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0104209:	89 74 24 04          	mov    %esi,0x4(%esp)
f010420d:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0104214:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0104217:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010421a:	89 f8                	mov    %edi,%eax
f010421c:	e8 3e fe ff ff       	call   f010405f <stab_binsearch>
	if (lfile == 0)
f0104221:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104224:	85 c0                	test   %eax,%eax
f0104226:	0f 84 5b 01 00 00    	je     f0104387 <debuginfo_eip+0x226>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010422c:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f010422f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104232:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0104235:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104239:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0104240:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0104243:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0104246:	89 f8                	mov    %edi,%eax
f0104248:	e8 12 fe ff ff       	call   f010405f <stab_binsearch>

	if (lfun <= rfun) {
f010424d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104250:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0104253:	39 c8                	cmp    %ecx,%eax
f0104255:	7f 32                	jg     f0104289 <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0104257:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010425a:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f010425d:	8d 3c 97             	lea    (%edi,%edx,4),%edi
f0104260:	8b 17                	mov    (%edi),%edx
f0104262:	89 55 b8             	mov    %edx,-0x48(%ebp)
f0104265:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0104268:	2b 55 c0             	sub    -0x40(%ebp),%edx
f010426b:	39 55 b8             	cmp    %edx,-0x48(%ebp)
f010426e:	73 09                	jae    f0104279 <debuginfo_eip+0x118>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104270:	8b 55 b8             	mov    -0x48(%ebp),%edx
f0104273:	03 55 c0             	add    -0x40(%ebp),%edx
f0104276:	89 53 08             	mov    %edx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0104279:	8b 57 08             	mov    0x8(%edi),%edx
f010427c:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f010427f:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0104281:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0104284:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0104287:	eb 0f                	jmp    f0104298 <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0104289:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f010428c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010428f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0104292:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104295:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0104298:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f010429f:	00 
f01042a0:	8b 43 08             	mov    0x8(%ebx),%eax
f01042a3:	89 04 24             	mov    %eax,(%esp)
f01042a6:	e8 00 09 00 00       	call   f0104bab <strfind>
f01042ab:	2b 43 08             	sub    0x8(%ebx),%eax
f01042ae:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

          stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); 
f01042b1:	89 74 24 04          	mov    %esi,0x4(%esp)
f01042b5:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f01042bc:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01042bf:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01042c2:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f01042c5:	89 f8                	mov    %edi,%eax
f01042c7:	e8 93 fd ff ff       	call   f010405f <stab_binsearch>
          info->eip_line = stabs[lline].n_desc;
f01042cc:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01042cf:	8d 0c 12             	lea    (%edx,%edx,1),%ecx
f01042d2:	8d 04 11             	lea    (%ecx,%edx,1),%eax
f01042d5:	0f b7 44 87 06       	movzwl 0x6(%edi,%eax,4),%eax
f01042da:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01042dd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01042e0:	89 c6                	mov    %eax,%esi
f01042e2:	89 d0                	mov    %edx,%eax
f01042e4:	01 ca                	add    %ecx,%edx
f01042e6:	8d 14 97             	lea    (%edi,%edx,4),%edx
f01042e9:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01042ec:	eb 06                	jmp    f01042f4 <debuginfo_eip+0x193>
f01042ee:	83 e8 01             	sub    $0x1,%eax
f01042f1:	83 ea 0c             	sub    $0xc,%edx
f01042f4:	89 c7                	mov    %eax,%edi
f01042f6:	39 c6                	cmp    %eax,%esi
f01042f8:	7f 3c                	jg     f0104336 <debuginfo_eip+0x1d5>
	       && stabs[lline].n_type != N_SOL
f01042fa:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01042fe:	80 f9 84             	cmp    $0x84,%cl
f0104301:	75 08                	jne    f010430b <debuginfo_eip+0x1aa>
f0104303:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104306:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0104309:	eb 11                	jmp    f010431c <debuginfo_eip+0x1bb>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010430b:	80 f9 64             	cmp    $0x64,%cl
f010430e:	75 de                	jne    f01042ee <debuginfo_eip+0x18d>
f0104310:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0104314:	74 d8                	je     f01042ee <debuginfo_eip+0x18d>
f0104316:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104319:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010431c:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f010431f:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0104322:	8b 04 86             	mov    (%esi,%eax,4),%eax
f0104325:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0104328:	2b 55 c0             	sub    -0x40(%ebp),%edx
f010432b:	39 d0                	cmp    %edx,%eax
f010432d:	73 0a                	jae    f0104339 <debuginfo_eip+0x1d8>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010432f:	03 45 c0             	add    -0x40(%ebp),%eax
f0104332:	89 03                	mov    %eax,(%ebx)
f0104334:	eb 03                	jmp    f0104339 <debuginfo_eip+0x1d8>
f0104336:	8b 5d 0c             	mov    0xc(%ebp),%ebx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104339:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010433c:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010433f:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104344:	39 f2                	cmp    %esi,%edx
f0104346:	7d 4b                	jge    f0104393 <debuginfo_eip+0x232>
		for (lline = lfun + 1;
f0104348:	83 c2 01             	add    $0x1,%edx
f010434b:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f010434e:	89 d0                	mov    %edx,%eax
f0104350:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0104353:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0104356:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0104359:	eb 04                	jmp    f010435f <debuginfo_eip+0x1fe>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f010435b:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f010435f:	39 c6                	cmp    %eax,%esi
f0104361:	7e 2b                	jle    f010438e <debuginfo_eip+0x22d>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104363:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104367:	83 c0 01             	add    $0x1,%eax
f010436a:	83 c2 0c             	add    $0xc,%edx
f010436d:	80 f9 a0             	cmp    $0xa0,%cl
f0104370:	74 e9                	je     f010435b <debuginfo_eip+0x1fa>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104372:	b8 00 00 00 00       	mov    $0x0,%eax
f0104377:	eb 1a                	jmp    f0104393 <debuginfo_eip+0x232>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0104379:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010437e:	eb 13                	jmp    f0104393 <debuginfo_eip+0x232>
f0104380:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104385:	eb 0c                	jmp    f0104393 <debuginfo_eip+0x232>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0104387:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010438c:	eb 05                	jmp    f0104393 <debuginfo_eip+0x232>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010438e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104393:	83 c4 4c             	add    $0x4c,%esp
f0104396:	5b                   	pop    %ebx
f0104397:	5e                   	pop    %esi
f0104398:	5f                   	pop    %edi
f0104399:	5d                   	pop    %ebp
f010439a:	c3                   	ret    
f010439b:	66 90                	xchg   %ax,%ax
f010439d:	66 90                	xchg   %ax,%ax
f010439f:	90                   	nop

f01043a0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01043a0:	55                   	push   %ebp
f01043a1:	89 e5                	mov    %esp,%ebp
f01043a3:	57                   	push   %edi
f01043a4:	56                   	push   %esi
f01043a5:	53                   	push   %ebx
f01043a6:	83 ec 3c             	sub    $0x3c,%esp
f01043a9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01043ac:	89 d7                	mov    %edx,%edi
f01043ae:	8b 45 08             	mov    0x8(%ebp),%eax
f01043b1:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01043b4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01043b7:	89 c3                	mov    %eax,%ebx
f01043b9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01043bc:	8b 45 10             	mov    0x10(%ebp),%eax
f01043bf:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01043c2:	b9 00 00 00 00       	mov    $0x0,%ecx
f01043c7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01043ca:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01043cd:	39 d9                	cmp    %ebx,%ecx
f01043cf:	72 05                	jb     f01043d6 <printnum+0x36>
f01043d1:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f01043d4:	77 69                	ja     f010443f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01043d6:	8b 4d 18             	mov    0x18(%ebp),%ecx
f01043d9:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01043dd:	83 ee 01             	sub    $0x1,%esi
f01043e0:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01043e4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01043e8:	8b 44 24 08          	mov    0x8(%esp),%eax
f01043ec:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01043f0:	89 c3                	mov    %eax,%ebx
f01043f2:	89 d6                	mov    %edx,%esi
f01043f4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01043f7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01043fa:	89 54 24 08          	mov    %edx,0x8(%esp)
f01043fe:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0104402:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104405:	89 04 24             	mov    %eax,(%esp)
f0104408:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010440b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010440f:	e8 bc 09 00 00       	call   f0104dd0 <__udivdi3>
f0104414:	89 d9                	mov    %ebx,%ecx
f0104416:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010441a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010441e:	89 04 24             	mov    %eax,(%esp)
f0104421:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104425:	89 fa                	mov    %edi,%edx
f0104427:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010442a:	e8 71 ff ff ff       	call   f01043a0 <printnum>
f010442f:	eb 1b                	jmp    f010444c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104431:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104435:	8b 45 18             	mov    0x18(%ebp),%eax
f0104438:	89 04 24             	mov    %eax,(%esp)
f010443b:	ff d3                	call   *%ebx
f010443d:	eb 03                	jmp    f0104442 <printnum+0xa2>
f010443f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0104442:	83 ee 01             	sub    $0x1,%esi
f0104445:	85 f6                	test   %esi,%esi
f0104447:	7f e8                	jg     f0104431 <printnum+0x91>
f0104449:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010444c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104450:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0104454:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104457:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010445a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010445e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104462:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104465:	89 04 24             	mov    %eax,(%esp)
f0104468:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010446b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010446f:	e8 8c 0a 00 00       	call   f0104f00 <__umoddi3>
f0104474:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104478:	0f be 80 52 65 10 f0 	movsbl -0xfef9aae(%eax),%eax
f010447f:	89 04 24             	mov    %eax,(%esp)
f0104482:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104485:	ff d0                	call   *%eax
}
f0104487:	83 c4 3c             	add    $0x3c,%esp
f010448a:	5b                   	pop    %ebx
f010448b:	5e                   	pop    %esi
f010448c:	5f                   	pop    %edi
f010448d:	5d                   	pop    %ebp
f010448e:	c3                   	ret    

f010448f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f010448f:	55                   	push   %ebp
f0104490:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0104492:	83 fa 01             	cmp    $0x1,%edx
f0104495:	7e 0e                	jle    f01044a5 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0104497:	8b 10                	mov    (%eax),%edx
f0104499:	8d 4a 08             	lea    0x8(%edx),%ecx
f010449c:	89 08                	mov    %ecx,(%eax)
f010449e:	8b 02                	mov    (%edx),%eax
f01044a0:	8b 52 04             	mov    0x4(%edx),%edx
f01044a3:	eb 22                	jmp    f01044c7 <getuint+0x38>
	else if (lflag)
f01044a5:	85 d2                	test   %edx,%edx
f01044a7:	74 10                	je     f01044b9 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01044a9:	8b 10                	mov    (%eax),%edx
f01044ab:	8d 4a 04             	lea    0x4(%edx),%ecx
f01044ae:	89 08                	mov    %ecx,(%eax)
f01044b0:	8b 02                	mov    (%edx),%eax
f01044b2:	ba 00 00 00 00       	mov    $0x0,%edx
f01044b7:	eb 0e                	jmp    f01044c7 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01044b9:	8b 10                	mov    (%eax),%edx
f01044bb:	8d 4a 04             	lea    0x4(%edx),%ecx
f01044be:	89 08                	mov    %ecx,(%eax)
f01044c0:	8b 02                	mov    (%edx),%eax
f01044c2:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01044c7:	5d                   	pop    %ebp
f01044c8:	c3                   	ret    

f01044c9 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01044c9:	55                   	push   %ebp
f01044ca:	89 e5                	mov    %esp,%ebp
f01044cc:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01044cf:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01044d3:	8b 10                	mov    (%eax),%edx
f01044d5:	3b 50 04             	cmp    0x4(%eax),%edx
f01044d8:	73 0a                	jae    f01044e4 <sprintputch+0x1b>
		*b->buf++ = ch;
f01044da:	8d 4a 01             	lea    0x1(%edx),%ecx
f01044dd:	89 08                	mov    %ecx,(%eax)
f01044df:	8b 45 08             	mov    0x8(%ebp),%eax
f01044e2:	88 02                	mov    %al,(%edx)
}
f01044e4:	5d                   	pop    %ebp
f01044e5:	c3                   	ret    

f01044e6 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01044e6:	55                   	push   %ebp
f01044e7:	89 e5                	mov    %esp,%ebp
f01044e9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f01044ec:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01044ef:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01044f3:	8b 45 10             	mov    0x10(%ebp),%eax
f01044f6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01044fa:	8b 45 0c             	mov    0xc(%ebp),%eax
f01044fd:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104501:	8b 45 08             	mov    0x8(%ebp),%eax
f0104504:	89 04 24             	mov    %eax,(%esp)
f0104507:	e8 02 00 00 00       	call   f010450e <vprintfmt>
	va_end(ap);
}
f010450c:	c9                   	leave  
f010450d:	c3                   	ret    

f010450e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010450e:	55                   	push   %ebp
f010450f:	89 e5                	mov    %esp,%ebp
f0104511:	57                   	push   %edi
f0104512:	56                   	push   %esi
f0104513:	53                   	push   %ebx
f0104514:	83 ec 3c             	sub    $0x3c,%esp
f0104517:	8b 7d 0c             	mov    0xc(%ebp),%edi
f010451a:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010451d:	eb 14                	jmp    f0104533 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010451f:	85 c0                	test   %eax,%eax
f0104521:	0f 84 b3 03 00 00    	je     f01048da <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f0104527:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010452b:	89 04 24             	mov    %eax,(%esp)
f010452e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104531:	89 f3                	mov    %esi,%ebx
f0104533:	8d 73 01             	lea    0x1(%ebx),%esi
f0104536:	0f b6 03             	movzbl (%ebx),%eax
f0104539:	83 f8 25             	cmp    $0x25,%eax
f010453c:	75 e1                	jne    f010451f <vprintfmt+0x11>
f010453e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0104542:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0104549:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0104550:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0104557:	ba 00 00 00 00       	mov    $0x0,%edx
f010455c:	eb 1d                	jmp    f010457b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010455e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0104560:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0104564:	eb 15                	jmp    f010457b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104566:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0104568:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f010456c:	eb 0d                	jmp    f010457b <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f010456e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104571:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0104574:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010457b:	8d 5e 01             	lea    0x1(%esi),%ebx
f010457e:	0f b6 0e             	movzbl (%esi),%ecx
f0104581:	0f b6 c1             	movzbl %cl,%eax
f0104584:	83 e9 23             	sub    $0x23,%ecx
f0104587:	80 f9 55             	cmp    $0x55,%cl
f010458a:	0f 87 2a 03 00 00    	ja     f01048ba <vprintfmt+0x3ac>
f0104590:	0f b6 c9             	movzbl %cl,%ecx
f0104593:	ff 24 8d dc 65 10 f0 	jmp    *-0xfef9a24(,%ecx,4)
f010459a:	89 de                	mov    %ebx,%esi
f010459c:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01045a1:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f01045a4:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f01045a8:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f01045ab:	8d 58 d0             	lea    -0x30(%eax),%ebx
f01045ae:	83 fb 09             	cmp    $0x9,%ebx
f01045b1:	77 36                	ja     f01045e9 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01045b3:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f01045b6:	eb e9                	jmp    f01045a1 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01045b8:	8b 45 14             	mov    0x14(%ebp),%eax
f01045bb:	8d 48 04             	lea    0x4(%eax),%ecx
f01045be:	89 4d 14             	mov    %ecx,0x14(%ebp)
f01045c1:	8b 00                	mov    (%eax),%eax
f01045c3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01045c6:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01045c8:	eb 22                	jmp    f01045ec <vprintfmt+0xde>
f01045ca:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01045cd:	85 c9                	test   %ecx,%ecx
f01045cf:	b8 00 00 00 00       	mov    $0x0,%eax
f01045d4:	0f 49 c1             	cmovns %ecx,%eax
f01045d7:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01045da:	89 de                	mov    %ebx,%esi
f01045dc:	eb 9d                	jmp    f010457b <vprintfmt+0x6d>
f01045de:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01045e0:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f01045e7:	eb 92                	jmp    f010457b <vprintfmt+0x6d>
f01045e9:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f01045ec:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01045f0:	79 89                	jns    f010457b <vprintfmt+0x6d>
f01045f2:	e9 77 ff ff ff       	jmp    f010456e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01045f7:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01045fa:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f01045fc:	e9 7a ff ff ff       	jmp    f010457b <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104601:	8b 45 14             	mov    0x14(%ebp),%eax
f0104604:	8d 50 04             	lea    0x4(%eax),%edx
f0104607:	89 55 14             	mov    %edx,0x14(%ebp)
f010460a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010460e:	8b 00                	mov    (%eax),%eax
f0104610:	89 04 24             	mov    %eax,(%esp)
f0104613:	ff 55 08             	call   *0x8(%ebp)
			break;
f0104616:	e9 18 ff ff ff       	jmp    f0104533 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010461b:	8b 45 14             	mov    0x14(%ebp),%eax
f010461e:	8d 50 04             	lea    0x4(%eax),%edx
f0104621:	89 55 14             	mov    %edx,0x14(%ebp)
f0104624:	8b 00                	mov    (%eax),%eax
f0104626:	99                   	cltd   
f0104627:	31 d0                	xor    %edx,%eax
f0104629:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010462b:	83 f8 06             	cmp    $0x6,%eax
f010462e:	7f 0b                	jg     f010463b <vprintfmt+0x12d>
f0104630:	8b 14 85 34 67 10 f0 	mov    -0xfef98cc(,%eax,4),%edx
f0104637:	85 d2                	test   %edx,%edx
f0104639:	75 20                	jne    f010465b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f010463b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010463f:	c7 44 24 08 6a 65 10 	movl   $0xf010656a,0x8(%esp)
f0104646:	f0 
f0104647:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010464b:	8b 45 08             	mov    0x8(%ebp),%eax
f010464e:	89 04 24             	mov    %eax,(%esp)
f0104651:	e8 90 fe ff ff       	call   f01044e6 <printfmt>
f0104656:	e9 d8 fe ff ff       	jmp    f0104533 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f010465b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010465f:	c7 44 24 08 cc 55 10 	movl   $0xf01055cc,0x8(%esp)
f0104666:	f0 
f0104667:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010466b:	8b 45 08             	mov    0x8(%ebp),%eax
f010466e:	89 04 24             	mov    %eax,(%esp)
f0104671:	e8 70 fe ff ff       	call   f01044e6 <printfmt>
f0104676:	e9 b8 fe ff ff       	jmp    f0104533 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010467b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010467e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104681:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0104684:	8b 45 14             	mov    0x14(%ebp),%eax
f0104687:	8d 50 04             	lea    0x4(%eax),%edx
f010468a:	89 55 14             	mov    %edx,0x14(%ebp)
f010468d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f010468f:	85 f6                	test   %esi,%esi
f0104691:	b8 63 65 10 f0       	mov    $0xf0106563,%eax
f0104696:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0104699:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f010469d:	0f 84 97 00 00 00    	je     f010473a <vprintfmt+0x22c>
f01046a3:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f01046a7:	0f 8e 9b 00 00 00    	jle    f0104748 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f01046ad:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01046b1:	89 34 24             	mov    %esi,(%esp)
f01046b4:	e8 9f 03 00 00       	call   f0104a58 <strnlen>
f01046b9:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01046bc:	29 c2                	sub    %eax,%edx
f01046be:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f01046c1:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f01046c5:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01046c8:	89 75 d8             	mov    %esi,-0x28(%ebp)
f01046cb:	8b 75 08             	mov    0x8(%ebp),%esi
f01046ce:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01046d1:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01046d3:	eb 0f                	jmp    f01046e4 <vprintfmt+0x1d6>
					putch(padc, putdat);
f01046d5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01046d9:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01046dc:	89 04 24             	mov    %eax,(%esp)
f01046df:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01046e1:	83 eb 01             	sub    $0x1,%ebx
f01046e4:	85 db                	test   %ebx,%ebx
f01046e6:	7f ed                	jg     f01046d5 <vprintfmt+0x1c7>
f01046e8:	8b 75 d8             	mov    -0x28(%ebp),%esi
f01046eb:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01046ee:	85 d2                	test   %edx,%edx
f01046f0:	b8 00 00 00 00       	mov    $0x0,%eax
f01046f5:	0f 49 c2             	cmovns %edx,%eax
f01046f8:	29 c2                	sub    %eax,%edx
f01046fa:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01046fd:	89 d7                	mov    %edx,%edi
f01046ff:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0104702:	eb 50                	jmp    f0104754 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104704:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104708:	74 1e                	je     f0104728 <vprintfmt+0x21a>
f010470a:	0f be d2             	movsbl %dl,%edx
f010470d:	83 ea 20             	sub    $0x20,%edx
f0104710:	83 fa 5e             	cmp    $0x5e,%edx
f0104713:	76 13                	jbe    f0104728 <vprintfmt+0x21a>
					putch('?', putdat);
f0104715:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104718:	89 44 24 04          	mov    %eax,0x4(%esp)
f010471c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0104723:	ff 55 08             	call   *0x8(%ebp)
f0104726:	eb 0d                	jmp    f0104735 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f0104728:	8b 55 0c             	mov    0xc(%ebp),%edx
f010472b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010472f:	89 04 24             	mov    %eax,(%esp)
f0104732:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104735:	83 ef 01             	sub    $0x1,%edi
f0104738:	eb 1a                	jmp    f0104754 <vprintfmt+0x246>
f010473a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010473d:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0104740:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0104743:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0104746:	eb 0c                	jmp    f0104754 <vprintfmt+0x246>
f0104748:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010474b:	8b 7d dc             	mov    -0x24(%ebp),%edi
f010474e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0104751:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0104754:	83 c6 01             	add    $0x1,%esi
f0104757:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f010475b:	0f be c2             	movsbl %dl,%eax
f010475e:	85 c0                	test   %eax,%eax
f0104760:	74 27                	je     f0104789 <vprintfmt+0x27b>
f0104762:	85 db                	test   %ebx,%ebx
f0104764:	78 9e                	js     f0104704 <vprintfmt+0x1f6>
f0104766:	83 eb 01             	sub    $0x1,%ebx
f0104769:	79 99                	jns    f0104704 <vprintfmt+0x1f6>
f010476b:	89 f8                	mov    %edi,%eax
f010476d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0104770:	8b 75 08             	mov    0x8(%ebp),%esi
f0104773:	89 c3                	mov    %eax,%ebx
f0104775:	eb 1a                	jmp    f0104791 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0104777:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010477b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0104782:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0104784:	83 eb 01             	sub    $0x1,%ebx
f0104787:	eb 08                	jmp    f0104791 <vprintfmt+0x283>
f0104789:	89 fb                	mov    %edi,%ebx
f010478b:	8b 75 08             	mov    0x8(%ebp),%esi
f010478e:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0104791:	85 db                	test   %ebx,%ebx
f0104793:	7f e2                	jg     f0104777 <vprintfmt+0x269>
f0104795:	89 75 08             	mov    %esi,0x8(%ebp)
f0104798:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010479b:	e9 93 fd ff ff       	jmp    f0104533 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01047a0:	83 fa 01             	cmp    $0x1,%edx
f01047a3:	7e 16                	jle    f01047bb <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f01047a5:	8b 45 14             	mov    0x14(%ebp),%eax
f01047a8:	8d 50 08             	lea    0x8(%eax),%edx
f01047ab:	89 55 14             	mov    %edx,0x14(%ebp)
f01047ae:	8b 50 04             	mov    0x4(%eax),%edx
f01047b1:	8b 00                	mov    (%eax),%eax
f01047b3:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01047b6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01047b9:	eb 32                	jmp    f01047ed <vprintfmt+0x2df>
	else if (lflag)
f01047bb:	85 d2                	test   %edx,%edx
f01047bd:	74 18                	je     f01047d7 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f01047bf:	8b 45 14             	mov    0x14(%ebp),%eax
f01047c2:	8d 50 04             	lea    0x4(%eax),%edx
f01047c5:	89 55 14             	mov    %edx,0x14(%ebp)
f01047c8:	8b 30                	mov    (%eax),%esi
f01047ca:	89 75 e0             	mov    %esi,-0x20(%ebp)
f01047cd:	89 f0                	mov    %esi,%eax
f01047cf:	c1 f8 1f             	sar    $0x1f,%eax
f01047d2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01047d5:	eb 16                	jmp    f01047ed <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f01047d7:	8b 45 14             	mov    0x14(%ebp),%eax
f01047da:	8d 50 04             	lea    0x4(%eax),%edx
f01047dd:	89 55 14             	mov    %edx,0x14(%ebp)
f01047e0:	8b 30                	mov    (%eax),%esi
f01047e2:	89 75 e0             	mov    %esi,-0x20(%ebp)
f01047e5:	89 f0                	mov    %esi,%eax
f01047e7:	c1 f8 1f             	sar    $0x1f,%eax
f01047ea:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01047ed:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01047f0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01047f3:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01047f8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01047fc:	0f 89 80 00 00 00    	jns    f0104882 <vprintfmt+0x374>
				putch('-', putdat);
f0104802:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104806:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010480d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0104810:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104813:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104816:	f7 d8                	neg    %eax
f0104818:	83 d2 00             	adc    $0x0,%edx
f010481b:	f7 da                	neg    %edx
			}
			base = 10;
f010481d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0104822:	eb 5e                	jmp    f0104882 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0104824:	8d 45 14             	lea    0x14(%ebp),%eax
f0104827:	e8 63 fc ff ff       	call   f010448f <getuint>
			base = 10;
f010482c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0104831:	eb 4f                	jmp    f0104882 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0104833:	8d 45 14             	lea    0x14(%ebp),%eax
f0104836:	e8 54 fc ff ff       	call   f010448f <getuint>
			base = 8;
f010483b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0104840:	eb 40                	jmp    f0104882 <vprintfmt+0x374>

		// pointer
		case 'p':
			putch('0', putdat);
f0104842:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104846:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010484d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0104850:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104854:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010485b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010485e:	8b 45 14             	mov    0x14(%ebp),%eax
f0104861:	8d 50 04             	lea    0x4(%eax),%edx
f0104864:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0104867:	8b 00                	mov    (%eax),%eax
f0104869:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010486e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0104873:	eb 0d                	jmp    f0104882 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0104875:	8d 45 14             	lea    0x14(%ebp),%eax
f0104878:	e8 12 fc ff ff       	call   f010448f <getuint>
			base = 16;
f010487d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0104882:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f0104886:	89 74 24 10          	mov    %esi,0x10(%esp)
f010488a:	8b 75 dc             	mov    -0x24(%ebp),%esi
f010488d:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0104891:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104895:	89 04 24             	mov    %eax,(%esp)
f0104898:	89 54 24 04          	mov    %edx,0x4(%esp)
f010489c:	89 fa                	mov    %edi,%edx
f010489e:	8b 45 08             	mov    0x8(%ebp),%eax
f01048a1:	e8 fa fa ff ff       	call   f01043a0 <printnum>
			break;
f01048a6:	e9 88 fc ff ff       	jmp    f0104533 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01048ab:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01048af:	89 04 24             	mov    %eax,(%esp)
f01048b2:	ff 55 08             	call   *0x8(%ebp)
			break;
f01048b5:	e9 79 fc ff ff       	jmp    f0104533 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01048ba:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01048be:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01048c5:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01048c8:	89 f3                	mov    %esi,%ebx
f01048ca:	eb 03                	jmp    f01048cf <vprintfmt+0x3c1>
f01048cc:	83 eb 01             	sub    $0x1,%ebx
f01048cf:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f01048d3:	75 f7                	jne    f01048cc <vprintfmt+0x3be>
f01048d5:	e9 59 fc ff ff       	jmp    f0104533 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f01048da:	83 c4 3c             	add    $0x3c,%esp
f01048dd:	5b                   	pop    %ebx
f01048de:	5e                   	pop    %esi
f01048df:	5f                   	pop    %edi
f01048e0:	5d                   	pop    %ebp
f01048e1:	c3                   	ret    

f01048e2 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01048e2:	55                   	push   %ebp
f01048e3:	89 e5                	mov    %esp,%ebp
f01048e5:	83 ec 28             	sub    $0x28,%esp
f01048e8:	8b 45 08             	mov    0x8(%ebp),%eax
f01048eb:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01048ee:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01048f1:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01048f5:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01048f8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01048ff:	85 c0                	test   %eax,%eax
f0104901:	74 30                	je     f0104933 <vsnprintf+0x51>
f0104903:	85 d2                	test   %edx,%edx
f0104905:	7e 2c                	jle    f0104933 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104907:	8b 45 14             	mov    0x14(%ebp),%eax
f010490a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010490e:	8b 45 10             	mov    0x10(%ebp),%eax
f0104911:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104915:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104918:	89 44 24 04          	mov    %eax,0x4(%esp)
f010491c:	c7 04 24 c9 44 10 f0 	movl   $0xf01044c9,(%esp)
f0104923:	e8 e6 fb ff ff       	call   f010450e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104928:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010492b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010492e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104931:	eb 05                	jmp    f0104938 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104933:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0104938:	c9                   	leave  
f0104939:	c3                   	ret    

f010493a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010493a:	55                   	push   %ebp
f010493b:	89 e5                	mov    %esp,%ebp
f010493d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104940:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104943:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104947:	8b 45 10             	mov    0x10(%ebp),%eax
f010494a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010494e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104951:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104955:	8b 45 08             	mov    0x8(%ebp),%eax
f0104958:	89 04 24             	mov    %eax,(%esp)
f010495b:	e8 82 ff ff ff       	call   f01048e2 <vsnprintf>
	va_end(ap);

	return rc;
}
f0104960:	c9                   	leave  
f0104961:	c3                   	ret    
f0104962:	66 90                	xchg   %ax,%ax
f0104964:	66 90                	xchg   %ax,%ax
f0104966:	66 90                	xchg   %ax,%ax
f0104968:	66 90                	xchg   %ax,%ax
f010496a:	66 90                	xchg   %ax,%ax
f010496c:	66 90                	xchg   %ax,%ax
f010496e:	66 90                	xchg   %ax,%ax

f0104970 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104970:	55                   	push   %ebp
f0104971:	89 e5                	mov    %esp,%ebp
f0104973:	57                   	push   %edi
f0104974:	56                   	push   %esi
f0104975:	53                   	push   %ebx
f0104976:	83 ec 1c             	sub    $0x1c,%esp
f0104979:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010497c:	85 c0                	test   %eax,%eax
f010497e:	74 10                	je     f0104990 <readline+0x20>
		cprintf("%s", prompt);
f0104980:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104984:	c7 04 24 cc 55 10 f0 	movl   $0xf01055cc,(%esp)
f010498b:	e8 5e ed ff ff       	call   f01036ee <cprintf>

	i = 0;
	echoing = iscons(0);
f0104990:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0104997:	e8 a6 bc ff ff       	call   f0100642 <iscons>
f010499c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010499e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01049a3:	e8 89 bc ff ff       	call   f0100631 <getchar>
f01049a8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01049aa:	85 c0                	test   %eax,%eax
f01049ac:	79 17                	jns    f01049c5 <readline+0x55>
			cprintf("read error: %e\n", c);
f01049ae:	89 44 24 04          	mov    %eax,0x4(%esp)
f01049b2:	c7 04 24 50 67 10 f0 	movl   $0xf0106750,(%esp)
f01049b9:	e8 30 ed ff ff       	call   f01036ee <cprintf>
			return NULL;
f01049be:	b8 00 00 00 00       	mov    $0x0,%eax
f01049c3:	eb 6d                	jmp    f0104a32 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01049c5:	83 f8 7f             	cmp    $0x7f,%eax
f01049c8:	74 05                	je     f01049cf <readline+0x5f>
f01049ca:	83 f8 08             	cmp    $0x8,%eax
f01049cd:	75 19                	jne    f01049e8 <readline+0x78>
f01049cf:	85 f6                	test   %esi,%esi
f01049d1:	7e 15                	jle    f01049e8 <readline+0x78>
			if (echoing)
f01049d3:	85 ff                	test   %edi,%edi
f01049d5:	74 0c                	je     f01049e3 <readline+0x73>
				cputchar('\b');
f01049d7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01049de:	e8 3e bc ff ff       	call   f0100621 <cputchar>
			i--;
f01049e3:	83 ee 01             	sub    $0x1,%esi
f01049e6:	eb bb                	jmp    f01049a3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01049e8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01049ee:	7f 1c                	jg     f0104a0c <readline+0x9c>
f01049f0:	83 fb 1f             	cmp    $0x1f,%ebx
f01049f3:	7e 17                	jle    f0104a0c <readline+0x9c>
			if (echoing)
f01049f5:	85 ff                	test   %edi,%edi
f01049f7:	74 08                	je     f0104a01 <readline+0x91>
				cputchar(c);
f01049f9:	89 1c 24             	mov    %ebx,(%esp)
f01049fc:	e8 20 bc ff ff       	call   f0100621 <cputchar>
			buf[i++] = c;
f0104a01:	88 9e a0 da 17 f0    	mov    %bl,-0xfe82560(%esi)
f0104a07:	8d 76 01             	lea    0x1(%esi),%esi
f0104a0a:	eb 97                	jmp    f01049a3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0104a0c:	83 fb 0d             	cmp    $0xd,%ebx
f0104a0f:	74 05                	je     f0104a16 <readline+0xa6>
f0104a11:	83 fb 0a             	cmp    $0xa,%ebx
f0104a14:	75 8d                	jne    f01049a3 <readline+0x33>
			if (echoing)
f0104a16:	85 ff                	test   %edi,%edi
f0104a18:	74 0c                	je     f0104a26 <readline+0xb6>
				cputchar('\n');
f0104a1a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0104a21:	e8 fb bb ff ff       	call   f0100621 <cputchar>
			buf[i] = 0;
f0104a26:	c6 86 a0 da 17 f0 00 	movb   $0x0,-0xfe82560(%esi)
			return buf;
f0104a2d:	b8 a0 da 17 f0       	mov    $0xf017daa0,%eax
		}
	}
}
f0104a32:	83 c4 1c             	add    $0x1c,%esp
f0104a35:	5b                   	pop    %ebx
f0104a36:	5e                   	pop    %esi
f0104a37:	5f                   	pop    %edi
f0104a38:	5d                   	pop    %ebp
f0104a39:	c3                   	ret    
f0104a3a:	66 90                	xchg   %ax,%ax
f0104a3c:	66 90                	xchg   %ax,%ax
f0104a3e:	66 90                	xchg   %ax,%ax

f0104a40 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104a40:	55                   	push   %ebp
f0104a41:	89 e5                	mov    %esp,%ebp
f0104a43:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104a46:	b8 00 00 00 00       	mov    $0x0,%eax
f0104a4b:	eb 03                	jmp    f0104a50 <strlen+0x10>
		n++;
f0104a4d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104a50:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104a54:	75 f7                	jne    f0104a4d <strlen+0xd>
		n++;
	return n;
}
f0104a56:	5d                   	pop    %ebp
f0104a57:	c3                   	ret    

f0104a58 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104a58:	55                   	push   %ebp
f0104a59:	89 e5                	mov    %esp,%ebp
f0104a5b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104a5e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104a61:	b8 00 00 00 00       	mov    $0x0,%eax
f0104a66:	eb 03                	jmp    f0104a6b <strnlen+0x13>
		n++;
f0104a68:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104a6b:	39 d0                	cmp    %edx,%eax
f0104a6d:	74 06                	je     f0104a75 <strnlen+0x1d>
f0104a6f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0104a73:	75 f3                	jne    f0104a68 <strnlen+0x10>
		n++;
	return n;
}
f0104a75:	5d                   	pop    %ebp
f0104a76:	c3                   	ret    

f0104a77 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104a77:	55                   	push   %ebp
f0104a78:	89 e5                	mov    %esp,%ebp
f0104a7a:	53                   	push   %ebx
f0104a7b:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a7e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104a81:	89 c2                	mov    %eax,%edx
f0104a83:	83 c2 01             	add    $0x1,%edx
f0104a86:	83 c1 01             	add    $0x1,%ecx
f0104a89:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0104a8d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104a90:	84 db                	test   %bl,%bl
f0104a92:	75 ef                	jne    f0104a83 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104a94:	5b                   	pop    %ebx
f0104a95:	5d                   	pop    %ebp
f0104a96:	c3                   	ret    

f0104a97 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104a97:	55                   	push   %ebp
f0104a98:	89 e5                	mov    %esp,%ebp
f0104a9a:	53                   	push   %ebx
f0104a9b:	83 ec 08             	sub    $0x8,%esp
f0104a9e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104aa1:	89 1c 24             	mov    %ebx,(%esp)
f0104aa4:	e8 97 ff ff ff       	call   f0104a40 <strlen>
	strcpy(dst + len, src);
f0104aa9:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104aac:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104ab0:	01 d8                	add    %ebx,%eax
f0104ab2:	89 04 24             	mov    %eax,(%esp)
f0104ab5:	e8 bd ff ff ff       	call   f0104a77 <strcpy>
	return dst;
}
f0104aba:	89 d8                	mov    %ebx,%eax
f0104abc:	83 c4 08             	add    $0x8,%esp
f0104abf:	5b                   	pop    %ebx
f0104ac0:	5d                   	pop    %ebp
f0104ac1:	c3                   	ret    

f0104ac2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104ac2:	55                   	push   %ebp
f0104ac3:	89 e5                	mov    %esp,%ebp
f0104ac5:	56                   	push   %esi
f0104ac6:	53                   	push   %ebx
f0104ac7:	8b 75 08             	mov    0x8(%ebp),%esi
f0104aca:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104acd:	89 f3                	mov    %esi,%ebx
f0104acf:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104ad2:	89 f2                	mov    %esi,%edx
f0104ad4:	eb 0f                	jmp    f0104ae5 <strncpy+0x23>
		*dst++ = *src;
f0104ad6:	83 c2 01             	add    $0x1,%edx
f0104ad9:	0f b6 01             	movzbl (%ecx),%eax
f0104adc:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104adf:	80 39 01             	cmpb   $0x1,(%ecx)
f0104ae2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104ae5:	39 da                	cmp    %ebx,%edx
f0104ae7:	75 ed                	jne    f0104ad6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104ae9:	89 f0                	mov    %esi,%eax
f0104aeb:	5b                   	pop    %ebx
f0104aec:	5e                   	pop    %esi
f0104aed:	5d                   	pop    %ebp
f0104aee:	c3                   	ret    

f0104aef <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104aef:	55                   	push   %ebp
f0104af0:	89 e5                	mov    %esp,%ebp
f0104af2:	56                   	push   %esi
f0104af3:	53                   	push   %ebx
f0104af4:	8b 75 08             	mov    0x8(%ebp),%esi
f0104af7:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104afa:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104afd:	89 f0                	mov    %esi,%eax
f0104aff:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104b03:	85 c9                	test   %ecx,%ecx
f0104b05:	75 0b                	jne    f0104b12 <strlcpy+0x23>
f0104b07:	eb 1d                	jmp    f0104b26 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104b09:	83 c0 01             	add    $0x1,%eax
f0104b0c:	83 c2 01             	add    $0x1,%edx
f0104b0f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104b12:	39 d8                	cmp    %ebx,%eax
f0104b14:	74 0b                	je     f0104b21 <strlcpy+0x32>
f0104b16:	0f b6 0a             	movzbl (%edx),%ecx
f0104b19:	84 c9                	test   %cl,%cl
f0104b1b:	75 ec                	jne    f0104b09 <strlcpy+0x1a>
f0104b1d:	89 c2                	mov    %eax,%edx
f0104b1f:	eb 02                	jmp    f0104b23 <strlcpy+0x34>
f0104b21:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0104b23:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0104b26:	29 f0                	sub    %esi,%eax
}
f0104b28:	5b                   	pop    %ebx
f0104b29:	5e                   	pop    %esi
f0104b2a:	5d                   	pop    %ebp
f0104b2b:	c3                   	ret    

f0104b2c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104b2c:	55                   	push   %ebp
f0104b2d:	89 e5                	mov    %esp,%ebp
f0104b2f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104b32:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104b35:	eb 06                	jmp    f0104b3d <strcmp+0x11>
		p++, q++;
f0104b37:	83 c1 01             	add    $0x1,%ecx
f0104b3a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104b3d:	0f b6 01             	movzbl (%ecx),%eax
f0104b40:	84 c0                	test   %al,%al
f0104b42:	74 04                	je     f0104b48 <strcmp+0x1c>
f0104b44:	3a 02                	cmp    (%edx),%al
f0104b46:	74 ef                	je     f0104b37 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104b48:	0f b6 c0             	movzbl %al,%eax
f0104b4b:	0f b6 12             	movzbl (%edx),%edx
f0104b4e:	29 d0                	sub    %edx,%eax
}
f0104b50:	5d                   	pop    %ebp
f0104b51:	c3                   	ret    

f0104b52 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104b52:	55                   	push   %ebp
f0104b53:	89 e5                	mov    %esp,%ebp
f0104b55:	53                   	push   %ebx
f0104b56:	8b 45 08             	mov    0x8(%ebp),%eax
f0104b59:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104b5c:	89 c3                	mov    %eax,%ebx
f0104b5e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104b61:	eb 06                	jmp    f0104b69 <strncmp+0x17>
		n--, p++, q++;
f0104b63:	83 c0 01             	add    $0x1,%eax
f0104b66:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0104b69:	39 d8                	cmp    %ebx,%eax
f0104b6b:	74 15                	je     f0104b82 <strncmp+0x30>
f0104b6d:	0f b6 08             	movzbl (%eax),%ecx
f0104b70:	84 c9                	test   %cl,%cl
f0104b72:	74 04                	je     f0104b78 <strncmp+0x26>
f0104b74:	3a 0a                	cmp    (%edx),%cl
f0104b76:	74 eb                	je     f0104b63 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104b78:	0f b6 00             	movzbl (%eax),%eax
f0104b7b:	0f b6 12             	movzbl (%edx),%edx
f0104b7e:	29 d0                	sub    %edx,%eax
f0104b80:	eb 05                	jmp    f0104b87 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104b82:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0104b87:	5b                   	pop    %ebx
f0104b88:	5d                   	pop    %ebp
f0104b89:	c3                   	ret    

f0104b8a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104b8a:	55                   	push   %ebp
f0104b8b:	89 e5                	mov    %esp,%ebp
f0104b8d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104b90:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104b94:	eb 07                	jmp    f0104b9d <strchr+0x13>
		if (*s == c)
f0104b96:	38 ca                	cmp    %cl,%dl
f0104b98:	74 0f                	je     f0104ba9 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104b9a:	83 c0 01             	add    $0x1,%eax
f0104b9d:	0f b6 10             	movzbl (%eax),%edx
f0104ba0:	84 d2                	test   %dl,%dl
f0104ba2:	75 f2                	jne    f0104b96 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0104ba4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104ba9:	5d                   	pop    %ebp
f0104baa:	c3                   	ret    

f0104bab <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104bab:	55                   	push   %ebp
f0104bac:	89 e5                	mov    %esp,%ebp
f0104bae:	8b 45 08             	mov    0x8(%ebp),%eax
f0104bb1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104bb5:	eb 07                	jmp    f0104bbe <strfind+0x13>
		if (*s == c)
f0104bb7:	38 ca                	cmp    %cl,%dl
f0104bb9:	74 0a                	je     f0104bc5 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0104bbb:	83 c0 01             	add    $0x1,%eax
f0104bbe:	0f b6 10             	movzbl (%eax),%edx
f0104bc1:	84 d2                	test   %dl,%dl
f0104bc3:	75 f2                	jne    f0104bb7 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0104bc5:	5d                   	pop    %ebp
f0104bc6:	c3                   	ret    

f0104bc7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104bc7:	55                   	push   %ebp
f0104bc8:	89 e5                	mov    %esp,%ebp
f0104bca:	57                   	push   %edi
f0104bcb:	56                   	push   %esi
f0104bcc:	53                   	push   %ebx
f0104bcd:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104bd0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104bd3:	85 c9                	test   %ecx,%ecx
f0104bd5:	74 36                	je     f0104c0d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104bd7:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104bdd:	75 28                	jne    f0104c07 <memset+0x40>
f0104bdf:	f6 c1 03             	test   $0x3,%cl
f0104be2:	75 23                	jne    f0104c07 <memset+0x40>
		c &= 0xFF;
f0104be4:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104be8:	89 d3                	mov    %edx,%ebx
f0104bea:	c1 e3 08             	shl    $0x8,%ebx
f0104bed:	89 d6                	mov    %edx,%esi
f0104bef:	c1 e6 18             	shl    $0x18,%esi
f0104bf2:	89 d0                	mov    %edx,%eax
f0104bf4:	c1 e0 10             	shl    $0x10,%eax
f0104bf7:	09 f0                	or     %esi,%eax
f0104bf9:	09 c2                	or     %eax,%edx
f0104bfb:	89 d0                	mov    %edx,%eax
f0104bfd:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0104bff:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0104c02:	fc                   	cld    
f0104c03:	f3 ab                	rep stos %eax,%es:(%edi)
f0104c05:	eb 06                	jmp    f0104c0d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104c07:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104c0a:	fc                   	cld    
f0104c0b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104c0d:	89 f8                	mov    %edi,%eax
f0104c0f:	5b                   	pop    %ebx
f0104c10:	5e                   	pop    %esi
f0104c11:	5f                   	pop    %edi
f0104c12:	5d                   	pop    %ebp
f0104c13:	c3                   	ret    

f0104c14 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104c14:	55                   	push   %ebp
f0104c15:	89 e5                	mov    %esp,%ebp
f0104c17:	57                   	push   %edi
f0104c18:	56                   	push   %esi
f0104c19:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c1c:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104c1f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104c22:	39 c6                	cmp    %eax,%esi
f0104c24:	73 35                	jae    f0104c5b <memmove+0x47>
f0104c26:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104c29:	39 d0                	cmp    %edx,%eax
f0104c2b:	73 2e                	jae    f0104c5b <memmove+0x47>
		s += n;
		d += n;
f0104c2d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0104c30:	89 d6                	mov    %edx,%esi
f0104c32:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104c34:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104c3a:	75 13                	jne    f0104c4f <memmove+0x3b>
f0104c3c:	f6 c1 03             	test   $0x3,%cl
f0104c3f:	75 0e                	jne    f0104c4f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0104c41:	83 ef 04             	sub    $0x4,%edi
f0104c44:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104c47:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0104c4a:	fd                   	std    
f0104c4b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104c4d:	eb 09                	jmp    f0104c58 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0104c4f:	83 ef 01             	sub    $0x1,%edi
f0104c52:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0104c55:	fd                   	std    
f0104c56:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104c58:	fc                   	cld    
f0104c59:	eb 1d                	jmp    f0104c78 <memmove+0x64>
f0104c5b:	89 f2                	mov    %esi,%edx
f0104c5d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104c5f:	f6 c2 03             	test   $0x3,%dl
f0104c62:	75 0f                	jne    f0104c73 <memmove+0x5f>
f0104c64:	f6 c1 03             	test   $0x3,%cl
f0104c67:	75 0a                	jne    f0104c73 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0104c69:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0104c6c:	89 c7                	mov    %eax,%edi
f0104c6e:	fc                   	cld    
f0104c6f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104c71:	eb 05                	jmp    f0104c78 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104c73:	89 c7                	mov    %eax,%edi
f0104c75:	fc                   	cld    
f0104c76:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0104c78:	5e                   	pop    %esi
f0104c79:	5f                   	pop    %edi
f0104c7a:	5d                   	pop    %ebp
f0104c7b:	c3                   	ret    

f0104c7c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0104c7c:	55                   	push   %ebp
f0104c7d:	89 e5                	mov    %esp,%ebp
f0104c7f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0104c82:	8b 45 10             	mov    0x10(%ebp),%eax
f0104c85:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104c89:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104c8c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104c90:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c93:	89 04 24             	mov    %eax,(%esp)
f0104c96:	e8 79 ff ff ff       	call   f0104c14 <memmove>
}
f0104c9b:	c9                   	leave  
f0104c9c:	c3                   	ret    

f0104c9d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104c9d:	55                   	push   %ebp
f0104c9e:	89 e5                	mov    %esp,%ebp
f0104ca0:	56                   	push   %esi
f0104ca1:	53                   	push   %ebx
f0104ca2:	8b 55 08             	mov    0x8(%ebp),%edx
f0104ca5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104ca8:	89 d6                	mov    %edx,%esi
f0104caa:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104cad:	eb 1a                	jmp    f0104cc9 <memcmp+0x2c>
		if (*s1 != *s2)
f0104caf:	0f b6 02             	movzbl (%edx),%eax
f0104cb2:	0f b6 19             	movzbl (%ecx),%ebx
f0104cb5:	38 d8                	cmp    %bl,%al
f0104cb7:	74 0a                	je     f0104cc3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0104cb9:	0f b6 c0             	movzbl %al,%eax
f0104cbc:	0f b6 db             	movzbl %bl,%ebx
f0104cbf:	29 d8                	sub    %ebx,%eax
f0104cc1:	eb 0f                	jmp    f0104cd2 <memcmp+0x35>
		s1++, s2++;
f0104cc3:	83 c2 01             	add    $0x1,%edx
f0104cc6:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104cc9:	39 f2                	cmp    %esi,%edx
f0104ccb:	75 e2                	jne    f0104caf <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104ccd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104cd2:	5b                   	pop    %ebx
f0104cd3:	5e                   	pop    %esi
f0104cd4:	5d                   	pop    %ebp
f0104cd5:	c3                   	ret    

f0104cd6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104cd6:	55                   	push   %ebp
f0104cd7:	89 e5                	mov    %esp,%ebp
f0104cd9:	8b 45 08             	mov    0x8(%ebp),%eax
f0104cdc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0104cdf:	89 c2                	mov    %eax,%edx
f0104ce1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0104ce4:	eb 07                	jmp    f0104ced <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104ce6:	38 08                	cmp    %cl,(%eax)
f0104ce8:	74 07                	je     f0104cf1 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104cea:	83 c0 01             	add    $0x1,%eax
f0104ced:	39 d0                	cmp    %edx,%eax
f0104cef:	72 f5                	jb     f0104ce6 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104cf1:	5d                   	pop    %ebp
f0104cf2:	c3                   	ret    

f0104cf3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104cf3:	55                   	push   %ebp
f0104cf4:	89 e5                	mov    %esp,%ebp
f0104cf6:	57                   	push   %edi
f0104cf7:	56                   	push   %esi
f0104cf8:	53                   	push   %ebx
f0104cf9:	8b 55 08             	mov    0x8(%ebp),%edx
f0104cfc:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104cff:	eb 03                	jmp    f0104d04 <strtol+0x11>
		s++;
f0104d01:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104d04:	0f b6 0a             	movzbl (%edx),%ecx
f0104d07:	80 f9 09             	cmp    $0x9,%cl
f0104d0a:	74 f5                	je     f0104d01 <strtol+0xe>
f0104d0c:	80 f9 20             	cmp    $0x20,%cl
f0104d0f:	74 f0                	je     f0104d01 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104d11:	80 f9 2b             	cmp    $0x2b,%cl
f0104d14:	75 0a                	jne    f0104d20 <strtol+0x2d>
		s++;
f0104d16:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0104d19:	bf 00 00 00 00       	mov    $0x0,%edi
f0104d1e:	eb 11                	jmp    f0104d31 <strtol+0x3e>
f0104d20:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104d25:	80 f9 2d             	cmp    $0x2d,%cl
f0104d28:	75 07                	jne    f0104d31 <strtol+0x3e>
		s++, neg = 1;
f0104d2a:	8d 52 01             	lea    0x1(%edx),%edx
f0104d2d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104d31:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0104d36:	75 15                	jne    f0104d4d <strtol+0x5a>
f0104d38:	80 3a 30             	cmpb   $0x30,(%edx)
f0104d3b:	75 10                	jne    f0104d4d <strtol+0x5a>
f0104d3d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0104d41:	75 0a                	jne    f0104d4d <strtol+0x5a>
		s += 2, base = 16;
f0104d43:	83 c2 02             	add    $0x2,%edx
f0104d46:	b8 10 00 00 00       	mov    $0x10,%eax
f0104d4b:	eb 10                	jmp    f0104d5d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f0104d4d:	85 c0                	test   %eax,%eax
f0104d4f:	75 0c                	jne    f0104d5d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104d51:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104d53:	80 3a 30             	cmpb   $0x30,(%edx)
f0104d56:	75 05                	jne    f0104d5d <strtol+0x6a>
		s++, base = 8;
f0104d58:	83 c2 01             	add    $0x1,%edx
f0104d5b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f0104d5d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104d62:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104d65:	0f b6 0a             	movzbl (%edx),%ecx
f0104d68:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0104d6b:	89 f0                	mov    %esi,%eax
f0104d6d:	3c 09                	cmp    $0x9,%al
f0104d6f:	77 08                	ja     f0104d79 <strtol+0x86>
			dig = *s - '0';
f0104d71:	0f be c9             	movsbl %cl,%ecx
f0104d74:	83 e9 30             	sub    $0x30,%ecx
f0104d77:	eb 20                	jmp    f0104d99 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0104d79:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0104d7c:	89 f0                	mov    %esi,%eax
f0104d7e:	3c 19                	cmp    $0x19,%al
f0104d80:	77 08                	ja     f0104d8a <strtol+0x97>
			dig = *s - 'a' + 10;
f0104d82:	0f be c9             	movsbl %cl,%ecx
f0104d85:	83 e9 57             	sub    $0x57,%ecx
f0104d88:	eb 0f                	jmp    f0104d99 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f0104d8a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0104d8d:	89 f0                	mov    %esi,%eax
f0104d8f:	3c 19                	cmp    $0x19,%al
f0104d91:	77 16                	ja     f0104da9 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0104d93:	0f be c9             	movsbl %cl,%ecx
f0104d96:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0104d99:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f0104d9c:	7d 0f                	jge    f0104dad <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f0104d9e:	83 c2 01             	add    $0x1,%edx
f0104da1:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0104da5:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0104da7:	eb bc                	jmp    f0104d65 <strtol+0x72>
f0104da9:	89 d8                	mov    %ebx,%eax
f0104dab:	eb 02                	jmp    f0104daf <strtol+0xbc>
f0104dad:	89 d8                	mov    %ebx,%eax

	if (endptr)
f0104daf:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104db3:	74 05                	je     f0104dba <strtol+0xc7>
		*endptr = (char *) s;
f0104db5:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104db8:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f0104dba:	f7 d8                	neg    %eax
f0104dbc:	85 ff                	test   %edi,%edi
f0104dbe:	0f 44 c3             	cmove  %ebx,%eax
}
f0104dc1:	5b                   	pop    %ebx
f0104dc2:	5e                   	pop    %esi
f0104dc3:	5f                   	pop    %edi
f0104dc4:	5d                   	pop    %ebp
f0104dc5:	c3                   	ret    
f0104dc6:	66 90                	xchg   %ax,%ax
f0104dc8:	66 90                	xchg   %ax,%ax
f0104dca:	66 90                	xchg   %ax,%ax
f0104dcc:	66 90                	xchg   %ax,%ax
f0104dce:	66 90                	xchg   %ax,%ax

f0104dd0 <__udivdi3>:
f0104dd0:	55                   	push   %ebp
f0104dd1:	57                   	push   %edi
f0104dd2:	56                   	push   %esi
f0104dd3:	83 ec 0c             	sub    $0xc,%esp
f0104dd6:	8b 44 24 28          	mov    0x28(%esp),%eax
f0104dda:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0104dde:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0104de2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0104de6:	85 c0                	test   %eax,%eax
f0104de8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104dec:	89 ea                	mov    %ebp,%edx
f0104dee:	89 0c 24             	mov    %ecx,(%esp)
f0104df1:	75 2d                	jne    f0104e20 <__udivdi3+0x50>
f0104df3:	39 e9                	cmp    %ebp,%ecx
f0104df5:	77 61                	ja     f0104e58 <__udivdi3+0x88>
f0104df7:	85 c9                	test   %ecx,%ecx
f0104df9:	89 ce                	mov    %ecx,%esi
f0104dfb:	75 0b                	jne    f0104e08 <__udivdi3+0x38>
f0104dfd:	b8 01 00 00 00       	mov    $0x1,%eax
f0104e02:	31 d2                	xor    %edx,%edx
f0104e04:	f7 f1                	div    %ecx
f0104e06:	89 c6                	mov    %eax,%esi
f0104e08:	31 d2                	xor    %edx,%edx
f0104e0a:	89 e8                	mov    %ebp,%eax
f0104e0c:	f7 f6                	div    %esi
f0104e0e:	89 c5                	mov    %eax,%ebp
f0104e10:	89 f8                	mov    %edi,%eax
f0104e12:	f7 f6                	div    %esi
f0104e14:	89 ea                	mov    %ebp,%edx
f0104e16:	83 c4 0c             	add    $0xc,%esp
f0104e19:	5e                   	pop    %esi
f0104e1a:	5f                   	pop    %edi
f0104e1b:	5d                   	pop    %ebp
f0104e1c:	c3                   	ret    
f0104e1d:	8d 76 00             	lea    0x0(%esi),%esi
f0104e20:	39 e8                	cmp    %ebp,%eax
f0104e22:	77 24                	ja     f0104e48 <__udivdi3+0x78>
f0104e24:	0f bd e8             	bsr    %eax,%ebp
f0104e27:	83 f5 1f             	xor    $0x1f,%ebp
f0104e2a:	75 3c                	jne    f0104e68 <__udivdi3+0x98>
f0104e2c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0104e30:	39 34 24             	cmp    %esi,(%esp)
f0104e33:	0f 86 9f 00 00 00    	jbe    f0104ed8 <__udivdi3+0x108>
f0104e39:	39 d0                	cmp    %edx,%eax
f0104e3b:	0f 82 97 00 00 00    	jb     f0104ed8 <__udivdi3+0x108>
f0104e41:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104e48:	31 d2                	xor    %edx,%edx
f0104e4a:	31 c0                	xor    %eax,%eax
f0104e4c:	83 c4 0c             	add    $0xc,%esp
f0104e4f:	5e                   	pop    %esi
f0104e50:	5f                   	pop    %edi
f0104e51:	5d                   	pop    %ebp
f0104e52:	c3                   	ret    
f0104e53:	90                   	nop
f0104e54:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104e58:	89 f8                	mov    %edi,%eax
f0104e5a:	f7 f1                	div    %ecx
f0104e5c:	31 d2                	xor    %edx,%edx
f0104e5e:	83 c4 0c             	add    $0xc,%esp
f0104e61:	5e                   	pop    %esi
f0104e62:	5f                   	pop    %edi
f0104e63:	5d                   	pop    %ebp
f0104e64:	c3                   	ret    
f0104e65:	8d 76 00             	lea    0x0(%esi),%esi
f0104e68:	89 e9                	mov    %ebp,%ecx
f0104e6a:	8b 3c 24             	mov    (%esp),%edi
f0104e6d:	d3 e0                	shl    %cl,%eax
f0104e6f:	89 c6                	mov    %eax,%esi
f0104e71:	b8 20 00 00 00       	mov    $0x20,%eax
f0104e76:	29 e8                	sub    %ebp,%eax
f0104e78:	89 c1                	mov    %eax,%ecx
f0104e7a:	d3 ef                	shr    %cl,%edi
f0104e7c:	89 e9                	mov    %ebp,%ecx
f0104e7e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0104e82:	8b 3c 24             	mov    (%esp),%edi
f0104e85:	09 74 24 08          	or     %esi,0x8(%esp)
f0104e89:	89 d6                	mov    %edx,%esi
f0104e8b:	d3 e7                	shl    %cl,%edi
f0104e8d:	89 c1                	mov    %eax,%ecx
f0104e8f:	89 3c 24             	mov    %edi,(%esp)
f0104e92:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0104e96:	d3 ee                	shr    %cl,%esi
f0104e98:	89 e9                	mov    %ebp,%ecx
f0104e9a:	d3 e2                	shl    %cl,%edx
f0104e9c:	89 c1                	mov    %eax,%ecx
f0104e9e:	d3 ef                	shr    %cl,%edi
f0104ea0:	09 d7                	or     %edx,%edi
f0104ea2:	89 f2                	mov    %esi,%edx
f0104ea4:	89 f8                	mov    %edi,%eax
f0104ea6:	f7 74 24 08          	divl   0x8(%esp)
f0104eaa:	89 d6                	mov    %edx,%esi
f0104eac:	89 c7                	mov    %eax,%edi
f0104eae:	f7 24 24             	mull   (%esp)
f0104eb1:	39 d6                	cmp    %edx,%esi
f0104eb3:	89 14 24             	mov    %edx,(%esp)
f0104eb6:	72 30                	jb     f0104ee8 <__udivdi3+0x118>
f0104eb8:	8b 54 24 04          	mov    0x4(%esp),%edx
f0104ebc:	89 e9                	mov    %ebp,%ecx
f0104ebe:	d3 e2                	shl    %cl,%edx
f0104ec0:	39 c2                	cmp    %eax,%edx
f0104ec2:	73 05                	jae    f0104ec9 <__udivdi3+0xf9>
f0104ec4:	3b 34 24             	cmp    (%esp),%esi
f0104ec7:	74 1f                	je     f0104ee8 <__udivdi3+0x118>
f0104ec9:	89 f8                	mov    %edi,%eax
f0104ecb:	31 d2                	xor    %edx,%edx
f0104ecd:	e9 7a ff ff ff       	jmp    f0104e4c <__udivdi3+0x7c>
f0104ed2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104ed8:	31 d2                	xor    %edx,%edx
f0104eda:	b8 01 00 00 00       	mov    $0x1,%eax
f0104edf:	e9 68 ff ff ff       	jmp    f0104e4c <__udivdi3+0x7c>
f0104ee4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104ee8:	8d 47 ff             	lea    -0x1(%edi),%eax
f0104eeb:	31 d2                	xor    %edx,%edx
f0104eed:	83 c4 0c             	add    $0xc,%esp
f0104ef0:	5e                   	pop    %esi
f0104ef1:	5f                   	pop    %edi
f0104ef2:	5d                   	pop    %ebp
f0104ef3:	c3                   	ret    
f0104ef4:	66 90                	xchg   %ax,%ax
f0104ef6:	66 90                	xchg   %ax,%ax
f0104ef8:	66 90                	xchg   %ax,%ax
f0104efa:	66 90                	xchg   %ax,%ax
f0104efc:	66 90                	xchg   %ax,%ax
f0104efe:	66 90                	xchg   %ax,%ax

f0104f00 <__umoddi3>:
f0104f00:	55                   	push   %ebp
f0104f01:	57                   	push   %edi
f0104f02:	56                   	push   %esi
f0104f03:	83 ec 14             	sub    $0x14,%esp
f0104f06:	8b 44 24 28          	mov    0x28(%esp),%eax
f0104f0a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0104f0e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0104f12:	89 c7                	mov    %eax,%edi
f0104f14:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104f18:	8b 44 24 30          	mov    0x30(%esp),%eax
f0104f1c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0104f20:	89 34 24             	mov    %esi,(%esp)
f0104f23:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104f27:	85 c0                	test   %eax,%eax
f0104f29:	89 c2                	mov    %eax,%edx
f0104f2b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104f2f:	75 17                	jne    f0104f48 <__umoddi3+0x48>
f0104f31:	39 fe                	cmp    %edi,%esi
f0104f33:	76 4b                	jbe    f0104f80 <__umoddi3+0x80>
f0104f35:	89 c8                	mov    %ecx,%eax
f0104f37:	89 fa                	mov    %edi,%edx
f0104f39:	f7 f6                	div    %esi
f0104f3b:	89 d0                	mov    %edx,%eax
f0104f3d:	31 d2                	xor    %edx,%edx
f0104f3f:	83 c4 14             	add    $0x14,%esp
f0104f42:	5e                   	pop    %esi
f0104f43:	5f                   	pop    %edi
f0104f44:	5d                   	pop    %ebp
f0104f45:	c3                   	ret    
f0104f46:	66 90                	xchg   %ax,%ax
f0104f48:	39 f8                	cmp    %edi,%eax
f0104f4a:	77 54                	ja     f0104fa0 <__umoddi3+0xa0>
f0104f4c:	0f bd e8             	bsr    %eax,%ebp
f0104f4f:	83 f5 1f             	xor    $0x1f,%ebp
f0104f52:	75 5c                	jne    f0104fb0 <__umoddi3+0xb0>
f0104f54:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0104f58:	39 3c 24             	cmp    %edi,(%esp)
f0104f5b:	0f 87 e7 00 00 00    	ja     f0105048 <__umoddi3+0x148>
f0104f61:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0104f65:	29 f1                	sub    %esi,%ecx
f0104f67:	19 c7                	sbb    %eax,%edi
f0104f69:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104f6d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104f71:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104f75:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0104f79:	83 c4 14             	add    $0x14,%esp
f0104f7c:	5e                   	pop    %esi
f0104f7d:	5f                   	pop    %edi
f0104f7e:	5d                   	pop    %ebp
f0104f7f:	c3                   	ret    
f0104f80:	85 f6                	test   %esi,%esi
f0104f82:	89 f5                	mov    %esi,%ebp
f0104f84:	75 0b                	jne    f0104f91 <__umoddi3+0x91>
f0104f86:	b8 01 00 00 00       	mov    $0x1,%eax
f0104f8b:	31 d2                	xor    %edx,%edx
f0104f8d:	f7 f6                	div    %esi
f0104f8f:	89 c5                	mov    %eax,%ebp
f0104f91:	8b 44 24 04          	mov    0x4(%esp),%eax
f0104f95:	31 d2                	xor    %edx,%edx
f0104f97:	f7 f5                	div    %ebp
f0104f99:	89 c8                	mov    %ecx,%eax
f0104f9b:	f7 f5                	div    %ebp
f0104f9d:	eb 9c                	jmp    f0104f3b <__umoddi3+0x3b>
f0104f9f:	90                   	nop
f0104fa0:	89 c8                	mov    %ecx,%eax
f0104fa2:	89 fa                	mov    %edi,%edx
f0104fa4:	83 c4 14             	add    $0x14,%esp
f0104fa7:	5e                   	pop    %esi
f0104fa8:	5f                   	pop    %edi
f0104fa9:	5d                   	pop    %ebp
f0104faa:	c3                   	ret    
f0104fab:	90                   	nop
f0104fac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104fb0:	8b 04 24             	mov    (%esp),%eax
f0104fb3:	be 20 00 00 00       	mov    $0x20,%esi
f0104fb8:	89 e9                	mov    %ebp,%ecx
f0104fba:	29 ee                	sub    %ebp,%esi
f0104fbc:	d3 e2                	shl    %cl,%edx
f0104fbe:	89 f1                	mov    %esi,%ecx
f0104fc0:	d3 e8                	shr    %cl,%eax
f0104fc2:	89 e9                	mov    %ebp,%ecx
f0104fc4:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104fc8:	8b 04 24             	mov    (%esp),%eax
f0104fcb:	09 54 24 04          	or     %edx,0x4(%esp)
f0104fcf:	89 fa                	mov    %edi,%edx
f0104fd1:	d3 e0                	shl    %cl,%eax
f0104fd3:	89 f1                	mov    %esi,%ecx
f0104fd5:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104fd9:	8b 44 24 10          	mov    0x10(%esp),%eax
f0104fdd:	d3 ea                	shr    %cl,%edx
f0104fdf:	89 e9                	mov    %ebp,%ecx
f0104fe1:	d3 e7                	shl    %cl,%edi
f0104fe3:	89 f1                	mov    %esi,%ecx
f0104fe5:	d3 e8                	shr    %cl,%eax
f0104fe7:	89 e9                	mov    %ebp,%ecx
f0104fe9:	09 f8                	or     %edi,%eax
f0104feb:	8b 7c 24 10          	mov    0x10(%esp),%edi
f0104fef:	f7 74 24 04          	divl   0x4(%esp)
f0104ff3:	d3 e7                	shl    %cl,%edi
f0104ff5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104ff9:	89 d7                	mov    %edx,%edi
f0104ffb:	f7 64 24 08          	mull   0x8(%esp)
f0104fff:	39 d7                	cmp    %edx,%edi
f0105001:	89 c1                	mov    %eax,%ecx
f0105003:	89 14 24             	mov    %edx,(%esp)
f0105006:	72 2c                	jb     f0105034 <__umoddi3+0x134>
f0105008:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f010500c:	72 22                	jb     f0105030 <__umoddi3+0x130>
f010500e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0105012:	29 c8                	sub    %ecx,%eax
f0105014:	19 d7                	sbb    %edx,%edi
f0105016:	89 e9                	mov    %ebp,%ecx
f0105018:	89 fa                	mov    %edi,%edx
f010501a:	d3 e8                	shr    %cl,%eax
f010501c:	89 f1                	mov    %esi,%ecx
f010501e:	d3 e2                	shl    %cl,%edx
f0105020:	89 e9                	mov    %ebp,%ecx
f0105022:	d3 ef                	shr    %cl,%edi
f0105024:	09 d0                	or     %edx,%eax
f0105026:	89 fa                	mov    %edi,%edx
f0105028:	83 c4 14             	add    $0x14,%esp
f010502b:	5e                   	pop    %esi
f010502c:	5f                   	pop    %edi
f010502d:	5d                   	pop    %ebp
f010502e:	c3                   	ret    
f010502f:	90                   	nop
f0105030:	39 d7                	cmp    %edx,%edi
f0105032:	75 da                	jne    f010500e <__umoddi3+0x10e>
f0105034:	8b 14 24             	mov    (%esp),%edx
f0105037:	89 c1                	mov    %eax,%ecx
f0105039:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f010503d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0105041:	eb cb                	jmp    f010500e <__umoddi3+0x10e>
f0105043:	90                   	nop
f0105044:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105048:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f010504c:	0f 82 0f ff ff ff    	jb     f0104f61 <__umoddi3+0x61>
f0105052:	e9 1a ff ff ff       	jmp    f0104f71 <__umoddi3+0x71>
