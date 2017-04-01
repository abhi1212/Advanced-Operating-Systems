
obj/user/stresssched:     file format elf32-i386


Disassembly of section .text:

00800020 <_start>:
// starts us running when we are initially loaded into a new environment.
.text
.globl _start
_start:
	// See if we were started with arguments on the stack
	cmpl $USTACKTOP, %esp
  800020:	81 fc 00 e0 bf ee    	cmp    $0xeebfe000,%esp
	jne args_exist
  800026:	75 04                	jne    80002c <args_exist>

	// If not, push dummy argc/argv arguments.
	// This happens when we are loaded by the kernel,
	// because the kernel does not know about passing arguments.
	pushl $0
  800028:	6a 00                	push   $0x0
	pushl $0
  80002a:	6a 00                	push   $0x0

0080002c <args_exist>:

args_exist:
	call libmain
  80002c:	e8 e0 00 00 00       	call   800111 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>
  800033:	66 90                	xchg   %ax,%ax
  800035:	66 90                	xchg   %ax,%ax
  800037:	66 90                	xchg   %ax,%ax
  800039:	66 90                	xchg   %ax,%ax
  80003b:	66 90                	xchg   %ax,%ax
  80003d:	66 90                	xchg   %ax,%ax
  80003f:	90                   	nop

00800040 <umain>:

volatile int counter;

void
umain(int argc, char **argv)
{
  800040:	55                   	push   %ebp
  800041:	89 e5                	mov    %esp,%ebp
  800043:	56                   	push   %esi
  800044:	53                   	push   %ebx
  800045:	83 ec 10             	sub    $0x10,%esp
	int i, j;
	int seen;
	envid_t parent = sys_getenvid();
  800048:	e8 18 0c 00 00       	call   800c65 <sys_getenvid>
  80004d:	89 c6                	mov    %eax,%esi

	// Fork several environments
	for (i = 0; i < 20; i++)
  80004f:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (fork() == 0)
  800054:	e8 8c 0f 00 00       	call   800fe5 <fork>
  800059:	85 c0                	test   %eax,%eax
  80005b:	74 0a                	je     800067 <umain+0x27>
	int i, j;
	int seen;
	envid_t parent = sys_getenvid();

	// Fork several environments
	for (i = 0; i < 20; i++)
  80005d:	83 c3 01             	add    $0x1,%ebx
  800060:	83 fb 14             	cmp    $0x14,%ebx
  800063:	75 ef                	jne    800054 <umain+0x14>
  800065:	eb 16                	jmp    80007d <umain+0x3d>
		if (fork() == 0)
			break;
	if (i == 20) {
  800067:	83 fb 14             	cmp    $0x14,%ebx
  80006a:	74 11                	je     80007d <umain+0x3d>
		sys_yield();
		return;
	}

	// Wait for the parent to finish forking
	while (envs[ENVX(parent)].env_status != ENV_FREE)
  80006c:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
  800072:	6b d6 7c             	imul   $0x7c,%esi,%edx
  800075:	81 c2 04 00 c0 ee    	add    $0xeec00004,%edx
  80007b:	eb 0c                	jmp    800089 <umain+0x49>
	// Fork several environments
	for (i = 0; i < 20; i++)
		if (fork() == 0)
			break;
	if (i == 20) {
		sys_yield();
  80007d:	e8 02 0c 00 00       	call   800c84 <sys_yield>
		return;
  800082:	e9 83 00 00 00       	jmp    80010a <umain+0xca>
	}

	// Wait for the parent to finish forking
	while (envs[ENVX(parent)].env_status != ENV_FREE)
		asm volatile("pause");
  800087:	f3 90                	pause  
		sys_yield();
		return;
	}

	// Wait for the parent to finish forking
	while (envs[ENVX(parent)].env_status != ENV_FREE)
  800089:	8b 42 50             	mov    0x50(%edx),%eax
  80008c:	85 c0                	test   %eax,%eax
  80008e:	66 90                	xchg   %ax,%ax
  800090:	75 f5                	jne    800087 <umain+0x47>
  800092:	bb 0a 00 00 00       	mov    $0xa,%ebx
		asm volatile("pause");

	// Check that one environment doesn't run on two CPUs at once
	for (i = 0; i < 10; i++) {
		sys_yield();
  800097:	e8 e8 0b 00 00       	call   800c84 <sys_yield>
  80009c:	b8 10 27 00 00       	mov    $0x2710,%eax
		for (j = 0; j < 10000; j++)
			counter++;
  8000a1:	8b 15 04 20 80 00    	mov    0x802004,%edx
  8000a7:	83 c2 01             	add    $0x1,%edx
  8000aa:	89 15 04 20 80 00    	mov    %edx,0x802004
		asm volatile("pause");

	// Check that one environment doesn't run on two CPUs at once
	for (i = 0; i < 10; i++) {
		sys_yield();
		for (j = 0; j < 10000; j++)
  8000b0:	83 e8 01             	sub    $0x1,%eax
  8000b3:	75 ec                	jne    8000a1 <umain+0x61>
	// Wait for the parent to finish forking
	while (envs[ENVX(parent)].env_status != ENV_FREE)
		asm volatile("pause");

	// Check that one environment doesn't run on two CPUs at once
	for (i = 0; i < 10; i++) {
  8000b5:	83 eb 01             	sub    $0x1,%ebx
  8000b8:	75 dd                	jne    800097 <umain+0x57>
		sys_yield();
		for (j = 0; j < 10000; j++)
			counter++;
	}

	if (counter != 10*10000)
  8000ba:	a1 04 20 80 00       	mov    0x802004,%eax
  8000bf:	3d a0 86 01 00       	cmp    $0x186a0,%eax
  8000c4:	74 25                	je     8000eb <umain+0xab>
		panic("ran on two CPUs at once (counter is %d)", counter);
  8000c6:	a1 04 20 80 00       	mov    0x802004,%eax
  8000cb:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8000cf:	c7 44 24 08 e0 15 80 	movl   $0x8015e0,0x8(%esp)
  8000d6:	00 
  8000d7:	c7 44 24 04 21 00 00 	movl   $0x21,0x4(%esp)
  8000de:	00 
  8000df:	c7 04 24 08 16 80 00 	movl   $0x801608,(%esp)
  8000e6:	e8 82 00 00 00       	call   80016d <_panic>

	// Check that we see environments running on different CPUs
	cprintf("[%08x] stresssched on CPU %d\n", thisenv->env_id, thisenv->env_cpunum);
  8000eb:	a1 08 20 80 00       	mov    0x802008,%eax
  8000f0:	8b 50 5c             	mov    0x5c(%eax),%edx
  8000f3:	8b 40 48             	mov    0x48(%eax),%eax
  8000f6:	89 54 24 08          	mov    %edx,0x8(%esp)
  8000fa:	89 44 24 04          	mov    %eax,0x4(%esp)
  8000fe:	c7 04 24 1b 16 80 00 	movl   $0x80161b,(%esp)
  800105:	e8 5c 01 00 00       	call   800266 <cprintf>

}
  80010a:	83 c4 10             	add    $0x10,%esp
  80010d:	5b                   	pop    %ebx
  80010e:	5e                   	pop    %esi
  80010f:	5d                   	pop    %ebp
  800110:	c3                   	ret    

00800111 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800111:	55                   	push   %ebp
  800112:	89 e5                	mov    %esp,%ebp
  800114:	56                   	push   %esi
  800115:	53                   	push   %ebx
  800116:	83 ec 10             	sub    $0x10,%esp
  800119:	8b 5d 08             	mov    0x8(%ebp),%ebx
  80011c:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	
	thisenv = (struct Env*)envs + ENVX(sys_getenvid());
  80011f:	e8 41 0b 00 00       	call   800c65 <sys_getenvid>
  800124:	25 ff 03 00 00       	and    $0x3ff,%eax
  800129:	6b c0 7c             	imul   $0x7c,%eax,%eax
  80012c:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800131:	a3 08 20 80 00       	mov    %eax,0x802008

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800136:	85 db                	test   %ebx,%ebx
  800138:	7e 07                	jle    800141 <libmain+0x30>
		binaryname = argv[0];
  80013a:	8b 06                	mov    (%esi),%eax
  80013c:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800141:	89 74 24 04          	mov    %esi,0x4(%esp)
  800145:	89 1c 24             	mov    %ebx,(%esp)
  800148:	e8 f3 fe ff ff       	call   800040 <umain>

	// exit gracefully
	exit();
  80014d:	e8 07 00 00 00       	call   800159 <exit>
}
  800152:	83 c4 10             	add    $0x10,%esp
  800155:	5b                   	pop    %ebx
  800156:	5e                   	pop    %esi
  800157:	5d                   	pop    %ebp
  800158:	c3                   	ret    

00800159 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800159:	55                   	push   %ebp
  80015a:	89 e5                	mov    %esp,%ebp
  80015c:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  80015f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800166:	e8 a8 0a 00 00       	call   800c13 <sys_env_destroy>
}
  80016b:	c9                   	leave  
  80016c:	c3                   	ret    

0080016d <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  80016d:	55                   	push   %ebp
  80016e:	89 e5                	mov    %esp,%ebp
  800170:	56                   	push   %esi
  800171:	53                   	push   %ebx
  800172:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  800175:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800178:	8b 35 00 20 80 00    	mov    0x802000,%esi
  80017e:	e8 e2 0a 00 00       	call   800c65 <sys_getenvid>
  800183:	8b 55 0c             	mov    0xc(%ebp),%edx
  800186:	89 54 24 10          	mov    %edx,0x10(%esp)
  80018a:	8b 55 08             	mov    0x8(%ebp),%edx
  80018d:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800191:	89 74 24 08          	mov    %esi,0x8(%esp)
  800195:	89 44 24 04          	mov    %eax,0x4(%esp)
  800199:	c7 04 24 44 16 80 00 	movl   $0x801644,(%esp)
  8001a0:	e8 c1 00 00 00       	call   800266 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  8001a5:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8001a9:	8b 45 10             	mov    0x10(%ebp),%eax
  8001ac:	89 04 24             	mov    %eax,(%esp)
  8001af:	e8 51 00 00 00       	call   800205 <vcprintf>
	cprintf("\n");
  8001b4:	c7 04 24 37 16 80 00 	movl   $0x801637,(%esp)
  8001bb:	e8 a6 00 00 00       	call   800266 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8001c0:	cc                   	int3   
  8001c1:	eb fd                	jmp    8001c0 <_panic+0x53>

008001c3 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8001c3:	55                   	push   %ebp
  8001c4:	89 e5                	mov    %esp,%ebp
  8001c6:	53                   	push   %ebx
  8001c7:	83 ec 14             	sub    $0x14,%esp
  8001ca:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8001cd:	8b 13                	mov    (%ebx),%edx
  8001cf:	8d 42 01             	lea    0x1(%edx),%eax
  8001d2:	89 03                	mov    %eax,(%ebx)
  8001d4:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001d7:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8001db:	3d ff 00 00 00       	cmp    $0xff,%eax
  8001e0:	75 19                	jne    8001fb <putch+0x38>
		sys_cputs(b->buf, b->idx);
  8001e2:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  8001e9:	00 
  8001ea:	8d 43 08             	lea    0x8(%ebx),%eax
  8001ed:	89 04 24             	mov    %eax,(%esp)
  8001f0:	e8 e1 09 00 00       	call   800bd6 <sys_cputs>
		b->idx = 0;
  8001f5:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  8001fb:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001ff:	83 c4 14             	add    $0x14,%esp
  800202:	5b                   	pop    %ebx
  800203:	5d                   	pop    %ebp
  800204:	c3                   	ret    

00800205 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800205:	55                   	push   %ebp
  800206:	89 e5                	mov    %esp,%ebp
  800208:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  80020e:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800215:	00 00 00 
	b.cnt = 0;
  800218:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  80021f:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800222:	8b 45 0c             	mov    0xc(%ebp),%eax
  800225:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800229:	8b 45 08             	mov    0x8(%ebp),%eax
  80022c:	89 44 24 08          	mov    %eax,0x8(%esp)
  800230:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800236:	89 44 24 04          	mov    %eax,0x4(%esp)
  80023a:	c7 04 24 c3 01 80 00 	movl   $0x8001c3,(%esp)
  800241:	e8 a8 01 00 00       	call   8003ee <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800246:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  80024c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800250:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800256:	89 04 24             	mov    %eax,(%esp)
  800259:	e8 78 09 00 00       	call   800bd6 <sys_cputs>

	return b.cnt;
}
  80025e:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800264:	c9                   	leave  
  800265:	c3                   	ret    

00800266 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800266:	55                   	push   %ebp
  800267:	89 e5                	mov    %esp,%ebp
  800269:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80026c:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  80026f:	89 44 24 04          	mov    %eax,0x4(%esp)
  800273:	8b 45 08             	mov    0x8(%ebp),%eax
  800276:	89 04 24             	mov    %eax,(%esp)
  800279:	e8 87 ff ff ff       	call   800205 <vcprintf>
	va_end(ap);

	return cnt;
}
  80027e:	c9                   	leave  
  80027f:	c3                   	ret    

