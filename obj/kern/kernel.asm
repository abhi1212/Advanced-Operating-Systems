
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
f0100015:	b8 00 f0 11 00       	mov    $0x11f000,%eax
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
f0100034:	bc 00 f0 11 f0       	mov    $0xf011f000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 6a 00 00 00       	call   f01000a8 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{ 
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	56                   	push   %esi
f0100044:	53                   	push   %ebx
f0100045:	83 ec 10             	sub    $0x10,%esp
f0100048:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010004b:	83 3d 80 1e 23 f0 00 	cmpl   $0x0,0xf0231e80
f0100052:	75 46                	jne    f010009a <_panic+0x5a>
		goto dead;
	panicstr = fmt;
f0100054:	89 35 80 1e 23 f0    	mov    %esi,0xf0231e80

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f010005a:	fa                   	cli    
f010005b:	fc                   	cld    

	va_start(ap, fmt);
f010005c:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005f:	e8 e5 65 00 00       	call   f0106649 <cpunum>
f0100064:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100067:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010006b:	8b 55 08             	mov    0x8(%ebp),%edx
f010006e:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100072:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100076:	c7 04 24 20 6d 10 f0 	movl   $0xf0106d20,(%esp)
f010007d:	e8 a7 3e 00 00       	call   f0103f29 <cprintf>
	vcprintf(fmt, ap);
f0100082:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100086:	89 34 24             	mov    %esi,(%esp)
f0100089:	e8 68 3e 00 00       	call   f0103ef6 <vcprintf>
	cprintf("\n");
f010008e:	c7 04 24 b0 7f 10 f0 	movl   $0xf0107fb0,(%esp)
f0100095:	e8 8f 3e 00 00       	call   f0103f29 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010009a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000a1:	e8 e5 08 00 00       	call   f010098b <monitor>
f01000a6:	eb f2                	jmp    f010009a <_panic+0x5a>

f01000a8 <i386_init>:
static void boot_aps(void);


void
i386_init(void)
{
f01000a8:	55                   	push   %ebp
f01000a9:	89 e5                	mov    %esp,%ebp
f01000ab:	53                   	push   %ebx
f01000ac:	83 ec 14             	sub    $0x14,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000af:	b8 08 30 27 f0       	mov    $0xf0273008,%eax
f01000b4:	2d e8 00 23 f0       	sub    $0xf02300e8,%eax
f01000b9:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000bd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000c4:	00 
f01000c5:	c7 04 24 e8 00 23 f0 	movl   $0xf02300e8,(%esp)
f01000cc:	e8 26 5f 00 00       	call   f0105ff7 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000d1:	e8 a9 05 00 00       	call   f010067f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828); 
f01000d6:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000dd:	00 
f01000de:	c7 04 24 8c 6d 10 f0 	movl   $0xf0106d8c,(%esp)
f01000e5:	e8 3f 3e 00 00       	call   f0103f29 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000ea:	e8 9b 13 00 00       	call   f010148a <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000ef:	e8 86 35 00 00       	call   f010367a <env_init>
	trap_init();
f01000f4:	e8 28 3f 00 00       	call   f0104021 <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000f9:	e8 3c 62 00 00       	call   f010633a <mp_init>
	lapic_init();
f01000fe:	66 90                	xchg   %ax,%ax
f0100100:	e8 5f 65 00 00       	call   f0106664 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f0100105:	e8 4f 3d 00 00       	call   f0103e59 <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f010010a:	c7 04 24 c0 13 12 f0 	movl   $0xf01213c0,(%esp)
f0100111:	e8 b1 67 00 00       	call   f01068c7 <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100116:	83 3d 88 1e 23 f0 07 	cmpl   $0x7,0xf0231e88
f010011d:	77 24                	ja     f0100143 <i386_init+0x9b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010011f:	c7 44 24 0c 00 70 00 	movl   $0x7000,0xc(%esp)
f0100126:	00 
f0100127:	c7 44 24 08 44 6d 10 	movl   $0xf0106d44,0x8(%esp)
f010012e:	f0 
f010012f:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100136:	00 
f0100137:	c7 04 24 a7 6d 10 f0 	movl   $0xf0106da7,(%esp)
f010013e:	e8 fd fe ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f0100143:	b8 72 62 10 f0       	mov    $0xf0106272,%eax
f0100148:	2d f8 61 10 f0       	sub    $0xf01061f8,%eax
f010014d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100151:	c7 44 24 04 f8 61 10 	movl   $0xf01061f8,0x4(%esp)
f0100158:	f0 
f0100159:	c7 04 24 00 70 00 f0 	movl   $0xf0007000,(%esp)
f0100160:	e8 df 5e 00 00       	call   f0106044 <memmove>

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f0100165:	bb 20 20 23 f0       	mov    $0xf0232020,%ebx
f010016a:	eb 4d                	jmp    f01001b9 <i386_init+0x111>
		if (c == cpus + cpunum())  // We've started already.
f010016c:	e8 d8 64 00 00       	call   f0106649 <cpunum>
f0100171:	6b c0 74             	imul   $0x74,%eax,%eax
f0100174:	05 20 20 23 f0       	add    $0xf0232020,%eax
f0100179:	39 c3                	cmp    %eax,%ebx
f010017b:	74 39                	je     f01001b6 <i386_init+0x10e>
f010017d:	89 d8                	mov    %ebx,%eax
f010017f:	2d 20 20 23 f0       	sub    $0xf0232020,%eax
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f0100184:	c1 f8 02             	sar    $0x2,%eax
f0100187:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f010018d:	c1 e0 0f             	shl    $0xf,%eax
f0100190:	8d 80 00 b0 23 f0    	lea    -0xfdc5000(%eax),%eax
f0100196:	a3 84 1e 23 f0       	mov    %eax,0xf0231e84
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f010019b:	c7 44 24 04 00 70 00 	movl   $0x7000,0x4(%esp)
f01001a2:	00 
f01001a3:	0f b6 03             	movzbl (%ebx),%eax
f01001a6:	89 04 24             	mov    %eax,(%esp)
f01001a9:	e8 06 66 00 00       	call   f01067b4 <lapic_startap>
		// Wait for the CPU to finish some basic setup in mp_main()
		while(c->cpu_status != CPU_STARTED)
f01001ae:	8b 43 04             	mov    0x4(%ebx),%eax
f01001b1:	83 f8 01             	cmp    $0x1,%eax
f01001b4:	75 f8                	jne    f01001ae <i386_init+0x106>
	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f01001b6:	83 c3 74             	add    $0x74,%ebx
f01001b9:	6b 05 c4 23 23 f0 74 	imul   $0x74,0xf02323c4,%eax
f01001c0:	05 20 20 23 f0       	add    $0xf0232020,%eax
f01001c5:	39 c3                	cmp    %eax,%ebx
f01001c7:	72 a3                	jb     f010016c <i386_init+0xc4>
	// Starting non-boot CPUs
	boot_aps();

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f01001c9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01001d0:	00 
f01001d1:	c7 04 24 dd 1f 1a f0 	movl   $0xf01a1fdd,(%esp)
f01001d8:	e8 b7 36 00 00       	call   f0103894 <env_create>
	// Touch all you want.
	//ENV_CREATE(user_primes, ENV_TYPE_USER);
#endif // TEST*

	// Schedule and run the first user environment!
	sched_yield();
f01001dd:	e8 f4 4c 00 00       	call   f0104ed6 <sched_yield>

f01001e2 <mp_main>:
}

// Setup code for APs
void
mp_main(void)
{
f01001e2:	55                   	push   %ebp
f01001e3:	89 e5                	mov    %esp,%ebp
f01001e5:	83 ec 18             	sub    $0x18,%esp
	// We are in high EIP now, safe to switch to kern_pgdir 
	lcr3(PADDR(kern_pgdir));
f01001e8:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01001ed:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001f2:	77 20                	ja     f0100214 <mp_main+0x32>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001f4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01001f8:	c7 44 24 08 68 6d 10 	movl   $0xf0106d68,0x8(%esp)
f01001ff:	f0 
f0100200:	c7 44 24 04 6d 00 00 	movl   $0x6d,0x4(%esp)
f0100207:	00 
f0100208:	c7 04 24 a7 6d 10 f0 	movl   $0xf0106da7,(%esp)
f010020f:	e8 2c fe ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100214:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0100219:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f010021c:	e8 28 64 00 00       	call   f0106649 <cpunum>
f0100221:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100225:	c7 04 24 b3 6d 10 f0 	movl   $0xf0106db3,(%esp)
f010022c:	e8 f8 3c 00 00       	call   f0103f29 <cprintf>

	lapic_init();
f0100231:	e8 2e 64 00 00       	call   f0106664 <lapic_init>
	env_init_percpu();
f0100236:	e8 15 34 00 00       	call   f0103650 <env_init_percpu>
	trap_init_percpu();
f010023b:	90                   	nop
f010023c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100240:	e8 0b 3d 00 00       	call   f0103f50 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100245:	e8 ff 63 00 00       	call   f0106649 <cpunum>
f010024a:	6b d0 74             	imul   $0x74,%eax,%edx
f010024d:	81 c2 20 20 23 f0    	add    $0xf0232020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0100253:	b8 01 00 00 00       	mov    $0x1,%eax
f0100258:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
	//lock_kernel();
	//sched_yield(); 

	// Remove this after you finish Exercise 4
	//for (;;);
}
f010025c:	c9                   	leave  
f010025d:	c3                   	ret    

f010025e <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010025e:	55                   	push   %ebp
f010025f:	89 e5                	mov    %esp,%ebp
f0100261:	53                   	push   %ebx
f0100262:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f0100265:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100268:	8b 45 0c             	mov    0xc(%ebp),%eax
f010026b:	89 44 24 08          	mov    %eax,0x8(%esp)
f010026f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100272:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100276:	c7 04 24 c9 6d 10 f0 	movl   $0xf0106dc9,(%esp)
f010027d:	e8 a7 3c 00 00       	call   f0103f29 <cprintf>
	vcprintf(fmt, ap);
f0100282:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100286:	8b 45 10             	mov    0x10(%ebp),%eax
f0100289:	89 04 24             	mov    %eax,(%esp)
f010028c:	e8 65 3c 00 00       	call   f0103ef6 <vcprintf>
	cprintf("\n");
f0100291:	c7 04 24 b0 7f 10 f0 	movl   $0xf0107fb0,(%esp)
f0100298:	e8 8c 3c 00 00       	call   f0103f29 <cprintf>
	va_end(ap);
}
f010029d:	83 c4 14             	add    $0x14,%esp
f01002a0:	5b                   	pop    %ebx
f01002a1:	5d                   	pop    %ebp
f01002a2:	c3                   	ret    
f01002a3:	66 90                	xchg   %ax,%ax
f01002a5:	66 90                	xchg   %ax,%ax
f01002a7:	66 90                	xchg   %ax,%ax
f01002a9:	66 90                	xchg   %ax,%ax
f01002ab:	66 90                	xchg   %ax,%ax
f01002ad:	66 90                	xchg   %ax,%ax
f01002af:	90                   	nop

f01002b0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01002b0:	55                   	push   %ebp
f01002b1:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002b3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01002b8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01002b9:	a8 01                	test   $0x1,%al
f01002bb:	74 08                	je     f01002c5 <serial_proc_data+0x15>
f01002bd:	b2 f8                	mov    $0xf8,%dl
f01002bf:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01002c0:	0f b6 c0             	movzbl %al,%eax
f01002c3:	eb 05                	jmp    f01002ca <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01002c5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01002ca:	5d                   	pop    %ebp
f01002cb:	c3                   	ret    

f01002cc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01002cc:	55                   	push   %ebp
f01002cd:	89 e5                	mov    %esp,%ebp
f01002cf:	53                   	push   %ebx
f01002d0:	83 ec 04             	sub    $0x4,%esp
f01002d3:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01002d5:	eb 2a                	jmp    f0100301 <cons_intr+0x35>
		if (c == 0)
f01002d7:	85 d2                	test   %edx,%edx
f01002d9:	74 26                	je     f0100301 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01002db:	a1 24 12 23 f0       	mov    0xf0231224,%eax
f01002e0:	8d 48 01             	lea    0x1(%eax),%ecx
f01002e3:	89 0d 24 12 23 f0    	mov    %ecx,0xf0231224
f01002e9:	88 90 20 10 23 f0    	mov    %dl,-0xfdcefe0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01002ef:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01002f5:	75 0a                	jne    f0100301 <cons_intr+0x35>
			cons.wpos = 0;
f01002f7:	c7 05 24 12 23 f0 00 	movl   $0x0,0xf0231224
f01002fe:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100301:	ff d3                	call   *%ebx
f0100303:	89 c2                	mov    %eax,%edx
f0100305:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100308:	75 cd                	jne    f01002d7 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010030a:	83 c4 04             	add    $0x4,%esp
f010030d:	5b                   	pop    %ebx
f010030e:	5d                   	pop    %ebp
f010030f:	c3                   	ret    

f0100310 <kbd_proc_data>:
f0100310:	ba 64 00 00 00       	mov    $0x64,%edx
f0100315:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f0100316:	a8 01                	test   $0x1,%al
f0100318:	0f 84 f7 00 00 00    	je     f0100415 <kbd_proc_data+0x105>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f010031e:	a8 20                	test   $0x20,%al
f0100320:	0f 85 f5 00 00 00    	jne    f010041b <kbd_proc_data+0x10b>
f0100326:	b2 60                	mov    $0x60,%dl
f0100328:	ec                   	in     (%dx),%al
f0100329:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010032b:	3c e0                	cmp    $0xe0,%al
f010032d:	75 0d                	jne    f010033c <kbd_proc_data+0x2c>
		// E0 escape character
		shift |= E0ESC;
f010032f:	83 0d 00 10 23 f0 40 	orl    $0x40,0xf0231000
		return 0;
f0100336:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f010033b:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010033c:	55                   	push   %ebp
f010033d:	89 e5                	mov    %esp,%ebp
f010033f:	53                   	push   %ebx
f0100340:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f0100343:	84 c0                	test   %al,%al
f0100345:	79 37                	jns    f010037e <kbd_proc_data+0x6e>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100347:	8b 0d 00 10 23 f0    	mov    0xf0231000,%ecx
f010034d:	89 cb                	mov    %ecx,%ebx
f010034f:	83 e3 40             	and    $0x40,%ebx
f0100352:	83 e0 7f             	and    $0x7f,%eax
f0100355:	85 db                	test   %ebx,%ebx
f0100357:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010035a:	0f b6 d2             	movzbl %dl,%edx
f010035d:	0f b6 82 40 6f 10 f0 	movzbl -0xfef90c0(%edx),%eax
f0100364:	83 c8 40             	or     $0x40,%eax
f0100367:	0f b6 c0             	movzbl %al,%eax
f010036a:	f7 d0                	not    %eax
f010036c:	21 c1                	and    %eax,%ecx
f010036e:	89 0d 00 10 23 f0    	mov    %ecx,0xf0231000
		return 0;
f0100374:	b8 00 00 00 00       	mov    $0x0,%eax
f0100379:	e9 a3 00 00 00       	jmp    f0100421 <kbd_proc_data+0x111>
	} else if (shift & E0ESC) {
f010037e:	8b 0d 00 10 23 f0    	mov    0xf0231000,%ecx
f0100384:	f6 c1 40             	test   $0x40,%cl
f0100387:	74 0e                	je     f0100397 <kbd_proc_data+0x87>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100389:	83 c8 80             	or     $0xffffff80,%eax
f010038c:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010038e:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100391:	89 0d 00 10 23 f0    	mov    %ecx,0xf0231000
	}

	shift |= shiftcode[data];
f0100397:	0f b6 d2             	movzbl %dl,%edx
f010039a:	0f b6 82 40 6f 10 f0 	movzbl -0xfef90c0(%edx),%eax
f01003a1:	0b 05 00 10 23 f0    	or     0xf0231000,%eax
	shift ^= togglecode[data];
f01003a7:	0f b6 8a 40 6e 10 f0 	movzbl -0xfef91c0(%edx),%ecx
f01003ae:	31 c8                	xor    %ecx,%eax
f01003b0:	a3 00 10 23 f0       	mov    %eax,0xf0231000

	c = charcode[shift & (CTL | SHIFT)][data];
f01003b5:	89 c1                	mov    %eax,%ecx
f01003b7:	83 e1 03             	and    $0x3,%ecx
f01003ba:	8b 0c 8d 20 6e 10 f0 	mov    -0xfef91e0(,%ecx,4),%ecx
f01003c1:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01003c5:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01003c8:	a8 08                	test   $0x8,%al
f01003ca:	74 1b                	je     f01003e7 <kbd_proc_data+0xd7>
		if ('a' <= c && c <= 'z')
f01003cc:	89 da                	mov    %ebx,%edx
f01003ce:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01003d1:	83 f9 19             	cmp    $0x19,%ecx
f01003d4:	77 05                	ja     f01003db <kbd_proc_data+0xcb>
			c += 'A' - 'a';
f01003d6:	83 eb 20             	sub    $0x20,%ebx
f01003d9:	eb 0c                	jmp    f01003e7 <kbd_proc_data+0xd7>
		else if ('A' <= c && c <= 'Z')
f01003db:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01003de:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01003e1:	83 fa 19             	cmp    $0x19,%edx
f01003e4:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01003e7:	f7 d0                	not    %eax
f01003e9:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003eb:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01003ed:	f6 c2 06             	test   $0x6,%dl
f01003f0:	75 2f                	jne    f0100421 <kbd_proc_data+0x111>
f01003f2:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01003f8:	75 27                	jne    f0100421 <kbd_proc_data+0x111>
		cprintf("Rebooting!\n");
f01003fa:	c7 04 24 e3 6d 10 f0 	movl   $0xf0106de3,(%esp)
f0100401:	e8 23 3b 00 00       	call   f0103f29 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100406:	ba 92 00 00 00       	mov    $0x92,%edx
f010040b:	b8 03 00 00 00       	mov    $0x3,%eax
f0100410:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100411:	89 d8                	mov    %ebx,%eax
f0100413:	eb 0c                	jmp    f0100421 <kbd_proc_data+0x111>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100415:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010041a:	c3                   	ret    
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f010041b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100420:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100421:	83 c4 14             	add    $0x14,%esp
f0100424:	5b                   	pop    %ebx
f0100425:	5d                   	pop    %ebp
f0100426:	c3                   	ret    

f0100427 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100427:	55                   	push   %ebp
f0100428:	89 e5                	mov    %esp,%ebp
f010042a:	57                   	push   %edi
f010042b:	56                   	push   %esi
f010042c:	53                   	push   %ebx
f010042d:	83 ec 1c             	sub    $0x1c,%esp
f0100430:	89 c7                	mov    %eax,%edi
f0100432:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100437:	be fd 03 00 00       	mov    $0x3fd,%esi
f010043c:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100441:	eb 06                	jmp    f0100449 <cons_putc+0x22>
f0100443:	89 ca                	mov    %ecx,%edx
f0100445:	ec                   	in     (%dx),%al
f0100446:	ec                   	in     (%dx),%al
f0100447:	ec                   	in     (%dx),%al
f0100448:	ec                   	in     (%dx),%al
f0100449:	89 f2                	mov    %esi,%edx
f010044b:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f010044c:	a8 20                	test   $0x20,%al
f010044e:	75 05                	jne    f0100455 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100450:	83 eb 01             	sub    $0x1,%ebx
f0100453:	75 ee                	jne    f0100443 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f0100455:	89 f8                	mov    %edi,%eax
f0100457:	0f b6 c0             	movzbl %al,%eax
f010045a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010045d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100462:	ee                   	out    %al,(%dx)
f0100463:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100468:	be 79 03 00 00       	mov    $0x379,%esi
f010046d:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100472:	eb 06                	jmp    f010047a <cons_putc+0x53>
f0100474:	89 ca                	mov    %ecx,%edx
f0100476:	ec                   	in     (%dx),%al
f0100477:	ec                   	in     (%dx),%al
f0100478:	ec                   	in     (%dx),%al
f0100479:	ec                   	in     (%dx),%al
f010047a:	89 f2                	mov    %esi,%edx
f010047c:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010047d:	84 c0                	test   %al,%al
f010047f:	78 05                	js     f0100486 <cons_putc+0x5f>
f0100481:	83 eb 01             	sub    $0x1,%ebx
f0100484:	75 ee                	jne    f0100474 <cons_putc+0x4d>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100486:	ba 78 03 00 00       	mov    $0x378,%edx
f010048b:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f010048f:	ee                   	out    %al,(%dx)
f0100490:	b2 7a                	mov    $0x7a,%dl
f0100492:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100497:	ee                   	out    %al,(%dx)
f0100498:	b8 08 00 00 00       	mov    $0x8,%eax
f010049d:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010049e:	89 fa                	mov    %edi,%edx
f01004a0:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f01004a6:	89 f8                	mov    %edi,%eax
f01004a8:	80 cc 07             	or     $0x7,%ah
f01004ab:	85 d2                	test   %edx,%edx
f01004ad:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f01004b0:	89 f8                	mov    %edi,%eax
f01004b2:	0f b6 c0             	movzbl %al,%eax
f01004b5:	83 f8 09             	cmp    $0x9,%eax
f01004b8:	74 78                	je     f0100532 <cons_putc+0x10b>
f01004ba:	83 f8 09             	cmp    $0x9,%eax
f01004bd:	7f 0a                	jg     f01004c9 <cons_putc+0xa2>
f01004bf:	83 f8 08             	cmp    $0x8,%eax
f01004c2:	74 18                	je     f01004dc <cons_putc+0xb5>
f01004c4:	e9 9d 00 00 00       	jmp    f0100566 <cons_putc+0x13f>
f01004c9:	83 f8 0a             	cmp    $0xa,%eax
f01004cc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01004d0:	74 3a                	je     f010050c <cons_putc+0xe5>
f01004d2:	83 f8 0d             	cmp    $0xd,%eax
f01004d5:	74 3d                	je     f0100514 <cons_putc+0xed>
f01004d7:	e9 8a 00 00 00       	jmp    f0100566 <cons_putc+0x13f>
	case '\b':
		if (crt_pos > 0) {
f01004dc:	0f b7 05 28 12 23 f0 	movzwl 0xf0231228,%eax
f01004e3:	66 85 c0             	test   %ax,%ax
f01004e6:	0f 84 e5 00 00 00    	je     f01005d1 <cons_putc+0x1aa>
			crt_pos--;
f01004ec:	83 e8 01             	sub    $0x1,%eax
f01004ef:	66 a3 28 12 23 f0    	mov    %ax,0xf0231228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004f5:	0f b7 c0             	movzwl %ax,%eax
f01004f8:	66 81 e7 00 ff       	and    $0xff00,%di
f01004fd:	83 cf 20             	or     $0x20,%edi
f0100500:	8b 15 2c 12 23 f0    	mov    0xf023122c,%edx
f0100506:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f010050a:	eb 78                	jmp    f0100584 <cons_putc+0x15d>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010050c:	66 83 05 28 12 23 f0 	addw   $0x50,0xf0231228
f0100513:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100514:	0f b7 05 28 12 23 f0 	movzwl 0xf0231228,%eax
f010051b:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100521:	c1 e8 16             	shr    $0x16,%eax
f0100524:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100527:	c1 e0 04             	shl    $0x4,%eax
f010052a:	66 a3 28 12 23 f0    	mov    %ax,0xf0231228
f0100530:	eb 52                	jmp    f0100584 <cons_putc+0x15d>
		break;
	case '\t':
		cons_putc(' ');
f0100532:	b8 20 00 00 00       	mov    $0x20,%eax
f0100537:	e8 eb fe ff ff       	call   f0100427 <cons_putc>
		cons_putc(' ');
f010053c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100541:	e8 e1 fe ff ff       	call   f0100427 <cons_putc>
		cons_putc(' ');
f0100546:	b8 20 00 00 00       	mov    $0x20,%eax
f010054b:	e8 d7 fe ff ff       	call   f0100427 <cons_putc>
		cons_putc(' ');
f0100550:	b8 20 00 00 00       	mov    $0x20,%eax
f0100555:	e8 cd fe ff ff       	call   f0100427 <cons_putc>
		cons_putc(' ');
f010055a:	b8 20 00 00 00       	mov    $0x20,%eax
f010055f:	e8 c3 fe ff ff       	call   f0100427 <cons_putc>
f0100564:	eb 1e                	jmp    f0100584 <cons_putc+0x15d>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100566:	0f b7 05 28 12 23 f0 	movzwl 0xf0231228,%eax
f010056d:	8d 50 01             	lea    0x1(%eax),%edx
f0100570:	66 89 15 28 12 23 f0 	mov    %dx,0xf0231228
f0100577:	0f b7 c0             	movzwl %ax,%eax
f010057a:	8b 15 2c 12 23 f0    	mov    0xf023122c,%edx
f0100580:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100584:	66 81 3d 28 12 23 f0 	cmpw   $0x7cf,0xf0231228
f010058b:	cf 07 
f010058d:	76 42                	jbe    f01005d1 <cons_putc+0x1aa>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010058f:	a1 2c 12 23 f0       	mov    0xf023122c,%eax
f0100594:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010059b:	00 
f010059c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01005a2:	89 54 24 04          	mov    %edx,0x4(%esp)
f01005a6:	89 04 24             	mov    %eax,(%esp)
f01005a9:	e8 96 5a 00 00       	call   f0106044 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01005ae:	8b 15 2c 12 23 f0    	mov    0xf023122c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005b4:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f01005b9:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005bf:	83 c0 01             	add    $0x1,%eax
f01005c2:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01005c7:	75 f0                	jne    f01005b9 <cons_putc+0x192>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01005c9:	66 83 2d 28 12 23 f0 	subw   $0x50,0xf0231228
f01005d0:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01005d1:	8b 0d 30 12 23 f0    	mov    0xf0231230,%ecx
f01005d7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005dc:	89 ca                	mov    %ecx,%edx
f01005de:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01005df:	0f b7 1d 28 12 23 f0 	movzwl 0xf0231228,%ebx
f01005e6:	8d 71 01             	lea    0x1(%ecx),%esi
f01005e9:	89 d8                	mov    %ebx,%eax
f01005eb:	66 c1 e8 08          	shr    $0x8,%ax
f01005ef:	89 f2                	mov    %esi,%edx
f01005f1:	ee                   	out    %al,(%dx)
f01005f2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005f7:	89 ca                	mov    %ecx,%edx
f01005f9:	ee                   	out    %al,(%dx)
f01005fa:	89 d8                	mov    %ebx,%eax
f01005fc:	89 f2                	mov    %esi,%edx
f01005fe:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01005ff:	83 c4 1c             	add    $0x1c,%esp
f0100602:	5b                   	pop    %ebx
f0100603:	5e                   	pop    %esi
f0100604:	5f                   	pop    %edi
f0100605:	5d                   	pop    %ebp
f0100606:	c3                   	ret    

f0100607 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100607:	80 3d 34 12 23 f0 00 	cmpb   $0x0,0xf0231234
f010060e:	74 11                	je     f0100621 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100610:	55                   	push   %ebp
f0100611:	89 e5                	mov    %esp,%ebp
f0100613:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100616:	b8 b0 02 10 f0       	mov    $0xf01002b0,%eax
f010061b:	e8 ac fc ff ff       	call   f01002cc <cons_intr>
}
f0100620:	c9                   	leave  
f0100621:	f3 c3                	repz ret 

f0100623 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100623:	55                   	push   %ebp
f0100624:	89 e5                	mov    %esp,%ebp
f0100626:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100629:	b8 10 03 10 f0       	mov    $0xf0100310,%eax
f010062e:	e8 99 fc ff ff       	call   f01002cc <cons_intr>
}
f0100633:	c9                   	leave  
f0100634:	c3                   	ret    

f0100635 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100635:	55                   	push   %ebp
f0100636:	89 e5                	mov    %esp,%ebp
f0100638:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010063b:	e8 c7 ff ff ff       	call   f0100607 <serial_intr>
	kbd_intr();
f0100640:	e8 de ff ff ff       	call   f0100623 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100645:	a1 20 12 23 f0       	mov    0xf0231220,%eax
f010064a:	3b 05 24 12 23 f0    	cmp    0xf0231224,%eax
f0100650:	74 26                	je     f0100678 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100652:	8d 50 01             	lea    0x1(%eax),%edx
f0100655:	89 15 20 12 23 f0    	mov    %edx,0xf0231220
f010065b:	0f b6 88 20 10 23 f0 	movzbl -0xfdcefe0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100662:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100664:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010066a:	75 11                	jne    f010067d <cons_getc+0x48>
			cons.rpos = 0;
f010066c:	c7 05 20 12 23 f0 00 	movl   $0x0,0xf0231220
f0100673:	00 00 00 
f0100676:	eb 05                	jmp    f010067d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100678:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010067d:	c9                   	leave  
f010067e:	c3                   	ret    

f010067f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010067f:	55                   	push   %ebp
f0100680:	89 e5                	mov    %esp,%ebp
f0100682:	57                   	push   %edi
f0100683:	56                   	push   %esi
f0100684:	53                   	push   %ebx
f0100685:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100688:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010068f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100696:	5a a5 
	if (*cp != 0xA55A) {
f0100698:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010069f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01006a3:	74 11                	je     f01006b6 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01006a5:	c7 05 30 12 23 f0 b4 	movl   $0x3b4,0xf0231230
f01006ac:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01006af:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f01006b4:	eb 16                	jmp    f01006cc <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01006b6:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01006bd:	c7 05 30 12 23 f0 d4 	movl   $0x3d4,0xf0231230
f01006c4:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006c7:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01006cc:	8b 0d 30 12 23 f0    	mov    0xf0231230,%ecx
f01006d2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01006d7:	89 ca                	mov    %ecx,%edx
f01006d9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01006da:	8d 59 01             	lea    0x1(%ecx),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006dd:	89 da                	mov    %ebx,%edx
f01006df:	ec                   	in     (%dx),%al
f01006e0:	0f b6 f0             	movzbl %al,%esi
f01006e3:	c1 e6 08             	shl    $0x8,%esi
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006e6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01006eb:	89 ca                	mov    %ecx,%edx
f01006ed:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006ee:	89 da                	mov    %ebx,%edx
f01006f0:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01006f1:	89 3d 2c 12 23 f0    	mov    %edi,0xf023122c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01006f7:	0f b6 d8             	movzbl %al,%ebx
f01006fa:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01006fc:	66 89 35 28 12 23 f0 	mov    %si,0xf0231228

static void
kbd_init(void)
{
	// Drain the kbd buffer so that QEMU generates interrupts.
	kbd_intr();
f0100703:	e8 1b ff ff ff       	call   f0100623 <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<IRQ_KBD));
f0100708:	0f b7 05 a8 13 12 f0 	movzwl 0xf01213a8,%eax
f010070f:	25 fd ff 00 00       	and    $0xfffd,%eax
f0100714:	89 04 24             	mov    %eax,(%esp)
f0100717:	e8 ce 36 00 00       	call   f0103dea <irq_setmask_8259A>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010071c:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100721:	b8 00 00 00 00       	mov    $0x0,%eax
f0100726:	89 f2                	mov    %esi,%edx
f0100728:	ee                   	out    %al,(%dx)
f0100729:	b2 fb                	mov    $0xfb,%dl
f010072b:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100730:	ee                   	out    %al,(%dx)
f0100731:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100736:	b8 0c 00 00 00       	mov    $0xc,%eax
f010073b:	89 da                	mov    %ebx,%edx
f010073d:	ee                   	out    %al,(%dx)
f010073e:	b2 f9                	mov    $0xf9,%dl
f0100740:	b8 00 00 00 00       	mov    $0x0,%eax
f0100745:	ee                   	out    %al,(%dx)
f0100746:	b2 fb                	mov    $0xfb,%dl
f0100748:	b8 03 00 00 00       	mov    $0x3,%eax
f010074d:	ee                   	out    %al,(%dx)
f010074e:	b2 fc                	mov    $0xfc,%dl
f0100750:	b8 00 00 00 00       	mov    $0x0,%eax
f0100755:	ee                   	out    %al,(%dx)
f0100756:	b2 f9                	mov    $0xf9,%dl
f0100758:	b8 01 00 00 00       	mov    $0x1,%eax
f010075d:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010075e:	b2 fd                	mov    $0xfd,%dl
f0100760:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100761:	3c ff                	cmp    $0xff,%al
f0100763:	0f 95 c1             	setne  %cl
f0100766:	88 0d 34 12 23 f0    	mov    %cl,0xf0231234
f010076c:	89 f2                	mov    %esi,%edx
f010076e:	ec                   	in     (%dx),%al
f010076f:	89 da                	mov    %ebx,%edx
f0100771:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100772:	84 c9                	test   %cl,%cl
f0100774:	75 0c                	jne    f0100782 <cons_init+0x103>
		cprintf("Serial port does not exist!\n");
f0100776:	c7 04 24 ef 6d 10 f0 	movl   $0xf0106def,(%esp)
f010077d:	e8 a7 37 00 00       	call   f0103f29 <cprintf>
}
f0100782:	83 c4 1c             	add    $0x1c,%esp
f0100785:	5b                   	pop    %ebx
f0100786:	5e                   	pop    %esi
f0100787:	5f                   	pop    %edi
f0100788:	5d                   	pop    %ebp
f0100789:	c3                   	ret    

f010078a <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010078a:	55                   	push   %ebp
f010078b:	89 e5                	mov    %esp,%ebp
f010078d:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100790:	8b 45 08             	mov    0x8(%ebp),%eax
f0100793:	e8 8f fc ff ff       	call   f0100427 <cons_putc>
}
f0100798:	c9                   	leave  
f0100799:	c3                   	ret    

f010079a <getchar>:

int
getchar(void)
{
f010079a:	55                   	push   %ebp
f010079b:	89 e5                	mov    %esp,%ebp
f010079d:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01007a0:	e8 90 fe ff ff       	call   f0100635 <cons_getc>
f01007a5:	85 c0                	test   %eax,%eax
f01007a7:	74 f7                	je     f01007a0 <getchar+0x6>
		/* do nothing */;
	return c;
}
f01007a9:	c9                   	leave  
f01007aa:	c3                   	ret    

f01007ab <iscons>:

int
iscons(int fdnum)
{
f01007ab:	55                   	push   %ebp
f01007ac:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01007ae:	b8 01 00 00 00       	mov    $0x1,%eax
f01007b3:	5d                   	pop    %ebp
f01007b4:	c3                   	ret    
f01007b5:	66 90                	xchg   %ax,%ax
f01007b7:	66 90                	xchg   %ax,%ax
f01007b9:	66 90                	xchg   %ax,%ax
f01007bb:	66 90                	xchg   %ax,%ax
f01007bd:	66 90                	xchg   %ax,%ax
f01007bf:	90                   	nop

f01007c0 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01007c0:	55                   	push   %ebp
f01007c1:	89 e5                	mov    %esp,%ebp
f01007c3:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01007c6:	c7 44 24 08 40 70 10 	movl   $0xf0107040,0x8(%esp)
f01007cd:	f0 
f01007ce:	c7 44 24 04 5e 70 10 	movl   $0xf010705e,0x4(%esp)
f01007d5:	f0 
f01007d6:	c7 04 24 63 70 10 f0 	movl   $0xf0107063,(%esp)
f01007dd:	e8 47 37 00 00       	call   f0103f29 <cprintf>
f01007e2:	c7 44 24 08 04 71 10 	movl   $0xf0107104,0x8(%esp)
f01007e9:	f0 
f01007ea:	c7 44 24 04 6c 70 10 	movl   $0xf010706c,0x4(%esp)
f01007f1:	f0 
f01007f2:	c7 04 24 63 70 10 f0 	movl   $0xf0107063,(%esp)
f01007f9:	e8 2b 37 00 00       	call   f0103f29 <cprintf>
f01007fe:	c7 44 24 08 75 70 10 	movl   $0xf0107075,0x8(%esp)
f0100805:	f0 
f0100806:	c7 44 24 04 93 70 10 	movl   $0xf0107093,0x4(%esp)
f010080d:	f0 
f010080e:	c7 04 24 63 70 10 f0 	movl   $0xf0107063,(%esp)
f0100815:	e8 0f 37 00 00       	call   f0103f29 <cprintf>
	return 0;
}
f010081a:	b8 00 00 00 00       	mov    $0x0,%eax
f010081f:	c9                   	leave  
f0100820:	c3                   	ret    

f0100821 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100821:	55                   	push   %ebp
f0100822:	89 e5                	mov    %esp,%ebp
f0100824:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100827:	c7 04 24 9d 70 10 f0 	movl   $0xf010709d,(%esp)
f010082e:	e8 f6 36 00 00       	call   f0103f29 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100833:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f010083a:	00 
f010083b:	c7 04 24 2c 71 10 f0 	movl   $0xf010712c,(%esp)
f0100842:	e8 e2 36 00 00       	call   f0103f29 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100847:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010084e:	00 
f010084f:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100856:	f0 
f0100857:	c7 04 24 54 71 10 f0 	movl   $0xf0107154,(%esp)
f010085e:	e8 c6 36 00 00       	call   f0103f29 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100863:	c7 44 24 08 17 6d 10 	movl   $0x106d17,0x8(%esp)
f010086a:	00 
f010086b:	c7 44 24 04 17 6d 10 	movl   $0xf0106d17,0x4(%esp)
f0100872:	f0 
f0100873:	c7 04 24 78 71 10 f0 	movl   $0xf0107178,(%esp)
f010087a:	e8 aa 36 00 00       	call   f0103f29 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010087f:	c7 44 24 08 e8 00 23 	movl   $0x2300e8,0x8(%esp)
f0100886:	00 
f0100887:	c7 44 24 04 e8 00 23 	movl   $0xf02300e8,0x4(%esp)
f010088e:	f0 
f010088f:	c7 04 24 9c 71 10 f0 	movl   $0xf010719c,(%esp)
f0100896:	e8 8e 36 00 00       	call   f0103f29 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010089b:	c7 44 24 08 08 30 27 	movl   $0x273008,0x8(%esp)
f01008a2:	00 
f01008a3:	c7 44 24 04 08 30 27 	movl   $0xf0273008,0x4(%esp)
f01008aa:	f0 
f01008ab:	c7 04 24 c0 71 10 f0 	movl   $0xf01071c0,(%esp)
f01008b2:	e8 72 36 00 00       	call   f0103f29 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01008b7:	b8 07 34 27 f0       	mov    $0xf0273407,%eax
f01008bc:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f01008c1:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01008c6:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01008cc:	85 c0                	test   %eax,%eax
f01008ce:	0f 48 c2             	cmovs  %edx,%eax
f01008d1:	c1 f8 0a             	sar    $0xa,%eax
f01008d4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008d8:	c7 04 24 e4 71 10 f0 	movl   $0xf01071e4,(%esp)
f01008df:	e8 45 36 00 00       	call   f0103f29 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01008e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01008e9:	c9                   	leave  
f01008ea:	c3                   	ret    

f01008eb <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01008eb:	55                   	push   %ebp
f01008ec:	89 e5                	mov    %esp,%ebp
f01008ee:	56                   	push   %esi
f01008ef:	53                   	push   %ebx
f01008f0:	83 ec 40             	sub    $0x40,%esp
      uint32_t  *x;
      x= (uint32_t *) read_ebp();   
f01008f3:	89 eb                	mov    %ebp,%ebx
      struct Eipdebuginfo info;
      while(x)
     {

	 cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", x, x[1], x[2],x[3],x[4],x[5],x[6]);
         debuginfo_eip(x[1], &info);
f01008f5:	8d 75 e0             	lea    -0x20(%ebp),%esi
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
      uint32_t  *x;
      x= (uint32_t *) read_ebp();   
      struct Eipdebuginfo info;
      while(x)
f01008f8:	eb 7d                	jmp    f0100977 <mon_backtrace+0x8c>
     {

	 cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", x, x[1], x[2],x[3],x[4],x[5],x[6]);
f01008fa:	8b 43 18             	mov    0x18(%ebx),%eax
f01008fd:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f0100901:	8b 43 14             	mov    0x14(%ebx),%eax
f0100904:	89 44 24 18          	mov    %eax,0x18(%esp)
f0100908:	8b 43 10             	mov    0x10(%ebx),%eax
f010090b:	89 44 24 14          	mov    %eax,0x14(%esp)
f010090f:	8b 43 0c             	mov    0xc(%ebx),%eax
f0100912:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100916:	8b 43 08             	mov    0x8(%ebx),%eax
f0100919:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010091d:	8b 43 04             	mov    0x4(%ebx),%eax
f0100920:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100924:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100928:	c7 04 24 10 72 10 f0 	movl   $0xf0107210,(%esp)
f010092f:	e8 f5 35 00 00       	call   f0103f29 <cprintf>
         debuginfo_eip(x[1], &info);
f0100934:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100938:	8b 43 04             	mov    0x4(%ebx),%eax
f010093b:	89 04 24             	mov    %eax,(%esp)
f010093e:	e8 4a 4c 00 00       	call   f010558d <debuginfo_eip>
         cprintf("%s:%d:%.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,(x[1]- info.eip_fn_addr));
f0100943:	8b 43 04             	mov    0x4(%ebx),%eax
f0100946:	2b 45 f0             	sub    -0x10(%ebp),%eax
f0100949:	89 44 24 14          	mov    %eax,0x14(%esp)
f010094d:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100950:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100954:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100957:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010095b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010095e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100962:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100965:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100969:	c7 04 24 b6 70 10 f0 	movl   $0xf01070b6,(%esp)
f0100970:	e8 b4 35 00 00       	call   f0103f29 <cprintf>
         
	 x=(uint32_t *)x[0];
f0100975:	8b 1b                	mov    (%ebx),%ebx
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
      uint32_t  *x;
      x= (uint32_t *) read_ebp();   
      struct Eipdebuginfo info;
      while(x)
f0100977:	85 db                	test   %ebx,%ebx
f0100979:	0f 85 7b ff ff ff    	jne    f01008fa <mon_backtrace+0xf>
	 x=(uint32_t *)x[0];

	}	      
     // Your code here.
	return 0;
}
f010097f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100984:	83 c4 40             	add    $0x40,%esp
f0100987:	5b                   	pop    %ebx
f0100988:	5e                   	pop    %esi
f0100989:	5d                   	pop    %ebp
f010098a:	c3                   	ret    

f010098b <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010098b:	55                   	push   %ebp
f010098c:	89 e5                	mov    %esp,%ebp
f010098e:	57                   	push   %edi
f010098f:	56                   	push   %esi
f0100990:	53                   	push   %ebx
f0100991:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100994:	c7 04 24 44 72 10 f0 	movl   $0xf0107244,(%esp)
f010099b:	e8 89 35 00 00       	call   f0103f29 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01009a0:	c7 04 24 68 72 10 f0 	movl   $0xf0107268,(%esp)
f01009a7:	e8 7d 35 00 00       	call   f0103f29 <cprintf>

	if (tf != NULL)
f01009ac:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01009b0:	74 0b                	je     f01009bd <monitor+0x32>
		print_trapframe(tf);
f01009b2:	8b 45 08             	mov    0x8(%ebp),%eax
f01009b5:	89 04 24             	mov    %eax,(%esp)
f01009b8:	e8 ce 3c 00 00       	call   f010468b <print_trapframe>

	while (1) {
		buf = readline("K> ");
f01009bd:	c7 04 24 c5 70 10 f0 	movl   $0xf01070c5,(%esp)
f01009c4:	e8 d7 53 00 00       	call   f0105da0 <readline>
f01009c9:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01009cb:	85 c0                	test   %eax,%eax
f01009cd:	74 ee                	je     f01009bd <monitor+0x32>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01009cf:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01009d6:	be 00 00 00 00       	mov    $0x0,%esi
f01009db:	eb 0a                	jmp    f01009e7 <monitor+0x5c>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01009dd:	c6 03 00             	movb   $0x0,(%ebx)
f01009e0:	89 f7                	mov    %esi,%edi
f01009e2:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01009e5:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01009e7:	0f b6 03             	movzbl (%ebx),%eax
f01009ea:	84 c0                	test   %al,%al
f01009ec:	74 66                	je     f0100a54 <monitor+0xc9>
f01009ee:	0f be c0             	movsbl %al,%eax
f01009f1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009f5:	c7 04 24 c9 70 10 f0 	movl   $0xf01070c9,(%esp)
f01009fc:	e8 b9 55 00 00       	call   f0105fba <strchr>
f0100a01:	85 c0                	test   %eax,%eax
f0100a03:	75 d8                	jne    f01009dd <monitor+0x52>
			*buf++ = 0;
		if (*buf == 0)
f0100a05:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100a08:	74 4a                	je     f0100a54 <monitor+0xc9>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100a0a:	83 fe 0f             	cmp    $0xf,%esi
f0100a0d:	8d 76 00             	lea    0x0(%esi),%esi
f0100a10:	75 16                	jne    f0100a28 <monitor+0x9d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100a12:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100a19:	00 
f0100a1a:	c7 04 24 ce 70 10 f0 	movl   $0xf01070ce,(%esp)
f0100a21:	e8 03 35 00 00       	call   f0103f29 <cprintf>
f0100a26:	eb 95                	jmp    f01009bd <monitor+0x32>
			return 0;
		}
		argv[argc++] = buf;
f0100a28:	8d 7e 01             	lea    0x1(%esi),%edi
f0100a2b:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100a2f:	eb 03                	jmp    f0100a34 <monitor+0xa9>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100a31:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100a34:	0f b6 03             	movzbl (%ebx),%eax
f0100a37:	84 c0                	test   %al,%al
f0100a39:	74 aa                	je     f01009e5 <monitor+0x5a>
f0100a3b:	0f be c0             	movsbl %al,%eax
f0100a3e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a42:	c7 04 24 c9 70 10 f0 	movl   $0xf01070c9,(%esp)
f0100a49:	e8 6c 55 00 00       	call   f0105fba <strchr>
f0100a4e:	85 c0                	test   %eax,%eax
f0100a50:	74 df                	je     f0100a31 <monitor+0xa6>
f0100a52:	eb 91                	jmp    f01009e5 <monitor+0x5a>
			buf++;
	}
	argv[argc] = 0;
f0100a54:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100a5b:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100a5c:	85 f6                	test   %esi,%esi
f0100a5e:	0f 84 59 ff ff ff    	je     f01009bd <monitor+0x32>
f0100a64:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100a69:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a6c:	8b 04 85 a0 72 10 f0 	mov    -0xfef8d60(,%eax,4),%eax
f0100a73:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a77:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100a7a:	89 04 24             	mov    %eax,(%esp)
f0100a7d:	e8 da 54 00 00       	call   f0105f5c <strcmp>
f0100a82:	85 c0                	test   %eax,%eax
f0100a84:	75 24                	jne    f0100aaa <monitor+0x11f>
			return commands[i].func(argc, argv, tf);
f0100a86:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100a89:	8b 55 08             	mov    0x8(%ebp),%edx
f0100a8c:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100a90:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100a93:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100a97:	89 34 24             	mov    %esi,(%esp)
f0100a9a:	ff 14 85 a8 72 10 f0 	call   *-0xfef8d58(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100aa1:	85 c0                	test   %eax,%eax
f0100aa3:	78 25                	js     f0100aca <monitor+0x13f>
f0100aa5:	e9 13 ff ff ff       	jmp    f01009bd <monitor+0x32>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100aaa:	83 c3 01             	add    $0x1,%ebx
f0100aad:	83 fb 03             	cmp    $0x3,%ebx
f0100ab0:	75 b7                	jne    f0100a69 <monitor+0xde>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100ab2:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100ab5:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ab9:	c7 04 24 eb 70 10 f0 	movl   $0xf01070eb,(%esp)
f0100ac0:	e8 64 34 00 00       	call   f0103f29 <cprintf>
f0100ac5:	e9 f3 fe ff ff       	jmp    f01009bd <monitor+0x32>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100aca:	83 c4 5c             	add    $0x5c,%esp
f0100acd:	5b                   	pop    %ebx
f0100ace:	5e                   	pop    %esi
f0100acf:	5f                   	pop    %edi
f0100ad0:	5d                   	pop    %ebp
f0100ad1:	c3                   	ret    
f0100ad2:	66 90                	xchg   %ax,%ax
f0100ad4:	66 90                	xchg   %ax,%ax
f0100ad6:	66 90                	xchg   %ax,%ax
f0100ad8:	66 90                	xchg   %ax,%ax
f0100ada:	66 90                	xchg   %ax,%ax
f0100adc:	66 90                	xchg   %ax,%ax
f0100ade:	66 90                	xchg   %ax,%ax

f0100ae0 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100ae0:	55                   	push   %ebp
f0100ae1:	89 e5                	mov    %esp,%ebp
f0100ae3:	56                   	push   %esi
f0100ae4:	53                   	push   %ebx
f0100ae5:	83 ec 10             	sub    $0x10,%esp
f0100ae8:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100aea:	89 04 24             	mov    %eax,(%esp)
f0100aed:	e8 ce 32 00 00       	call   f0103dc0 <mc146818_read>
f0100af2:	89 c6                	mov    %eax,%esi
f0100af4:	83 c3 01             	add    $0x1,%ebx
f0100af7:	89 1c 24             	mov    %ebx,(%esp)
f0100afa:	e8 c1 32 00 00       	call   f0103dc0 <mc146818_read>
f0100aff:	c1 e0 08             	shl    $0x8,%eax
f0100b02:	09 f0                	or     %esi,%eax
}
f0100b04:	83 c4 10             	add    $0x10,%esp
f0100b07:	5b                   	pop    %ebx
f0100b08:	5e                   	pop    %esi
f0100b09:	5d                   	pop    %ebp
f0100b0a:	c3                   	ret    

f0100b0b <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100b0b:	83 3d 38 12 23 f0 00 	cmpl   $0x0,0xf0231238
f0100b12:	75 11                	jne    f0100b25 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100b14:	ba 07 40 27 f0       	mov    $0xf0274007,%edx
f0100b19:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100b1f:	89 15 38 12 23 f0    	mov    %edx,0xf0231238
	//
	// LAB 2: Your code here.
	
	
	
	if(n>0)
f0100b25:	85 c0                	test   %eax,%eax
f0100b27:	74 2e                	je     f0100b57 <boot_alloc+0x4c>
	{
	result=nextfree;
f0100b29:	8b 0d 38 12 23 f0    	mov    0xf0231238,%ecx
	nextfree +=ROUNDUP(n, PGSIZE);
f0100b2f:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100b35:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100b3b:	01 ca                	add    %ecx,%edx
f0100b3d:	89 15 38 12 23 f0    	mov    %edx,0xf0231238
	else
	{
	return nextfree;	
    }
    
    if ((uint32_t) nextfree> ((npages * PGSIZE)+KERNBASE))
f0100b43:	a1 88 1e 23 f0       	mov    0xf0231e88,%eax
f0100b48:	05 00 00 0f 00       	add    $0xf0000,%eax
f0100b4d:	c1 e0 0c             	shl    $0xc,%eax
f0100b50:	39 c2                	cmp    %eax,%edx
f0100b52:	77 09                	ja     f0100b5d <boot_alloc+0x52>
    {
    panic("Out of memory \n");
    }

	return result;
f0100b54:	89 c8                	mov    %ecx,%eax
f0100b56:	c3                   	ret    
	nextfree +=ROUNDUP(n, PGSIZE);
	
	}
	else
	{
	return nextfree;	
f0100b57:	a1 38 12 23 f0       	mov    0xf0231238,%eax
f0100b5c:	c3                   	ret    
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100b5d:	55                   	push   %ebp
f0100b5e:	89 e5                	mov    %esp,%ebp
f0100b60:	83 ec 18             	sub    $0x18,%esp
	return nextfree;	
    }
    
    if ((uint32_t) nextfree> ((npages * PGSIZE)+KERNBASE))
    {
    panic("Out of memory \n");
f0100b63:	c7 44 24 08 c4 72 10 	movl   $0xf01072c4,0x8(%esp)
f0100b6a:	f0 
f0100b6b:	c7 44 24 04 7c 00 00 	movl   $0x7c,0x4(%esp)
f0100b72:	00 
f0100b73:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0100b7a:	e8 c1 f4 ff ff       	call   f0100040 <_panic>

f0100b7f <page2kva>:
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b7f:	2b 05 90 1e 23 f0    	sub    0xf0231e90,%eax
f0100b85:	c1 f8 03             	sar    $0x3,%eax
f0100b88:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b8b:	89 c2                	mov    %eax,%edx
f0100b8d:	c1 ea 0c             	shr    $0xc,%edx
f0100b90:	3b 15 88 1e 23 f0    	cmp    0xf0231e88,%edx
f0100b96:	72 26                	jb     f0100bbe <page2kva+0x3f>
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0100b98:	55                   	push   %ebp
f0100b99:	89 e5                	mov    %esp,%ebp
f0100b9b:	83 ec 18             	sub    $0x18,%esp

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b9e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ba2:	c7 44 24 08 44 6d 10 	movl   $0xf0106d44,0x8(%esp)
f0100ba9:	f0 
f0100baa:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0100bb1:	00 
f0100bb2:	c7 04 24 e0 72 10 f0 	movl   $0xf01072e0,(%esp)
f0100bb9:	e8 82 f4 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0100bbe:	2d 00 00 00 10       	sub    $0x10000000,%eax

static inline void*
page2kva(struct PageInfo *pp)
{
	return KADDR(page2pa(pp));
}
f0100bc3:	c3                   	ret    

f0100bc4 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100bc4:	89 d1                	mov    %edx,%ecx
f0100bc6:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100bc9:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100bcc:	a8 01                	test   $0x1,%al
f0100bce:	74 5d                	je     f0100c2d <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100bd0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100bd5:	89 c1                	mov    %eax,%ecx
f0100bd7:	c1 e9 0c             	shr    $0xc,%ecx
f0100bda:	3b 0d 88 1e 23 f0    	cmp    0xf0231e88,%ecx
f0100be0:	72 26                	jb     f0100c08 <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100be2:	55                   	push   %ebp
f0100be3:	89 e5                	mov    %esp,%ebp
f0100be5:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100be8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100bec:	c7 44 24 08 44 6d 10 	movl   $0xf0106d44,0x8(%esp)
f0100bf3:	f0 
f0100bf4:	c7 44 24 04 9f 03 00 	movl   $0x39f,0x4(%esp)
f0100bfb:	00 
f0100bfc:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0100c03:	e8 38 f4 ff ff       	call   f0100040 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100c08:	c1 ea 0c             	shr    $0xc,%edx
f0100c0b:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100c11:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100c18:	89 c2                	mov    %eax,%edx
f0100c1a:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100c1d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100c22:	85 d2                	test   %edx,%edx
f0100c24:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100c29:	0f 44 c2             	cmove  %edx,%eax
f0100c2c:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100c2d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100c32:	c3                   	ret    

f0100c33 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100c33:	55                   	push   %ebp
f0100c34:	89 e5                	mov    %esp,%ebp
f0100c36:	57                   	push   %edi
f0100c37:	56                   	push   %esi
f0100c38:	53                   	push   %ebx
f0100c39:	83 ec 4c             	sub    $0x4c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c3c:	84 c0                	test   %al,%al
f0100c3e:	0f 85 3f 03 00 00    	jne    f0100f83 <check_page_free_list+0x350>
f0100c44:	e9 4c 03 00 00       	jmp    f0100f95 <check_page_free_list+0x362>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100c49:	c7 44 24 08 0c 76 10 	movl   $0xf010760c,0x8(%esp)
f0100c50:	f0 
f0100c51:	c7 44 24 04 d2 02 00 	movl   $0x2d2,0x4(%esp)
f0100c58:	00 
f0100c59:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0100c60:	e8 db f3 ff ff       	call   f0100040 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100c65:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100c68:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100c6b:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c6e:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c71:	89 c2                	mov    %eax,%edx
f0100c73:	2b 15 90 1e 23 f0    	sub    0xf0231e90,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100c79:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100c7f:	0f 95 c2             	setne  %dl
f0100c82:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100c85:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100c89:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100c8b:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c8f:	8b 00                	mov    (%eax),%eax
f0100c91:	85 c0                	test   %eax,%eax
f0100c93:	75 dc                	jne    f0100c71 <check_page_free_list+0x3e>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100c95:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c98:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100c9e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ca1:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100ca4:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100ca6:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ca9:	a3 40 12 23 f0       	mov    %eax,0xf0231240
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100cae:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100cb3:	8b 1d 40 12 23 f0    	mov    0xf0231240,%ebx
f0100cb9:	eb 63                	jmp    f0100d1e <check_page_free_list+0xeb>
f0100cbb:	89 d8                	mov    %ebx,%eax
f0100cbd:	2b 05 90 1e 23 f0    	sub    0xf0231e90,%eax
f0100cc3:	c1 f8 03             	sar    $0x3,%eax
f0100cc6:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100cc9:	89 c2                	mov    %eax,%edx
f0100ccb:	c1 ea 16             	shr    $0x16,%edx
f0100cce:	39 f2                	cmp    %esi,%edx
f0100cd0:	73 4a                	jae    f0100d1c <check_page_free_list+0xe9>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100cd2:	89 c2                	mov    %eax,%edx
f0100cd4:	c1 ea 0c             	shr    $0xc,%edx
f0100cd7:	3b 15 88 1e 23 f0    	cmp    0xf0231e88,%edx
f0100cdd:	72 20                	jb     f0100cff <check_page_free_list+0xcc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100cdf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ce3:	c7 44 24 08 44 6d 10 	movl   $0xf0106d44,0x8(%esp)
f0100cea:	f0 
f0100ceb:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0100cf2:	00 
f0100cf3:	c7 04 24 e0 72 10 f0 	movl   $0xf01072e0,(%esp)
f0100cfa:	e8 41 f3 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100cff:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100d06:	00 
f0100d07:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100d0e:	00 
	return (void *)(pa + KERNBASE);
f0100d0f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d14:	89 04 24             	mov    %eax,(%esp)
f0100d17:	e8 db 52 00 00       	call   f0105ff7 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100d1c:	8b 1b                	mov    (%ebx),%ebx
f0100d1e:	85 db                	test   %ebx,%ebx
f0100d20:	75 99                	jne    f0100cbb <check_page_free_list+0x88>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100d22:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d27:	e8 df fd ff ff       	call   f0100b0b <boot_alloc>
f0100d2c:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d2f:	8b 15 40 12 23 f0    	mov    0xf0231240,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100d35:	8b 0d 90 1e 23 f0    	mov    0xf0231e90,%ecx
		assert(pp < pages + npages);
f0100d3b:	a1 88 1e 23 f0       	mov    0xf0231e88,%eax
f0100d40:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100d43:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100d46:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100d49:	89 4d cc             	mov    %ecx,-0x34(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100d4c:	bf 00 00 00 00       	mov    $0x0,%edi
f0100d51:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d54:	e9 c4 01 00 00       	jmp    f0100f1d <check_page_free_list+0x2ea>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100d59:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100d5c:	73 24                	jae    f0100d82 <check_page_free_list+0x14f>
f0100d5e:	c7 44 24 0c ee 72 10 	movl   $0xf01072ee,0xc(%esp)
f0100d65:	f0 
f0100d66:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0100d6d:	f0 
f0100d6e:	c7 44 24 04 ec 02 00 	movl   $0x2ec,0x4(%esp)
f0100d75:	00 
f0100d76:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0100d7d:	e8 be f2 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100d82:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0100d85:	72 24                	jb     f0100dab <check_page_free_list+0x178>
f0100d87:	c7 44 24 0c 0f 73 10 	movl   $0xf010730f,0xc(%esp)
f0100d8e:	f0 
f0100d8f:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0100d96:	f0 
f0100d97:	c7 44 24 04 ed 02 00 	movl   $0x2ed,0x4(%esp)
f0100d9e:	00 
f0100d9f:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0100da6:	e8 95 f2 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100dab:	89 d0                	mov    %edx,%eax
f0100dad:	2b 45 cc             	sub    -0x34(%ebp),%eax
f0100db0:	a8 07                	test   $0x7,%al
f0100db2:	74 24                	je     f0100dd8 <check_page_free_list+0x1a5>
f0100db4:	c7 44 24 0c 30 76 10 	movl   $0xf0107630,0xc(%esp)
f0100dbb:	f0 
f0100dbc:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0100dc3:	f0 
f0100dc4:	c7 44 24 04 ee 02 00 	movl   $0x2ee,0x4(%esp)
f0100dcb:	00 
f0100dcc:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0100dd3:	e8 68 f2 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100dd8:	c1 f8 03             	sar    $0x3,%eax
f0100ddb:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100dde:	85 c0                	test   %eax,%eax
f0100de0:	75 24                	jne    f0100e06 <check_page_free_list+0x1d3>
f0100de2:	c7 44 24 0c 23 73 10 	movl   $0xf0107323,0xc(%esp)
f0100de9:	f0 
f0100dea:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0100df1:	f0 
f0100df2:	c7 44 24 04 f1 02 00 	movl   $0x2f1,0x4(%esp)
f0100df9:	00 
f0100dfa:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0100e01:	e8 3a f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100e06:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100e0b:	75 24                	jne    f0100e31 <check_page_free_list+0x1fe>
f0100e0d:	c7 44 24 0c 34 73 10 	movl   $0xf0107334,0xc(%esp)
f0100e14:	f0 
f0100e15:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0100e1c:	f0 
f0100e1d:	c7 44 24 04 f2 02 00 	movl   $0x2f2,0x4(%esp)
f0100e24:	00 
f0100e25:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0100e2c:	e8 0f f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100e31:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100e36:	75 24                	jne    f0100e5c <check_page_free_list+0x229>
f0100e38:	c7 44 24 0c 64 76 10 	movl   $0xf0107664,0xc(%esp)
f0100e3f:	f0 
f0100e40:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0100e47:	f0 
f0100e48:	c7 44 24 04 f3 02 00 	movl   $0x2f3,0x4(%esp)
f0100e4f:	00 
f0100e50:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0100e57:	e8 e4 f1 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100e5c:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100e61:	75 24                	jne    f0100e87 <check_page_free_list+0x254>
f0100e63:	c7 44 24 0c 4d 73 10 	movl   $0xf010734d,0xc(%esp)
f0100e6a:	f0 
f0100e6b:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0100e72:	f0 
f0100e73:	c7 44 24 04 f4 02 00 	movl   $0x2f4,0x4(%esp)
f0100e7a:	00 
f0100e7b:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0100e82:	e8 b9 f1 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100e87:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100e8c:	0f 86 2a 01 00 00    	jbe    f0100fbc <check_page_free_list+0x389>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e92:	89 c1                	mov    %eax,%ecx
f0100e94:	c1 e9 0c             	shr    $0xc,%ecx
f0100e97:	39 4d c4             	cmp    %ecx,-0x3c(%ebp)
f0100e9a:	77 20                	ja     f0100ebc <check_page_free_list+0x289>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e9c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ea0:	c7 44 24 08 44 6d 10 	movl   $0xf0106d44,0x8(%esp)
f0100ea7:	f0 
f0100ea8:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0100eaf:	00 
f0100eb0:	c7 04 24 e0 72 10 f0 	movl   $0xf01072e0,(%esp)
f0100eb7:	e8 84 f1 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0100ebc:	8d 88 00 00 00 f0    	lea    -0x10000000(%eax),%ecx
f0100ec2:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0100ec5:	0f 86 e1 00 00 00    	jbe    f0100fac <check_page_free_list+0x379>
f0100ecb:	c7 44 24 0c 88 76 10 	movl   $0xf0107688,0xc(%esp)
f0100ed2:	f0 
f0100ed3:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0100eda:	f0 
f0100edb:	c7 44 24 04 f5 02 00 	movl   $0x2f5,0x4(%esp)
f0100ee2:	00 
f0100ee3:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0100eea:	e8 51 f1 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100eef:	c7 44 24 0c 67 73 10 	movl   $0xf0107367,0xc(%esp)
f0100ef6:	f0 
f0100ef7:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0100efe:	f0 
f0100eff:	c7 44 24 04 f7 02 00 	movl   $0x2f7,0x4(%esp)
f0100f06:	00 
f0100f07:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0100f0e:	e8 2d f1 ff ff       	call   f0100040 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100f13:	83 c3 01             	add    $0x1,%ebx
f0100f16:	eb 03                	jmp    f0100f1b <check_page_free_list+0x2e8>
		else
			++nfree_extmem;
f0100f18:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100f1b:	8b 12                	mov    (%edx),%edx
f0100f1d:	85 d2                	test   %edx,%edx
f0100f1f:	0f 85 34 fe ff ff    	jne    f0100d59 <check_page_free_list+0x126>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100f25:	85 db                	test   %ebx,%ebx
f0100f27:	7f 24                	jg     f0100f4d <check_page_free_list+0x31a>
f0100f29:	c7 44 24 0c 84 73 10 	movl   $0xf0107384,0xc(%esp)
f0100f30:	f0 
f0100f31:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0100f38:	f0 
f0100f39:	c7 44 24 04 ff 02 00 	movl   $0x2ff,0x4(%esp)
f0100f40:	00 
f0100f41:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0100f48:	e8 f3 f0 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100f4d:	85 ff                	test   %edi,%edi
f0100f4f:	7f 24                	jg     f0100f75 <check_page_free_list+0x342>
f0100f51:	c7 44 24 0c 96 73 10 	movl   $0xf0107396,0xc(%esp)
f0100f58:	f0 
f0100f59:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0100f60:	f0 
f0100f61:	c7 44 24 04 00 03 00 	movl   $0x300,0x4(%esp)
f0100f68:	00 
f0100f69:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0100f70:	e8 cb f0 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_free_list() succeeded!\n");
f0100f75:	c7 04 24 d0 76 10 f0 	movl   $0xf01076d0,(%esp)
f0100f7c:	e8 a8 2f 00 00       	call   f0103f29 <cprintf>
f0100f81:	eb 49                	jmp    f0100fcc <check_page_free_list+0x399>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100f83:	a1 40 12 23 f0       	mov    0xf0231240,%eax
f0100f88:	85 c0                	test   %eax,%eax
f0100f8a:	0f 85 d5 fc ff ff    	jne    f0100c65 <check_page_free_list+0x32>
f0100f90:	e9 b4 fc ff ff       	jmp    f0100c49 <check_page_free_list+0x16>
f0100f95:	83 3d 40 12 23 f0 00 	cmpl   $0x0,0xf0231240
f0100f9c:	0f 84 a7 fc ff ff    	je     f0100c49 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100fa2:	be 00 04 00 00       	mov    $0x400,%esi
f0100fa7:	e9 07 fd ff ff       	jmp    f0100cb3 <check_page_free_list+0x80>
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100fac:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100fb1:	0f 85 61 ff ff ff    	jne    f0100f18 <check_page_free_list+0x2e5>
f0100fb7:	e9 33 ff ff ff       	jmp    f0100eef <check_page_free_list+0x2bc>
f0100fbc:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100fc1:	0f 85 4c ff ff ff    	jne    f0100f13 <check_page_free_list+0x2e0>
f0100fc7:	e9 23 ff ff ff       	jmp    f0100eef <check_page_free_list+0x2bc>

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);

	cprintf("check_page_free_list() succeeded!\n");
}
f0100fcc:	83 c4 4c             	add    $0x4c,%esp
f0100fcf:	5b                   	pop    %ebx
f0100fd0:	5e                   	pop    %esi
f0100fd1:	5f                   	pop    %edi
f0100fd2:	5d                   	pop    %ebp
f0100fd3:	c3                   	ret    

f0100fd4 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100fd4:	55                   	push   %ebp
f0100fd5:	89 e5                	mov    %esp,%ebp
f0100fd7:	53                   	push   %ebx
f0100fd8:	83 ec 04             	sub    $0x4,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100fdb:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100fe0:	eb 52                	jmp    f0101034 <page_init+0x60>
	if(i==0 ||(i>=(IOPHYSMEM/PGSIZE)&&i<=(((uint32_t)boot_alloc(0)-KERNBASE)/PGSIZE))||i==MPENTRY_PADDR/PGSIZE)
f0100fe2:	85 db                	test   %ebx,%ebx
f0100fe4:	74 4b                	je     f0101031 <page_init+0x5d>
f0100fe6:	81 fb 9f 00 00 00    	cmp    $0x9f,%ebx
f0100fec:	76 16                	jbe    f0101004 <page_init+0x30>
f0100fee:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ff3:	e8 13 fb ff ff       	call   f0100b0b <boot_alloc>
f0100ff8:	05 00 00 00 10       	add    $0x10000000,%eax
f0100ffd:	c1 e8 0c             	shr    $0xc,%eax
f0101000:	39 c3                	cmp    %eax,%ebx
f0101002:	76 2d                	jbe    f0101031 <page_init+0x5d>
f0101004:	83 fb 07             	cmp    $0x7,%ebx
f0101007:	74 28                	je     f0101031 <page_init+0x5d>
f0101009:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
	continue;

		pages[i].pp_ref = 0;
f0101010:	89 c2                	mov    %eax,%edx
f0101012:	03 15 90 1e 23 f0    	add    0xf0231e90,%edx
f0101018:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
		pages[i].pp_link = page_free_list;
f010101e:	8b 0d 40 12 23 f0    	mov    0xf0231240,%ecx
f0101024:	89 0a                	mov    %ecx,(%edx)
		page_free_list = &pages[i];
f0101026:	03 05 90 1e 23 f0    	add    0xf0231e90,%eax
f010102c:	a3 40 12 23 f0       	mov    %eax,0xf0231240
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0101031:	83 c3 01             	add    $0x1,%ebx
f0101034:	3b 1d 88 1e 23 f0    	cmp    0xf0231e88,%ebx
f010103a:	72 a6                	jb     f0100fe2 <page_init+0xe>
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	
	}
}
f010103c:	83 c4 04             	add    $0x4,%esp
f010103f:	5b                   	pop    %ebx
f0101040:	5d                   	pop    %ebp
f0101041:	c3                   	ret    

f0101042 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0101042:	55                   	push   %ebp
f0101043:	89 e5                	mov    %esp,%ebp
f0101045:	53                   	push   %ebx
f0101046:	83 ec 14             	sub    $0x14,%esp
	struct PageInfo *tempage;
	
	if (page_free_list == NULL)
f0101049:	8b 1d 40 12 23 f0    	mov    0xf0231240,%ebx
f010104f:	85 db                	test   %ebx,%ebx
f0101051:	74 6f                	je     f01010c2 <page_alloc+0x80>
		return NULL;

  	tempage= page_free_list;
  	page_free_list = tempage->pp_link;
f0101053:	8b 03                	mov    (%ebx),%eax
f0101055:	a3 40 12 23 f0       	mov    %eax,0xf0231240
  	tempage->pp_link = NULL;
f010105a:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)

	if (alloc_flags & ALLOC_ZERO)
		memset(page2kva(tempage), 0, PGSIZE); 

  	return tempage;
f0101060:	89 d8                	mov    %ebx,%eax

  	tempage= page_free_list;
  	page_free_list = tempage->pp_link;
  	tempage->pp_link = NULL;

	if (alloc_flags & ALLOC_ZERO)
f0101062:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0101066:	74 5f                	je     f01010c7 <page_alloc+0x85>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101068:	2b 05 90 1e 23 f0    	sub    0xf0231e90,%eax
f010106e:	c1 f8 03             	sar    $0x3,%eax
f0101071:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101074:	89 c2                	mov    %eax,%edx
f0101076:	c1 ea 0c             	shr    $0xc,%edx
f0101079:	3b 15 88 1e 23 f0    	cmp    0xf0231e88,%edx
f010107f:	72 20                	jb     f01010a1 <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101081:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101085:	c7 44 24 08 44 6d 10 	movl   $0xf0106d44,0x8(%esp)
f010108c:	f0 
f010108d:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0101094:	00 
f0101095:	c7 04 24 e0 72 10 f0 	movl   $0xf01072e0,(%esp)
f010109c:	e8 9f ef ff ff       	call   f0100040 <_panic>
		memset(page2kva(tempage), 0, PGSIZE); 
f01010a1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01010a8:	00 
f01010a9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01010b0:	00 
	return (void *)(pa + KERNBASE);
f01010b1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01010b6:	89 04 24             	mov    %eax,(%esp)
f01010b9:	e8 39 4f 00 00       	call   f0105ff7 <memset>

  	return tempage;
f01010be:	89 d8                	mov    %ebx,%eax
f01010c0:	eb 05                	jmp    f01010c7 <page_alloc+0x85>
page_alloc(int alloc_flags)
{
	struct PageInfo *tempage;
	
	if (page_free_list == NULL)
		return NULL;
f01010c2:	b8 00 00 00 00       	mov    $0x0,%eax
	if (alloc_flags & ALLOC_ZERO)
		memset(page2kva(tempage), 0, PGSIZE); 

  	return tempage;
	
}
f01010c7:	83 c4 14             	add    $0x14,%esp
f01010ca:	5b                   	pop    %ebx
f01010cb:	5d                   	pop    %ebp
f01010cc:	c3                   	ret    

f01010cd <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f01010cd:	55                   	push   %ebp
f01010ce:	89 e5                	mov    %esp,%ebp
f01010d0:	83 ec 18             	sub    $0x18,%esp
f01010d3:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if(pp->pp_ref==0)
f01010d6:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f01010db:	75 0f                	jne    f01010ec <page_free+0x1f>
	{
	pp->pp_link=page_free_list;
f01010dd:	8b 15 40 12 23 f0    	mov    0xf0231240,%edx
f01010e3:	89 10                	mov    %edx,(%eax)
	page_free_list=pp;	
f01010e5:	a3 40 12 23 f0       	mov    %eax,0xf0231240
f01010ea:	eb 1c                	jmp    f0101108 <page_free+0x3b>
	}
	else
	panic("page ref not zero \n");
f01010ec:	c7 44 24 08 a7 73 10 	movl   $0xf01073a7,0x8(%esp)
f01010f3:	f0 
f01010f4:	c7 44 24 04 93 01 00 	movl   $0x193,0x4(%esp)
f01010fb:	00 
f01010fc:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0101103:	e8 38 ef ff ff       	call   f0100040 <_panic>
}
f0101108:	c9                   	leave  
f0101109:	c3                   	ret    

f010110a <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f010110a:	55                   	push   %ebp
f010110b:	89 e5                	mov    %esp,%ebp
f010110d:	83 ec 18             	sub    $0x18,%esp
f0101110:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0101113:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f0101117:	8d 51 ff             	lea    -0x1(%ecx),%edx
f010111a:	66 89 50 04          	mov    %dx,0x4(%eax)
f010111e:	66 85 d2             	test   %dx,%dx
f0101121:	75 08                	jne    f010112b <page_decref+0x21>
		page_free(pp);
f0101123:	89 04 24             	mov    %eax,(%esp)
f0101126:	e8 a2 ff ff ff       	call   f01010cd <page_free>
}
f010112b:	c9                   	leave  
f010112c:	c3                   	ret    

f010112d <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f010112d:	55                   	push   %ebp
f010112e:	89 e5                	mov    %esp,%ebp
f0101130:	57                   	push   %edi
f0101131:	56                   	push   %esi
f0101132:	53                   	push   %ebx
f0101133:	83 ec 1c             	sub    $0x1c,%esp
f0101136:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	  pde_t * pde; //va(virtual address) point to pa(physical address)
	  pte_t * pgtable; //same as pde
	  struct PageInfo *pp;

	  pde = &pgdir[PDX(va)]; // va->pgdir
f0101139:	89 de                	mov    %ebx,%esi
f010113b:	c1 ee 16             	shr    $0x16,%esi
f010113e:	c1 e6 02             	shl    $0x2,%esi
f0101141:	03 75 08             	add    0x8(%ebp),%esi
	  if(*pde & PTE_P) { 
f0101144:	8b 06                	mov    (%esi),%eax
f0101146:	a8 01                	test   $0x1,%al
f0101148:	74 3d                	je     f0101187 <pgdir_walk+0x5a>
	  	pgtable = (KADDR(PTE_ADDR(*pde)));
f010114a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010114f:	89 c2                	mov    %eax,%edx
f0101151:	c1 ea 0c             	shr    $0xc,%edx
f0101154:	3b 15 88 1e 23 f0    	cmp    0xf0231e88,%edx
f010115a:	72 20                	jb     f010117c <pgdir_walk+0x4f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010115c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101160:	c7 44 24 08 44 6d 10 	movl   $0xf0106d44,0x8(%esp)
f0101167:	f0 
f0101168:	c7 44 24 04 c0 01 00 	movl   $0x1c0,0x4(%esp)
f010116f:	00 
f0101170:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0101177:	e8 c4 ee ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f010117c:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx
f0101182:	e9 97 00 00 00       	jmp    f010121e <pgdir_walk+0xf1>
	  } else {
		//page table page not exist
		if(!create || 
f0101187:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010118b:	0f 84 9b 00 00 00    	je     f010122c <pgdir_walk+0xff>
f0101191:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101198:	e8 a5 fe ff ff       	call   f0101042 <page_alloc>
f010119d:	85 c0                	test   %eax,%eax
f010119f:	0f 84 8e 00 00 00    	je     f0101233 <pgdir_walk+0x106>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01011a5:	89 c1                	mov    %eax,%ecx
f01011a7:	2b 0d 90 1e 23 f0    	sub    0xf0231e90,%ecx
f01011ad:	c1 f9 03             	sar    $0x3,%ecx
f01011b0:	c1 e1 0c             	shl    $0xc,%ecx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01011b3:	89 ca                	mov    %ecx,%edx
f01011b5:	c1 ea 0c             	shr    $0xc,%edx
f01011b8:	3b 15 88 1e 23 f0    	cmp    0xf0231e88,%edx
f01011be:	72 20                	jb     f01011e0 <pgdir_walk+0xb3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01011c0:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01011c4:	c7 44 24 08 44 6d 10 	movl   $0xf0106d44,0x8(%esp)
f01011cb:	f0 
f01011cc:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f01011d3:	00 
f01011d4:	c7 04 24 e0 72 10 f0 	movl   $0xf01072e0,(%esp)
f01011db:	e8 60 ee ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01011e0:	8d b9 00 00 00 f0    	lea    -0x10000000(%ecx),%edi
f01011e6:	89 fa                	mov    %edi,%edx
		   !(pp = page_alloc(ALLOC_ZERO)) ||
f01011e8:	85 ff                	test   %edi,%edi
f01011ea:	74 4e                	je     f010123a <pgdir_walk+0x10d>
		   !(pgtable = (pte_t*)page2kva(pp))) 
			return NULL;
		    
		pp->pp_ref++;
f01011ec:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01011f1:	81 ff ff ff ff ef    	cmp    $0xefffffff,%edi
f01011f7:	77 20                	ja     f0101219 <pgdir_walk+0xec>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01011f9:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01011fd:	c7 44 24 08 68 6d 10 	movl   $0xf0106d68,0x8(%esp)
f0101204:	f0 
f0101205:	c7 44 24 04 c9 01 00 	movl   $0x1c9,0x4(%esp)
f010120c:	00 
f010120d:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0101214:	e8 27 ee ff ff       	call   f0100040 <_panic>
		*pde = PADDR(pgtable) | PTE_P | PTE_W | PTE_U;
f0101219:	83 c9 07             	or     $0x7,%ecx
f010121c:	89 0e                	mov    %ecx,(%esi)
	}

	return &pgtable[PTX(va)];
f010121e:	c1 eb 0a             	shr    $0xa,%ebx
f0101221:	89 d8                	mov    %ebx,%eax
f0101223:	25 fc 0f 00 00       	and    $0xffc,%eax
f0101228:	01 d0                	add    %edx,%eax
f010122a:	eb 13                	jmp    f010123f <pgdir_walk+0x112>
	  } else {
		//page table page not exist
		if(!create || 
		   !(pp = page_alloc(ALLOC_ZERO)) ||
		   !(pgtable = (pte_t*)page2kva(pp))) 
			return NULL;
f010122c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101231:	eb 0c                	jmp    f010123f <pgdir_walk+0x112>
f0101233:	b8 00 00 00 00       	mov    $0x0,%eax
f0101238:	eb 05                	jmp    f010123f <pgdir_walk+0x112>
f010123a:	b8 00 00 00 00       	mov    $0x0,%eax
		pp->pp_ref++;
		*pde = PADDR(pgtable) | PTE_P | PTE_W | PTE_U;
	}

	return &pgtable[PTX(va)];
}
f010123f:	83 c4 1c             	add    $0x1c,%esp
f0101242:	5b                   	pop    %ebx
f0101243:	5e                   	pop    %esi
f0101244:	5f                   	pop    %edi
f0101245:	5d                   	pop    %ebp
f0101246:	c3                   	ret    

f0101247 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0101247:	55                   	push   %ebp
f0101248:	89 e5                	mov    %esp,%ebp
f010124a:	57                   	push   %edi
f010124b:	56                   	push   %esi
f010124c:	53                   	push   %ebx
f010124d:	83 ec 2c             	sub    $0x2c,%esp
f0101250:	89 45 dc             	mov    %eax,-0x24(%ebp)
	uint32_t x;
	uint32_t i=0;
	pte_t * pt; 
	x=size/PGSIZE;
f0101253:	c1 e9 0c             	shr    $0xc,%ecx
f0101256:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	while(i<x)
f0101259:	89 d3                	mov    %edx,%ebx
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	uint32_t x;
	uint32_t i=0;
f010125b:	be 00 00 00 00       	mov    $0x0,%esi
f0101260:	8b 45 08             	mov    0x8(%ebp),%eax
f0101263:	29 d0                	sub    %edx,%eax
f0101265:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pte_t * pt; 
	x=size/PGSIZE;
	while(i<x)
	{
		pt=pgdir_walk(pgdir,(void*)va,1);
		*pt=(PTE_ADDR(pa) | perm | PTE_P);
f0101268:	8b 45 0c             	mov    0xc(%ebp),%eax
f010126b:	83 c8 01             	or     $0x1,%eax
f010126e:	89 45 d8             	mov    %eax,-0x28(%ebp)
{
	uint32_t x;
	uint32_t i=0;
	pte_t * pt; 
	x=size/PGSIZE;
	while(i<x)
f0101271:	eb 2b                	jmp    f010129e <boot_map_region+0x57>
	{
		pt=pgdir_walk(pgdir,(void*)va,1);
f0101273:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010127a:	00 
f010127b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010127f:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101282:	89 04 24             	mov    %eax,(%esp)
f0101285:	e8 a3 fe ff ff       	call   f010112d <pgdir_walk>
		*pt=(PTE_ADDR(pa) | perm | PTE_P);
f010128a:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
f0101290:	0b 7d d8             	or     -0x28(%ebp),%edi
f0101293:	89 38                	mov    %edi,(%eax)
		va+=PGSIZE;
f0101295:	81 c3 00 10 00 00    	add    $0x1000,%ebx
		pa+=PGSIZE;
		i++;
f010129b:	83 c6 01             	add    $0x1,%esi
f010129e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01012a1:	8d 3c 18             	lea    (%eax,%ebx,1),%edi
{
	uint32_t x;
	uint32_t i=0;
	pte_t * pt; 
	x=size/PGSIZE;
	while(i<x)
f01012a4:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f01012a7:	75 ca                	jne    f0101273 <boot_map_region+0x2c>
		va+=PGSIZE;
		pa+=PGSIZE;
		i++;
	}
	// Fill this function in
}
f01012a9:	83 c4 2c             	add    $0x2c,%esp
f01012ac:	5b                   	pop    %ebx
f01012ad:	5e                   	pop    %esi
f01012ae:	5f                   	pop    %edi
f01012af:	5d                   	pop    %ebp
f01012b0:	c3                   	ret    

f01012b1 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01012b1:	55                   	push   %ebp
f01012b2:	89 e5                	mov    %esp,%ebp
f01012b4:	83 ec 18             	sub    $0x18,%esp
	pte_t * pt = pgdir_walk(pgdir, va, 0);
f01012b7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01012be:	00 
f01012bf:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012c2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012c6:	8b 45 08             	mov    0x8(%ebp),%eax
f01012c9:	89 04 24             	mov    %eax,(%esp)
f01012cc:	e8 5c fe ff ff       	call   f010112d <pgdir_walk>
	
	if(pt == NULL)
f01012d1:	85 c0                	test   %eax,%eax
f01012d3:	74 39                	je     f010130e <page_lookup+0x5d>
	return NULL;
	
	*pte_store = pt;
f01012d5:	8b 55 10             	mov    0x10(%ebp),%edx
f01012d8:	89 02                	mov    %eax,(%edx)
	
  return pa2page(PTE_ADDR(*pt));	
f01012da:	8b 00                	mov    (%eax),%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01012dc:	c1 e8 0c             	shr    $0xc,%eax
f01012df:	3b 05 88 1e 23 f0    	cmp    0xf0231e88,%eax
f01012e5:	72 1c                	jb     f0101303 <page_lookup+0x52>
		panic("pa2page called with invalid pa");
f01012e7:	c7 44 24 08 f4 76 10 	movl   $0xf01076f4,0x8(%esp)
f01012ee:	f0 
f01012ef:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
f01012f6:	00 
f01012f7:	c7 04 24 e0 72 10 f0 	movl   $0xf01072e0,(%esp)
f01012fe:	e8 3d ed ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f0101303:	8b 15 90 1e 23 f0    	mov    0xf0231e90,%edx
f0101309:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f010130c:	eb 05                	jmp    f0101313 <page_lookup+0x62>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t * pt = pgdir_walk(pgdir, va, 0);
	
	if(pt == NULL)
	return NULL;
f010130e:	b8 00 00 00 00       	mov    $0x0,%eax
	
	*pte_store = pt;
	
  return pa2page(PTE_ADDR(*pt));	

}
f0101313:	c9                   	leave  
f0101314:	c3                   	ret    

f0101315 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0101315:	55                   	push   %ebp
f0101316:	89 e5                	mov    %esp,%ebp
f0101318:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f010131b:	e8 29 53 00 00       	call   f0106649 <cpunum>
f0101320:	6b c0 74             	imul   $0x74,%eax,%eax
f0101323:	83 b8 28 20 23 f0 00 	cmpl   $0x0,-0xfdcdfd8(%eax)
f010132a:	74 16                	je     f0101342 <tlb_invalidate+0x2d>
f010132c:	e8 18 53 00 00       	call   f0106649 <cpunum>
f0101331:	6b c0 74             	imul   $0x74,%eax,%eax
f0101334:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f010133a:	8b 55 08             	mov    0x8(%ebp),%edx
f010133d:	39 50 78             	cmp    %edx,0x78(%eax)
f0101340:	75 06                	jne    f0101348 <tlb_invalidate+0x33>
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101342:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101345:	0f 01 38             	invlpg (%eax)
		invlpg(va);
}
f0101348:	c9                   	leave  
f0101349:	c3                   	ret    

f010134a <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f010134a:	55                   	push   %ebp
f010134b:	89 e5                	mov    %esp,%ebp
f010134d:	56                   	push   %esi
f010134e:	53                   	push   %ebx
f010134f:	83 ec 20             	sub    $0x20,%esp
f0101352:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101355:	8b 75 0c             	mov    0xc(%ebp),%esi
	struct PageInfo *page = NULL;
	pte_t *pt = NULL;
f0101358:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	if ((page = page_lookup(pgdir, va, &pt)) != NULL){
f010135f:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101362:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101366:	89 74 24 04          	mov    %esi,0x4(%esp)
f010136a:	89 1c 24             	mov    %ebx,(%esp)
f010136d:	e8 3f ff ff ff       	call   f01012b1 <page_lookup>
f0101372:	85 c0                	test   %eax,%eax
f0101374:	74 14                	je     f010138a <page_remove+0x40>
		page_decref(page);
f0101376:	89 04 24             	mov    %eax,(%esp)
f0101379:	e8 8c fd ff ff       	call   f010110a <page_decref>
		tlb_invalidate(pgdir, va);
f010137e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101382:	89 1c 24             	mov    %ebx,(%esp)
f0101385:	e8 8b ff ff ff       	call   f0101315 <tlb_invalidate>
	}
	*pt=0;
f010138a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010138d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
f0101393:	83 c4 20             	add    $0x20,%esp
f0101396:	5b                   	pop    %ebx
f0101397:	5e                   	pop    %esi
f0101398:	5d                   	pop    %ebp
f0101399:	c3                   	ret    

f010139a <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010139a:	55                   	push   %ebp
f010139b:	89 e5                	mov    %esp,%ebp
f010139d:	57                   	push   %edi
f010139e:	56                   	push   %esi
f010139f:	53                   	push   %ebx
f01013a0:	83 ec 1c             	sub    $0x1c,%esp
f01013a3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01013a6:	8b 7d 10             	mov    0x10(%ebp),%edi
pte_t *pte = pgdir_walk(pgdir, va, 1);
f01013a9:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01013b0:	00 
f01013b1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01013b5:	8b 45 08             	mov    0x8(%ebp),%eax
f01013b8:	89 04 24             	mov    %eax,(%esp)
f01013bb:	e8 6d fd ff ff       	call   f010112d <pgdir_walk>
f01013c0:	89 c6                	mov    %eax,%esi
 

    if (pte != NULL) {
f01013c2:	85 c0                	test   %eax,%eax
f01013c4:	74 48                	je     f010140e <page_insert+0x74>
     
        if (*pte & PTE_P)
f01013c6:	f6 00 01             	testb  $0x1,(%eax)
f01013c9:	74 0f                	je     f01013da <page_insert+0x40>
            page_remove(pgdir, va);
f01013cb:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01013cf:	8b 45 08             	mov    0x8(%ebp),%eax
f01013d2:	89 04 24             	mov    %eax,(%esp)
f01013d5:	e8 70 ff ff ff       	call   f010134a <page_remove>
   
       if (page_free_list == pp)
f01013da:	a1 40 12 23 f0       	mov    0xf0231240,%eax
f01013df:	39 d8                	cmp    %ebx,%eax
f01013e1:	75 07                	jne    f01013ea <page_insert+0x50>
            page_free_list = page_free_list->pp_link;
f01013e3:	8b 00                	mov    (%eax),%eax
f01013e5:	a3 40 12 23 f0       	mov    %eax,0xf0231240
    }
    else {
    
            return -E_NO_MEM;
    }
    *pte = page2pa(pp) | perm | PTE_P;
f01013ea:	8b 55 14             	mov    0x14(%ebp),%edx
f01013ed:	83 ca 01             	or     $0x1,%edx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01013f0:	89 d8                	mov    %ebx,%eax
f01013f2:	2b 05 90 1e 23 f0    	sub    0xf0231e90,%eax
f01013f8:	c1 f8 03             	sar    $0x3,%eax
f01013fb:	c1 e0 0c             	shl    $0xc,%eax
f01013fe:	09 d0                	or     %edx,%eax
f0101400:	89 06                	mov    %eax,(%esi)
    pp->pp_ref++;
f0101402:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)

return 0;
f0101407:	b8 00 00 00 00       	mov    $0x0,%eax
f010140c:	eb 05                	jmp    f0101413 <page_insert+0x79>
       if (page_free_list == pp)
            page_free_list = page_free_list->pp_link;
    }
    else {
    
            return -E_NO_MEM;
f010140e:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
    *pte = page2pa(pp) | perm | PTE_P;
    pp->pp_ref++;

return 0;
	
}
f0101413:	83 c4 1c             	add    $0x1c,%esp
f0101416:	5b                   	pop    %ebx
f0101417:	5e                   	pop    %esi
f0101418:	5f                   	pop    %edi
f0101419:	5d                   	pop    %ebp
f010141a:	c3                   	ret    

f010141b <mmio_map_region>:
// location.  Return the base of the reserved region.  size does *not*
// have to be multiple of PGSIZE.
//
void *
mmio_map_region(physaddr_t pa, size_t size)
{
f010141b:	55                   	push   %ebp
f010141c:	89 e5                	mov    %esp,%ebp
f010141e:	53                   	push   %ebx
f010141f:	83 ec 14             	sub    $0x14,%esp
	// okay to simply panic if this happens).
	//
	// Hint: The staff solution uses boot_map_region.
	//
	// Your code here:
	size = ROUNDUP(size, PGSIZE);
f0101422:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101425:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
f010142b:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	if (base + size > MMIOLIM)
f0101431:	8b 15 00 13 12 f0    	mov    0xf0121300,%edx
f0101437:	8d 04 13             	lea    (%ebx,%edx,1),%eax
f010143a:	3d 00 00 c0 ef       	cmp    $0xefc00000,%eax
f010143f:	76 1c                	jbe    f010145d <mmio_map_region+0x42>
		panic("overflow MMIOLIM\n");
f0101441:	c7 44 24 08 bb 73 10 	movl   $0xf01073bb,0x8(%esp)
f0101448:	f0 
f0101449:	c7 44 24 04 80 02 00 	movl   $0x280,0x4(%esp)
f0101450:	00 
f0101451:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0101458:	e8 e3 eb ff ff       	call   f0100040 <_panic>
	boot_map_region(kern_pgdir, base, size, pa, PTE_P|PTE_W|PTE_PCD|PTE_PWT);
f010145d:	c7 44 24 04 1b 00 00 	movl   $0x1b,0x4(%esp)
f0101464:	00 
f0101465:	8b 45 08             	mov    0x8(%ebp),%eax
f0101468:	89 04 24             	mov    %eax,(%esp)
f010146b:	89 d9                	mov    %ebx,%ecx
f010146d:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
f0101472:	e8 d0 fd ff ff       	call   f0101247 <boot_map_region>
	uintptr_t retaddr = base;
f0101477:	a1 00 13 12 f0       	mov    0xf0121300,%eax
	base += size;
f010147c:	01 c3                	add    %eax,%ebx
f010147e:	89 1d 00 13 12 f0    	mov    %ebx,0xf0121300
return (void *)retaddr;
}
f0101484:	83 c4 14             	add    $0x14,%esp
f0101487:	5b                   	pop    %ebx
f0101488:	5d                   	pop    %ebp
f0101489:	c3                   	ret    

f010148a <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f010148a:	55                   	push   %ebp
f010148b:	89 e5                	mov    %esp,%ebp
f010148d:	57                   	push   %edi
f010148e:	56                   	push   %esi
f010148f:	53                   	push   %ebx
f0101490:	83 ec 4c             	sub    $0x4c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0101493:	b8 15 00 00 00       	mov    $0x15,%eax
f0101498:	e8 43 f6 ff ff       	call   f0100ae0 <nvram_read>
f010149d:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f010149f:	b8 17 00 00 00       	mov    $0x17,%eax
f01014a4:	e8 37 f6 ff ff       	call   f0100ae0 <nvram_read>
f01014a9:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01014ab:	b8 34 00 00 00       	mov    $0x34,%eax
f01014b0:	e8 2b f6 ff ff       	call   f0100ae0 <nvram_read>
f01014b5:	c1 e0 06             	shl    $0x6,%eax
f01014b8:	89 c2                	mov    %eax,%edx

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
		totalmem = 16 * 1024 + ext16mem;
f01014ba:	8d 80 00 40 00 00    	lea    0x4000(%eax),%eax
	extmem = nvram_read(NVRAM_EXTLO);
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f01014c0:	85 d2                	test   %edx,%edx
f01014c2:	75 0b                	jne    f01014cf <mem_init+0x45>
		totalmem = 16 * 1024 + ext16mem;
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f01014c4:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01014ca:	85 f6                	test   %esi,%esi
f01014cc:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f01014cf:	89 c2                	mov    %eax,%edx
f01014d1:	c1 ea 02             	shr    $0x2,%edx
f01014d4:	89 15 88 1e 23 f0    	mov    %edx,0xf0231e88
	npages_basemem = basemem / (PGSIZE / 1024);
f01014da:	89 da                	mov    %ebx,%edx
f01014dc:	c1 ea 02             	shr    $0x2,%edx
f01014df:	89 15 44 12 23 f0    	mov    %edx,0xf0231244
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01014e5:	89 c2                	mov    %eax,%edx
f01014e7:	29 da                	sub    %ebx,%edx
f01014e9:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01014ed:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01014f1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01014f5:	c7 04 24 14 77 10 f0 	movl   $0xf0107714,(%esp)
f01014fc:	e8 28 2a 00 00       	call   f0103f29 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101501:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101506:	e8 00 f6 ff ff       	call   f0100b0b <boot_alloc>
f010150b:	a3 8c 1e 23 f0       	mov    %eax,0xf0231e8c
	memset(kern_pgdir, 0, PGSIZE);
f0101510:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101517:	00 
f0101518:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010151f:	00 
f0101520:	89 04 24             	mov    %eax,(%esp)
f0101523:	e8 cf 4a 00 00       	call   f0105ff7 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101528:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010152d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101532:	77 20                	ja     f0101554 <mem_init+0xca>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101534:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101538:	c7 44 24 08 68 6d 10 	movl   $0xf0106d68,0x8(%esp)
f010153f:	f0 
f0101540:	c7 44 24 04 a3 00 00 	movl   $0xa3,0x4(%esp)
f0101547:	00 
f0101548:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f010154f:	e8 ec ea ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101554:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010155a:	83 ca 05             	or     $0x5,%edx
f010155d:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages=(struct PageInfo *)boot_alloc(sizeof(struct PageInfo)*npages);
f0101563:	a1 88 1e 23 f0       	mov    0xf0231e88,%eax
f0101568:	c1 e0 03             	shl    $0x3,%eax
f010156b:	e8 9b f5 ff ff       	call   f0100b0b <boot_alloc>
f0101570:	a3 90 1e 23 f0       	mov    %eax,0xf0231e90
	memset(pages,0,sizeof(struct PageInfo)*npages);
f0101575:	8b 0d 88 1e 23 f0    	mov    0xf0231e88,%ecx
f010157b:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0101582:	89 54 24 08          	mov    %edx,0x8(%esp)
f0101586:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010158d:	00 
f010158e:	89 04 24             	mov    %eax,(%esp)
f0101591:	e8 61 4a 00 00       	call   f0105ff7 <memset>
	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	
	
	envs=(struct Env *)boot_alloc(sizeof(struct Env)*NENV);
f0101596:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f010159b:	e8 6b f5 ff ff       	call   f0100b0b <boot_alloc>
f01015a0:	a3 48 12 23 f0       	mov    %eax,0xf0231248
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01015a5:	e8 2a fa ff ff       	call   f0100fd4 <page_init>

	check_page_free_list(1);
f01015aa:	b8 01 00 00 00       	mov    $0x1,%eax
f01015af:	e8 7f f6 ff ff       	call   f0100c33 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01015b4:	83 3d 90 1e 23 f0 00 	cmpl   $0x0,0xf0231e90
f01015bb:	75 1c                	jne    f01015d9 <mem_init+0x14f>
		panic("'pages' is a null pointer!");
f01015bd:	c7 44 24 08 cd 73 10 	movl   $0xf01073cd,0x8(%esp)
f01015c4:	f0 
f01015c5:	c7 44 24 04 13 03 00 	movl   $0x313,0x4(%esp)
f01015cc:	00 
f01015cd:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f01015d4:	e8 67 ea ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01015d9:	a1 40 12 23 f0       	mov    0xf0231240,%eax
f01015de:	bb 00 00 00 00       	mov    $0x0,%ebx
f01015e3:	eb 05                	jmp    f01015ea <mem_init+0x160>
		++nfree;
f01015e5:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01015e8:	8b 00                	mov    (%eax),%eax
f01015ea:	85 c0                	test   %eax,%eax
f01015ec:	75 f7                	jne    f01015e5 <mem_init+0x15b>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015ee:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015f5:	e8 48 fa ff ff       	call   f0101042 <page_alloc>
f01015fa:	89 c7                	mov    %eax,%edi
f01015fc:	85 c0                	test   %eax,%eax
f01015fe:	75 24                	jne    f0101624 <mem_init+0x19a>
f0101600:	c7 44 24 0c e8 73 10 	movl   $0xf01073e8,0xc(%esp)
f0101607:	f0 
f0101608:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f010160f:	f0 
f0101610:	c7 44 24 04 1b 03 00 	movl   $0x31b,0x4(%esp)
f0101617:	00 
f0101618:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f010161f:	e8 1c ea ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101624:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010162b:	e8 12 fa ff ff       	call   f0101042 <page_alloc>
f0101630:	89 c6                	mov    %eax,%esi
f0101632:	85 c0                	test   %eax,%eax
f0101634:	75 24                	jne    f010165a <mem_init+0x1d0>
f0101636:	c7 44 24 0c fe 73 10 	movl   $0xf01073fe,0xc(%esp)
f010163d:	f0 
f010163e:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0101645:	f0 
f0101646:	c7 44 24 04 1c 03 00 	movl   $0x31c,0x4(%esp)
f010164d:	00 
f010164e:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0101655:	e8 e6 e9 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f010165a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101661:	e8 dc f9 ff ff       	call   f0101042 <page_alloc>
f0101666:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101669:	85 c0                	test   %eax,%eax
f010166b:	75 24                	jne    f0101691 <mem_init+0x207>
f010166d:	c7 44 24 0c 14 74 10 	movl   $0xf0107414,0xc(%esp)
f0101674:	f0 
f0101675:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f010167c:	f0 
f010167d:	c7 44 24 04 1d 03 00 	movl   $0x31d,0x4(%esp)
f0101684:	00 
f0101685:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f010168c:	e8 af e9 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101691:	39 f7                	cmp    %esi,%edi
f0101693:	75 24                	jne    f01016b9 <mem_init+0x22f>
f0101695:	c7 44 24 0c 2a 74 10 	movl   $0xf010742a,0xc(%esp)
f010169c:	f0 
f010169d:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f01016a4:	f0 
f01016a5:	c7 44 24 04 20 03 00 	movl   $0x320,0x4(%esp)
f01016ac:	00 
f01016ad:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f01016b4:	e8 87 e9 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01016b9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01016bc:	39 c6                	cmp    %eax,%esi
f01016be:	74 04                	je     f01016c4 <mem_init+0x23a>
f01016c0:	39 c7                	cmp    %eax,%edi
f01016c2:	75 24                	jne    f01016e8 <mem_init+0x25e>
f01016c4:	c7 44 24 0c 50 77 10 	movl   $0xf0107750,0xc(%esp)
f01016cb:	f0 
f01016cc:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f01016d3:	f0 
f01016d4:	c7 44 24 04 21 03 00 	movl   $0x321,0x4(%esp)
f01016db:	00 
f01016dc:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f01016e3:	e8 58 e9 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01016e8:	8b 15 90 1e 23 f0    	mov    0xf0231e90,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f01016ee:	a1 88 1e 23 f0       	mov    0xf0231e88,%eax
f01016f3:	c1 e0 0c             	shl    $0xc,%eax
f01016f6:	89 f9                	mov    %edi,%ecx
f01016f8:	29 d1                	sub    %edx,%ecx
f01016fa:	c1 f9 03             	sar    $0x3,%ecx
f01016fd:	c1 e1 0c             	shl    $0xc,%ecx
f0101700:	39 c1                	cmp    %eax,%ecx
f0101702:	72 24                	jb     f0101728 <mem_init+0x29e>
f0101704:	c7 44 24 0c 3c 74 10 	movl   $0xf010743c,0xc(%esp)
f010170b:	f0 
f010170c:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0101713:	f0 
f0101714:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f010171b:	00 
f010171c:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0101723:	e8 18 e9 ff ff       	call   f0100040 <_panic>
f0101728:	89 f1                	mov    %esi,%ecx
f010172a:	29 d1                	sub    %edx,%ecx
f010172c:	c1 f9 03             	sar    $0x3,%ecx
f010172f:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101732:	39 c8                	cmp    %ecx,%eax
f0101734:	77 24                	ja     f010175a <mem_init+0x2d0>
f0101736:	c7 44 24 0c 59 74 10 	movl   $0xf0107459,0xc(%esp)
f010173d:	f0 
f010173e:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0101745:	f0 
f0101746:	c7 44 24 04 23 03 00 	movl   $0x323,0x4(%esp)
f010174d:	00 
f010174e:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0101755:	e8 e6 e8 ff ff       	call   f0100040 <_panic>
f010175a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010175d:	29 d1                	sub    %edx,%ecx
f010175f:	89 ca                	mov    %ecx,%edx
f0101761:	c1 fa 03             	sar    $0x3,%edx
f0101764:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f0101767:	39 d0                	cmp    %edx,%eax
f0101769:	77 24                	ja     f010178f <mem_init+0x305>
f010176b:	c7 44 24 0c 76 74 10 	movl   $0xf0107476,0xc(%esp)
f0101772:	f0 
f0101773:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f010177a:	f0 
f010177b:	c7 44 24 04 24 03 00 	movl   $0x324,0x4(%esp)
f0101782:	00 
f0101783:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f010178a:	e8 b1 e8 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010178f:	a1 40 12 23 f0       	mov    0xf0231240,%eax
f0101794:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101797:	c7 05 40 12 23 f0 00 	movl   $0x0,0xf0231240
f010179e:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01017a1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017a8:	e8 95 f8 ff ff       	call   f0101042 <page_alloc>
f01017ad:	85 c0                	test   %eax,%eax
f01017af:	74 24                	je     f01017d5 <mem_init+0x34b>
f01017b1:	c7 44 24 0c 93 74 10 	movl   $0xf0107493,0xc(%esp)
f01017b8:	f0 
f01017b9:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f01017c0:	f0 
f01017c1:	c7 44 24 04 2b 03 00 	movl   $0x32b,0x4(%esp)
f01017c8:	00 
f01017c9:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f01017d0:	e8 6b e8 ff ff       	call   f0100040 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01017d5:	89 3c 24             	mov    %edi,(%esp)
f01017d8:	e8 f0 f8 ff ff       	call   f01010cd <page_free>
	page_free(pp1);
f01017dd:	89 34 24             	mov    %esi,(%esp)
f01017e0:	e8 e8 f8 ff ff       	call   f01010cd <page_free>
	page_free(pp2);
f01017e5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017e8:	89 04 24             	mov    %eax,(%esp)
f01017eb:	e8 dd f8 ff ff       	call   f01010cd <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01017f0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017f7:	e8 46 f8 ff ff       	call   f0101042 <page_alloc>
f01017fc:	89 c6                	mov    %eax,%esi
f01017fe:	85 c0                	test   %eax,%eax
f0101800:	75 24                	jne    f0101826 <mem_init+0x39c>
f0101802:	c7 44 24 0c e8 73 10 	movl   $0xf01073e8,0xc(%esp)
f0101809:	f0 
f010180a:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0101811:	f0 
f0101812:	c7 44 24 04 32 03 00 	movl   $0x332,0x4(%esp)
f0101819:	00 
f010181a:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0101821:	e8 1a e8 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101826:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010182d:	e8 10 f8 ff ff       	call   f0101042 <page_alloc>
f0101832:	89 c7                	mov    %eax,%edi
f0101834:	85 c0                	test   %eax,%eax
f0101836:	75 24                	jne    f010185c <mem_init+0x3d2>
f0101838:	c7 44 24 0c fe 73 10 	movl   $0xf01073fe,0xc(%esp)
f010183f:	f0 
f0101840:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0101847:	f0 
f0101848:	c7 44 24 04 33 03 00 	movl   $0x333,0x4(%esp)
f010184f:	00 
f0101850:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0101857:	e8 e4 e7 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f010185c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101863:	e8 da f7 ff ff       	call   f0101042 <page_alloc>
f0101868:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010186b:	85 c0                	test   %eax,%eax
f010186d:	75 24                	jne    f0101893 <mem_init+0x409>
f010186f:	c7 44 24 0c 14 74 10 	movl   $0xf0107414,0xc(%esp)
f0101876:	f0 
f0101877:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f010187e:	f0 
f010187f:	c7 44 24 04 34 03 00 	movl   $0x334,0x4(%esp)
f0101886:	00 
f0101887:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f010188e:	e8 ad e7 ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101893:	39 fe                	cmp    %edi,%esi
f0101895:	75 24                	jne    f01018bb <mem_init+0x431>
f0101897:	c7 44 24 0c 2a 74 10 	movl   $0xf010742a,0xc(%esp)
f010189e:	f0 
f010189f:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f01018a6:	f0 
f01018a7:	c7 44 24 04 36 03 00 	movl   $0x336,0x4(%esp)
f01018ae:	00 
f01018af:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f01018b6:	e8 85 e7 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01018bb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01018be:	39 c7                	cmp    %eax,%edi
f01018c0:	74 04                	je     f01018c6 <mem_init+0x43c>
f01018c2:	39 c6                	cmp    %eax,%esi
f01018c4:	75 24                	jne    f01018ea <mem_init+0x460>
f01018c6:	c7 44 24 0c 50 77 10 	movl   $0xf0107750,0xc(%esp)
f01018cd:	f0 
f01018ce:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f01018d5:	f0 
f01018d6:	c7 44 24 04 37 03 00 	movl   $0x337,0x4(%esp)
f01018dd:	00 
f01018de:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f01018e5:	e8 56 e7 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f01018ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018f1:	e8 4c f7 ff ff       	call   f0101042 <page_alloc>
f01018f6:	85 c0                	test   %eax,%eax
f01018f8:	74 24                	je     f010191e <mem_init+0x494>
f01018fa:	c7 44 24 0c 93 74 10 	movl   $0xf0107493,0xc(%esp)
f0101901:	f0 
f0101902:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0101909:	f0 
f010190a:	c7 44 24 04 38 03 00 	movl   $0x338,0x4(%esp)
f0101911:	00 
f0101912:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0101919:	e8 22 e7 ff ff       	call   f0100040 <_panic>
f010191e:	89 f0                	mov    %esi,%eax
f0101920:	2b 05 90 1e 23 f0    	sub    0xf0231e90,%eax
f0101926:	c1 f8 03             	sar    $0x3,%eax
f0101929:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010192c:	89 c2                	mov    %eax,%edx
f010192e:	c1 ea 0c             	shr    $0xc,%edx
f0101931:	3b 15 88 1e 23 f0    	cmp    0xf0231e88,%edx
f0101937:	72 20                	jb     f0101959 <mem_init+0x4cf>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101939:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010193d:	c7 44 24 08 44 6d 10 	movl   $0xf0106d44,0x8(%esp)
f0101944:	f0 
f0101945:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f010194c:	00 
f010194d:	c7 04 24 e0 72 10 f0 	movl   $0xf01072e0,(%esp)
f0101954:	e8 e7 e6 ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101959:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101960:	00 
f0101961:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101968:	00 
	return (void *)(pa + KERNBASE);
f0101969:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010196e:	89 04 24             	mov    %eax,(%esp)
f0101971:	e8 81 46 00 00       	call   f0105ff7 <memset>
	page_free(pp0);
f0101976:	89 34 24             	mov    %esi,(%esp)
f0101979:	e8 4f f7 ff ff       	call   f01010cd <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010197e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101985:	e8 b8 f6 ff ff       	call   f0101042 <page_alloc>
f010198a:	85 c0                	test   %eax,%eax
f010198c:	75 24                	jne    f01019b2 <mem_init+0x528>
f010198e:	c7 44 24 0c a2 74 10 	movl   $0xf01074a2,0xc(%esp)
f0101995:	f0 
f0101996:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f010199d:	f0 
f010199e:	c7 44 24 04 3d 03 00 	movl   $0x33d,0x4(%esp)
f01019a5:	00 
f01019a6:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f01019ad:	e8 8e e6 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f01019b2:	39 c6                	cmp    %eax,%esi
f01019b4:	74 24                	je     f01019da <mem_init+0x550>
f01019b6:	c7 44 24 0c c0 74 10 	movl   $0xf01074c0,0xc(%esp)
f01019bd:	f0 
f01019be:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f01019c5:	f0 
f01019c6:	c7 44 24 04 3e 03 00 	movl   $0x33e,0x4(%esp)
f01019cd:	00 
f01019ce:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f01019d5:	e8 66 e6 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01019da:	89 f0                	mov    %esi,%eax
f01019dc:	2b 05 90 1e 23 f0    	sub    0xf0231e90,%eax
f01019e2:	c1 f8 03             	sar    $0x3,%eax
f01019e5:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01019e8:	89 c2                	mov    %eax,%edx
f01019ea:	c1 ea 0c             	shr    $0xc,%edx
f01019ed:	3b 15 88 1e 23 f0    	cmp    0xf0231e88,%edx
f01019f3:	72 20                	jb     f0101a15 <mem_init+0x58b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01019f5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01019f9:	c7 44 24 08 44 6d 10 	movl   $0xf0106d44,0x8(%esp)
f0101a00:	f0 
f0101a01:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0101a08:	00 
f0101a09:	c7 04 24 e0 72 10 f0 	movl   $0xf01072e0,(%esp)
f0101a10:	e8 2b e6 ff ff       	call   f0100040 <_panic>
f0101a15:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101a1b:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101a21:	80 38 00             	cmpb   $0x0,(%eax)
f0101a24:	74 24                	je     f0101a4a <mem_init+0x5c0>
f0101a26:	c7 44 24 0c d0 74 10 	movl   $0xf01074d0,0xc(%esp)
f0101a2d:	f0 
f0101a2e:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0101a35:	f0 
f0101a36:	c7 44 24 04 41 03 00 	movl   $0x341,0x4(%esp)
f0101a3d:	00 
f0101a3e:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0101a45:	e8 f6 e5 ff ff       	call   f0100040 <_panic>
f0101a4a:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101a4d:	39 d0                	cmp    %edx,%eax
f0101a4f:	75 d0                	jne    f0101a21 <mem_init+0x597>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101a51:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101a54:	a3 40 12 23 f0       	mov    %eax,0xf0231240

	// free the pages we took
	page_free(pp0);
f0101a59:	89 34 24             	mov    %esi,(%esp)
f0101a5c:	e8 6c f6 ff ff       	call   f01010cd <page_free>
	page_free(pp1);
f0101a61:	89 3c 24             	mov    %edi,(%esp)
f0101a64:	e8 64 f6 ff ff       	call   f01010cd <page_free>
	page_free(pp2);
f0101a69:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a6c:	89 04 24             	mov    %eax,(%esp)
f0101a6f:	e8 59 f6 ff ff       	call   f01010cd <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101a74:	a1 40 12 23 f0       	mov    0xf0231240,%eax
f0101a79:	eb 05                	jmp    f0101a80 <mem_init+0x5f6>
		--nfree;
f0101a7b:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101a7e:	8b 00                	mov    (%eax),%eax
f0101a80:	85 c0                	test   %eax,%eax
f0101a82:	75 f7                	jne    f0101a7b <mem_init+0x5f1>
		--nfree;
	assert(nfree == 0);
f0101a84:	85 db                	test   %ebx,%ebx
f0101a86:	74 24                	je     f0101aac <mem_init+0x622>
f0101a88:	c7 44 24 0c da 74 10 	movl   $0xf01074da,0xc(%esp)
f0101a8f:	f0 
f0101a90:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0101a97:	f0 
f0101a98:	c7 44 24 04 4e 03 00 	movl   $0x34e,0x4(%esp)
f0101a9f:	00 
f0101aa0:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0101aa7:	e8 94 e5 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101aac:	c7 04 24 70 77 10 f0 	movl   $0xf0107770,(%esp)
f0101ab3:	e8 71 24 00 00       	call   f0103f29 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101ab8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101abf:	e8 7e f5 ff ff       	call   f0101042 <page_alloc>
f0101ac4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101ac7:	85 c0                	test   %eax,%eax
f0101ac9:	75 24                	jne    f0101aef <mem_init+0x665>
f0101acb:	c7 44 24 0c e8 73 10 	movl   $0xf01073e8,0xc(%esp)
f0101ad2:	f0 
f0101ad3:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0101ada:	f0 
f0101adb:	c7 44 24 04 b4 03 00 	movl   $0x3b4,0x4(%esp)
f0101ae2:	00 
f0101ae3:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0101aea:	e8 51 e5 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101aef:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101af6:	e8 47 f5 ff ff       	call   f0101042 <page_alloc>
f0101afb:	89 c3                	mov    %eax,%ebx
f0101afd:	85 c0                	test   %eax,%eax
f0101aff:	75 24                	jne    f0101b25 <mem_init+0x69b>
f0101b01:	c7 44 24 0c fe 73 10 	movl   $0xf01073fe,0xc(%esp)
f0101b08:	f0 
f0101b09:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0101b10:	f0 
f0101b11:	c7 44 24 04 b5 03 00 	movl   $0x3b5,0x4(%esp)
f0101b18:	00 
f0101b19:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0101b20:	e8 1b e5 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101b25:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b2c:	e8 11 f5 ff ff       	call   f0101042 <page_alloc>
f0101b31:	89 c6                	mov    %eax,%esi
f0101b33:	85 c0                	test   %eax,%eax
f0101b35:	75 24                	jne    f0101b5b <mem_init+0x6d1>
f0101b37:	c7 44 24 0c 14 74 10 	movl   $0xf0107414,0xc(%esp)
f0101b3e:	f0 
f0101b3f:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0101b46:	f0 
f0101b47:	c7 44 24 04 b6 03 00 	movl   $0x3b6,0x4(%esp)
f0101b4e:	00 
f0101b4f:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0101b56:	e8 e5 e4 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101b5b:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101b5e:	75 24                	jne    f0101b84 <mem_init+0x6fa>
f0101b60:	c7 44 24 0c 2a 74 10 	movl   $0xf010742a,0xc(%esp)
f0101b67:	f0 
f0101b68:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0101b6f:	f0 
f0101b70:	c7 44 24 04 b9 03 00 	movl   $0x3b9,0x4(%esp)
f0101b77:	00 
f0101b78:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0101b7f:	e8 bc e4 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101b84:	39 c3                	cmp    %eax,%ebx
f0101b86:	74 05                	je     f0101b8d <mem_init+0x703>
f0101b88:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101b8b:	75 24                	jne    f0101bb1 <mem_init+0x727>
f0101b8d:	c7 44 24 0c 50 77 10 	movl   $0xf0107750,0xc(%esp)
f0101b94:	f0 
f0101b95:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0101b9c:	f0 
f0101b9d:	c7 44 24 04 ba 03 00 	movl   $0x3ba,0x4(%esp)
f0101ba4:	00 
f0101ba5:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0101bac:	e8 8f e4 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101bb1:	a1 40 12 23 f0       	mov    0xf0231240,%eax
f0101bb6:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101bb9:	c7 05 40 12 23 f0 00 	movl   $0x0,0xf0231240
f0101bc0:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101bc3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101bca:	e8 73 f4 ff ff       	call   f0101042 <page_alloc>
f0101bcf:	85 c0                	test   %eax,%eax
f0101bd1:	74 24                	je     f0101bf7 <mem_init+0x76d>
f0101bd3:	c7 44 24 0c 93 74 10 	movl   $0xf0107493,0xc(%esp)
f0101bda:	f0 
f0101bdb:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0101be2:	f0 
f0101be3:	c7 44 24 04 c1 03 00 	movl   $0x3c1,0x4(%esp)
f0101bea:	00 
f0101beb:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0101bf2:	e8 49 e4 ff ff       	call   f0100040 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101bf7:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101bfa:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101bfe:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101c05:	00 
f0101c06:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
f0101c0b:	89 04 24             	mov    %eax,(%esp)
f0101c0e:	e8 9e f6 ff ff       	call   f01012b1 <page_lookup>
f0101c13:	85 c0                	test   %eax,%eax
f0101c15:	74 24                	je     f0101c3b <mem_init+0x7b1>
f0101c17:	c7 44 24 0c 90 77 10 	movl   $0xf0107790,0xc(%esp)
f0101c1e:	f0 
f0101c1f:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0101c26:	f0 
f0101c27:	c7 44 24 04 c4 03 00 	movl   $0x3c4,0x4(%esp)
f0101c2e:	00 
f0101c2f:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0101c36:	e8 05 e4 ff ff       	call   f0100040 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101c3b:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101c42:	00 
f0101c43:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101c4a:	00 
f0101c4b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101c4f:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
f0101c54:	89 04 24             	mov    %eax,(%esp)
f0101c57:	e8 3e f7 ff ff       	call   f010139a <page_insert>
f0101c5c:	85 c0                	test   %eax,%eax
f0101c5e:	78 24                	js     f0101c84 <mem_init+0x7fa>
f0101c60:	c7 44 24 0c c8 77 10 	movl   $0xf01077c8,0xc(%esp)
f0101c67:	f0 
f0101c68:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0101c6f:	f0 
f0101c70:	c7 44 24 04 c7 03 00 	movl   $0x3c7,0x4(%esp)
f0101c77:	00 
f0101c78:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0101c7f:	e8 bc e3 ff ff       	call   f0100040 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101c84:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c87:	89 04 24             	mov    %eax,(%esp)
f0101c8a:	e8 3e f4 ff ff       	call   f01010cd <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101c8f:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101c96:	00 
f0101c97:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101c9e:	00 
f0101c9f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101ca3:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
f0101ca8:	89 04 24             	mov    %eax,(%esp)
f0101cab:	e8 ea f6 ff ff       	call   f010139a <page_insert>
f0101cb0:	85 c0                	test   %eax,%eax
f0101cb2:	74 24                	je     f0101cd8 <mem_init+0x84e>
f0101cb4:	c7 44 24 0c f8 77 10 	movl   $0xf01077f8,0xc(%esp)
f0101cbb:	f0 
f0101cbc:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0101cc3:	f0 
f0101cc4:	c7 44 24 04 cb 03 00 	movl   $0x3cb,0x4(%esp)
f0101ccb:	00 
f0101ccc:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0101cd3:	e8 68 e3 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101cd8:	8b 3d 8c 1e 23 f0    	mov    0xf0231e8c,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101cde:	a1 90 1e 23 f0       	mov    0xf0231e90,%eax
f0101ce3:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101ce6:	8b 17                	mov    (%edi),%edx
f0101ce8:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101cee:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101cf1:	29 c1                	sub    %eax,%ecx
f0101cf3:	89 c8                	mov    %ecx,%eax
f0101cf5:	c1 f8 03             	sar    $0x3,%eax
f0101cf8:	c1 e0 0c             	shl    $0xc,%eax
f0101cfb:	39 c2                	cmp    %eax,%edx
f0101cfd:	74 24                	je     f0101d23 <mem_init+0x899>
f0101cff:	c7 44 24 0c 28 78 10 	movl   $0xf0107828,0xc(%esp)
f0101d06:	f0 
f0101d07:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0101d0e:	f0 
f0101d0f:	c7 44 24 04 cc 03 00 	movl   $0x3cc,0x4(%esp)
f0101d16:	00 
f0101d17:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0101d1e:	e8 1d e3 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101d23:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d28:	89 f8                	mov    %edi,%eax
f0101d2a:	e8 95 ee ff ff       	call   f0100bc4 <check_va2pa>
f0101d2f:	89 da                	mov    %ebx,%edx
f0101d31:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101d34:	c1 fa 03             	sar    $0x3,%edx
f0101d37:	c1 e2 0c             	shl    $0xc,%edx
f0101d3a:	39 d0                	cmp    %edx,%eax
f0101d3c:	74 24                	je     f0101d62 <mem_init+0x8d8>
f0101d3e:	c7 44 24 0c 50 78 10 	movl   $0xf0107850,0xc(%esp)
f0101d45:	f0 
f0101d46:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0101d4d:	f0 
f0101d4e:	c7 44 24 04 cd 03 00 	movl   $0x3cd,0x4(%esp)
f0101d55:	00 
f0101d56:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0101d5d:	e8 de e2 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101d62:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101d67:	74 24                	je     f0101d8d <mem_init+0x903>
f0101d69:	c7 44 24 0c e5 74 10 	movl   $0xf01074e5,0xc(%esp)
f0101d70:	f0 
f0101d71:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0101d78:	f0 
f0101d79:	c7 44 24 04 ce 03 00 	movl   $0x3ce,0x4(%esp)
f0101d80:	00 
f0101d81:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0101d88:	e8 b3 e2 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101d8d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d90:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101d95:	74 24                	je     f0101dbb <mem_init+0x931>
f0101d97:	c7 44 24 0c f6 74 10 	movl   $0xf01074f6,0xc(%esp)
f0101d9e:	f0 
f0101d9f:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0101da6:	f0 
f0101da7:	c7 44 24 04 cf 03 00 	movl   $0x3cf,0x4(%esp)
f0101dae:	00 
f0101daf:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0101db6:	e8 85 e2 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101dbb:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101dc2:	00 
f0101dc3:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101dca:	00 
f0101dcb:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101dcf:	89 3c 24             	mov    %edi,(%esp)
f0101dd2:	e8 c3 f5 ff ff       	call   f010139a <page_insert>
f0101dd7:	85 c0                	test   %eax,%eax
f0101dd9:	74 24                	je     f0101dff <mem_init+0x975>
f0101ddb:	c7 44 24 0c 80 78 10 	movl   $0xf0107880,0xc(%esp)
f0101de2:	f0 
f0101de3:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0101dea:	f0 
f0101deb:	c7 44 24 04 d2 03 00 	movl   $0x3d2,0x4(%esp)
f0101df2:	00 
f0101df3:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0101dfa:	e8 41 e2 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101dff:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e04:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
f0101e09:	e8 b6 ed ff ff       	call   f0100bc4 <check_va2pa>
f0101e0e:	89 f2                	mov    %esi,%edx
f0101e10:	2b 15 90 1e 23 f0    	sub    0xf0231e90,%edx
f0101e16:	c1 fa 03             	sar    $0x3,%edx
f0101e19:	c1 e2 0c             	shl    $0xc,%edx
f0101e1c:	39 d0                	cmp    %edx,%eax
f0101e1e:	74 24                	je     f0101e44 <mem_init+0x9ba>
f0101e20:	c7 44 24 0c bc 78 10 	movl   $0xf01078bc,0xc(%esp)
f0101e27:	f0 
f0101e28:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0101e2f:	f0 
f0101e30:	c7 44 24 04 d3 03 00 	movl   $0x3d3,0x4(%esp)
f0101e37:	00 
f0101e38:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0101e3f:	e8 fc e1 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101e44:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101e49:	74 24                	je     f0101e6f <mem_init+0x9e5>
f0101e4b:	c7 44 24 0c 07 75 10 	movl   $0xf0107507,0xc(%esp)
f0101e52:	f0 
f0101e53:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0101e5a:	f0 
f0101e5b:	c7 44 24 04 d4 03 00 	movl   $0x3d4,0x4(%esp)
f0101e62:	00 
f0101e63:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0101e6a:	e8 d1 e1 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101e6f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101e76:	e8 c7 f1 ff ff       	call   f0101042 <page_alloc>
f0101e7b:	85 c0                	test   %eax,%eax
f0101e7d:	74 24                	je     f0101ea3 <mem_init+0xa19>
f0101e7f:	c7 44 24 0c 93 74 10 	movl   $0xf0107493,0xc(%esp)
f0101e86:	f0 
f0101e87:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0101e8e:	f0 
f0101e8f:	c7 44 24 04 d7 03 00 	movl   $0x3d7,0x4(%esp)
f0101e96:	00 
f0101e97:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0101e9e:	e8 9d e1 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ea3:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101eaa:	00 
f0101eab:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101eb2:	00 
f0101eb3:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101eb7:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
f0101ebc:	89 04 24             	mov    %eax,(%esp)
f0101ebf:	e8 d6 f4 ff ff       	call   f010139a <page_insert>
f0101ec4:	85 c0                	test   %eax,%eax
f0101ec6:	74 24                	je     f0101eec <mem_init+0xa62>
f0101ec8:	c7 44 24 0c 80 78 10 	movl   $0xf0107880,0xc(%esp)
f0101ecf:	f0 
f0101ed0:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0101ed7:	f0 
f0101ed8:	c7 44 24 04 da 03 00 	movl   $0x3da,0x4(%esp)
f0101edf:	00 
f0101ee0:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0101ee7:	e8 54 e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101eec:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ef1:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
f0101ef6:	e8 c9 ec ff ff       	call   f0100bc4 <check_va2pa>
f0101efb:	89 f2                	mov    %esi,%edx
f0101efd:	2b 15 90 1e 23 f0    	sub    0xf0231e90,%edx
f0101f03:	c1 fa 03             	sar    $0x3,%edx
f0101f06:	c1 e2 0c             	shl    $0xc,%edx
f0101f09:	39 d0                	cmp    %edx,%eax
f0101f0b:	74 24                	je     f0101f31 <mem_init+0xaa7>
f0101f0d:	c7 44 24 0c bc 78 10 	movl   $0xf01078bc,0xc(%esp)
f0101f14:	f0 
f0101f15:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0101f1c:	f0 
f0101f1d:	c7 44 24 04 db 03 00 	movl   $0x3db,0x4(%esp)
f0101f24:	00 
f0101f25:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0101f2c:	e8 0f e1 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101f31:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101f36:	74 24                	je     f0101f5c <mem_init+0xad2>
f0101f38:	c7 44 24 0c 07 75 10 	movl   $0xf0107507,0xc(%esp)
f0101f3f:	f0 
f0101f40:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0101f47:	f0 
f0101f48:	c7 44 24 04 dc 03 00 	movl   $0x3dc,0x4(%esp)
f0101f4f:	00 
f0101f50:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0101f57:	e8 e4 e0 ff ff       	call   f0100040 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101f5c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101f63:	e8 da f0 ff ff       	call   f0101042 <page_alloc>
f0101f68:	85 c0                	test   %eax,%eax
f0101f6a:	74 24                	je     f0101f90 <mem_init+0xb06>
f0101f6c:	c7 44 24 0c 93 74 10 	movl   $0xf0107493,0xc(%esp)
f0101f73:	f0 
f0101f74:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0101f7b:	f0 
f0101f7c:	c7 44 24 04 e0 03 00 	movl   $0x3e0,0x4(%esp)
f0101f83:	00 
f0101f84:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0101f8b:	e8 b0 e0 ff ff       	call   f0100040 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101f90:	8b 15 8c 1e 23 f0    	mov    0xf0231e8c,%edx
f0101f96:	8b 02                	mov    (%edx),%eax
f0101f98:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f9d:	89 c1                	mov    %eax,%ecx
f0101f9f:	c1 e9 0c             	shr    $0xc,%ecx
f0101fa2:	3b 0d 88 1e 23 f0    	cmp    0xf0231e88,%ecx
f0101fa8:	72 20                	jb     f0101fca <mem_init+0xb40>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101faa:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101fae:	c7 44 24 08 44 6d 10 	movl   $0xf0106d44,0x8(%esp)
f0101fb5:	f0 
f0101fb6:	c7 44 24 04 e3 03 00 	movl   $0x3e3,0x4(%esp)
f0101fbd:	00 
f0101fbe:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0101fc5:	e8 76 e0 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0101fca:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101fcf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101fd2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101fd9:	00 
f0101fda:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101fe1:	00 
f0101fe2:	89 14 24             	mov    %edx,(%esp)
f0101fe5:	e8 43 f1 ff ff       	call   f010112d <pgdir_walk>
f0101fea:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101fed:	8d 51 04             	lea    0x4(%ecx),%edx
f0101ff0:	39 d0                	cmp    %edx,%eax
f0101ff2:	74 24                	je     f0102018 <mem_init+0xb8e>
f0101ff4:	c7 44 24 0c ec 78 10 	movl   $0xf01078ec,0xc(%esp)
f0101ffb:	f0 
f0101ffc:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0102003:	f0 
f0102004:	c7 44 24 04 e4 03 00 	movl   $0x3e4,0x4(%esp)
f010200b:	00 
f010200c:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0102013:	e8 28 e0 ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102018:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f010201f:	00 
f0102020:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102027:	00 
f0102028:	89 74 24 04          	mov    %esi,0x4(%esp)
f010202c:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
f0102031:	89 04 24             	mov    %eax,(%esp)
f0102034:	e8 61 f3 ff ff       	call   f010139a <page_insert>
f0102039:	85 c0                	test   %eax,%eax
f010203b:	74 24                	je     f0102061 <mem_init+0xbd7>
f010203d:	c7 44 24 0c 2c 79 10 	movl   $0xf010792c,0xc(%esp)
f0102044:	f0 
f0102045:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f010204c:	f0 
f010204d:	c7 44 24 04 e7 03 00 	movl   $0x3e7,0x4(%esp)
f0102054:	00 
f0102055:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f010205c:	e8 df df ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102061:	8b 3d 8c 1e 23 f0    	mov    0xf0231e8c,%edi
f0102067:	ba 00 10 00 00       	mov    $0x1000,%edx
f010206c:	89 f8                	mov    %edi,%eax
f010206e:	e8 51 eb ff ff       	call   f0100bc4 <check_va2pa>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102073:	89 f2                	mov    %esi,%edx
f0102075:	2b 15 90 1e 23 f0    	sub    0xf0231e90,%edx
f010207b:	c1 fa 03             	sar    $0x3,%edx
f010207e:	c1 e2 0c             	shl    $0xc,%edx
f0102081:	39 d0                	cmp    %edx,%eax
f0102083:	74 24                	je     f01020a9 <mem_init+0xc1f>
f0102085:	c7 44 24 0c bc 78 10 	movl   $0xf01078bc,0xc(%esp)
f010208c:	f0 
f010208d:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0102094:	f0 
f0102095:	c7 44 24 04 e8 03 00 	movl   $0x3e8,0x4(%esp)
f010209c:	00 
f010209d:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f01020a4:	e8 97 df ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f01020a9:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01020ae:	74 24                	je     f01020d4 <mem_init+0xc4a>
f01020b0:	c7 44 24 0c 07 75 10 	movl   $0xf0107507,0xc(%esp)
f01020b7:	f0 
f01020b8:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f01020bf:	f0 
f01020c0:	c7 44 24 04 e9 03 00 	movl   $0x3e9,0x4(%esp)
f01020c7:	00 
f01020c8:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f01020cf:	e8 6c df ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01020d4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01020db:	00 
f01020dc:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01020e3:	00 
f01020e4:	89 3c 24             	mov    %edi,(%esp)
f01020e7:	e8 41 f0 ff ff       	call   f010112d <pgdir_walk>
f01020ec:	f6 00 04             	testb  $0x4,(%eax)
f01020ef:	75 24                	jne    f0102115 <mem_init+0xc8b>
f01020f1:	c7 44 24 0c 6c 79 10 	movl   $0xf010796c,0xc(%esp)
f01020f8:	f0 
f01020f9:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0102100:	f0 
f0102101:	c7 44 24 04 ea 03 00 	movl   $0x3ea,0x4(%esp)
f0102108:	00 
f0102109:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0102110:	e8 2b df ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0102115:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
f010211a:	f6 00 04             	testb  $0x4,(%eax)
f010211d:	75 24                	jne    f0102143 <mem_init+0xcb9>
f010211f:	c7 44 24 0c 18 75 10 	movl   $0xf0107518,0xc(%esp)
f0102126:	f0 
f0102127:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f010212e:	f0 
f010212f:	c7 44 24 04 eb 03 00 	movl   $0x3eb,0x4(%esp)
f0102136:	00 
f0102137:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f010213e:	e8 fd de ff ff       	call   f0100040 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102143:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010214a:	00 
f010214b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102152:	00 
f0102153:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102157:	89 04 24             	mov    %eax,(%esp)
f010215a:	e8 3b f2 ff ff       	call   f010139a <page_insert>
f010215f:	85 c0                	test   %eax,%eax
f0102161:	74 24                	je     f0102187 <mem_init+0xcfd>
f0102163:	c7 44 24 0c 80 78 10 	movl   $0xf0107880,0xc(%esp)
f010216a:	f0 
f010216b:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0102172:	f0 
f0102173:	c7 44 24 04 ee 03 00 	movl   $0x3ee,0x4(%esp)
f010217a:	00 
f010217b:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0102182:	e8 b9 de ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0102187:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010218e:	00 
f010218f:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102196:	00 
f0102197:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
f010219c:	89 04 24             	mov    %eax,(%esp)
f010219f:	e8 89 ef ff ff       	call   f010112d <pgdir_walk>
f01021a4:	f6 00 02             	testb  $0x2,(%eax)
f01021a7:	75 24                	jne    f01021cd <mem_init+0xd43>
f01021a9:	c7 44 24 0c a0 79 10 	movl   $0xf01079a0,0xc(%esp)
f01021b0:	f0 
f01021b1:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f01021b8:	f0 
f01021b9:	c7 44 24 04 ef 03 00 	movl   $0x3ef,0x4(%esp)
f01021c0:	00 
f01021c1:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f01021c8:	e8 73 de ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01021cd:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01021d4:	00 
f01021d5:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01021dc:	00 
f01021dd:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
f01021e2:	89 04 24             	mov    %eax,(%esp)
f01021e5:	e8 43 ef ff ff       	call   f010112d <pgdir_walk>
f01021ea:	f6 00 04             	testb  $0x4,(%eax)
f01021ed:	74 24                	je     f0102213 <mem_init+0xd89>
f01021ef:	c7 44 24 0c d4 79 10 	movl   $0xf01079d4,0xc(%esp)
f01021f6:	f0 
f01021f7:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f01021fe:	f0 
f01021ff:	c7 44 24 04 f0 03 00 	movl   $0x3f0,0x4(%esp)
f0102206:	00 
f0102207:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f010220e:	e8 2d de ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102213:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010221a:	00 
f010221b:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0102222:	00 
f0102223:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102226:	89 44 24 04          	mov    %eax,0x4(%esp)
f010222a:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
f010222f:	89 04 24             	mov    %eax,(%esp)
f0102232:	e8 63 f1 ff ff       	call   f010139a <page_insert>
f0102237:	85 c0                	test   %eax,%eax
f0102239:	78 24                	js     f010225f <mem_init+0xdd5>
f010223b:	c7 44 24 0c 0c 7a 10 	movl   $0xf0107a0c,0xc(%esp)
f0102242:	f0 
f0102243:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f010224a:	f0 
f010224b:	c7 44 24 04 f3 03 00 	movl   $0x3f3,0x4(%esp)
f0102252:	00 
f0102253:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f010225a:	e8 e1 dd ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f010225f:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102266:	00 
f0102267:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010226e:	00 
f010226f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102273:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
f0102278:	89 04 24             	mov    %eax,(%esp)
f010227b:	e8 1a f1 ff ff       	call   f010139a <page_insert>
f0102280:	85 c0                	test   %eax,%eax
f0102282:	74 24                	je     f01022a8 <mem_init+0xe1e>
f0102284:	c7 44 24 0c 44 7a 10 	movl   $0xf0107a44,0xc(%esp)
f010228b:	f0 
f010228c:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0102293:	f0 
f0102294:	c7 44 24 04 f6 03 00 	movl   $0x3f6,0x4(%esp)
f010229b:	00 
f010229c:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f01022a3:	e8 98 dd ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01022a8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01022af:	00 
f01022b0:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01022b7:	00 
f01022b8:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
f01022bd:	89 04 24             	mov    %eax,(%esp)
f01022c0:	e8 68 ee ff ff       	call   f010112d <pgdir_walk>
f01022c5:	f6 00 04             	testb  $0x4,(%eax)
f01022c8:	74 24                	je     f01022ee <mem_init+0xe64>
f01022ca:	c7 44 24 0c d4 79 10 	movl   $0xf01079d4,0xc(%esp)
f01022d1:	f0 
f01022d2:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f01022d9:	f0 
f01022da:	c7 44 24 04 f7 03 00 	movl   $0x3f7,0x4(%esp)
f01022e1:	00 
f01022e2:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f01022e9:	e8 52 dd ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01022ee:	8b 3d 8c 1e 23 f0    	mov    0xf0231e8c,%edi
f01022f4:	ba 00 00 00 00       	mov    $0x0,%edx
f01022f9:	89 f8                	mov    %edi,%eax
f01022fb:	e8 c4 e8 ff ff       	call   f0100bc4 <check_va2pa>
f0102300:	89 c1                	mov    %eax,%ecx
f0102302:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102305:	89 d8                	mov    %ebx,%eax
f0102307:	2b 05 90 1e 23 f0    	sub    0xf0231e90,%eax
f010230d:	c1 f8 03             	sar    $0x3,%eax
f0102310:	c1 e0 0c             	shl    $0xc,%eax
f0102313:	39 c1                	cmp    %eax,%ecx
f0102315:	74 24                	je     f010233b <mem_init+0xeb1>
f0102317:	c7 44 24 0c 80 7a 10 	movl   $0xf0107a80,0xc(%esp)
f010231e:	f0 
f010231f:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0102326:	f0 
f0102327:	c7 44 24 04 fa 03 00 	movl   $0x3fa,0x4(%esp)
f010232e:	00 
f010232f:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0102336:	e8 05 dd ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010233b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102340:	89 f8                	mov    %edi,%eax
f0102342:	e8 7d e8 ff ff       	call   f0100bc4 <check_va2pa>
f0102347:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f010234a:	74 24                	je     f0102370 <mem_init+0xee6>
f010234c:	c7 44 24 0c ac 7a 10 	movl   $0xf0107aac,0xc(%esp)
f0102353:	f0 
f0102354:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f010235b:	f0 
f010235c:	c7 44 24 04 fb 03 00 	movl   $0x3fb,0x4(%esp)
f0102363:	00 
f0102364:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f010236b:	e8 d0 dc ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0102370:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0102375:	74 24                	je     f010239b <mem_init+0xf11>
f0102377:	c7 44 24 0c 2e 75 10 	movl   $0xf010752e,0xc(%esp)
f010237e:	f0 
f010237f:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0102386:	f0 
f0102387:	c7 44 24 04 fd 03 00 	movl   $0x3fd,0x4(%esp)
f010238e:	00 
f010238f:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0102396:	e8 a5 dc ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010239b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01023a0:	74 24                	je     f01023c6 <mem_init+0xf3c>
f01023a2:	c7 44 24 0c 3f 75 10 	movl   $0xf010753f,0xc(%esp)
f01023a9:	f0 
f01023aa:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f01023b1:	f0 
f01023b2:	c7 44 24 04 fe 03 00 	movl   $0x3fe,0x4(%esp)
f01023b9:	00 
f01023ba:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f01023c1:	e8 7a dc ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f01023c6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01023cd:	e8 70 ec ff ff       	call   f0101042 <page_alloc>
f01023d2:	85 c0                	test   %eax,%eax
f01023d4:	74 04                	je     f01023da <mem_init+0xf50>
f01023d6:	39 c6                	cmp    %eax,%esi
f01023d8:	74 24                	je     f01023fe <mem_init+0xf74>
f01023da:	c7 44 24 0c dc 7a 10 	movl   $0xf0107adc,0xc(%esp)
f01023e1:	f0 
f01023e2:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f01023e9:	f0 
f01023ea:	c7 44 24 04 01 04 00 	movl   $0x401,0x4(%esp)
f01023f1:	00 
f01023f2:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f01023f9:	e8 42 dc ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f01023fe:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102405:	00 
f0102406:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
f010240b:	89 04 24             	mov    %eax,(%esp)
f010240e:	e8 37 ef ff ff       	call   f010134a <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102413:	8b 3d 8c 1e 23 f0    	mov    0xf0231e8c,%edi
f0102419:	ba 00 00 00 00       	mov    $0x0,%edx
f010241e:	89 f8                	mov    %edi,%eax
f0102420:	e8 9f e7 ff ff       	call   f0100bc4 <check_va2pa>
f0102425:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102428:	74 24                	je     f010244e <mem_init+0xfc4>
f010242a:	c7 44 24 0c 00 7b 10 	movl   $0xf0107b00,0xc(%esp)
f0102431:	f0 
f0102432:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0102439:	f0 
f010243a:	c7 44 24 04 05 04 00 	movl   $0x405,0x4(%esp)
f0102441:	00 
f0102442:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0102449:	e8 f2 db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010244e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102453:	89 f8                	mov    %edi,%eax
f0102455:	e8 6a e7 ff ff       	call   f0100bc4 <check_va2pa>
f010245a:	89 da                	mov    %ebx,%edx
f010245c:	2b 15 90 1e 23 f0    	sub    0xf0231e90,%edx
f0102462:	c1 fa 03             	sar    $0x3,%edx
f0102465:	c1 e2 0c             	shl    $0xc,%edx
f0102468:	39 d0                	cmp    %edx,%eax
f010246a:	74 24                	je     f0102490 <mem_init+0x1006>
f010246c:	c7 44 24 0c ac 7a 10 	movl   $0xf0107aac,0xc(%esp)
f0102473:	f0 
f0102474:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f010247b:	f0 
f010247c:	c7 44 24 04 06 04 00 	movl   $0x406,0x4(%esp)
f0102483:	00 
f0102484:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f010248b:	e8 b0 db ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0102490:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102495:	74 24                	je     f01024bb <mem_init+0x1031>
f0102497:	c7 44 24 0c e5 74 10 	movl   $0xf01074e5,0xc(%esp)
f010249e:	f0 
f010249f:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f01024a6:	f0 
f01024a7:	c7 44 24 04 07 04 00 	movl   $0x407,0x4(%esp)
f01024ae:	00 
f01024af:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f01024b6:	e8 85 db ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f01024bb:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01024c0:	74 24                	je     f01024e6 <mem_init+0x105c>
f01024c2:	c7 44 24 0c 3f 75 10 	movl   $0xf010753f,0xc(%esp)
f01024c9:	f0 
f01024ca:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f01024d1:	f0 
f01024d2:	c7 44 24 04 08 04 00 	movl   $0x408,0x4(%esp)
f01024d9:	00 
f01024da:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f01024e1:	e8 5a db ff ff       	call   f0100040 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f01024e6:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01024ed:	00 
f01024ee:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01024f5:	00 
f01024f6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01024fa:	89 3c 24             	mov    %edi,(%esp)
f01024fd:	e8 98 ee ff ff       	call   f010139a <page_insert>
f0102502:	85 c0                	test   %eax,%eax
f0102504:	74 24                	je     f010252a <mem_init+0x10a0>
f0102506:	c7 44 24 0c 24 7b 10 	movl   $0xf0107b24,0xc(%esp)
f010250d:	f0 
f010250e:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0102515:	f0 
f0102516:	c7 44 24 04 0b 04 00 	movl   $0x40b,0x4(%esp)
f010251d:	00 
f010251e:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0102525:	e8 16 db ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f010252a:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010252f:	75 24                	jne    f0102555 <mem_init+0x10cb>
f0102531:	c7 44 24 0c 50 75 10 	movl   $0xf0107550,0xc(%esp)
f0102538:	f0 
f0102539:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0102540:	f0 
f0102541:	c7 44 24 04 0c 04 00 	movl   $0x40c,0x4(%esp)
f0102548:	00 
f0102549:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0102550:	e8 eb da ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f0102555:	83 3b 00             	cmpl   $0x0,(%ebx)
f0102558:	74 24                	je     f010257e <mem_init+0x10f4>
f010255a:	c7 44 24 0c 5c 75 10 	movl   $0xf010755c,0xc(%esp)
f0102561:	f0 
f0102562:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0102569:	f0 
f010256a:	c7 44 24 04 0d 04 00 	movl   $0x40d,0x4(%esp)
f0102571:	00 
f0102572:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0102579:	e8 c2 da ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f010257e:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102585:	00 
f0102586:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
f010258b:	89 04 24             	mov    %eax,(%esp)
f010258e:	e8 b7 ed ff ff       	call   f010134a <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102593:	8b 3d 8c 1e 23 f0    	mov    0xf0231e8c,%edi
f0102599:	ba 00 00 00 00       	mov    $0x0,%edx
f010259e:	89 f8                	mov    %edi,%eax
f01025a0:	e8 1f e6 ff ff       	call   f0100bc4 <check_va2pa>
f01025a5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01025a8:	74 24                	je     f01025ce <mem_init+0x1144>
f01025aa:	c7 44 24 0c 00 7b 10 	movl   $0xf0107b00,0xc(%esp)
f01025b1:	f0 
f01025b2:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f01025b9:	f0 
f01025ba:	c7 44 24 04 11 04 00 	movl   $0x411,0x4(%esp)
f01025c1:	00 
f01025c2:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f01025c9:	e8 72 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01025ce:	ba 00 10 00 00       	mov    $0x1000,%edx
f01025d3:	89 f8                	mov    %edi,%eax
f01025d5:	e8 ea e5 ff ff       	call   f0100bc4 <check_va2pa>
f01025da:	83 f8 ff             	cmp    $0xffffffff,%eax
f01025dd:	74 24                	je     f0102603 <mem_init+0x1179>
f01025df:	c7 44 24 0c 5c 7b 10 	movl   $0xf0107b5c,0xc(%esp)
f01025e6:	f0 
f01025e7:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f01025ee:	f0 
f01025ef:	c7 44 24 04 12 04 00 	movl   $0x412,0x4(%esp)
f01025f6:	00 
f01025f7:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f01025fe:	e8 3d da ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102603:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102608:	74 24                	je     f010262e <mem_init+0x11a4>
f010260a:	c7 44 24 0c 71 75 10 	movl   $0xf0107571,0xc(%esp)
f0102611:	f0 
f0102612:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0102619:	f0 
f010261a:	c7 44 24 04 13 04 00 	movl   $0x413,0x4(%esp)
f0102621:	00 
f0102622:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0102629:	e8 12 da ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010262e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102633:	74 24                	je     f0102659 <mem_init+0x11cf>
f0102635:	c7 44 24 0c 3f 75 10 	movl   $0xf010753f,0xc(%esp)
f010263c:	f0 
f010263d:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0102644:	f0 
f0102645:	c7 44 24 04 14 04 00 	movl   $0x414,0x4(%esp)
f010264c:	00 
f010264d:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0102654:	e8 e7 d9 ff ff       	call   f0100040 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102659:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102660:	e8 dd e9 ff ff       	call   f0101042 <page_alloc>
f0102665:	85 c0                	test   %eax,%eax
f0102667:	74 04                	je     f010266d <mem_init+0x11e3>
f0102669:	39 c3                	cmp    %eax,%ebx
f010266b:	74 24                	je     f0102691 <mem_init+0x1207>
f010266d:	c7 44 24 0c 84 7b 10 	movl   $0xf0107b84,0xc(%esp)
f0102674:	f0 
f0102675:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f010267c:	f0 
f010267d:	c7 44 24 04 17 04 00 	movl   $0x417,0x4(%esp)
f0102684:	00 
f0102685:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f010268c:	e8 af d9 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102691:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102698:	e8 a5 e9 ff ff       	call   f0101042 <page_alloc>
f010269d:	85 c0                	test   %eax,%eax
f010269f:	74 24                	je     f01026c5 <mem_init+0x123b>
f01026a1:	c7 44 24 0c 93 74 10 	movl   $0xf0107493,0xc(%esp)
f01026a8:	f0 
f01026a9:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f01026b0:	f0 
f01026b1:	c7 44 24 04 1a 04 00 	movl   $0x41a,0x4(%esp)
f01026b8:	00 
f01026b9:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f01026c0:	e8 7b d9 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01026c5:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
f01026ca:	8b 08                	mov    (%eax),%ecx
f01026cc:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01026d2:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01026d5:	2b 15 90 1e 23 f0    	sub    0xf0231e90,%edx
f01026db:	c1 fa 03             	sar    $0x3,%edx
f01026de:	c1 e2 0c             	shl    $0xc,%edx
f01026e1:	39 d1                	cmp    %edx,%ecx
f01026e3:	74 24                	je     f0102709 <mem_init+0x127f>
f01026e5:	c7 44 24 0c 28 78 10 	movl   $0xf0107828,0xc(%esp)
f01026ec:	f0 
f01026ed:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f01026f4:	f0 
f01026f5:	c7 44 24 04 1d 04 00 	movl   $0x41d,0x4(%esp)
f01026fc:	00 
f01026fd:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0102704:	e8 37 d9 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102709:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f010270f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102712:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102717:	74 24                	je     f010273d <mem_init+0x12b3>
f0102719:	c7 44 24 0c f6 74 10 	movl   $0xf01074f6,0xc(%esp)
f0102720:	f0 
f0102721:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0102728:	f0 
f0102729:	c7 44 24 04 1f 04 00 	movl   $0x41f,0x4(%esp)
f0102730:	00 
f0102731:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0102738:	e8 03 d9 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f010273d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102740:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102746:	89 04 24             	mov    %eax,(%esp)
f0102749:	e8 7f e9 ff ff       	call   f01010cd <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f010274e:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102755:	00 
f0102756:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f010275d:	00 
f010275e:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
f0102763:	89 04 24             	mov    %eax,(%esp)
f0102766:	e8 c2 e9 ff ff       	call   f010112d <pgdir_walk>
f010276b:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010276e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102771:	8b 15 8c 1e 23 f0    	mov    0xf0231e8c,%edx
f0102777:	8b 7a 04             	mov    0x4(%edx),%edi
f010277a:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102780:	8b 0d 88 1e 23 f0    	mov    0xf0231e88,%ecx
f0102786:	89 f8                	mov    %edi,%eax
f0102788:	c1 e8 0c             	shr    $0xc,%eax
f010278b:	39 c8                	cmp    %ecx,%eax
f010278d:	72 20                	jb     f01027af <mem_init+0x1325>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010278f:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0102793:	c7 44 24 08 44 6d 10 	movl   $0xf0106d44,0x8(%esp)
f010279a:	f0 
f010279b:	c7 44 24 04 26 04 00 	movl   $0x426,0x4(%esp)
f01027a2:	00 
f01027a3:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f01027aa:	e8 91 d8 ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01027af:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f01027b5:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f01027b8:	74 24                	je     f01027de <mem_init+0x1354>
f01027ba:	c7 44 24 0c 82 75 10 	movl   $0xf0107582,0xc(%esp)
f01027c1:	f0 
f01027c2:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f01027c9:	f0 
f01027ca:	c7 44 24 04 27 04 00 	movl   $0x427,0x4(%esp)
f01027d1:	00 
f01027d2:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f01027d9:	e8 62 d8 ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f01027de:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f01027e5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01027e8:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01027ee:	2b 05 90 1e 23 f0    	sub    0xf0231e90,%eax
f01027f4:	c1 f8 03             	sar    $0x3,%eax
f01027f7:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01027fa:	89 c2                	mov    %eax,%edx
f01027fc:	c1 ea 0c             	shr    $0xc,%edx
f01027ff:	39 d1                	cmp    %edx,%ecx
f0102801:	77 20                	ja     f0102823 <mem_init+0x1399>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102803:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102807:	c7 44 24 08 44 6d 10 	movl   $0xf0106d44,0x8(%esp)
f010280e:	f0 
f010280f:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0102816:	00 
f0102817:	c7 04 24 e0 72 10 f0 	movl   $0xf01072e0,(%esp)
f010281e:	e8 1d d8 ff ff       	call   f0100040 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102823:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010282a:	00 
f010282b:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f0102832:	00 
	return (void *)(pa + KERNBASE);
f0102833:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102838:	89 04 24             	mov    %eax,(%esp)
f010283b:	e8 b7 37 00 00       	call   f0105ff7 <memset>
	page_free(pp0);
f0102840:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102843:	89 3c 24             	mov    %edi,(%esp)
f0102846:	e8 82 e8 ff ff       	call   f01010cd <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010284b:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102852:	00 
f0102853:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010285a:	00 
f010285b:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
f0102860:	89 04 24             	mov    %eax,(%esp)
f0102863:	e8 c5 e8 ff ff       	call   f010112d <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102868:	89 fa                	mov    %edi,%edx
f010286a:	2b 15 90 1e 23 f0    	sub    0xf0231e90,%edx
f0102870:	c1 fa 03             	sar    $0x3,%edx
f0102873:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102876:	89 d0                	mov    %edx,%eax
f0102878:	c1 e8 0c             	shr    $0xc,%eax
f010287b:	3b 05 88 1e 23 f0    	cmp    0xf0231e88,%eax
f0102881:	72 20                	jb     f01028a3 <mem_init+0x1419>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102883:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102887:	c7 44 24 08 44 6d 10 	movl   $0xf0106d44,0x8(%esp)
f010288e:	f0 
f010288f:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0102896:	00 
f0102897:	c7 04 24 e0 72 10 f0 	movl   $0xf01072e0,(%esp)
f010289e:	e8 9d d7 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01028a3:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01028a9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01028ac:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01028b2:	f6 00 01             	testb  $0x1,(%eax)
f01028b5:	74 24                	je     f01028db <mem_init+0x1451>
f01028b7:	c7 44 24 0c 9a 75 10 	movl   $0xf010759a,0xc(%esp)
f01028be:	f0 
f01028bf:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f01028c6:	f0 
f01028c7:	c7 44 24 04 31 04 00 	movl   $0x431,0x4(%esp)
f01028ce:	00 
f01028cf:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f01028d6:	e8 65 d7 ff ff       	call   f0100040 <_panic>
f01028db:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01028de:	39 d0                	cmp    %edx,%eax
f01028e0:	75 d0                	jne    f01028b2 <mem_init+0x1428>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01028e2:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
f01028e7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01028ed:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01028f0:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01028f6:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01028f9:	89 0d 40 12 23 f0    	mov    %ecx,0xf0231240

	// free the pages we took
	page_free(pp0);
f01028ff:	89 04 24             	mov    %eax,(%esp)
f0102902:	e8 c6 e7 ff ff       	call   f01010cd <page_free>
	page_free(pp1);
f0102907:	89 1c 24             	mov    %ebx,(%esp)
f010290a:	e8 be e7 ff ff       	call   f01010cd <page_free>
	page_free(pp2);
f010290f:	89 34 24             	mov    %esi,(%esp)
f0102912:	e8 b6 e7 ff ff       	call   f01010cd <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f0102917:	c7 44 24 04 01 10 00 	movl   $0x1001,0x4(%esp)
f010291e:	00 
f010291f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102926:	e8 f0 ea ff ff       	call   f010141b <mmio_map_region>
f010292b:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f010292d:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102934:	00 
f0102935:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010293c:	e8 da ea ff ff       	call   f010141b <mmio_map_region>
f0102941:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8096 < MMIOLIM);
f0102943:	8d 83 a0 1f 00 00    	lea    0x1fa0(%ebx),%eax
f0102949:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f010294e:	77 08                	ja     f0102958 <mem_init+0x14ce>
f0102950:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102956:	77 24                	ja     f010297c <mem_init+0x14f2>
f0102958:	c7 44 24 0c a8 7b 10 	movl   $0xf0107ba8,0xc(%esp)
f010295f:	f0 
f0102960:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0102967:	f0 
f0102968:	c7 44 24 04 41 04 00 	movl   $0x441,0x4(%esp)
f010296f:	00 
f0102970:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0102977:	e8 c4 d6 ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f010297c:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f0102982:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f0102988:	77 08                	ja     f0102992 <mem_init+0x1508>
f010298a:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102990:	77 24                	ja     f01029b6 <mem_init+0x152c>
f0102992:	c7 44 24 0c d0 7b 10 	movl   $0xf0107bd0,0xc(%esp)
f0102999:	f0 
f010299a:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f01029a1:	f0 
f01029a2:	c7 44 24 04 42 04 00 	movl   $0x442,0x4(%esp)
f01029a9:	00 
f01029aa:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f01029b1:	e8 8a d6 ff ff       	call   f0100040 <_panic>
f01029b6:	89 da                	mov    %ebx,%edx
f01029b8:	09 f2                	or     %esi,%edx
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f01029ba:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f01029c0:	74 24                	je     f01029e6 <mem_init+0x155c>
f01029c2:	c7 44 24 0c f8 7b 10 	movl   $0xf0107bf8,0xc(%esp)
f01029c9:	f0 
f01029ca:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f01029d1:	f0 
f01029d2:	c7 44 24 04 44 04 00 	movl   $0x444,0x4(%esp)
f01029d9:	00 
f01029da:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f01029e1:	e8 5a d6 ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f01029e6:	39 c6                	cmp    %eax,%esi
f01029e8:	73 24                	jae    f0102a0e <mem_init+0x1584>
f01029ea:	c7 44 24 0c b1 75 10 	movl   $0xf01075b1,0xc(%esp)
f01029f1:	f0 
f01029f2:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f01029f9:	f0 
f01029fa:	c7 44 24 04 46 04 00 	movl   $0x446,0x4(%esp)
f0102a01:	00 
f0102a02:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0102a09:	e8 32 d6 ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f0102a0e:	8b 3d 8c 1e 23 f0    	mov    0xf0231e8c,%edi
f0102a14:	89 da                	mov    %ebx,%edx
f0102a16:	89 f8                	mov    %edi,%eax
f0102a18:	e8 a7 e1 ff ff       	call   f0100bc4 <check_va2pa>
f0102a1d:	85 c0                	test   %eax,%eax
f0102a1f:	74 24                	je     f0102a45 <mem_init+0x15bb>
f0102a21:	c7 44 24 0c 20 7c 10 	movl   $0xf0107c20,0xc(%esp)
f0102a28:	f0 
f0102a29:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0102a30:	f0 
f0102a31:	c7 44 24 04 48 04 00 	movl   $0x448,0x4(%esp)
f0102a38:	00 
f0102a39:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0102a40:	e8 fb d5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f0102a45:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f0102a4b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102a4e:	89 c2                	mov    %eax,%edx
f0102a50:	89 f8                	mov    %edi,%eax
f0102a52:	e8 6d e1 ff ff       	call   f0100bc4 <check_va2pa>
f0102a57:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0102a5c:	74 24                	je     f0102a82 <mem_init+0x15f8>
f0102a5e:	c7 44 24 0c 44 7c 10 	movl   $0xf0107c44,0xc(%esp)
f0102a65:	f0 
f0102a66:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0102a6d:	f0 
f0102a6e:	c7 44 24 04 49 04 00 	movl   $0x449,0x4(%esp)
f0102a75:	00 
f0102a76:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0102a7d:	e8 be d5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f0102a82:	89 f2                	mov    %esi,%edx
f0102a84:	89 f8                	mov    %edi,%eax
f0102a86:	e8 39 e1 ff ff       	call   f0100bc4 <check_va2pa>
f0102a8b:	85 c0                	test   %eax,%eax
f0102a8d:	74 24                	je     f0102ab3 <mem_init+0x1629>
f0102a8f:	c7 44 24 0c 74 7c 10 	movl   $0xf0107c74,0xc(%esp)
f0102a96:	f0 
f0102a97:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0102a9e:	f0 
f0102a9f:	c7 44 24 04 4a 04 00 	movl   $0x44a,0x4(%esp)
f0102aa6:	00 
f0102aa7:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0102aae:	e8 8d d5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f0102ab3:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f0102ab9:	89 f8                	mov    %edi,%eax
f0102abb:	e8 04 e1 ff ff       	call   f0100bc4 <check_va2pa>
f0102ac0:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102ac3:	74 24                	je     f0102ae9 <mem_init+0x165f>
f0102ac5:	c7 44 24 0c 98 7c 10 	movl   $0xf0107c98,0xc(%esp)
f0102acc:	f0 
f0102acd:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0102ad4:	f0 
f0102ad5:	c7 44 24 04 4b 04 00 	movl   $0x44b,0x4(%esp)
f0102adc:	00 
f0102add:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0102ae4:	e8 57 d5 ff ff       	call   f0100040 <_panic>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f0102ae9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102af0:	00 
f0102af1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102af5:	89 3c 24             	mov    %edi,(%esp)
f0102af8:	e8 30 e6 ff ff       	call   f010112d <pgdir_walk>
f0102afd:	f6 00 1a             	testb  $0x1a,(%eax)
f0102b00:	75 24                	jne    f0102b26 <mem_init+0x169c>
f0102b02:	c7 44 24 0c c4 7c 10 	movl   $0xf0107cc4,0xc(%esp)
f0102b09:	f0 
f0102b0a:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0102b11:	f0 
f0102b12:	c7 44 24 04 4d 04 00 	movl   $0x44d,0x4(%esp)
f0102b19:	00 
f0102b1a:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0102b21:	e8 1a d5 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f0102b26:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102b2d:	00 
f0102b2e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102b32:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
f0102b37:	89 04 24             	mov    %eax,(%esp)
f0102b3a:	e8 ee e5 ff ff       	call   f010112d <pgdir_walk>
f0102b3f:	f6 00 04             	testb  $0x4,(%eax)
f0102b42:	74 24                	je     f0102b68 <mem_init+0x16de>
f0102b44:	c7 44 24 0c 08 7d 10 	movl   $0xf0107d08,0xc(%esp)
f0102b4b:	f0 
f0102b4c:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0102b53:	f0 
f0102b54:	c7 44 24 04 4e 04 00 	movl   $0x44e,0x4(%esp)
f0102b5b:	00 
f0102b5c:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0102b63:	e8 d8 d4 ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f0102b68:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102b6f:	00 
f0102b70:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102b74:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
f0102b79:	89 04 24             	mov    %eax,(%esp)
f0102b7c:	e8 ac e5 ff ff       	call   f010112d <pgdir_walk>
f0102b81:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f0102b87:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102b8e:	00 
f0102b8f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b92:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102b96:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
f0102b9b:	89 04 24             	mov    %eax,(%esp)
f0102b9e:	e8 8a e5 ff ff       	call   f010112d <pgdir_walk>
f0102ba3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f0102ba9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102bb0:	00 
f0102bb1:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102bb5:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
f0102bba:	89 04 24             	mov    %eax,(%esp)
f0102bbd:	e8 6b e5 ff ff       	call   f010112d <pgdir_walk>
f0102bc2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f0102bc8:	c7 04 24 c3 75 10 f0 	movl   $0xf01075c3,(%esp)
f0102bcf:	e8 55 13 00 00       	call   f0103f29 <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	//static void boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm);
	boot_map_region(kern_pgdir, UPAGES, PTSIZE,PADDR(pages), PTE_U | PTE_P);
f0102bd4:	a1 90 1e 23 f0       	mov    0xf0231e90,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102bd9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102bde:	77 20                	ja     f0102c00 <mem_init+0x1776>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102be0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102be4:	c7 44 24 08 68 6d 10 	movl   $0xf0106d68,0x8(%esp)
f0102beb:	f0 
f0102bec:	c7 44 24 04 d0 00 00 	movl   $0xd0,0x4(%esp)
f0102bf3:	00 
f0102bf4:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0102bfb:	e8 40 d4 ff ff       	call   f0100040 <_panic>
f0102c00:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102c07:	00 
	return (physaddr_t)kva - KERNBASE;
f0102c08:	05 00 00 00 10       	add    $0x10000000,%eax
f0102c0d:	89 04 24             	mov    %eax,(%esp)
f0102c10:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102c15:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102c1a:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
f0102c1f:	e8 23 e6 ff ff       	call   f0101247 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, PTSIZE,PADDR(envs), PTE_U | PTE_P);
f0102c24:	a1 48 12 23 f0       	mov    0xf0231248,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102c29:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c2e:	77 20                	ja     f0102c50 <mem_init+0x17c6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c30:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102c34:	c7 44 24 08 68 6d 10 	movl   $0xf0106d68,0x8(%esp)
f0102c3b:	f0 
f0102c3c:	c7 44 24 04 dc 00 00 	movl   $0xdc,0x4(%esp)
f0102c43:	00 
f0102c44:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0102c4b:	e8 f0 d3 ff ff       	call   f0100040 <_panic>
f0102c50:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102c57:	00 
	return (physaddr_t)kva - KERNBASE;
f0102c58:	05 00 00 00 10       	add    $0x10000000,%eax
f0102c5d:	89 04 24             	mov    %eax,(%esp)
f0102c60:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102c65:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102c6a:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
f0102c6f:	e8 d3 e5 ff ff       	call   f0101247 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102c74:	b8 00 70 11 f0       	mov    $0xf0117000,%eax
f0102c79:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c7e:	77 20                	ja     f0102ca0 <mem_init+0x1816>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c80:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102c84:	c7 44 24 08 68 6d 10 	movl   $0xf0106d68,0x8(%esp)
f0102c8b:	f0 
f0102c8c:	c7 44 24 04 e8 00 00 	movl   $0xe8,0x4(%esp)
f0102c93:	00 
f0102c94:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0102c9b:	e8 a0 d3 ff ff       	call   f0100040 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE,PADDR(bootstack), PTE_W );
f0102ca0:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102ca7:	00 
f0102ca8:	c7 04 24 00 70 11 00 	movl   $0x117000,(%esp)
f0102caf:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102cb4:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102cb9:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
f0102cbe:	e8 84 e5 ff ff       	call   f0101247 <boot_map_region>
f0102cc3:	bf 00 30 27 f0       	mov    $0xf0273000,%edi
f0102cc8:	bb 00 30 23 f0       	mov    $0xf0233000,%ebx
f0102ccd:	be 00 80 ff ef       	mov    $0xefff8000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102cd2:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102cd8:	77 20                	ja     f0102cfa <mem_init+0x1870>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102cda:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102cde:	c7 44 24 08 68 6d 10 	movl   $0xf0106d68,0x8(%esp)
f0102ce5:	f0 
f0102ce6:	c7 44 24 04 30 01 00 	movl   $0x130,0x4(%esp)
f0102ced:	00 
f0102cee:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0102cf5:	e8 46 d3 ff ff       	call   f0100040 <_panic>
	//
	// LAB 4: Your code here:
	uint32_t i, currstack;
	for (i=0 ; i < NCPU; i++){
		currstack = KSTACKTOP - i*(KSTKSIZE + KSTKGAP) - KSTKSIZE;
		boot_map_region(kern_pgdir, currstack, KSTKSIZE, 
f0102cfa:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102d01:	00 
f0102d02:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f0102d08:	89 04 24             	mov    %eax,(%esp)
f0102d0b:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102d10:	89 f2                	mov    %esi,%edx
f0102d12:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
f0102d17:	e8 2b e5 ff ff       	call   f0101247 <boot_map_region>
f0102d1c:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f0102d22:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	//             Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	//
	// LAB 4: Your code here:
	uint32_t i, currstack;
	for (i=0 ; i < NCPU; i++){
f0102d28:	39 fb                	cmp    %edi,%ebx
f0102d2a:	75 a6                	jne    f0102cd2 <mem_init+0x1848>
	// Initialize the SMP-related parts of the memory map
	mem_init_mp();


	uint64_t kern_map_length = 0x100000000 - (uint64_t) KERNBASE;
    boot_map_region(kern_pgdir, KERNBASE,kern_map_length ,0, PTE_W | PTE_P);
f0102d2c:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102d33:	00 
f0102d34:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102d3b:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102d40:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102d45:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
f0102d4a:	e8 f8 e4 ff ff       	call   f0101247 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102d4f:	8b 3d 8c 1e 23 f0    	mov    0xf0231e8c,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102d55:	a1 88 1e 23 f0       	mov    0xf0231e88,%eax
f0102d5a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102d5d:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102d64:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102d69:	89 45 d0             	mov    %eax,-0x30(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102d6c:	8b 35 90 1e 23 f0    	mov    0xf0231e90,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102d72:	89 75 cc             	mov    %esi,-0x34(%ebp)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
f0102d75:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f0102d7b:	89 45 c8             	mov    %eax,-0x38(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102d7e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102d83:	eb 6a                	jmp    f0102def <mem_init+0x1965>
f0102d85:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102d8b:	89 f8                	mov    %edi,%eax
f0102d8d:	e8 32 de ff ff       	call   f0100bc4 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102d92:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f0102d99:	77 20                	ja     f0102dbb <mem_init+0x1931>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d9b:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0102d9f:	c7 44 24 08 68 6d 10 	movl   $0xf0106d68,0x8(%esp)
f0102da6:	f0 
f0102da7:	c7 44 24 04 66 03 00 	movl   $0x366,0x4(%esp)
f0102dae:	00 
f0102daf:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0102db6:	e8 85 d2 ff ff       	call   f0100040 <_panic>
f0102dbb:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102dbe:	8d 14 0b             	lea    (%ebx,%ecx,1),%edx
f0102dc1:	39 d0                	cmp    %edx,%eax
f0102dc3:	74 24                	je     f0102de9 <mem_init+0x195f>
f0102dc5:	c7 44 24 0c 3c 7d 10 	movl   $0xf0107d3c,0xc(%esp)
f0102dcc:	f0 
f0102dcd:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0102dd4:	f0 
f0102dd5:	c7 44 24 04 66 03 00 	movl   $0x366,0x4(%esp)
f0102ddc:	00 
f0102ddd:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0102de4:	e8 57 d2 ff ff       	call   f0100040 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102de9:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102def:	39 5d d0             	cmp    %ebx,-0x30(%ebp)
f0102df2:	77 91                	ja     f0102d85 <mem_init+0x18fb>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102df4:	8b 1d 48 12 23 f0    	mov    0xf0231248,%ebx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102dfa:	89 de                	mov    %ebx,%esi
f0102dfc:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102e01:	89 f8                	mov    %edi,%eax
f0102e03:	e8 bc dd ff ff       	call   f0100bc4 <check_va2pa>
f0102e08:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102e0e:	77 20                	ja     f0102e30 <mem_init+0x19a6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e10:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102e14:	c7 44 24 08 68 6d 10 	movl   $0xf0106d68,0x8(%esp)
f0102e1b:	f0 
f0102e1c:	c7 44 24 04 6b 03 00 	movl   $0x36b,0x4(%esp)
f0102e23:	00 
f0102e24:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0102e2b:	e8 10 d2 ff ff       	call   f0100040 <_panic>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e30:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f0102e35:	81 c6 00 00 40 21    	add    $0x21400000,%esi
f0102e3b:	8d 14 1e             	lea    (%esi,%ebx,1),%edx
f0102e3e:	39 d0                	cmp    %edx,%eax
f0102e40:	74 24                	je     f0102e66 <mem_init+0x19dc>
f0102e42:	c7 44 24 0c 70 7d 10 	movl   $0xf0107d70,0xc(%esp)
f0102e49:	f0 
f0102e4a:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0102e51:	f0 
f0102e52:	c7 44 24 04 6b 03 00 	movl   $0x36b,0x4(%esp)
f0102e59:	00 
f0102e5a:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0102e61:	e8 da d1 ff ff       	call   f0100040 <_panic>
f0102e66:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102e6c:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f0102e72:	0f 85 a8 05 00 00    	jne    f0103420 <mem_init+0x1f96>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102e78:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0102e7b:	c1 e6 0c             	shl    $0xc,%esi
f0102e7e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102e83:	eb 3b                	jmp    f0102ec0 <mem_init+0x1a36>
f0102e85:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102e8b:	89 f8                	mov    %edi,%eax
f0102e8d:	e8 32 dd ff ff       	call   f0100bc4 <check_va2pa>
f0102e92:	39 c3                	cmp    %eax,%ebx
f0102e94:	74 24                	je     f0102eba <mem_init+0x1a30>
f0102e96:	c7 44 24 0c a4 7d 10 	movl   $0xf0107da4,0xc(%esp)
f0102e9d:	f0 
f0102e9e:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0102ea5:	f0 
f0102ea6:	c7 44 24 04 6f 03 00 	movl   $0x36f,0x4(%esp)
f0102ead:	00 
f0102eae:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0102eb5:	e8 86 d1 ff ff       	call   f0100040 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102eba:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102ec0:	39 f3                	cmp    %esi,%ebx
f0102ec2:	72 c1                	jb     f0102e85 <mem_init+0x19fb>
f0102ec4:	c7 45 d0 00 30 23 f0 	movl   $0xf0233000,-0x30(%ebp)
f0102ecb:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
f0102ed2:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f0102ed7:	b8 00 30 23 f0       	mov    $0xf0233000,%eax
f0102edc:	05 00 80 00 20       	add    $0x20008000,%eax
f0102ee1:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0102ee4:	8d 86 00 80 00 00    	lea    0x8000(%esi),%eax
f0102eea:	89 45 cc             	mov    %eax,-0x34(%ebp)
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0102eed:	89 f2                	mov    %esi,%edx
f0102eef:	89 f8                	mov    %edi,%eax
f0102ef1:	e8 ce dc ff ff       	call   f0100bc4 <check_va2pa>
f0102ef6:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102ef9:	81 f9 ff ff ff ef    	cmp    $0xefffffff,%ecx
f0102eff:	77 20                	ja     f0102f21 <mem_init+0x1a97>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102f01:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0102f05:	c7 44 24 08 68 6d 10 	movl   $0xf0106d68,0x8(%esp)
f0102f0c:	f0 
f0102f0d:	c7 44 24 04 77 03 00 	movl   $0x377,0x4(%esp)
f0102f14:	00 
f0102f15:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0102f1c:	e8 1f d1 ff ff       	call   f0100040 <_panic>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102f21:	89 f3                	mov    %esi,%ebx
f0102f23:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0102f26:	03 4d d4             	add    -0x2c(%ebp),%ecx
f0102f29:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0102f2c:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102f2f:	8d 14 19             	lea    (%ecx,%ebx,1),%edx
f0102f32:	39 c2                	cmp    %eax,%edx
f0102f34:	74 24                	je     f0102f5a <mem_init+0x1ad0>
f0102f36:	c7 44 24 0c cc 7d 10 	movl   $0xf0107dcc,0xc(%esp)
f0102f3d:	f0 
f0102f3e:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0102f45:	f0 
f0102f46:	c7 44 24 04 77 03 00 	movl   $0x377,0x4(%esp)
f0102f4d:	00 
f0102f4e:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0102f55:	e8 e6 d0 ff ff       	call   f0100040 <_panic>
f0102f5a:	81 c3 00 10 00 00    	add    $0x1000,%ebx

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102f60:	3b 5d cc             	cmp    -0x34(%ebp),%ebx
f0102f63:	0f 85 a9 04 00 00    	jne    f0103412 <mem_init+0x1f88>
f0102f69:	8d 9e 00 80 ff ff    	lea    -0x8000(%esi),%ebx
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
f0102f6f:	89 da                	mov    %ebx,%edx
f0102f71:	89 f8                	mov    %edi,%eax
f0102f73:	e8 4c dc ff ff       	call   f0100bc4 <check_va2pa>
f0102f78:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102f7b:	74 24                	je     f0102fa1 <mem_init+0x1b17>
f0102f7d:	c7 44 24 0c 14 7e 10 	movl   $0xf0107e14,0xc(%esp)
f0102f84:	f0 
f0102f85:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0102f8c:	f0 
f0102f8d:	c7 44 24 04 79 03 00 	movl   $0x379,0x4(%esp)
f0102f94:	00 
f0102f95:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0102f9c:	e8 9f d0 ff ff       	call   f0100040 <_panic>
f0102fa1:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f0102fa7:	39 de                	cmp    %ebx,%esi
f0102fa9:	75 c4                	jne    f0102f6f <mem_init+0x1ae5>
f0102fab:	81 ee 00 00 01 00    	sub    $0x10000,%esi
f0102fb1:	81 45 d4 00 80 01 00 	addl   $0x18000,-0x2c(%ebp)
f0102fb8:	81 45 d0 00 80 00 00 	addl   $0x8000,-0x30(%ebp)
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
f0102fbf:	81 fe 00 80 f7 ef    	cmp    $0xeff78000,%esi
f0102fc5:	0f 85 19 ff ff ff    	jne    f0102ee4 <mem_init+0x1a5a>
f0102fcb:	b8 00 00 00 00       	mov    $0x0,%eax
f0102fd0:	e9 c2 00 00 00       	jmp    f0103097 <mem_init+0x1c0d>
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102fd5:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f0102fdb:	83 fa 04             	cmp    $0x4,%edx
f0102fde:	77 2e                	ja     f010300e <mem_init+0x1b84>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
		case PDX(MMIOBASE):
			assert(pgdir[i] & PTE_P);
f0102fe0:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f0102fe4:	0f 85 aa 00 00 00    	jne    f0103094 <mem_init+0x1c0a>
f0102fea:	c7 44 24 0c dc 75 10 	movl   $0xf01075dc,0xc(%esp)
f0102ff1:	f0 
f0102ff2:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0102ff9:	f0 
f0102ffa:	c7 44 24 04 84 03 00 	movl   $0x384,0x4(%esp)
f0103001:	00 
f0103002:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0103009:	e8 32 d0 ff ff       	call   f0100040 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f010300e:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0103013:	76 55                	jbe    f010306a <mem_init+0x1be0>
				assert(pgdir[i] & PTE_P);
f0103015:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0103018:	f6 c2 01             	test   $0x1,%dl
f010301b:	75 24                	jne    f0103041 <mem_init+0x1bb7>
f010301d:	c7 44 24 0c dc 75 10 	movl   $0xf01075dc,0xc(%esp)
f0103024:	f0 
f0103025:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f010302c:	f0 
f010302d:	c7 44 24 04 88 03 00 	movl   $0x388,0x4(%esp)
f0103034:	00 
f0103035:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f010303c:	e8 ff cf ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f0103041:	f6 c2 02             	test   $0x2,%dl
f0103044:	75 4e                	jne    f0103094 <mem_init+0x1c0a>
f0103046:	c7 44 24 0c ed 75 10 	movl   $0xf01075ed,0xc(%esp)
f010304d:	f0 
f010304e:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0103055:	f0 
f0103056:	c7 44 24 04 89 03 00 	movl   $0x389,0x4(%esp)
f010305d:	00 
f010305e:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0103065:	e8 d6 cf ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f010306a:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f010306e:	74 24                	je     f0103094 <mem_init+0x1c0a>
f0103070:	c7 44 24 0c fe 75 10 	movl   $0xf01075fe,0xc(%esp)
f0103077:	f0 
f0103078:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f010307f:	f0 
f0103080:	c7 44 24 04 8b 03 00 	movl   $0x38b,0x4(%esp)
f0103087:	00 
f0103088:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f010308f:	e8 ac cf ff ff       	call   f0100040 <_panic>
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0103094:	83 c0 01             	add    $0x1,%eax
f0103097:	3d 00 04 00 00       	cmp    $0x400,%eax
f010309c:	0f 85 33 ff ff ff    	jne    f0102fd5 <mem_init+0x1b4b>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01030a2:	c7 04 24 38 7e 10 f0 	movl   $0xf0107e38,(%esp)
f01030a9:	e8 7b 0e 00 00       	call   f0103f29 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01030ae:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
f01030b3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01030b8:	77 20                	ja     f01030da <mem_init+0x1c50>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01030ba:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01030be:	c7 44 24 08 68 6d 10 	movl   $0xf0106d68,0x8(%esp)
f01030c5:	f0 
f01030c6:	c7 44 24 04 07 01 00 	movl   $0x107,0x4(%esp)
f01030cd:	00 
f01030ce:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f01030d5:	e8 66 cf ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01030da:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01030df:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01030e2:	b8 00 00 00 00       	mov    $0x0,%eax
f01030e7:	e8 47 db ff ff       	call   f0100c33 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f01030ec:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f01030ef:	83 e0 f3             	and    $0xfffffff3,%eax
f01030f2:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f01030f7:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01030fa:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103101:	e8 3c df ff ff       	call   f0101042 <page_alloc>
f0103106:	89 c3                	mov    %eax,%ebx
f0103108:	85 c0                	test   %eax,%eax
f010310a:	75 24                	jne    f0103130 <mem_init+0x1ca6>
f010310c:	c7 44 24 0c e8 73 10 	movl   $0xf01073e8,0xc(%esp)
f0103113:	f0 
f0103114:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f010311b:	f0 
f010311c:	c7 44 24 04 63 04 00 	movl   $0x463,0x4(%esp)
f0103123:	00 
f0103124:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f010312b:	e8 10 cf ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0103130:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103137:	e8 06 df ff ff       	call   f0101042 <page_alloc>
f010313c:	89 c7                	mov    %eax,%edi
f010313e:	85 c0                	test   %eax,%eax
f0103140:	75 24                	jne    f0103166 <mem_init+0x1cdc>
f0103142:	c7 44 24 0c fe 73 10 	movl   $0xf01073fe,0xc(%esp)
f0103149:	f0 
f010314a:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0103151:	f0 
f0103152:	c7 44 24 04 64 04 00 	movl   $0x464,0x4(%esp)
f0103159:	00 
f010315a:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0103161:	e8 da ce ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0103166:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010316d:	e8 d0 de ff ff       	call   f0101042 <page_alloc>
f0103172:	89 c6                	mov    %eax,%esi
f0103174:	85 c0                	test   %eax,%eax
f0103176:	75 24                	jne    f010319c <mem_init+0x1d12>
f0103178:	c7 44 24 0c 14 74 10 	movl   $0xf0107414,0xc(%esp)
f010317f:	f0 
f0103180:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0103187:	f0 
f0103188:	c7 44 24 04 65 04 00 	movl   $0x465,0x4(%esp)
f010318f:	00 
f0103190:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0103197:	e8 a4 ce ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f010319c:	89 1c 24             	mov    %ebx,(%esp)
f010319f:	e8 29 df ff ff       	call   f01010cd <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f01031a4:	89 f8                	mov    %edi,%eax
f01031a6:	e8 d4 d9 ff ff       	call   f0100b7f <page2kva>
f01031ab:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01031b2:	00 
f01031b3:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01031ba:	00 
f01031bb:	89 04 24             	mov    %eax,(%esp)
f01031be:	e8 34 2e 00 00       	call   f0105ff7 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f01031c3:	89 f0                	mov    %esi,%eax
f01031c5:	e8 b5 d9 ff ff       	call   f0100b7f <page2kva>
f01031ca:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01031d1:	00 
f01031d2:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f01031d9:	00 
f01031da:	89 04 24             	mov    %eax,(%esp)
f01031dd:	e8 15 2e 00 00       	call   f0105ff7 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01031e2:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01031e9:	00 
f01031ea:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01031f1:	00 
f01031f2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01031f6:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
f01031fb:	89 04 24             	mov    %eax,(%esp)
f01031fe:	e8 97 e1 ff ff       	call   f010139a <page_insert>
	assert(pp1->pp_ref == 1);
f0103203:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0103208:	74 24                	je     f010322e <mem_init+0x1da4>
f010320a:	c7 44 24 0c e5 74 10 	movl   $0xf01074e5,0xc(%esp)
f0103211:	f0 
f0103212:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0103219:	f0 
f010321a:	c7 44 24 04 6a 04 00 	movl   $0x46a,0x4(%esp)
f0103221:	00 
f0103222:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0103229:	e8 12 ce ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010322e:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0103235:	01 01 01 
f0103238:	74 24                	je     f010325e <mem_init+0x1dd4>
f010323a:	c7 44 24 0c 58 7e 10 	movl   $0xf0107e58,0xc(%esp)
f0103241:	f0 
f0103242:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0103249:	f0 
f010324a:	c7 44 24 04 6b 04 00 	movl   $0x46b,0x4(%esp)
f0103251:	00 
f0103252:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0103259:	e8 e2 cd ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f010325e:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0103265:	00 
f0103266:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010326d:	00 
f010326e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103272:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
f0103277:	89 04 24             	mov    %eax,(%esp)
f010327a:	e8 1b e1 ff ff       	call   f010139a <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010327f:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0103286:	02 02 02 
f0103289:	74 24                	je     f01032af <mem_init+0x1e25>
f010328b:	c7 44 24 0c 7c 7e 10 	movl   $0xf0107e7c,0xc(%esp)
f0103292:	f0 
f0103293:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f010329a:	f0 
f010329b:	c7 44 24 04 6d 04 00 	movl   $0x46d,0x4(%esp)
f01032a2:	00 
f01032a3:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f01032aa:	e8 91 cd ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f01032af:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01032b4:	74 24                	je     f01032da <mem_init+0x1e50>
f01032b6:	c7 44 24 0c 07 75 10 	movl   $0xf0107507,0xc(%esp)
f01032bd:	f0 
f01032be:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f01032c5:	f0 
f01032c6:	c7 44 24 04 6e 04 00 	movl   $0x46e,0x4(%esp)
f01032cd:	00 
f01032ce:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f01032d5:	e8 66 cd ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f01032da:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01032df:	74 24                	je     f0103305 <mem_init+0x1e7b>
f01032e1:	c7 44 24 0c 71 75 10 	movl   $0xf0107571,0xc(%esp)
f01032e8:	f0 
f01032e9:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f01032f0:	f0 
f01032f1:	c7 44 24 04 6f 04 00 	movl   $0x46f,0x4(%esp)
f01032f8:	00 
f01032f9:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f0103300:	e8 3b cd ff ff       	call   f0100040 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0103305:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f010330c:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f010330f:	89 f0                	mov    %esi,%eax
f0103311:	e8 69 d8 ff ff       	call   f0100b7f <page2kva>
f0103316:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f010331c:	74 24                	je     f0103342 <mem_init+0x1eb8>
f010331e:	c7 44 24 0c a0 7e 10 	movl   $0xf0107ea0,0xc(%esp)
f0103325:	f0 
f0103326:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f010332d:	f0 
f010332e:	c7 44 24 04 71 04 00 	movl   $0x471,0x4(%esp)
f0103335:	00 
f0103336:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f010333d:	e8 fe cc ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0103342:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0103349:	00 
f010334a:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
f010334f:	89 04 24             	mov    %eax,(%esp)
f0103352:	e8 f3 df ff ff       	call   f010134a <page_remove>
	assert(pp2->pp_ref == 0);
f0103357:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010335c:	74 24                	je     f0103382 <mem_init+0x1ef8>
f010335e:	c7 44 24 0c 3f 75 10 	movl   $0xf010753f,0xc(%esp)
f0103365:	f0 
f0103366:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f010336d:	f0 
f010336e:	c7 44 24 04 73 04 00 	movl   $0x473,0x4(%esp)
f0103375:	00 
f0103376:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f010337d:	e8 be cc ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0103382:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
f0103387:	8b 08                	mov    (%eax),%ecx
f0103389:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010338f:	89 da                	mov    %ebx,%edx
f0103391:	2b 15 90 1e 23 f0    	sub    0xf0231e90,%edx
f0103397:	c1 fa 03             	sar    $0x3,%edx
f010339a:	c1 e2 0c             	shl    $0xc,%edx
f010339d:	39 d1                	cmp    %edx,%ecx
f010339f:	74 24                	je     f01033c5 <mem_init+0x1f3b>
f01033a1:	c7 44 24 0c 28 78 10 	movl   $0xf0107828,0xc(%esp)
f01033a8:	f0 
f01033a9:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f01033b0:	f0 
f01033b1:	c7 44 24 04 76 04 00 	movl   $0x476,0x4(%esp)
f01033b8:	00 
f01033b9:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f01033c0:	e8 7b cc ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f01033c5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f01033cb:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01033d0:	74 24                	je     f01033f6 <mem_init+0x1f6c>
f01033d2:	c7 44 24 0c f6 74 10 	movl   $0xf01074f6,0xc(%esp)
f01033d9:	f0 
f01033da:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f01033e1:	f0 
f01033e2:	c7 44 24 04 78 04 00 	movl   $0x478,0x4(%esp)
f01033e9:	00 
f01033ea:	c7 04 24 d4 72 10 f0 	movl   $0xf01072d4,(%esp)
f01033f1:	e8 4a cc ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f01033f6:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01033fc:	89 1c 24             	mov    %ebx,(%esp)
f01033ff:	e8 c9 dc ff ff       	call   f01010cd <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0103404:	c7 04 24 cc 7e 10 f0 	movl   $0xf0107ecc,(%esp)
f010340b:	e8 19 0b 00 00       	call   f0103f29 <cprintf>
f0103410:	eb 1c                	jmp    f010342e <mem_init+0x1fa4>
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0103412:	89 da                	mov    %ebx,%edx
f0103414:	89 f8                	mov    %edi,%eax
f0103416:	e8 a9 d7 ff ff       	call   f0100bc4 <check_va2pa>
f010341b:	e9 0c fb ff ff       	jmp    f0102f2c <mem_init+0x1aa2>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0103420:	89 da                	mov    %ebx,%edx
f0103422:	89 f8                	mov    %edi,%eax
f0103424:	e8 9b d7 ff ff       	call   f0100bc4 <check_va2pa>
f0103429:	e9 0d fa ff ff       	jmp    f0102e3b <mem_init+0x19b1>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f010342e:	83 c4 4c             	add    $0x4c,%esp
f0103431:	5b                   	pop    %ebx
f0103432:	5e                   	pop    %esi
f0103433:	5f                   	pop    %edi
f0103434:	5d                   	pop    %ebp
f0103435:	c3                   	ret    

f0103436 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0103436:	55                   	push   %ebp
f0103437:	89 e5                	mov    %esp,%ebp
f0103439:	57                   	push   %edi
f010343a:	56                   	push   %esi
f010343b:	53                   	push   %ebx
f010343c:	83 ec 1c             	sub    $0x1c,%esp
f010343f:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	pte_t *pte;
	uint32_t addr = ROUNDDOWN((uint32_t) va, PGSIZE);
f0103442:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103445:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uint32_t end = ROUNDUP((uint32_t) va + len, PGSIZE);
f010344b:	8b 45 10             	mov    0x10(%ebp),%eax
f010344e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103451:	8d 84 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%eax
f0103458:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010345d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	perm |= PTE_P;
f0103460:	8b 75 14             	mov    0x14(%ebp),%esi
f0103463:	83 ce 01             	or     $0x1,%esi

	for (; addr < end; addr += PGSIZE) {
f0103466:	eb 45                	jmp    f01034ad <user_mem_check+0x77>
		pte = pgdir_walk(env->env_pgdir, (void*) addr, 0); 
f0103468:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010346f:	00 
f0103470:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103474:	8b 47 78             	mov    0x78(%edi),%eax
f0103477:	89 04 24             	mov    %eax,(%esp)
f010347a:	e8 ae dc ff ff       	call   f010112d <pgdir_walk>
		
		if (!pte|| addr >= ULIM|| ((*pte & perm) != perm) ) {
f010347f:	85 c0                	test   %eax,%eax
f0103481:	74 10                	je     f0103493 <user_mem_check+0x5d>
f0103483:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0103489:	77 08                	ja     f0103493 <user_mem_check+0x5d>
f010348b:	89 f2                	mov    %esi,%edx
f010348d:	23 10                	and    (%eax),%edx
f010348f:	39 d6                	cmp    %edx,%esi
f0103491:	74 14                	je     f01034a7 <user_mem_check+0x71>
f0103493:	3b 5d 0c             	cmp    0xc(%ebp),%ebx
f0103496:	0f 42 5d 0c          	cmovb  0xc(%ebp),%ebx
			user_mem_check_addr = addr < (uint32_t) va ? (uintptr_t) va : addr;
f010349a:	89 1d 3c 12 23 f0    	mov    %ebx,0xf023123c
			return -E_FAULT;
f01034a0:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01034a5:	eb 10                	jmp    f01034b7 <user_mem_check+0x81>
	pte_t *pte;
	uint32_t addr = ROUNDDOWN((uint32_t) va, PGSIZE);
	uint32_t end = ROUNDUP((uint32_t) va + len, PGSIZE);
	perm |= PTE_P;

	for (; addr < end; addr += PGSIZE) {
f01034a7:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01034ad:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f01034b0:	72 b6                	jb     f0103468 <user_mem_check+0x32>
			user_mem_check_addr = addr < (uint32_t) va ? (uintptr_t) va : addr;
			return -E_FAULT;
		}
	}

	return 0;
f01034b2:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01034b7:	83 c4 1c             	add    $0x1c,%esp
f01034ba:	5b                   	pop    %ebx
f01034bb:	5e                   	pop    %esi
f01034bc:	5f                   	pop    %edi
f01034bd:	5d                   	pop    %ebp
f01034be:	c3                   	ret    

f01034bf <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f01034bf:	55                   	push   %ebp
f01034c0:	89 e5                	mov    %esp,%ebp
f01034c2:	53                   	push   %ebx
f01034c3:	83 ec 14             	sub    $0x14,%esp
f01034c6:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f01034c9:	8b 45 14             	mov    0x14(%ebp),%eax
f01034cc:	83 c8 04             	or     $0x4,%eax
f01034cf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01034d3:	8b 45 10             	mov    0x10(%ebp),%eax
f01034d6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01034da:	8b 45 0c             	mov    0xc(%ebp),%eax
f01034dd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01034e1:	89 1c 24             	mov    %ebx,(%esp)
f01034e4:	e8 4d ff ff ff       	call   f0103436 <user_mem_check>
f01034e9:	85 c0                	test   %eax,%eax
f01034eb:	79 24                	jns    f0103511 <user_mem_assert+0x52>
		cprintf("[%08x] user_mem_check assertion failure for "
f01034ed:	a1 3c 12 23 f0       	mov    0xf023123c,%eax
f01034f2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01034f6:	8b 43 48             	mov    0x48(%ebx),%eax
f01034f9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01034fd:	c7 04 24 f8 7e 10 f0 	movl   $0xf0107ef8,(%esp)
f0103504:	e8 20 0a 00 00       	call   f0103f29 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0103509:	89 1c 24             	mov    %ebx,(%esp)
f010350c:	e8 0c 07 00 00       	call   f0103c1d <env_destroy>
	}
}
f0103511:	83 c4 14             	add    $0x14,%esp
f0103514:	5b                   	pop    %ebx
f0103515:	5d                   	pop    %ebp
f0103516:	c3                   	ret    

f0103517 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0103517:	55                   	push   %ebp
f0103518:	89 e5                	mov    %esp,%ebp
f010351a:	57                   	push   %edi
f010351b:	56                   	push   %esi
f010351c:	53                   	push   %ebx
f010351d:	83 ec 1c             	sub    $0x1c,%esp
f0103520:	89 c7                	mov    %eax,%edi
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	
	uint32_t startadd=(uint32_t)ROUNDDOWN(va,PGSIZE);
f0103522:	89 d3                	mov    %edx,%ebx
f0103524:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uint32_t endadd=(uint32_t)ROUNDUP(va+len,PGSIZE);
f010352a:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0103531:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	
	while(startadd<endadd)
f0103537:	eb 6e                	jmp    f01035a7 <region_alloc+0x90>
	{
	struct PageInfo* p=page_alloc(false);	
f0103539:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103540:	e8 fd da ff ff       	call   f0101042 <page_alloc>
	
	if(p==NULL)
f0103545:	85 c0                	test   %eax,%eax
f0103547:	75 1c                	jne    f0103565 <region_alloc+0x4e>
	panic("Fail to alloc a page right now in region_alloc");
f0103549:	c7 44 24 08 30 7f 10 	movl   $0xf0107f30,0x8(%esp)
f0103550:	f0 
f0103551:	c7 44 24 04 45 01 00 	movl   $0x145,0x4(%esp)
f0103558:	00 
f0103559:	c7 04 24 5f 7f 10 f0 	movl   $0xf0107f5f,(%esp)
f0103560:	e8 db ca ff ff       	call   f0100040 <_panic>
	
	if(page_insert(e->env_pgdir,p,(void *)startadd,PTE_U|PTE_W)==-E_NO_MEM)
f0103565:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f010356c:	00 
f010356d:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103571:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103575:	8b 47 78             	mov    0x78(%edi),%eax
f0103578:	89 04 24             	mov    %eax,(%esp)
f010357b:	e8 1a de ff ff       	call   f010139a <page_insert>
f0103580:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0103583:	75 1c                	jne    f01035a1 <region_alloc+0x8a>
	panic("page insert failed");
f0103585:	c7 44 24 08 6a 7f 10 	movl   $0xf0107f6a,0x8(%esp)
f010358c:	f0 
f010358d:	c7 44 24 04 48 01 00 	movl   $0x148,0x4(%esp)
f0103594:	00 
f0103595:	c7 04 24 5f 7f 10 f0 	movl   $0xf0107f5f,(%esp)
f010359c:	e8 9f ca ff ff       	call   f0100040 <_panic>
	
	startadd+=PGSIZE;
f01035a1:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	//   (Watch out for corner-cases!)
	
	uint32_t startadd=(uint32_t)ROUNDDOWN(va,PGSIZE);
	uint32_t endadd=(uint32_t)ROUNDUP(va+len,PGSIZE);
	
	while(startadd<endadd)
f01035a7:	39 f3                	cmp    %esi,%ebx
f01035a9:	72 8e                	jb     f0103539 <region_alloc+0x22>
	
	startadd+=PGSIZE;
		
	}
	
}
f01035ab:	83 c4 1c             	add    $0x1c,%esp
f01035ae:	5b                   	pop    %ebx
f01035af:	5e                   	pop    %esi
f01035b0:	5f                   	pop    %edi
f01035b1:	5d                   	pop    %ebp
f01035b2:	c3                   	ret    

f01035b3 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f01035b3:	55                   	push   %ebp
f01035b4:	89 e5                	mov    %esp,%ebp
f01035b6:	56                   	push   %esi
f01035b7:	53                   	push   %ebx
f01035b8:	8b 45 08             	mov    0x8(%ebp),%eax
f01035bb:	8b 55 10             	mov    0x10(%ebp),%edx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f01035be:	85 c0                	test   %eax,%eax
f01035c0:	75 1a                	jne    f01035dc <envid2env+0x29>
		*env_store = curenv;
f01035c2:	e8 82 30 00 00       	call   f0106649 <cpunum>
f01035c7:	6b c0 74             	imul   $0x74,%eax,%eax
f01035ca:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f01035d0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01035d3:	89 01                	mov    %eax,(%ecx)
		return 0;
f01035d5:	b8 00 00 00 00       	mov    $0x0,%eax
f01035da:	eb 70                	jmp    f010364c <envid2env+0x99>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f01035dc:	89 c3                	mov    %eax,%ebx
f01035de:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f01035e4:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f01035e7:	03 1d 48 12 23 f0    	add    0xf0231248,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f01035ed:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f01035f1:	74 05                	je     f01035f8 <envid2env+0x45>
f01035f3:	39 43 48             	cmp    %eax,0x48(%ebx)
f01035f6:	74 10                	je     f0103608 <envid2env+0x55>
		*env_store = 0;
f01035f8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01035fb:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103601:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103606:	eb 44                	jmp    f010364c <envid2env+0x99>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0103608:	84 d2                	test   %dl,%dl
f010360a:	74 36                	je     f0103642 <envid2env+0x8f>
f010360c:	e8 38 30 00 00       	call   f0106649 <cpunum>
f0103611:	6b c0 74             	imul   $0x74,%eax,%eax
f0103614:	39 98 28 20 23 f0    	cmp    %ebx,-0xfdcdfd8(%eax)
f010361a:	74 26                	je     f0103642 <envid2env+0x8f>
f010361c:	8b 73 4c             	mov    0x4c(%ebx),%esi
f010361f:	e8 25 30 00 00       	call   f0106649 <cpunum>
f0103624:	6b c0 74             	imul   $0x74,%eax,%eax
f0103627:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f010362d:	3b 70 48             	cmp    0x48(%eax),%esi
f0103630:	74 10                	je     f0103642 <envid2env+0x8f>
		*env_store = 0;
f0103632:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103635:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f010363b:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103640:	eb 0a                	jmp    f010364c <envid2env+0x99>
	}

	*env_store = e;
f0103642:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103645:	89 18                	mov    %ebx,(%eax)
	return 0;
f0103647:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010364c:	5b                   	pop    %ebx
f010364d:	5e                   	pop    %esi
f010364e:	5d                   	pop    %ebp
f010364f:	c3                   	ret    

f0103650 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0103650:	55                   	push   %ebp
f0103651:	89 e5                	mov    %esp,%ebp
}

static inline void
lgdt(void *p)
{
	asm volatile("lgdt (%0)" : : "r" (p));
f0103653:	b8 20 13 12 f0       	mov    $0xf0121320,%eax
f0103658:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f010365b:	b8 23 00 00 00       	mov    $0x23,%eax
f0103660:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f0103662:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f0103664:	b0 10                	mov    $0x10,%al
f0103666:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f0103668:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f010366a:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f010366c:	ea 73 36 10 f0 08 00 	ljmp   $0x8,$0xf0103673
}

static inline void
lldt(uint16_t sel)
{
	asm volatile("lldt %0" : : "r" (sel));
f0103673:	b0 00                	mov    $0x0,%al
f0103675:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0103678:	5d                   	pop    %ebp
f0103679:	c3                   	ret    

f010367a <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f010367a:	55                   	push   %ebp
f010367b:	89 e5                	mov    %esp,%ebp
f010367d:	56                   	push   %esi
f010367e:	53                   	push   %ebx
	// LAB 3: Your code here.
	
	env_free_list = 0;
	
	for (int i = NENV - 1 ; i >= 0; i--){
		envs[i].env_link = env_free_list;
f010367f:	8b 35 48 12 23 f0    	mov    0xf0231248,%esi
f0103685:	8d 86 84 ef 01 00    	lea    0x1ef84(%esi),%eax
f010368b:	ba 00 04 00 00       	mov    $0x400,%edx
f0103690:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103695:	89 c3                	mov    %eax,%ebx
f0103697:	89 48 44             	mov    %ecx,0x44(%eax)
		envs[i].env_status = ENV_FREE;
f010369a:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
f01036a1:	83 e8 7c             	sub    $0x7c,%eax
	// Set up envs array
	// LAB 3: Your code here.
	
	env_free_list = 0;
	
	for (int i = NENV - 1 ; i >= 0; i--){
f01036a4:	83 ea 01             	sub    $0x1,%edx
f01036a7:	74 04                	je     f01036ad <env_init+0x33>
		envs[i].env_link = env_free_list;
		envs[i].env_status = ENV_FREE;
		env_free_list = &envs[i];
f01036a9:	89 d9                	mov    %ebx,%ecx
f01036ab:	eb e8                	jmp    f0103695 <env_init+0x1b>
f01036ad:	89 35 4c 12 23 f0    	mov    %esi,0xf023124c
	}
	// Per-CPU part of the initialization
	env_init_percpu();
f01036b3:	e8 98 ff ff ff       	call   f0103650 <env_init_percpu>
	
	
}
f01036b8:	5b                   	pop    %ebx
f01036b9:	5e                   	pop    %esi
f01036ba:	5d                   	pop    %ebp
f01036bb:	c3                   	ret    

f01036bc <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f01036bc:	55                   	push   %ebp
f01036bd:	89 e5                	mov    %esp,%ebp
f01036bf:	53                   	push   %ebx
f01036c0:	83 ec 14             	sub    $0x14,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f01036c3:	8b 1d 4c 12 23 f0    	mov    0xf023124c,%ebx
f01036c9:	85 db                	test   %ebx,%ebx
f01036cb:	0f 84 b1 01 00 00    	je     f0103882 <env_alloc+0x1c6>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f01036d1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01036d8:	e8 65 d9 ff ff       	call   f0101042 <page_alloc>
f01036dd:	85 c0                	test   %eax,%eax
f01036df:	0f 84 a4 01 00 00    	je     f0103889 <env_alloc+0x1cd>
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	
	p->pp_ref++;
f01036e5:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
f01036ea:	2b 05 90 1e 23 f0    	sub    0xf0231e90,%eax
f01036f0:	c1 f8 03             	sar    $0x3,%eax
f01036f3:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01036f6:	89 c2                	mov    %eax,%edx
f01036f8:	c1 ea 0c             	shr    $0xc,%edx
f01036fb:	3b 15 88 1e 23 f0    	cmp    0xf0231e88,%edx
f0103701:	72 20                	jb     f0103723 <env_alloc+0x67>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103703:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103707:	c7 44 24 08 44 6d 10 	movl   $0xf0106d44,0x8(%esp)
f010370e:	f0 
f010370f:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0103716:	00 
f0103717:	c7 04 24 e0 72 10 f0 	movl   $0xf01072e0,(%esp)
f010371e:	e8 1d c9 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0103723:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0103728:	89 43 78             	mov    %eax,0x78(%ebx)
	
	// set e->env_pgdir and initialize the page directory.
	e->env_pgdir = (pde_t *) page2kva(p);
	
	for (i = 0; i < PDX(UTOP); i++)
f010372b:	b8 00 00 00 00       	mov    $0x0,%eax
f0103730:	ba 00 00 00 00       	mov    $0x0,%edx
		e->env_pgdir[i] = 0;
f0103735:	8b 4b 78             	mov    0x78(%ebx),%ecx
f0103738:	c7 04 91 00 00 00 00 	movl   $0x0,(%ecx,%edx,4)
	p->pp_ref++;
	
	// set e->env_pgdir and initialize the page directory.
	e->env_pgdir = (pde_t *) page2kva(p);
	
	for (i = 0; i < PDX(UTOP); i++)
f010373f:	83 c0 01             	add    $0x1,%eax
f0103742:	89 c2                	mov    %eax,%edx
f0103744:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0103749:	75 ea                	jne    f0103735 <env_alloc+0x79>
f010374b:	66 b8 ec 0e          	mov    $0xeec,%ax
		e->env_pgdir[i] = 0;

	for (i = PDX(UTOP); i < NPDENTRIES; i++)
		e->env_pgdir[i] = kern_pgdir[i];	
f010374f:	8b 15 8c 1e 23 f0    	mov    0xf0231e8c,%edx
f0103755:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f0103758:	8b 53 78             	mov    0x78(%ebx),%edx
f010375b:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f010375e:	83 c0 04             	add    $0x4,%eax
	e->env_pgdir = (pde_t *) page2kva(p);
	
	for (i = 0; i < PDX(UTOP); i++)
		e->env_pgdir[i] = 0;

	for (i = PDX(UTOP); i < NPDENTRIES; i++)
f0103761:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0103766:	75 e7                	jne    f010374f <env_alloc+0x93>
		
	
	
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0103768:	8b 43 78             	mov    0x78(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010376b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103770:	77 20                	ja     f0103792 <env_alloc+0xd6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103772:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103776:	c7 44 24 08 68 6d 10 	movl   $0xf0106d68,0x8(%esp)
f010377d:	f0 
f010377e:	c7 44 24 04 d8 00 00 	movl   $0xd8,0x4(%esp)
f0103785:	00 
f0103786:	c7 04 24 5f 7f 10 f0 	movl   $0xf0107f5f,(%esp)
f010378d:	e8 ae c8 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103792:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0103798:	83 ca 05             	or     $0x5,%edx
f010379b:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01037a1:	8b 43 48             	mov    0x48(%ebx),%eax
f01037a4:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f01037a9:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f01037ae:	ba 00 10 00 00       	mov    $0x1000,%edx
f01037b3:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01037b6:	89 da                	mov    %ebx,%edx
f01037b8:	2b 15 48 12 23 f0    	sub    0xf0231248,%edx
f01037be:	c1 fa 02             	sar    $0x2,%edx
f01037c1:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f01037c7:	09 d0                	or     %edx,%eax
f01037c9:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f01037cc:	8b 45 0c             	mov    0xc(%ebp),%eax
f01037cf:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f01037d2:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f01037d9:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f01037e0:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f01037e7:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f01037ee:	00 
f01037ef:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01037f6:	00 
f01037f7:	89 1c 24             	mov    %ebx,(%esp)
f01037fa:	e8 f8 27 00 00       	call   f0105ff7 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f01037ff:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0103805:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f010380b:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0103811:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0103818:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// Enable interrupts while in user mode.
	// LAB 4: Your code here.

	if((e->env_tf.tf_cs & 3)==3)
	{
		e->env_tf.tf_eflags= (e->env_tf.tf_eflags | FL_IF);
f010381e:	81 4b 38 00 02 00 00 	orl    $0x200,0x38(%ebx)
	}


	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f0103825:	c7 43 60 00 00 00 00 	movl   $0x0,0x60(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f010382c:	c6 43 64 00          	movb   $0x0,0x64(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f0103830:	8b 43 44             	mov    0x44(%ebx),%eax
f0103833:	a3 4c 12 23 f0       	mov    %eax,0xf023124c
	*newenv_store = e;
f0103838:	8b 45 08             	mov    0x8(%ebp),%eax
f010383b:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f010383d:	8b 5b 48             	mov    0x48(%ebx),%ebx
f0103840:	e8 04 2e 00 00       	call   f0106649 <cpunum>
f0103845:	6b d0 74             	imul   $0x74,%eax,%edx
f0103848:	b8 00 00 00 00       	mov    $0x0,%eax
f010384d:	83 ba 28 20 23 f0 00 	cmpl   $0x0,-0xfdcdfd8(%edx)
f0103854:	74 11                	je     f0103867 <env_alloc+0x1ab>
f0103856:	e8 ee 2d 00 00       	call   f0106649 <cpunum>
f010385b:	6b c0 74             	imul   $0x74,%eax,%eax
f010385e:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f0103864:	8b 40 48             	mov    0x48(%eax),%eax
f0103867:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010386b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010386f:	c7 04 24 7d 7f 10 f0 	movl   $0xf0107f7d,(%esp)
f0103876:	e8 ae 06 00 00       	call   f0103f29 <cprintf>
	return 0;
f010387b:	b8 00 00 00 00       	mov    $0x0,%eax
f0103880:	eb 0c                	jmp    f010388e <env_alloc+0x1d2>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0103882:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0103887:	eb 05                	jmp    f010388e <env_alloc+0x1d2>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0103889:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f010388e:	83 c4 14             	add    $0x14,%esp
f0103891:	5b                   	pop    %ebx
f0103892:	5d                   	pop    %ebp
f0103893:	c3                   	ret    

f0103894 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0103894:	55                   	push   %ebp
f0103895:	89 e5                	mov    %esp,%ebp
f0103897:	57                   	push   %edi
f0103898:	56                   	push   %esi
f0103899:	53                   	push   %ebx
f010389a:	83 ec 3c             	sub    $0x3c,%esp
f010389d:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	
	struct Env *env;
	
	int check;
	check = env_alloc(&env, 0);
f01038a0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01038a7:	00 
f01038a8:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01038ab:	89 04 24             	mov    %eax,(%esp)
f01038ae:	e8 09 fe ff ff       	call   f01036bc <env_alloc>
	
	if (check < 0) {
f01038b3:	85 c0                	test   %eax,%eax
f01038b5:	79 20                	jns    f01038d7 <env_create+0x43>
		panic("env_alloc: %e", check);
f01038b7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01038bb:	c7 44 24 08 92 7f 10 	movl   $0xf0107f92,0x8(%esp)
f01038c2:	f0 
f01038c3:	c7 44 24 04 cd 01 00 	movl   $0x1cd,0x4(%esp)
f01038ca:	00 
f01038cb:	c7 04 24 5f 7f 10 f0 	movl   $0xf0107f5f,(%esp)
f01038d2:	e8 69 c7 ff ff       	call   f0100040 <_panic>
		return;
	}
	
	load_icode(env, binary);
f01038d7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01038da:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// LAB 3: Your code here.
	
		// read 1st page off disk
	//readseg((uint32_t) ELFHDR, SECTSIZE*8, 0);
	
	lcr3(PADDR(e->env_pgdir));
f01038dd:	8b 40 78             	mov    0x78(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01038e0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01038e5:	77 20                	ja     f0103907 <env_create+0x73>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01038e7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01038eb:	c7 44 24 08 68 6d 10 	movl   $0xf0106d68,0x8(%esp)
f01038f2:	f0 
f01038f3:	c7 44 24 04 90 01 00 	movl   $0x190,0x4(%esp)
f01038fa:	00 
f01038fb:	c7 04 24 5f 7f 10 f0 	movl   $0xf0107f5f,(%esp)
f0103902:	e8 39 c7 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103907:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f010390c:	0f 22 d8             	mov    %eax,%cr3
	struct Proghdr *ph, *eph;
	struct Elf * ELFHDR=(struct Elf *) binary;
	// is this a valid ELF?
	
	if (ELFHDR->e_magic != ELF_MAGIC)
f010390f:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0103915:	74 1c                	je     f0103933 <env_create+0x9f>
		panic("Not an elf file \n");
f0103917:	c7 44 24 08 a0 7f 10 	movl   $0xf0107fa0,0x8(%esp)
f010391e:	f0 
f010391f:	c7 44 24 04 96 01 00 	movl   $0x196,0x4(%esp)
f0103926:	00 
f0103927:	c7 04 24 5f 7f 10 f0 	movl   $0xf0107f5f,(%esp)
f010392e:	e8 0d c7 ff ff       	call   f0100040 <_panic>

	// load each program segment (ignores ph flags)
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
f0103933:	89 fb                	mov    %edi,%ebx
f0103935:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + ELFHDR->e_phnum;
f0103938:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f010393c:	c1 e6 05             	shl    $0x5,%esi
f010393f:	01 de                	add    %ebx,%esi
	 
	e->env_tf.tf_eip = ELFHDR->e_entry;
f0103941:	8b 47 18             	mov    0x18(%edi),%eax
f0103944:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0103947:	89 41 30             	mov    %eax,0x30(%ecx)
f010394a:	eb 71                	jmp    f01039bd <env_create+0x129>
	
	
	for (; ph < eph; ph++)
{		
	
	if (ph->p_type != ELF_PROG_LOAD) 
f010394c:	83 3b 01             	cmpl   $0x1,(%ebx)
f010394f:	75 69                	jne    f01039ba <env_create+0x126>
	continue;
	
	if (ph->p_filesz > ph->p_memsz)
f0103951:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0103954:	39 4b 10             	cmp    %ecx,0x10(%ebx)
f0103957:	76 1c                	jbe    f0103975 <env_create+0xe1>
	panic("file size greater \n");
f0103959:	c7 44 24 08 b2 7f 10 	movl   $0xf0107fb2,0x8(%esp)
f0103960:	f0 
f0103961:	c7 44 24 04 a8 01 00 	movl   $0x1a8,0x4(%esp)
f0103968:	00 
f0103969:	c7 04 24 5f 7f 10 f0 	movl   $0xf0107f5f,(%esp)
f0103970:	e8 cb c6 ff ff       	call   f0100040 <_panic>
	
	region_alloc(e, (void *) ph->p_va, ph->p_memsz);
f0103975:	8b 53 08             	mov    0x8(%ebx),%edx
f0103978:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010397b:	e8 97 fb ff ff       	call   f0103517 <region_alloc>
	
	memcpy((void *) ph->p_va, binary+ph->p_offset, ph->p_filesz);
f0103980:	8b 43 10             	mov    0x10(%ebx),%eax
f0103983:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103987:	89 f8                	mov    %edi,%eax
f0103989:	03 43 04             	add    0x4(%ebx),%eax
f010398c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103990:	8b 43 08             	mov    0x8(%ebx),%eax
f0103993:	89 04 24             	mov    %eax,(%esp)
f0103996:	e8 11 27 00 00       	call   f01060ac <memcpy>
	
	memset((void *) ph->p_va + ph->p_filesz, 0, (ph->p_memsz - ph->p_filesz));
f010399b:	8b 43 10             	mov    0x10(%ebx),%eax
f010399e:	8b 53 14             	mov    0x14(%ebx),%edx
f01039a1:	29 c2                	sub    %eax,%edx
f01039a3:	89 54 24 08          	mov    %edx,0x8(%esp)
f01039a7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01039ae:	00 
f01039af:	03 43 08             	add    0x8(%ebx),%eax
f01039b2:	89 04 24             	mov    %eax,(%esp)
f01039b5:	e8 3d 26 00 00       	call   f0105ff7 <memset>
	e->env_tf.tf_eip = ELFHDR->e_entry;

	
	
	
	for (; ph < eph; ph++)
f01039ba:	83 c3 20             	add    $0x20,%ebx
f01039bd:	39 de                	cmp    %ebx,%esi
f01039bf:	77 8b                	ja     f010394c <env_create+0xb8>
	
	memset((void *) ph->p_va + ph->p_filesz, 0, (ph->p_memsz - ph->p_filesz));
	
}
	
   	region_alloc(e, (void *) USTACKTOP - PGSIZE, PGSIZE);
f01039c1:	b9 00 10 00 00       	mov    $0x1000,%ecx
f01039c6:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f01039cb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01039ce:	e8 44 fb ff ff       	call   f0103517 <region_alloc>

	lcr3(PADDR(kern_pgdir));
f01039d3:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01039d8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01039dd:	77 20                	ja     f01039ff <env_create+0x16b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01039df:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01039e3:	c7 44 24 08 68 6d 10 	movl   $0xf0106d68,0x8(%esp)
f01039ea:	f0 
f01039eb:	c7 44 24 04 b4 01 00 	movl   $0x1b4,0x4(%esp)
f01039f2:	00 
f01039f3:	c7 04 24 5f 7f 10 f0 	movl   $0xf0107f5f,(%esp)
f01039fa:	e8 41 c6 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01039ff:	05 00 00 00 10       	add    $0x10000000,%eax
f0103a04:	0f 22 d8             	mov    %eax,%cr3
		panic("env_alloc: %e", check);
		return;
	}
	
	load_icode(env, binary);
	env->env_type = type;
f0103a07:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103a0a:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103a0d:	89 50 50             	mov    %edx,0x50(%eax)
}
f0103a10:	83 c4 3c             	add    $0x3c,%esp
f0103a13:	5b                   	pop    %ebx
f0103a14:	5e                   	pop    %esi
f0103a15:	5f                   	pop    %edi
f0103a16:	5d                   	pop    %ebp
f0103a17:	c3                   	ret    

f0103a18 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0103a18:	55                   	push   %ebp
f0103a19:	89 e5                	mov    %esp,%ebp
f0103a1b:	57                   	push   %edi
f0103a1c:	56                   	push   %esi
f0103a1d:	53                   	push   %ebx
f0103a1e:	83 ec 2c             	sub    $0x2c,%esp
f0103a21:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0103a24:	e8 20 2c 00 00       	call   f0106649 <cpunum>
f0103a29:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a2c:	39 b8 28 20 23 f0    	cmp    %edi,-0xfdcdfd8(%eax)
f0103a32:	75 34                	jne    f0103a68 <env_free+0x50>
		lcr3(PADDR(kern_pgdir));
f0103a34:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103a39:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103a3e:	77 20                	ja     f0103a60 <env_free+0x48>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103a40:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103a44:	c7 44 24 08 68 6d 10 	movl   $0xf0106d68,0x8(%esp)
f0103a4b:	f0 
f0103a4c:	c7 44 24 04 e3 01 00 	movl   $0x1e3,0x4(%esp)
f0103a53:	00 
f0103a54:	c7 04 24 5f 7f 10 f0 	movl   $0xf0107f5f,(%esp)
f0103a5b:	e8 e0 c5 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103a60:	05 00 00 00 10       	add    $0x10000000,%eax
f0103a65:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103a68:	8b 5f 48             	mov    0x48(%edi),%ebx
f0103a6b:	e8 d9 2b 00 00       	call   f0106649 <cpunum>
f0103a70:	6b d0 74             	imul   $0x74,%eax,%edx
f0103a73:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a78:	83 ba 28 20 23 f0 00 	cmpl   $0x0,-0xfdcdfd8(%edx)
f0103a7f:	74 11                	je     f0103a92 <env_free+0x7a>
f0103a81:	e8 c3 2b 00 00       	call   f0106649 <cpunum>
f0103a86:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a89:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f0103a8f:	8b 40 48             	mov    0x48(%eax),%eax
f0103a92:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103a96:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a9a:	c7 04 24 c6 7f 10 f0 	movl   $0xf0107fc6,(%esp)
f0103aa1:	e8 83 04 00 00       	call   f0103f29 <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103aa6:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103aad:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103ab0:	89 c8                	mov    %ecx,%eax
f0103ab2:	c1 e0 02             	shl    $0x2,%eax
f0103ab5:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103ab8:	8b 47 78             	mov    0x78(%edi),%eax
f0103abb:	8b 34 88             	mov    (%eax,%ecx,4),%esi
f0103abe:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103ac4:	0f 84 b7 00 00 00    	je     f0103b81 <env_free+0x169>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103aca:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103ad0:	89 f0                	mov    %esi,%eax
f0103ad2:	c1 e8 0c             	shr    $0xc,%eax
f0103ad5:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103ad8:	3b 05 88 1e 23 f0    	cmp    0xf0231e88,%eax
f0103ade:	72 20                	jb     f0103b00 <env_free+0xe8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103ae0:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103ae4:	c7 44 24 08 44 6d 10 	movl   $0xf0106d44,0x8(%esp)
f0103aeb:	f0 
f0103aec:	c7 44 24 04 f2 01 00 	movl   $0x1f2,0x4(%esp)
f0103af3:	00 
f0103af4:	c7 04 24 5f 7f 10 f0 	movl   $0xf0107f5f,(%esp)
f0103afb:	e8 40 c5 ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103b00:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103b03:	c1 e0 16             	shl    $0x16,%eax
f0103b06:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103b09:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0103b0e:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0103b15:	01 
f0103b16:	74 17                	je     f0103b2f <env_free+0x117>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103b18:	89 d8                	mov    %ebx,%eax
f0103b1a:	c1 e0 0c             	shl    $0xc,%eax
f0103b1d:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103b20:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b24:	8b 47 78             	mov    0x78(%edi),%eax
f0103b27:	89 04 24             	mov    %eax,(%esp)
f0103b2a:	e8 1b d8 ff ff       	call   f010134a <page_remove>
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103b2f:	83 c3 01             	add    $0x1,%ebx
f0103b32:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103b38:	75 d4                	jne    f0103b0e <env_free+0xf6>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103b3a:	8b 47 78             	mov    0x78(%edi),%eax
f0103b3d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103b40:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103b47:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103b4a:	3b 05 88 1e 23 f0    	cmp    0xf0231e88,%eax
f0103b50:	72 1c                	jb     f0103b6e <env_free+0x156>
		panic("pa2page called with invalid pa");
f0103b52:	c7 44 24 08 f4 76 10 	movl   $0xf01076f4,0x8(%esp)
f0103b59:	f0 
f0103b5a:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
f0103b61:	00 
f0103b62:	c7 04 24 e0 72 10 f0 	movl   $0xf01072e0,(%esp)
f0103b69:	e8 d2 c4 ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f0103b6e:	a1 90 1e 23 f0       	mov    0xf0231e90,%eax
f0103b73:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103b76:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		page_decref(pa2page(pa));
f0103b79:	89 04 24             	mov    %eax,(%esp)
f0103b7c:	e8 89 d5 ff ff       	call   f010110a <page_decref>
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103b81:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0103b85:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f0103b8c:	0f 85 1b ff ff ff    	jne    f0103aad <env_free+0x95>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103b92:	8b 47 78             	mov    0x78(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103b95:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103b9a:	77 20                	ja     f0103bbc <env_free+0x1a4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103b9c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103ba0:	c7 44 24 08 68 6d 10 	movl   $0xf0106d68,0x8(%esp)
f0103ba7:	f0 
f0103ba8:	c7 44 24 04 00 02 00 	movl   $0x200,0x4(%esp)
f0103baf:	00 
f0103bb0:	c7 04 24 5f 7f 10 f0 	movl   $0xf0107f5f,(%esp)
f0103bb7:	e8 84 c4 ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f0103bbc:	c7 47 78 00 00 00 00 	movl   $0x0,0x78(%edi)
	return (physaddr_t)kva - KERNBASE;
f0103bc3:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103bc8:	c1 e8 0c             	shr    $0xc,%eax
f0103bcb:	3b 05 88 1e 23 f0    	cmp    0xf0231e88,%eax
f0103bd1:	72 1c                	jb     f0103bef <env_free+0x1d7>
		panic("pa2page called with invalid pa");
f0103bd3:	c7 44 24 08 f4 76 10 	movl   $0xf01076f4,0x8(%esp)
f0103bda:	f0 
f0103bdb:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
f0103be2:	00 
f0103be3:	c7 04 24 e0 72 10 f0 	movl   $0xf01072e0,(%esp)
f0103bea:	e8 51 c4 ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f0103bef:	8b 15 90 1e 23 f0    	mov    0xf0231e90,%edx
f0103bf5:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	page_decref(pa2page(pa));
f0103bf8:	89 04 24             	mov    %eax,(%esp)
f0103bfb:	e8 0a d5 ff ff       	call   f010110a <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103c00:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103c07:	a1 4c 12 23 f0       	mov    0xf023124c,%eax
f0103c0c:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0103c0f:	89 3d 4c 12 23 f0    	mov    %edi,0xf023124c
}
f0103c15:	83 c4 2c             	add    $0x2c,%esp
f0103c18:	5b                   	pop    %ebx
f0103c19:	5e                   	pop    %esi
f0103c1a:	5f                   	pop    %edi
f0103c1b:	5d                   	pop    %ebp
f0103c1c:	c3                   	ret    

f0103c1d <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f0103c1d:	55                   	push   %ebp
f0103c1e:	89 e5                	mov    %esp,%ebp
f0103c20:	53                   	push   %ebx
f0103c21:	83 ec 14             	sub    $0x14,%esp
f0103c24:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f0103c27:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f0103c2b:	75 19                	jne    f0103c46 <env_destroy+0x29>
f0103c2d:	e8 17 2a 00 00       	call   f0106649 <cpunum>
f0103c32:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c35:	39 98 28 20 23 f0    	cmp    %ebx,-0xfdcdfd8(%eax)
f0103c3b:	74 09                	je     f0103c46 <env_destroy+0x29>
	
		e->env_status = ENV_DYING;
f0103c3d:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f0103c44:	eb 2f                	jmp    f0103c75 <env_destroy+0x58>
	}

	env_free(e);
f0103c46:	89 1c 24             	mov    %ebx,(%esp)
f0103c49:	e8 ca fd ff ff       	call   f0103a18 <env_free>
	

	if (curenv == e) {
f0103c4e:	e8 f6 29 00 00       	call   f0106649 <cpunum>
f0103c53:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c56:	39 98 28 20 23 f0    	cmp    %ebx,-0xfdcdfd8(%eax)
f0103c5c:	75 17                	jne    f0103c75 <env_destroy+0x58>
	
		curenv = NULL;
f0103c5e:	e8 e6 29 00 00       	call   f0106649 <cpunum>
f0103c63:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c66:	c7 80 28 20 23 f0 00 	movl   $0x0,-0xfdcdfd8(%eax)
f0103c6d:	00 00 00 
		sched_yield();
f0103c70:	e8 61 12 00 00       	call   f0104ed6 <sched_yield>
	}
}
f0103c75:	83 c4 14             	add    $0x14,%esp
f0103c78:	5b                   	pop    %ebx
f0103c79:	5d                   	pop    %ebp
f0103c7a:	c3                   	ret    

f0103c7b <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103c7b:	55                   	push   %ebp
f0103c7c:	89 e5                	mov    %esp,%ebp
f0103c7e:	53                   	push   %ebx
f0103c7f:	83 ec 14             	sub    $0x14,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f0103c82:	e8 c2 29 00 00       	call   f0106649 <cpunum>
f0103c87:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c8a:	8b 98 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%ebx
f0103c90:	e8 b4 29 00 00       	call   f0106649 <cpunum>
f0103c95:	89 43 5c             	mov    %eax,0x5c(%ebx)
	
	//panic("pop_tf");
	asm volatile(
f0103c98:	8b 65 08             	mov    0x8(%ebp),%esp
f0103c9b:	61                   	popa   
f0103c9c:	07                   	pop    %es
f0103c9d:	1f                   	pop    %ds
f0103c9e:	83 c4 08             	add    $0x8,%esp
f0103ca1:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103ca2:	c7 44 24 08 dc 7f 10 	movl   $0xf0107fdc,0x8(%esp)
f0103ca9:	f0 
f0103caa:	c7 44 24 04 3b 02 00 	movl   $0x23b,0x4(%esp)
f0103cb1:	00 
f0103cb2:	c7 04 24 5f 7f 10 f0 	movl   $0xf0107f5f,(%esp)
f0103cb9:	e8 82 c3 ff ff       	call   f0100040 <_panic>

f0103cbe <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103cbe:	55                   	push   %ebp
f0103cbf:	89 e5                	mov    %esp,%ebp
f0103cc1:	53                   	push   %ebx
f0103cc2:	83 ec 14             	sub    $0x14,%esp
f0103cc5:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	// env_status : ENV_FREE, ENV_RUNNABLE, ENV_RUNNING, ENV_NOT_RUNNABLE

	if (curenv == NULL || curenv!= e) 
f0103cc8:	e8 7c 29 00 00       	call   f0106649 <cpunum>
f0103ccd:	6b c0 74             	imul   $0x74,%eax,%eax
f0103cd0:	83 b8 28 20 23 f0 00 	cmpl   $0x0,-0xfdcdfd8(%eax)
f0103cd7:	74 14                	je     f0103ced <env_run+0x2f>
f0103cd9:	e8 6b 29 00 00       	call   f0106649 <cpunum>
f0103cde:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ce1:	39 98 28 20 23 f0    	cmp    %ebx,-0xfdcdfd8(%eax)
f0103ce7:	0f 84 af 00 00 00    	je     f0103d9c <env_run+0xde>
	{
		if (curenv && curenv->env_status == ENV_RUNNING)
f0103ced:	e8 57 29 00 00       	call   f0106649 <cpunum>
f0103cf2:	6b c0 74             	imul   $0x74,%eax,%eax
f0103cf5:	83 b8 28 20 23 f0 00 	cmpl   $0x0,-0xfdcdfd8(%eax)
f0103cfc:	74 29                	je     f0103d27 <env_run+0x69>
f0103cfe:	e8 46 29 00 00       	call   f0106649 <cpunum>
f0103d03:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d06:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f0103d0c:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103d10:	75 15                	jne    f0103d27 <env_run+0x69>
			
			curenv->env_status = ENV_RUNNABLE;
f0103d12:	e8 32 29 00 00       	call   f0106649 <cpunum>
f0103d17:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d1a:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f0103d20:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
			curenv = e;
f0103d27:	e8 1d 29 00 00       	call   f0106649 <cpunum>
f0103d2c:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d2f:	89 98 28 20 23 f0    	mov    %ebx,-0xfdcdfd8(%eax)
	
		curenv->env_status = ENV_RUNNING;
f0103d35:	e8 0f 29 00 00       	call   f0106649 <cpunum>
f0103d3a:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d3d:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f0103d43:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
		curenv->env_runs++;
f0103d4a:	e8 fa 28 00 00       	call   f0106649 <cpunum>
f0103d4f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d52:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f0103d58:	83 40 58 01          	addl   $0x1,0x58(%eax)
		
		lcr3(PADDR(curenv->env_pgdir));
f0103d5c:	e8 e8 28 00 00       	call   f0106649 <cpunum>
f0103d61:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d64:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f0103d6a:	8b 40 78             	mov    0x78(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103d6d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103d72:	77 20                	ja     f0103d94 <env_run+0xd6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103d74:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103d78:	c7 44 24 08 68 6d 10 	movl   $0xf0106d68,0x8(%esp)
f0103d7f:	f0 
f0103d80:	c7 44 24 04 66 02 00 	movl   $0x266,0x4(%esp)
f0103d87:	00 
f0103d88:	c7 04 24 5f 7f 10 f0 	movl   $0xf0107f5f,(%esp)
f0103d8f:	e8 ac c2 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103d94:	05 00 00 00 10       	add    $0x10000000,%eax
f0103d99:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0103d9c:	c7 04 24 c0 13 12 f0 	movl   $0xf01213c0,(%esp)
f0103da3:	e8 cb 2b 00 00       	call   f0106973 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f0103da8:	f3 90                	pause  
	}

	
	unlock_kernel();
	
	env_pop_tf(&(curenv->env_tf));
f0103daa:	e8 9a 28 00 00       	call   f0106649 <cpunum>
f0103daf:	6b c0 74             	imul   $0x74,%eax,%eax
f0103db2:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f0103db8:	89 04 24             	mov    %eax,(%esp)
f0103dbb:	e8 bb fe ff ff       	call   f0103c7b <env_pop_tf>

f0103dc0 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103dc0:	55                   	push   %ebp
f0103dc1:	89 e5                	mov    %esp,%ebp
f0103dc3:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103dc7:	ba 70 00 00 00       	mov    $0x70,%edx
f0103dcc:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103dcd:	b2 71                	mov    $0x71,%dl
f0103dcf:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103dd0:	0f b6 c0             	movzbl %al,%eax
}
f0103dd3:	5d                   	pop    %ebp
f0103dd4:	c3                   	ret    

f0103dd5 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103dd5:	55                   	push   %ebp
f0103dd6:	89 e5                	mov    %esp,%ebp
f0103dd8:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103ddc:	ba 70 00 00 00       	mov    $0x70,%edx
f0103de1:	ee                   	out    %al,(%dx)
f0103de2:	b2 71                	mov    $0x71,%dl
f0103de4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103de7:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103de8:	5d                   	pop    %ebp
f0103de9:	c3                   	ret    

f0103dea <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f0103dea:	55                   	push   %ebp
f0103deb:	89 e5                	mov    %esp,%ebp
f0103ded:	56                   	push   %esi
f0103dee:	53                   	push   %ebx
f0103def:	83 ec 10             	sub    $0x10,%esp
f0103df2:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f0103df5:	66 a3 a8 13 12 f0    	mov    %ax,0xf01213a8
	if (!didinit)
f0103dfb:	80 3d 50 12 23 f0 00 	cmpb   $0x0,0xf0231250
f0103e02:	74 4e                	je     f0103e52 <irq_setmask_8259A+0x68>
f0103e04:	89 c6                	mov    %eax,%esi
f0103e06:	ba 21 00 00 00       	mov    $0x21,%edx
f0103e0b:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
f0103e0c:	66 c1 e8 08          	shr    $0x8,%ax
f0103e10:	b2 a1                	mov    $0xa1,%dl
f0103e12:	ee                   	out    %al,(%dx)
	cprintf("enabled interrupts:");
f0103e13:	c7 04 24 e8 7f 10 f0 	movl   $0xf0107fe8,(%esp)
f0103e1a:	e8 0a 01 00 00       	call   f0103f29 <cprintf>
	for (i = 0; i < 16; i++)
f0103e1f:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0103e24:	0f b7 f6             	movzwl %si,%esi
f0103e27:	f7 d6                	not    %esi
f0103e29:	0f a3 de             	bt     %ebx,%esi
f0103e2c:	73 10                	jae    f0103e3e <irq_setmask_8259A+0x54>
			cprintf(" %d", i);
f0103e2e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103e32:	c7 04 24 11 84 10 f0 	movl   $0xf0108411,(%esp)
f0103e39:	e8 eb 00 00 00       	call   f0103f29 <cprintf>
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f0103e3e:	83 c3 01             	add    $0x1,%ebx
f0103e41:	83 fb 10             	cmp    $0x10,%ebx
f0103e44:	75 e3                	jne    f0103e29 <irq_setmask_8259A+0x3f>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f0103e46:	c7 04 24 b0 7f 10 f0 	movl   $0xf0107fb0,(%esp)
f0103e4d:	e8 d7 00 00 00       	call   f0103f29 <cprintf>
}
f0103e52:	83 c4 10             	add    $0x10,%esp
f0103e55:	5b                   	pop    %ebx
f0103e56:	5e                   	pop    %esi
f0103e57:	5d                   	pop    %ebp
f0103e58:	c3                   	ret    

f0103e59 <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f0103e59:	c6 05 50 12 23 f0 01 	movb   $0x1,0xf0231250
f0103e60:	ba 21 00 00 00       	mov    $0x21,%edx
f0103e65:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103e6a:	ee                   	out    %al,(%dx)
f0103e6b:	b2 a1                	mov    $0xa1,%dl
f0103e6d:	ee                   	out    %al,(%dx)
f0103e6e:	b2 20                	mov    $0x20,%dl
f0103e70:	b8 11 00 00 00       	mov    $0x11,%eax
f0103e75:	ee                   	out    %al,(%dx)
f0103e76:	b2 21                	mov    $0x21,%dl
f0103e78:	b8 20 00 00 00       	mov    $0x20,%eax
f0103e7d:	ee                   	out    %al,(%dx)
f0103e7e:	b8 04 00 00 00       	mov    $0x4,%eax
f0103e83:	ee                   	out    %al,(%dx)
f0103e84:	b8 03 00 00 00       	mov    $0x3,%eax
f0103e89:	ee                   	out    %al,(%dx)
f0103e8a:	b2 a0                	mov    $0xa0,%dl
f0103e8c:	b8 11 00 00 00       	mov    $0x11,%eax
f0103e91:	ee                   	out    %al,(%dx)
f0103e92:	b2 a1                	mov    $0xa1,%dl
f0103e94:	b8 28 00 00 00       	mov    $0x28,%eax
f0103e99:	ee                   	out    %al,(%dx)
f0103e9a:	b8 02 00 00 00       	mov    $0x2,%eax
f0103e9f:	ee                   	out    %al,(%dx)
f0103ea0:	b8 01 00 00 00       	mov    $0x1,%eax
f0103ea5:	ee                   	out    %al,(%dx)
f0103ea6:	b2 20                	mov    $0x20,%dl
f0103ea8:	b8 68 00 00 00       	mov    $0x68,%eax
f0103ead:	ee                   	out    %al,(%dx)
f0103eae:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103eb3:	ee                   	out    %al,(%dx)
f0103eb4:	b2 a0                	mov    $0xa0,%dl
f0103eb6:	b8 68 00 00 00       	mov    $0x68,%eax
f0103ebb:	ee                   	out    %al,(%dx)
f0103ebc:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103ec1:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f0103ec2:	0f b7 05 a8 13 12 f0 	movzwl 0xf01213a8,%eax
f0103ec9:	66 83 f8 ff          	cmp    $0xffff,%ax
f0103ecd:	74 12                	je     f0103ee1 <pic_init+0x88>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f0103ecf:	55                   	push   %ebp
f0103ed0:	89 e5                	mov    %esp,%ebp
f0103ed2:	83 ec 18             	sub    $0x18,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f0103ed5:	0f b7 c0             	movzwl %ax,%eax
f0103ed8:	89 04 24             	mov    %eax,(%esp)
f0103edb:	e8 0a ff ff ff       	call   f0103dea <irq_setmask_8259A>
}
f0103ee0:	c9                   	leave  
f0103ee1:	f3 c3                	repz ret 

f0103ee3 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103ee3:	55                   	push   %ebp
f0103ee4:	89 e5                	mov    %esp,%ebp
f0103ee6:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0103ee9:	8b 45 08             	mov    0x8(%ebp),%eax
f0103eec:	89 04 24             	mov    %eax,(%esp)
f0103eef:	e8 96 c8 ff ff       	call   f010078a <cputchar>
	*cnt++;
}
f0103ef4:	c9                   	leave  
f0103ef5:	c3                   	ret    

f0103ef6 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103ef6:	55                   	push   %ebp
f0103ef7:	89 e5                	mov    %esp,%ebp
f0103ef9:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0103efc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103f03:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103f06:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103f0a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f0d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103f11:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103f14:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103f18:	c7 04 24 e3 3e 10 f0 	movl   $0xf0103ee3,(%esp)
f0103f1f:	e8 1a 1a 00 00       	call   f010593e <vprintfmt>
	return cnt;
}
f0103f24:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103f27:	c9                   	leave  
f0103f28:	c3                   	ret    

f0103f29 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103f29:	55                   	push   %ebp
f0103f2a:	89 e5                	mov    %esp,%ebp
f0103f2c:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103f2f:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103f32:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103f36:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f39:	89 04 24             	mov    %eax,(%esp)
f0103f3c:	e8 b5 ff ff ff       	call   f0103ef6 <vcprintf>
	va_end(ap);

	return cnt;
}
f0103f41:	c9                   	leave  
f0103f42:	c3                   	ret    
f0103f43:	66 90                	xchg   %ax,%ax
f0103f45:	66 90                	xchg   %ax,%ax
f0103f47:	66 90                	xchg   %ax,%ax
f0103f49:	66 90                	xchg   %ax,%ax
f0103f4b:	66 90                	xchg   %ax,%ax
f0103f4d:	66 90                	xchg   %ax,%ax
f0103f4f:	90                   	nop

f0103f50 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103f50:	55                   	push   %ebp
f0103f51:	89 e5                	mov    %esp,%ebp
f0103f53:	57                   	push   %edi
f0103f54:	56                   	push   %esi
f0103f55:	53                   	push   %ebx
f0103f56:	83 ec 1c             	sub    $0x1c,%esp
	// wrong, you may not get a fault until you try to return from
	// user space on that CPU.
	//
	// LAB 4: Your code here:

	uint32_t i = thiscpu->cpu_id;
f0103f59:	e8 eb 26 00 00       	call   f0106649 <cpunum>
f0103f5e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f61:	0f b6 80 20 20 23 f0 	movzbl -0xfdcdfe0(%eax),%eax
f0103f68:	88 45 e7             	mov    %al,-0x19(%ebp)
f0103f6b:	0f b6 d8             	movzbl %al,%ebx
	thiscpu->cpu_ts.ts_esp0 = KSTACKTOP - i * (KSTKSIZE + KSTKGAP);
f0103f6e:	e8 d6 26 00 00       	call   f0106649 <cpunum>
f0103f73:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f76:	89 da                	mov    %ebx,%edx
f0103f78:	f7 da                	neg    %edx
f0103f7a:	c1 e2 10             	shl    $0x10,%edx
f0103f7d:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0103f83:	89 90 30 20 23 f0    	mov    %edx,-0xfdcdfd0(%eax)
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f0103f89:	e8 bb 26 00 00       	call   f0106649 <cpunum>
f0103f8e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f91:	66 c7 80 34 20 23 f0 	movw   $0x10,-0xfdcdfcc(%eax)
f0103f98:	10 00 

	// Initialize the TSS slot of the gdt.

	gdt[(GD_TSS0 >> 3) + i] = SEG16(STS_T32A, (uint32_t)&thiscpu->cpu_ts,
f0103f9a:	83 c3 05             	add    $0x5,%ebx
f0103f9d:	e8 a7 26 00 00       	call   f0106649 <cpunum>
f0103fa2:	89 c7                	mov    %eax,%edi
f0103fa4:	e8 a0 26 00 00       	call   f0106649 <cpunum>
f0103fa9:	89 c6                	mov    %eax,%esi
f0103fab:	e8 99 26 00 00       	call   f0106649 <cpunum>
f0103fb0:	66 c7 04 dd 40 13 12 	movw   $0x68,-0xfedecc0(,%ebx,8)
f0103fb7:	f0 68 00 
f0103fba:	6b ff 74             	imul   $0x74,%edi,%edi
f0103fbd:	81 c7 2c 20 23 f0    	add    $0xf023202c,%edi
f0103fc3:	66 89 3c dd 42 13 12 	mov    %di,-0xfedecbe(,%ebx,8)
f0103fca:	f0 
f0103fcb:	6b d6 74             	imul   $0x74,%esi,%edx
f0103fce:	81 c2 2c 20 23 f0    	add    $0xf023202c,%edx
f0103fd4:	c1 ea 10             	shr    $0x10,%edx
f0103fd7:	88 14 dd 44 13 12 f0 	mov    %dl,-0xfedecbc(,%ebx,8)
f0103fde:	c6 04 dd 46 13 12 f0 	movb   $0x40,-0xfedecba(,%ebx,8)
f0103fe5:	40 
f0103fe6:	6b c0 74             	imul   $0x74,%eax,%eax
f0103fe9:	05 2c 20 23 f0       	add    $0xf023202c,%eax
f0103fee:	c1 e8 18             	shr    $0x18,%eax
f0103ff1:	88 04 dd 47 13 12 f0 	mov    %al,-0xfedecb9(,%ebx,8)
						sizeof(struct Taskstate), 0);
	gdt[(GD_TSS0 >> 3) + i].sd_s = 0;
f0103ff8:	c6 04 dd 45 13 12 f0 	movb   $0x89,-0xfedecbb(,%ebx,8)
f0103fff:	89 

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0 + (i << 3) );
f0104000:	0f b6 75 e7          	movzbl -0x19(%ebp),%esi
f0104004:	8d 34 f5 28 00 00 00 	lea    0x28(,%esi,8),%esi
}

static inline void
ltr(uint16_t sel)
{
	asm volatile("ltr %0" : : "r" (sel));
f010400b:	0f 00 de             	ltr    %si
}

static inline void
lidt(void *p)
{
	asm volatile("lidt (%0)" : : "r" (p));
f010400e:	b8 aa 13 12 f0       	mov    $0xf01213aa,%eax
f0104013:	0f 01 18             	lidtl  (%eax)
f0104016:	0f 01 18             	lidtl  (%eax)
	lidt(&idt_pd);

	// Load the IDT
	lidt(&idt_pd);
}
f0104019:	83 c4 1c             	add    $0x1c,%esp
f010401c:	5b                   	pop    %ebx
f010401d:	5e                   	pop    %esi
f010401e:	5f                   	pop    %edi
f010401f:	5d                   	pop    %ebp
f0104020:	c3                   	ret    

f0104021 <trap_init>:
}


void
trap_init(void)
{
f0104021:	55                   	push   %ebp
f0104022:	89 e5                	mov    %esp,%ebp
f0104024:	83 ec 08             	sub    $0x8,%esp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.
	SETGATE(idt[T_DIVIDE],0,GD_KT,divide_zero,DPLKERN);    //CSS=kernel text
f0104027:	b8 a0 4c 10 f0       	mov    $0xf0104ca0,%eax
f010402c:	66 a3 60 12 23 f0    	mov    %ax,0xf0231260
f0104032:	66 c7 05 62 12 23 f0 	movw   $0x8,0xf0231262
f0104039:	08 00 
f010403b:	c6 05 64 12 23 f0 00 	movb   $0x0,0xf0231264
f0104042:	c6 05 65 12 23 f0 8e 	movb   $0x8e,0xf0231265
f0104049:	c1 e8 10             	shr    $0x10,%eax
f010404c:	66 a3 66 12 23 f0    	mov    %ax,0xf0231266
    SETGATE(idt[T_BRKPT],0,GD_KT,brkpoint,DPLUSR);
f0104052:	b8 aa 4c 10 f0       	mov    $0xf0104caa,%eax
f0104057:	66 a3 78 12 23 f0    	mov    %ax,0xf0231278
f010405d:	66 c7 05 7a 12 23 f0 	movw   $0x8,0xf023127a
f0104064:	08 00 
f0104066:	c6 05 7c 12 23 f0 00 	movb   $0x0,0xf023127c
f010406d:	c6 05 7d 12 23 f0 ee 	movb   $0xee,0xf023127d
f0104074:	c1 e8 10             	shr    $0x10,%eax
f0104077:	66 a3 7e 12 23 f0    	mov    %ax,0xf023127e
    SETGATE(idt[T_SEGNP],0,GD_KT,no_seg,DPLKERN);
f010407d:	b8 b4 4c 10 f0       	mov    $0xf0104cb4,%eax
f0104082:	66 a3 b8 12 23 f0    	mov    %ax,0xf02312b8
f0104088:	66 c7 05 ba 12 23 f0 	movw   $0x8,0xf02312ba
f010408f:	08 00 
f0104091:	c6 05 bc 12 23 f0 00 	movb   $0x0,0xf02312bc
f0104098:	c6 05 bd 12 23 f0 8e 	movb   $0x8e,0xf02312bd
f010409f:	c1 e8 10             	shr    $0x10,%eax
f01040a2:	66 a3 be 12 23 f0    	mov    %ax,0xf02312be
    SETGATE(idt[T_DEBUG],0,GD_KT,debug,DPLKERN);
f01040a8:	b8 bc 4c 10 f0       	mov    $0xf0104cbc,%eax
f01040ad:	66 a3 68 12 23 f0    	mov    %ax,0xf0231268
f01040b3:	66 c7 05 6a 12 23 f0 	movw   $0x8,0xf023126a
f01040ba:	08 00 
f01040bc:	c6 05 6c 12 23 f0 00 	movb   $0x0,0xf023126c
f01040c3:	c6 05 6d 12 23 f0 8e 	movb   $0x8e,0xf023126d
f01040ca:	c1 e8 10             	shr    $0x10,%eax
f01040cd:	66 a3 6e 12 23 f0    	mov    %ax,0xf023126e
    SETGATE(idt[T_NMI],0,GD_KT,nmi,DPLKERN);
f01040d3:	b8 c6 4c 10 f0       	mov    $0xf0104cc6,%eax
f01040d8:	66 a3 70 12 23 f0    	mov    %ax,0xf0231270
f01040de:	66 c7 05 72 12 23 f0 	movw   $0x8,0xf0231272
f01040e5:	08 00 
f01040e7:	c6 05 74 12 23 f0 00 	movb   $0x0,0xf0231274
f01040ee:	c6 05 75 12 23 f0 8e 	movb   $0x8e,0xf0231275
f01040f5:	c1 e8 10             	shr    $0x10,%eax
f01040f8:	66 a3 76 12 23 f0    	mov    %ax,0xf0231276
    SETGATE(idt[T_OFLOW],0,GD_KT,oflow,DPLKERN);
f01040fe:	b8 d0 4c 10 f0       	mov    $0xf0104cd0,%eax
f0104103:	66 a3 80 12 23 f0    	mov    %ax,0xf0231280
f0104109:	66 c7 05 82 12 23 f0 	movw   $0x8,0xf0231282
f0104110:	08 00 
f0104112:	c6 05 84 12 23 f0 00 	movb   $0x0,0xf0231284
f0104119:	c6 05 85 12 23 f0 8e 	movb   $0x8e,0xf0231285
f0104120:	c1 e8 10             	shr    $0x10,%eax
f0104123:	66 a3 86 12 23 f0    	mov    %ax,0xf0231286
    SETGATE(idt[T_BOUND],0,GD_KT,bound,DPLKERN);
f0104129:	b8 da 4c 10 f0       	mov    $0xf0104cda,%eax
f010412e:	66 a3 88 12 23 f0    	mov    %ax,0xf0231288
f0104134:	66 c7 05 8a 12 23 f0 	movw   $0x8,0xf023128a
f010413b:	08 00 
f010413d:	c6 05 8c 12 23 f0 00 	movb   $0x0,0xf023128c
f0104144:	c6 05 8d 12 23 f0 8e 	movb   $0x8e,0xf023128d
f010414b:	c1 e8 10             	shr    $0x10,%eax
f010414e:	66 a3 8e 12 23 f0    	mov    %ax,0xf023128e
    SETGATE(idt[T_ILLOP],0,GD_KT,illop,DPLKERN);
f0104154:	b8 e4 4c 10 f0       	mov    $0xf0104ce4,%eax
f0104159:	66 a3 90 12 23 f0    	mov    %ax,0xf0231290
f010415f:	66 c7 05 92 12 23 f0 	movw   $0x8,0xf0231292
f0104166:	08 00 
f0104168:	c6 05 94 12 23 f0 00 	movb   $0x0,0xf0231294
f010416f:	c6 05 95 12 23 f0 8e 	movb   $0x8e,0xf0231295
f0104176:	c1 e8 10             	shr    $0x10,%eax
f0104179:	66 a3 96 12 23 f0    	mov    %ax,0xf0231296
    SETGATE(idt[T_DEVICE],0,GD_KT,device,DPLKERN);
f010417f:	b8 ee 4c 10 f0       	mov    $0xf0104cee,%eax
f0104184:	66 a3 98 12 23 f0    	mov    %ax,0xf0231298
f010418a:	66 c7 05 9a 12 23 f0 	movw   $0x8,0xf023129a
f0104191:	08 00 
f0104193:	c6 05 9c 12 23 f0 00 	movb   $0x0,0xf023129c
f010419a:	c6 05 9d 12 23 f0 8e 	movb   $0x8e,0xf023129d
f01041a1:	c1 e8 10             	shr    $0x10,%eax
f01041a4:	66 a3 9e 12 23 f0    	mov    %ax,0xf023129e
    SETGATE(idt[T_DBLFLT],0,GD_KT,dblflt,DPLKERN);
f01041aa:	b8 f8 4c 10 f0       	mov    $0xf0104cf8,%eax
f01041af:	66 a3 a0 12 23 f0    	mov    %ax,0xf02312a0
f01041b5:	66 c7 05 a2 12 23 f0 	movw   $0x8,0xf02312a2
f01041bc:	08 00 
f01041be:	c6 05 a4 12 23 f0 00 	movb   $0x0,0xf02312a4
f01041c5:	c6 05 a5 12 23 f0 8e 	movb   $0x8e,0xf02312a5
f01041cc:	c1 e8 10             	shr    $0x10,%eax
f01041cf:	66 a3 a6 12 23 f0    	mov    %ax,0xf02312a6
    SETGATE(idt[T_TSS], 0, GD_KT, tss, DPLKERN);
f01041d5:	b8 00 4d 10 f0       	mov    $0xf0104d00,%eax
f01041da:	66 a3 b0 12 23 f0    	mov    %ax,0xf02312b0
f01041e0:	66 c7 05 b2 12 23 f0 	movw   $0x8,0xf02312b2
f01041e7:	08 00 
f01041e9:	c6 05 b4 12 23 f0 00 	movb   $0x0,0xf02312b4
f01041f0:	c6 05 b5 12 23 f0 8e 	movb   $0x8e,0xf02312b5
f01041f7:	c1 e8 10             	shr    $0x10,%eax
f01041fa:	66 a3 b6 12 23 f0    	mov    %ax,0xf02312b6
    SETGATE(idt[T_STACK], 0, GD_KT, stack, DPLKERN);
f0104200:	b8 08 4d 10 f0       	mov    $0xf0104d08,%eax
f0104205:	66 a3 c0 12 23 f0    	mov    %ax,0xf02312c0
f010420b:	66 c7 05 c2 12 23 f0 	movw   $0x8,0xf02312c2
f0104212:	08 00 
f0104214:	c6 05 c4 12 23 f0 00 	movb   $0x0,0xf02312c4
f010421b:	c6 05 c5 12 23 f0 8e 	movb   $0x8e,0xf02312c5
f0104222:	c1 e8 10             	shr    $0x10,%eax
f0104225:	66 a3 c6 12 23 f0    	mov    %ax,0xf02312c6
    SETGATE(idt[T_GPFLT], 0, GD_KT, gpflt, DPLKERN);
f010422b:	b8 10 4d 10 f0       	mov    $0xf0104d10,%eax
f0104230:	66 a3 c8 12 23 f0    	mov    %ax,0xf02312c8
f0104236:	66 c7 05 ca 12 23 f0 	movw   $0x8,0xf02312ca
f010423d:	08 00 
f010423f:	c6 05 cc 12 23 f0 00 	movb   $0x0,0xf02312cc
f0104246:	c6 05 cd 12 23 f0 8e 	movb   $0x8e,0xf02312cd
f010424d:	c1 e8 10             	shr    $0x10,%eax
f0104250:	66 a3 ce 12 23 f0    	mov    %ax,0xf02312ce
    SETGATE(idt[T_PGFLT], 0, GD_KT, pgflt, DPLKERN);
f0104256:	b8 18 4d 10 f0       	mov    $0xf0104d18,%eax
f010425b:	66 a3 d0 12 23 f0    	mov    %ax,0xf02312d0
f0104261:	66 c7 05 d2 12 23 f0 	movw   $0x8,0xf02312d2
f0104268:	08 00 
f010426a:	c6 05 d4 12 23 f0 00 	movb   $0x0,0xf02312d4
f0104271:	c6 05 d5 12 23 f0 8e 	movb   $0x8e,0xf02312d5
f0104278:	c1 e8 10             	shr    $0x10,%eax
f010427b:	66 a3 d6 12 23 f0    	mov    %ax,0xf02312d6
    SETGATE(idt[T_FPERR], 0, GD_KT, fperr, DPLKERN);
f0104281:	b8 20 4d 10 f0       	mov    $0xf0104d20,%eax
f0104286:	66 a3 e0 12 23 f0    	mov    %ax,0xf02312e0
f010428c:	66 c7 05 e2 12 23 f0 	movw   $0x8,0xf02312e2
f0104293:	08 00 
f0104295:	c6 05 e4 12 23 f0 00 	movb   $0x0,0xf02312e4
f010429c:	c6 05 e5 12 23 f0 8e 	movb   $0x8e,0xf02312e5
f01042a3:	c1 e8 10             	shr    $0x10,%eax
f01042a6:	66 a3 e6 12 23 f0    	mov    %ax,0xf02312e6
    SETGATE(idt[T_ALIGN], 0, GD_KT, align, DPLKERN);
f01042ac:	b8 2a 4d 10 f0       	mov    $0xf0104d2a,%eax
f01042b1:	66 a3 e8 12 23 f0    	mov    %ax,0xf02312e8
f01042b7:	66 c7 05 ea 12 23 f0 	movw   $0x8,0xf02312ea
f01042be:	08 00 
f01042c0:	c6 05 ec 12 23 f0 00 	movb   $0x0,0xf02312ec
f01042c7:	c6 05 ed 12 23 f0 8e 	movb   $0x8e,0xf02312ed
f01042ce:	c1 e8 10             	shr    $0x10,%eax
f01042d1:	66 a3 ee 12 23 f0    	mov    %ax,0xf02312ee
    SETGATE(idt[T_MCHK], 0, GD_KT, mchk, DPLKERN);
f01042d7:	b8 32 4d 10 f0       	mov    $0xf0104d32,%eax
f01042dc:	66 a3 f0 12 23 f0    	mov    %ax,0xf02312f0
f01042e2:	66 c7 05 f2 12 23 f0 	movw   $0x8,0xf02312f2
f01042e9:	08 00 
f01042eb:	c6 05 f4 12 23 f0 00 	movb   $0x0,0xf02312f4
f01042f2:	c6 05 f5 12 23 f0 8e 	movb   $0x8e,0xf02312f5
f01042f9:	c1 e8 10             	shr    $0x10,%eax
f01042fc:	66 a3 f6 12 23 f0    	mov    %ax,0xf02312f6
    SETGATE(idt[T_SIMDERR], 0, GD_KT, simderr, DPLKERN);
f0104302:	b8 3c 4d 10 f0       	mov    $0xf0104d3c,%eax
f0104307:	66 a3 f8 12 23 f0    	mov    %ax,0xf02312f8
f010430d:	66 c7 05 fa 12 23 f0 	movw   $0x8,0xf02312fa
f0104314:	08 00 
f0104316:	c6 05 fc 12 23 f0 00 	movb   $0x0,0xf02312fc
f010431d:	c6 05 fd 12 23 f0 8e 	movb   $0x8e,0xf02312fd
f0104324:	c1 e8 10             	shr    $0x10,%eax
f0104327:	66 a3 fe 12 23 f0    	mov    %ax,0xf02312fe

    SETGATE(idt[T_SYSCALL], 0, GD_KT, syscalls, DPLUSR);
f010432d:	b8 46 4d 10 f0       	mov    $0xf0104d46,%eax
f0104332:	66 a3 e0 13 23 f0    	mov    %ax,0xf02313e0
f0104338:	66 c7 05 e2 13 23 f0 	movw   $0x8,0xf02313e2
f010433f:	08 00 
f0104341:	c6 05 e4 13 23 f0 00 	movb   $0x0,0xf02313e4
f0104348:	c6 05 e5 13 23 f0 ee 	movb   $0xee,0xf02313e5
f010434f:	c1 e8 10             	shr    $0x10,%eax
f0104352:	66 a3 e6 13 23 f0    	mov    %ax,0xf02313e6


    SETGATE(idt[32], 0, GD_KT, irq , DPLUSR);
f0104358:	b8 50 4d 10 f0       	mov    $0xf0104d50,%eax
f010435d:	66 a3 60 13 23 f0    	mov    %ax,0xf0231360
f0104363:	66 c7 05 62 13 23 f0 	movw   $0x8,0xf0231362
f010436a:	08 00 
f010436c:	c6 05 64 13 23 f0 00 	movb   $0x0,0xf0231364
f0104373:	c6 05 65 13 23 f0 ee 	movb   $0xee,0xf0231365
f010437a:	c1 e8 10             	shr    $0x10,%eax
f010437d:	66 a3 66 13 23 f0    	mov    %ax,0xf0231366
    SETGATE(idt[33], 0, GD_KT, irq1, DPLUSR);
f0104383:	b8 5a 4d 10 f0       	mov    $0xf0104d5a,%eax
f0104388:	66 a3 68 13 23 f0    	mov    %ax,0xf0231368
f010438e:	66 c7 05 6a 13 23 f0 	movw   $0x8,0xf023136a
f0104395:	08 00 
f0104397:	c6 05 6c 13 23 f0 00 	movb   $0x0,0xf023136c
f010439e:	c6 05 6d 13 23 f0 ee 	movb   $0xee,0xf023136d
f01043a5:	c1 e8 10             	shr    $0x10,%eax
f01043a8:	66 a3 6e 13 23 f0    	mov    %ax,0xf023136e
    SETGATE(idt[34], 0, GD_KT, irq2, DPLUSR);
f01043ae:	b8 64 4d 10 f0       	mov    $0xf0104d64,%eax
f01043b3:	66 a3 70 13 23 f0    	mov    %ax,0xf0231370
f01043b9:	66 c7 05 72 13 23 f0 	movw   $0x8,0xf0231372
f01043c0:	08 00 
f01043c2:	c6 05 74 13 23 f0 00 	movb   $0x0,0xf0231374
f01043c9:	c6 05 75 13 23 f0 ee 	movb   $0xee,0xf0231375
f01043d0:	c1 e8 10             	shr    $0x10,%eax
f01043d3:	66 a3 76 13 23 f0    	mov    %ax,0xf0231376
    SETGATE(idt[35], 0, GD_KT, irq3, DPLUSR);
f01043d9:	b8 6e 4d 10 f0       	mov    $0xf0104d6e,%eax
f01043de:	66 a3 78 13 23 f0    	mov    %ax,0xf0231378
f01043e4:	66 c7 05 7a 13 23 f0 	movw   $0x8,0xf023137a
f01043eb:	08 00 
f01043ed:	c6 05 7c 13 23 f0 00 	movb   $0x0,0xf023137c
f01043f4:	c6 05 7d 13 23 f0 ee 	movb   $0xee,0xf023137d
f01043fb:	c1 e8 10             	shr    $0x10,%eax
f01043fe:	66 a3 7e 13 23 f0    	mov    %ax,0xf023137e
    SETGATE(idt[36], 0, GD_KT, irq4, DPLUSR);
f0104404:	b8 78 4d 10 f0       	mov    $0xf0104d78,%eax
f0104409:	66 a3 80 13 23 f0    	mov    %ax,0xf0231380
f010440f:	66 c7 05 82 13 23 f0 	movw   $0x8,0xf0231382
f0104416:	08 00 
f0104418:	c6 05 84 13 23 f0 00 	movb   $0x0,0xf0231384
f010441f:	c6 05 85 13 23 f0 ee 	movb   $0xee,0xf0231385
f0104426:	c1 e8 10             	shr    $0x10,%eax
f0104429:	66 a3 86 13 23 f0    	mov    %ax,0xf0231386
    SETGATE(idt[37], 0, GD_KT, irq5, DPLUSR);
f010442f:	b8 82 4d 10 f0       	mov    $0xf0104d82,%eax
f0104434:	66 a3 88 13 23 f0    	mov    %ax,0xf0231388
f010443a:	66 c7 05 8a 13 23 f0 	movw   $0x8,0xf023138a
f0104441:	08 00 
f0104443:	c6 05 8c 13 23 f0 00 	movb   $0x0,0xf023138c
f010444a:	c6 05 8d 13 23 f0 ee 	movb   $0xee,0xf023138d
f0104451:	c1 e8 10             	shr    $0x10,%eax
f0104454:	66 a3 8e 13 23 f0    	mov    %ax,0xf023138e
    SETGATE(idt[38], 0, GD_KT, irq6, DPLUSR);
f010445a:	b8 8c 4d 10 f0       	mov    $0xf0104d8c,%eax
f010445f:	66 a3 90 13 23 f0    	mov    %ax,0xf0231390
f0104465:	66 c7 05 92 13 23 f0 	movw   $0x8,0xf0231392
f010446c:	08 00 
f010446e:	c6 05 94 13 23 f0 00 	movb   $0x0,0xf0231394
f0104475:	c6 05 95 13 23 f0 ee 	movb   $0xee,0xf0231395
f010447c:	c1 e8 10             	shr    $0x10,%eax
f010447f:	66 a3 96 13 23 f0    	mov    %ax,0xf0231396
    SETGATE(idt[39], 0, GD_KT, irq7, DPLUSR);
f0104485:	b8 96 4d 10 f0       	mov    $0xf0104d96,%eax
f010448a:	66 a3 98 13 23 f0    	mov    %ax,0xf0231398
f0104490:	66 c7 05 9a 13 23 f0 	movw   $0x8,0xf023139a
f0104497:	08 00 
f0104499:	c6 05 9c 13 23 f0 00 	movb   $0x0,0xf023139c
f01044a0:	c6 05 9d 13 23 f0 ee 	movb   $0xee,0xf023139d
f01044a7:	c1 e8 10             	shr    $0x10,%eax
f01044aa:	66 a3 9e 13 23 f0    	mov    %ax,0xf023139e
    SETGATE(idt[40], 0, GD_KT, irq8, DPLUSR);
f01044b0:	b8 a0 4d 10 f0       	mov    $0xf0104da0,%eax
f01044b5:	66 a3 a0 13 23 f0    	mov    %ax,0xf02313a0
f01044bb:	66 c7 05 a2 13 23 f0 	movw   $0x8,0xf02313a2
f01044c2:	08 00 
f01044c4:	c6 05 a4 13 23 f0 00 	movb   $0x0,0xf02313a4
f01044cb:	c6 05 a5 13 23 f0 ee 	movb   $0xee,0xf02313a5
f01044d2:	c1 e8 10             	shr    $0x10,%eax
f01044d5:	66 a3 a6 13 23 f0    	mov    %ax,0xf02313a6
    SETGATE(idt[41], 0, GD_KT, irq9, DPLUSR);
f01044db:	b8 aa 4d 10 f0       	mov    $0xf0104daa,%eax
f01044e0:	66 a3 a8 13 23 f0    	mov    %ax,0xf02313a8
f01044e6:	66 c7 05 aa 13 23 f0 	movw   $0x8,0xf02313aa
f01044ed:	08 00 
f01044ef:	c6 05 ac 13 23 f0 00 	movb   $0x0,0xf02313ac
f01044f6:	c6 05 ad 13 23 f0 ee 	movb   $0xee,0xf02313ad
f01044fd:	c1 e8 10             	shr    $0x10,%eax
f0104500:	66 a3 ae 13 23 f0    	mov    %ax,0xf02313ae
    SETGATE(idt[42], 0, GD_KT, irq10, DPLUSR);
f0104506:	b8 b4 4d 10 f0       	mov    $0xf0104db4,%eax
f010450b:	66 a3 b0 13 23 f0    	mov    %ax,0xf02313b0
f0104511:	66 c7 05 b2 13 23 f0 	movw   $0x8,0xf02313b2
f0104518:	08 00 
f010451a:	c6 05 b4 13 23 f0 00 	movb   $0x0,0xf02313b4
f0104521:	c6 05 b5 13 23 f0 ee 	movb   $0xee,0xf02313b5
f0104528:	c1 e8 10             	shr    $0x10,%eax
f010452b:	66 a3 b6 13 23 f0    	mov    %ax,0xf02313b6
    SETGATE(idt[43], 0, GD_KT, irq11, DPLUSR);
f0104531:	b8 be 4d 10 f0       	mov    $0xf0104dbe,%eax
f0104536:	66 a3 b8 13 23 f0    	mov    %ax,0xf02313b8
f010453c:	66 c7 05 ba 13 23 f0 	movw   $0x8,0xf02313ba
f0104543:	08 00 
f0104545:	c6 05 bc 13 23 f0 00 	movb   $0x0,0xf02313bc
f010454c:	c6 05 bd 13 23 f0 ee 	movb   $0xee,0xf02313bd
f0104553:	c1 e8 10             	shr    $0x10,%eax
f0104556:	66 a3 be 13 23 f0    	mov    %ax,0xf02313be
    SETGATE(idt[44], 0, GD_KT, irq12, DPLUSR);
f010455c:	b8 c8 4d 10 f0       	mov    $0xf0104dc8,%eax
f0104561:	66 a3 c0 13 23 f0    	mov    %ax,0xf02313c0
f0104567:	66 c7 05 c2 13 23 f0 	movw   $0x8,0xf02313c2
f010456e:	08 00 
f0104570:	c6 05 c4 13 23 f0 00 	movb   $0x0,0xf02313c4
f0104577:	c6 05 c5 13 23 f0 ee 	movb   $0xee,0xf02313c5
f010457e:	c1 e8 10             	shr    $0x10,%eax
f0104581:	66 a3 c6 13 23 f0    	mov    %ax,0xf02313c6
    SETGATE(idt[45], 0, GD_KT, irq13, DPLUSR);
f0104587:	b8 d2 4d 10 f0       	mov    $0xf0104dd2,%eax
f010458c:	66 a3 c8 13 23 f0    	mov    %ax,0xf02313c8
f0104592:	66 c7 05 ca 13 23 f0 	movw   $0x8,0xf02313ca
f0104599:	08 00 
f010459b:	c6 05 cc 13 23 f0 00 	movb   $0x0,0xf02313cc
f01045a2:	c6 05 cd 13 23 f0 ee 	movb   $0xee,0xf02313cd
f01045a9:	c1 e8 10             	shr    $0x10,%eax
f01045ac:	66 a3 ce 13 23 f0    	mov    %ax,0xf02313ce
    SETGATE(idt[46], 0, GD_KT, irq14, DPLUSR);	
f01045b2:	b8 dc 4d 10 f0       	mov    $0xf0104ddc,%eax
f01045b7:	66 a3 d0 13 23 f0    	mov    %ax,0xf02313d0
f01045bd:	66 c7 05 d2 13 23 f0 	movw   $0x8,0xf02313d2
f01045c4:	08 00 
f01045c6:	c6 05 d4 13 23 f0 00 	movb   $0x0,0xf02313d4
f01045cd:	c6 05 d5 13 23 f0 ee 	movb   $0xee,0xf02313d5
f01045d4:	c1 e8 10             	shr    $0x10,%eax
f01045d7:	66 a3 d6 13 23 f0    	mov    %ax,0xf02313d6




// Per-CPU setup 
	trap_init_percpu();
f01045dd:	e8 6e f9 ff ff       	call   f0103f50 <trap_init_percpu>
}
f01045e2:	c9                   	leave  
f01045e3:	c3                   	ret    

f01045e4 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f01045e4:	55                   	push   %ebp
f01045e5:	89 e5                	mov    %esp,%ebp
f01045e7:	53                   	push   %ebx
f01045e8:	83 ec 14             	sub    $0x14,%esp
f01045eb:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01045ee:	8b 03                	mov    (%ebx),%eax
f01045f0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01045f4:	c7 04 24 fc 7f 10 f0 	movl   $0xf0107ffc,(%esp)
f01045fb:	e8 29 f9 ff ff       	call   f0103f29 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0104600:	8b 43 04             	mov    0x4(%ebx),%eax
f0104603:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104607:	c7 04 24 0b 80 10 f0 	movl   $0xf010800b,(%esp)
f010460e:	e8 16 f9 ff ff       	call   f0103f29 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0104613:	8b 43 08             	mov    0x8(%ebx),%eax
f0104616:	89 44 24 04          	mov    %eax,0x4(%esp)
f010461a:	c7 04 24 1a 80 10 f0 	movl   $0xf010801a,(%esp)
f0104621:	e8 03 f9 ff ff       	call   f0103f29 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0104626:	8b 43 0c             	mov    0xc(%ebx),%eax
f0104629:	89 44 24 04          	mov    %eax,0x4(%esp)
f010462d:	c7 04 24 29 80 10 f0 	movl   $0xf0108029,(%esp)
f0104634:	e8 f0 f8 ff ff       	call   f0103f29 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0104639:	8b 43 10             	mov    0x10(%ebx),%eax
f010463c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104640:	c7 04 24 38 80 10 f0 	movl   $0xf0108038,(%esp)
f0104647:	e8 dd f8 ff ff       	call   f0103f29 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f010464c:	8b 43 14             	mov    0x14(%ebx),%eax
f010464f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104653:	c7 04 24 47 80 10 f0 	movl   $0xf0108047,(%esp)
f010465a:	e8 ca f8 ff ff       	call   f0103f29 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f010465f:	8b 43 18             	mov    0x18(%ebx),%eax
f0104662:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104666:	c7 04 24 56 80 10 f0 	movl   $0xf0108056,(%esp)
f010466d:	e8 b7 f8 ff ff       	call   f0103f29 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0104672:	8b 43 1c             	mov    0x1c(%ebx),%eax
f0104675:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104679:	c7 04 24 65 80 10 f0 	movl   $0xf0108065,(%esp)
f0104680:	e8 a4 f8 ff ff       	call   f0103f29 <cprintf>
}
f0104685:	83 c4 14             	add    $0x14,%esp
f0104688:	5b                   	pop    %ebx
f0104689:	5d                   	pop    %ebp
f010468a:	c3                   	ret    

f010468b <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f010468b:	55                   	push   %ebp
f010468c:	89 e5                	mov    %esp,%ebp
f010468e:	56                   	push   %esi
f010468f:	53                   	push   %ebx
f0104690:	83 ec 10             	sub    $0x10,%esp
f0104693:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0104696:	e8 ae 1f 00 00       	call   f0106649 <cpunum>
f010469b:	89 44 24 08          	mov    %eax,0x8(%esp)
f010469f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01046a3:	c7 04 24 d0 80 10 f0 	movl   $0xf01080d0,(%esp)
f01046aa:	e8 7a f8 ff ff       	call   f0103f29 <cprintf>
	print_regs(&tf->tf_regs);
f01046af:	89 1c 24             	mov    %ebx,(%esp)
f01046b2:	e8 2d ff ff ff       	call   f01045e4 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f01046b7:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f01046bb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01046bf:	c7 04 24 ee 80 10 f0 	movl   $0xf01080ee,(%esp)
f01046c6:	e8 5e f8 ff ff       	call   f0103f29 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f01046cb:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f01046cf:	89 44 24 04          	mov    %eax,0x4(%esp)
f01046d3:	c7 04 24 01 81 10 f0 	movl   $0xf0108101,(%esp)
f01046da:	e8 4a f8 ff ff       	call   f0103f29 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01046df:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f01046e2:	83 f8 13             	cmp    $0x13,%eax
f01046e5:	77 09                	ja     f01046f0 <print_trapframe+0x65>
		return excnames[trapno];
f01046e7:	8b 14 85 80 83 10 f0 	mov    -0xfef7c80(,%eax,4),%edx
f01046ee:	eb 1f                	jmp    f010470f <print_trapframe+0x84>
	if (trapno == T_SYSCALL)
f01046f0:	83 f8 30             	cmp    $0x30,%eax
f01046f3:	74 15                	je     f010470a <print_trapframe+0x7f>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f01046f5:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
f01046f8:	83 fa 0f             	cmp    $0xf,%edx
f01046fb:	ba 80 80 10 f0       	mov    $0xf0108080,%edx
f0104700:	b9 93 80 10 f0       	mov    $0xf0108093,%ecx
f0104705:	0f 47 d1             	cmova  %ecx,%edx
f0104708:	eb 05                	jmp    f010470f <print_trapframe+0x84>
	};

	if (trapno < ARRAY_SIZE(excnames))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f010470a:	ba 74 80 10 f0       	mov    $0xf0108074,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f010470f:	89 54 24 08          	mov    %edx,0x8(%esp)
f0104713:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104717:	c7 04 24 14 81 10 f0 	movl   $0xf0108114,(%esp)
f010471e:	e8 06 f8 ff ff       	call   f0103f29 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0104723:	3b 1d 60 1a 23 f0    	cmp    0xf0231a60,%ebx
f0104729:	75 19                	jne    f0104744 <print_trapframe+0xb9>
f010472b:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f010472f:	75 13                	jne    f0104744 <print_trapframe+0xb9>

static inline uint32_t
rcr2(void)
{
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0104731:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0104734:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104738:	c7 04 24 26 81 10 f0 	movl   $0xf0108126,(%esp)
f010473f:	e8 e5 f7 ff ff       	call   f0103f29 <cprintf>
	cprintf("  err  0x%08x", tf->tf_err);
f0104744:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0104747:	89 44 24 04          	mov    %eax,0x4(%esp)
f010474b:	c7 04 24 35 81 10 f0 	movl   $0xf0108135,(%esp)
f0104752:	e8 d2 f7 ff ff       	call   f0103f29 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0104757:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f010475b:	75 51                	jne    f01047ae <print_trapframe+0x123>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f010475d:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0104760:	89 c2                	mov    %eax,%edx
f0104762:	83 e2 01             	and    $0x1,%edx
f0104765:	ba a2 80 10 f0       	mov    $0xf01080a2,%edx
f010476a:	b9 ad 80 10 f0       	mov    $0xf01080ad,%ecx
f010476f:	0f 45 ca             	cmovne %edx,%ecx
f0104772:	89 c2                	mov    %eax,%edx
f0104774:	83 e2 02             	and    $0x2,%edx
f0104777:	ba b9 80 10 f0       	mov    $0xf01080b9,%edx
f010477c:	be bf 80 10 f0       	mov    $0xf01080bf,%esi
f0104781:	0f 44 d6             	cmove  %esi,%edx
f0104784:	83 e0 04             	and    $0x4,%eax
f0104787:	b8 c4 80 10 f0       	mov    $0xf01080c4,%eax
f010478c:	be c9 80 10 f0       	mov    $0xf01080c9,%esi
f0104791:	0f 44 c6             	cmove  %esi,%eax
f0104794:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0104798:	89 54 24 08          	mov    %edx,0x8(%esp)
f010479c:	89 44 24 04          	mov    %eax,0x4(%esp)
f01047a0:	c7 04 24 43 81 10 f0 	movl   $0xf0108143,(%esp)
f01047a7:	e8 7d f7 ff ff       	call   f0103f29 <cprintf>
f01047ac:	eb 0c                	jmp    f01047ba <print_trapframe+0x12f>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f01047ae:	c7 04 24 b0 7f 10 f0 	movl   $0xf0107fb0,(%esp)
f01047b5:	e8 6f f7 ff ff       	call   f0103f29 <cprintf>
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f01047ba:	8b 43 30             	mov    0x30(%ebx),%eax
f01047bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01047c1:	c7 04 24 52 81 10 f0 	movl   $0xf0108152,(%esp)
f01047c8:	e8 5c f7 ff ff       	call   f0103f29 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f01047cd:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f01047d1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01047d5:	c7 04 24 61 81 10 f0 	movl   $0xf0108161,(%esp)
f01047dc:	e8 48 f7 ff ff       	call   f0103f29 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f01047e1:	8b 43 38             	mov    0x38(%ebx),%eax
f01047e4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01047e8:	c7 04 24 74 81 10 f0 	movl   $0xf0108174,(%esp)
f01047ef:	e8 35 f7 ff ff       	call   f0103f29 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f01047f4:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f01047f8:	74 27                	je     f0104821 <print_trapframe+0x196>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f01047fa:	8b 43 3c             	mov    0x3c(%ebx),%eax
f01047fd:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104801:	c7 04 24 83 81 10 f0 	movl   $0xf0108183,(%esp)
f0104808:	e8 1c f7 ff ff       	call   f0103f29 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f010480d:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0104811:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104815:	c7 04 24 92 81 10 f0 	movl   $0xf0108192,(%esp)
f010481c:	e8 08 f7 ff ff       	call   f0103f29 <cprintf>
	}
}
f0104821:	83 c4 10             	add    $0x10,%esp
f0104824:	5b                   	pop    %ebx
f0104825:	5e                   	pop    %esi
f0104826:	5d                   	pop    %ebp
f0104827:	c3                   	ret    

f0104828 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0104828:	55                   	push   %ebp
f0104829:	89 e5                	mov    %esp,%ebp
f010482b:	57                   	push   %edi
f010482c:	56                   	push   %esi
f010482d:	53                   	push   %ebx
f010482e:	83 ec 2c             	sub    $0x2c,%esp
f0104831:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0104834:	0f 20 d0             	mov    %cr2,%eax
f0104837:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    uint32_t fault_va;

    // Read processor's CR2 register to find the faulting address
    fault_va = rcr2();
    cprintf("fault_va=%x\n",fault_va);
f010483a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010483e:	c7 04 24 a5 81 10 f0 	movl   $0xf01081a5,(%esp)
f0104845:	e8 df f6 ff ff       	call   f0103f29 <cprintf>

    // Handle kernel-mode page faults.
    if((tf->tf_cs & 3)==0)
f010484a:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f010484e:	75 1c                	jne    f010486c <page_fault_handler+0x44>
        panic("page fault kernel mode");
f0104850:	c7 44 24 08 b2 81 10 	movl   $0xf01081b2,0x8(%esp)
f0104857:	f0 
f0104858:	c7 44 24 04 93 01 00 	movl   $0x193,0x4(%esp)
f010485f:	00 
f0104860:	c7 04 24 c9 81 10 f0 	movl   $0xf01081c9,(%esp)
f0104867:	e8 d4 b7 ff ff       	call   f0100040 <_panic>

    // LAB 4: Your code here.

    // Destroy the environment that caused the fault.
    //cprintf("address= %x\n", curenv->env_tf.tf_esp);
    if(curenv->env_pgfault_upcall == NULL || curenv->env_tf.tf_esp > UXSTACKTOP || (curenv->env_tf.tf_esp < (UXSTACKTOP-PGSIZE) && curenv->env_tf.tf_esp > USTACKTOP))
f010486c:	e8 d8 1d 00 00       	call   f0106649 <cpunum>
f0104871:	6b c0 74             	imul   $0x74,%eax,%eax
f0104874:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f010487a:	83 78 60 00          	cmpl   $0x0,0x60(%eax)
f010487e:	74 45                	je     f01048c5 <page_fault_handler+0x9d>
f0104880:	e8 c4 1d 00 00       	call   f0106649 <cpunum>
f0104885:	6b c0 74             	imul   $0x74,%eax,%eax
f0104888:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f010488e:	81 78 3c 00 00 c0 ee 	cmpl   $0xeec00000,0x3c(%eax)
f0104895:	77 2e                	ja     f01048c5 <page_fault_handler+0x9d>
f0104897:	e8 ad 1d 00 00       	call   f0106649 <cpunum>
f010489c:	6b c0 74             	imul   $0x74,%eax,%eax
f010489f:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f01048a5:	81 78 3c ff ef bf ee 	cmpl   $0xeebfefff,0x3c(%eax)
f01048ac:	77 64                	ja     f0104912 <page_fault_handler+0xea>
f01048ae:	e8 96 1d 00 00       	call   f0106649 <cpunum>
f01048b3:	6b c0 74             	imul   $0x74,%eax,%eax
f01048b6:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f01048bc:	81 78 3c 00 e0 bf ee 	cmpl   $0xeebfe000,0x3c(%eax)
f01048c3:	76 4d                	jbe    f0104912 <page_fault_handler+0xea>
    {
        cprintf("[%08x] user fault va %08x ip %08x\n",curenv->env_id, fault_va, tf->tf_eip);
f01048c5:	8b 73 30             	mov    0x30(%ebx),%esi
f01048c8:	e8 7c 1d 00 00       	call   f0106649 <cpunum>
f01048cd:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01048d1:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01048d4:	89 54 24 08          	mov    %edx,0x8(%esp)
f01048d8:	6b c0 74             	imul   $0x74,%eax,%eax
f01048db:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f01048e1:	8b 40 48             	mov    0x48(%eax),%eax
f01048e4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01048e8:	c7 04 24 58 83 10 f0 	movl   $0xf0108358,(%esp)
f01048ef:	e8 35 f6 ff ff       	call   f0103f29 <cprintf>
	 print_trapframe(tf);
f01048f4:	89 1c 24             	mov    %ebx,(%esp)
f01048f7:	e8 8f fd ff ff       	call   f010468b <print_trapframe>
        env_destroy(curenv);
f01048fc:	e8 48 1d 00 00       	call   f0106649 <cpunum>
f0104901:	6b c0 74             	imul   $0x74,%eax,%eax
f0104904:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f010490a:	89 04 24             	mov    %eax,(%esp)
f010490d:	e8 0b f3 ff ff       	call   f0103c1d <env_destroy>
    }
   
    uint32_t eStack = curenv->env_tf.tf_esp;
f0104912:	e8 32 1d 00 00       	call   f0106649 <cpunum>
f0104917:	6b c0 74             	imul   $0x74,%eax,%eax
f010491a:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
   
    if(eStack < UXSTACKTOP && eStack > (UXSTACKTOP-PGSIZE))
f0104920:	8b 40 3c             	mov    0x3c(%eax),%eax
f0104923:	05 ff 0f 40 11       	add    $0x11400fff,%eax
f0104928:	3d fe 0f 00 00       	cmp    $0xffe,%eax
f010492d:	77 43                	ja     f0104972 <page_fault_handler+0x14a>
    {
        eStack = curenv->env_tf.tf_esp - 4;
f010492f:	e8 15 1d 00 00       	call   f0106649 <cpunum>
f0104934:	6b c0 74             	imul   $0x74,%eax,%eax
f0104937:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f010493d:	8b 58 3c             	mov    0x3c(%eax),%ebx
f0104940:	8d 7b fc             	lea    -0x4(%ebx),%edi
        user_mem_assert(curenv, (void *)eStack-sizeof(struct UTrapframe), (size_t)sizeof(struct UTrapframe), PTE_U|PTE_P|PTE_W);
f0104943:	e8 01 1d 00 00       	call   f0106649 <cpunum>
f0104948:	c7 44 24 0c 07 00 00 	movl   $0x7,0xc(%esp)
f010494f:	00 
f0104950:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
f0104957:	00 
f0104958:	83 eb 38             	sub    $0x38,%ebx
f010495b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010495f:	6b c0 74             	imul   $0x74,%eax,%eax
f0104962:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f0104968:	89 04 24             	mov    %eax,(%esp)
f010496b:	e8 4f eb ff ff       	call   f01034bf <user_mem_assert>
f0104970:	eb 33                	jmp    f01049a5 <page_fault_handler+0x17d>
    }
    else
    {
        eStack = UXSTACKTOP;
        user_mem_assert(curenv, (void *) eStack-sizeof(struct UTrapframe), (size_t)sizeof(struct UTrapframe), PTE_U|PTE_P|PTE_W);       
f0104972:	e8 d2 1c 00 00       	call   f0106649 <cpunum>
f0104977:	c7 44 24 0c 07 00 00 	movl   $0x7,0xc(%esp)
f010497e:	00 
f010497f:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
f0104986:	00 
f0104987:	c7 44 24 04 cc ff bf 	movl   $0xeebfffcc,0x4(%esp)
f010498e:	ee 
f010498f:	6b c0 74             	imul   $0x74,%eax,%eax
f0104992:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f0104998:	89 04 24             	mov    %eax,(%esp)
f010499b:	e8 1f eb ff ff       	call   f01034bf <user_mem_assert>
        eStack = curenv->env_tf.tf_esp - 4;
        user_mem_assert(curenv, (void *)eStack-sizeof(struct UTrapframe), (size_t)sizeof(struct UTrapframe), PTE_U|PTE_P|PTE_W);
    }
    else
    {
        eStack = UXSTACKTOP;
f01049a0:	bf 00 00 c0 ee       	mov    $0xeec00000,%edi
        user_mem_assert(curenv, (void *) eStack-sizeof(struct UTrapframe), (size_t)sizeof(struct UTrapframe), PTE_U|PTE_P|PTE_W);       
    }           
   
    struct UTrapframe *utf=(void *)eStack-sizeof(struct UTrapframe);
f01049a5:	8d 5f cc             	lea    -0x34(%edi),%ebx
       
    utf->utf_esp = curenv->env_tf.tf_esp;
f01049a8:	e8 9c 1c 00 00       	call   f0106649 <cpunum>
f01049ad:	6b c0 74             	imul   $0x74,%eax,%eax
f01049b0:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f01049b6:	8b 40 3c             	mov    0x3c(%eax),%eax
f01049b9:	89 43 30             	mov    %eax,0x30(%ebx)
    utf->utf_err = curenv->env_tf.tf_err;
f01049bc:	e8 88 1c 00 00       	call   f0106649 <cpunum>
f01049c1:	6b c0 74             	imul   $0x74,%eax,%eax
f01049c4:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f01049ca:	8b 40 2c             	mov    0x2c(%eax),%eax
f01049cd:	89 43 04             	mov    %eax,0x4(%ebx)
    utf->utf_eip = curenv->env_tf.tf_eip;
f01049d0:	e8 74 1c 00 00       	call   f0106649 <cpunum>
f01049d5:	6b c0 74             	imul   $0x74,%eax,%eax
f01049d8:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f01049de:	8b 40 30             	mov    0x30(%eax),%eax
f01049e1:	89 43 28             	mov    %eax,0x28(%ebx)
    utf->utf_regs = curenv->env_tf.tf_regs;
f01049e4:	e8 60 1c 00 00       	call   f0106649 <cpunum>
f01049e9:	6b c0 74             	imul   $0x74,%eax,%eax
f01049ec:	83 ef 2c             	sub    $0x2c,%edi
f01049ef:	8b b0 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%esi
f01049f5:	b8 20 00 00 00       	mov    $0x20,%eax
f01049fa:	f7 c7 01 00 00 00    	test   $0x1,%edi
f0104a00:	74 03                	je     f0104a05 <page_fault_handler+0x1dd>
f0104a02:	a4                   	movsb  %ds:(%esi),%es:(%edi)
f0104a03:	b0 1f                	mov    $0x1f,%al
f0104a05:	f7 c7 02 00 00 00    	test   $0x2,%edi
f0104a0b:	74 05                	je     f0104a12 <page_fault_handler+0x1ea>
f0104a0d:	66 a5                	movsw  %ds:(%esi),%es:(%edi)
f0104a0f:	83 e8 02             	sub    $0x2,%eax
f0104a12:	89 c1                	mov    %eax,%ecx
f0104a14:	c1 e9 02             	shr    $0x2,%ecx
f0104a17:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104a19:	ba 00 00 00 00       	mov    $0x0,%edx
f0104a1e:	a8 02                	test   $0x2,%al
f0104a20:	74 0b                	je     f0104a2d <page_fault_handler+0x205>
f0104a22:	0f b7 16             	movzwl (%esi),%edx
f0104a25:	66 89 17             	mov    %dx,(%edi)
f0104a28:	ba 02 00 00 00       	mov    $0x2,%edx
f0104a2d:	a8 01                	test   $0x1,%al
f0104a2f:	74 07                	je     f0104a38 <page_fault_handler+0x210>
f0104a31:	0f b6 04 16          	movzbl (%esi,%edx,1),%eax
f0104a35:	88 04 17             	mov    %al,(%edi,%edx,1)
    utf->utf_eflags = curenv->env_tf.tf_eflags;
f0104a38:	e8 0c 1c 00 00       	call   f0106649 <cpunum>
f0104a3d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a40:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f0104a46:	8b 40 38             	mov    0x38(%eax),%eax
f0104a49:	89 43 2c             	mov    %eax,0x2c(%ebx)
    utf->utf_fault_va = fault_va;
f0104a4c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104a4f:	89 03                	mov    %eax,(%ebx)
    cprintf("va=%x\n", utf->utf_fault_va);
f0104a51:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104a55:	c7 04 24 ab 81 10 f0 	movl   $0xf01081ab,(%esp)
f0104a5c:	e8 c8 f4 ff ff       	call   f0103f29 <cprintf>
   
    curenv->env_tf.tf_esp = eStack - sizeof(struct UTrapframe);
f0104a61:	e8 e3 1b 00 00       	call   f0106649 <cpunum>
f0104a66:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a69:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f0104a6f:	89 58 3c             	mov    %ebx,0x3c(%eax)
   
    //cprintf("curenv->env_tf.tf_esp = %x\n", curenv->env_tf.tf_esp);
   
    curenv->env_tf.tf_eip = (uint32_t)curenv->env_pgfault_upcall;
f0104a72:	e8 d2 1b 00 00       	call   f0106649 <cpunum>
f0104a77:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a7a:	8b 98 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%ebx
f0104a80:	e8 c4 1b 00 00       	call   f0106649 <cpunum>
f0104a85:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a88:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f0104a8e:	8b 40 60             	mov    0x60(%eax),%eax
f0104a91:	89 43 30             	mov    %eax,0x30(%ebx)
    env_run(curenv);
f0104a94:	e8 b0 1b 00 00       	call   f0106649 <cpunum>
f0104a99:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a9c:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f0104aa2:	89 04 24             	mov    %eax,(%esp)
f0104aa5:	e8 14 f2 ff ff       	call   f0103cbe <env_run>

f0104aaa <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0104aaa:	55                   	push   %ebp
f0104aab:	89 e5                	mov    %esp,%ebp
f0104aad:	57                   	push   %edi
f0104aae:	56                   	push   %esi
f0104aaf:	83 ec 20             	sub    $0x20,%esp
f0104ab2:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0104ab5:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f0104ab6:	83 3d 80 1e 23 f0 00 	cmpl   $0x0,0xf0231e80
f0104abd:	74 01                	je     f0104ac0 <trap+0x16>
		asm volatile("hlt");
f0104abf:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0104ac0:	e8 84 1b 00 00       	call   f0106649 <cpunum>
f0104ac5:	6b d0 74             	imul   $0x74,%eax,%edx
f0104ac8:	81 c2 20 20 23 f0    	add    $0xf0232020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0104ace:	b8 01 00 00 00       	mov    $0x1,%eax
f0104ad3:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0104ad7:	83 f8 02             	cmp    $0x2,%eax
f0104ada:	75 0c                	jne    f0104ae8 <trap+0x3e>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f0104adc:	c7 04 24 c0 13 12 f0 	movl   $0xf01213c0,(%esp)
f0104ae3:	e8 df 1d 00 00       	call   f01068c7 <spin_lock>

static inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0104ae8:	9c                   	pushf  
f0104ae9:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0104aea:	f6 c4 02             	test   $0x2,%ah
f0104aed:	74 24                	je     f0104b13 <trap+0x69>
f0104aef:	c7 44 24 0c d5 81 10 	movl   $0xf01081d5,0xc(%esp)
f0104af6:	f0 
f0104af7:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0104afe:	f0 
f0104aff:	c7 44 24 04 5e 01 00 	movl   $0x15e,0x4(%esp)
f0104b06:	00 
f0104b07:	c7 04 24 c9 81 10 f0 	movl   $0xf01081c9,(%esp)
f0104b0e:	e8 2d b5 ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f0104b13:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0104b17:	83 e0 03             	and    $0x3,%eax
f0104b1a:	66 83 f8 03          	cmp    $0x3,%ax
f0104b1e:	0f 85 a7 00 00 00    	jne    f0104bcb <trap+0x121>
f0104b24:	c7 04 24 c0 13 12 f0 	movl   $0xf01213c0,(%esp)
f0104b2b:	e8 97 1d 00 00       	call   f01068c7 <spin_lock>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		lock_kernel();
		assert(curenv);
f0104b30:	e8 14 1b 00 00       	call   f0106649 <cpunum>
f0104b35:	6b c0 74             	imul   $0x74,%eax,%eax
f0104b38:	83 b8 28 20 23 f0 00 	cmpl   $0x0,-0xfdcdfd8(%eax)
f0104b3f:	75 24                	jne    f0104b65 <trap+0xbb>
f0104b41:	c7 44 24 0c ee 81 10 	movl   $0xf01081ee,0xc(%esp)
f0104b48:	f0 
f0104b49:	c7 44 24 08 fa 72 10 	movl   $0xf01072fa,0x8(%esp)
f0104b50:	f0 
f0104b51:	c7 44 24 04 66 01 00 	movl   $0x166,0x4(%esp)
f0104b58:	00 
f0104b59:	c7 04 24 c9 81 10 f0 	movl   $0xf01081c9,(%esp)
f0104b60:	e8 db b4 ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f0104b65:	e8 df 1a 00 00       	call   f0106649 <cpunum>
f0104b6a:	6b c0 74             	imul   $0x74,%eax,%eax
f0104b6d:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f0104b73:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f0104b77:	75 2d                	jne    f0104ba6 <trap+0xfc>
			env_free(curenv);
f0104b79:	e8 cb 1a 00 00       	call   f0106649 <cpunum>
f0104b7e:	6b c0 74             	imul   $0x74,%eax,%eax
f0104b81:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f0104b87:	89 04 24             	mov    %eax,(%esp)
f0104b8a:	e8 89 ee ff ff       	call   f0103a18 <env_free>
			curenv = NULL;
f0104b8f:	e8 b5 1a 00 00       	call   f0106649 <cpunum>
f0104b94:	6b c0 74             	imul   $0x74,%eax,%eax
f0104b97:	c7 80 28 20 23 f0 00 	movl   $0x0,-0xfdcdfd8(%eax)
f0104b9e:	00 00 00 
			sched_yield();
f0104ba1:	e8 30 03 00 00       	call   f0104ed6 <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0104ba6:	e8 9e 1a 00 00       	call   f0106649 <cpunum>
f0104bab:	6b c0 74             	imul   $0x74,%eax,%eax
f0104bae:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f0104bb4:	b9 11 00 00 00       	mov    $0x11,%ecx
f0104bb9:	89 c7                	mov    %eax,%edi
f0104bbb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0104bbd:	e8 87 1a 00 00       	call   f0106649 <cpunum>
f0104bc2:	6b c0 74             	imul   $0x74,%eax,%eax
f0104bc5:	8b b0 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0104bcb:	89 35 60 1a 23 f0    	mov    %esi,0xf0231a60
{
	int rval=0;
		//cprintf("error interruot %x\n", tf->tf_err);
	// Handle processor exceptions.
	// LAB 3: Your code here.
	if(tf->tf_trapno==14)
f0104bd1:	8b 46 28             	mov    0x28(%esi),%eax
f0104bd4:	83 f8 0e             	cmp    $0xe,%eax
f0104bd7:	75 08                	jne    f0104be1 <trap+0x137>
       {
        page_fault_handler(tf);
f0104bd9:	89 34 24             	mov    %esi,(%esp)
f0104bdc:	e8 47 fc ff ff       	call   f0104828 <page_fault_handler>
        return;
	}
	
	if(tf->tf_trapno==3)
f0104be1:	83 f8 03             	cmp    $0x3,%eax
f0104be4:	75 0c                	jne    f0104bf2 <trap+0x148>
	{
	monitor(tf);
f0104be6:	89 34 24             	mov    %esi,(%esp)
f0104be9:	e8 9d bd ff ff       	call   f010098b <monitor>
f0104bee:	66 90                	xchg   %ax,%ax
f0104bf0:	eb 6d                	jmp    f0104c5f <trap+0x1b5>
	return;	
		
	}
	
	if(tf->tf_trapno==T_SYSCALL)
f0104bf2:	83 f8 30             	cmp    $0x30,%eax
f0104bf5:	75 32                	jne    f0104c29 <trap+0x17f>
	{
	rval= syscall(tf->tf_regs.reg_eax,tf->tf_regs.reg_edx,tf->tf_regs.reg_ecx,tf->tf_regs.reg_ebx,tf->tf_regs.reg_edi,tf->tf_regs.reg_esi);
f0104bf7:	8b 46 04             	mov    0x4(%esi),%eax
f0104bfa:	89 44 24 14          	mov    %eax,0x14(%esp)
f0104bfe:	8b 06                	mov    (%esi),%eax
f0104c00:	89 44 24 10          	mov    %eax,0x10(%esp)
f0104c04:	8b 46 10             	mov    0x10(%esi),%eax
f0104c07:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104c0b:	8b 46 18             	mov    0x18(%esi),%eax
f0104c0e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104c12:	8b 46 14             	mov    0x14(%esi),%eax
f0104c15:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104c19:	8b 46 1c             	mov    0x1c(%esi),%eax
f0104c1c:	89 04 24             	mov    %eax,(%esp)
f0104c1f:	e8 84 03 00 00       	call   f0104fa8 <syscall>
	tf->tf_regs.reg_eax = rval;
f0104c24:	89 46 1c             	mov    %eax,0x1c(%esi)
f0104c27:	eb 36                	jmp    f0104c5f <trap+0x1b5>


	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f0104c29:	83 f8 27             	cmp    $0x27,%eax
f0104c2c:	75 16                	jne    f0104c44 <trap+0x19a>
		cprintf("Spurious interrupt on irq 7\n");
f0104c2e:	c7 04 24 f5 81 10 f0 	movl   $0xf01081f5,(%esp)
f0104c35:	e8 ef f2 ff ff       	call   f0103f29 <cprintf>
		print_trapframe(tf);
f0104c3a:	89 34 24             	mov    %esi,(%esp)
f0104c3d:	e8 49 fa ff ff       	call   f010468b <print_trapframe>
f0104c42:	eb 1b                	jmp    f0104c5f <trap+0x1b5>

	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.

	if(tf->tf_trapno== IRQ_OFFSET +IRQ_TIMER)
f0104c44:	83 f8 20             	cmp    $0x20,%eax
f0104c47:	75 11                	jne    f0104c5a <trap+0x1b0>
	{
		//cprintf("It is a timer interrupt");
		lapic_eoi();
f0104c49:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104c50:	e8 41 1b 00 00       	call   f0106796 <lapic_eoi>
		sched_yield();
f0104c55:	e8 7c 02 00 00       	call   f0104ed6 <sched_yield>
	}
		



	sched_yield();        
f0104c5a:	e8 77 02 00 00       	call   f0104ed6 <sched_yield>
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f0104c5f:	90                   	nop
f0104c60:	e8 e4 19 00 00       	call   f0106649 <cpunum>
f0104c65:	6b c0 74             	imul   $0x74,%eax,%eax
f0104c68:	83 b8 28 20 23 f0 00 	cmpl   $0x0,-0xfdcdfd8(%eax)
f0104c6f:	74 2a                	je     f0104c9b <trap+0x1f1>
f0104c71:	e8 d3 19 00 00       	call   f0106649 <cpunum>
f0104c76:	6b c0 74             	imul   $0x74,%eax,%eax
f0104c79:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f0104c7f:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0104c83:	75 16                	jne    f0104c9b <trap+0x1f1>
		env_run(curenv);
f0104c85:	e8 bf 19 00 00       	call   f0106649 <cpunum>
f0104c8a:	6b c0 74             	imul   $0x74,%eax,%eax
f0104c8d:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f0104c93:	89 04 24             	mov    %eax,(%esp)
f0104c96:	e8 23 f0 ff ff       	call   f0103cbe <env_run>
	else
		sched_yield();
f0104c9b:	e8 36 02 00 00       	call   f0104ed6 <sched_yield>

f0104ca0 <divide_zero>:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(divide_zero,T_DIVIDE)
f0104ca0:	6a 00                	push   $0x0
f0104ca2:	6a 00                	push   $0x0
f0104ca4:	e9 46 01 00 00       	jmp    f0104def <_alltraps>
f0104ca9:	90                   	nop

f0104caa <brkpoint>:
TRAPHANDLER_NOEC(brkpoint,T_BRKPT)
f0104caa:	6a 00                	push   $0x0
f0104cac:	6a 03                	push   $0x3
f0104cae:	e9 3c 01 00 00       	jmp    f0104def <_alltraps>
f0104cb3:	90                   	nop

f0104cb4 <no_seg>:
TRAPHANDLER(no_seg,T_SEGNP)
f0104cb4:	6a 0b                	push   $0xb
f0104cb6:	e9 34 01 00 00       	jmp    f0104def <_alltraps>
f0104cbb:	90                   	nop

f0104cbc <debug>:
TRAPHANDLER_NOEC(debug,T_DEBUG)
f0104cbc:	6a 00                	push   $0x0
f0104cbe:	6a 01                	push   $0x1
f0104cc0:	e9 2a 01 00 00       	jmp    f0104def <_alltraps>
f0104cc5:	90                   	nop

f0104cc6 <nmi>:
TRAPHANDLER_NOEC(nmi,T_NMI)
f0104cc6:	6a 00                	push   $0x0
f0104cc8:	6a 02                	push   $0x2
f0104cca:	e9 20 01 00 00       	jmp    f0104def <_alltraps>
f0104ccf:	90                   	nop

f0104cd0 <oflow>:
TRAPHANDLER_NOEC(oflow,T_OFLOW)
f0104cd0:	6a 00                	push   $0x0
f0104cd2:	6a 04                	push   $0x4
f0104cd4:	e9 16 01 00 00       	jmp    f0104def <_alltraps>
f0104cd9:	90                   	nop

f0104cda <bound>:
TRAPHANDLER_NOEC(bound,T_BOUND)
f0104cda:	6a 00                	push   $0x0
f0104cdc:	6a 05                	push   $0x5
f0104cde:	e9 0c 01 00 00       	jmp    f0104def <_alltraps>
f0104ce3:	90                   	nop

f0104ce4 <illop>:
TRAPHANDLER_NOEC(illop,T_ILLOP)
f0104ce4:	6a 00                	push   $0x0
f0104ce6:	6a 06                	push   $0x6
f0104ce8:	e9 02 01 00 00       	jmp    f0104def <_alltraps>
f0104ced:	90                   	nop

f0104cee <device>:
TRAPHANDLER_NOEC(device,T_DEVICE)
f0104cee:	6a 00                	push   $0x0
f0104cf0:	6a 07                	push   $0x7
f0104cf2:	e9 f8 00 00 00       	jmp    f0104def <_alltraps>
f0104cf7:	90                   	nop

f0104cf8 <dblflt>:
TRAPHANDLER(dblflt,T_DBLFLT)
f0104cf8:	6a 08                	push   $0x8
f0104cfa:	e9 f0 00 00 00       	jmp    f0104def <_alltraps>
f0104cff:	90                   	nop

f0104d00 <tss>:
TRAPHANDLER(tss, T_TSS)
f0104d00:	6a 0a                	push   $0xa
f0104d02:	e9 e8 00 00 00       	jmp    f0104def <_alltraps>
f0104d07:	90                   	nop

f0104d08 <stack>:

TRAPHANDLER(stack, T_STACK)
f0104d08:	6a 0c                	push   $0xc
f0104d0a:	e9 e0 00 00 00       	jmp    f0104def <_alltraps>
f0104d0f:	90                   	nop

f0104d10 <gpflt>:
TRAPHANDLER(gpflt, T_GPFLT)
f0104d10:	6a 0d                	push   $0xd
f0104d12:	e9 d8 00 00 00       	jmp    f0104def <_alltraps>
f0104d17:	90                   	nop

f0104d18 <pgflt>:
TRAPHANDLER(pgflt, T_PGFLT)
f0104d18:	6a 0e                	push   $0xe
f0104d1a:	e9 d0 00 00 00       	jmp    f0104def <_alltraps>
f0104d1f:	90                   	nop

f0104d20 <fperr>:

TRAPHANDLER_NOEC(fperr, T_FPERR)
f0104d20:	6a 00                	push   $0x0
f0104d22:	6a 10                	push   $0x10
f0104d24:	e9 c6 00 00 00       	jmp    f0104def <_alltraps>
f0104d29:	90                   	nop

f0104d2a <align>:
TRAPHANDLER(align, T_ALIGN)
f0104d2a:	6a 11                	push   $0x11
f0104d2c:	e9 be 00 00 00       	jmp    f0104def <_alltraps>
f0104d31:	90                   	nop

f0104d32 <mchk>:
TRAPHANDLER_NOEC(mchk, T_MCHK)
f0104d32:	6a 00                	push   $0x0
f0104d34:	6a 12                	push   $0x12
f0104d36:	e9 b4 00 00 00       	jmp    f0104def <_alltraps>
f0104d3b:	90                   	nop

f0104d3c <simderr>:
TRAPHANDLER_NOEC(simderr, T_SIMDERR)
f0104d3c:	6a 00                	push   $0x0
f0104d3e:	6a 13                	push   $0x13
f0104d40:	e9 aa 00 00 00       	jmp    f0104def <_alltraps>
f0104d45:	90                   	nop

f0104d46 <syscalls>:



TRAPHANDLER_NOEC(syscalls, T_SYSCALL)
f0104d46:	6a 00                	push   $0x0
f0104d48:	6a 30                	push   $0x30
f0104d4a:	e9 a0 00 00 00       	jmp    f0104def <_alltraps>
f0104d4f:	90                   	nop

f0104d50 <irq>:

TRAPHANDLER_NOEC(irq, 32)
f0104d50:	6a 00                	push   $0x0
f0104d52:	6a 20                	push   $0x20
f0104d54:	e9 96 00 00 00       	jmp    f0104def <_alltraps>
f0104d59:	90                   	nop

f0104d5a <irq1>:
TRAPHANDLER_NOEC(irq1, 33)
f0104d5a:	6a 00                	push   $0x0
f0104d5c:	6a 21                	push   $0x21
f0104d5e:	e9 8c 00 00 00       	jmp    f0104def <_alltraps>
f0104d63:	90                   	nop

f0104d64 <irq2>:
TRAPHANDLER_NOEC(irq2, 34)
f0104d64:	6a 00                	push   $0x0
f0104d66:	6a 22                	push   $0x22
f0104d68:	e9 82 00 00 00       	jmp    f0104def <_alltraps>
f0104d6d:	90                   	nop

f0104d6e <irq3>:
TRAPHANDLER_NOEC(irq3, 35)
f0104d6e:	6a 00                	push   $0x0
f0104d70:	6a 23                	push   $0x23
f0104d72:	e9 78 00 00 00       	jmp    f0104def <_alltraps>
f0104d77:	90                   	nop

f0104d78 <irq4>:
TRAPHANDLER_NOEC(irq4, 36)
f0104d78:	6a 00                	push   $0x0
f0104d7a:	6a 24                	push   $0x24
f0104d7c:	e9 6e 00 00 00       	jmp    f0104def <_alltraps>
f0104d81:	90                   	nop

f0104d82 <irq5>:
TRAPHANDLER_NOEC(irq5, 37)
f0104d82:	6a 00                	push   $0x0
f0104d84:	6a 25                	push   $0x25
f0104d86:	e9 64 00 00 00       	jmp    f0104def <_alltraps>
f0104d8b:	90                   	nop

f0104d8c <irq6>:
TRAPHANDLER_NOEC(irq6, 38)
f0104d8c:	6a 00                	push   $0x0
f0104d8e:	6a 26                	push   $0x26
f0104d90:	e9 5a 00 00 00       	jmp    f0104def <_alltraps>
f0104d95:	90                   	nop

f0104d96 <irq7>:
TRAPHANDLER_NOEC(irq7, 39)
f0104d96:	6a 00                	push   $0x0
f0104d98:	6a 27                	push   $0x27
f0104d9a:	e9 50 00 00 00       	jmp    f0104def <_alltraps>
f0104d9f:	90                   	nop

f0104da0 <irq8>:
TRAPHANDLER_NOEC(irq8, 40)
f0104da0:	6a 00                	push   $0x0
f0104da2:	6a 28                	push   $0x28
f0104da4:	e9 46 00 00 00       	jmp    f0104def <_alltraps>
f0104da9:	90                   	nop

f0104daa <irq9>:
TRAPHANDLER_NOEC(irq9, 41)
f0104daa:	6a 00                	push   $0x0
f0104dac:	6a 29                	push   $0x29
f0104dae:	e9 3c 00 00 00       	jmp    f0104def <_alltraps>
f0104db3:	90                   	nop

f0104db4 <irq10>:
TRAPHANDLER_NOEC(irq10, 42)
f0104db4:	6a 00                	push   $0x0
f0104db6:	6a 2a                	push   $0x2a
f0104db8:	e9 32 00 00 00       	jmp    f0104def <_alltraps>
f0104dbd:	90                   	nop

f0104dbe <irq11>:
TRAPHANDLER_NOEC(irq11, 43)
f0104dbe:	6a 00                	push   $0x0
f0104dc0:	6a 2b                	push   $0x2b
f0104dc2:	e9 28 00 00 00       	jmp    f0104def <_alltraps>
f0104dc7:	90                   	nop

f0104dc8 <irq12>:
TRAPHANDLER_NOEC(irq12, 44)
f0104dc8:	6a 00                	push   $0x0
f0104dca:	6a 2c                	push   $0x2c
f0104dcc:	e9 1e 00 00 00       	jmp    f0104def <_alltraps>
f0104dd1:	90                   	nop

f0104dd2 <irq13>:
TRAPHANDLER_NOEC(irq13, 45)
f0104dd2:	6a 00                	push   $0x0
f0104dd4:	6a 2d                	push   $0x2d
f0104dd6:	e9 14 00 00 00       	jmp    f0104def <_alltraps>
f0104ddb:	90                   	nop

f0104ddc <irq14>:
TRAPHANDLER_NOEC(irq14, 46)
f0104ddc:	6a 00                	push   $0x0
f0104dde:	6a 2e                	push   $0x2e
f0104de0:	e9 0a 00 00 00       	jmp    f0104def <_alltraps>
f0104de5:	90                   	nop

f0104de6 <irq15>:
TRAPHANDLER_NOEC(irq15, 47)
f0104de6:	6a 00                	push   $0x0
f0104de8:	6a 2f                	push   $0x2f
f0104dea:	e9 00 00 00 00       	jmp    f0104def <_alltraps>

f0104def <_alltraps>:



.globl _alltraps
_alltraps:
	pushl %ds
f0104def:	1e                   	push   %ds
    pushl %es
f0104df0:	06                   	push   %es
	pushal
f0104df1:	60                   	pusha  

	movw $GD_KD, %ax
f0104df2:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f0104df6:	8e d8                	mov    %eax,%ds
	movw %ax, %es 
f0104df8:	8e c0                	mov    %eax,%es

    pushl %esp  /* trap(%esp) */
f0104dfa:	54                   	push   %esp
    call trap
f0104dfb:	e8 aa fc ff ff       	call   f0104aaa <trap>

f0104e00 <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f0104e00:	55                   	push   %ebp
f0104e01:	89 e5                	mov    %esp,%ebp
f0104e03:	83 ec 18             	sub    $0x18,%esp
f0104e06:	8b 15 48 12 23 f0    	mov    0xf0231248,%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0104e0c:	b8 00 00 00 00       	mov    $0x0,%eax
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
f0104e11:	8b 4a 54             	mov    0x54(%edx),%ecx
f0104e14:	83 e9 01             	sub    $0x1,%ecx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
		if ((envs[i].env_status == ENV_RUNNABLE ||
f0104e17:	83 f9 02             	cmp    $0x2,%ecx
f0104e1a:	76 0f                	jbe    f0104e2b <sched_halt+0x2b>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0104e1c:	83 c0 01             	add    $0x1,%eax
f0104e1f:	83 c2 7c             	add    $0x7c,%edx
f0104e22:	3d 00 04 00 00       	cmp    $0x400,%eax
f0104e27:	75 e8                	jne    f0104e11 <sched_halt+0x11>
f0104e29:	eb 07                	jmp    f0104e32 <sched_halt+0x32>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f0104e2b:	3d 00 04 00 00       	cmp    $0x400,%eax
f0104e30:	75 1a                	jne    f0104e4c <sched_halt+0x4c>
		cprintf("No runnable environments in the system!\n");
f0104e32:	c7 04 24 d0 83 10 f0 	movl   $0xf01083d0,(%esp)
f0104e39:	e8 eb f0 ff ff       	call   f0103f29 <cprintf>
		while (1)
			monitor(NULL);
f0104e3e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0104e45:	e8 41 bb ff ff       	call   f010098b <monitor>
f0104e4a:	eb f2                	jmp    f0104e3e <sched_halt+0x3e>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f0104e4c:	e8 f8 17 00 00       	call   f0106649 <cpunum>
f0104e51:	6b c0 74             	imul   $0x74,%eax,%eax
f0104e54:	c7 80 28 20 23 f0 00 	movl   $0x0,-0xfdcdfd8(%eax)
f0104e5b:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f0104e5e:	a1 8c 1e 23 f0       	mov    0xf0231e8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0104e63:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0104e68:	77 20                	ja     f0104e8a <sched_halt+0x8a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0104e6a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104e6e:	c7 44 24 08 68 6d 10 	movl   $0xf0106d68,0x8(%esp)
f0104e75:	f0 
f0104e76:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
f0104e7d:	00 
f0104e7e:	c7 04 24 f9 83 10 f0 	movl   $0xf01083f9,(%esp)
f0104e85:	e8 b6 b1 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0104e8a:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0104e8f:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f0104e92:	e8 b2 17 00 00       	call   f0106649 <cpunum>
f0104e97:	6b d0 74             	imul   $0x74,%eax,%edx
f0104e9a:	81 c2 20 20 23 f0    	add    $0xf0232020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f0104ea0:	b8 02 00 00 00       	mov    $0x2,%eax
f0104ea5:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0104ea9:	c7 04 24 c0 13 12 f0 	movl   $0xf01213c0,(%esp)
f0104eb0:	e8 be 1a 00 00       	call   f0106973 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f0104eb5:	f3 90                	pause  
		"pushl $0\n"
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f0104eb7:	e8 8d 17 00 00       	call   f0106649 <cpunum>
f0104ebc:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
f0104ebf:	8b 80 30 20 23 f0    	mov    -0xfdcdfd0(%eax),%eax
f0104ec5:	bd 00 00 00 00       	mov    $0x0,%ebp
f0104eca:	89 c4                	mov    %eax,%esp
f0104ecc:	6a 00                	push   $0x0
f0104ece:	6a 00                	push   $0x0
f0104ed0:	fb                   	sti    
f0104ed1:	f4                   	hlt    
f0104ed2:	eb fd                	jmp    f0104ed1 <sched_halt+0xd1>
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f0104ed4:	c9                   	leave  
f0104ed5:	c3                   	ret    

f0104ed6 <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f0104ed6:	55                   	push   %ebp
f0104ed7:	89 e5                	mov    %esp,%ebp
f0104ed9:	56                   	push   %esi
f0104eda:	53                   	push   %ebx
f0104edb:	83 ec 10             	sub    $0x10,%esp
	// below to halt the cpu.

	// LAB 4: Your code here.
	uint32_t i; 
	//uint32_t currenv;
	uint32_t nextid= curenv ? ENVX(curenv->env_id) :0 ;   
f0104ede:	e8 66 17 00 00       	call   f0106649 <cpunum>
f0104ee3:	6b c0 74             	imul   $0x74,%eax,%eax
f0104ee6:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104eeb:	83 b8 28 20 23 f0 00 	cmpl   $0x0,-0xfdcdfd8(%eax)
f0104ef2:	0f 84 9f 00 00 00    	je     f0104f97 <sched_yield+0xc1>
f0104ef8:	e8 4c 17 00 00       	call   f0106649 <cpunum>
f0104efd:	6b c0 74             	imul   $0x74,%eax,%eax
f0104f00:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f0104f06:	8b 58 48             	mov    0x48(%eax),%ebx
f0104f09:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0104f0f:	e9 83 00 00 00       	jmp    f0104f97 <sched_yield+0xc1>

	for(i=0;i<NENV;i++)
	{
		
		//cprintf("next id is %d",nextid);
		if(envs[ENVX(nextid)].env_status==ENV_RUNNABLE)
f0104f14:	6b c3 7c             	imul   $0x7c,%ebx,%eax
f0104f17:	03 05 48 12 23 f0    	add    0xf0231248,%eax
f0104f1d:	83 78 54 02          	cmpl   $0x2,0x54(%eax)
f0104f21:	75 08                	jne    f0104f2b <sched_yield+0x55>
		{
			
			env_run(&envs[ENVX(nextid)]);
f0104f23:	89 04 24             	mov    %eax,(%esp)
f0104f26:	e8 93 ed ff ff       	call   f0103cbe <env_run>
			panic("Env_run succedded");
		}
		
		nextid=(nextid +1) %1024;
f0104f2b:	83 c3 01             	add    $0x1,%ebx
f0104f2e:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
		cprintf("The ids are %d", nextid);
f0104f34:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104f38:	c7 04 24 06 84 10 f0 	movl   $0xf0108406,(%esp)
f0104f3f:	e8 e5 ef ff ff       	call   f0103f29 <cprintf>
	// LAB 4: Your code here.
	uint32_t i; 
	//uint32_t currenv;
	uint32_t nextid= curenv ? ENVX(curenv->env_id) :0 ;   

	for(i=0;i<NENV;i++)
f0104f44:	83 ee 01             	sub    $0x1,%esi
f0104f47:	75 cb                	jne    f0104f14 <sched_yield+0x3e>
		
		nextid=(nextid +1) %1024;
		cprintf("The ids are %d", nextid);
	}

	if(curenv!=NULL && curenv->env_status==ENV_RUNNING)
f0104f49:	e8 fb 16 00 00       	call   f0106649 <cpunum>
f0104f4e:	6b c0 74             	imul   $0x74,%eax,%eax
f0104f51:	83 b8 28 20 23 f0 00 	cmpl   $0x0,-0xfdcdfd8(%eax)
f0104f58:	74 2a                	je     f0104f84 <sched_yield+0xae>
f0104f5a:	e8 ea 16 00 00       	call   f0106649 <cpunum>
f0104f5f:	6b c0 74             	imul   $0x74,%eax,%eax
f0104f62:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f0104f68:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0104f6c:	75 16                	jne    f0104f84 <sched_yield+0xae>
	{
			
			env_run(curenv);
f0104f6e:	e8 d6 16 00 00       	call   f0106649 <cpunum>
f0104f73:	6b c0 74             	imul   $0x74,%eax,%eax
f0104f76:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f0104f7c:	89 04 24             	mov    %eax,(%esp)
f0104f7f:	e8 3a ed ff ff       	call   f0103cbe <env_run>
	}		
	

	// sched_halt never returns
	cprintf("Im here");
f0104f84:	c7 04 24 15 84 10 f0 	movl   $0xf0108415,(%esp)
f0104f8b:	e8 99 ef ff ff       	call   f0103f29 <cprintf>
	sched_halt();
f0104f90:	e8 6b fe ff ff       	call   f0104e00 <sched_halt>
f0104f95:	eb 0a                	jmp    f0104fa1 <sched_yield+0xcb>
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f0104f97:	be 00 04 00 00       	mov    $0x400,%esi
f0104f9c:	e9 73 ff ff ff       	jmp    f0104f14 <sched_yield+0x3e>
	

	// sched_halt never returns
	cprintf("Im here");
	sched_halt();
}
f0104fa1:	83 c4 10             	add    $0x10,%esp
f0104fa4:	5b                   	pop    %ebx
f0104fa5:	5e                   	pop    %esi
f0104fa6:	5d                   	pop    %ebp
f0104fa7:	c3                   	ret    

f0104fa8 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0104fa8:	55                   	push   %ebp
f0104fa9:	89 e5                	mov    %esp,%ebp
f0104fab:	57                   	push   %edi
f0104fac:	56                   	push   %esi
f0104fad:	53                   	push   %ebx
f0104fae:	83 ec 2c             	sub    $0x2c,%esp
f0104fb1:	8b 45 08             	mov    0x8(%ebp),%eax
//	SYS_cputs = 0,
//	SYS_cgetc,
//	SYS_getenvid,
//	SYS_env_destroy,al
	int rval=0;
	switch(syscallno){
f0104fb4:	83 f8 0c             	cmp    $0xc,%eax
f0104fb7:	0f 87 c1 04 00 00    	ja     f010547e <syscall+0x4d6>
f0104fbd:	ff 24 85 58 84 10 f0 	jmp    *-0xfef7ba8(,%eax,4)
static void
sys_cputs(const char *s, size_t len)
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.
    user_mem_assert(curenv, s, len, PTE_U);
f0104fc4:	e8 80 16 00 00       	call   f0106649 <cpunum>
f0104fc9:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f0104fd0:	00 
f0104fd1:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104fd4:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104fd8:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0104fdb:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104fdf:	6b c0 74             	imul   $0x74,%eax,%eax
f0104fe2:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f0104fe8:	89 04 24             	mov    %eax,(%esp)
f0104feb:	e8 cf e4 ff ff       	call   f01034bf <user_mem_assert>
	// LAB 3: Your code here.

	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0104ff0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104ff3:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104ff7:	8b 45 10             	mov    0x10(%ebp),%eax
f0104ffa:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104ffe:	c7 04 24 1d 84 10 f0 	movl   $0xf010841d,(%esp)
f0105005:	e8 1f ef ff ff       	call   f0103f29 <cprintf>
//	SYS_env_destroy,al
	int rval=0;
	switch(syscallno){
		case SYS_cputs:
			sys_cputs((const char *)a1, a2);
			return 0;		
f010500a:	b8 00 00 00 00       	mov    $0x0,%eax
f010500f:	e9 6f 04 00 00       	jmp    f0105483 <syscall+0x4db>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f0105014:	e8 1c b6 ff ff       	call   f0100635 <cons_getc>
		case SYS_cputs:
			sys_cputs((const char *)a1, a2);
			return 0;		
		case SYS_cgetc:
			sys_cgetc();
			return 0;
f0105019:	b8 00 00 00 00       	mov    $0x0,%eax
f010501e:	e9 60 04 00 00       	jmp    f0105483 <syscall+0x4db>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0105023:	e8 21 16 00 00       	call   f0106649 <cpunum>
f0105028:	6b c0 74             	imul   $0x74,%eax,%eax
f010502b:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f0105031:	8b 40 48             	mov    0x48(%eax),%eax
			return 0;		
		case SYS_cgetc:
			sys_cgetc();
			return 0;
		case SYS_getenvid:
			return sys_getenvid();
f0105034:	e9 4a 04 00 00       	jmp    f0105483 <syscall+0x4db>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0105039:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0105040:	00 
f0105041:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0105044:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105048:	8b 45 0c             	mov    0xc(%ebp),%eax
f010504b:	89 04 24             	mov    %eax,(%esp)
f010504e:	e8 60 e5 ff ff       	call   f01035b3 <envid2env>
		return r;
f0105053:	89 c2                	mov    %eax,%edx
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0105055:	85 c0                	test   %eax,%eax
f0105057:	78 6e                	js     f01050c7 <syscall+0x11f>
		return r;
	if (e == curenv)
f0105059:	e8 eb 15 00 00       	call   f0106649 <cpunum>
f010505e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0105061:	6b c0 74             	imul   $0x74,%eax,%eax
f0105064:	39 90 28 20 23 f0    	cmp    %edx,-0xfdcdfd8(%eax)
f010506a:	75 23                	jne    f010508f <syscall+0xe7>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f010506c:	e8 d8 15 00 00       	call   f0106649 <cpunum>
f0105071:	6b c0 74             	imul   $0x74,%eax,%eax
f0105074:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f010507a:	8b 40 48             	mov    0x48(%eax),%eax
f010507d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105081:	c7 04 24 22 84 10 f0 	movl   $0xf0108422,(%esp)
f0105088:	e8 9c ee ff ff       	call   f0103f29 <cprintf>
f010508d:	eb 28                	jmp    f01050b7 <syscall+0x10f>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f010508f:	8b 5a 48             	mov    0x48(%edx),%ebx
f0105092:	e8 b2 15 00 00       	call   f0106649 <cpunum>
f0105097:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010509b:	6b c0 74             	imul   $0x74,%eax,%eax
f010509e:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f01050a4:	8b 40 48             	mov    0x48(%eax),%eax
f01050a7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01050ab:	c7 04 24 3d 84 10 f0 	movl   $0xf010843d,(%esp)
f01050b2:	e8 72 ee ff ff       	call   f0103f29 <cprintf>
	env_destroy(e);
f01050b7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01050ba:	89 04 24             	mov    %eax,(%esp)
f01050bd:	e8 5b eb ff ff       	call   f0103c1d <env_destroy>
	return 0;
f01050c2:	ba 00 00 00 00       	mov    $0x0,%edx
			sys_cgetc();
			return 0;
		case SYS_getenvid:
			return sys_getenvid();
		case SYS_env_destroy:
			return sys_env_destroy(a1);			
f01050c7:	89 d0                	mov    %edx,%eax
f01050c9:	e9 b5 03 00 00       	jmp    f0105483 <syscall+0x4db>

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f01050ce:	e8 03 fe ff ff       	call   f0104ed6 <sched_yield>
	// LAB 4: Your code here.
	struct PageInfo* check;
	struct Env* env;
	int status;
	uint32_t flag;
	if ((perm & PTE_U) != PTE_U || (perm & PTE_P) != PTE_P  ||(perm & ~PTE_SYSCALL) != 0 )
f01050d3:	8b 45 14             	mov    0x14(%ebp),%eax
f01050d6:	25 fd f1 ff ff       	and    $0xfffff1fd,%eax
f01050db:	83 f8 05             	cmp    $0x5,%eax
f01050de:	75 7d                	jne    f010515d <syscall+0x1b5>
		return -E_INVAL;

	

	flag= envid2env(envid, &env ,1);
f01050e0:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01050e7:	00 
f01050e8:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01050eb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01050ef:	8b 45 0c             	mov    0xc(%ebp),%eax
f01050f2:	89 04 24             	mov    %eax,(%esp)
f01050f5:	e8 b9 e4 ff ff       	call   f01035b3 <envid2env>

	

	if(flag==-E_BAD_ENV)
f01050fa:	83 f8 fe             	cmp    $0xfffffffe,%eax
f01050fd:	0f 84 80 03 00 00    	je     f0105483 <syscall+0x4db>
	{ 
		return flag;
	} 

	
	if((uintptr_t)va>= UTOP || (uintptr_t) va % PGSIZE!=0)
f0105103:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f010510a:	77 5b                	ja     f0105167 <syscall+0x1bf>
f010510c:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0105113:	75 5c                	jne    f0105171 <syscall+0x1c9>
		return -E_INVAL;
	}

	

	check=page_alloc(ALLOC_ZERO);
f0105115:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010511c:	e8 21 bf ff ff       	call   f0101042 <page_alloc>
f0105121:	89 c3                	mov    %eax,%ebx
	if(check==NULL)
f0105123:	85 c0                	test   %eax,%eax
f0105125:	74 54                	je     f010517b <syscall+0x1d3>
	{
		return -E_NO_MEM;
	}
	
	
	status=page_insert( env->env_pgdir, check,va, perm);
f0105127:	8b 45 14             	mov    0x14(%ebp),%eax
f010512a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010512e:	8b 45 10             	mov    0x10(%ebp),%eax
f0105131:	89 44 24 08          	mov    %eax,0x8(%esp)
f0105135:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0105139:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010513c:	8b 40 78             	mov    0x78(%eax),%eax
f010513f:	89 04 24             	mov    %eax,(%esp)
f0105142:	e8 53 c2 ff ff       	call   f010139a <page_insert>
f0105147:	89 c6                	mov    %eax,%esi
	if(status== -E_NO_MEM)
f0105149:	83 f8 fc             	cmp    $0xfffffffc,%eax
f010514c:	75 37                	jne    f0105185 <syscall+0x1dd>
	{
		page_free(check);
f010514e:	89 1c 24             	mov    %ebx,(%esp)
f0105151:	e8 77 bf ff ff       	call   f01010cd <page_free>
		return -E_NO_MEM;
f0105156:	89 f0                	mov    %esi,%eax
f0105158:	e9 26 03 00 00       	jmp    f0105483 <syscall+0x4db>
	struct PageInfo* check;
	struct Env* env;
	int status;
	uint32_t flag;
	if ((perm & PTE_U) != PTE_U || (perm & PTE_P) != PTE_P  ||(perm & ~PTE_SYSCALL) != 0 )
		return -E_INVAL;
f010515d:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0105162:	e9 1c 03 00 00       	jmp    f0105483 <syscall+0x4db>
	} 

	
	if((uintptr_t)va>= UTOP || (uintptr_t) va % PGSIZE!=0)
	{
		return -E_INVAL;
f0105167:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010516c:	e9 12 03 00 00       	jmp    f0105483 <syscall+0x4db>
f0105171:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0105176:	e9 08 03 00 00       	jmp    f0105483 <syscall+0x4db>
	

	check=page_alloc(ALLOC_ZERO);
	if(check==NULL)
	{
		return -E_NO_MEM;
f010517b:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0105180:	e9 fe 02 00 00       	jmp    f0105483 <syscall+0x4db>
			return sys_env_destroy(a1);			
		case SYS_yield:			
			sys_yield();
			break;
		case SYS_page_alloc:
			return sys_page_alloc((envid_t)a1, (void *)a2, a3);			
f0105185:	e9 f9 02 00 00       	jmp    f0105483 <syscall+0x4db>
//	-E_NO_MEM if there's no memory to allocate any necessary page tables.
static int
sys_page_map(envid_t srcenvid, void *srcva,
	     envid_t dstenvid, void *dstva, int perm)
{
	if((uintptr_t)srcva >= UTOP || (uintptr_t)dstva >= UTOP || (((uintptr_t)srcva%PGSIZE) != 0) || (((uintptr_t)dstva%PGSIZE) != 0))
f010518a:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0105191:	0f 87 06 01 00 00    	ja     f010529d <syscall+0x2f5>
f0105197:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f010519e:	0f 87 f9 00 00 00    	ja     f010529d <syscall+0x2f5>
f01051a4:	8b 45 10             	mov    0x10(%ebp),%eax
f01051a7:	0b 45 18             	or     0x18(%ebp),%eax
f01051aa:	a9 ff 0f 00 00       	test   $0xfff,%eax
f01051af:	0f 85 ef 00 00 00    	jne    f01052a4 <syscall+0x2fc>
		return -E_INVAL;


	if ((perm & PTE_U) != PTE_U || (perm & PTE_P) != PTE_P  || (perm & ~PTE_SYSCALL) != 0 )
f01051b5:	8b 45 1c             	mov    0x1c(%ebp),%eax
f01051b8:	25 fd f1 ff ff       	and    $0xfffff1fd,%eax
f01051bd:	83 f8 05             	cmp    $0x5,%eax
f01051c0:	0f 85 e5 00 00 00    	jne    f01052ab <syscall+0x303>
		return -E_INVAL;

	struct Env * src;
	struct Env * dst;
	if( !envid2env(srcenvid, &src, true) && !envid2env(dstenvid, &dst,  true))
f01051c6:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01051cd:	00 
f01051ce:	8d 45 dc             	lea    -0x24(%ebp),%eax
f01051d1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01051d5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01051d8:	89 04 24             	mov    %eax,(%esp)
f01051db:	e8 d3 e3 ff ff       	call   f01035b3 <envid2env>
f01051e0:	85 c0                	test   %eax,%eax
f01051e2:	0f 85 ca 00 00 00    	jne    f01052b2 <syscall+0x30a>
f01051e8:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01051ef:	00 
f01051f0:	8d 45 e0             	lea    -0x20(%ebp),%eax
f01051f3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01051f7:	8b 45 14             	mov    0x14(%ebp),%eax
f01051fa:	89 04 24             	mov    %eax,(%esp)
f01051fd:	e8 b1 e3 ff ff       	call   f01035b3 <envid2env>
f0105202:	89 c6                	mov    %eax,%esi
f0105204:	85 c0                	test   %eax,%eax
f0105206:	0f 85 ad 00 00 00    	jne    f01052b9 <syscall+0x311>
	{
		//cprintf("In sys_page_map\n");
		pte_t * pte;
		struct PageInfo * pp = page_lookup(src->env_pgdir, srcva, &pte);
f010520c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010520f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0105213:	8b 45 10             	mov    0x10(%ebp),%eax
f0105216:	89 44 24 04          	mov    %eax,0x4(%esp)
f010521a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010521d:	8b 40 78             	mov    0x78(%eax),%eax
f0105220:	89 04 24             	mov    %eax,(%esp)
f0105223:	e8 89 c0 ff ff       	call   f01012b1 <page_lookup>
		if(pp)
f0105228:	85 c0                	test   %eax,%eax
f010522a:	74 6a                	je     f0105296 <syscall+0x2ee>
		{
			if(perm & PTE_W)
f010522c:	8b 5d 1c             	mov    0x1c(%ebp),%ebx
f010522f:	83 e3 02             	and    $0x2,%ebx
f0105232:	74 36                	je     f010526a <syscall+0x2c2>
						return -E_NO_MEM;
					else
						return 0;
				}
				else
					return -E_INVAL;
f0105234:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
		struct PageInfo * pp = page_lookup(src->env_pgdir, srcva, &pte);
		if(pp)
		{
			if(perm & PTE_W)
			{
				if(*pte & PTE_W)
f0105239:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010523c:	f6 02 02             	testb  $0x2,(%edx)
f010523f:	74 7d                	je     f01052be <syscall+0x316>
				{
					if(page_insert(dst->env_pgdir, pp, dstva, perm) < 0)
f0105241:	8b 4d 1c             	mov    0x1c(%ebp),%ecx
f0105244:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0105248:	8b 4d 18             	mov    0x18(%ebp),%ecx
f010524b:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010524f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105253:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105256:	8b 40 78             	mov    0x78(%eax),%eax
f0105259:	89 04 24             	mov    %eax,(%esp)
f010525c:	e8 39 c1 ff ff       	call   f010139a <page_insert>
						return -E_NO_MEM;
f0105261:	85 c0                	test   %eax,%eax
f0105263:	b3 fc                	mov    $0xfc,%bl
f0105265:	0f 49 de             	cmovns %esi,%ebx
f0105268:	eb 54                	jmp    f01052be <syscall+0x316>
				else
					return -E_INVAL;
			}
			else
			{
				if(page_insert(dst->env_pgdir, pp, dstva, perm) < 0)
f010526a:	8b 75 1c             	mov    0x1c(%ebp),%esi
f010526d:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0105271:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0105274:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105278:	89 44 24 04          	mov    %eax,0x4(%esp)
f010527c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010527f:	8b 40 78             	mov    0x78(%eax),%eax
f0105282:	89 04 24             	mov    %eax,(%esp)
f0105285:	e8 10 c1 ff ff       	call   f010139a <page_insert>
					return -E_NO_MEM;  	
f010528a:	85 c0                	test   %eax,%eax
f010528c:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0105291:	0f 48 d8             	cmovs  %eax,%ebx
f0105294:	eb 28                	jmp    f01052be <syscall+0x316>
				else
					return 0;
			}
		}
		else
			return -E_INVAL; 
f0105296:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f010529b:	eb 21                	jmp    f01052be <syscall+0x316>
static int
sys_page_map(envid_t srcenvid, void *srcva,
	     envid_t dstenvid, void *dstva, int perm)
{
	if((uintptr_t)srcva >= UTOP || (uintptr_t)dstva >= UTOP || (((uintptr_t)srcva%PGSIZE) != 0) || (((uintptr_t)dstva%PGSIZE) != 0))
		return -E_INVAL;
f010529d:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01052a2:	eb 1a                	jmp    f01052be <syscall+0x316>
f01052a4:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01052a9:	eb 13                	jmp    f01052be <syscall+0x316>


	if ((perm & PTE_U) != PTE_U || (perm & PTE_P) != PTE_P  || (perm & ~PTE_SYSCALL) != 0 )
		return -E_INVAL;
f01052ab:	bb fd ff ff ff       	mov    $0xfffffffd,%ebx
f01052b0:	eb 0c                	jmp    f01052be <syscall+0x316>
		}
		else
			return -E_INVAL; 
	}
	else 
return -E_BAD_ENV;
f01052b2:	bb fe ff ff ff       	mov    $0xfffffffe,%ebx
f01052b7:	eb 05                	jmp    f01052be <syscall+0x316>
f01052b9:	bb fe ff ff ff       	mov    $0xfffffffe,%ebx
			sys_yield();
			break;
		case SYS_page_alloc:
			return sys_page_alloc((envid_t)a1, (void *)a2, a3);			
		case SYS_page_map:			
			return sys_page_map((envid_t)a1, (void *)a2, (envid_t)a3, (void *)a4, a5);			
f01052be:	89 d8                	mov    %ebx,%eax
f01052c0:	e9 be 01 00 00       	jmp    f0105483 <syscall+0x4db>
sys_page_unmap(envid_t envid, void *va)
{
	// Hint: This function is a wrapper around page_remove().

	struct Env* env;
	if(envid2env(envid, &env, 1)== -E_BAD_ENV)
f01052c5:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01052cc:	00 
f01052cd:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01052d0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01052d4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01052d7:	89 04 24             	mov    %eax,(%esp)
f01052da:	e8 d4 e2 ff ff       	call   f01035b3 <envid2env>
f01052df:	83 f8 fe             	cmp    $0xfffffffe,%eax
f01052e2:	0f 84 9b 01 00 00    	je     f0105483 <syscall+0x4db>
	{
		return -E_BAD_ENV;
	}

	if((uintptr_t) va>=UTOP || ((uintptr_t) va % PGSIZE!=0))
f01052e8:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f01052ef:	77 28                	ja     f0105319 <syscall+0x371>
f01052f1:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f01052f8:	75 29                	jne    f0105323 <syscall+0x37b>
	{
		return -E_INVAL;
	}
	page_remove(env->env_pgdir, va);
f01052fa:	8b 45 10             	mov    0x10(%ebp),%eax
f01052fd:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105301:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105304:	8b 40 78             	mov    0x78(%eax),%eax
f0105307:	89 04 24             	mov    %eax,(%esp)
f010530a:	e8 3b c0 ff ff       	call   f010134a <page_remove>
	return 0;
f010530f:	b8 00 00 00 00       	mov    $0x0,%eax
f0105314:	e9 6a 01 00 00       	jmp    f0105483 <syscall+0x4db>
		return -E_BAD_ENV;
	}

	if((uintptr_t) va>=UTOP || ((uintptr_t) va % PGSIZE!=0))
	{
		return -E_INVAL;
f0105319:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010531e:	e9 60 01 00 00       	jmp    f0105483 <syscall+0x4db>
f0105323:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
		case SYS_page_alloc:
			return sys_page_alloc((envid_t)a1, (void *)a2, a3);			
		case SYS_page_map:			
			return sys_page_map((envid_t)a1, (void *)a2, (envid_t)a3, (void *)a4, a5);			
		case SYS_page_unmap:
			return sys_page_unmap((envid_t)a1, (void *)a2);			
f0105328:	e9 56 01 00 00       	jmp    f0105483 <syscall+0x4db>
	// from the current environment -- but tweaked so sys_exofork
	// will appear to return 0.

	// LAB 4: Your code here.
	int flag=0;
	struct Env *newenv_store=NULL;	
f010532d:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	flag= env_alloc(&newenv_store, curenv->env_id);
f0105334:	e8 10 13 00 00       	call   f0106649 <cpunum>
f0105339:	6b c0 74             	imul   $0x74,%eax,%eax
f010533c:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f0105342:	8b 40 48             	mov    0x48(%eax),%eax
f0105345:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105349:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010534c:	89 04 24             	mov    %eax,(%esp)
f010534f:	e8 68 e3 ff ff       	call   f01036bc <env_alloc>
	//cprintf("Flag is %d", flag);
	if(flag<0)
	{
		return flag;
f0105354:	89 c2                	mov    %eax,%edx
	// LAB 4: Your code here.
	int flag=0;
	struct Env *newenv_store=NULL;	
	flag= env_alloc(&newenv_store, curenv->env_id);
	//cprintf("Flag is %d", flag);
	if(flag<0)
f0105356:	85 c0                	test   %eax,%eax
f0105358:	78 2e                	js     f0105388 <syscall+0x3e0>
	{
		return flag;
	}
	
	newenv_store->env_status= ENV_NOT_RUNNABLE;
f010535a:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010535d:	c7 43 54 04 00 00 00 	movl   $0x4,0x54(%ebx)
	newenv_store->env_tf= curenv->env_tf;
f0105364:	e8 e0 12 00 00       	call   f0106649 <cpunum>
f0105369:	6b c0 74             	imul   $0x74,%eax,%eax
f010536c:	8b b0 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%esi
f0105372:	b9 11 00 00 00       	mov    $0x11,%ecx
f0105377:	89 df                	mov    %ebx,%edi
f0105379:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	newenv_store->env_tf.tf_regs.reg_eax=0;
f010537b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010537e:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
	return (newenv_store->env_id);
f0105385:	8b 50 48             	mov    0x48(%eax),%edx
		case SYS_page_map:			
			return sys_page_map((envid_t)a1, (void *)a2, (envid_t)a3, (void *)a4, a5);			
		case SYS_page_unmap:
			return sys_page_unmap((envid_t)a1, (void *)a2);			
		case SYS_exofork:
			return sys_exofork();			
f0105388:	89 d0                	mov    %edx,%eax
f010538a:	e9 f4 00 00 00       	jmp    f0105483 <syscall+0x4db>
	// envid's status.

	// LAB 4: Your code here.
	struct Env *env_store;
	int check;	
	if(!(status == ENV_RUNNABLE || status == ENV_NOT_RUNNABLE))
f010538f:	83 7d 10 04          	cmpl   $0x4,0x10(%ebp)
f0105393:	74 06                	je     f010539b <syscall+0x3f3>
f0105395:	83 7d 10 02          	cmpl   $0x2,0x10(%ebp)
f0105399:	75 35                	jne    f01053d0 <syscall+0x428>
		return -E_INVAL;
	if((check= envid2env(envid,&env_store, 1))<0)
f010539b:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01053a2:	00 
f01053a3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01053a6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01053aa:	8b 45 0c             	mov    0xc(%ebp),%eax
f01053ad:	89 04 24             	mov    %eax,(%esp)
f01053b0:	e8 fe e1 ff ff       	call   f01035b3 <envid2env>
f01053b5:	85 c0                	test   %eax,%eax
f01053b7:	0f 88 c6 00 00 00    	js     f0105483 <syscall+0x4db>
	return check;

	env_store->env_status= status;
f01053bd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01053c0:	8b 7d 10             	mov    0x10(%ebp),%edi
f01053c3:	89 78 54             	mov    %edi,0x54(%eax)
	return 0;
f01053c6:	b8 00 00 00 00       	mov    $0x0,%eax
f01053cb:	e9 b3 00 00 00       	jmp    f0105483 <syscall+0x4db>

	// LAB 4: Your code here.
	struct Env *env_store;
	int check;	
	if(!(status == ENV_RUNNABLE || status == ENV_NOT_RUNNABLE))
		return -E_INVAL;
f01053d0:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01053d5:	e9 a9 00 00 00       	jmp    f0105483 <syscall+0x4db>
sys_env_set_pgfault_upcall(envid_t envid, void *func)
{
	// LAB 4: Your code here.
	struct Env *env;
	int check;
	if((check= envid2env(envid,&env, 1))<0)
f01053da:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01053e1:	00 
f01053e2:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01053e5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01053e9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01053ec:	89 04 24             	mov    %eax,(%esp)
f01053ef:	e8 bf e1 ff ff       	call   f01035b3 <envid2env>
f01053f4:	85 c0                	test   %eax,%eax
f01053f6:	0f 88 87 00 00 00    	js     f0105483 <syscall+0x4db>
	return check;
	
	
	env->env_pgfault_upcall=func;
f01053fc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01053ff:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0105402:	89 48 60             	mov    %ecx,0x60(%eax)
	return 0;
f0105405:	b8 00 00 00 00       	mov    $0x0,%eax
f010540a:	eb 77                	jmp    f0105483 <syscall+0x4db>
//	-E_INVAL if dstva < UTOP but dstva is not page-aligned.
static int
sys_ipc_recv(void *dstva)
{
	
	if(dstva>(void *)UTOP || dstva==NULL || ((uintptr_t) dstva % PGSIZE!=0 ) )
f010540c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010540f:	8d 50 ff             	lea    -0x1(%eax),%edx
f0105412:	81 fa ff ff bf ee    	cmp    $0xeebfffff,%edx
f0105418:	77 56                	ja     f0105470 <syscall+0x4c8>
f010541a:	a9 ff 0f 00 00       	test   $0xfff,%eax
f010541f:	75 56                	jne    f0105477 <syscall+0x4cf>
		curenv->env_status=4;
	}	
	

	//panic("sys_ipc_recv not implemented");
	return 0;
f0105421:	b8 00 00 00 00       	mov    $0x0,%eax

	}

	

	if(dstva<(void *)UTOP && dstva!=NULL)
f0105426:	81 fa fe ff bf ee    	cmp    $0xeebffffe,%edx
f010542c:	77 55                	ja     f0105483 <syscall+0x4db>
	{
		curenv->env_ipc_recving=1;
f010542e:	e8 16 12 00 00       	call   f0106649 <cpunum>
f0105433:	6b c0 74             	imul   $0x74,%eax,%eax
f0105436:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f010543c:	c6 40 64 01          	movb   $0x1,0x64(%eax)
		curenv->env_ipc_dstva=dstva;
f0105440:	e8 04 12 00 00       	call   f0106649 <cpunum>
f0105445:	6b c0 74             	imul   $0x74,%eax,%eax
f0105448:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f010544e:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0105451:	89 78 68             	mov    %edi,0x68(%eax)
		curenv->env_status=4;
f0105454:	e8 f0 11 00 00       	call   f0106649 <cpunum>
f0105459:	6b c0 74             	imul   $0x74,%eax,%eax
f010545c:	8b 80 28 20 23 f0    	mov    -0xfdcdfd8(%eax),%eax
f0105462:	c7 40 54 04 00 00 00 	movl   $0x4,0x54(%eax)
	}	
	

	//panic("sys_ipc_recv not implemented");
	return 0;
f0105469:	b8 00 00 00 00       	mov    $0x0,%eax
f010546e:	eb 13                	jmp    f0105483 <syscall+0x4db>
sys_ipc_recv(void *dstva)
{
	
	if(dstva>(void *)UTOP || dstva==NULL || ((uintptr_t) dstva % PGSIZE!=0 ) )
	{
		return -E_INVAL;
f0105470:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0105475:	eb 0c                	jmp    f0105483 <syscall+0x4db>
f0105477:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
		case SYS_env_set_status:
			return sys_env_set_status(a1,a2);
		case SYS_env_set_pgfault_upcall:
			return sys_env_set_pgfault_upcall((envid_t)a1, (void *) a2);
		case SYS_ipc_recv:
			return sys_ipc_recv((void *) a1);
f010547c:	eb 05                	jmp    f0105483 <syscall+0x4db>

		
		default:
			return -E_INVAL;
f010547e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	 
	}
	return rval;
}
f0105483:	83 c4 2c             	add    $0x2c,%esp
f0105486:	5b                   	pop    %ebx
f0105487:	5e                   	pop    %esi
f0105488:	5f                   	pop    %edi
f0105489:	5d                   	pop    %ebp
f010548a:	c3                   	ret    

f010548b <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010548b:	55                   	push   %ebp
f010548c:	89 e5                	mov    %esp,%ebp
f010548e:	57                   	push   %edi
f010548f:	56                   	push   %esi
f0105490:	53                   	push   %ebx
f0105491:	83 ec 14             	sub    $0x14,%esp
f0105494:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0105497:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010549a:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010549d:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f01054a0:	8b 1a                	mov    (%edx),%ebx
f01054a2:	8b 01                	mov    (%ecx),%eax
f01054a4:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01054a7:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01054ae:	e9 88 00 00 00       	jmp    f010553b <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f01054b3:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01054b6:	01 d8                	add    %ebx,%eax
f01054b8:	89 c7                	mov    %eax,%edi
f01054ba:	c1 ef 1f             	shr    $0x1f,%edi
f01054bd:	01 c7                	add    %eax,%edi
f01054bf:	d1 ff                	sar    %edi
f01054c1:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f01054c4:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01054c7:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01054ca:	89 f8                	mov    %edi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01054cc:	eb 03                	jmp    f01054d1 <stab_binsearch+0x46>
			m--;
f01054ce:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01054d1:	39 c3                	cmp    %eax,%ebx
f01054d3:	7f 1f                	jg     f01054f4 <stab_binsearch+0x69>
f01054d5:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01054d9:	83 ea 0c             	sub    $0xc,%edx
f01054dc:	39 f1                	cmp    %esi,%ecx
f01054de:	75 ee                	jne    f01054ce <stab_binsearch+0x43>
f01054e0:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01054e3:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01054e6:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01054e9:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01054ed:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01054f0:	76 18                	jbe    f010550a <stab_binsearch+0x7f>
f01054f2:	eb 05                	jmp    f01054f9 <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01054f4:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f01054f7:	eb 42                	jmp    f010553b <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f01054f9:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01054fc:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01054fe:	8d 5f 01             	lea    0x1(%edi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0105501:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0105508:	eb 31                	jmp    f010553b <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010550a:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010550d:	73 17                	jae    f0105526 <stab_binsearch+0x9b>
			*region_right = m - 1;
f010550f:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0105512:	83 e8 01             	sub    $0x1,%eax
f0105515:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0105518:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010551b:	89 07                	mov    %eax,(%edi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010551d:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0105524:	eb 15                	jmp    f010553b <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0105526:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0105529:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f010552c:	89 1f                	mov    %ebx,(%edi)
			l = m;
			addr++;
f010552e:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0105532:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0105534:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010553b:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f010553e:	0f 8e 6f ff ff ff    	jle    f01054b3 <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0105544:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0105548:	75 0f                	jne    f0105559 <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f010554a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010554d:	8b 00                	mov    (%eax),%eax
f010554f:	83 e8 01             	sub    $0x1,%eax
f0105552:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0105555:	89 07                	mov    %eax,(%edi)
f0105557:	eb 2c                	jmp    f0105585 <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0105559:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010555c:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f010555e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0105561:	8b 0f                	mov    (%edi),%ecx
f0105563:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0105566:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0105569:	8d 14 97             	lea    (%edi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010556c:	eb 03                	jmp    f0105571 <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010556e:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0105571:	39 c8                	cmp    %ecx,%eax
f0105573:	7e 0b                	jle    f0105580 <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f0105575:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0105579:	83 ea 0c             	sub    $0xc,%edx
f010557c:	39 f3                	cmp    %esi,%ebx
f010557e:	75 ee                	jne    f010556e <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f0105580:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0105583:	89 07                	mov    %eax,(%edi)
	}
}
f0105585:	83 c4 14             	add    $0x14,%esp
f0105588:	5b                   	pop    %ebx
f0105589:	5e                   	pop    %esi
f010558a:	5f                   	pop    %edi
f010558b:	5d                   	pop    %ebp
f010558c:	c3                   	ret    

f010558d <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010558d:	55                   	push   %ebp
f010558e:	89 e5                	mov    %esp,%ebp
f0105590:	57                   	push   %edi
f0105591:	56                   	push   %esi
f0105592:	53                   	push   %ebx
f0105593:	83 ec 4c             	sub    $0x4c,%esp
f0105596:	8b 75 08             	mov    0x8(%ebp),%esi
f0105599:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010559c:	c7 03 8c 84 10 f0    	movl   $0xf010848c,(%ebx)
	info->eip_line = 0;
f01055a2:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01055a9:	c7 43 08 8c 84 10 f0 	movl   $0xf010848c,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01055b0:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01055b7:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01055ba:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01055c1:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01055c7:	77 21                	ja     f01055ea <debuginfo_eip+0x5d>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f01055c9:	a1 00 00 20 00       	mov    0x200000,%eax
f01055ce:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		stab_end = usd->stab_end;
f01055d1:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f01055d6:	8b 3d 08 00 20 00    	mov    0x200008,%edi
f01055dc:	89 7d c0             	mov    %edi,-0x40(%ebp)
		stabstr_end = usd->stabstr_end;
f01055df:	8b 3d 0c 00 20 00    	mov    0x20000c,%edi
f01055e5:	89 7d bc             	mov    %edi,-0x44(%ebp)
f01055e8:	eb 1a                	jmp    f0105604 <debuginfo_eip+0x77>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f01055ea:	c7 45 bc aa 63 11 f0 	movl   $0xf01163aa,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f01055f1:	c7 45 c0 c5 2c 11 f0 	movl   $0xf0112cc5,-0x40(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f01055f8:	b8 c4 2c 11 f0       	mov    $0xf0112cc4,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f01055fd:	c7 45 c4 74 89 10 f0 	movl   $0xf0108974,-0x3c(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0105604:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0105607:	39 7d c0             	cmp    %edi,-0x40(%ebp)
f010560a:	0f 83 95 01 00 00    	jae    f01057a5 <debuginfo_eip+0x218>
f0105610:	80 7f ff 00          	cmpb   $0x0,-0x1(%edi)
f0105614:	0f 85 92 01 00 00    	jne    f01057ac <debuginfo_eip+0x21f>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010561a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0105621:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0105624:	29 f8                	sub    %edi,%eax
f0105626:	c1 f8 02             	sar    $0x2,%eax
f0105629:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f010562f:	83 e8 01             	sub    $0x1,%eax
f0105632:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0105635:	89 74 24 04          	mov    %esi,0x4(%esp)
f0105639:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0105640:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0105643:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0105646:	89 f8                	mov    %edi,%eax
f0105648:	e8 3e fe ff ff       	call   f010548b <stab_binsearch>
	if (lfile == 0)
f010564d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105650:	85 c0                	test   %eax,%eax
f0105652:	0f 84 5b 01 00 00    	je     f01057b3 <debuginfo_eip+0x226>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0105658:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f010565b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010565e:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0105661:	89 74 24 04          	mov    %esi,0x4(%esp)
f0105665:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f010566c:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f010566f:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0105672:	89 f8                	mov    %edi,%eax
f0105674:	e8 12 fe ff ff       	call   f010548b <stab_binsearch>

	if (lfun <= rfun) {
f0105679:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010567c:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f010567f:	39 c8                	cmp    %ecx,%eax
f0105681:	7f 32                	jg     f01056b5 <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0105683:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0105686:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0105689:	8d 3c 97             	lea    (%edi,%edx,4),%edi
f010568c:	8b 17                	mov    (%edi),%edx
f010568e:	89 55 b8             	mov    %edx,-0x48(%ebp)
f0105691:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0105694:	2b 55 c0             	sub    -0x40(%ebp),%edx
f0105697:	39 55 b8             	cmp    %edx,-0x48(%ebp)
f010569a:	73 09                	jae    f01056a5 <debuginfo_eip+0x118>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010569c:	8b 55 b8             	mov    -0x48(%ebp),%edx
f010569f:	03 55 c0             	add    -0x40(%ebp),%edx
f01056a2:	89 53 08             	mov    %edx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f01056a5:	8b 57 08             	mov    0x8(%edi),%edx
f01056a8:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01056ab:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f01056ad:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01056b0:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f01056b3:	eb 0f                	jmp    f01056c4 <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01056b5:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f01056b8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01056bb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01056be:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01056c1:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01056c4:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f01056cb:	00 
f01056cc:	8b 43 08             	mov    0x8(%ebx),%eax
f01056cf:	89 04 24             	mov    %eax,(%esp)
f01056d2:	e8 04 09 00 00       	call   f0105fdb <strfind>
f01056d7:	2b 43 08             	sub    0x8(%ebx),%eax
f01056da:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

          stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); 
f01056dd:	89 74 24 04          	mov    %esi,0x4(%esp)
f01056e1:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f01056e8:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01056eb:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01056ee:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f01056f1:	89 f8                	mov    %edi,%eax
f01056f3:	e8 93 fd ff ff       	call   f010548b <stab_binsearch>
          info->eip_line = stabs[lline].n_desc;
f01056f8:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01056fb:	8d 0c 12             	lea    (%edx,%edx,1),%ecx
f01056fe:	8d 04 11             	lea    (%ecx,%edx,1),%eax
f0105701:	0f b7 44 87 06       	movzwl 0x6(%edi,%eax,4),%eax
f0105706:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0105709:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010570c:	89 c6                	mov    %eax,%esi
f010570e:	89 d0                	mov    %edx,%eax
f0105710:	01 ca                	add    %ecx,%edx
f0105712:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0105715:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0105718:	eb 06                	jmp    f0105720 <debuginfo_eip+0x193>
f010571a:	83 e8 01             	sub    $0x1,%eax
f010571d:	83 ea 0c             	sub    $0xc,%edx
f0105720:	89 c7                	mov    %eax,%edi
f0105722:	39 c6                	cmp    %eax,%esi
f0105724:	7f 3c                	jg     f0105762 <debuginfo_eip+0x1d5>
	       && stabs[lline].n_type != N_SOL
f0105726:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010572a:	80 f9 84             	cmp    $0x84,%cl
f010572d:	75 08                	jne    f0105737 <debuginfo_eip+0x1aa>
f010572f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0105732:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0105735:	eb 11                	jmp    f0105748 <debuginfo_eip+0x1bb>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0105737:	80 f9 64             	cmp    $0x64,%cl
f010573a:	75 de                	jne    f010571a <debuginfo_eip+0x18d>
f010573c:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0105740:	74 d8                	je     f010571a <debuginfo_eip+0x18d>
f0105742:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0105745:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0105748:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f010574b:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f010574e:	8b 04 86             	mov    (%esi,%eax,4),%eax
f0105751:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0105754:	2b 55 c0             	sub    -0x40(%ebp),%edx
f0105757:	39 d0                	cmp    %edx,%eax
f0105759:	73 0a                	jae    f0105765 <debuginfo_eip+0x1d8>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010575b:	03 45 c0             	add    -0x40(%ebp),%eax
f010575e:	89 03                	mov    %eax,(%ebx)
f0105760:	eb 03                	jmp    f0105765 <debuginfo_eip+0x1d8>
f0105762:	8b 5d 0c             	mov    0xc(%ebp),%ebx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0105765:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0105768:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010576b:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0105770:	39 f2                	cmp    %esi,%edx
f0105772:	7d 4b                	jge    f01057bf <debuginfo_eip+0x232>
		for (lline = lfun + 1;
f0105774:	83 c2 01             	add    $0x1,%edx
f0105777:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f010577a:	89 d0                	mov    %edx,%eax
f010577c:	8d 14 52             	lea    (%edx,%edx,2),%edx
f010577f:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0105782:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0105785:	eb 04                	jmp    f010578b <debuginfo_eip+0x1fe>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0105787:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f010578b:	39 c6                	cmp    %eax,%esi
f010578d:	7e 2b                	jle    f01057ba <debuginfo_eip+0x22d>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010578f:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0105793:	83 c0 01             	add    $0x1,%eax
f0105796:	83 c2 0c             	add    $0xc,%edx
f0105799:	80 f9 a0             	cmp    $0xa0,%cl
f010579c:	74 e9                	je     f0105787 <debuginfo_eip+0x1fa>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010579e:	b8 00 00 00 00       	mov    $0x0,%eax
f01057a3:	eb 1a                	jmp    f01057bf <debuginfo_eip+0x232>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01057a5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01057aa:	eb 13                	jmp    f01057bf <debuginfo_eip+0x232>
f01057ac:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01057b1:	eb 0c                	jmp    f01057bf <debuginfo_eip+0x232>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01057b3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01057b8:	eb 05                	jmp    f01057bf <debuginfo_eip+0x232>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01057ba:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01057bf:	83 c4 4c             	add    $0x4c,%esp
f01057c2:	5b                   	pop    %ebx
f01057c3:	5e                   	pop    %esi
f01057c4:	5f                   	pop    %edi
f01057c5:	5d                   	pop    %ebp
f01057c6:	c3                   	ret    
f01057c7:	66 90                	xchg   %ax,%ax
f01057c9:	66 90                	xchg   %ax,%ax
f01057cb:	66 90                	xchg   %ax,%ax
f01057cd:	66 90                	xchg   %ax,%ax
f01057cf:	90                   	nop

f01057d0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01057d0:	55                   	push   %ebp
f01057d1:	89 e5                	mov    %esp,%ebp
f01057d3:	57                   	push   %edi
f01057d4:	56                   	push   %esi
f01057d5:	53                   	push   %ebx
f01057d6:	83 ec 3c             	sub    $0x3c,%esp
f01057d9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01057dc:	89 d7                	mov    %edx,%edi
f01057de:	8b 45 08             	mov    0x8(%ebp),%eax
f01057e1:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01057e4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01057e7:	89 c3                	mov    %eax,%ebx
f01057e9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01057ec:	8b 45 10             	mov    0x10(%ebp),%eax
f01057ef:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01057f2:	b9 00 00 00 00       	mov    $0x0,%ecx
f01057f7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01057fa:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01057fd:	39 d9                	cmp    %ebx,%ecx
f01057ff:	72 05                	jb     f0105806 <printnum+0x36>
f0105801:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0105804:	77 69                	ja     f010586f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0105806:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0105809:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f010580d:	83 ee 01             	sub    $0x1,%esi
f0105810:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0105814:	89 44 24 08          	mov    %eax,0x8(%esp)
f0105818:	8b 44 24 08          	mov    0x8(%esp),%eax
f010581c:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0105820:	89 c3                	mov    %eax,%ebx
f0105822:	89 d6                	mov    %edx,%esi
f0105824:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0105827:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010582a:	89 54 24 08          	mov    %edx,0x8(%esp)
f010582e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0105832:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105835:	89 04 24             	mov    %eax,(%esp)
f0105838:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010583b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010583f:	e8 4c 12 00 00       	call   f0106a90 <__udivdi3>
f0105844:	89 d9                	mov    %ebx,%ecx
f0105846:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010584a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010584e:	89 04 24             	mov    %eax,(%esp)
f0105851:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105855:	89 fa                	mov    %edi,%edx
f0105857:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010585a:	e8 71 ff ff ff       	call   f01057d0 <printnum>
f010585f:	eb 1b                	jmp    f010587c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0105861:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105865:	8b 45 18             	mov    0x18(%ebp),%eax
f0105868:	89 04 24             	mov    %eax,(%esp)
f010586b:	ff d3                	call   *%ebx
f010586d:	eb 03                	jmp    f0105872 <printnum+0xa2>
f010586f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0105872:	83 ee 01             	sub    $0x1,%esi
f0105875:	85 f6                	test   %esi,%esi
f0105877:	7f e8                	jg     f0105861 <printnum+0x91>
f0105879:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010587c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105880:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0105884:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0105887:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010588a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010588e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0105892:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105895:	89 04 24             	mov    %eax,(%esp)
f0105898:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010589b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010589f:	e8 1c 13 00 00       	call   f0106bc0 <__umoddi3>
f01058a4:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01058a8:	0f be 80 96 84 10 f0 	movsbl -0xfef7b6a(%eax),%eax
f01058af:	89 04 24             	mov    %eax,(%esp)
f01058b2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01058b5:	ff d0                	call   *%eax
}
f01058b7:	83 c4 3c             	add    $0x3c,%esp
f01058ba:	5b                   	pop    %ebx
f01058bb:	5e                   	pop    %esi
f01058bc:	5f                   	pop    %edi
f01058bd:	5d                   	pop    %ebp
f01058be:	c3                   	ret    

f01058bf <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01058bf:	55                   	push   %ebp
f01058c0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01058c2:	83 fa 01             	cmp    $0x1,%edx
f01058c5:	7e 0e                	jle    f01058d5 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01058c7:	8b 10                	mov    (%eax),%edx
f01058c9:	8d 4a 08             	lea    0x8(%edx),%ecx
f01058cc:	89 08                	mov    %ecx,(%eax)
f01058ce:	8b 02                	mov    (%edx),%eax
f01058d0:	8b 52 04             	mov    0x4(%edx),%edx
f01058d3:	eb 22                	jmp    f01058f7 <getuint+0x38>
	else if (lflag)
f01058d5:	85 d2                	test   %edx,%edx
f01058d7:	74 10                	je     f01058e9 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01058d9:	8b 10                	mov    (%eax),%edx
f01058db:	8d 4a 04             	lea    0x4(%edx),%ecx
f01058de:	89 08                	mov    %ecx,(%eax)
f01058e0:	8b 02                	mov    (%edx),%eax
f01058e2:	ba 00 00 00 00       	mov    $0x0,%edx
f01058e7:	eb 0e                	jmp    f01058f7 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01058e9:	8b 10                	mov    (%eax),%edx
f01058eb:	8d 4a 04             	lea    0x4(%edx),%ecx
f01058ee:	89 08                	mov    %ecx,(%eax)
f01058f0:	8b 02                	mov    (%edx),%eax
f01058f2:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01058f7:	5d                   	pop    %ebp
f01058f8:	c3                   	ret    

f01058f9 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01058f9:	55                   	push   %ebp
f01058fa:	89 e5                	mov    %esp,%ebp
f01058fc:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01058ff:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0105903:	8b 10                	mov    (%eax),%edx
f0105905:	3b 50 04             	cmp    0x4(%eax),%edx
f0105908:	73 0a                	jae    f0105914 <sprintputch+0x1b>
		*b->buf++ = ch;
f010590a:	8d 4a 01             	lea    0x1(%edx),%ecx
f010590d:	89 08                	mov    %ecx,(%eax)
f010590f:	8b 45 08             	mov    0x8(%ebp),%eax
f0105912:	88 02                	mov    %al,(%edx)
}
f0105914:	5d                   	pop    %ebp
f0105915:	c3                   	ret    

f0105916 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0105916:	55                   	push   %ebp
f0105917:	89 e5                	mov    %esp,%ebp
f0105919:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f010591c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010591f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105923:	8b 45 10             	mov    0x10(%ebp),%eax
f0105926:	89 44 24 08          	mov    %eax,0x8(%esp)
f010592a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010592d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105931:	8b 45 08             	mov    0x8(%ebp),%eax
f0105934:	89 04 24             	mov    %eax,(%esp)
f0105937:	e8 02 00 00 00       	call   f010593e <vprintfmt>
	va_end(ap);
}
f010593c:	c9                   	leave  
f010593d:	c3                   	ret    

f010593e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010593e:	55                   	push   %ebp
f010593f:	89 e5                	mov    %esp,%ebp
f0105941:	57                   	push   %edi
f0105942:	56                   	push   %esi
f0105943:	53                   	push   %ebx
f0105944:	83 ec 3c             	sub    $0x3c,%esp
f0105947:	8b 7d 0c             	mov    0xc(%ebp),%edi
f010594a:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010594d:	eb 14                	jmp    f0105963 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010594f:	85 c0                	test   %eax,%eax
f0105951:	0f 84 b3 03 00 00    	je     f0105d0a <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f0105957:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010595b:	89 04 24             	mov    %eax,(%esp)
f010595e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0105961:	89 f3                	mov    %esi,%ebx
f0105963:	8d 73 01             	lea    0x1(%ebx),%esi
f0105966:	0f b6 03             	movzbl (%ebx),%eax
f0105969:	83 f8 25             	cmp    $0x25,%eax
f010596c:	75 e1                	jne    f010594f <vprintfmt+0x11>
f010596e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0105972:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0105979:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0105980:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0105987:	ba 00 00 00 00       	mov    $0x0,%edx
f010598c:	eb 1d                	jmp    f01059ab <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010598e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0105990:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0105994:	eb 15                	jmp    f01059ab <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105996:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0105998:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f010599c:	eb 0d                	jmp    f01059ab <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f010599e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01059a1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01059a4:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01059ab:	8d 5e 01             	lea    0x1(%esi),%ebx
f01059ae:	0f b6 0e             	movzbl (%esi),%ecx
f01059b1:	0f b6 c1             	movzbl %cl,%eax
f01059b4:	83 e9 23             	sub    $0x23,%ecx
f01059b7:	80 f9 55             	cmp    $0x55,%cl
f01059ba:	0f 87 2a 03 00 00    	ja     f0105cea <vprintfmt+0x3ac>
f01059c0:	0f b6 c9             	movzbl %cl,%ecx
f01059c3:	ff 24 8d 60 85 10 f0 	jmp    *-0xfef7aa0(,%ecx,4)
f01059ca:	89 de                	mov    %ebx,%esi
f01059cc:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01059d1:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f01059d4:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f01059d8:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f01059db:	8d 58 d0             	lea    -0x30(%eax),%ebx
f01059de:	83 fb 09             	cmp    $0x9,%ebx
f01059e1:	77 36                	ja     f0105a19 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01059e3:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f01059e6:	eb e9                	jmp    f01059d1 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01059e8:	8b 45 14             	mov    0x14(%ebp),%eax
f01059eb:	8d 48 04             	lea    0x4(%eax),%ecx
f01059ee:	89 4d 14             	mov    %ecx,0x14(%ebp)
f01059f1:	8b 00                	mov    (%eax),%eax
f01059f3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01059f6:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01059f8:	eb 22                	jmp    f0105a1c <vprintfmt+0xde>
f01059fa:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01059fd:	85 c9                	test   %ecx,%ecx
f01059ff:	b8 00 00 00 00       	mov    $0x0,%eax
f0105a04:	0f 49 c1             	cmovns %ecx,%eax
f0105a07:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105a0a:	89 de                	mov    %ebx,%esi
f0105a0c:	eb 9d                	jmp    f01059ab <vprintfmt+0x6d>
f0105a0e:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0105a10:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0105a17:	eb 92                	jmp    f01059ab <vprintfmt+0x6d>
f0105a19:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f0105a1c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0105a20:	79 89                	jns    f01059ab <vprintfmt+0x6d>
f0105a22:	e9 77 ff ff ff       	jmp    f010599e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0105a27:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105a2a:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0105a2c:	e9 7a ff ff ff       	jmp    f01059ab <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0105a31:	8b 45 14             	mov    0x14(%ebp),%eax
f0105a34:	8d 50 04             	lea    0x4(%eax),%edx
f0105a37:	89 55 14             	mov    %edx,0x14(%ebp)
f0105a3a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105a3e:	8b 00                	mov    (%eax),%eax
f0105a40:	89 04 24             	mov    %eax,(%esp)
f0105a43:	ff 55 08             	call   *0x8(%ebp)
			break;
f0105a46:	e9 18 ff ff ff       	jmp    f0105963 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0105a4b:	8b 45 14             	mov    0x14(%ebp),%eax
f0105a4e:	8d 50 04             	lea    0x4(%eax),%edx
f0105a51:	89 55 14             	mov    %edx,0x14(%ebp)
f0105a54:	8b 00                	mov    (%eax),%eax
f0105a56:	99                   	cltd   
f0105a57:	31 d0                	xor    %edx,%eax
f0105a59:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0105a5b:	83 f8 08             	cmp    $0x8,%eax
f0105a5e:	7f 0b                	jg     f0105a6b <vprintfmt+0x12d>
f0105a60:	8b 14 85 c0 86 10 f0 	mov    -0xfef7940(,%eax,4),%edx
f0105a67:	85 d2                	test   %edx,%edx
f0105a69:	75 20                	jne    f0105a8b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f0105a6b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105a6f:	c7 44 24 08 ae 84 10 	movl   $0xf01084ae,0x8(%esp)
f0105a76:	f0 
f0105a77:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105a7b:	8b 45 08             	mov    0x8(%ebp),%eax
f0105a7e:	89 04 24             	mov    %eax,(%esp)
f0105a81:	e8 90 fe ff ff       	call   f0105916 <printfmt>
f0105a86:	e9 d8 fe ff ff       	jmp    f0105963 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f0105a8b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0105a8f:	c7 44 24 08 0c 73 10 	movl   $0xf010730c,0x8(%esp)
f0105a96:	f0 
f0105a97:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105a9b:	8b 45 08             	mov    0x8(%ebp),%eax
f0105a9e:	89 04 24             	mov    %eax,(%esp)
f0105aa1:	e8 70 fe ff ff       	call   f0105916 <printfmt>
f0105aa6:	e9 b8 fe ff ff       	jmp    f0105963 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105aab:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0105aae:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0105ab1:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0105ab4:	8b 45 14             	mov    0x14(%ebp),%eax
f0105ab7:	8d 50 04             	lea    0x4(%eax),%edx
f0105aba:	89 55 14             	mov    %edx,0x14(%ebp)
f0105abd:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f0105abf:	85 f6                	test   %esi,%esi
f0105ac1:	b8 a7 84 10 f0       	mov    $0xf01084a7,%eax
f0105ac6:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0105ac9:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f0105acd:	0f 84 97 00 00 00    	je     f0105b6a <vprintfmt+0x22c>
f0105ad3:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0105ad7:	0f 8e 9b 00 00 00    	jle    f0105b78 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f0105add:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0105ae1:	89 34 24             	mov    %esi,(%esp)
f0105ae4:	e8 9f 03 00 00       	call   f0105e88 <strnlen>
f0105ae9:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0105aec:	29 c2                	sub    %eax,%edx
f0105aee:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0105af1:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0105af5:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0105af8:	89 75 d8             	mov    %esi,-0x28(%ebp)
f0105afb:	8b 75 08             	mov    0x8(%ebp),%esi
f0105afe:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0105b01:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0105b03:	eb 0f                	jmp    f0105b14 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0105b05:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105b09:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0105b0c:	89 04 24             	mov    %eax,(%esp)
f0105b0f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0105b11:	83 eb 01             	sub    $0x1,%ebx
f0105b14:	85 db                	test   %ebx,%ebx
f0105b16:	7f ed                	jg     f0105b05 <vprintfmt+0x1c7>
f0105b18:	8b 75 d8             	mov    -0x28(%ebp),%esi
f0105b1b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0105b1e:	85 d2                	test   %edx,%edx
f0105b20:	b8 00 00 00 00       	mov    $0x0,%eax
f0105b25:	0f 49 c2             	cmovns %edx,%eax
f0105b28:	29 c2                	sub    %eax,%edx
f0105b2a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0105b2d:	89 d7                	mov    %edx,%edi
f0105b2f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0105b32:	eb 50                	jmp    f0105b84 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0105b34:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0105b38:	74 1e                	je     f0105b58 <vprintfmt+0x21a>
f0105b3a:	0f be d2             	movsbl %dl,%edx
f0105b3d:	83 ea 20             	sub    $0x20,%edx
f0105b40:	83 fa 5e             	cmp    $0x5e,%edx
f0105b43:	76 13                	jbe    f0105b58 <vprintfmt+0x21a>
					putch('?', putdat);
f0105b45:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105b48:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105b4c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0105b53:	ff 55 08             	call   *0x8(%ebp)
f0105b56:	eb 0d                	jmp    f0105b65 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f0105b58:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105b5b:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105b5f:	89 04 24             	mov    %eax,(%esp)
f0105b62:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0105b65:	83 ef 01             	sub    $0x1,%edi
f0105b68:	eb 1a                	jmp    f0105b84 <vprintfmt+0x246>
f0105b6a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0105b6d:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0105b70:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0105b73:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0105b76:	eb 0c                	jmp    f0105b84 <vprintfmt+0x246>
f0105b78:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0105b7b:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0105b7e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0105b81:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0105b84:	83 c6 01             	add    $0x1,%esi
f0105b87:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f0105b8b:	0f be c2             	movsbl %dl,%eax
f0105b8e:	85 c0                	test   %eax,%eax
f0105b90:	74 27                	je     f0105bb9 <vprintfmt+0x27b>
f0105b92:	85 db                	test   %ebx,%ebx
f0105b94:	78 9e                	js     f0105b34 <vprintfmt+0x1f6>
f0105b96:	83 eb 01             	sub    $0x1,%ebx
f0105b99:	79 99                	jns    f0105b34 <vprintfmt+0x1f6>
f0105b9b:	89 f8                	mov    %edi,%eax
f0105b9d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0105ba0:	8b 75 08             	mov    0x8(%ebp),%esi
f0105ba3:	89 c3                	mov    %eax,%ebx
f0105ba5:	eb 1a                	jmp    f0105bc1 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0105ba7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105bab:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0105bb2:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0105bb4:	83 eb 01             	sub    $0x1,%ebx
f0105bb7:	eb 08                	jmp    f0105bc1 <vprintfmt+0x283>
f0105bb9:	89 fb                	mov    %edi,%ebx
f0105bbb:	8b 75 08             	mov    0x8(%ebp),%esi
f0105bbe:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0105bc1:	85 db                	test   %ebx,%ebx
f0105bc3:	7f e2                	jg     f0105ba7 <vprintfmt+0x269>
f0105bc5:	89 75 08             	mov    %esi,0x8(%ebp)
f0105bc8:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0105bcb:	e9 93 fd ff ff       	jmp    f0105963 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0105bd0:	83 fa 01             	cmp    $0x1,%edx
f0105bd3:	7e 16                	jle    f0105beb <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f0105bd5:	8b 45 14             	mov    0x14(%ebp),%eax
f0105bd8:	8d 50 08             	lea    0x8(%eax),%edx
f0105bdb:	89 55 14             	mov    %edx,0x14(%ebp)
f0105bde:	8b 50 04             	mov    0x4(%eax),%edx
f0105be1:	8b 00                	mov    (%eax),%eax
f0105be3:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0105be6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0105be9:	eb 32                	jmp    f0105c1d <vprintfmt+0x2df>
	else if (lflag)
f0105beb:	85 d2                	test   %edx,%edx
f0105bed:	74 18                	je     f0105c07 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f0105bef:	8b 45 14             	mov    0x14(%ebp),%eax
f0105bf2:	8d 50 04             	lea    0x4(%eax),%edx
f0105bf5:	89 55 14             	mov    %edx,0x14(%ebp)
f0105bf8:	8b 30                	mov    (%eax),%esi
f0105bfa:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0105bfd:	89 f0                	mov    %esi,%eax
f0105bff:	c1 f8 1f             	sar    $0x1f,%eax
f0105c02:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105c05:	eb 16                	jmp    f0105c1d <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f0105c07:	8b 45 14             	mov    0x14(%ebp),%eax
f0105c0a:	8d 50 04             	lea    0x4(%eax),%edx
f0105c0d:	89 55 14             	mov    %edx,0x14(%ebp)
f0105c10:	8b 30                	mov    (%eax),%esi
f0105c12:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0105c15:	89 f0                	mov    %esi,%eax
f0105c17:	c1 f8 1f             	sar    $0x1f,%eax
f0105c1a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0105c1d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105c20:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0105c23:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0105c28:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0105c2c:	0f 89 80 00 00 00    	jns    f0105cb2 <vprintfmt+0x374>
				putch('-', putdat);
f0105c32:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105c36:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0105c3d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0105c40:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105c43:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0105c46:	f7 d8                	neg    %eax
f0105c48:	83 d2 00             	adc    $0x0,%edx
f0105c4b:	f7 da                	neg    %edx
			}
			base = 10;
f0105c4d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0105c52:	eb 5e                	jmp    f0105cb2 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0105c54:	8d 45 14             	lea    0x14(%ebp),%eax
f0105c57:	e8 63 fc ff ff       	call   f01058bf <getuint>
			base = 10;
f0105c5c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0105c61:	eb 4f                	jmp    f0105cb2 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0105c63:	8d 45 14             	lea    0x14(%ebp),%eax
f0105c66:	e8 54 fc ff ff       	call   f01058bf <getuint>
			base = 8;
f0105c6b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0105c70:	eb 40                	jmp    f0105cb2 <vprintfmt+0x374>

		// pointer
		case 'p':
			putch('0', putdat);
f0105c72:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105c76:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0105c7d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0105c80:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105c84:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0105c8b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0105c8e:	8b 45 14             	mov    0x14(%ebp),%eax
f0105c91:	8d 50 04             	lea    0x4(%eax),%edx
f0105c94:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0105c97:	8b 00                	mov    (%eax),%eax
f0105c99:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0105c9e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0105ca3:	eb 0d                	jmp    f0105cb2 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0105ca5:	8d 45 14             	lea    0x14(%ebp),%eax
f0105ca8:	e8 12 fc ff ff       	call   f01058bf <getuint>
			base = 16;
f0105cad:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0105cb2:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f0105cb6:	89 74 24 10          	mov    %esi,0x10(%esp)
f0105cba:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0105cbd:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0105cc1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105cc5:	89 04 24             	mov    %eax,(%esp)
f0105cc8:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105ccc:	89 fa                	mov    %edi,%edx
f0105cce:	8b 45 08             	mov    0x8(%ebp),%eax
f0105cd1:	e8 fa fa ff ff       	call   f01057d0 <printnum>
			break;
f0105cd6:	e9 88 fc ff ff       	jmp    f0105963 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0105cdb:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105cdf:	89 04 24             	mov    %eax,(%esp)
f0105ce2:	ff 55 08             	call   *0x8(%ebp)
			break;
f0105ce5:	e9 79 fc ff ff       	jmp    f0105963 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0105cea:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105cee:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0105cf5:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0105cf8:	89 f3                	mov    %esi,%ebx
f0105cfa:	eb 03                	jmp    f0105cff <vprintfmt+0x3c1>
f0105cfc:	83 eb 01             	sub    $0x1,%ebx
f0105cff:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0105d03:	75 f7                	jne    f0105cfc <vprintfmt+0x3be>
f0105d05:	e9 59 fc ff ff       	jmp    f0105963 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f0105d0a:	83 c4 3c             	add    $0x3c,%esp
f0105d0d:	5b                   	pop    %ebx
f0105d0e:	5e                   	pop    %esi
f0105d0f:	5f                   	pop    %edi
f0105d10:	5d                   	pop    %ebp
f0105d11:	c3                   	ret    

f0105d12 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0105d12:	55                   	push   %ebp
f0105d13:	89 e5                	mov    %esp,%ebp
f0105d15:	83 ec 28             	sub    $0x28,%esp
f0105d18:	8b 45 08             	mov    0x8(%ebp),%eax
f0105d1b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0105d1e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0105d21:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0105d25:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0105d28:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0105d2f:	85 c0                	test   %eax,%eax
f0105d31:	74 30                	je     f0105d63 <vsnprintf+0x51>
f0105d33:	85 d2                	test   %edx,%edx
f0105d35:	7e 2c                	jle    f0105d63 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0105d37:	8b 45 14             	mov    0x14(%ebp),%eax
f0105d3a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105d3e:	8b 45 10             	mov    0x10(%ebp),%eax
f0105d41:	89 44 24 08          	mov    %eax,0x8(%esp)
f0105d45:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0105d48:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105d4c:	c7 04 24 f9 58 10 f0 	movl   $0xf01058f9,(%esp)
f0105d53:	e8 e6 fb ff ff       	call   f010593e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0105d58:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0105d5b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0105d5e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0105d61:	eb 05                	jmp    f0105d68 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0105d63:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0105d68:	c9                   	leave  
f0105d69:	c3                   	ret    

f0105d6a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0105d6a:	55                   	push   %ebp
f0105d6b:	89 e5                	mov    %esp,%ebp
f0105d6d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0105d70:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0105d73:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105d77:	8b 45 10             	mov    0x10(%ebp),%eax
f0105d7a:	89 44 24 08          	mov    %eax,0x8(%esp)
f0105d7e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105d81:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105d85:	8b 45 08             	mov    0x8(%ebp),%eax
f0105d88:	89 04 24             	mov    %eax,(%esp)
f0105d8b:	e8 82 ff ff ff       	call   f0105d12 <vsnprintf>
	va_end(ap);

	return rc;
}
f0105d90:	c9                   	leave  
f0105d91:	c3                   	ret    
f0105d92:	66 90                	xchg   %ax,%ax
f0105d94:	66 90                	xchg   %ax,%ax
f0105d96:	66 90                	xchg   %ax,%ax
f0105d98:	66 90                	xchg   %ax,%ax
f0105d9a:	66 90                	xchg   %ax,%ax
f0105d9c:	66 90                	xchg   %ax,%ax
f0105d9e:	66 90                	xchg   %ax,%ax

f0105da0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0105da0:	55                   	push   %ebp
f0105da1:	89 e5                	mov    %esp,%ebp
f0105da3:	57                   	push   %edi
f0105da4:	56                   	push   %esi
f0105da5:	53                   	push   %ebx
f0105da6:	83 ec 1c             	sub    $0x1c,%esp
f0105da9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0105dac:	85 c0                	test   %eax,%eax
f0105dae:	74 10                	je     f0105dc0 <readline+0x20>
		cprintf("%s", prompt);
f0105db0:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105db4:	c7 04 24 0c 73 10 f0 	movl   $0xf010730c,(%esp)
f0105dbb:	e8 69 e1 ff ff       	call   f0103f29 <cprintf>

	i = 0;
	echoing = iscons(0);
f0105dc0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0105dc7:	e8 df a9 ff ff       	call   f01007ab <iscons>
f0105dcc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0105dce:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0105dd3:	e8 c2 a9 ff ff       	call   f010079a <getchar>
f0105dd8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0105dda:	85 c0                	test   %eax,%eax
f0105ddc:	79 17                	jns    f0105df5 <readline+0x55>
			cprintf("read error: %e\n", c);
f0105dde:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105de2:	c7 04 24 e4 86 10 f0 	movl   $0xf01086e4,(%esp)
f0105de9:	e8 3b e1 ff ff       	call   f0103f29 <cprintf>
			return NULL;
f0105dee:	b8 00 00 00 00       	mov    $0x0,%eax
f0105df3:	eb 6d                	jmp    f0105e62 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0105df5:	83 f8 7f             	cmp    $0x7f,%eax
f0105df8:	74 05                	je     f0105dff <readline+0x5f>
f0105dfa:	83 f8 08             	cmp    $0x8,%eax
f0105dfd:	75 19                	jne    f0105e18 <readline+0x78>
f0105dff:	85 f6                	test   %esi,%esi
f0105e01:	7e 15                	jle    f0105e18 <readline+0x78>
			if (echoing)
f0105e03:	85 ff                	test   %edi,%edi
f0105e05:	74 0c                	je     f0105e13 <readline+0x73>
				cputchar('\b');
f0105e07:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f0105e0e:	e8 77 a9 ff ff       	call   f010078a <cputchar>
			i--;
f0105e13:	83 ee 01             	sub    $0x1,%esi
f0105e16:	eb bb                	jmp    f0105dd3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0105e18:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0105e1e:	7f 1c                	jg     f0105e3c <readline+0x9c>
f0105e20:	83 fb 1f             	cmp    $0x1f,%ebx
f0105e23:	7e 17                	jle    f0105e3c <readline+0x9c>
			if (echoing)
f0105e25:	85 ff                	test   %edi,%edi
f0105e27:	74 08                	je     f0105e31 <readline+0x91>
				cputchar(c);
f0105e29:	89 1c 24             	mov    %ebx,(%esp)
f0105e2c:	e8 59 a9 ff ff       	call   f010078a <cputchar>
			buf[i++] = c;
f0105e31:	88 9e 80 1a 23 f0    	mov    %bl,-0xfdce580(%esi)
f0105e37:	8d 76 01             	lea    0x1(%esi),%esi
f0105e3a:	eb 97                	jmp    f0105dd3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0105e3c:	83 fb 0d             	cmp    $0xd,%ebx
f0105e3f:	74 05                	je     f0105e46 <readline+0xa6>
f0105e41:	83 fb 0a             	cmp    $0xa,%ebx
f0105e44:	75 8d                	jne    f0105dd3 <readline+0x33>
			if (echoing)
f0105e46:	85 ff                	test   %edi,%edi
f0105e48:	74 0c                	je     f0105e56 <readline+0xb6>
				cputchar('\n');
f0105e4a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0105e51:	e8 34 a9 ff ff       	call   f010078a <cputchar>
			buf[i] = 0;
f0105e56:	c6 86 80 1a 23 f0 00 	movb   $0x0,-0xfdce580(%esi)
			return buf;
f0105e5d:	b8 80 1a 23 f0       	mov    $0xf0231a80,%eax
		}
	}
}
f0105e62:	83 c4 1c             	add    $0x1c,%esp
f0105e65:	5b                   	pop    %ebx
f0105e66:	5e                   	pop    %esi
f0105e67:	5f                   	pop    %edi
f0105e68:	5d                   	pop    %ebp
f0105e69:	c3                   	ret    
f0105e6a:	66 90                	xchg   %ax,%ax
f0105e6c:	66 90                	xchg   %ax,%ax
f0105e6e:	66 90                	xchg   %ax,%ax

f0105e70 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0105e70:	55                   	push   %ebp
f0105e71:	89 e5                	mov    %esp,%ebp
f0105e73:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0105e76:	b8 00 00 00 00       	mov    $0x0,%eax
f0105e7b:	eb 03                	jmp    f0105e80 <strlen+0x10>
		n++;
f0105e7d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0105e80:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0105e84:	75 f7                	jne    f0105e7d <strlen+0xd>
		n++;
	return n;
}
f0105e86:	5d                   	pop    %ebp
f0105e87:	c3                   	ret    

f0105e88 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0105e88:	55                   	push   %ebp
f0105e89:	89 e5                	mov    %esp,%ebp
f0105e8b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105e8e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0105e91:	b8 00 00 00 00       	mov    $0x0,%eax
f0105e96:	eb 03                	jmp    f0105e9b <strnlen+0x13>
		n++;
f0105e98:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0105e9b:	39 d0                	cmp    %edx,%eax
f0105e9d:	74 06                	je     f0105ea5 <strnlen+0x1d>
f0105e9f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0105ea3:	75 f3                	jne    f0105e98 <strnlen+0x10>
		n++;
	return n;
}
f0105ea5:	5d                   	pop    %ebp
f0105ea6:	c3                   	ret    

f0105ea7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0105ea7:	55                   	push   %ebp
f0105ea8:	89 e5                	mov    %esp,%ebp
f0105eaa:	53                   	push   %ebx
f0105eab:	8b 45 08             	mov    0x8(%ebp),%eax
f0105eae:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0105eb1:	89 c2                	mov    %eax,%edx
f0105eb3:	83 c2 01             	add    $0x1,%edx
f0105eb6:	83 c1 01             	add    $0x1,%ecx
f0105eb9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0105ebd:	88 5a ff             	mov    %bl,-0x1(%edx)
f0105ec0:	84 db                	test   %bl,%bl
f0105ec2:	75 ef                	jne    f0105eb3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0105ec4:	5b                   	pop    %ebx
f0105ec5:	5d                   	pop    %ebp
f0105ec6:	c3                   	ret    

f0105ec7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0105ec7:	55                   	push   %ebp
f0105ec8:	89 e5                	mov    %esp,%ebp
f0105eca:	53                   	push   %ebx
f0105ecb:	83 ec 08             	sub    $0x8,%esp
f0105ece:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0105ed1:	89 1c 24             	mov    %ebx,(%esp)
f0105ed4:	e8 97 ff ff ff       	call   f0105e70 <strlen>
	strcpy(dst + len, src);
f0105ed9:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105edc:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105ee0:	01 d8                	add    %ebx,%eax
f0105ee2:	89 04 24             	mov    %eax,(%esp)
f0105ee5:	e8 bd ff ff ff       	call   f0105ea7 <strcpy>
	return dst;
}
f0105eea:	89 d8                	mov    %ebx,%eax
f0105eec:	83 c4 08             	add    $0x8,%esp
f0105eef:	5b                   	pop    %ebx
f0105ef0:	5d                   	pop    %ebp
f0105ef1:	c3                   	ret    

f0105ef2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0105ef2:	55                   	push   %ebp
f0105ef3:	89 e5                	mov    %esp,%ebp
f0105ef5:	56                   	push   %esi
f0105ef6:	53                   	push   %ebx
f0105ef7:	8b 75 08             	mov    0x8(%ebp),%esi
f0105efa:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0105efd:	89 f3                	mov    %esi,%ebx
f0105eff:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105f02:	89 f2                	mov    %esi,%edx
f0105f04:	eb 0f                	jmp    f0105f15 <strncpy+0x23>
		*dst++ = *src;
f0105f06:	83 c2 01             	add    $0x1,%edx
f0105f09:	0f b6 01             	movzbl (%ecx),%eax
f0105f0c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0105f0f:	80 39 01             	cmpb   $0x1,(%ecx)
f0105f12:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105f15:	39 da                	cmp    %ebx,%edx
f0105f17:	75 ed                	jne    f0105f06 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0105f19:	89 f0                	mov    %esi,%eax
f0105f1b:	5b                   	pop    %ebx
f0105f1c:	5e                   	pop    %esi
f0105f1d:	5d                   	pop    %ebp
f0105f1e:	c3                   	ret    

f0105f1f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0105f1f:	55                   	push   %ebp
f0105f20:	89 e5                	mov    %esp,%ebp
f0105f22:	56                   	push   %esi
f0105f23:	53                   	push   %ebx
f0105f24:	8b 75 08             	mov    0x8(%ebp),%esi
f0105f27:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105f2a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0105f2d:	89 f0                	mov    %esi,%eax
f0105f2f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0105f33:	85 c9                	test   %ecx,%ecx
f0105f35:	75 0b                	jne    f0105f42 <strlcpy+0x23>
f0105f37:	eb 1d                	jmp    f0105f56 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0105f39:	83 c0 01             	add    $0x1,%eax
f0105f3c:	83 c2 01             	add    $0x1,%edx
f0105f3f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0105f42:	39 d8                	cmp    %ebx,%eax
f0105f44:	74 0b                	je     f0105f51 <strlcpy+0x32>
f0105f46:	0f b6 0a             	movzbl (%edx),%ecx
f0105f49:	84 c9                	test   %cl,%cl
f0105f4b:	75 ec                	jne    f0105f39 <strlcpy+0x1a>
f0105f4d:	89 c2                	mov    %eax,%edx
f0105f4f:	eb 02                	jmp    f0105f53 <strlcpy+0x34>
f0105f51:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0105f53:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0105f56:	29 f0                	sub    %esi,%eax
}
f0105f58:	5b                   	pop    %ebx
f0105f59:	5e                   	pop    %esi
f0105f5a:	5d                   	pop    %ebp
f0105f5b:	c3                   	ret    

f0105f5c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0105f5c:	55                   	push   %ebp
f0105f5d:	89 e5                	mov    %esp,%ebp
f0105f5f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105f62:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0105f65:	eb 06                	jmp    f0105f6d <strcmp+0x11>
		p++, q++;
f0105f67:	83 c1 01             	add    $0x1,%ecx
f0105f6a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0105f6d:	0f b6 01             	movzbl (%ecx),%eax
f0105f70:	84 c0                	test   %al,%al
f0105f72:	74 04                	je     f0105f78 <strcmp+0x1c>
f0105f74:	3a 02                	cmp    (%edx),%al
f0105f76:	74 ef                	je     f0105f67 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0105f78:	0f b6 c0             	movzbl %al,%eax
f0105f7b:	0f b6 12             	movzbl (%edx),%edx
f0105f7e:	29 d0                	sub    %edx,%eax
}
f0105f80:	5d                   	pop    %ebp
f0105f81:	c3                   	ret    

f0105f82 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0105f82:	55                   	push   %ebp
f0105f83:	89 e5                	mov    %esp,%ebp
f0105f85:	53                   	push   %ebx
f0105f86:	8b 45 08             	mov    0x8(%ebp),%eax
f0105f89:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105f8c:	89 c3                	mov    %eax,%ebx
f0105f8e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0105f91:	eb 06                	jmp    f0105f99 <strncmp+0x17>
		n--, p++, q++;
f0105f93:	83 c0 01             	add    $0x1,%eax
f0105f96:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0105f99:	39 d8                	cmp    %ebx,%eax
f0105f9b:	74 15                	je     f0105fb2 <strncmp+0x30>
f0105f9d:	0f b6 08             	movzbl (%eax),%ecx
f0105fa0:	84 c9                	test   %cl,%cl
f0105fa2:	74 04                	je     f0105fa8 <strncmp+0x26>
f0105fa4:	3a 0a                	cmp    (%edx),%cl
f0105fa6:	74 eb                	je     f0105f93 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0105fa8:	0f b6 00             	movzbl (%eax),%eax
f0105fab:	0f b6 12             	movzbl (%edx),%edx
f0105fae:	29 d0                	sub    %edx,%eax
f0105fb0:	eb 05                	jmp    f0105fb7 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0105fb2:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0105fb7:	5b                   	pop    %ebx
f0105fb8:	5d                   	pop    %ebp
f0105fb9:	c3                   	ret    

f0105fba <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0105fba:	55                   	push   %ebp
f0105fbb:	89 e5                	mov    %esp,%ebp
f0105fbd:	8b 45 08             	mov    0x8(%ebp),%eax
f0105fc0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105fc4:	eb 07                	jmp    f0105fcd <strchr+0x13>
		if (*s == c)
f0105fc6:	38 ca                	cmp    %cl,%dl
f0105fc8:	74 0f                	je     f0105fd9 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0105fca:	83 c0 01             	add    $0x1,%eax
f0105fcd:	0f b6 10             	movzbl (%eax),%edx
f0105fd0:	84 d2                	test   %dl,%dl
f0105fd2:	75 f2                	jne    f0105fc6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0105fd4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105fd9:	5d                   	pop    %ebp
f0105fda:	c3                   	ret    

f0105fdb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0105fdb:	55                   	push   %ebp
f0105fdc:	89 e5                	mov    %esp,%ebp
f0105fde:	8b 45 08             	mov    0x8(%ebp),%eax
f0105fe1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105fe5:	eb 07                	jmp    f0105fee <strfind+0x13>
		if (*s == c)
f0105fe7:	38 ca                	cmp    %cl,%dl
f0105fe9:	74 0a                	je     f0105ff5 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0105feb:	83 c0 01             	add    $0x1,%eax
f0105fee:	0f b6 10             	movzbl (%eax),%edx
f0105ff1:	84 d2                	test   %dl,%dl
f0105ff3:	75 f2                	jne    f0105fe7 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0105ff5:	5d                   	pop    %ebp
f0105ff6:	c3                   	ret    

f0105ff7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0105ff7:	55                   	push   %ebp
f0105ff8:	89 e5                	mov    %esp,%ebp
f0105ffa:	57                   	push   %edi
f0105ffb:	56                   	push   %esi
f0105ffc:	53                   	push   %ebx
f0105ffd:	8b 7d 08             	mov    0x8(%ebp),%edi
f0106000:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0106003:	85 c9                	test   %ecx,%ecx
f0106005:	74 36                	je     f010603d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0106007:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010600d:	75 28                	jne    f0106037 <memset+0x40>
f010600f:	f6 c1 03             	test   $0x3,%cl
f0106012:	75 23                	jne    f0106037 <memset+0x40>
		c &= 0xFF;
f0106014:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0106018:	89 d3                	mov    %edx,%ebx
f010601a:	c1 e3 08             	shl    $0x8,%ebx
f010601d:	89 d6                	mov    %edx,%esi
f010601f:	c1 e6 18             	shl    $0x18,%esi
f0106022:	89 d0                	mov    %edx,%eax
f0106024:	c1 e0 10             	shl    $0x10,%eax
f0106027:	09 f0                	or     %esi,%eax
f0106029:	09 c2                	or     %eax,%edx
f010602b:	89 d0                	mov    %edx,%eax
f010602d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010602f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0106032:	fc                   	cld    
f0106033:	f3 ab                	rep stos %eax,%es:(%edi)
f0106035:	eb 06                	jmp    f010603d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0106037:	8b 45 0c             	mov    0xc(%ebp),%eax
f010603a:	fc                   	cld    
f010603b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010603d:	89 f8                	mov    %edi,%eax
f010603f:	5b                   	pop    %ebx
f0106040:	5e                   	pop    %esi
f0106041:	5f                   	pop    %edi
f0106042:	5d                   	pop    %ebp
f0106043:	c3                   	ret    

f0106044 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0106044:	55                   	push   %ebp
f0106045:	89 e5                	mov    %esp,%ebp
f0106047:	57                   	push   %edi
f0106048:	56                   	push   %esi
f0106049:	8b 45 08             	mov    0x8(%ebp),%eax
f010604c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010604f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0106052:	39 c6                	cmp    %eax,%esi
f0106054:	73 35                	jae    f010608b <memmove+0x47>
f0106056:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0106059:	39 d0                	cmp    %edx,%eax
f010605b:	73 2e                	jae    f010608b <memmove+0x47>
		s += n;
		d += n;
f010605d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0106060:	89 d6                	mov    %edx,%esi
f0106062:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0106064:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010606a:	75 13                	jne    f010607f <memmove+0x3b>
f010606c:	f6 c1 03             	test   $0x3,%cl
f010606f:	75 0e                	jne    f010607f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0106071:	83 ef 04             	sub    $0x4,%edi
f0106074:	8d 72 fc             	lea    -0x4(%edx),%esi
f0106077:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010607a:	fd                   	std    
f010607b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010607d:	eb 09                	jmp    f0106088 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010607f:	83 ef 01             	sub    $0x1,%edi
f0106082:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0106085:	fd                   	std    
f0106086:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0106088:	fc                   	cld    
f0106089:	eb 1d                	jmp    f01060a8 <memmove+0x64>
f010608b:	89 f2                	mov    %esi,%edx
f010608d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010608f:	f6 c2 03             	test   $0x3,%dl
f0106092:	75 0f                	jne    f01060a3 <memmove+0x5f>
f0106094:	f6 c1 03             	test   $0x3,%cl
f0106097:	75 0a                	jne    f01060a3 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0106099:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010609c:	89 c7                	mov    %eax,%edi
f010609e:	fc                   	cld    
f010609f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01060a1:	eb 05                	jmp    f01060a8 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01060a3:	89 c7                	mov    %eax,%edi
f01060a5:	fc                   	cld    
f01060a6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01060a8:	5e                   	pop    %esi
f01060a9:	5f                   	pop    %edi
f01060aa:	5d                   	pop    %ebp
f01060ab:	c3                   	ret    

f01060ac <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01060ac:	55                   	push   %ebp
f01060ad:	89 e5                	mov    %esp,%ebp
f01060af:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01060b2:	8b 45 10             	mov    0x10(%ebp),%eax
f01060b5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01060b9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01060bc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01060c0:	8b 45 08             	mov    0x8(%ebp),%eax
f01060c3:	89 04 24             	mov    %eax,(%esp)
f01060c6:	e8 79 ff ff ff       	call   f0106044 <memmove>
}
f01060cb:	c9                   	leave  
f01060cc:	c3                   	ret    

f01060cd <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01060cd:	55                   	push   %ebp
f01060ce:	89 e5                	mov    %esp,%ebp
f01060d0:	56                   	push   %esi
f01060d1:	53                   	push   %ebx
f01060d2:	8b 55 08             	mov    0x8(%ebp),%edx
f01060d5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01060d8:	89 d6                	mov    %edx,%esi
f01060da:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01060dd:	eb 1a                	jmp    f01060f9 <memcmp+0x2c>
		if (*s1 != *s2)
f01060df:	0f b6 02             	movzbl (%edx),%eax
f01060e2:	0f b6 19             	movzbl (%ecx),%ebx
f01060e5:	38 d8                	cmp    %bl,%al
f01060e7:	74 0a                	je     f01060f3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01060e9:	0f b6 c0             	movzbl %al,%eax
f01060ec:	0f b6 db             	movzbl %bl,%ebx
f01060ef:	29 d8                	sub    %ebx,%eax
f01060f1:	eb 0f                	jmp    f0106102 <memcmp+0x35>
		s1++, s2++;
f01060f3:	83 c2 01             	add    $0x1,%edx
f01060f6:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01060f9:	39 f2                	cmp    %esi,%edx
f01060fb:	75 e2                	jne    f01060df <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01060fd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0106102:	5b                   	pop    %ebx
f0106103:	5e                   	pop    %esi
f0106104:	5d                   	pop    %ebp
f0106105:	c3                   	ret    

f0106106 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0106106:	55                   	push   %ebp
f0106107:	89 e5                	mov    %esp,%ebp
f0106109:	8b 45 08             	mov    0x8(%ebp),%eax
f010610c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010610f:	89 c2                	mov    %eax,%edx
f0106111:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0106114:	eb 07                	jmp    f010611d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0106116:	38 08                	cmp    %cl,(%eax)
f0106118:	74 07                	je     f0106121 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010611a:	83 c0 01             	add    $0x1,%eax
f010611d:	39 d0                	cmp    %edx,%eax
f010611f:	72 f5                	jb     f0106116 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0106121:	5d                   	pop    %ebp
f0106122:	c3                   	ret    

f0106123 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0106123:	55                   	push   %ebp
f0106124:	89 e5                	mov    %esp,%ebp
f0106126:	57                   	push   %edi
f0106127:	56                   	push   %esi
f0106128:	53                   	push   %ebx
f0106129:	8b 55 08             	mov    0x8(%ebp),%edx
f010612c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010612f:	eb 03                	jmp    f0106134 <strtol+0x11>
		s++;
f0106131:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0106134:	0f b6 0a             	movzbl (%edx),%ecx
f0106137:	80 f9 09             	cmp    $0x9,%cl
f010613a:	74 f5                	je     f0106131 <strtol+0xe>
f010613c:	80 f9 20             	cmp    $0x20,%cl
f010613f:	74 f0                	je     f0106131 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0106141:	80 f9 2b             	cmp    $0x2b,%cl
f0106144:	75 0a                	jne    f0106150 <strtol+0x2d>
		s++;
f0106146:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0106149:	bf 00 00 00 00       	mov    $0x0,%edi
f010614e:	eb 11                	jmp    f0106161 <strtol+0x3e>
f0106150:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0106155:	80 f9 2d             	cmp    $0x2d,%cl
f0106158:	75 07                	jne    f0106161 <strtol+0x3e>
		s++, neg = 1;
f010615a:	8d 52 01             	lea    0x1(%edx),%edx
f010615d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0106161:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0106166:	75 15                	jne    f010617d <strtol+0x5a>
f0106168:	80 3a 30             	cmpb   $0x30,(%edx)
f010616b:	75 10                	jne    f010617d <strtol+0x5a>
f010616d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0106171:	75 0a                	jne    f010617d <strtol+0x5a>
		s += 2, base = 16;
f0106173:	83 c2 02             	add    $0x2,%edx
f0106176:	b8 10 00 00 00       	mov    $0x10,%eax
f010617b:	eb 10                	jmp    f010618d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f010617d:	85 c0                	test   %eax,%eax
f010617f:	75 0c                	jne    f010618d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0106181:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0106183:	80 3a 30             	cmpb   $0x30,(%edx)
f0106186:	75 05                	jne    f010618d <strtol+0x6a>
		s++, base = 8;
f0106188:	83 c2 01             	add    $0x1,%edx
f010618b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f010618d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0106192:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0106195:	0f b6 0a             	movzbl (%edx),%ecx
f0106198:	8d 71 d0             	lea    -0x30(%ecx),%esi
f010619b:	89 f0                	mov    %esi,%eax
f010619d:	3c 09                	cmp    $0x9,%al
f010619f:	77 08                	ja     f01061a9 <strtol+0x86>
			dig = *s - '0';
f01061a1:	0f be c9             	movsbl %cl,%ecx
f01061a4:	83 e9 30             	sub    $0x30,%ecx
f01061a7:	eb 20                	jmp    f01061c9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f01061a9:	8d 71 9f             	lea    -0x61(%ecx),%esi
f01061ac:	89 f0                	mov    %esi,%eax
f01061ae:	3c 19                	cmp    $0x19,%al
f01061b0:	77 08                	ja     f01061ba <strtol+0x97>
			dig = *s - 'a' + 10;
f01061b2:	0f be c9             	movsbl %cl,%ecx
f01061b5:	83 e9 57             	sub    $0x57,%ecx
f01061b8:	eb 0f                	jmp    f01061c9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f01061ba:	8d 71 bf             	lea    -0x41(%ecx),%esi
f01061bd:	89 f0                	mov    %esi,%eax
f01061bf:	3c 19                	cmp    $0x19,%al
f01061c1:	77 16                	ja     f01061d9 <strtol+0xb6>
			dig = *s - 'A' + 10;
f01061c3:	0f be c9             	movsbl %cl,%ecx
f01061c6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01061c9:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f01061cc:	7d 0f                	jge    f01061dd <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f01061ce:	83 c2 01             	add    $0x1,%edx
f01061d1:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f01061d5:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f01061d7:	eb bc                	jmp    f0106195 <strtol+0x72>
f01061d9:	89 d8                	mov    %ebx,%eax
f01061db:	eb 02                	jmp    f01061df <strtol+0xbc>
f01061dd:	89 d8                	mov    %ebx,%eax

	if (endptr)
f01061df:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01061e3:	74 05                	je     f01061ea <strtol+0xc7>
		*endptr = (char *) s;
f01061e5:	8b 75 0c             	mov    0xc(%ebp),%esi
f01061e8:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f01061ea:	f7 d8                	neg    %eax
f01061ec:	85 ff                	test   %edi,%edi
f01061ee:	0f 44 c3             	cmove  %ebx,%eax
}
f01061f1:	5b                   	pop    %ebx
f01061f2:	5e                   	pop    %esi
f01061f3:	5f                   	pop    %edi
f01061f4:	5d                   	pop    %ebp
f01061f5:	c3                   	ret    
f01061f6:	66 90                	xchg   %ax,%ax

f01061f8 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f01061f8:	fa                   	cli    

	xorw    %ax, %ax
f01061f9:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f01061fb:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f01061fd:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f01061ff:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0106201:	0f 01 16             	lgdtl  (%esi)
f0106204:	74 70                	je     f0106276 <mpentry_end+0x4>
	movl    %cr0, %eax
f0106206:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f0106209:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f010620d:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0106210:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f0106216:	08 00                	or     %al,(%eax)

f0106218 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f0106218:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f010621c:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f010621e:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0106220:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f0106222:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f0106226:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f0106228:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f010622a:	b8 00 f0 11 00       	mov    $0x11f000,%eax
	movl    %eax, %cr3
f010622f:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f0106232:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0106235:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f010623a:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f010623d:	8b 25 84 1e 23 f0    	mov    0xf0231e84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0106243:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f0106248:	b8 e2 01 10 f0       	mov    $0xf01001e2,%eax
	call    *%eax
f010624d:	ff d0                	call   *%eax

f010624f <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f010624f:	eb fe                	jmp    f010624f <spin>
f0106251:	8d 76 00             	lea    0x0(%esi),%esi

f0106254 <gdt>:
	...
f010625c:	ff                   	(bad)  
f010625d:	ff 00                	incl   (%eax)
f010625f:	00 00                	add    %al,(%eax)
f0106261:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f0106268:	00 92 cf 00 17 00    	add    %dl,0x1700cf(%edx)

f010626c <gdtdesc>:
f010626c:	17                   	pop    %ss
f010626d:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0106272 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0106272:	90                   	nop
f0106273:	66 90                	xchg   %ax,%ax
f0106275:	66 90                	xchg   %ax,%ax
f0106277:	66 90                	xchg   %ax,%ax
f0106279:	66 90                	xchg   %ax,%ax
f010627b:	66 90                	xchg   %ax,%ax
f010627d:	66 90                	xchg   %ax,%ax
f010627f:	90                   	nop

f0106280 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0106280:	55                   	push   %ebp
f0106281:	89 e5                	mov    %esp,%ebp
f0106283:	56                   	push   %esi
f0106284:	53                   	push   %ebx
f0106285:	83 ec 10             	sub    $0x10,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0106288:	8b 0d 88 1e 23 f0    	mov    0xf0231e88,%ecx
f010628e:	89 c3                	mov    %eax,%ebx
f0106290:	c1 eb 0c             	shr    $0xc,%ebx
f0106293:	39 cb                	cmp    %ecx,%ebx
f0106295:	72 20                	jb     f01062b7 <mpsearch1+0x37>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0106297:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010629b:	c7 44 24 08 44 6d 10 	movl   $0xf0106d44,0x8(%esp)
f01062a2:	f0 
f01062a3:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
f01062aa:	00 
f01062ab:	c7 04 24 81 88 10 f0 	movl   $0xf0108881,(%esp)
f01062b2:	e8 89 9d ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01062b7:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f01062bd:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01062bf:	89 c2                	mov    %eax,%edx
f01062c1:	c1 ea 0c             	shr    $0xc,%edx
f01062c4:	39 d1                	cmp    %edx,%ecx
f01062c6:	77 20                	ja     f01062e8 <mpsearch1+0x68>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01062c8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01062cc:	c7 44 24 08 44 6d 10 	movl   $0xf0106d44,0x8(%esp)
f01062d3:	f0 
f01062d4:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
f01062db:	00 
f01062dc:	c7 04 24 81 88 10 f0 	movl   $0xf0108881,(%esp)
f01062e3:	e8 58 9d ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01062e8:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f01062ee:	eb 36                	jmp    f0106326 <mpsearch1+0xa6>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f01062f0:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
f01062f7:	00 
f01062f8:	c7 44 24 04 91 88 10 	movl   $0xf0108891,0x4(%esp)
f01062ff:	f0 
f0106300:	89 1c 24             	mov    %ebx,(%esp)
f0106303:	e8 c5 fd ff ff       	call   f01060cd <memcmp>
f0106308:	85 c0                	test   %eax,%eax
f010630a:	75 17                	jne    f0106323 <mpsearch1+0xa3>
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f010630c:	ba 00 00 00 00       	mov    $0x0,%edx
		sum += ((uint8_t *)addr)[i];
f0106311:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0106315:	01 c8                	add    %ecx,%eax
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0106317:	83 c2 01             	add    $0x1,%edx
f010631a:	83 fa 10             	cmp    $0x10,%edx
f010631d:	75 f2                	jne    f0106311 <mpsearch1+0x91>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f010631f:	84 c0                	test   %al,%al
f0106321:	74 0e                	je     f0106331 <mpsearch1+0xb1>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f0106323:	83 c3 10             	add    $0x10,%ebx
f0106326:	39 f3                	cmp    %esi,%ebx
f0106328:	72 c6                	jb     f01062f0 <mpsearch1+0x70>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f010632a:	b8 00 00 00 00       	mov    $0x0,%eax
f010632f:	eb 02                	jmp    f0106333 <mpsearch1+0xb3>
f0106331:	89 d8                	mov    %ebx,%eax
}
f0106333:	83 c4 10             	add    $0x10,%esp
f0106336:	5b                   	pop    %ebx
f0106337:	5e                   	pop    %esi
f0106338:	5d                   	pop    %ebp
f0106339:	c3                   	ret    

f010633a <mp_init>:
	return conf;
}

void
mp_init(void)
{
f010633a:	55                   	push   %ebp
f010633b:	89 e5                	mov    %esp,%ebp
f010633d:	57                   	push   %edi
f010633e:	56                   	push   %esi
f010633f:	53                   	push   %ebx
f0106340:	83 ec 2c             	sub    $0x2c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0106343:	c7 05 c0 23 23 f0 20 	movl   $0xf0232020,0xf02323c0
f010634a:	20 23 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010634d:	83 3d 88 1e 23 f0 00 	cmpl   $0x0,0xf0231e88
f0106354:	75 24                	jne    f010637a <mp_init+0x40>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0106356:	c7 44 24 0c 00 04 00 	movl   $0x400,0xc(%esp)
f010635d:	00 
f010635e:	c7 44 24 08 44 6d 10 	movl   $0xf0106d44,0x8(%esp)
f0106365:	f0 
f0106366:	c7 44 24 04 6f 00 00 	movl   $0x6f,0x4(%esp)
f010636d:	00 
f010636e:	c7 04 24 81 88 10 f0 	movl   $0xf0108881,(%esp)
f0106375:	e8 c6 9c ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f010637a:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0106381:	85 c0                	test   %eax,%eax
f0106383:	74 16                	je     f010639b <mp_init+0x61>
		p <<= 4;	// Translate from segment to PA
f0106385:	c1 e0 04             	shl    $0x4,%eax
		if ((mp = mpsearch1(p, 1024)))
f0106388:	ba 00 04 00 00       	mov    $0x400,%edx
f010638d:	e8 ee fe ff ff       	call   f0106280 <mpsearch1>
f0106392:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0106395:	85 c0                	test   %eax,%eax
f0106397:	75 3c                	jne    f01063d5 <mp_init+0x9b>
f0106399:	eb 20                	jmp    f01063bb <mp_init+0x81>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
f010639b:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f01063a2:	c1 e0 0a             	shl    $0xa,%eax
		if ((mp = mpsearch1(p - 1024, 1024)))
f01063a5:	2d 00 04 00 00       	sub    $0x400,%eax
f01063aa:	ba 00 04 00 00       	mov    $0x400,%edx
f01063af:	e8 cc fe ff ff       	call   f0106280 <mpsearch1>
f01063b4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01063b7:	85 c0                	test   %eax,%eax
f01063b9:	75 1a                	jne    f01063d5 <mp_init+0x9b>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f01063bb:	ba 00 00 01 00       	mov    $0x10000,%edx
f01063c0:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f01063c5:	e8 b6 fe ff ff       	call   f0106280 <mpsearch1>
f01063ca:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f01063cd:	85 c0                	test   %eax,%eax
f01063cf:	0f 84 54 02 00 00    	je     f0106629 <mp_init+0x2ef>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f01063d5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01063d8:	8b 70 04             	mov    0x4(%eax),%esi
f01063db:	85 f6                	test   %esi,%esi
f01063dd:	74 06                	je     f01063e5 <mp_init+0xab>
f01063df:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f01063e3:	74 11                	je     f01063f6 <mp_init+0xbc>
		cprintf("SMP: Default configurations not implemented\n");
f01063e5:	c7 04 24 f4 86 10 f0 	movl   $0xf01086f4,(%esp)
f01063ec:	e8 38 db ff ff       	call   f0103f29 <cprintf>
f01063f1:	e9 33 02 00 00       	jmp    f0106629 <mp_init+0x2ef>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01063f6:	89 f0                	mov    %esi,%eax
f01063f8:	c1 e8 0c             	shr    $0xc,%eax
f01063fb:	3b 05 88 1e 23 f0    	cmp    0xf0231e88,%eax
f0106401:	72 20                	jb     f0106423 <mp_init+0xe9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0106403:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0106407:	c7 44 24 08 44 6d 10 	movl   $0xf0106d44,0x8(%esp)
f010640e:	f0 
f010640f:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
f0106416:	00 
f0106417:	c7 04 24 81 88 10 f0 	movl   $0xf0108881,(%esp)
f010641e:	e8 1d 9c ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0106423:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f0106429:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
f0106430:	00 
f0106431:	c7 44 24 04 96 88 10 	movl   $0xf0108896,0x4(%esp)
f0106438:	f0 
f0106439:	89 1c 24             	mov    %ebx,(%esp)
f010643c:	e8 8c fc ff ff       	call   f01060cd <memcmp>
f0106441:	85 c0                	test   %eax,%eax
f0106443:	74 11                	je     f0106456 <mp_init+0x11c>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f0106445:	c7 04 24 24 87 10 f0 	movl   $0xf0108724,(%esp)
f010644c:	e8 d8 da ff ff       	call   f0103f29 <cprintf>
f0106451:	e9 d3 01 00 00       	jmp    f0106629 <mp_init+0x2ef>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0106456:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f010645a:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f010645e:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0106461:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0106466:	b8 00 00 00 00       	mov    $0x0,%eax
f010646b:	eb 0d                	jmp    f010647a <mp_init+0x140>
		sum += ((uint8_t *)addr)[i];
f010646d:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f0106474:	f0 
f0106475:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0106477:	83 c0 01             	add    $0x1,%eax
f010647a:	39 c7                	cmp    %eax,%edi
f010647c:	7f ef                	jg     f010646d <mp_init+0x133>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f010647e:	84 d2                	test   %dl,%dl
f0106480:	74 11                	je     f0106493 <mp_init+0x159>
		cprintf("SMP: Bad MP configuration checksum\n");
f0106482:	c7 04 24 58 87 10 f0 	movl   $0xf0108758,(%esp)
f0106489:	e8 9b da ff ff       	call   f0103f29 <cprintf>
f010648e:	e9 96 01 00 00       	jmp    f0106629 <mp_init+0x2ef>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f0106493:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f0106497:	3c 04                	cmp    $0x4,%al
f0106499:	74 1f                	je     f01064ba <mp_init+0x180>
f010649b:	3c 01                	cmp    $0x1,%al
f010649d:	8d 76 00             	lea    0x0(%esi),%esi
f01064a0:	74 18                	je     f01064ba <mp_init+0x180>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f01064a2:	0f b6 c0             	movzbl %al,%eax
f01064a5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01064a9:	c7 04 24 7c 87 10 f0 	movl   $0xf010877c,(%esp)
f01064b0:	e8 74 da ff ff       	call   f0103f29 <cprintf>
f01064b5:	e9 6f 01 00 00       	jmp    f0106629 <mp_init+0x2ef>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f01064ba:	0f b7 73 28          	movzwl 0x28(%ebx),%esi
f01064be:	0f b7 7d e2          	movzwl -0x1e(%ebp),%edi
f01064c2:	01 df                	add    %ebx,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f01064c4:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f01064c9:	b8 00 00 00 00       	mov    $0x0,%eax
f01064ce:	eb 09                	jmp    f01064d9 <mp_init+0x19f>
		sum += ((uint8_t *)addr)[i];
f01064d0:	0f b6 0c 07          	movzbl (%edi,%eax,1),%ecx
f01064d4:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f01064d6:	83 c0 01             	add    $0x1,%eax
f01064d9:	39 c6                	cmp    %eax,%esi
f01064db:	7f f3                	jg     f01064d0 <mp_init+0x196>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f01064dd:	02 53 2a             	add    0x2a(%ebx),%dl
f01064e0:	84 d2                	test   %dl,%dl
f01064e2:	74 11                	je     f01064f5 <mp_init+0x1bb>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f01064e4:	c7 04 24 9c 87 10 f0 	movl   $0xf010879c,(%esp)
f01064eb:	e8 39 da ff ff       	call   f0103f29 <cprintf>
f01064f0:	e9 34 01 00 00       	jmp    f0106629 <mp_init+0x2ef>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f01064f5:	85 db                	test   %ebx,%ebx
f01064f7:	0f 84 2c 01 00 00    	je     f0106629 <mp_init+0x2ef>
		return;
	ismp = 1;
f01064fd:	c7 05 00 20 23 f0 01 	movl   $0x1,0xf0232000
f0106504:	00 00 00 
	lapicaddr = conf->lapicaddr;
f0106507:	8b 43 24             	mov    0x24(%ebx),%eax
f010650a:	a3 00 30 27 f0       	mov    %eax,0xf0273000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f010650f:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f0106512:	be 00 00 00 00       	mov    $0x0,%esi
f0106517:	e9 86 00 00 00       	jmp    f01065a2 <mp_init+0x268>
		switch (*p) {
f010651c:	0f b6 07             	movzbl (%edi),%eax
f010651f:	84 c0                	test   %al,%al
f0106521:	74 06                	je     f0106529 <mp_init+0x1ef>
f0106523:	3c 04                	cmp    $0x4,%al
f0106525:	77 57                	ja     f010657e <mp_init+0x244>
f0106527:	eb 50                	jmp    f0106579 <mp_init+0x23f>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f0106529:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f010652d:	8d 76 00             	lea    0x0(%esi),%esi
f0106530:	74 11                	je     f0106543 <mp_init+0x209>
				bootcpu = &cpus[ncpu];
f0106532:	6b 05 c4 23 23 f0 74 	imul   $0x74,0xf02323c4,%eax
f0106539:	05 20 20 23 f0       	add    $0xf0232020,%eax
f010653e:	a3 c0 23 23 f0       	mov    %eax,0xf02323c0
			if (ncpu < NCPU) {
f0106543:	a1 c4 23 23 f0       	mov    0xf02323c4,%eax
f0106548:	83 f8 07             	cmp    $0x7,%eax
f010654b:	7f 13                	jg     f0106560 <mp_init+0x226>
				cpus[ncpu].cpu_id = ncpu;
f010654d:	6b d0 74             	imul   $0x74,%eax,%edx
f0106550:	88 82 20 20 23 f0    	mov    %al,-0xfdcdfe0(%edx)
				ncpu++;
f0106556:	83 c0 01             	add    $0x1,%eax
f0106559:	a3 c4 23 23 f0       	mov    %eax,0xf02323c4
f010655e:	eb 14                	jmp    f0106574 <mp_init+0x23a>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f0106560:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f0106564:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106568:	c7 04 24 cc 87 10 f0 	movl   $0xf01087cc,(%esp)
f010656f:	e8 b5 d9 ff ff       	call   f0103f29 <cprintf>
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f0106574:	83 c7 14             	add    $0x14,%edi
			continue;
f0106577:	eb 26                	jmp    f010659f <mp_init+0x265>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f0106579:	83 c7 08             	add    $0x8,%edi
			continue;
f010657c:	eb 21                	jmp    f010659f <mp_init+0x265>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f010657e:	0f b6 c0             	movzbl %al,%eax
f0106581:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106585:	c7 04 24 f4 87 10 f0 	movl   $0xf01087f4,(%esp)
f010658c:	e8 98 d9 ff ff       	call   f0103f29 <cprintf>
			ismp = 0;
f0106591:	c7 05 00 20 23 f0 00 	movl   $0x0,0xf0232000
f0106598:	00 00 00 
			i = conf->entry;
f010659b:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f010659f:	83 c6 01             	add    $0x1,%esi
f01065a2:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f01065a6:	39 c6                	cmp    %eax,%esi
f01065a8:	0f 82 6e ff ff ff    	jb     f010651c <mp_init+0x1e2>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f01065ae:	a1 c0 23 23 f0       	mov    0xf02323c0,%eax
f01065b3:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f01065ba:	83 3d 00 20 23 f0 00 	cmpl   $0x0,0xf0232000
f01065c1:	75 22                	jne    f01065e5 <mp_init+0x2ab>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f01065c3:	c7 05 c4 23 23 f0 01 	movl   $0x1,0xf02323c4
f01065ca:	00 00 00 
		lapicaddr = 0;
f01065cd:	c7 05 00 30 27 f0 00 	movl   $0x0,0xf0273000
f01065d4:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f01065d7:	c7 04 24 14 88 10 f0 	movl   $0xf0108814,(%esp)
f01065de:	e8 46 d9 ff ff       	call   f0103f29 <cprintf>
		return;
f01065e3:	eb 44                	jmp    f0106629 <mp_init+0x2ef>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f01065e5:	8b 15 c4 23 23 f0    	mov    0xf02323c4,%edx
f01065eb:	89 54 24 08          	mov    %edx,0x8(%esp)
f01065ef:	0f b6 00             	movzbl (%eax),%eax
f01065f2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01065f6:	c7 04 24 9b 88 10 f0 	movl   $0xf010889b,(%esp)
f01065fd:	e8 27 d9 ff ff       	call   f0103f29 <cprintf>

	if (mp->imcrp) {
f0106602:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0106605:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f0106609:	74 1e                	je     f0106629 <mp_init+0x2ef>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f010660b:	c7 04 24 40 88 10 f0 	movl   $0xf0108840,(%esp)
f0106612:	e8 12 d9 ff ff       	call   f0103f29 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0106617:	ba 22 00 00 00       	mov    $0x22,%edx
f010661c:	b8 70 00 00 00       	mov    $0x70,%eax
f0106621:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0106622:	b2 23                	mov    $0x23,%dl
f0106624:	ec                   	in     (%dx),%al
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
f0106625:	83 c8 01             	or     $0x1,%eax
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0106628:	ee                   	out    %al,(%dx)
	}
}
f0106629:	83 c4 2c             	add    $0x2c,%esp
f010662c:	5b                   	pop    %ebx
f010662d:	5e                   	pop    %esi
f010662e:	5f                   	pop    %edi
f010662f:	5d                   	pop    %ebp
f0106630:	c3                   	ret    

f0106631 <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f0106631:	55                   	push   %ebp
f0106632:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f0106634:	8b 0d 04 30 27 f0    	mov    0xf0273004,%ecx
f010663a:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f010663d:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f010663f:	a1 04 30 27 f0       	mov    0xf0273004,%eax
f0106644:	8b 40 20             	mov    0x20(%eax),%eax
}
f0106647:	5d                   	pop    %ebp
f0106648:	c3                   	ret    

f0106649 <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f0106649:	55                   	push   %ebp
f010664a:	89 e5                	mov    %esp,%ebp
	if (lapic)
f010664c:	a1 04 30 27 f0       	mov    0xf0273004,%eax
f0106651:	85 c0                	test   %eax,%eax
f0106653:	74 08                	je     f010665d <cpunum+0x14>
		return lapic[ID] >> 24;
f0106655:	8b 40 20             	mov    0x20(%eax),%eax
f0106658:	c1 e8 18             	shr    $0x18,%eax
f010665b:	eb 05                	jmp    f0106662 <cpunum+0x19>
	return 0;
f010665d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0106662:	5d                   	pop    %ebp
f0106663:	c3                   	ret    

f0106664 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f0106664:	a1 00 30 27 f0       	mov    0xf0273000,%eax
f0106669:	85 c0                	test   %eax,%eax
f010666b:	0f 84 23 01 00 00    	je     f0106794 <lapic_init+0x130>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f0106671:	55                   	push   %ebp
f0106672:	89 e5                	mov    %esp,%ebp
f0106674:	83 ec 18             	sub    $0x18,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f0106677:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010667e:	00 
f010667f:	89 04 24             	mov    %eax,(%esp)
f0106682:	e8 94 ad ff ff       	call   f010141b <mmio_map_region>
f0106687:	a3 04 30 27 f0       	mov    %eax,0xf0273004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f010668c:	ba 27 01 00 00       	mov    $0x127,%edx
f0106691:	b8 3c 00 00 00       	mov    $0x3c,%eax
f0106696:	e8 96 ff ff ff       	call   f0106631 <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f010669b:	ba 0b 00 00 00       	mov    $0xb,%edx
f01066a0:	b8 f8 00 00 00       	mov    $0xf8,%eax
f01066a5:	e8 87 ff ff ff       	call   f0106631 <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f01066aa:	ba 20 00 02 00       	mov    $0x20020,%edx
f01066af:	b8 c8 00 00 00       	mov    $0xc8,%eax
f01066b4:	e8 78 ff ff ff       	call   f0106631 <lapicw>
	lapicw(TICR, 10000000); 
f01066b9:	ba 80 96 98 00       	mov    $0x989680,%edx
f01066be:	b8 e0 00 00 00       	mov    $0xe0,%eax
f01066c3:	e8 69 ff ff ff       	call   f0106631 <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f01066c8:	e8 7c ff ff ff       	call   f0106649 <cpunum>
f01066cd:	6b c0 74             	imul   $0x74,%eax,%eax
f01066d0:	05 20 20 23 f0       	add    $0xf0232020,%eax
f01066d5:	39 05 c0 23 23 f0    	cmp    %eax,0xf02323c0
f01066db:	74 0f                	je     f01066ec <lapic_init+0x88>
		lapicw(LINT0, MASKED);
f01066dd:	ba 00 00 01 00       	mov    $0x10000,%edx
f01066e2:	b8 d4 00 00 00       	mov    $0xd4,%eax
f01066e7:	e8 45 ff ff ff       	call   f0106631 <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f01066ec:	ba 00 00 01 00       	mov    $0x10000,%edx
f01066f1:	b8 d8 00 00 00       	mov    $0xd8,%eax
f01066f6:	e8 36 ff ff ff       	call   f0106631 <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f01066fb:	a1 04 30 27 f0       	mov    0xf0273004,%eax
f0106700:	8b 40 30             	mov    0x30(%eax),%eax
f0106703:	c1 e8 10             	shr    $0x10,%eax
f0106706:	3c 03                	cmp    $0x3,%al
f0106708:	76 0f                	jbe    f0106719 <lapic_init+0xb5>
		lapicw(PCINT, MASKED);
f010670a:	ba 00 00 01 00       	mov    $0x10000,%edx
f010670f:	b8 d0 00 00 00       	mov    $0xd0,%eax
f0106714:	e8 18 ff ff ff       	call   f0106631 <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f0106719:	ba 33 00 00 00       	mov    $0x33,%edx
f010671e:	b8 dc 00 00 00       	mov    $0xdc,%eax
f0106723:	e8 09 ff ff ff       	call   f0106631 <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f0106728:	ba 00 00 00 00       	mov    $0x0,%edx
f010672d:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0106732:	e8 fa fe ff ff       	call   f0106631 <lapicw>
	lapicw(ESR, 0);
f0106737:	ba 00 00 00 00       	mov    $0x0,%edx
f010673c:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0106741:	e8 eb fe ff ff       	call   f0106631 <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f0106746:	ba 00 00 00 00       	mov    $0x0,%edx
f010674b:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0106750:	e8 dc fe ff ff       	call   f0106631 <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f0106755:	ba 00 00 00 00       	mov    $0x0,%edx
f010675a:	b8 c4 00 00 00       	mov    $0xc4,%eax
f010675f:	e8 cd fe ff ff       	call   f0106631 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f0106764:	ba 00 85 08 00       	mov    $0x88500,%edx
f0106769:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010676e:	e8 be fe ff ff       	call   f0106631 <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0106773:	8b 15 04 30 27 f0    	mov    0xf0273004,%edx
f0106779:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f010677f:	f6 c4 10             	test   $0x10,%ah
f0106782:	75 f5                	jne    f0106779 <lapic_init+0x115>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f0106784:	ba 00 00 00 00       	mov    $0x0,%edx
f0106789:	b8 20 00 00 00       	mov    $0x20,%eax
f010678e:	e8 9e fe ff ff       	call   f0106631 <lapicw>
}
f0106793:	c9                   	leave  
f0106794:	f3 c3                	repz ret 

f0106796 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0106796:	83 3d 04 30 27 f0 00 	cmpl   $0x0,0xf0273004
f010679d:	74 13                	je     f01067b2 <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f010679f:	55                   	push   %ebp
f01067a0:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f01067a2:	ba 00 00 00 00       	mov    $0x0,%edx
f01067a7:	b8 2c 00 00 00       	mov    $0x2c,%eax
f01067ac:	e8 80 fe ff ff       	call   f0106631 <lapicw>
}
f01067b1:	5d                   	pop    %ebp
f01067b2:	f3 c3                	repz ret 

f01067b4 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f01067b4:	55                   	push   %ebp
f01067b5:	89 e5                	mov    %esp,%ebp
f01067b7:	56                   	push   %esi
f01067b8:	53                   	push   %ebx
f01067b9:	83 ec 10             	sub    $0x10,%esp
f01067bc:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01067bf:	8b 75 0c             	mov    0xc(%ebp),%esi
f01067c2:	ba 70 00 00 00       	mov    $0x70,%edx
f01067c7:	b8 0f 00 00 00       	mov    $0xf,%eax
f01067cc:	ee                   	out    %al,(%dx)
f01067cd:	b2 71                	mov    $0x71,%dl
f01067cf:	b8 0a 00 00 00       	mov    $0xa,%eax
f01067d4:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01067d5:	83 3d 88 1e 23 f0 00 	cmpl   $0x0,0xf0231e88
f01067dc:	75 24                	jne    f0106802 <lapic_startap+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01067de:	c7 44 24 0c 67 04 00 	movl   $0x467,0xc(%esp)
f01067e5:	00 
f01067e6:	c7 44 24 08 44 6d 10 	movl   $0xf0106d44,0x8(%esp)
f01067ed:	f0 
f01067ee:	c7 44 24 04 98 00 00 	movl   $0x98,0x4(%esp)
f01067f5:	00 
f01067f6:	c7 04 24 b8 88 10 f0 	movl   $0xf01088b8,(%esp)
f01067fd:	e8 3e 98 ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f0106802:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f0106809:	00 00 
	wrv[1] = addr >> 4;
f010680b:	89 f0                	mov    %esi,%eax
f010680d:	c1 e8 04             	shr    $0x4,%eax
f0106810:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f0106816:	c1 e3 18             	shl    $0x18,%ebx
f0106819:	89 da                	mov    %ebx,%edx
f010681b:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0106820:	e8 0c fe ff ff       	call   f0106631 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0106825:	ba 00 c5 00 00       	mov    $0xc500,%edx
f010682a:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010682f:	e8 fd fd ff ff       	call   f0106631 <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0106834:	ba 00 85 00 00       	mov    $0x8500,%edx
f0106839:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010683e:	e8 ee fd ff ff       	call   f0106631 <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0106843:	c1 ee 0c             	shr    $0xc,%esi
f0106846:	81 ce 00 06 00 00    	or     $0x600,%esi
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f010684c:	89 da                	mov    %ebx,%edx
f010684e:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0106853:	e8 d9 fd ff ff       	call   f0106631 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0106858:	89 f2                	mov    %esi,%edx
f010685a:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010685f:	e8 cd fd ff ff       	call   f0106631 <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0106864:	89 da                	mov    %ebx,%edx
f0106866:	b8 c4 00 00 00       	mov    $0xc4,%eax
f010686b:	e8 c1 fd ff ff       	call   f0106631 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0106870:	89 f2                	mov    %esi,%edx
f0106872:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0106877:	e8 b5 fd ff ff       	call   f0106631 <lapicw>
		microdelay(200);
	}
}
f010687c:	83 c4 10             	add    $0x10,%esp
f010687f:	5b                   	pop    %ebx
f0106880:	5e                   	pop    %esi
f0106881:	5d                   	pop    %ebp
f0106882:	c3                   	ret    

f0106883 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0106883:	55                   	push   %ebp
f0106884:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0106886:	8b 55 08             	mov    0x8(%ebp),%edx
f0106889:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f010688f:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0106894:	e8 98 fd ff ff       	call   f0106631 <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0106899:	8b 15 04 30 27 f0    	mov    0xf0273004,%edx
f010689f:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f01068a5:	f6 c4 10             	test   $0x10,%ah
f01068a8:	75 f5                	jne    f010689f <lapic_ipi+0x1c>
		;
}
f01068aa:	5d                   	pop    %ebp
f01068ab:	c3                   	ret    

f01068ac <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f01068ac:	55                   	push   %ebp
f01068ad:	89 e5                	mov    %esp,%ebp
f01068af:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f01068b2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f01068b8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01068bb:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f01068be:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f01068c5:	5d                   	pop    %ebp
f01068c6:	c3                   	ret    

f01068c7 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f01068c7:	55                   	push   %ebp
f01068c8:	89 e5                	mov    %esp,%ebp
f01068ca:	56                   	push   %esi
f01068cb:	53                   	push   %ebx
f01068cc:	83 ec 20             	sub    $0x20,%esp
f01068cf:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f01068d2:	83 3b 00             	cmpl   $0x0,(%ebx)
f01068d5:	75 07                	jne    f01068de <spin_lock+0x17>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f01068d7:	ba 01 00 00 00       	mov    $0x1,%edx
f01068dc:	eb 42                	jmp    f0106920 <spin_lock+0x59>
f01068de:	8b 73 08             	mov    0x8(%ebx),%esi
f01068e1:	e8 63 fd ff ff       	call   f0106649 <cpunum>
f01068e6:	6b c0 74             	imul   $0x74,%eax,%eax
f01068e9:	05 20 20 23 f0       	add    $0xf0232020,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f01068ee:	39 c6                	cmp    %eax,%esi
f01068f0:	75 e5                	jne    f01068d7 <spin_lock+0x10>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f01068f2:	8b 5b 04             	mov    0x4(%ebx),%ebx
f01068f5:	e8 4f fd ff ff       	call   f0106649 <cpunum>
f01068fa:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f01068fe:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0106902:	c7 44 24 08 c8 88 10 	movl   $0xf01088c8,0x8(%esp)
f0106909:	f0 
f010690a:	c7 44 24 04 41 00 00 	movl   $0x41,0x4(%esp)
f0106911:	00 
f0106912:	c7 04 24 2c 89 10 f0 	movl   $0xf010892c,(%esp)
f0106919:	e8 22 97 ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f010691e:	f3 90                	pause  
f0106920:	89 d0                	mov    %edx,%eax
f0106922:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f0106925:	85 c0                	test   %eax,%eax
f0106927:	75 f5                	jne    f010691e <spin_lock+0x57>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f0106929:	e8 1b fd ff ff       	call   f0106649 <cpunum>
f010692e:	6b c0 74             	imul   $0x74,%eax,%eax
f0106931:	05 20 20 23 f0       	add    $0xf0232020,%eax
f0106936:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f0106939:	83 c3 0c             	add    $0xc,%ebx
get_caller_pcs(uint32_t pcs[])
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
f010693c:	89 ea                	mov    %ebp,%edx
	for (i = 0; i < 10; i++){
f010693e:	b8 00 00 00 00       	mov    $0x0,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f0106943:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f0106949:	76 12                	jbe    f010695d <spin_lock+0x96>
			break;
		pcs[i] = ebp[1];          // saved %eip
f010694b:	8b 4a 04             	mov    0x4(%edx),%ecx
f010694e:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f0106951:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0106953:	83 c0 01             	add    $0x1,%eax
f0106956:	83 f8 0a             	cmp    $0xa,%eax
f0106959:	75 e8                	jne    f0106943 <spin_lock+0x7c>
f010695b:	eb 0f                	jmp    f010696c <spin_lock+0xa5>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f010695d:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f0106964:	83 c0 01             	add    $0x1,%eax
f0106967:	83 f8 09             	cmp    $0x9,%eax
f010696a:	7e f1                	jle    f010695d <spin_lock+0x96>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f010696c:	83 c4 20             	add    $0x20,%esp
f010696f:	5b                   	pop    %ebx
f0106970:	5e                   	pop    %esi
f0106971:	5d                   	pop    %ebp
f0106972:	c3                   	ret    

f0106973 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0106973:	55                   	push   %ebp
f0106974:	89 e5                	mov    %esp,%ebp
f0106976:	57                   	push   %edi
f0106977:	56                   	push   %esi
f0106978:	53                   	push   %ebx
f0106979:	83 ec 6c             	sub    $0x6c,%esp
f010697c:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f010697f:	83 3e 00             	cmpl   $0x0,(%esi)
f0106982:	74 18                	je     f010699c <spin_unlock+0x29>
f0106984:	8b 5e 08             	mov    0x8(%esi),%ebx
f0106987:	e8 bd fc ff ff       	call   f0106649 <cpunum>
f010698c:	6b c0 74             	imul   $0x74,%eax,%eax
f010698f:	05 20 20 23 f0       	add    $0xf0232020,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f0106994:	39 c3                	cmp    %eax,%ebx
f0106996:	0f 84 ce 00 00 00    	je     f0106a6a <spin_unlock+0xf7>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f010699c:	c7 44 24 08 28 00 00 	movl   $0x28,0x8(%esp)
f01069a3:	00 
f01069a4:	8d 46 0c             	lea    0xc(%esi),%eax
f01069a7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01069ab:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f01069ae:	89 1c 24             	mov    %ebx,(%esp)
f01069b1:	e8 8e f6 ff ff       	call   f0106044 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f01069b6:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f01069b9:	0f b6 38             	movzbl (%eax),%edi
f01069bc:	8b 76 04             	mov    0x4(%esi),%esi
f01069bf:	e8 85 fc ff ff       	call   f0106649 <cpunum>
f01069c4:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01069c8:	89 74 24 08          	mov    %esi,0x8(%esp)
f01069cc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01069d0:	c7 04 24 f4 88 10 f0 	movl   $0xf01088f4,(%esp)
f01069d7:	e8 4d d5 ff ff       	call   f0103f29 <cprintf>
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f01069dc:	8d 7d a8             	lea    -0x58(%ebp),%edi
f01069df:	eb 65                	jmp    f0106a46 <spin_unlock+0xd3>
f01069e1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01069e5:	89 04 24             	mov    %eax,(%esp)
f01069e8:	e8 a0 eb ff ff       	call   f010558d <debuginfo_eip>
f01069ed:	85 c0                	test   %eax,%eax
f01069ef:	78 39                	js     f0106a2a <spin_unlock+0xb7>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f01069f1:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f01069f3:	89 c2                	mov    %eax,%edx
f01069f5:	2b 55 b8             	sub    -0x48(%ebp),%edx
f01069f8:	89 54 24 18          	mov    %edx,0x18(%esp)
f01069fc:	8b 55 b0             	mov    -0x50(%ebp),%edx
f01069ff:	89 54 24 14          	mov    %edx,0x14(%esp)
f0106a03:	8b 55 b4             	mov    -0x4c(%ebp),%edx
f0106a06:	89 54 24 10          	mov    %edx,0x10(%esp)
f0106a0a:	8b 55 ac             	mov    -0x54(%ebp),%edx
f0106a0d:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0106a11:	8b 55 a8             	mov    -0x58(%ebp),%edx
f0106a14:	89 54 24 08          	mov    %edx,0x8(%esp)
f0106a18:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106a1c:	c7 04 24 3c 89 10 f0 	movl   $0xf010893c,(%esp)
f0106a23:	e8 01 d5 ff ff       	call   f0103f29 <cprintf>
f0106a28:	eb 12                	jmp    f0106a3c <spin_unlock+0xc9>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f0106a2a:	8b 06                	mov    (%esi),%eax
f0106a2c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106a30:	c7 04 24 53 89 10 f0 	movl   $0xf0108953,(%esp)
f0106a37:	e8 ed d4 ff ff       	call   f0103f29 <cprintf>
f0106a3c:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f0106a3f:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0106a42:	39 c3                	cmp    %eax,%ebx
f0106a44:	74 08                	je     f0106a4e <spin_unlock+0xdb>
f0106a46:	89 de                	mov    %ebx,%esi
f0106a48:	8b 03                	mov    (%ebx),%eax
f0106a4a:	85 c0                	test   %eax,%eax
f0106a4c:	75 93                	jne    f01069e1 <spin_unlock+0x6e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f0106a4e:	c7 44 24 08 5b 89 10 	movl   $0xf010895b,0x8(%esp)
f0106a55:	f0 
f0106a56:	c7 44 24 04 67 00 00 	movl   $0x67,0x4(%esp)
f0106a5d:	00 
f0106a5e:	c7 04 24 2c 89 10 f0 	movl   $0xf010892c,(%esp)
f0106a65:	e8 d6 95 ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f0106a6a:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f0106a71:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
f0106a78:	b8 00 00 00 00       	mov    $0x0,%eax
f0106a7d:	f0 87 06             	lock xchg %eax,(%esi)
	// respect to any other instruction which references the same memory.
	// x86 CPUs will not reorder loads/stores across locked instructions
	// (vol 3, 8.2.2). Because xchg() is implemented using asm volatile,
	// gcc will not reorder C statements across the xchg.
	xchg(&lk->locked, 0);
}
f0106a80:	83 c4 6c             	add    $0x6c,%esp
f0106a83:	5b                   	pop    %ebx
f0106a84:	5e                   	pop    %esi
f0106a85:	5f                   	pop    %edi
f0106a86:	5d                   	pop    %ebp
f0106a87:	c3                   	ret    
f0106a88:	66 90                	xchg   %ax,%ax
f0106a8a:	66 90                	xchg   %ax,%ax
f0106a8c:	66 90                	xchg   %ax,%ax
f0106a8e:	66 90                	xchg   %ax,%ax

f0106a90 <__udivdi3>:
f0106a90:	55                   	push   %ebp
f0106a91:	57                   	push   %edi
f0106a92:	56                   	push   %esi
f0106a93:	83 ec 0c             	sub    $0xc,%esp
f0106a96:	8b 44 24 28          	mov    0x28(%esp),%eax
f0106a9a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0106a9e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0106aa2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0106aa6:	85 c0                	test   %eax,%eax
f0106aa8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0106aac:	89 ea                	mov    %ebp,%edx
f0106aae:	89 0c 24             	mov    %ecx,(%esp)
f0106ab1:	75 2d                	jne    f0106ae0 <__udivdi3+0x50>
f0106ab3:	39 e9                	cmp    %ebp,%ecx
f0106ab5:	77 61                	ja     f0106b18 <__udivdi3+0x88>
f0106ab7:	85 c9                	test   %ecx,%ecx
f0106ab9:	89 ce                	mov    %ecx,%esi
f0106abb:	75 0b                	jne    f0106ac8 <__udivdi3+0x38>
f0106abd:	b8 01 00 00 00       	mov    $0x1,%eax
f0106ac2:	31 d2                	xor    %edx,%edx
f0106ac4:	f7 f1                	div    %ecx
f0106ac6:	89 c6                	mov    %eax,%esi
f0106ac8:	31 d2                	xor    %edx,%edx
f0106aca:	89 e8                	mov    %ebp,%eax
f0106acc:	f7 f6                	div    %esi
f0106ace:	89 c5                	mov    %eax,%ebp
f0106ad0:	89 f8                	mov    %edi,%eax
f0106ad2:	f7 f6                	div    %esi
f0106ad4:	89 ea                	mov    %ebp,%edx
f0106ad6:	83 c4 0c             	add    $0xc,%esp
f0106ad9:	5e                   	pop    %esi
f0106ada:	5f                   	pop    %edi
f0106adb:	5d                   	pop    %ebp
f0106adc:	c3                   	ret    
f0106add:	8d 76 00             	lea    0x0(%esi),%esi
f0106ae0:	39 e8                	cmp    %ebp,%eax
f0106ae2:	77 24                	ja     f0106b08 <__udivdi3+0x78>
f0106ae4:	0f bd e8             	bsr    %eax,%ebp
f0106ae7:	83 f5 1f             	xor    $0x1f,%ebp
f0106aea:	75 3c                	jne    f0106b28 <__udivdi3+0x98>
f0106aec:	8b 74 24 04          	mov    0x4(%esp),%esi
f0106af0:	39 34 24             	cmp    %esi,(%esp)
f0106af3:	0f 86 9f 00 00 00    	jbe    f0106b98 <__udivdi3+0x108>
f0106af9:	39 d0                	cmp    %edx,%eax
f0106afb:	0f 82 97 00 00 00    	jb     f0106b98 <__udivdi3+0x108>
f0106b01:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0106b08:	31 d2                	xor    %edx,%edx
f0106b0a:	31 c0                	xor    %eax,%eax
f0106b0c:	83 c4 0c             	add    $0xc,%esp
f0106b0f:	5e                   	pop    %esi
f0106b10:	5f                   	pop    %edi
f0106b11:	5d                   	pop    %ebp
f0106b12:	c3                   	ret    
f0106b13:	90                   	nop
f0106b14:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106b18:	89 f8                	mov    %edi,%eax
f0106b1a:	f7 f1                	div    %ecx
f0106b1c:	31 d2                	xor    %edx,%edx
f0106b1e:	83 c4 0c             	add    $0xc,%esp
f0106b21:	5e                   	pop    %esi
f0106b22:	5f                   	pop    %edi
f0106b23:	5d                   	pop    %ebp
f0106b24:	c3                   	ret    
f0106b25:	8d 76 00             	lea    0x0(%esi),%esi
f0106b28:	89 e9                	mov    %ebp,%ecx
f0106b2a:	8b 3c 24             	mov    (%esp),%edi
f0106b2d:	d3 e0                	shl    %cl,%eax
f0106b2f:	89 c6                	mov    %eax,%esi
f0106b31:	b8 20 00 00 00       	mov    $0x20,%eax
f0106b36:	29 e8                	sub    %ebp,%eax
f0106b38:	89 c1                	mov    %eax,%ecx
f0106b3a:	d3 ef                	shr    %cl,%edi
f0106b3c:	89 e9                	mov    %ebp,%ecx
f0106b3e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0106b42:	8b 3c 24             	mov    (%esp),%edi
f0106b45:	09 74 24 08          	or     %esi,0x8(%esp)
f0106b49:	89 d6                	mov    %edx,%esi
f0106b4b:	d3 e7                	shl    %cl,%edi
f0106b4d:	89 c1                	mov    %eax,%ecx
f0106b4f:	89 3c 24             	mov    %edi,(%esp)
f0106b52:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0106b56:	d3 ee                	shr    %cl,%esi
f0106b58:	89 e9                	mov    %ebp,%ecx
f0106b5a:	d3 e2                	shl    %cl,%edx
f0106b5c:	89 c1                	mov    %eax,%ecx
f0106b5e:	d3 ef                	shr    %cl,%edi
f0106b60:	09 d7                	or     %edx,%edi
f0106b62:	89 f2                	mov    %esi,%edx
f0106b64:	89 f8                	mov    %edi,%eax
f0106b66:	f7 74 24 08          	divl   0x8(%esp)
f0106b6a:	89 d6                	mov    %edx,%esi
f0106b6c:	89 c7                	mov    %eax,%edi
f0106b6e:	f7 24 24             	mull   (%esp)
f0106b71:	39 d6                	cmp    %edx,%esi
f0106b73:	89 14 24             	mov    %edx,(%esp)
f0106b76:	72 30                	jb     f0106ba8 <__udivdi3+0x118>
f0106b78:	8b 54 24 04          	mov    0x4(%esp),%edx
f0106b7c:	89 e9                	mov    %ebp,%ecx
f0106b7e:	d3 e2                	shl    %cl,%edx
f0106b80:	39 c2                	cmp    %eax,%edx
f0106b82:	73 05                	jae    f0106b89 <__udivdi3+0xf9>
f0106b84:	3b 34 24             	cmp    (%esp),%esi
f0106b87:	74 1f                	je     f0106ba8 <__udivdi3+0x118>
f0106b89:	89 f8                	mov    %edi,%eax
f0106b8b:	31 d2                	xor    %edx,%edx
f0106b8d:	e9 7a ff ff ff       	jmp    f0106b0c <__udivdi3+0x7c>
f0106b92:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0106b98:	31 d2                	xor    %edx,%edx
f0106b9a:	b8 01 00 00 00       	mov    $0x1,%eax
f0106b9f:	e9 68 ff ff ff       	jmp    f0106b0c <__udivdi3+0x7c>
f0106ba4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106ba8:	8d 47 ff             	lea    -0x1(%edi),%eax
f0106bab:	31 d2                	xor    %edx,%edx
f0106bad:	83 c4 0c             	add    $0xc,%esp
f0106bb0:	5e                   	pop    %esi
f0106bb1:	5f                   	pop    %edi
f0106bb2:	5d                   	pop    %ebp
f0106bb3:	c3                   	ret    
f0106bb4:	66 90                	xchg   %ax,%ax
f0106bb6:	66 90                	xchg   %ax,%ax
f0106bb8:	66 90                	xchg   %ax,%ax
f0106bba:	66 90                	xchg   %ax,%ax
f0106bbc:	66 90                	xchg   %ax,%ax
f0106bbe:	66 90                	xchg   %ax,%ax

f0106bc0 <__umoddi3>:
f0106bc0:	55                   	push   %ebp
f0106bc1:	57                   	push   %edi
f0106bc2:	56                   	push   %esi
f0106bc3:	83 ec 14             	sub    $0x14,%esp
f0106bc6:	8b 44 24 28          	mov    0x28(%esp),%eax
f0106bca:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0106bce:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0106bd2:	89 c7                	mov    %eax,%edi
f0106bd4:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106bd8:	8b 44 24 30          	mov    0x30(%esp),%eax
f0106bdc:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0106be0:	89 34 24             	mov    %esi,(%esp)
f0106be3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0106be7:	85 c0                	test   %eax,%eax
f0106be9:	89 c2                	mov    %eax,%edx
f0106beb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0106bef:	75 17                	jne    f0106c08 <__umoddi3+0x48>
f0106bf1:	39 fe                	cmp    %edi,%esi
f0106bf3:	76 4b                	jbe    f0106c40 <__umoddi3+0x80>
f0106bf5:	89 c8                	mov    %ecx,%eax
f0106bf7:	89 fa                	mov    %edi,%edx
f0106bf9:	f7 f6                	div    %esi
f0106bfb:	89 d0                	mov    %edx,%eax
f0106bfd:	31 d2                	xor    %edx,%edx
f0106bff:	83 c4 14             	add    $0x14,%esp
f0106c02:	5e                   	pop    %esi
f0106c03:	5f                   	pop    %edi
f0106c04:	5d                   	pop    %ebp
f0106c05:	c3                   	ret    
f0106c06:	66 90                	xchg   %ax,%ax
f0106c08:	39 f8                	cmp    %edi,%eax
f0106c0a:	77 54                	ja     f0106c60 <__umoddi3+0xa0>
f0106c0c:	0f bd e8             	bsr    %eax,%ebp
f0106c0f:	83 f5 1f             	xor    $0x1f,%ebp
f0106c12:	75 5c                	jne    f0106c70 <__umoddi3+0xb0>
f0106c14:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0106c18:	39 3c 24             	cmp    %edi,(%esp)
f0106c1b:	0f 87 e7 00 00 00    	ja     f0106d08 <__umoddi3+0x148>
f0106c21:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0106c25:	29 f1                	sub    %esi,%ecx
f0106c27:	19 c7                	sbb    %eax,%edi
f0106c29:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0106c2d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0106c31:	8b 44 24 08          	mov    0x8(%esp),%eax
f0106c35:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0106c39:	83 c4 14             	add    $0x14,%esp
f0106c3c:	5e                   	pop    %esi
f0106c3d:	5f                   	pop    %edi
f0106c3e:	5d                   	pop    %ebp
f0106c3f:	c3                   	ret    
f0106c40:	85 f6                	test   %esi,%esi
f0106c42:	89 f5                	mov    %esi,%ebp
f0106c44:	75 0b                	jne    f0106c51 <__umoddi3+0x91>
f0106c46:	b8 01 00 00 00       	mov    $0x1,%eax
f0106c4b:	31 d2                	xor    %edx,%edx
f0106c4d:	f7 f6                	div    %esi
f0106c4f:	89 c5                	mov    %eax,%ebp
f0106c51:	8b 44 24 04          	mov    0x4(%esp),%eax
f0106c55:	31 d2                	xor    %edx,%edx
f0106c57:	f7 f5                	div    %ebp
f0106c59:	89 c8                	mov    %ecx,%eax
f0106c5b:	f7 f5                	div    %ebp
f0106c5d:	eb 9c                	jmp    f0106bfb <__umoddi3+0x3b>
f0106c5f:	90                   	nop
f0106c60:	89 c8                	mov    %ecx,%eax
f0106c62:	89 fa                	mov    %edi,%edx
f0106c64:	83 c4 14             	add    $0x14,%esp
f0106c67:	5e                   	pop    %esi
f0106c68:	5f                   	pop    %edi
f0106c69:	5d                   	pop    %ebp
f0106c6a:	c3                   	ret    
f0106c6b:	90                   	nop
f0106c6c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106c70:	8b 04 24             	mov    (%esp),%eax
f0106c73:	be 20 00 00 00       	mov    $0x20,%esi
f0106c78:	89 e9                	mov    %ebp,%ecx
f0106c7a:	29 ee                	sub    %ebp,%esi
f0106c7c:	d3 e2                	shl    %cl,%edx
f0106c7e:	89 f1                	mov    %esi,%ecx
f0106c80:	d3 e8                	shr    %cl,%eax
f0106c82:	89 e9                	mov    %ebp,%ecx
f0106c84:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106c88:	8b 04 24             	mov    (%esp),%eax
f0106c8b:	09 54 24 04          	or     %edx,0x4(%esp)
f0106c8f:	89 fa                	mov    %edi,%edx
f0106c91:	d3 e0                	shl    %cl,%eax
f0106c93:	89 f1                	mov    %esi,%ecx
f0106c95:	89 44 24 08          	mov    %eax,0x8(%esp)
f0106c99:	8b 44 24 10          	mov    0x10(%esp),%eax
f0106c9d:	d3 ea                	shr    %cl,%edx
f0106c9f:	89 e9                	mov    %ebp,%ecx
f0106ca1:	d3 e7                	shl    %cl,%edi
f0106ca3:	89 f1                	mov    %esi,%ecx
f0106ca5:	d3 e8                	shr    %cl,%eax
f0106ca7:	89 e9                	mov    %ebp,%ecx
f0106ca9:	09 f8                	or     %edi,%eax
f0106cab:	8b 7c 24 10          	mov    0x10(%esp),%edi
f0106caf:	f7 74 24 04          	divl   0x4(%esp)
f0106cb3:	d3 e7                	shl    %cl,%edi
f0106cb5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0106cb9:	89 d7                	mov    %edx,%edi
f0106cbb:	f7 64 24 08          	mull   0x8(%esp)
f0106cbf:	39 d7                	cmp    %edx,%edi
f0106cc1:	89 c1                	mov    %eax,%ecx
f0106cc3:	89 14 24             	mov    %edx,(%esp)
f0106cc6:	72 2c                	jb     f0106cf4 <__umoddi3+0x134>
f0106cc8:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f0106ccc:	72 22                	jb     f0106cf0 <__umoddi3+0x130>
f0106cce:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0106cd2:	29 c8                	sub    %ecx,%eax
f0106cd4:	19 d7                	sbb    %edx,%edi
f0106cd6:	89 e9                	mov    %ebp,%ecx
f0106cd8:	89 fa                	mov    %edi,%edx
f0106cda:	d3 e8                	shr    %cl,%eax
f0106cdc:	89 f1                	mov    %esi,%ecx
f0106cde:	d3 e2                	shl    %cl,%edx
f0106ce0:	89 e9                	mov    %ebp,%ecx
f0106ce2:	d3 ef                	shr    %cl,%edi
f0106ce4:	09 d0                	or     %edx,%eax
f0106ce6:	89 fa                	mov    %edi,%edx
f0106ce8:	83 c4 14             	add    $0x14,%esp
f0106ceb:	5e                   	pop    %esi
f0106cec:	5f                   	pop    %edi
f0106ced:	5d                   	pop    %ebp
f0106cee:	c3                   	ret    
f0106cef:	90                   	nop
f0106cf0:	39 d7                	cmp    %edx,%edi
f0106cf2:	75 da                	jne    f0106cce <__umoddi3+0x10e>
f0106cf4:	8b 14 24             	mov    (%esp),%edx
f0106cf7:	89 c1                	mov    %eax,%ecx
f0106cf9:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f0106cfd:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0106d01:	eb cb                	jmp    f0106cce <__umoddi3+0x10e>
f0106d03:	90                   	nop
f0106d04:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106d08:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f0106d0c:	0f 82 0f ff ff ff    	jb     f0106c21 <__umoddi3+0x61>
f0106d12:	e9 1a ff ff ff       	jmp    f0106c31 <__umoddi3+0x71>