00800280 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800280:	55                   	push   %ebp
  800281:	89 e5                	mov    %esp,%ebp
  800283:	57                   	push   %edi
  800284:	56                   	push   %esi
  800285:	53                   	push   %ebx
  800286:	83 ec 3c             	sub    $0x3c,%esp
  800289:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80028c:	89 d7                	mov    %edx,%edi
  80028e:	8b 45 08             	mov    0x8(%ebp),%eax
  800291:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800294:	8b 45 0c             	mov    0xc(%ebp),%eax
  800297:	89 c3                	mov    %eax,%ebx
  800299:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  80029c:	8b 45 10             	mov    0x10(%ebp),%eax
  80029f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8002a2:	b9 00 00 00 00       	mov    $0x0,%ecx
  8002a7:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8002aa:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8002ad:	39 d9                	cmp    %ebx,%ecx
  8002af:	72 05                	jb     8002b6 <printnum+0x36>
  8002b1:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  8002b4:	77 69                	ja     80031f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8002b6:	8b 4d 18             	mov    0x18(%ebp),%ecx
  8002b9:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  8002bd:	83 ee 01             	sub    $0x1,%esi
  8002c0:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8002c4:	89 44 24 08          	mov    %eax,0x8(%esp)
  8002c8:	8b 44 24 08          	mov    0x8(%esp),%eax
  8002cc:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8002d0:	89 c3                	mov    %eax,%ebx
  8002d2:	89 d6                	mov    %edx,%esi
  8002d4:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8002d7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8002da:	89 54 24 08          	mov    %edx,0x8(%esp)
  8002de:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  8002e2:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8002e5:	89 04 24             	mov    %eax,(%esp)
  8002e8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8002eb:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002ef:	e8 5c 10 00 00       	call   801350 <__udivdi3>
  8002f4:	89 d9                	mov    %ebx,%ecx
  8002f6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8002fa:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8002fe:	89 04 24             	mov    %eax,(%esp)
  800301:	89 54 24 04          	mov    %edx,0x4(%esp)
  800305:	89 fa                	mov    %edi,%edx
  800307:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80030a:	e8 71 ff ff ff       	call   800280 <printnum>
  80030f:	eb 1b                	jmp    80032c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800311:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800315:	8b 45 18             	mov    0x18(%ebp),%eax
  800318:	89 04 24             	mov    %eax,(%esp)
  80031b:	ff d3                	call   *%ebx
  80031d:	eb 03                	jmp    800322 <printnum+0xa2>
  80031f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800322:	83 ee 01             	sub    $0x1,%esi
  800325:	85 f6                	test   %esi,%esi
  800327:	7f e8                	jg     800311 <printnum+0x91>
  800329:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80032c:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800330:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800334:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800337:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80033a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80033e:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800342:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800345:	89 04 24             	mov    %eax,(%esp)
  800348:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80034b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80034f:	e8 2c 11 00 00       	call   801480 <__umoddi3>
  800354:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800358:	0f be 80 67 16 80 00 	movsbl 0x801667(%eax),%eax
  80035f:	89 04 24             	mov    %eax,(%esp)
  800362:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800365:	ff d0                	call   *%eax
}
  800367:	83 c4 3c             	add    $0x3c,%esp
  80036a:	5b                   	pop    %ebx
  80036b:	5e                   	pop    %esi
  80036c:	5f                   	pop    %edi
  80036d:	5d                   	pop    %ebp
  80036e:	c3                   	ret    

0080036f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  80036f:	55                   	push   %ebp
  800370:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800372:	83 fa 01             	cmp    $0x1,%edx
  800375:	7e 0e                	jle    800385 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800377:	8b 10                	mov    (%eax),%edx
  800379:	8d 4a 08             	lea    0x8(%edx),%ecx
  80037c:	89 08                	mov    %ecx,(%eax)
  80037e:	8b 02                	mov    (%edx),%eax
  800380:	8b 52 04             	mov    0x4(%edx),%edx
  800383:	eb 22                	jmp    8003a7 <getuint+0x38>
	else if (lflag)
  800385:	85 d2                	test   %edx,%edx
  800387:	74 10                	je     800399 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800389:	8b 10                	mov    (%eax),%edx
  80038b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80038e:	89 08                	mov    %ecx,(%eax)
  800390:	8b 02                	mov    (%edx),%eax
  800392:	ba 00 00 00 00       	mov    $0x0,%edx
  800397:	eb 0e                	jmp    8003a7 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800399:	8b 10                	mov    (%eax),%edx
  80039b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80039e:	89 08                	mov    %ecx,(%eax)
  8003a0:	8b 02                	mov    (%edx),%eax
  8003a2:	ba 00 00 00 00       	mov    $0x0,%edx
}
  8003a7:	5d                   	pop    %ebp
  8003a8:	c3                   	ret    

008003a9 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8003a9:	55                   	push   %ebp
  8003aa:	89 e5                	mov    %esp,%ebp
  8003ac:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8003af:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8003b3:	8b 10                	mov    (%eax),%edx
  8003b5:	3b 50 04             	cmp    0x4(%eax),%edx
  8003b8:	73 0a                	jae    8003c4 <sprintputch+0x1b>
		*b->buf++ = ch;
  8003ba:	8d 4a 01             	lea    0x1(%edx),%ecx
  8003bd:	89 08                	mov    %ecx,(%eax)
  8003bf:	8b 45 08             	mov    0x8(%ebp),%eax
  8003c2:	88 02                	mov    %al,(%edx)
}
  8003c4:	5d                   	pop    %ebp
  8003c5:	c3                   	ret    

008003c6 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8003c6:	55                   	push   %ebp
  8003c7:	89 e5                	mov    %esp,%ebp
  8003c9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  8003cc:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8003cf:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8003d3:	8b 45 10             	mov    0x10(%ebp),%eax
  8003d6:	89 44 24 08          	mov    %eax,0x8(%esp)
  8003da:	8b 45 0c             	mov    0xc(%ebp),%eax
  8003dd:	89 44 24 04          	mov    %eax,0x4(%esp)
  8003e1:	8b 45 08             	mov    0x8(%ebp),%eax
  8003e4:	89 04 24             	mov    %eax,(%esp)
  8003e7:	e8 02 00 00 00       	call   8003ee <vprintfmt>
	va_end(ap);
}
  8003ec:	c9                   	leave  
  8003ed:	c3                   	ret    

008003ee <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8003ee:	55                   	push   %ebp
  8003ef:	89 e5                	mov    %esp,%ebp
  8003f1:	57                   	push   %edi
  8003f2:	56                   	push   %esi
  8003f3:	53                   	push   %ebx
  8003f4:	83 ec 3c             	sub    $0x3c,%esp
  8003f7:	8b 7d 0c             	mov    0xc(%ebp),%edi
  8003fa:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8003fd:	eb 14                	jmp    800413 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8003ff:	85 c0                	test   %eax,%eax
  800401:	0f 84 b3 03 00 00    	je     8007ba <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
  800407:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80040b:	89 04 24             	mov    %eax,(%esp)
  80040e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800411:	89 f3                	mov    %esi,%ebx
  800413:	8d 73 01             	lea    0x1(%ebx),%esi
  800416:	0f b6 03             	movzbl (%ebx),%eax
  800419:	83 f8 25             	cmp    $0x25,%eax
  80041c:	75 e1                	jne    8003ff <vprintfmt+0x11>
  80041e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
  800422:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  800429:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
  800430:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800437:	ba 00 00 00 00       	mov    $0x0,%edx
  80043c:	eb 1d                	jmp    80045b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80043e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
  800440:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
  800444:	eb 15                	jmp    80045b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800446:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800448:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
  80044c:	eb 0d                	jmp    80045b <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  80044e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800451:	89 45 dc             	mov    %eax,-0x24(%ebp)
  800454:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80045b:	8d 5e 01             	lea    0x1(%esi),%ebx
  80045e:	0f b6 0e             	movzbl (%esi),%ecx
  800461:	0f b6 c1             	movzbl %cl,%eax
  800464:	83 e9 23             	sub    $0x23,%ecx
  800467:	80 f9 55             	cmp    $0x55,%cl
  80046a:	0f 87 2a 03 00 00    	ja     80079a <vprintfmt+0x3ac>
  800470:	0f b6 c9             	movzbl %cl,%ecx
  800473:	ff 24 8d 20 17 80 00 	jmp    *0x801720(,%ecx,4)
  80047a:	89 de                	mov    %ebx,%esi
  80047c:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800481:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
  800484:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
  800488:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
  80048b:	8d 58 d0             	lea    -0x30(%eax),%ebx
  80048e:	83 fb 09             	cmp    $0x9,%ebx
  800491:	77 36                	ja     8004c9 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800493:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800496:	eb e9                	jmp    800481 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800498:	8b 45 14             	mov    0x14(%ebp),%eax
  80049b:	8d 48 04             	lea    0x4(%eax),%ecx
  80049e:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8004a1:	8b 00                	mov    (%eax),%eax
  8004a3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004a6:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8004a8:	eb 22                	jmp    8004cc <vprintfmt+0xde>
  8004aa:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8004ad:	85 c9                	test   %ecx,%ecx
  8004af:	b8 00 00 00 00       	mov    $0x0,%eax
  8004b4:	0f 49 c1             	cmovns %ecx,%eax
  8004b7:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004ba:	89 de                	mov    %ebx,%esi
  8004bc:	eb 9d                	jmp    80045b <vprintfmt+0x6d>
  8004be:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8004c0:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
  8004c7:	eb 92                	jmp    80045b <vprintfmt+0x6d>
  8004c9:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
  8004cc:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8004d0:	79 89                	jns    80045b <vprintfmt+0x6d>
  8004d2:	e9 77 ff ff ff       	jmp    80044e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8004d7:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004da:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8004dc:	e9 7a ff ff ff       	jmp    80045b <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8004e1:	8b 45 14             	mov    0x14(%ebp),%eax
  8004e4:	8d 50 04             	lea    0x4(%eax),%edx
  8004e7:	89 55 14             	mov    %edx,0x14(%ebp)
  8004ea:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8004ee:	8b 00                	mov    (%eax),%eax
  8004f0:	89 04 24             	mov    %eax,(%esp)
  8004f3:	ff 55 08             	call   *0x8(%ebp)
			break;
  8004f6:	e9 18 ff ff ff       	jmp    800413 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8004fb:	8b 45 14             	mov    0x14(%ebp),%eax
  8004fe:	8d 50 04             	lea    0x4(%eax),%edx
  800501:	89 55 14             	mov    %edx,0x14(%ebp)
  800504:	8b 00                	mov    (%eax),%eax
  800506:	99                   	cltd   
  800507:	31 d0                	xor    %edx,%eax
  800509:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80050b:	83 f8 08             	cmp    $0x8,%eax
  80050e:	7f 0b                	jg     80051b <vprintfmt+0x12d>
  800510:	8b 14 85 80 18 80 00 	mov    0x801880(,%eax,4),%edx
  800517:	85 d2                	test   %edx,%edx
  800519:	75 20                	jne    80053b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
  80051b:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80051f:	c7 44 24 08 7f 16 80 	movl   $0x80167f,0x8(%esp)
  800526:	00 
  800527:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80052b:	8b 45 08             	mov    0x8(%ebp),%eax
  80052e:	89 04 24             	mov    %eax,(%esp)
  800531:	e8 90 fe ff ff       	call   8003c6 <printfmt>
  800536:	e9 d8 fe ff ff       	jmp    800413 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  80053b:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80053f:	c7 44 24 08 88 16 80 	movl   $0x801688,0x8(%esp)
  800546:	00 
  800547:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80054b:	8b 45 08             	mov    0x8(%ebp),%eax
  80054e:	89 04 24             	mov    %eax,(%esp)
  800551:	e8 70 fe ff ff       	call   8003c6 <printfmt>
  800556:	e9 b8 fe ff ff       	jmp    800413 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80055b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  80055e:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800561:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800564:	8b 45 14             	mov    0x14(%ebp),%eax
  800567:	8d 50 04             	lea    0x4(%eax),%edx
  80056a:	89 55 14             	mov    %edx,0x14(%ebp)
  80056d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
  80056f:	85 f6                	test   %esi,%esi
  800571:	b8 78 16 80 00       	mov    $0x801678,%eax
  800576:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
  800579:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
  80057d:	0f 84 97 00 00 00    	je     80061a <vprintfmt+0x22c>
  800583:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  800587:	0f 8e 9b 00 00 00    	jle    800628 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
  80058d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800591:	89 34 24             	mov    %esi,(%esp)
  800594:	e8 cf 02 00 00       	call   800868 <strnlen>
  800599:	8b 55 d0             	mov    -0x30(%ebp),%edx
  80059c:	29 c2                	sub    %eax,%edx
  80059e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
  8005a1:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
  8005a5:	89 45 dc             	mov    %eax,-0x24(%ebp)
  8005a8:	89 75 d8             	mov    %esi,-0x28(%ebp)
  8005ab:	8b 75 08             	mov    0x8(%ebp),%esi
  8005ae:	89 5d 10             	mov    %ebx,0x10(%ebp)
  8005b1:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8005b3:	eb 0f                	jmp    8005c4 <vprintfmt+0x1d6>
					putch(padc, putdat);
  8005b5:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8005b9:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8005bc:	89 04 24             	mov    %eax,(%esp)
  8005bf:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8005c1:	83 eb 01             	sub    $0x1,%ebx
  8005c4:	85 db                	test   %ebx,%ebx
  8005c6:	7f ed                	jg     8005b5 <vprintfmt+0x1c7>
  8005c8:	8b 75 d8             	mov    -0x28(%ebp),%esi
  8005cb:	8b 55 d0             	mov    -0x30(%ebp),%edx
  8005ce:	85 d2                	test   %edx,%edx
  8005d0:	b8 00 00 00 00       	mov    $0x0,%eax
  8005d5:	0f 49 c2             	cmovns %edx,%eax
  8005d8:	29 c2                	sub    %eax,%edx
  8005da:	89 7d 0c             	mov    %edi,0xc(%ebp)
  8005dd:	89 d7                	mov    %edx,%edi
  8005df:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  8005e2:	eb 50                	jmp    800634 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8005e4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8005e8:	74 1e                	je     800608 <vprintfmt+0x21a>
  8005ea:	0f be d2             	movsbl %dl,%edx
  8005ed:	83 ea 20             	sub    $0x20,%edx
  8005f0:	83 fa 5e             	cmp    $0x5e,%edx
  8005f3:	76 13                	jbe    800608 <vprintfmt+0x21a>
					putch('?', putdat);
  8005f5:	8b 45 0c             	mov    0xc(%ebp),%eax
  8005f8:	89 44 24 04          	mov    %eax,0x4(%esp)
  8005fc:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800603:	ff 55 08             	call   *0x8(%ebp)
  800606:	eb 0d                	jmp    800615 <vprintfmt+0x227>
				else
					putch(ch, putdat);
  800608:	8b 55 0c             	mov    0xc(%ebp),%edx
  80060b:	89 54 24 04          	mov    %edx,0x4(%esp)
  80060f:	89 04 24             	mov    %eax,(%esp)
  800612:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800615:	83 ef 01             	sub    $0x1,%edi
  800618:	eb 1a                	jmp    800634 <vprintfmt+0x246>
  80061a:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80061d:	8b 7d dc             	mov    -0x24(%ebp),%edi
  800620:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800623:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800626:	eb 0c                	jmp    800634 <vprintfmt+0x246>
  800628:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80062b:	8b 7d dc             	mov    -0x24(%ebp),%edi
  80062e:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800631:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800634:	83 c6 01             	add    $0x1,%esi
  800637:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
  80063b:	0f be c2             	movsbl %dl,%eax
  80063e:	85 c0                	test   %eax,%eax
  800640:	74 27                	je     800669 <vprintfmt+0x27b>
  800642:	85 db                	test   %ebx,%ebx
  800644:	78 9e                	js     8005e4 <vprintfmt+0x1f6>
  800646:	83 eb 01             	sub    $0x1,%ebx
  800649:	79 99                	jns    8005e4 <vprintfmt+0x1f6>
  80064b:	89 f8                	mov    %edi,%eax
  80064d:	8b 7d 0c             	mov    0xc(%ebp),%edi
  800650:	8b 75 08             	mov    0x8(%ebp),%esi
  800653:	89 c3                	mov    %eax,%ebx
  800655:	eb 1a                	jmp    800671 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800657:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80065b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  800662:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800664:	83 eb 01             	sub    $0x1,%ebx
  800667:	eb 08                	jmp    800671 <vprintfmt+0x283>
  800669:	89 fb                	mov    %edi,%ebx
  80066b:	8b 75 08             	mov    0x8(%ebp),%esi
  80066e:	8b 7d 0c             	mov    0xc(%ebp),%edi
  800671:	85 db                	test   %ebx,%ebx
  800673:	7f e2                	jg     800657 <vprintfmt+0x269>
  800675:	89 75 08             	mov    %esi,0x8(%ebp)
  800678:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80067b:	e9 93 fd ff ff       	jmp    800413 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800680:	83 fa 01             	cmp    $0x1,%edx
  800683:	7e 16                	jle    80069b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
  800685:	8b 45 14             	mov    0x14(%ebp),%eax
  800688:	8d 50 08             	lea    0x8(%eax),%edx
  80068b:	89 55 14             	mov    %edx,0x14(%ebp)
  80068e:	8b 50 04             	mov    0x4(%eax),%edx
  800691:	8b 00                	mov    (%eax),%eax
  800693:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800696:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  800699:	eb 32                	jmp    8006cd <vprintfmt+0x2df>
	else if (lflag)
  80069b:	85 d2                	test   %edx,%edx
  80069d:	74 18                	je     8006b7 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
  80069f:	8b 45 14             	mov    0x14(%ebp),%eax
  8006a2:	8d 50 04             	lea    0x4(%eax),%edx
  8006a5:	89 55 14             	mov    %edx,0x14(%ebp)
  8006a8:	8b 30                	mov    (%eax),%esi
  8006aa:	89 75 e0             	mov    %esi,-0x20(%ebp)
  8006ad:	89 f0                	mov    %esi,%eax
  8006af:	c1 f8 1f             	sar    $0x1f,%eax
  8006b2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8006b5:	eb 16                	jmp    8006cd <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
  8006b7:	8b 45 14             	mov    0x14(%ebp),%eax
  8006ba:	8d 50 04             	lea    0x4(%eax),%edx
  8006bd:	89 55 14             	mov    %edx,0x14(%ebp)
  8006c0:	8b 30                	mov    (%eax),%esi
  8006c2:	89 75 e0             	mov    %esi,-0x20(%ebp)
  8006c5:	89 f0                	mov    %esi,%eax
  8006c7:	c1 f8 1f             	sar    $0x1f,%eax
  8006ca:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8006cd:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8006d0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8006d3:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8006d8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8006dc:	0f 89 80 00 00 00    	jns    800762 <vprintfmt+0x374>
				putch('-', putdat);
  8006e2:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8006e6:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  8006ed:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  8006f0:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8006f3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  8006f6:	f7 d8                	neg    %eax
  8006f8:	83 d2 00             	adc    $0x0,%edx
  8006fb:	f7 da                	neg    %edx
			}
			base = 10;
  8006fd:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800702:	eb 5e                	jmp    800762 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800704:	8d 45 14             	lea    0x14(%ebp),%eax
  800707:	e8 63 fc ff ff       	call   80036f <getuint>
			base = 10;
  80070c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800711:	eb 4f                	jmp    800762 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  800713:	8d 45 14             	lea    0x14(%ebp),%eax
  800716:	e8 54 fc ff ff       	call   80036f <getuint>
			base = 8;
  80071b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800720:	eb 40                	jmp    800762 <vprintfmt+0x374>

		// pointer
		case 'p':
			putch('0', putdat);
  800722:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800726:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  80072d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  800730:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800734:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  80073b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80073e:	8b 45 14             	mov    0x14(%ebp),%eax
  800741:	8d 50 04             	lea    0x4(%eax),%edx
  800744:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800747:	8b 00                	mov    (%eax),%eax
  800749:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  80074e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800753:	eb 0d                	jmp    800762 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800755:	8d 45 14             	lea    0x14(%ebp),%eax
  800758:	e8 12 fc ff ff       	call   80036f <getuint>
			base = 16;
  80075d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800762:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
  800766:	89 74 24 10          	mov    %esi,0x10(%esp)
  80076a:	8b 75 dc             	mov    -0x24(%ebp),%esi
  80076d:	89 74 24 0c          	mov    %esi,0xc(%esp)
  800771:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800775:	89 04 24             	mov    %eax,(%esp)
  800778:	89 54 24 04          	mov    %edx,0x4(%esp)
  80077c:	89 fa                	mov    %edi,%edx
  80077e:	8b 45 08             	mov    0x8(%ebp),%eax
  800781:	e8 fa fa ff ff       	call   800280 <printnum>
			break;
  800786:	e9 88 fc ff ff       	jmp    800413 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80078b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80078f:	89 04 24             	mov    %eax,(%esp)
  800792:	ff 55 08             	call   *0x8(%ebp)
			break;
  800795:	e9 79 fc ff ff       	jmp    800413 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  80079a:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80079e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  8007a5:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  8007a8:	89 f3                	mov    %esi,%ebx
  8007aa:	eb 03                	jmp    8007af <vprintfmt+0x3c1>
  8007ac:	83 eb 01             	sub    $0x1,%ebx
  8007af:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
  8007b3:	75 f7                	jne    8007ac <vprintfmt+0x3be>
  8007b5:	e9 59 fc ff ff       	jmp    800413 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  8007ba:	83 c4 3c             	add    $0x3c,%esp
  8007bd:	5b                   	pop    %ebx
  8007be:	5e                   	pop    %esi
  8007bf:	5f                   	pop    %edi
  8007c0:	5d                   	pop    %ebp
  8007c1:	c3                   	ret    

008007c2 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8007c2:	55                   	push   %ebp
  8007c3:	89 e5                	mov    %esp,%ebp
  8007c5:	83 ec 28             	sub    $0x28,%esp
  8007c8:	8b 45 08             	mov    0x8(%ebp),%eax
  8007cb:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8007ce:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8007d1:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8007d5:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8007d8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8007df:	85 c0                	test   %eax,%eax
  8007e1:	74 30                	je     800813 <vsnprintf+0x51>
  8007e3:	85 d2                	test   %edx,%edx
  8007e5:	7e 2c                	jle    800813 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8007e7:	8b 45 14             	mov    0x14(%ebp),%eax
  8007ea:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8007ee:	8b 45 10             	mov    0x10(%ebp),%eax
  8007f1:	89 44 24 08          	mov    %eax,0x8(%esp)
  8007f5:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8007f8:	89 44 24 04          	mov    %eax,0x4(%esp)
  8007fc:	c7 04 24 a9 03 80 00 	movl   $0x8003a9,(%esp)
  800803:	e8 e6 fb ff ff       	call   8003ee <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800808:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80080b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80080e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800811:	eb 05                	jmp    800818 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800813:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800818:	c9                   	leave  
  800819:	c3                   	ret    

0080081a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80081a:	55                   	push   %ebp
  80081b:	89 e5                	mov    %esp,%ebp
  80081d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800820:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800823:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800827:	8b 45 10             	mov    0x10(%ebp),%eax
  80082a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80082e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800831:	89 44 24 04          	mov    %eax,0x4(%esp)
  800835:	8b 45 08             	mov    0x8(%ebp),%eax
  800838:	89 04 24             	mov    %eax,(%esp)
  80083b:	e8 82 ff ff ff       	call   8007c2 <vsnprintf>
	va_end(ap);

	return rc;
}
  800840:	c9                   	leave  
  800841:	c3                   	ret    
  800842:	66 90                	xchg   %ax,%ax
  800844:	66 90                	xchg   %ax,%ax
  800846:	66 90                	xchg   %ax,%ax
  800848:	66 90                	xchg   %ax,%ax
  80084a:	66 90                	xchg   %ax,%ax
  80084c:	66 90                	xchg   %ax,%ax
  80084e:	66 90                	xchg   %ax,%ax

00800850 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800850:	55                   	push   %ebp
  800851:	89 e5                	mov    %esp,%ebp
  800853:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800856:	b8 00 00 00 00       	mov    $0x0,%eax
  80085b:	eb 03                	jmp    800860 <strlen+0x10>
		n++;
  80085d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800860:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800864:	75 f7                	jne    80085d <strlen+0xd>
		n++;
	return n;
}
  800866:	5d                   	pop    %ebp
  800867:	c3                   	ret    

00800868 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800868:	55                   	push   %ebp
  800869:	89 e5                	mov    %esp,%ebp
  80086b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80086e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800871:	b8 00 00 00 00       	mov    $0x0,%eax
  800876:	eb 03                	jmp    80087b <strnlen+0x13>
		n++;
  800878:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80087b:	39 d0                	cmp    %edx,%eax
  80087d:	74 06                	je     800885 <strnlen+0x1d>
  80087f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  800883:	75 f3                	jne    800878 <strnlen+0x10>
		n++;
	return n;
}
  800885:	5d                   	pop    %ebp
  800886:	c3                   	ret    

00800887 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800887:	55                   	push   %ebp
  800888:	89 e5                	mov    %esp,%ebp
  80088a:	53                   	push   %ebx
  80088b:	8b 45 08             	mov    0x8(%ebp),%eax
  80088e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800891:	89 c2                	mov    %eax,%edx
  800893:	83 c2 01             	add    $0x1,%edx
  800896:	83 c1 01             	add    $0x1,%ecx
  800899:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  80089d:	88 5a ff             	mov    %bl,-0x1(%edx)
  8008a0:	84 db                	test   %bl,%bl
  8008a2:	75 ef                	jne    800893 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8008a4:	5b                   	pop    %ebx
  8008a5:	5d                   	pop    %ebp
  8008a6:	c3                   	ret    

008008a7 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8008a7:	55                   	push   %ebp
  8008a8:	89 e5                	mov    %esp,%ebp
  8008aa:	53                   	push   %ebx
  8008ab:	83 ec 08             	sub    $0x8,%esp
  8008ae:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8008b1:	89 1c 24             	mov    %ebx,(%esp)
  8008b4:	e8 97 ff ff ff       	call   800850 <strlen>
	strcpy(dst + len, src);
  8008b9:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008bc:	89 54 24 04          	mov    %edx,0x4(%esp)
  8008c0:	01 d8                	add    %ebx,%eax
  8008c2:	89 04 24             	mov    %eax,(%esp)
  8008c5:	e8 bd ff ff ff       	call   800887 <strcpy>
	return dst;
}
  8008ca:	89 d8                	mov    %ebx,%eax
  8008cc:	83 c4 08             	add    $0x8,%esp
  8008cf:	5b                   	pop    %ebx
  8008d0:	5d                   	pop    %ebp
  8008d1:	c3                   	ret    

008008d2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8008d2:	55                   	push   %ebp
  8008d3:	89 e5                	mov    %esp,%ebp
  8008d5:	56                   	push   %esi
  8008d6:	53                   	push   %ebx
  8008d7:	8b 75 08             	mov    0x8(%ebp),%esi
  8008da:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8008dd:	89 f3                	mov    %esi,%ebx
  8008df:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8008e2:	89 f2                	mov    %esi,%edx
  8008e4:	eb 0f                	jmp    8008f5 <strncpy+0x23>
		*dst++ = *src;
  8008e6:	83 c2 01             	add    $0x1,%edx
  8008e9:	0f b6 01             	movzbl (%ecx),%eax
  8008ec:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8008ef:	80 39 01             	cmpb   $0x1,(%ecx)
  8008f2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8008f5:	39 da                	cmp    %ebx,%edx
  8008f7:	75 ed                	jne    8008e6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8008f9:	89 f0                	mov    %esi,%eax
  8008fb:	5b                   	pop    %ebx
  8008fc:	5e                   	pop    %esi
  8008fd:	5d                   	pop    %ebp
  8008fe:	c3                   	ret    

008008ff <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8008ff:	55                   	push   %ebp
  800900:	89 e5                	mov    %esp,%ebp
  800902:	56                   	push   %esi
  800903:	53                   	push   %ebx
  800904:	8b 75 08             	mov    0x8(%ebp),%esi
  800907:	8b 55 0c             	mov    0xc(%ebp),%edx
  80090a:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80090d:	89 f0                	mov    %esi,%eax
  80090f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800913:	85 c9                	test   %ecx,%ecx
  800915:	75 0b                	jne    800922 <strlcpy+0x23>
  800917:	eb 1d                	jmp    800936 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800919:	83 c0 01             	add    $0x1,%eax
  80091c:	83 c2 01             	add    $0x1,%edx
  80091f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800922:	39 d8                	cmp    %ebx,%eax
  800924:	74 0b                	je     800931 <strlcpy+0x32>
  800926:	0f b6 0a             	movzbl (%edx),%ecx
  800929:	84 c9                	test   %cl,%cl
  80092b:	75 ec                	jne    800919 <strlcpy+0x1a>
  80092d:	89 c2                	mov    %eax,%edx
  80092f:	eb 02                	jmp    800933 <strlcpy+0x34>
  800931:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
  800933:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  800936:	29 f0                	sub    %esi,%eax
}
  800938:	5b                   	pop    %ebx
  800939:	5e                   	pop    %esi
  80093a:	5d                   	pop    %ebp
  80093b:	c3                   	ret    

0080093c <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80093c:	55                   	push   %ebp
  80093d:	89 e5                	mov    %esp,%ebp
  80093f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800942:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800945:	eb 06                	jmp    80094d <strcmp+0x11>
		p++, q++;
  800947:	83 c1 01             	add    $0x1,%ecx
  80094a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80094d:	0f b6 01             	movzbl (%ecx),%eax
  800950:	84 c0                	test   %al,%al
  800952:	74 04                	je     800958 <strcmp+0x1c>
  800954:	3a 02                	cmp    (%edx),%al
  800956:	74 ef                	je     800947 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800958:	0f b6 c0             	movzbl %al,%eax
  80095b:	0f b6 12             	movzbl (%edx),%edx
  80095e:	29 d0                	sub    %edx,%eax
}
  800960:	5d                   	pop    %ebp
  800961:	c3                   	ret    

00800962 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800962:	55                   	push   %ebp
  800963:	89 e5                	mov    %esp,%ebp
  800965:	53                   	push   %ebx
  800966:	8b 45 08             	mov    0x8(%ebp),%eax
  800969:	8b 55 0c             	mov    0xc(%ebp),%edx
  80096c:	89 c3                	mov    %eax,%ebx
  80096e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800971:	eb 06                	jmp    800979 <strncmp+0x17>
		n--, p++, q++;
  800973:	83 c0 01             	add    $0x1,%eax
  800976:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800979:	39 d8                	cmp    %ebx,%eax
  80097b:	74 15                	je     800992 <strncmp+0x30>
  80097d:	0f b6 08             	movzbl (%eax),%ecx
  800980:	84 c9                	test   %cl,%cl
  800982:	74 04                	je     800988 <strncmp+0x26>
  800984:	3a 0a                	cmp    (%edx),%cl
  800986:	74 eb                	je     800973 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800988:	0f b6 00             	movzbl (%eax),%eax
  80098b:	0f b6 12             	movzbl (%edx),%edx
  80098e:	29 d0                	sub    %edx,%eax
  800990:	eb 05                	jmp    800997 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800992:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800997:	5b                   	pop    %ebx
  800998:	5d                   	pop    %ebp
  800999:	c3                   	ret    

0080099a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  80099a:	55                   	push   %ebp
  80099b:	89 e5                	mov    %esp,%ebp
  80099d:	8b 45 08             	mov    0x8(%ebp),%eax
  8009a0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8009a4:	eb 07                	jmp    8009ad <strchr+0x13>
		if (*s == c)
  8009a6:	38 ca                	cmp    %cl,%dl
  8009a8:	74 0f                	je     8009b9 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8009aa:	83 c0 01             	add    $0x1,%eax
  8009ad:	0f b6 10             	movzbl (%eax),%edx
  8009b0:	84 d2                	test   %dl,%dl
  8009b2:	75 f2                	jne    8009a6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8009b4:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009b9:	5d                   	pop    %ebp
  8009ba:	c3                   	ret    

008009bb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8009bb:	55                   	push   %ebp
  8009bc:	89 e5                	mov    %esp,%ebp
  8009be:	8b 45 08             	mov    0x8(%ebp),%eax
  8009c1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8009c5:	eb 07                	jmp    8009ce <strfind+0x13>
		if (*s == c)
  8009c7:	38 ca                	cmp    %cl,%dl
  8009c9:	74 0a                	je     8009d5 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  8009cb:	83 c0 01             	add    $0x1,%eax
  8009ce:	0f b6 10             	movzbl (%eax),%edx
  8009d1:	84 d2                	test   %dl,%dl
  8009d3:	75 f2                	jne    8009c7 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
  8009d5:	5d                   	pop    %ebp
  8009d6:	c3                   	ret    

008009d7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8009d7:	55                   	push   %ebp
  8009d8:	89 e5                	mov    %esp,%ebp
  8009da:	57                   	push   %edi
  8009db:	56                   	push   %esi
  8009dc:	53                   	push   %ebx
  8009dd:	8b 7d 08             	mov    0x8(%ebp),%edi
  8009e0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8009e3:	85 c9                	test   %ecx,%ecx
  8009e5:	74 36                	je     800a1d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8009e7:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8009ed:	75 28                	jne    800a17 <memset+0x40>
  8009ef:	f6 c1 03             	test   $0x3,%cl
  8009f2:	75 23                	jne    800a17 <memset+0x40>
		c &= 0xFF;
  8009f4:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8009f8:	89 d3                	mov    %edx,%ebx
  8009fa:	c1 e3 08             	shl    $0x8,%ebx
  8009fd:	89 d6                	mov    %edx,%esi
  8009ff:	c1 e6 18             	shl    $0x18,%esi
  800a02:	89 d0                	mov    %edx,%eax
  800a04:	c1 e0 10             	shl    $0x10,%eax
  800a07:	09 f0                	or     %esi,%eax
  800a09:	09 c2                	or     %eax,%edx
  800a0b:	89 d0                	mov    %edx,%eax
  800a0d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800a0f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800a12:	fc                   	cld    
  800a13:	f3 ab                	rep stos %eax,%es:(%edi)
  800a15:	eb 06                	jmp    800a1d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800a17:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a1a:	fc                   	cld    
  800a1b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800a1d:	89 f8                	mov    %edi,%eax
  800a1f:	5b                   	pop    %ebx
  800a20:	5e                   	pop    %esi
  800a21:	5f                   	pop    %edi
  800a22:	5d                   	pop    %ebp
  800a23:	c3                   	ret    

00800a24 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800a24:	55                   	push   %ebp
  800a25:	89 e5                	mov    %esp,%ebp
  800a27:	57                   	push   %edi
  800a28:	56                   	push   %esi
  800a29:	8b 45 08             	mov    0x8(%ebp),%eax
  800a2c:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a2f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800a32:	39 c6                	cmp    %eax,%esi
  800a34:	73 35                	jae    800a6b <memmove+0x47>
  800a36:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800a39:	39 d0                	cmp    %edx,%eax
  800a3b:	73 2e                	jae    800a6b <memmove+0x47>
		s += n;
		d += n;
  800a3d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
  800a40:	89 d6                	mov    %edx,%esi
  800a42:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a44:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800a4a:	75 13                	jne    800a5f <memmove+0x3b>
  800a4c:	f6 c1 03             	test   $0x3,%cl
  800a4f:	75 0e                	jne    800a5f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800a51:	83 ef 04             	sub    $0x4,%edi
  800a54:	8d 72 fc             	lea    -0x4(%edx),%esi
  800a57:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800a5a:	fd                   	std    
  800a5b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a5d:	eb 09                	jmp    800a68 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800a5f:	83 ef 01             	sub    $0x1,%edi
  800a62:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800a65:	fd                   	std    
  800a66:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800a68:	fc                   	cld    
  800a69:	eb 1d                	jmp    800a88 <memmove+0x64>
  800a6b:	89 f2                	mov    %esi,%edx
  800a6d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a6f:	f6 c2 03             	test   $0x3,%dl
  800a72:	75 0f                	jne    800a83 <memmove+0x5f>
  800a74:	f6 c1 03             	test   $0x3,%cl
  800a77:	75 0a                	jne    800a83 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800a79:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800a7c:	89 c7                	mov    %eax,%edi
  800a7e:	fc                   	cld    
  800a7f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a81:	eb 05                	jmp    800a88 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800a83:	89 c7                	mov    %eax,%edi
  800a85:	fc                   	cld    
  800a86:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800a88:	5e                   	pop    %esi
  800a89:	5f                   	pop    %edi
  800a8a:	5d                   	pop    %ebp
  800a8b:	c3                   	ret    

00800a8c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800a8c:	55                   	push   %ebp
  800a8d:	89 e5                	mov    %esp,%ebp
  800a8f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800a92:	8b 45 10             	mov    0x10(%ebp),%eax
  800a95:	89 44 24 08          	mov    %eax,0x8(%esp)
  800a99:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a9c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800aa0:	8b 45 08             	mov    0x8(%ebp),%eax
  800aa3:	89 04 24             	mov    %eax,(%esp)
  800aa6:	e8 79 ff ff ff       	call   800a24 <memmove>
}
  800aab:	c9                   	leave  
  800aac:	c3                   	ret    

00800aad <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800aad:	55                   	push   %ebp
  800aae:	89 e5                	mov    %esp,%ebp
  800ab0:	56                   	push   %esi
  800ab1:	53                   	push   %ebx
  800ab2:	8b 55 08             	mov    0x8(%ebp),%edx
  800ab5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800ab8:	89 d6                	mov    %edx,%esi
  800aba:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800abd:	eb 1a                	jmp    800ad9 <memcmp+0x2c>
		if (*s1 != *s2)
  800abf:	0f b6 02             	movzbl (%edx),%eax
  800ac2:	0f b6 19             	movzbl (%ecx),%ebx
  800ac5:	38 d8                	cmp    %bl,%al
  800ac7:	74 0a                	je     800ad3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800ac9:	0f b6 c0             	movzbl %al,%eax
  800acc:	0f b6 db             	movzbl %bl,%ebx
  800acf:	29 d8                	sub    %ebx,%eax
  800ad1:	eb 0f                	jmp    800ae2 <memcmp+0x35>
		s1++, s2++;
  800ad3:	83 c2 01             	add    $0x1,%edx
  800ad6:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800ad9:	39 f2                	cmp    %esi,%edx
  800adb:	75 e2                	jne    800abf <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800add:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800ae2:	5b                   	pop    %ebx
  800ae3:	5e                   	pop    %esi
  800ae4:	5d                   	pop    %ebp
  800ae5:	c3                   	ret    

00800ae6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800ae6:	55                   	push   %ebp
  800ae7:	89 e5                	mov    %esp,%ebp
  800ae9:	8b 45 08             	mov    0x8(%ebp),%eax
  800aec:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800aef:	89 c2                	mov    %eax,%edx
  800af1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800af4:	eb 07                	jmp    800afd <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800af6:	38 08                	cmp    %cl,(%eax)
  800af8:	74 07                	je     800b01 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800afa:	83 c0 01             	add    $0x1,%eax
  800afd:	39 d0                	cmp    %edx,%eax
  800aff:	72 f5                	jb     800af6 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800b01:	5d                   	pop    %ebp
  800b02:	c3                   	ret    

00800b03 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800b03:	55                   	push   %ebp
  800b04:	89 e5                	mov    %esp,%ebp
  800b06:	57                   	push   %edi
  800b07:	56                   	push   %esi
  800b08:	53                   	push   %ebx
  800b09:	8b 55 08             	mov    0x8(%ebp),%edx
  800b0c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b0f:	eb 03                	jmp    800b14 <strtol+0x11>
		s++;
  800b11:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b14:	0f b6 0a             	movzbl (%edx),%ecx
  800b17:	80 f9 09             	cmp    $0x9,%cl
  800b1a:	74 f5                	je     800b11 <strtol+0xe>
  800b1c:	80 f9 20             	cmp    $0x20,%cl
  800b1f:	74 f0                	je     800b11 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800b21:	80 f9 2b             	cmp    $0x2b,%cl
  800b24:	75 0a                	jne    800b30 <strtol+0x2d>
		s++;
  800b26:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800b29:	bf 00 00 00 00       	mov    $0x0,%edi
  800b2e:	eb 11                	jmp    800b41 <strtol+0x3e>
  800b30:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800b35:	80 f9 2d             	cmp    $0x2d,%cl
  800b38:	75 07                	jne    800b41 <strtol+0x3e>
		s++, neg = 1;
  800b3a:	8d 52 01             	lea    0x1(%edx),%edx
  800b3d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800b41:	a9 ef ff ff ff       	test   $0xffffffef,%eax
  800b46:	75 15                	jne    800b5d <strtol+0x5a>
  800b48:	80 3a 30             	cmpb   $0x30,(%edx)
  800b4b:	75 10                	jne    800b5d <strtol+0x5a>
  800b4d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800b51:	75 0a                	jne    800b5d <strtol+0x5a>
		s += 2, base = 16;
  800b53:	83 c2 02             	add    $0x2,%edx
  800b56:	b8 10 00 00 00       	mov    $0x10,%eax
  800b5b:	eb 10                	jmp    800b6d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
  800b5d:	85 c0                	test   %eax,%eax
  800b5f:	75 0c                	jne    800b6d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800b61:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b63:	80 3a 30             	cmpb   $0x30,(%edx)
  800b66:	75 05                	jne    800b6d <strtol+0x6a>
		s++, base = 8;
  800b68:	83 c2 01             	add    $0x1,%edx
  800b6b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
  800b6d:	bb 00 00 00 00       	mov    $0x0,%ebx
  800b72:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800b75:	0f b6 0a             	movzbl (%edx),%ecx
  800b78:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800b7b:	89 f0                	mov    %esi,%eax
  800b7d:	3c 09                	cmp    $0x9,%al
  800b7f:	77 08                	ja     800b89 <strtol+0x86>
			dig = *s - '0';
  800b81:	0f be c9             	movsbl %cl,%ecx
  800b84:	83 e9 30             	sub    $0x30,%ecx
  800b87:	eb 20                	jmp    800ba9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
  800b89:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800b8c:	89 f0                	mov    %esi,%eax
  800b8e:	3c 19                	cmp    $0x19,%al
  800b90:	77 08                	ja     800b9a <strtol+0x97>
			dig = *s - 'a' + 10;
  800b92:	0f be c9             	movsbl %cl,%ecx
  800b95:	83 e9 57             	sub    $0x57,%ecx
  800b98:	eb 0f                	jmp    800ba9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
  800b9a:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800b9d:	89 f0                	mov    %esi,%eax
  800b9f:	3c 19                	cmp    $0x19,%al
  800ba1:	77 16                	ja     800bb9 <strtol+0xb6>
			dig = *s - 'A' + 10;
  800ba3:	0f be c9             	movsbl %cl,%ecx
  800ba6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800ba9:	3b 4d 10             	cmp    0x10(%ebp),%ecx
  800bac:	7d 0f                	jge    800bbd <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
  800bae:	83 c2 01             	add    $0x1,%edx
  800bb1:	0f af 5d 10          	imul   0x10(%ebp),%ebx
  800bb5:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
  800bb7:	eb bc                	jmp    800b75 <strtol+0x72>
  800bb9:	89 d8                	mov    %ebx,%eax
  800bbb:	eb 02                	jmp    800bbf <strtol+0xbc>
  800bbd:	89 d8                	mov    %ebx,%eax

	if (endptr)
  800bbf:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800bc3:	74 05                	je     800bca <strtol+0xc7>
		*endptr = (char *) s;
  800bc5:	8b 75 0c             	mov    0xc(%ebp),%esi
  800bc8:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
  800bca:	f7 d8                	neg    %eax
  800bcc:	85 ff                	test   %edi,%edi
  800bce:	0f 44 c3             	cmove  %ebx,%eax
}
  800bd1:	5b                   	pop    %ebx
  800bd2:	5e                   	pop    %esi
  800bd3:	5f                   	pop    %edi
  800bd4:	5d                   	pop    %ebp
  800bd5:	c3                   	ret    

00800bd6 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800bd6:	55                   	push   %ebp
  800bd7:	89 e5                	mov    %esp,%ebp
  800bd9:	57                   	push   %edi
  800bda:	56                   	push   %esi
  800bdb:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bdc:	b8 00 00 00 00       	mov    $0x0,%eax
  800be1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800be4:	8b 55 08             	mov    0x8(%ebp),%edx
  800be7:	89 c3                	mov    %eax,%ebx
  800be9:	89 c7                	mov    %eax,%edi
  800beb:	89 c6                	mov    %eax,%esi
  800bed:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800bef:	5b                   	pop    %ebx
  800bf0:	5e                   	pop    %esi
  800bf1:	5f                   	pop    %edi
  800bf2:	5d                   	pop    %ebp
  800bf3:	c3                   	ret    

00800bf4 <sys_cgetc>:

int
sys_cgetc(void)
{
  800bf4:	55                   	push   %ebp
  800bf5:	89 e5                	mov    %esp,%ebp
  800bf7:	57                   	push   %edi
  800bf8:	56                   	push   %esi
  800bf9:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bfa:	ba 00 00 00 00       	mov    $0x0,%edx
  800bff:	b8 01 00 00 00       	mov    $0x1,%eax
  800c04:	89 d1                	mov    %edx,%ecx
  800c06:	89 d3                	mov    %edx,%ebx
  800c08:	89 d7                	mov    %edx,%edi
  800c0a:	89 d6                	mov    %edx,%esi
  800c0c:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800c0e:	5b                   	pop    %ebx
  800c0f:	5e                   	pop    %esi
  800c10:	5f                   	pop    %edi
  800c11:	5d                   	pop    %ebp
  800c12:	c3                   	ret    

00800c13 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800c13:	55                   	push   %ebp
  800c14:	89 e5                	mov    %esp,%ebp
  800c16:	57                   	push   %edi
  800c17:	56                   	push   %esi
  800c18:	53                   	push   %ebx
  800c19:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c1c:	b9 00 00 00 00       	mov    $0x0,%ecx
  800c21:	b8 03 00 00 00       	mov    $0x3,%eax
  800c26:	8b 55 08             	mov    0x8(%ebp),%edx
  800c29:	89 cb                	mov    %ecx,%ebx
  800c2b:	89 cf                	mov    %ecx,%edi
  800c2d:	89 ce                	mov    %ecx,%esi
  800c2f:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800c31:	85 c0                	test   %eax,%eax
  800c33:	7e 28                	jle    800c5d <sys_env_destroy+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c35:	89 44 24 10          	mov    %eax,0x10(%esp)
  800c39:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800c40:	00 
  800c41:	c7 44 24 08 a4 18 80 	movl   $0x8018a4,0x8(%esp)
  800c48:	00 
  800c49:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800c50:	00 
  800c51:	c7 04 24 c1 18 80 00 	movl   $0x8018c1,(%esp)
  800c58:	e8 10 f5 ff ff       	call   80016d <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800c5d:	83 c4 2c             	add    $0x2c,%esp
  800c60:	5b                   	pop    %ebx
  800c61:	5e                   	pop    %esi
  800c62:	5f                   	pop    %edi
  800c63:	5d                   	pop    %ebp
  800c64:	c3                   	ret    

00800c65 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800c65:	55                   	push   %ebp
  800c66:	89 e5                	mov    %esp,%ebp
  800c68:	57                   	push   %edi
  800c69:	56                   	push   %esi
  800c6a:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c6b:	ba 00 00 00 00       	mov    $0x0,%edx
  800c70:	b8 02 00 00 00       	mov    $0x2,%eax
  800c75:	89 d1                	mov    %edx,%ecx
  800c77:	89 d3                	mov    %edx,%ebx
  800c79:	89 d7                	mov    %edx,%edi
  800c7b:	89 d6                	mov    %edx,%esi
  800c7d:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800c7f:	5b                   	pop    %ebx
  800c80:	5e                   	pop    %esi
  800c81:	5f                   	pop    %edi
  800c82:	5d                   	pop    %ebp
  800c83:	c3                   	ret    

00800c84 <sys_yield>:

void
sys_yield(void)
{
  800c84:	55                   	push   %ebp
  800c85:	89 e5                	mov    %esp,%ebp
  800c87:	57                   	push   %edi
  800c88:	56                   	push   %esi
  800c89:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c8a:	ba 00 00 00 00       	mov    $0x0,%edx
  800c8f:	b8 0a 00 00 00       	mov    $0xa,%eax
  800c94:	89 d1                	mov    %edx,%ecx
  800c96:	89 d3                	mov    %edx,%ebx
  800c98:	89 d7                	mov    %edx,%edi
  800c9a:	89 d6                	mov    %edx,%esi
  800c9c:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800c9e:	5b                   	pop    %ebx
  800c9f:	5e                   	pop    %esi
  800ca0:	5f                   	pop    %edi
  800ca1:	5d                   	pop    %ebp
  800ca2:	c3                   	ret    

00800ca3 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800ca3:	55                   	push   %ebp
  800ca4:	89 e5                	mov    %esp,%ebp
  800ca6:	57                   	push   %edi
  800ca7:	56                   	push   %esi
  800ca8:	53                   	push   %ebx
  800ca9:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800cac:	be 00 00 00 00       	mov    $0x0,%esi
  800cb1:	b8 04 00 00 00       	mov    $0x4,%eax
  800cb6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800cb9:	8b 55 08             	mov    0x8(%ebp),%edx
  800cbc:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800cbf:	89 f7                	mov    %esi,%edi
  800cc1:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800cc3:	85 c0                	test   %eax,%eax
  800cc5:	7e 28                	jle    800cef <sys_page_alloc+0x4c>
		panic("syscall %d returned %d (> 0)", num, ret);
  800cc7:	89 44 24 10          	mov    %eax,0x10(%esp)
  800ccb:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
  800cd2:	00 
  800cd3:	c7 44 24 08 a4 18 80 	movl   $0x8018a4,0x8(%esp)
  800cda:	00 
  800cdb:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800ce2:	00 
  800ce3:	c7 04 24 c1 18 80 00 	movl   $0x8018c1,(%esp)
  800cea:	e8 7e f4 ff ff       	call   80016d <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  800cef:	83 c4 2c             	add    $0x2c,%esp
  800cf2:	5b                   	pop    %ebx
  800cf3:	5e                   	pop    %esi
  800cf4:	5f                   	pop    %edi
  800cf5:	5d                   	pop    %ebp
  800cf6:	c3                   	ret    

00800cf7 <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800cf7:	55                   	push   %ebp
  800cf8:	89 e5                	mov    %esp,%ebp
  800cfa:	57                   	push   %edi
  800cfb:	56                   	push   %esi
  800cfc:	53                   	push   %ebx
  800cfd:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d00:	b8 05 00 00 00       	mov    $0x5,%eax
  800d05:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d08:	8b 55 08             	mov    0x8(%ebp),%edx
  800d0b:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800d0e:	8b 7d 14             	mov    0x14(%ebp),%edi
  800d11:	8b 75 18             	mov    0x18(%ebp),%esi
  800d14:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800d16:	85 c0                	test   %eax,%eax
  800d18:	7e 28                	jle    800d42 <sys_page_map+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d1a:	89 44 24 10          	mov    %eax,0x10(%esp)
  800d1e:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
  800d25:	00 
  800d26:	c7 44 24 08 a4 18 80 	movl   $0x8018a4,0x8(%esp)
  800d2d:	00 
  800d2e:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800d35:	00 
  800d36:	c7 04 24 c1 18 80 00 	movl   $0x8018c1,(%esp)
  800d3d:	e8 2b f4 ff ff       	call   80016d <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  800d42:	83 c4 2c             	add    $0x2c,%esp
  800d45:	5b                   	pop    %ebx
  800d46:	5e                   	pop    %esi
  800d47:	5f                   	pop    %edi
  800d48:	5d                   	pop    %ebp
  800d49:	c3                   	ret    

00800d4a <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  800d4a:	55                   	push   %ebp
  800d4b:	89 e5                	mov    %esp,%ebp
  800d4d:	57                   	push   %edi
  800d4e:	56                   	push   %esi
  800d4f:	53                   	push   %ebx
  800d50:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d53:	bb 00 00 00 00       	mov    $0x0,%ebx
  800d58:	b8 06 00 00 00       	mov    $0x6,%eax
  800d5d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d60:	8b 55 08             	mov    0x8(%ebp),%edx
  800d63:	89 df                	mov    %ebx,%edi
  800d65:	89 de                	mov    %ebx,%esi
  800d67:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800d69:	85 c0                	test   %eax,%eax
  800d6b:	7e 28                	jle    800d95 <sys_page_unmap+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d6d:	89 44 24 10          	mov    %eax,0x10(%esp)
  800d71:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
  800d78:	00 
  800d79:	c7 44 24 08 a4 18 80 	movl   $0x8018a4,0x8(%esp)
  800d80:	00 
  800d81:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800d88:	00 
  800d89:	c7 04 24 c1 18 80 00 	movl   $0x8018c1,(%esp)
  800d90:	e8 d8 f3 ff ff       	call   80016d <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800d95:	83 c4 2c             	add    $0x2c,%esp
  800d98:	5b                   	pop    %ebx
  800d99:	5e                   	pop    %esi
  800d9a:	5f                   	pop    %edi
  800d9b:	5d                   	pop    %ebp
  800d9c:	c3                   	ret    

00800d9d <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800d9d:	55                   	push   %ebp
  800d9e:	89 e5                	mov    %esp,%ebp
  800da0:	57                   	push   %edi
  800da1:	56                   	push   %esi
  800da2:	53                   	push   %ebx
  800da3:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800da6:	bb 00 00 00 00       	mov    $0x0,%ebx
  800dab:	b8 08 00 00 00       	mov    $0x8,%eax
  800db0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800db3:	8b 55 08             	mov    0x8(%ebp),%edx
  800db6:	89 df                	mov    %ebx,%edi
  800db8:	89 de                	mov    %ebx,%esi
  800dba:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800dbc:	85 c0                	test   %eax,%eax
  800dbe:	7e 28                	jle    800de8 <sys_env_set_status+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800dc0:	89 44 24 10          	mov    %eax,0x10(%esp)
  800dc4:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  800dcb:	00 
  800dcc:	c7 44 24 08 a4 18 80 	movl   $0x8018a4,0x8(%esp)
  800dd3:	00 
  800dd4:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800ddb:	00 
  800ddc:	c7 04 24 c1 18 80 00 	movl   $0x8018c1,(%esp)
  800de3:	e8 85 f3 ff ff       	call   80016d <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800de8:	83 c4 2c             	add    $0x2c,%esp
  800deb:	5b                   	pop    %ebx
  800dec:	5e                   	pop    %esi
  800ded:	5f                   	pop    %edi
  800dee:	5d                   	pop    %ebp
  800def:	c3                   	ret    

00800df0 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800df0:	55                   	push   %ebp
  800df1:	89 e5                	mov    %esp,%ebp
  800df3:	57                   	push   %edi
  800df4:	56                   	push   %esi
  800df5:	53                   	push   %ebx
  800df6:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800df9:	bb 00 00 00 00       	mov    $0x0,%ebx
  800dfe:	b8 09 00 00 00       	mov    $0x9,%eax
  800e03:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800e06:	8b 55 08             	mov    0x8(%ebp),%edx
  800e09:	89 df                	mov    %ebx,%edi
  800e0b:	89 de                	mov    %ebx,%esi
  800e0d:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800e0f:	85 c0                	test   %eax,%eax
  800e11:	7e 28                	jle    800e3b <sys_env_set_pgfault_upcall+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800e13:	89 44 24 10          	mov    %eax,0x10(%esp)
  800e17:	c7 44 24 0c 09 00 00 	movl   $0x9,0xc(%esp)
  800e1e:	00 
  800e1f:	c7 44 24 08 a4 18 80 	movl   $0x8018a4,0x8(%esp)
  800e26:	00 
  800e27:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800e2e:	00 
  800e2f:	c7 04 24 c1 18 80 00 	movl   $0x8018c1,(%esp)
  800e36:	e8 32 f3 ff ff       	call   80016d <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  800e3b:	83 c4 2c             	add    $0x2c,%esp
  800e3e:	5b                   	pop    %ebx
  800e3f:	5e                   	pop    %esi
  800e40:	5f                   	pop    %edi
  800e41:	5d                   	pop    %ebp
  800e42:	c3                   	ret    

00800e43 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800e43:	55                   	push   %ebp
  800e44:	89 e5                	mov    %esp,%ebp
  800e46:	57                   	push   %edi
  800e47:	56                   	push   %esi
  800e48:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800e49:	be 00 00 00 00       	mov    $0x0,%esi
  800e4e:	b8 0b 00 00 00       	mov    $0xb,%eax
  800e53:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800e56:	8b 55 08             	mov    0x8(%ebp),%edx
  800e59:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800e5c:	8b 7d 14             	mov    0x14(%ebp),%edi
  800e5f:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  800e61:	5b                   	pop    %ebx
  800e62:	5e                   	pop    %esi
  800e63:	5f                   	pop    %edi
  800e64:	5d                   	pop    %ebp
  800e65:	c3                   	ret    

00800e66 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800e66:	55                   	push   %ebp
  800e67:	89 e5                	mov    %esp,%ebp
  800e69:	57                   	push   %edi
  800e6a:	56                   	push   %esi
  800e6b:	53                   	push   %ebx
  800e6c:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800e6f:	b9 00 00 00 00       	mov    $0x0,%ecx
  800e74:	b8 0c 00 00 00       	mov    $0xc,%eax
  800e79:	8b 55 08             	mov    0x8(%ebp),%edx
  800e7c:	89 cb                	mov    %ecx,%ebx
  800e7e:	89 cf                	mov    %ecx,%edi
  800e80:	89 ce                	mov    %ecx,%esi
  800e82:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800e84:	85 c0                	test   %eax,%eax
  800e86:	7e 28                	jle    800eb0 <sys_ipc_recv+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800e88:	89 44 24 10          	mov    %eax,0x10(%esp)
  800e8c:	c7 44 24 0c 0c 00 00 	movl   $0xc,0xc(%esp)
  800e93:	00 
  800e94:	c7 44 24 08 a4 18 80 	movl   $0x8018a4,0x8(%esp)
  800e9b:	00 
  800e9c:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800ea3:	00 
  800ea4:	c7 04 24 c1 18 80 00 	movl   $0x8018c1,(%esp)
  800eab:	e8 bd f2 ff ff       	call   80016d <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  800eb0:	83 c4 2c             	add    $0x2c,%esp
  800eb3:	5b                   	pop    %ebx
  800eb4:	5e                   	pop    %esi
  800eb5:	5f                   	pop    %edi
  800eb6:	5d                   	pop    %ebp
  800eb7:	c3                   	ret    

00800eb8 <pgfault>:
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
  800eb8:	55                   	push   %ebp
  800eb9:	89 e5                	mov    %esp,%ebp
  800ebb:	53                   	push   %ebx
  800ebc:	83 ec 24             	sub    $0x24,%esp
  800ebf:	8b 45 08             	mov    0x8(%ebp),%eax
	void *addr = (void *) utf->utf_fault_va;
  800ec2:	8b 10                	mov    (%eax),%edx
	uint32_t err = utf->utf_err;
  800ec4:	8b 48 04             	mov    0x4(%eax),%ecx

	// LAB 4: Your code here.
	//cprintf("err=%d",err);
	//cprintf("im here = %x",(uvpt[PGNUM((uint32_t)addr)] & (PTE_W|PTE_COW)));

	if((uvpt[PGNUM((uint32_t)addr)] & (PTE_W|PTE_COW)) == 0  && (err & FEC_WR) )
  800ec7:	89 d0                	mov    %edx,%eax
  800ec9:	c1 e8 0c             	shr    $0xc,%eax
  800ecc:	8b 04 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%eax
  800ed3:	a9 02 08 00 00       	test   $0x802,%eax
  800ed8:	75 21                	jne    800efb <pgfault+0x43>
  800eda:	f6 c1 02             	test   $0x2,%cl
  800edd:	74 1c                	je     800efb <pgfault+0x43>
		panic("Trying to write on a read only page or the error is not a Write error");
  800edf:	c7 44 24 08 d0 18 80 	movl   $0x8018d0,0x8(%esp)
  800ee6:	00 
  800ee7:	c7 44 24 04 22 00 00 	movl   $0x22,0x4(%esp)
  800eee:	00 
  800eef:	c7 04 24 44 19 80 00 	movl   $0x801944,(%esp)
  800ef6:	e8 72 f2 ff ff       	call   80016d <_panic>
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.

	// LAB 4: Your code here.
	void * vAddr = (void *)(ROUNDDOWN((uint32_t) addr, PGSIZE));
  800efb:	89 d3                	mov    %edx,%ebx
  800efd:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	if ((r = sys_page_alloc(0, (void*) PFTEMP, PTE_P|PTE_U|PTE_W)) < 0)
  800f03:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  800f0a:	00 
  800f0b:	c7 44 24 04 00 f0 7f 	movl   $0x7ff000,0x4(%esp)
  800f12:	00 
  800f13:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800f1a:	e8 84 fd ff ff       	call   800ca3 <sys_page_alloc>
  800f1f:	85 c0                	test   %eax,%eax
  800f21:	79 20                	jns    800f43 <pgfault+0x8b>
		panic("sys_page_alloc: %e", r);
  800f23:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800f27:	c7 44 24 08 4f 19 80 	movl   $0x80194f,0x8(%esp)
  800f2e:	00 
  800f2f:	c7 44 24 04 2d 00 00 	movl   $0x2d,0x4(%esp)
  800f36:	00 
  800f37:	c7 04 24 44 19 80 00 	movl   $0x801944,(%esp)
  800f3e:	e8 2a f2 ff ff       	call   80016d <_panic>
		
	memmove((void *)PFTEMP, vAddr, PGSIZE);
  800f43:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  800f4a:	00 
  800f4b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800f4f:	c7 04 24 00 f0 7f 00 	movl   $0x7ff000,(%esp)
  800f56:	e8 c9 fa ff ff       	call   800a24 <memmove>
	
	if ((r = sys_page_map(0, (void *)PFTEMP, 0, vAddr, PTE_P|PTE_U|PTE_W)) < 0)
  800f5b:	c7 44 24 10 07 00 00 	movl   $0x7,0x10(%esp)
  800f62:	00 
  800f63:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  800f67:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  800f6e:	00 
  800f6f:	c7 44 24 04 00 f0 7f 	movl   $0x7ff000,0x4(%esp)
  800f76:	00 
  800f77:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800f7e:	e8 74 fd ff ff       	call   800cf7 <sys_page_map>
  800f83:	85 c0                	test   %eax,%eax
  800f85:	79 20                	jns    800fa7 <pgfault+0xef>
		panic("sys_page_map: %e", r);
  800f87:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800f8b:	c7 44 24 08 62 19 80 	movl   $0x801962,0x8(%esp)
  800f92:	00 
  800f93:	c7 44 24 04 32 00 00 	movl   $0x32,0x4(%esp)
  800f9a:	00 
  800f9b:	c7 04 24 44 19 80 00 	movl   $0x801944,(%esp)
  800fa2:	e8 c6 f1 ff ff       	call   80016d <_panic>
		
	
	
	if ((r = sys_page_unmap(0, PFTEMP)) < 0)
  800fa7:	c7 44 24 04 00 f0 7f 	movl   $0x7ff000,0x4(%esp)
  800fae:	00 
  800faf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800fb6:	e8 8f fd ff ff       	call   800d4a <sys_page_unmap>
  800fbb:	85 c0                	test   %eax,%eax
  800fbd:	79 20                	jns    800fdf <pgfault+0x127>
		panic("sys_page_unmap: %e", r);
  800fbf:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800fc3:	c7 44 24 08 73 19 80 	movl   $0x801973,0x8(%esp)
  800fca:	00 
  800fcb:	c7 44 24 04 37 00 00 	movl   $0x37,0x4(%esp)
  800fd2:	00 
  800fd3:	c7 04 24 44 19 80 00 	movl   $0x801944,(%esp)
  800fda:	e8 8e f1 ff ff       	call   80016d <_panic>

}
  800fdf:	83 c4 24             	add    $0x24,%esp
  800fe2:	5b                   	pop    %ebx
  800fe3:	5d                   	pop    %ebp
  800fe4:	c3                   	ret    

00800fe5 <fork>:
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
  800fe5:	55                   	push   %ebp
  800fe6:	89 e5                	mov    %esp,%ebp
  800fe8:	57                   	push   %edi
  800fe9:	56                   	push   %esi
  800fea:	53                   	push   %ebx
  800feb:	83 ec 2c             	sub    $0x2c,%esp
	// LAB 4: Your code here.
	envid_t envid;
	extern unsigned char end[];
	uint32_t pn;
	
	set_pgfault_handler(pgfault);
  800fee:	c7 04 24 b8 0e 80 00 	movl   $0x800eb8,(%esp)
  800ff5:	e8 bc 02 00 00       	call   8012b6 <set_pgfault_handler>
// This must be inlined.  Exercise for reader: why?
static inline envid_t __attribute__((always_inline))
sys_exofork(void)
{
	envid_t ret;
	asm volatile("int %2"
  800ffa:	b8 07 00 00 00       	mov    $0x7,%eax
  800fff:	cd 30                	int    $0x30
  801001:	89 c7                	mov    %eax,%edi
  801003:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	
	envid = sys_exofork();
	//cprintf("envId=%d",envid);
	if (envid < 0)
  801006:	85 c0                	test   %eax,%eax
  801008:	79 20                	jns    80102a <fork+0x45>
		panic("sys_exofork: %e", envid);
  80100a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80100e:	c7 44 24 08 86 19 80 	movl   $0x801986,0x8(%esp)
  801015:	00 
  801016:	c7 44 24 04 83 00 00 	movl   $0x83,0x4(%esp)
  80101d:	00 
  80101e:	c7 04 24 44 19 80 00 	movl   $0x801944,(%esp)
  801025:	e8 43 f1 ff ff       	call   80016d <_panic>
	if (envid == 0) {
  80102a:	bb 00 08 00 00       	mov    $0x800,%ebx
  80102f:	85 c0                	test   %eax,%eax
  801031:	75 21                	jne    801054 <fork+0x6f>
		// We're the child.
		// The copied value of the global variable 'thisenv'
		// is no longer valid (it refers to the parent!).
		// Fix it and return 0.
		thisenv = &envs[ENVX(sys_getenvid())];
  801033:	e8 2d fc ff ff       	call   800c65 <sys_getenvid>
  801038:	25 ff 03 00 00       	and    $0x3ff,%eax
  80103d:	6b c0 7c             	imul   $0x7c,%eax,%eax
  801040:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  801045:	a3 08 20 80 00       	mov    %eax,0x802008
		return 0;
  80104a:	b8 00 00 00 00       	mov    $0x0,%eax
  80104f:	e9 38 02 00 00       	jmp    80128c <fork+0x2a7>
	}
	uint32_t i=0;
	for (pn =  PGNUM(UTEXT); pn < PGNUM(UXSTACKTOP - PGSIZE); pn += 1)
	{
		if(!(uvpd[PDX(pn<<PGSHIFT)] & PTE_P)) continue;
  801054:	89 d8                	mov    %ebx,%eax
  801056:	c1 e0 0c             	shl    $0xc,%eax
  801059:	89 c2                	mov    %eax,%edx
  80105b:	c1 ea 16             	shr    $0x16,%edx
  80105e:	8b 14 95 00 d0 7b ef 	mov    -0x10843000(,%edx,4),%edx
  801065:	f6 c2 01             	test   $0x1,%dl
  801068:	0f 84 69 01 00 00    	je     8011d7 <fork+0x1f2>
		if(!(uvpt[pn] & PTE_P)) continue;
  80106e:	8b 14 9d 00 00 40 ef 	mov    -0x10c00000(,%ebx,4),%edx
  801075:	f6 c2 01             	test   $0x1,%dl
  801078:	0f 84 59 01 00 00    	je     8011d7 <fork+0x1f2>
		if((pn << PGSHIFT) < (UXSTACKTOP - PGSIZE))
  80107e:	3d ff ef bf ee       	cmp    $0xeebfefff,%eax
  801083:	0f 87 4e 01 00 00    	ja     8011d7 <fork+0x1f2>
  801089:	89 c6                	mov    %eax,%esi
		int perm = 0;
		int perm1 =0;
		perm |= PTE_P|PTE_U|PTE_COW;
		perm1 |= PTE_P|PTE_U;

	if((uvpt[pn] & PTE_W) || (uvpt[pn] & PTE_COW))
  80108b:	8b 04 9d 00 00 40 ef 	mov    -0x10c00000(,%ebx,4),%eax
  801092:	a8 02                	test   $0x2,%al
  801094:	75 10                	jne    8010a6 <fork+0xc1>
  801096:	8b 04 9d 00 00 40 ef 	mov    -0x10c00000(,%ebx,4),%eax
  80109d:	f6 c4 08             	test   $0x8,%ah
  8010a0:	0f 84 93 00 00 00    	je     801139 <fork+0x154>
	{
		
	
		if ((r = sys_page_map(0, address, envid, address, perm)) < 0)
  8010a6:	c7 44 24 10 05 08 00 	movl   $0x805,0x10(%esp)
  8010ad:	00 
  8010ae:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8010b2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8010b5:	89 44 24 08          	mov    %eax,0x8(%esp)
  8010b9:	89 74 24 04          	mov    %esi,0x4(%esp)
  8010bd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8010c4:	e8 2e fc ff ff       	call   800cf7 <sys_page_map>
  8010c9:	85 c0                	test   %eax,%eax
  8010cb:	79 20                	jns    8010ed <fork+0x108>
			panic("sys_page_map: %e", r);
  8010cd:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8010d1:	c7 44 24 08 62 19 80 	movl   $0x801962,0x8(%esp)
  8010d8:	00 
  8010d9:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
  8010e0:	00 
  8010e1:	c7 04 24 44 19 80 00 	movl   $0x801944,(%esp)
  8010e8:	e8 80 f0 ff ff       	call   80016d <_panic>
		if ((r = sys_page_map(0, address, 0, address, perm)) < 0)
  8010ed:	c7 44 24 10 05 08 00 	movl   $0x805,0x10(%esp)
  8010f4:	00 
  8010f5:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8010f9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  801100:	00 
  801101:	89 74 24 04          	mov    %esi,0x4(%esp)
  801105:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  80110c:	e8 e6 fb ff ff       	call   800cf7 <sys_page_map>
  801111:	85 c0                	test   %eax,%eax
  801113:	0f 89 be 00 00 00    	jns    8011d7 <fork+0x1f2>
			panic("sys_page_map: %e", r);
  801119:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80111d:	c7 44 24 08 62 19 80 	movl   $0x801962,0x8(%esp)
  801124:	00 
  801125:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  80112c:	00 
  80112d:	c7 04 24 44 19 80 00 	movl   $0x801944,(%esp)
  801134:	e8 34 f0 ff ff       	call   80016d <_panic>
	}

	else if(uvpt[pn] & PTE_U)
  801139:	8b 04 9d 00 00 40 ef 	mov    -0x10c00000(,%ebx,4),%eax
  801140:	a8 04                	test   $0x4,%al
  801142:	0f 84 8f 00 00 00    	je     8011d7 <fork+0x1f2>
	{
		if ((r = sys_page_map(0, address, envid, address, perm1)) < 0)
  801148:	c7 44 24 10 05 00 00 	movl   $0x5,0x10(%esp)
  80114f:	00 
  801150:	89 74 24 0c          	mov    %esi,0xc(%esp)
  801154:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  801157:	89 44 24 08          	mov    %eax,0x8(%esp)
  80115b:	89 74 24 04          	mov    %esi,0x4(%esp)
  80115f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  801166:	e8 8c fb ff ff       	call   800cf7 <sys_page_map>
  80116b:	85 c0                	test   %eax,%eax
  80116d:	79 20                	jns    80118f <fork+0x1aa>
			panic("sys_page_map: %e", r);
  80116f:	89 44 24 0c          	mov    %eax,0xc(%esp)
  801173:	c7 44 24 08 62 19 80 	movl   $0x801962,0x8(%esp)
  80117a:	00 
  80117b:	c7 44 24 04 5e 00 00 	movl   $0x5e,0x4(%esp)
  801182:	00 
  801183:	c7 04 24 44 19 80 00 	movl   $0x801944,(%esp)
  80118a:	e8 de ef ff ff       	call   80016d <_panic>
		if ((r = sys_page_map(0, address, 0, address, perm1)) < 0)
  80118f:	c7 44 24 10 05 00 00 	movl   $0x5,0x10(%esp)
  801196:	00 
  801197:	89 74 24 0c          	mov    %esi,0xc(%esp)
  80119b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  8011a2:	00 
  8011a3:	89 74 24 04          	mov    %esi,0x4(%esp)
  8011a7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8011ae:	e8 44 fb ff ff       	call   800cf7 <sys_page_map>
  8011b3:	85 c0                	test   %eax,%eax
  8011b5:	79 20                	jns    8011d7 <fork+0x1f2>
			panic("sys_page_map: %e", r);
  8011b7:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8011bb:	c7 44 24 08 62 19 80 	movl   $0x801962,0x8(%esp)
  8011c2:	00 
  8011c3:	c7 44 24 04 60 00 00 	movl   $0x60,0x4(%esp)
  8011ca:	00 
  8011cb:	c7 04 24 44 19 80 00 	movl   $0x801944,(%esp)
  8011d2:	e8 96 ef ff ff       	call   80016d <_panic>
		// Fix it and return 0.
		thisenv = &envs[ENVX(sys_getenvid())];
		return 0;
	}
	uint32_t i=0;
	for (pn =  PGNUM(UTEXT); pn < PGNUM(UXSTACKTOP - PGSIZE); pn += 1)
  8011d7:	83 c3 01             	add    $0x1,%ebx
  8011da:	81 fb ff eb 0e 00    	cmp    $0xeebff,%ebx
  8011e0:	0f 85 6e fe ff ff    	jne    801054 <fork+0x6f>
	
	//panic("im here");
	
		
	int r;
	if ((r = sys_page_alloc(envid, (void *)(UXSTACKTOP-PGSIZE), PTE_P|PTE_U|PTE_W)) < 0)
  8011e6:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  8011ed:	00 
  8011ee:	c7 44 24 04 00 f0 bf 	movl   $0xeebff000,0x4(%esp)
  8011f5:	ee 
  8011f6:	89 3c 24             	mov    %edi,(%esp)
  8011f9:	e8 a5 fa ff ff       	call   800ca3 <sys_page_alloc>
  8011fe:	85 c0                	test   %eax,%eax
  801200:	79 20                	jns    801222 <fork+0x23d>
		panic("sys_page_alloc: %e", r);
  801202:	89 44 24 0c          	mov    %eax,0xc(%esp)
  801206:	c7 44 24 08 4f 19 80 	movl   $0x80194f,0x8(%esp)
  80120d:	00 
  80120e:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
  801215:	00 
  801216:	c7 04 24 44 19 80 00 	movl   $0x801944,(%esp)
  80121d:	e8 4b ef ff ff       	call   80016d <_panic>
		
	int status;
	if((status =sys_env_set_pgfault_upcall(envid, thisenv->env_pgfault_upcall)) < 0)
  801222:	a1 08 20 80 00       	mov    0x802008,%eax
  801227:	8b 40 60             	mov    0x60(%eax),%eax
  80122a:	89 44 24 04          	mov    %eax,0x4(%esp)
  80122e:	89 3c 24             	mov    %edi,(%esp)
  801231:	e8 ba fb ff ff       	call   800df0 <sys_env_set_pgfault_upcall>
  801236:	85 c0                	test   %eax,%eax
  801238:	79 1c                	jns    801256 <fork+0x271>
		panic("Bad Environment in user pagefault handler");
  80123a:	c7 44 24 08 18 19 80 	movl   $0x801918,0x8(%esp)
  801241:	00 
  801242:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  801249:	00 
  80124a:	c7 04 24 44 19 80 00 	movl   $0x801944,(%esp)
  801251:	e8 17 ef ff ff       	call   80016d <_panic>
			
	if ((r = sys_env_set_status(envid, ENV_RUNNABLE)) < 0)
  801256:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
  80125d:	00 
  80125e:	89 3c 24             	mov    %edi,(%esp)
  801261:	e8 37 fb ff ff       	call   800d9d <sys_env_set_status>
  801266:	85 c0                	test   %eax,%eax
  801268:	79 20                	jns    80128a <fork+0x2a5>
		panic("sys_env_set_status: %e", r);
  80126a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80126e:	c7 44 24 08 96 19 80 	movl   $0x801996,0x8(%esp)
  801275:	00 
  801276:	c7 44 24 04 a3 00 00 	movl   $0xa3,0x4(%esp)
  80127d:	00 
  80127e:	c7 04 24 44 19 80 00 	movl   $0x801944,(%esp)
  801285:	e8 e3 ee ff ff       	call   80016d <_panic>
		
	return envid;
  80128a:	89 f8                	mov    %edi,%eax
}
  80128c:	83 c4 2c             	add    $0x2c,%esp
  80128f:	5b                   	pop    %ebx
  801290:	5e                   	pop    %esi
  801291:	5f                   	pop    %edi
  801292:	5d                   	pop    %ebp
  801293:	c3                   	ret    

00801294 <sfork>:

// Challenge!
int
sfork(void)
{
  801294:	55                   	push   %ebp
  801295:	89 e5                	mov    %esp,%ebp
  801297:	83 ec 18             	sub    $0x18,%esp
	panic("sfork not implemented");
  80129a:	c7 44 24 08 ad 19 80 	movl   $0x8019ad,0x8(%esp)
  8012a1:	00 
  8012a2:	c7 44 24 04 ac 00 00 	movl   $0xac,0x4(%esp)
  8012a9:	00 
  8012aa:	c7 04 24 44 19 80 00 	movl   $0x801944,(%esp)
  8012b1:	e8 b7 ee ff ff       	call   80016d <_panic>

008012b6 <set_pgfault_handler>:
// at UXSTACKTOP), and tell the kernel to call the assembly-language
// _pgfault_upcall routine when a page fault occurs.
//
void
set_pgfault_handler(void (*handler)(struct UTrapframe *utf))
{
  8012b6:	55                   	push   %ebp
  8012b7:	89 e5                	mov    %esp,%ebp
  8012b9:	83 ec 18             	sub    $0x18,%esp
	int r;

	if (_pgfault_handler==0)
  8012bc:	83 3d 0c 20 80 00 00 	cmpl   $0x0,0x80200c
  8012c3:	75 58                	jne    80131d <set_pgfault_handler+0x67>
	{
		// First time through!
		// LAB 4: Your code here.
		int check;
		check=sys_page_alloc(thisenv->env_id, (void *)(UXSTACKTOP-PGSIZE),  PTE_U|PTE_W|PTE_P);
  8012c5:	a1 08 20 80 00       	mov    0x802008,%eax
  8012ca:	8b 40 48             	mov    0x48(%eax),%eax
  8012cd:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  8012d4:	00 
  8012d5:	c7 44 24 04 00 f0 bf 	movl   $0xeebff000,0x4(%esp)
  8012dc:	ee 
  8012dd:	89 04 24             	mov    %eax,(%esp)
  8012e0:	e8 be f9 ff ff       	call   800ca3 <sys_page_alloc>
		if(check<0)
  8012e5:	85 c0                	test   %eax,%eax
  8012e7:	79 1c                	jns    801305 <set_pgfault_handler+0x4f>
		{
			panic("Sys_page alloc failed");
  8012e9:	c7 44 24 08 c3 19 80 	movl   $0x8019c3,0x8(%esp)
  8012f0:	00 
  8012f1:	c7 44 24 04 25 00 00 	movl   $0x25,0x4(%esp)
  8012f8:	00 
  8012f9:	c7 04 24 d9 19 80 00 	movl   $0x8019d9,(%esp)
  801300:	e8 68 ee ff ff       	call   80016d <_panic>
		}
		
		sys_env_set_pgfault_upcall(thisenv->env_id, _pgfault_upcall);
  801305:	a1 08 20 80 00       	mov    0x802008,%eax
  80130a:	8b 40 48             	mov    0x48(%eax),%eax
  80130d:	c7 44 24 04 27 13 80 	movl   $0x801327,0x4(%esp)
  801314:	00 
  801315:	89 04 24             	mov    %eax,(%esp)
  801318:	e8 d3 fa ff ff       	call   800df0 <sys_env_set_pgfault_upcall>

		//panic("set_pgfault_handler not implemented");
	}

	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
  80131d:	8b 45 08             	mov    0x8(%ebp),%eax
  801320:	a3 0c 20 80 00       	mov    %eax,0x80200c
}
  801325:	c9                   	leave  
  801326:	c3                   	ret    

00801327 <_pgfault_upcall>:

.text
.globl _pgfault_upcall
_pgfault_upcall:
	// Call the C page fault handler.
	pushl %esp			// function argument: pointer to UTF
  801327:	54                   	push   %esp
	movl _pgfault_handler, %eax
  801328:	a1 0c 20 80 00       	mov    0x80200c,%eax
	call *%eax
  80132d:	ff d0                	call   *%eax
	addl $4, %esp			// pop function argument
  80132f:	83 c4 04             	add    $0x4,%esp
	// may find that you have to rearrange your code in non-obvious
	// ways as registers become unavailable as scratch space.
	//
	// LAB 4: Your code here.
	
		movl %esp,%ebx      // Store current esp at bottom
  801332:	89 e3                	mov    %esp,%ebx
		movl 40(%esp),%eax   // store eip value
  801334:	8b 44 24 28          	mov    0x28(%esp),%eax
		movl 48(%esp),%esp   // get new esp value
  801338:	8b 64 24 30          	mov    0x30(%esp),%esp
		pushl %eax          // push eip in the free space
  80133c:	50                   	push   %eax
		movl %ebx,%esp	    // get back to prev	
  80133d:	89 dc                	mov    %ebx,%esp
		subl $4,48(%esp)
  80133f:	83 6c 24 30 04       	subl   $0x4,0x30(%esp)
		
	// Restore the trap-time1 registers.  After you do this, you
	// can no longer modify any general-purpose registers.
	// LAB 4: Your code here.
		
		popl %eax //fault_va
  801344:	58                   	pop    %eax
		popl %eax //err
  801345:	58                   	pop    %eax
		popal
  801346:	61                   	popa   
	// Restore eflags from the stack.  After you do this, you can
	// no longer use arithmetic operations or anything else that
	// modifies eflags.
	// LAB 4: Your code here.

		addl $4, %esp
  801347:	83 c4 04             	add    $0x4,%esp
		popfl
  80134a:	9d                   	popf   


	// Switch back to the adjusted trap-time stack.
	// LAB 4: Your code here.

		popl %esp		
  80134b:	5c                   	pop    %esp


	// Return to re-execute the instruction that faulted.
	// LAB 4: Your code here.

		ret
  80134c:	c3                   	ret    
  80134d:	66 90                	xchg   %ax,%ax
  80134f:	90                   	nop

00801350 <__udivdi3>:
  801350:	55                   	push   %ebp
  801351:	57                   	push   %edi
  801352:	56                   	push   %esi
  801353:	83 ec 0c             	sub    $0xc,%esp
  801356:	8b 44 24 28          	mov    0x28(%esp),%eax
  80135a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  80135e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
  801362:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  801366:	85 c0                	test   %eax,%eax
  801368:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80136c:	89 ea                	mov    %ebp,%edx
  80136e:	89 0c 24             	mov    %ecx,(%esp)
  801371:	75 2d                	jne    8013a0 <__udivdi3+0x50>
  801373:	39 e9                	cmp    %ebp,%ecx
  801375:	77 61                	ja     8013d8 <__udivdi3+0x88>
  801377:	85 c9                	test   %ecx,%ecx
  801379:	89 ce                	mov    %ecx,%esi
  80137b:	75 0b                	jne    801388 <__udivdi3+0x38>
  80137d:	b8 01 00 00 00       	mov    $0x1,%eax
  801382:	31 d2                	xor    %edx,%edx
  801384:	f7 f1                	div    %ecx
  801386:	89 c6                	mov    %eax,%esi
  801388:	31 d2                	xor    %edx,%edx
  80138a:	89 e8                	mov    %ebp,%eax
  80138c:	f7 f6                	div    %esi
  80138e:	89 c5                	mov    %eax,%ebp
  801390:	89 f8                	mov    %edi,%eax
  801392:	f7 f6                	div    %esi
  801394:	89 ea                	mov    %ebp,%edx
  801396:	83 c4 0c             	add    $0xc,%esp
  801399:	5e                   	pop    %esi
  80139a:	5f                   	pop    %edi
  80139b:	5d                   	pop    %ebp
  80139c:	c3                   	ret    
  80139d:	8d 76 00             	lea    0x0(%esi),%esi
  8013a0:	39 e8                	cmp    %ebp,%eax
  8013a2:	77 24                	ja     8013c8 <__udivdi3+0x78>
  8013a4:	0f bd e8             	bsr    %eax,%ebp
  8013a7:	83 f5 1f             	xor    $0x1f,%ebp
  8013aa:	75 3c                	jne    8013e8 <__udivdi3+0x98>
  8013ac:	8b 74 24 04          	mov    0x4(%esp),%esi
  8013b0:	39 34 24             	cmp    %esi,(%esp)
  8013b3:	0f 86 9f 00 00 00    	jbe    801458 <__udivdi3+0x108>
  8013b9:	39 d0                	cmp    %edx,%eax
  8013bb:	0f 82 97 00 00 00    	jb     801458 <__udivdi3+0x108>
  8013c1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  8013c8:	31 d2                	xor    %edx,%edx
  8013ca:	31 c0                	xor    %eax,%eax
  8013cc:	83 c4 0c             	add    $0xc,%esp
  8013cf:	5e                   	pop    %esi
  8013d0:	5f                   	pop    %edi
  8013d1:	5d                   	pop    %ebp
  8013d2:	c3                   	ret    
  8013d3:	90                   	nop
  8013d4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8013d8:	89 f8                	mov    %edi,%eax
  8013da:	f7 f1                	div    %ecx
  8013dc:	31 d2                	xor    %edx,%edx
  8013de:	83 c4 0c             	add    $0xc,%esp
  8013e1:	5e                   	pop    %esi
  8013e2:	5f                   	pop    %edi
  8013e3:	5d                   	pop    %ebp
  8013e4:	c3                   	ret    
  8013e5:	8d 76 00             	lea    0x0(%esi),%esi
  8013e8:	89 e9                	mov    %ebp,%ecx
  8013ea:	8b 3c 24             	mov    (%esp),%edi
  8013ed:	d3 e0                	shl    %cl,%eax
  8013ef:	89 c6                	mov    %eax,%esi
  8013f1:	b8 20 00 00 00       	mov    $0x20,%eax
  8013f6:	29 e8                	sub    %ebp,%eax
  8013f8:	89 c1                	mov    %eax,%ecx
  8013fa:	d3 ef                	shr    %cl,%edi
  8013fc:	89 e9                	mov    %ebp,%ecx
  8013fe:	89 7c 24 08          	mov    %edi,0x8(%esp)
  801402:	8b 3c 24             	mov    (%esp),%edi
  801405:	09 74 24 08          	or     %esi,0x8(%esp)
  801409:	89 d6                	mov    %edx,%esi
  80140b:	d3 e7                	shl    %cl,%edi
  80140d:	89 c1                	mov    %eax,%ecx
  80140f:	89 3c 24             	mov    %edi,(%esp)
  801412:	8b 7c 24 04          	mov    0x4(%esp),%edi
  801416:	d3 ee                	shr    %cl,%esi
  801418:	89 e9                	mov    %ebp,%ecx
  80141a:	d3 e2                	shl    %cl,%edx
  80141c:	89 c1                	mov    %eax,%ecx
  80141e:	d3 ef                	shr    %cl,%edi
  801420:	09 d7                	or     %edx,%edi
  801422:	89 f2                	mov    %esi,%edx
  801424:	89 f8                	mov    %edi,%eax
  801426:	f7 74 24 08          	divl   0x8(%esp)
  80142a:	89 d6                	mov    %edx,%esi
  80142c:	89 c7                	mov    %eax,%edi
  80142e:	f7 24 24             	mull   (%esp)
  801431:	39 d6                	cmp    %edx,%esi
  801433:	89 14 24             	mov    %edx,(%esp)
  801436:	72 30                	jb     801468 <__udivdi3+0x118>
  801438:	8b 54 24 04          	mov    0x4(%esp),%edx
  80143c:	89 e9                	mov    %ebp,%ecx
  80143e:	d3 e2                	shl    %cl,%edx
  801440:	39 c2                	cmp    %eax,%edx
  801442:	73 05                	jae    801449 <__udivdi3+0xf9>
  801444:	3b 34 24             	cmp    (%esp),%esi
  801447:	74 1f                	je     801468 <__udivdi3+0x118>
  801449:	89 f8                	mov    %edi,%eax
  80144b:	31 d2                	xor    %edx,%edx
  80144d:	e9 7a ff ff ff       	jmp    8013cc <__udivdi3+0x7c>
  801452:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  801458:	31 d2                	xor    %edx,%edx
  80145a:	b8 01 00 00 00       	mov    $0x1,%eax
  80145f:	e9 68 ff ff ff       	jmp    8013cc <__udivdi3+0x7c>
  801464:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801468:	8d 47 ff             	lea    -0x1(%edi),%eax
  80146b:	31 d2                	xor    %edx,%edx
  80146d:	83 c4 0c             	add    $0xc,%esp
  801470:	5e                   	pop    %esi
  801471:	5f                   	pop    %edi
  801472:	5d                   	pop    %ebp
  801473:	c3                   	ret    
  801474:	66 90                	xchg   %ax,%ax
  801476:	66 90                	xchg   %ax,%ax
  801478:	66 90                	xchg   %ax,%ax
  80147a:	66 90                	xchg   %ax,%ax
  80147c:	66 90                	xchg   %ax,%ax
  80147e:	66 90                	xchg   %ax,%ax

00801480 <__umoddi3>:
  801480:	55                   	push   %ebp
  801481:	57                   	push   %edi
  801482:	56                   	push   %esi
  801483:	83 ec 14             	sub    $0x14,%esp
  801486:	8b 44 24 28          	mov    0x28(%esp),%eax
  80148a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  80148e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
  801492:	89 c7                	mov    %eax,%edi
  801494:	89 44 24 04          	mov    %eax,0x4(%esp)
  801498:	8b 44 24 30          	mov    0x30(%esp),%eax
  80149c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  8014a0:	89 34 24             	mov    %esi,(%esp)
  8014a3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8014a7:	85 c0                	test   %eax,%eax
  8014a9:	89 c2                	mov    %eax,%edx
  8014ab:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  8014af:	75 17                	jne    8014c8 <__umoddi3+0x48>
  8014b1:	39 fe                	cmp    %edi,%esi
  8014b3:	76 4b                	jbe    801500 <__umoddi3+0x80>
  8014b5:	89 c8                	mov    %ecx,%eax
  8014b7:	89 fa                	mov    %edi,%edx
  8014b9:	f7 f6                	div    %esi
  8014bb:	89 d0                	mov    %edx,%eax
  8014bd:	31 d2                	xor    %edx,%edx
  8014bf:	83 c4 14             	add    $0x14,%esp
  8014c2:	5e                   	pop    %esi
  8014c3:	5f                   	pop    %edi
  8014c4:	5d                   	pop    %ebp
  8014c5:	c3                   	ret    
  8014c6:	66 90                	xchg   %ax,%ax
  8014c8:	39 f8                	cmp    %edi,%eax
  8014ca:	77 54                	ja     801520 <__umoddi3+0xa0>
  8014cc:	0f bd e8             	bsr    %eax,%ebp
  8014cf:	83 f5 1f             	xor    $0x1f,%ebp
  8014d2:	75 5c                	jne    801530 <__umoddi3+0xb0>
  8014d4:	8b 7c 24 08          	mov    0x8(%esp),%edi
  8014d8:	39 3c 24             	cmp    %edi,(%esp)
  8014db:	0f 87 e7 00 00 00    	ja     8015c8 <__umoddi3+0x148>
  8014e1:	8b 7c 24 04          	mov    0x4(%esp),%edi
  8014e5:	29 f1                	sub    %esi,%ecx
  8014e7:	19 c7                	sbb    %eax,%edi
  8014e9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8014ed:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  8014f1:	8b 44 24 08          	mov    0x8(%esp),%eax
  8014f5:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8014f9:	83 c4 14             	add    $0x14,%esp
  8014fc:	5e                   	pop    %esi
  8014fd:	5f                   	pop    %edi
  8014fe:	5d                   	pop    %ebp
  8014ff:	c3                   	ret    
  801500:	85 f6                	test   %esi,%esi
  801502:	89 f5                	mov    %esi,%ebp
  801504:	75 0b                	jne    801511 <__umoddi3+0x91>
  801506:	b8 01 00 00 00       	mov    $0x1,%eax
  80150b:	31 d2                	xor    %edx,%edx
  80150d:	f7 f6                	div    %esi
  80150f:	89 c5                	mov    %eax,%ebp
  801511:	8b 44 24 04          	mov    0x4(%esp),%eax
  801515:	31 d2                	xor    %edx,%edx
  801517:	f7 f5                	div    %ebp
  801519:	89 c8                	mov    %ecx,%eax
  80151b:	f7 f5                	div    %ebp
  80151d:	eb 9c                	jmp    8014bb <__umoddi3+0x3b>
  80151f:	90                   	nop
  801520:	89 c8                	mov    %ecx,%eax
  801522:	89 fa                	mov    %edi,%edx
  801524:	83 c4 14             	add    $0x14,%esp
  801527:	5e                   	pop    %esi
  801528:	5f                   	pop    %edi
  801529:	5d                   	pop    %ebp
  80152a:	c3                   	ret    
  80152b:	90                   	nop
  80152c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801530:	8b 04 24             	mov    (%esp),%eax
  801533:	be 20 00 00 00       	mov    $0x20,%esi
  801538:	89 e9                	mov    %ebp,%ecx
  80153a:	29 ee                	sub    %ebp,%esi
  80153c:	d3 e2                	shl    %cl,%edx
  80153e:	89 f1                	mov    %esi,%ecx
  801540:	d3 e8                	shr    %cl,%eax
  801542:	89 e9                	mov    %ebp,%ecx
  801544:	89 44 24 04          	mov    %eax,0x4(%esp)
  801548:	8b 04 24             	mov    (%esp),%eax
  80154b:	09 54 24 04          	or     %edx,0x4(%esp)
  80154f:	89 fa                	mov    %edi,%edx
  801551:	d3 e0                	shl    %cl,%eax
  801553:	89 f1                	mov    %esi,%ecx
  801555:	89 44 24 08          	mov    %eax,0x8(%esp)
  801559:	8b 44 24 10          	mov    0x10(%esp),%eax
  80155d:	d3 ea                	shr    %cl,%edx
  80155f:	89 e9                	mov    %ebp,%ecx
  801561:	d3 e7                	shl    %cl,%edi
  801563:	89 f1                	mov    %esi,%ecx
  801565:	d3 e8                	shr    %cl,%eax
  801567:	89 e9                	mov    %ebp,%ecx
  801569:	09 f8                	or     %edi,%eax
  80156b:	8b 7c 24 10          	mov    0x10(%esp),%edi
  80156f:	f7 74 24 04          	divl   0x4(%esp)
  801573:	d3 e7                	shl    %cl,%edi
  801575:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  801579:	89 d7                	mov    %edx,%edi
  80157b:	f7 64 24 08          	mull   0x8(%esp)
  80157f:	39 d7                	cmp    %edx,%edi
  801581:	89 c1                	mov    %eax,%ecx
  801583:	89 14 24             	mov    %edx,(%esp)
  801586:	72 2c                	jb     8015b4 <__umoddi3+0x134>
  801588:	39 44 24 0c          	cmp    %eax,0xc(%esp)
  80158c:	72 22                	jb     8015b0 <__umoddi3+0x130>
  80158e:	8b 44 24 0c          	mov    0xc(%esp),%eax
  801592:	29 c8                	sub    %ecx,%eax
  801594:	19 d7                	sbb    %edx,%edi
  801596:	89 e9                	mov    %ebp,%ecx
  801598:	89 fa                	mov    %edi,%edx
  80159a:	d3 e8                	shr    %cl,%eax
  80159c:	89 f1                	mov    %esi,%ecx
  80159e:	d3 e2                	shl    %cl,%edx
  8015a0:	89 e9                	mov    %ebp,%ecx
  8015a2:	d3 ef                	shr    %cl,%edi
  8015a4:	09 d0                	or     %edx,%eax
  8015a6:	89 fa                	mov    %edi,%edx
  8015a8:	83 c4 14             	add    $0x14,%esp
  8015ab:	5e                   	pop    %esi
  8015ac:	5f                   	pop    %edi
  8015ad:	5d                   	pop    %ebp
  8015ae:	c3                   	ret    
  8015af:	90                   	nop
  8015b0:	39 d7                	cmp    %edx,%edi
  8015b2:	75 da                	jne    80158e <__umoddi3+0x10e>
  8015b4:	8b 14 24             	mov    (%esp),%edx
  8015b7:	89 c1                	mov    %eax,%ecx
  8015b9:	2b 4c 24 08          	sub    0x8(%esp),%ecx
  8015bd:	1b 54 24 04          	sbb    0x4(%esp),%edx
  8015c1:	eb cb                	jmp    80158e <__umoddi3+0x10e>
  8015c3:	90                   	nop
  8015c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8015c8:	3b 44 24 0c          	cmp    0xc(%esp),%eax
  8015cc:	0f 82 0f ff ff ff    	jb     8014e1 <__umoddi3+0x61>
  8015d2:	e9 1a ff ff ff       	jmp    8014f1 <__umoddi3+0x71>
