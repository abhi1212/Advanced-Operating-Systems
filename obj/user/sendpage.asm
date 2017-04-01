
obj/user/sendpage:     file format elf32-i386


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
  80002c:	e8 af 01 00 00       	call   8001e0 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:
#define TEMP_ADDR	((char*)0xa00000)
#define TEMP_ADDR_CHILD	((char*)0xb00000)

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 28             	sub    $0x28,%esp
	envid_t who;

	if ((who = fork()) == 0) {
  800039:	e8 27 10 00 00       	call   801065 <fork>
  80003e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  800041:	85 c0                	test   %eax,%eax
  800043:	0f 85 bd 00 00 00    	jne    800106 <umain+0xd3>
		// Child
		ipc_recv(&who, TEMP_ADDR_CHILD, 0);
  800049:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  800050:	00 
  800051:	c7 44 24 04 00 00 b0 	movl   $0xb00000,0x4(%esp)
  800058:	00 
  800059:	8d 45 f4             	lea    -0xc(%ebp),%eax
  80005c:	89 04 24             	mov    %eax,(%esp)
  80005f:	e8 d2 12 00 00       	call   801336 <ipc_recv>
		cprintf("%x got message: %s\n", who, TEMP_ADDR_CHILD);
  800064:	c7 44 24 08 00 00 b0 	movl   $0xb00000,0x8(%esp)
  80006b:	00 
  80006c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80006f:	89 44 24 04          	mov    %eax,0x4(%esp)
  800073:	c7 04 24 40 17 80 00 	movl   $0x801740,(%esp)
  80007a:	e8 60 02 00 00       	call   8002df <cprintf>
		if (strncmp(TEMP_ADDR_CHILD, str1, strlen(str1)) == 0)
  80007f:	a1 04 20 80 00       	mov    0x802004,%eax
  800084:	89 04 24             	mov    %eax,(%esp)
  800087:	e8 44 08 00 00       	call   8008d0 <strlen>
  80008c:	89 44 24 08          	mov    %eax,0x8(%esp)
  800090:	a1 04 20 80 00       	mov    0x802004,%eax
  800095:	89 44 24 04          	mov    %eax,0x4(%esp)
  800099:	c7 04 24 00 00 b0 00 	movl   $0xb00000,(%esp)
  8000a0:	e8 3d 09 00 00       	call   8009e2 <strncmp>
  8000a5:	85 c0                	test   %eax,%eax
  8000a7:	75 0c                	jne    8000b5 <umain+0x82>
			cprintf("child received correct message\n");
  8000a9:	c7 04 24 54 17 80 00 	movl   $0x801754,(%esp)
  8000b0:	e8 2a 02 00 00       	call   8002df <cprintf>

		memcpy(TEMP_ADDR_CHILD, str2, strlen(str2) + 1);
  8000b5:	a1 00 20 80 00       	mov    0x802000,%eax
  8000ba:	89 04 24             	mov    %eax,(%esp)
  8000bd:	e8 0e 08 00 00       	call   8008d0 <strlen>
  8000c2:	83 c0 01             	add    $0x1,%eax
  8000c5:	89 44 24 08          	mov    %eax,0x8(%esp)
  8000c9:	a1 00 20 80 00       	mov    0x802000,%eax
  8000ce:	89 44 24 04          	mov    %eax,0x4(%esp)
  8000d2:	c7 04 24 00 00 b0 00 	movl   $0xb00000,(%esp)
  8000d9:	e8 2e 0a 00 00       	call   800b0c <memcpy>
		ipc_send(who, 0, TEMP_ADDR_CHILD, PTE_P | PTE_W | PTE_U);
  8000de:	c7 44 24 0c 07 00 00 	movl   $0x7,0xc(%esp)
  8000e5:	00 
  8000e6:	c7 44 24 08 00 00 b0 	movl   $0xb00000,0x8(%esp)
  8000ed:	00 
  8000ee:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  8000f5:	00 
  8000f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8000f9:	89 04 24             	mov    %eax,(%esp)
  8000fc:	e8 57 12 00 00       	call   801358 <ipc_send>
		return;
  800101:	e9 d8 00 00 00       	jmp    8001de <umain+0x1ab>
	}

	// Parent
	sys_page_alloc(thisenv->env_id, TEMP_ADDR, PTE_P | PTE_W | PTE_U);
  800106:	a1 0c 20 80 00       	mov    0x80200c,%eax
  80010b:	8b 40 48             	mov    0x48(%eax),%eax
  80010e:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  800115:	00 
  800116:	c7 44 24 04 00 00 a0 	movl   $0xa00000,0x4(%esp)
  80011d:	00 
  80011e:	89 04 24             	mov    %eax,(%esp)
  800121:	e8 fd 0b 00 00       	call   800d23 <sys_page_alloc>
	memcpy(TEMP_ADDR, str1, strlen(str1) + 1);
  800126:	a1 04 20 80 00       	mov    0x802004,%eax
  80012b:	89 04 24             	mov    %eax,(%esp)
  80012e:	e8 9d 07 00 00       	call   8008d0 <strlen>
  800133:	83 c0 01             	add    $0x1,%eax
  800136:	89 44 24 08          	mov    %eax,0x8(%esp)
  80013a:	a1 04 20 80 00       	mov    0x802004,%eax
  80013f:	89 44 24 04          	mov    %eax,0x4(%esp)
  800143:	c7 04 24 00 00 a0 00 	movl   $0xa00000,(%esp)
  80014a:	e8 bd 09 00 00       	call   800b0c <memcpy>
	ipc_send(who, 0, TEMP_ADDR, PTE_P | PTE_W | PTE_U);
  80014f:	c7 44 24 0c 07 00 00 	movl   $0x7,0xc(%esp)
  800156:	00 
  800157:	c7 44 24 08 00 00 a0 	movl   $0xa00000,0x8(%esp)
  80015e:	00 
  80015f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  800166:	00 
  800167:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80016a:	89 04 24             	mov    %eax,(%esp)
  80016d:	e8 e6 11 00 00       	call   801358 <ipc_send>

	ipc_recv(&who, TEMP_ADDR, 0);
  800172:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  800179:	00 
  80017a:	c7 44 24 04 00 00 a0 	movl   $0xa00000,0x4(%esp)
  800181:	00 
  800182:	8d 45 f4             	lea    -0xc(%ebp),%eax
  800185:	89 04 24             	mov    %eax,(%esp)
  800188:	e8 a9 11 00 00       	call   801336 <ipc_recv>
	cprintf("%x got message: %s\n", who, TEMP_ADDR);
  80018d:	c7 44 24 08 00 00 a0 	movl   $0xa00000,0x8(%esp)
  800194:	00 
  800195:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800198:	89 44 24 04          	mov    %eax,0x4(%esp)
  80019c:	c7 04 24 40 17 80 00 	movl   $0x801740,(%esp)
  8001a3:	e8 37 01 00 00       	call   8002df <cprintf>
	if (strncmp(TEMP_ADDR, str2, strlen(str2)) == 0)
  8001a8:	a1 00 20 80 00       	mov    0x802000,%eax
  8001ad:	89 04 24             	mov    %eax,(%esp)
  8001b0:	e8 1b 07 00 00       	call   8008d0 <strlen>
  8001b5:	89 44 24 08          	mov    %eax,0x8(%esp)
  8001b9:	a1 00 20 80 00       	mov    0x802000,%eax
  8001be:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001c2:	c7 04 24 00 00 a0 00 	movl   $0xa00000,(%esp)
  8001c9:	e8 14 08 00 00       	call   8009e2 <strncmp>
  8001ce:	85 c0                	test   %eax,%eax
  8001d0:	75 0c                	jne    8001de <umain+0x1ab>
		cprintf("parent received correct message\n");
  8001d2:	c7 04 24 74 17 80 00 	movl   $0x801774,(%esp)
  8001d9:	e8 01 01 00 00       	call   8002df <cprintf>
	return;
}
  8001de:	c9                   	leave  
  8001df:	c3                   	ret    

008001e0 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  8001e0:	55                   	push   %ebp
  8001e1:	89 e5                	mov    %esp,%ebp
  8001e3:	56                   	push   %esi
  8001e4:	53                   	push   %ebx
  8001e5:	83 ec 10             	sub    $0x10,%esp
  8001e8:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8001eb:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	
	thisenv = (struct Env*)envs + ENVX(sys_getenvid());
  8001ee:	e8 f2 0a 00 00       	call   800ce5 <sys_getenvid>
  8001f3:	25 ff 03 00 00       	and    $0x3ff,%eax
  8001f8:	6b c0 7c             	imul   $0x7c,%eax,%eax
  8001fb:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800200:	a3 0c 20 80 00       	mov    %eax,0x80200c

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800205:	85 db                	test   %ebx,%ebx
  800207:	7e 07                	jle    800210 <libmain+0x30>
		binaryname = argv[0];
  800209:	8b 06                	mov    (%esi),%eax
  80020b:	a3 08 20 80 00       	mov    %eax,0x802008

	// call user main routine
	umain(argc, argv);
  800210:	89 74 24 04          	mov    %esi,0x4(%esp)
  800214:	89 1c 24             	mov    %ebx,(%esp)
  800217:	e8 17 fe ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80021c:	e8 07 00 00 00       	call   800228 <exit>
}
  800221:	83 c4 10             	add    $0x10,%esp
  800224:	5b                   	pop    %ebx
  800225:	5e                   	pop    %esi
  800226:	5d                   	pop    %ebp
  800227:	c3                   	ret    

00800228 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800228:	55                   	push   %ebp
  800229:	89 e5                	mov    %esp,%ebp
  80022b:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  80022e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800235:	e8 59 0a 00 00       	call   800c93 <sys_env_destroy>
}
  80023a:	c9                   	leave  
  80023b:	c3                   	ret    

0080023c <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  80023c:	55                   	push   %ebp
  80023d:	89 e5                	mov    %esp,%ebp
  80023f:	53                   	push   %ebx
  800240:	83 ec 14             	sub    $0x14,%esp
  800243:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800246:	8b 13                	mov    (%ebx),%edx
  800248:	8d 42 01             	lea    0x1(%edx),%eax
  80024b:	89 03                	mov    %eax,(%ebx)
  80024d:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800250:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  800254:	3d ff 00 00 00       	cmp    $0xff,%eax
  800259:	75 19                	jne    800274 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  80025b:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  800262:	00 
  800263:	8d 43 08             	lea    0x8(%ebx),%eax
  800266:	89 04 24             	mov    %eax,(%esp)
  800269:	e8 e8 09 00 00       	call   800c56 <sys_cputs>
		b->idx = 0;
  80026e:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  800274:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  800278:	83 c4 14             	add    $0x14,%esp
  80027b:	5b                   	pop    %ebx
  80027c:	5d                   	pop    %ebp
  80027d:	c3                   	ret    

0080027e <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  80027e:	55                   	push   %ebp
  80027f:	89 e5                	mov    %esp,%ebp
  800281:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  800287:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  80028e:	00 00 00 
	b.cnt = 0;
  800291:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800298:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80029b:	8b 45 0c             	mov    0xc(%ebp),%eax
  80029e:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8002a2:	8b 45 08             	mov    0x8(%ebp),%eax
  8002a5:	89 44 24 08          	mov    %eax,0x8(%esp)
  8002a9:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8002af:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002b3:	c7 04 24 3c 02 80 00 	movl   $0x80023c,(%esp)
  8002ba:	e8 af 01 00 00       	call   80046e <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8002bf:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  8002c5:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002c9:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8002cf:	89 04 24             	mov    %eax,(%esp)
  8002d2:	e8 7f 09 00 00       	call   800c56 <sys_cputs>

	return b.cnt;
}
  8002d7:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8002dd:	c9                   	leave  
  8002de:	c3                   	ret    

008002df <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8002df:	55                   	push   %ebp
  8002e0:	89 e5                	mov    %esp,%ebp
  8002e2:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  8002e5:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  8002e8:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002ec:	8b 45 08             	mov    0x8(%ebp),%eax
  8002ef:	89 04 24             	mov    %eax,(%esp)
  8002f2:	e8 87 ff ff ff       	call   80027e <vcprintf>
	va_end(ap);

	return cnt;
}
  8002f7:	c9                   	leave  
  8002f8:	c3                   	ret    
  8002f9:	66 90                	xchg   %ax,%ax
  8002fb:	66 90                	xchg   %ax,%ax
  8002fd:	66 90                	xchg   %ax,%ax
  8002ff:	90                   	nop

00800300 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800300:	55                   	push   %ebp
  800301:	89 e5                	mov    %esp,%ebp
  800303:	57                   	push   %edi
  800304:	56                   	push   %esi
  800305:	53                   	push   %ebx
  800306:	83 ec 3c             	sub    $0x3c,%esp
  800309:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80030c:	89 d7                	mov    %edx,%edi
  80030e:	8b 45 08             	mov    0x8(%ebp),%eax
  800311:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800314:	8b 45 0c             	mov    0xc(%ebp),%eax
  800317:	89 c3                	mov    %eax,%ebx
  800319:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  80031c:	8b 45 10             	mov    0x10(%ebp),%eax
  80031f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800322:	b9 00 00 00 00       	mov    $0x0,%ecx
  800327:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80032a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  80032d:	39 d9                	cmp    %ebx,%ecx
  80032f:	72 05                	jb     800336 <printnum+0x36>
  800331:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  800334:	77 69                	ja     80039f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800336:	8b 4d 18             	mov    0x18(%ebp),%ecx
  800339:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  80033d:	83 ee 01             	sub    $0x1,%esi
  800340:	89 74 24 0c          	mov    %esi,0xc(%esp)
  800344:	89 44 24 08          	mov    %eax,0x8(%esp)
  800348:	8b 44 24 08          	mov    0x8(%esp),%eax
  80034c:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800350:	89 c3                	mov    %eax,%ebx
  800352:	89 d6                	mov    %edx,%esi
  800354:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800357:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  80035a:	89 54 24 08          	mov    %edx,0x8(%esp)
  80035e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800362:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800365:	89 04 24             	mov    %eax,(%esp)
  800368:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80036b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80036f:	e8 2c 11 00 00       	call   8014a0 <__udivdi3>
  800374:	89 d9                	mov    %ebx,%ecx
  800376:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80037a:	89 74 24 0c          	mov    %esi,0xc(%esp)
  80037e:	89 04 24             	mov    %eax,(%esp)
  800381:	89 54 24 04          	mov    %edx,0x4(%esp)
  800385:	89 fa                	mov    %edi,%edx
  800387:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80038a:	e8 71 ff ff ff       	call   800300 <printnum>
  80038f:	eb 1b                	jmp    8003ac <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800391:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800395:	8b 45 18             	mov    0x18(%ebp),%eax
  800398:	89 04 24             	mov    %eax,(%esp)
  80039b:	ff d3                	call   *%ebx
  80039d:	eb 03                	jmp    8003a2 <printnum+0xa2>
  80039f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8003a2:	83 ee 01             	sub    $0x1,%esi
  8003a5:	85 f6                	test   %esi,%esi
  8003a7:	7f e8                	jg     800391 <printnum+0x91>
  8003a9:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8003ac:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8003b0:	8b 7c 24 04          	mov    0x4(%esp),%edi
  8003b4:	8b 45 d8             	mov    -0x28(%ebp),%eax
  8003b7:	8b 55 dc             	mov    -0x24(%ebp),%edx
  8003ba:	89 44 24 08          	mov    %eax,0x8(%esp)
  8003be:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8003c2:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8003c5:	89 04 24             	mov    %eax,(%esp)
  8003c8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8003cb:	89 44 24 04          	mov    %eax,0x4(%esp)
  8003cf:	e8 fc 11 00 00       	call   8015d0 <__umoddi3>
  8003d4:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8003d8:	0f be 80 ec 17 80 00 	movsbl 0x8017ec(%eax),%eax
  8003df:	89 04 24             	mov    %eax,(%esp)
  8003e2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8003e5:	ff d0                	call   *%eax
}
  8003e7:	83 c4 3c             	add    $0x3c,%esp
  8003ea:	5b                   	pop    %ebx
  8003eb:	5e                   	pop    %esi
  8003ec:	5f                   	pop    %edi
  8003ed:	5d                   	pop    %ebp
  8003ee:	c3                   	ret    

008003ef <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8003ef:	55                   	push   %ebp
  8003f0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8003f2:	83 fa 01             	cmp    $0x1,%edx
  8003f5:	7e 0e                	jle    800405 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8003f7:	8b 10                	mov    (%eax),%edx
  8003f9:	8d 4a 08             	lea    0x8(%edx),%ecx
  8003fc:	89 08                	mov    %ecx,(%eax)
  8003fe:	8b 02                	mov    (%edx),%eax
  800400:	8b 52 04             	mov    0x4(%edx),%edx
  800403:	eb 22                	jmp    800427 <getuint+0x38>
	else if (lflag)
  800405:	85 d2                	test   %edx,%edx
  800407:	74 10                	je     800419 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800409:	8b 10                	mov    (%eax),%edx
  80040b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80040e:	89 08                	mov    %ecx,(%eax)
  800410:	8b 02                	mov    (%edx),%eax
  800412:	ba 00 00 00 00       	mov    $0x0,%edx
  800417:	eb 0e                	jmp    800427 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800419:	8b 10                	mov    (%eax),%edx
  80041b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80041e:	89 08                	mov    %ecx,(%eax)
  800420:	8b 02                	mov    (%edx),%eax
  800422:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800427:	5d                   	pop    %ebp
  800428:	c3                   	ret    

00800429 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800429:	55                   	push   %ebp
  80042a:	89 e5                	mov    %esp,%ebp
  80042c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80042f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800433:	8b 10                	mov    (%eax),%edx
  800435:	3b 50 04             	cmp    0x4(%eax),%edx
  800438:	73 0a                	jae    800444 <sprintputch+0x1b>
		*b->buf++ = ch;
  80043a:	8d 4a 01             	lea    0x1(%edx),%ecx
  80043d:	89 08                	mov    %ecx,(%eax)
  80043f:	8b 45 08             	mov    0x8(%ebp),%eax
  800442:	88 02                	mov    %al,(%edx)
}
  800444:	5d                   	pop    %ebp
  800445:	c3                   	ret    

00800446 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800446:	55                   	push   %ebp
  800447:	89 e5                	mov    %esp,%ebp
  800449:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  80044c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80044f:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800453:	8b 45 10             	mov    0x10(%ebp),%eax
  800456:	89 44 24 08          	mov    %eax,0x8(%esp)
  80045a:	8b 45 0c             	mov    0xc(%ebp),%eax
  80045d:	89 44 24 04          	mov    %eax,0x4(%esp)
  800461:	8b 45 08             	mov    0x8(%ebp),%eax
  800464:	89 04 24             	mov    %eax,(%esp)
  800467:	e8 02 00 00 00       	call   80046e <vprintfmt>
	va_end(ap);
}
  80046c:	c9                   	leave  
  80046d:	c3                   	ret    

0080046e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  80046e:	55                   	push   %ebp
  80046f:	89 e5                	mov    %esp,%ebp
  800471:	57                   	push   %edi
  800472:	56                   	push   %esi
  800473:	53                   	push   %ebx
  800474:	83 ec 3c             	sub    $0x3c,%esp
  800477:	8b 7d 0c             	mov    0xc(%ebp),%edi
  80047a:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80047d:	eb 14                	jmp    800493 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  80047f:	85 c0                	test   %eax,%eax
  800481:	0f 84 b3 03 00 00    	je     80083a <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
  800487:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80048b:	89 04 24             	mov    %eax,(%esp)
  80048e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800491:	89 f3                	mov    %esi,%ebx
  800493:	8d 73 01             	lea    0x1(%ebx),%esi
  800496:	0f b6 03             	movzbl (%ebx),%eax
  800499:	83 f8 25             	cmp    $0x25,%eax
  80049c:	75 e1                	jne    80047f <vprintfmt+0x11>
  80049e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
  8004a2:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  8004a9:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
  8004b0:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  8004b7:	ba 00 00 00 00       	mov    $0x0,%edx
  8004bc:	eb 1d                	jmp    8004db <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004be:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
  8004c0:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
  8004c4:	eb 15                	jmp    8004db <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004c6:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8004c8:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
  8004cc:	eb 0d                	jmp    8004db <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  8004ce:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8004d1:	89 45 dc             	mov    %eax,-0x24(%ebp)
  8004d4:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004db:	8d 5e 01             	lea    0x1(%esi),%ebx
  8004de:	0f b6 0e             	movzbl (%esi),%ecx
  8004e1:	0f b6 c1             	movzbl %cl,%eax
  8004e4:	83 e9 23             	sub    $0x23,%ecx
  8004e7:	80 f9 55             	cmp    $0x55,%cl
  8004ea:	0f 87 2a 03 00 00    	ja     80081a <vprintfmt+0x3ac>
  8004f0:	0f b6 c9             	movzbl %cl,%ecx
  8004f3:	ff 24 8d c0 18 80 00 	jmp    *0x8018c0(,%ecx,4)
  8004fa:	89 de                	mov    %ebx,%esi
  8004fc:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800501:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
  800504:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
  800508:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
  80050b:	8d 58 d0             	lea    -0x30(%eax),%ebx
  80050e:	83 fb 09             	cmp    $0x9,%ebx
  800511:	77 36                	ja     800549 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800513:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800516:	eb e9                	jmp    800501 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800518:	8b 45 14             	mov    0x14(%ebp),%eax
  80051b:	8d 48 04             	lea    0x4(%eax),%ecx
  80051e:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800521:	8b 00                	mov    (%eax),%eax
  800523:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800526:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800528:	eb 22                	jmp    80054c <vprintfmt+0xde>
  80052a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  80052d:	85 c9                	test   %ecx,%ecx
  80052f:	b8 00 00 00 00       	mov    $0x0,%eax
  800534:	0f 49 c1             	cmovns %ecx,%eax
  800537:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80053a:	89 de                	mov    %ebx,%esi
  80053c:	eb 9d                	jmp    8004db <vprintfmt+0x6d>
  80053e:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800540:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
  800547:	eb 92                	jmp    8004db <vprintfmt+0x6d>
  800549:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
  80054c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800550:	79 89                	jns    8004db <vprintfmt+0x6d>
  800552:	e9 77 ff ff ff       	jmp    8004ce <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800557:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80055a:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80055c:	e9 7a ff ff ff       	jmp    8004db <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800561:	8b 45 14             	mov    0x14(%ebp),%eax
  800564:	8d 50 04             	lea    0x4(%eax),%edx
  800567:	89 55 14             	mov    %edx,0x14(%ebp)
  80056a:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80056e:	8b 00                	mov    (%eax),%eax
  800570:	89 04 24             	mov    %eax,(%esp)
  800573:	ff 55 08             	call   *0x8(%ebp)
			break;
  800576:	e9 18 ff ff ff       	jmp    800493 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80057b:	8b 45 14             	mov    0x14(%ebp),%eax
  80057e:	8d 50 04             	lea    0x4(%eax),%edx
  800581:	89 55 14             	mov    %edx,0x14(%ebp)
  800584:	8b 00                	mov    (%eax),%eax
  800586:	99                   	cltd   
  800587:	31 d0                	xor    %edx,%eax
  800589:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80058b:	83 f8 08             	cmp    $0x8,%eax
  80058e:	7f 0b                	jg     80059b <vprintfmt+0x12d>
  800590:	8b 14 85 20 1a 80 00 	mov    0x801a20(,%eax,4),%edx
  800597:	85 d2                	test   %edx,%edx
  800599:	75 20                	jne    8005bb <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
  80059b:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80059f:	c7 44 24 08 04 18 80 	movl   $0x801804,0x8(%esp)
  8005a6:	00 
  8005a7:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8005ab:	8b 45 08             	mov    0x8(%ebp),%eax
  8005ae:	89 04 24             	mov    %eax,(%esp)
  8005b1:	e8 90 fe ff ff       	call   800446 <printfmt>
  8005b6:	e9 d8 fe ff ff       	jmp    800493 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  8005bb:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8005bf:	c7 44 24 08 0d 18 80 	movl   $0x80180d,0x8(%esp)
  8005c6:	00 
  8005c7:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8005cb:	8b 45 08             	mov    0x8(%ebp),%eax
  8005ce:	89 04 24             	mov    %eax,(%esp)
  8005d1:	e8 70 fe ff ff       	call   800446 <printfmt>
  8005d6:	e9 b8 fe ff ff       	jmp    800493 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005db:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  8005de:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8005e1:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8005e4:	8b 45 14             	mov    0x14(%ebp),%eax
  8005e7:	8d 50 04             	lea    0x4(%eax),%edx
  8005ea:	89 55 14             	mov    %edx,0x14(%ebp)
  8005ed:	8b 30                	mov    (%eax),%esi
				p = "(null)";
  8005ef:	85 f6                	test   %esi,%esi
  8005f1:	b8 fd 17 80 00       	mov    $0x8017fd,%eax
  8005f6:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
  8005f9:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
  8005fd:	0f 84 97 00 00 00    	je     80069a <vprintfmt+0x22c>
  800603:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  800607:	0f 8e 9b 00 00 00    	jle    8006a8 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
  80060d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800611:	89 34 24             	mov    %esi,(%esp)
  800614:	e8 cf 02 00 00       	call   8008e8 <strnlen>
  800619:	8b 55 d0             	mov    -0x30(%ebp),%edx
  80061c:	29 c2                	sub    %eax,%edx
  80061e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
  800621:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
  800625:	89 45 dc             	mov    %eax,-0x24(%ebp)
  800628:	89 75 d8             	mov    %esi,-0x28(%ebp)
  80062b:	8b 75 08             	mov    0x8(%ebp),%esi
  80062e:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800631:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800633:	eb 0f                	jmp    800644 <vprintfmt+0x1d6>
					putch(padc, putdat);
  800635:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800639:	8b 45 dc             	mov    -0x24(%ebp),%eax
  80063c:	89 04 24             	mov    %eax,(%esp)
  80063f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800641:	83 eb 01             	sub    $0x1,%ebx
  800644:	85 db                	test   %ebx,%ebx
  800646:	7f ed                	jg     800635 <vprintfmt+0x1c7>
  800648:	8b 75 d8             	mov    -0x28(%ebp),%esi
  80064b:	8b 55 d0             	mov    -0x30(%ebp),%edx
  80064e:	85 d2                	test   %edx,%edx
  800650:	b8 00 00 00 00       	mov    $0x0,%eax
  800655:	0f 49 c2             	cmovns %edx,%eax
  800658:	29 c2                	sub    %eax,%edx
  80065a:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80065d:	89 d7                	mov    %edx,%edi
  80065f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800662:	eb 50                	jmp    8006b4 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800664:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800668:	74 1e                	je     800688 <vprintfmt+0x21a>
  80066a:	0f be d2             	movsbl %dl,%edx
  80066d:	83 ea 20             	sub    $0x20,%edx
  800670:	83 fa 5e             	cmp    $0x5e,%edx
  800673:	76 13                	jbe    800688 <vprintfmt+0x21a>
					putch('?', putdat);
  800675:	8b 45 0c             	mov    0xc(%ebp),%eax
  800678:	89 44 24 04          	mov    %eax,0x4(%esp)
  80067c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800683:	ff 55 08             	call   *0x8(%ebp)
  800686:	eb 0d                	jmp    800695 <vprintfmt+0x227>
				else
					putch(ch, putdat);
  800688:	8b 55 0c             	mov    0xc(%ebp),%edx
  80068b:	89 54 24 04          	mov    %edx,0x4(%esp)
  80068f:	89 04 24             	mov    %eax,(%esp)
  800692:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800695:	83 ef 01             	sub    $0x1,%edi
  800698:	eb 1a                	jmp    8006b4 <vprintfmt+0x246>
  80069a:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80069d:	8b 7d dc             	mov    -0x24(%ebp),%edi
  8006a0:	89 5d 10             	mov    %ebx,0x10(%ebp)
  8006a3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  8006a6:	eb 0c                	jmp    8006b4 <vprintfmt+0x246>
  8006a8:	89 7d 0c             	mov    %edi,0xc(%ebp)
  8006ab:	8b 7d dc             	mov    -0x24(%ebp),%edi
  8006ae:	89 5d 10             	mov    %ebx,0x10(%ebp)
  8006b1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  8006b4:	83 c6 01             	add    $0x1,%esi
  8006b7:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
  8006bb:	0f be c2             	movsbl %dl,%eax
  8006be:	85 c0                	test   %eax,%eax
  8006c0:	74 27                	je     8006e9 <vprintfmt+0x27b>
  8006c2:	85 db                	test   %ebx,%ebx
  8006c4:	78 9e                	js     800664 <vprintfmt+0x1f6>
  8006c6:	83 eb 01             	sub    $0x1,%ebx
  8006c9:	79 99                	jns    800664 <vprintfmt+0x1f6>
  8006cb:	89 f8                	mov    %edi,%eax
  8006cd:	8b 7d 0c             	mov    0xc(%ebp),%edi
  8006d0:	8b 75 08             	mov    0x8(%ebp),%esi
  8006d3:	89 c3                	mov    %eax,%ebx
  8006d5:	eb 1a                	jmp    8006f1 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8006d7:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8006db:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  8006e2:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8006e4:	83 eb 01             	sub    $0x1,%ebx
  8006e7:	eb 08                	jmp    8006f1 <vprintfmt+0x283>
  8006e9:	89 fb                	mov    %edi,%ebx
  8006eb:	8b 75 08             	mov    0x8(%ebp),%esi
  8006ee:	8b 7d 0c             	mov    0xc(%ebp),%edi
  8006f1:	85 db                	test   %ebx,%ebx
  8006f3:	7f e2                	jg     8006d7 <vprintfmt+0x269>
  8006f5:	89 75 08             	mov    %esi,0x8(%ebp)
  8006f8:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8006fb:	e9 93 fd ff ff       	jmp    800493 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800700:	83 fa 01             	cmp    $0x1,%edx
  800703:	7e 16                	jle    80071b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
  800705:	8b 45 14             	mov    0x14(%ebp),%eax
  800708:	8d 50 08             	lea    0x8(%eax),%edx
  80070b:	89 55 14             	mov    %edx,0x14(%ebp)
  80070e:	8b 50 04             	mov    0x4(%eax),%edx
  800711:	8b 00                	mov    (%eax),%eax
  800713:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800716:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  800719:	eb 32                	jmp    80074d <vprintfmt+0x2df>
	else if (lflag)
  80071b:	85 d2                	test   %edx,%edx
  80071d:	74 18                	je     800737 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
  80071f:	8b 45 14             	mov    0x14(%ebp),%eax
  800722:	8d 50 04             	lea    0x4(%eax),%edx
  800725:	89 55 14             	mov    %edx,0x14(%ebp)
  800728:	8b 30                	mov    (%eax),%esi
  80072a:	89 75 e0             	mov    %esi,-0x20(%ebp)
  80072d:	89 f0                	mov    %esi,%eax
  80072f:	c1 f8 1f             	sar    $0x1f,%eax
  800732:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800735:	eb 16                	jmp    80074d <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
  800737:	8b 45 14             	mov    0x14(%ebp),%eax
  80073a:	8d 50 04             	lea    0x4(%eax),%edx
  80073d:	89 55 14             	mov    %edx,0x14(%ebp)
  800740:	8b 30                	mov    (%eax),%esi
  800742:	89 75 e0             	mov    %esi,-0x20(%ebp)
  800745:	89 f0                	mov    %esi,%eax
  800747:	c1 f8 1f             	sar    $0x1f,%eax
  80074a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  80074d:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800750:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800753:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800758:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  80075c:	0f 89 80 00 00 00    	jns    8007e2 <vprintfmt+0x374>
				putch('-', putdat);
  800762:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800766:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  80076d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  800770:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800773:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  800776:	f7 d8                	neg    %eax
  800778:	83 d2 00             	adc    $0x0,%edx
  80077b:	f7 da                	neg    %edx
			}
			base = 10;
  80077d:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800782:	eb 5e                	jmp    8007e2 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800784:	8d 45 14             	lea    0x14(%ebp),%eax
  800787:	e8 63 fc ff ff       	call   8003ef <getuint>
			base = 10;
  80078c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800791:	eb 4f                	jmp    8007e2 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
  800793:	8d 45 14             	lea    0x14(%ebp),%eax
  800796:	e8 54 fc ff ff       	call   8003ef <getuint>
			base = 8;
  80079b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  8007a0:	eb 40                	jmp    8007e2 <vprintfmt+0x374>

		// pointer
		case 'p':
			putch('0', putdat);
  8007a2:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8007a6:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  8007ad:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  8007b0:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8007b4:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  8007bb:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8007be:	8b 45 14             	mov    0x14(%ebp),%eax
  8007c1:	8d 50 04             	lea    0x4(%eax),%edx
  8007c4:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  8007c7:	8b 00                	mov    (%eax),%eax
  8007c9:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8007ce:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8007d3:	eb 0d                	jmp    8007e2 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8007d5:	8d 45 14             	lea    0x14(%ebp),%eax
  8007d8:	e8 12 fc ff ff       	call   8003ef <getuint>
			base = 16;
  8007dd:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8007e2:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
  8007e6:	89 74 24 10          	mov    %esi,0x10(%esp)
  8007ea:	8b 75 dc             	mov    -0x24(%ebp),%esi
  8007ed:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8007f1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8007f5:	89 04 24             	mov    %eax,(%esp)
  8007f8:	89 54 24 04          	mov    %edx,0x4(%esp)
  8007fc:	89 fa                	mov    %edi,%edx
  8007fe:	8b 45 08             	mov    0x8(%ebp),%eax
  800801:	e8 fa fa ff ff       	call   800300 <printnum>
			break;
  800806:	e9 88 fc ff ff       	jmp    800493 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80080b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80080f:	89 04 24             	mov    %eax,(%esp)
  800812:	ff 55 08             	call   *0x8(%ebp)
			break;
  800815:	e9 79 fc ff ff       	jmp    800493 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  80081a:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80081e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  800825:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  800828:	89 f3                	mov    %esi,%ebx
  80082a:	eb 03                	jmp    80082f <vprintfmt+0x3c1>
  80082c:	83 eb 01             	sub    $0x1,%ebx
  80082f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
  800833:	75 f7                	jne    80082c <vprintfmt+0x3be>
  800835:	e9 59 fc ff ff       	jmp    800493 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  80083a:	83 c4 3c             	add    $0x3c,%esp
  80083d:	5b                   	pop    %ebx
  80083e:	5e                   	pop    %esi
  80083f:	5f                   	pop    %edi
  800840:	5d                   	pop    %ebp
  800841:	c3                   	ret    

00800842 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800842:	55                   	push   %ebp
  800843:	89 e5                	mov    %esp,%ebp
  800845:	83 ec 28             	sub    $0x28,%esp
  800848:	8b 45 08             	mov    0x8(%ebp),%eax
  80084b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80084e:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800851:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800855:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800858:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80085f:	85 c0                	test   %eax,%eax
  800861:	74 30                	je     800893 <vsnprintf+0x51>
  800863:	85 d2                	test   %edx,%edx
  800865:	7e 2c                	jle    800893 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800867:	8b 45 14             	mov    0x14(%ebp),%eax
  80086a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80086e:	8b 45 10             	mov    0x10(%ebp),%eax
  800871:	89 44 24 08          	mov    %eax,0x8(%esp)
  800875:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800878:	89 44 24 04          	mov    %eax,0x4(%esp)
  80087c:	c7 04 24 29 04 80 00 	movl   $0x800429,(%esp)
  800883:	e8 e6 fb ff ff       	call   80046e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800888:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80088b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80088e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800891:	eb 05                	jmp    800898 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800893:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800898:	c9                   	leave  
  800899:	c3                   	ret    

0080089a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80089a:	55                   	push   %ebp
  80089b:	89 e5                	mov    %esp,%ebp
  80089d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8008a0:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8008a3:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8008a7:	8b 45 10             	mov    0x10(%ebp),%eax
  8008aa:	89 44 24 08          	mov    %eax,0x8(%esp)
  8008ae:	8b 45 0c             	mov    0xc(%ebp),%eax
  8008b1:	89 44 24 04          	mov    %eax,0x4(%esp)
  8008b5:	8b 45 08             	mov    0x8(%ebp),%eax
  8008b8:	89 04 24             	mov    %eax,(%esp)
  8008bb:	e8 82 ff ff ff       	call   800842 <vsnprintf>
	va_end(ap);

	return rc;
}
  8008c0:	c9                   	leave  
  8008c1:	c3                   	ret    
  8008c2:	66 90                	xchg   %ax,%ax
  8008c4:	66 90                	xchg   %ax,%ax
  8008c6:	66 90                	xchg   %ax,%ax
  8008c8:	66 90                	xchg   %ax,%ax
  8008ca:	66 90                	xchg   %ax,%ax
  8008cc:	66 90                	xchg   %ax,%ax
  8008ce:	66 90                	xchg   %ax,%ax

008008d0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8008d0:	55                   	push   %ebp
  8008d1:	89 e5                	mov    %esp,%ebp
  8008d3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8008d6:	b8 00 00 00 00       	mov    $0x0,%eax
  8008db:	eb 03                	jmp    8008e0 <strlen+0x10>
		n++;
  8008dd:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8008e0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8008e4:	75 f7                	jne    8008dd <strlen+0xd>
		n++;
	return n;
}
  8008e6:	5d                   	pop    %ebp
  8008e7:	c3                   	ret    

008008e8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8008e8:	55                   	push   %ebp
  8008e9:	89 e5                	mov    %esp,%ebp
  8008eb:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8008ee:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8008f1:	b8 00 00 00 00       	mov    $0x0,%eax
  8008f6:	eb 03                	jmp    8008fb <strnlen+0x13>
		n++;
  8008f8:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8008fb:	39 d0                	cmp    %edx,%eax
  8008fd:	74 06                	je     800905 <strnlen+0x1d>
  8008ff:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  800903:	75 f3                	jne    8008f8 <strnlen+0x10>
		n++;
	return n;
}
  800905:	5d                   	pop    %ebp
  800906:	c3                   	ret    

00800907 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800907:	55                   	push   %ebp
  800908:	89 e5                	mov    %esp,%ebp
  80090a:	53                   	push   %ebx
  80090b:	8b 45 08             	mov    0x8(%ebp),%eax
  80090e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800911:	89 c2                	mov    %eax,%edx
  800913:	83 c2 01             	add    $0x1,%edx
  800916:	83 c1 01             	add    $0x1,%ecx
  800919:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  80091d:	88 5a ff             	mov    %bl,-0x1(%edx)
  800920:	84 db                	test   %bl,%bl
  800922:	75 ef                	jne    800913 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800924:	5b                   	pop    %ebx
  800925:	5d                   	pop    %ebp
  800926:	c3                   	ret    

00800927 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800927:	55                   	push   %ebp
  800928:	89 e5                	mov    %esp,%ebp
  80092a:	53                   	push   %ebx
  80092b:	83 ec 08             	sub    $0x8,%esp
  80092e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800931:	89 1c 24             	mov    %ebx,(%esp)
  800934:	e8 97 ff ff ff       	call   8008d0 <strlen>
	strcpy(dst + len, src);
  800939:	8b 55 0c             	mov    0xc(%ebp),%edx
  80093c:	89 54 24 04          	mov    %edx,0x4(%esp)
  800940:	01 d8                	add    %ebx,%eax
  800942:	89 04 24             	mov    %eax,(%esp)
  800945:	e8 bd ff ff ff       	call   800907 <strcpy>
	return dst;
}
  80094a:	89 d8                	mov    %ebx,%eax
  80094c:	83 c4 08             	add    $0x8,%esp
  80094f:	5b                   	pop    %ebx
  800950:	5d                   	pop    %ebp
  800951:	c3                   	ret    

00800952 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800952:	55                   	push   %ebp
  800953:	89 e5                	mov    %esp,%ebp
  800955:	56                   	push   %esi
  800956:	53                   	push   %ebx
  800957:	8b 75 08             	mov    0x8(%ebp),%esi
  80095a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80095d:	89 f3                	mov    %esi,%ebx
  80095f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800962:	89 f2                	mov    %esi,%edx
  800964:	eb 0f                	jmp    800975 <strncpy+0x23>
		*dst++ = *src;
  800966:	83 c2 01             	add    $0x1,%edx
  800969:	0f b6 01             	movzbl (%ecx),%eax
  80096c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80096f:	80 39 01             	cmpb   $0x1,(%ecx)
  800972:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800975:	39 da                	cmp    %ebx,%edx
  800977:	75 ed                	jne    800966 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800979:	89 f0                	mov    %esi,%eax
  80097b:	5b                   	pop    %ebx
  80097c:	5e                   	pop    %esi
  80097d:	5d                   	pop    %ebp
  80097e:	c3                   	ret    

0080097f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80097f:	55                   	push   %ebp
  800980:	89 e5                	mov    %esp,%ebp
  800982:	56                   	push   %esi
  800983:	53                   	push   %ebx
  800984:	8b 75 08             	mov    0x8(%ebp),%esi
  800987:	8b 55 0c             	mov    0xc(%ebp),%edx
  80098a:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80098d:	89 f0                	mov    %esi,%eax
  80098f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800993:	85 c9                	test   %ecx,%ecx
  800995:	75 0b                	jne    8009a2 <strlcpy+0x23>
  800997:	eb 1d                	jmp    8009b6 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800999:	83 c0 01             	add    $0x1,%eax
  80099c:	83 c2 01             	add    $0x1,%edx
  80099f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8009a2:	39 d8                	cmp    %ebx,%eax
  8009a4:	74 0b                	je     8009b1 <strlcpy+0x32>
  8009a6:	0f b6 0a             	movzbl (%edx),%ecx
  8009a9:	84 c9                	test   %cl,%cl
  8009ab:	75 ec                	jne    800999 <strlcpy+0x1a>
  8009ad:	89 c2                	mov    %eax,%edx
  8009af:	eb 02                	jmp    8009b3 <strlcpy+0x34>
  8009b1:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
  8009b3:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  8009b6:	29 f0                	sub    %esi,%eax
}
  8009b8:	5b                   	pop    %ebx
  8009b9:	5e                   	pop    %esi
  8009ba:	5d                   	pop    %ebp
  8009bb:	c3                   	ret    

008009bc <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8009bc:	55                   	push   %ebp
  8009bd:	89 e5                	mov    %esp,%ebp
  8009bf:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8009c2:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8009c5:	eb 06                	jmp    8009cd <strcmp+0x11>
		p++, q++;
  8009c7:	83 c1 01             	add    $0x1,%ecx
  8009ca:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8009cd:	0f b6 01             	movzbl (%ecx),%eax
  8009d0:	84 c0                	test   %al,%al
  8009d2:	74 04                	je     8009d8 <strcmp+0x1c>
  8009d4:	3a 02                	cmp    (%edx),%al
  8009d6:	74 ef                	je     8009c7 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8009d8:	0f b6 c0             	movzbl %al,%eax
  8009db:	0f b6 12             	movzbl (%edx),%edx
  8009de:	29 d0                	sub    %edx,%eax
}
  8009e0:	5d                   	pop    %ebp
  8009e1:	c3                   	ret    

008009e2 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8009e2:	55                   	push   %ebp
  8009e3:	89 e5                	mov    %esp,%ebp
  8009e5:	53                   	push   %ebx
  8009e6:	8b 45 08             	mov    0x8(%ebp),%eax
  8009e9:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009ec:	89 c3                	mov    %eax,%ebx
  8009ee:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  8009f1:	eb 06                	jmp    8009f9 <strncmp+0x17>
		n--, p++, q++;
  8009f3:	83 c0 01             	add    $0x1,%eax
  8009f6:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8009f9:	39 d8                	cmp    %ebx,%eax
  8009fb:	74 15                	je     800a12 <strncmp+0x30>
  8009fd:	0f b6 08             	movzbl (%eax),%ecx
  800a00:	84 c9                	test   %cl,%cl
  800a02:	74 04                	je     800a08 <strncmp+0x26>
  800a04:	3a 0a                	cmp    (%edx),%cl
  800a06:	74 eb                	je     8009f3 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800a08:	0f b6 00             	movzbl (%eax),%eax
  800a0b:	0f b6 12             	movzbl (%edx),%edx
  800a0e:	29 d0                	sub    %edx,%eax
  800a10:	eb 05                	jmp    800a17 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800a12:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800a17:	5b                   	pop    %ebx
  800a18:	5d                   	pop    %ebp
  800a19:	c3                   	ret    

00800a1a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800a1a:	55                   	push   %ebp
  800a1b:	89 e5                	mov    %esp,%ebp
  800a1d:	8b 45 08             	mov    0x8(%ebp),%eax
  800a20:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800a24:	eb 07                	jmp    800a2d <strchr+0x13>
		if (*s == c)
  800a26:	38 ca                	cmp    %cl,%dl
  800a28:	74 0f                	je     800a39 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800a2a:	83 c0 01             	add    $0x1,%eax
  800a2d:	0f b6 10             	movzbl (%eax),%edx
  800a30:	84 d2                	test   %dl,%dl
  800a32:	75 f2                	jne    800a26 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800a34:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a39:	5d                   	pop    %ebp
  800a3a:	c3                   	ret    

00800a3b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800a3b:	55                   	push   %ebp
  800a3c:	89 e5                	mov    %esp,%ebp
  800a3e:	8b 45 08             	mov    0x8(%ebp),%eax
  800a41:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800a45:	eb 07                	jmp    800a4e <strfind+0x13>
		if (*s == c)
  800a47:	38 ca                	cmp    %cl,%dl
  800a49:	74 0a                	je     800a55 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  800a4b:	83 c0 01             	add    $0x1,%eax
  800a4e:	0f b6 10             	movzbl (%eax),%edx
  800a51:	84 d2                	test   %dl,%dl
  800a53:	75 f2                	jne    800a47 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
  800a55:	5d                   	pop    %ebp
  800a56:	c3                   	ret    

00800a57 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800a57:	55                   	push   %ebp
  800a58:	89 e5                	mov    %esp,%ebp
  800a5a:	57                   	push   %edi
  800a5b:	56                   	push   %esi
  800a5c:	53                   	push   %ebx
  800a5d:	8b 7d 08             	mov    0x8(%ebp),%edi
  800a60:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800a63:	85 c9                	test   %ecx,%ecx
  800a65:	74 36                	je     800a9d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800a67:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800a6d:	75 28                	jne    800a97 <memset+0x40>
  800a6f:	f6 c1 03             	test   $0x3,%cl
  800a72:	75 23                	jne    800a97 <memset+0x40>
		c &= 0xFF;
  800a74:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800a78:	89 d3                	mov    %edx,%ebx
  800a7a:	c1 e3 08             	shl    $0x8,%ebx
  800a7d:	89 d6                	mov    %edx,%esi
  800a7f:	c1 e6 18             	shl    $0x18,%esi
  800a82:	89 d0                	mov    %edx,%eax
  800a84:	c1 e0 10             	shl    $0x10,%eax
  800a87:	09 f0                	or     %esi,%eax
  800a89:	09 c2                	or     %eax,%edx
  800a8b:	89 d0                	mov    %edx,%eax
  800a8d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800a8f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800a92:	fc                   	cld    
  800a93:	f3 ab                	rep stos %eax,%es:(%edi)
  800a95:	eb 06                	jmp    800a9d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800a97:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a9a:	fc                   	cld    
  800a9b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800a9d:	89 f8                	mov    %edi,%eax
  800a9f:	5b                   	pop    %ebx
  800aa0:	5e                   	pop    %esi
  800aa1:	5f                   	pop    %edi
  800aa2:	5d                   	pop    %ebp
  800aa3:	c3                   	ret    

00800aa4 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800aa4:	55                   	push   %ebp
  800aa5:	89 e5                	mov    %esp,%ebp
  800aa7:	57                   	push   %edi
  800aa8:	56                   	push   %esi
  800aa9:	8b 45 08             	mov    0x8(%ebp),%eax
  800aac:	8b 75 0c             	mov    0xc(%ebp),%esi
  800aaf:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800ab2:	39 c6                	cmp    %eax,%esi
  800ab4:	73 35                	jae    800aeb <memmove+0x47>
  800ab6:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800ab9:	39 d0                	cmp    %edx,%eax
  800abb:	73 2e                	jae    800aeb <memmove+0x47>
		s += n;
		d += n;
  800abd:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
  800ac0:	89 d6                	mov    %edx,%esi
  800ac2:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800ac4:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800aca:	75 13                	jne    800adf <memmove+0x3b>
  800acc:	f6 c1 03             	test   $0x3,%cl
  800acf:	75 0e                	jne    800adf <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800ad1:	83 ef 04             	sub    $0x4,%edi
  800ad4:	8d 72 fc             	lea    -0x4(%edx),%esi
  800ad7:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800ada:	fd                   	std    
  800adb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800add:	eb 09                	jmp    800ae8 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800adf:	83 ef 01             	sub    $0x1,%edi
  800ae2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800ae5:	fd                   	std    
  800ae6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800ae8:	fc                   	cld    
  800ae9:	eb 1d                	jmp    800b08 <memmove+0x64>
  800aeb:	89 f2                	mov    %esi,%edx
  800aed:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800aef:	f6 c2 03             	test   $0x3,%dl
  800af2:	75 0f                	jne    800b03 <memmove+0x5f>
  800af4:	f6 c1 03             	test   $0x3,%cl
  800af7:	75 0a                	jne    800b03 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800af9:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800afc:	89 c7                	mov    %eax,%edi
  800afe:	fc                   	cld    
  800aff:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800b01:	eb 05                	jmp    800b08 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800b03:	89 c7                	mov    %eax,%edi
  800b05:	fc                   	cld    
  800b06:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800b08:	5e                   	pop    %esi
  800b09:	5f                   	pop    %edi
  800b0a:	5d                   	pop    %ebp
  800b0b:	c3                   	ret    

00800b0c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800b0c:	55                   	push   %ebp
  800b0d:	89 e5                	mov    %esp,%ebp
  800b0f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800b12:	8b 45 10             	mov    0x10(%ebp),%eax
  800b15:	89 44 24 08          	mov    %eax,0x8(%esp)
  800b19:	8b 45 0c             	mov    0xc(%ebp),%eax
  800b1c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800b20:	8b 45 08             	mov    0x8(%ebp),%eax
  800b23:	89 04 24             	mov    %eax,(%esp)
  800b26:	e8 79 ff ff ff       	call   800aa4 <memmove>
}
  800b2b:	c9                   	leave  
  800b2c:	c3                   	ret    

00800b2d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800b2d:	55                   	push   %ebp
  800b2e:	89 e5                	mov    %esp,%ebp
  800b30:	56                   	push   %esi
  800b31:	53                   	push   %ebx
  800b32:	8b 55 08             	mov    0x8(%ebp),%edx
  800b35:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800b38:	89 d6                	mov    %edx,%esi
  800b3a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800b3d:	eb 1a                	jmp    800b59 <memcmp+0x2c>
		if (*s1 != *s2)
  800b3f:	0f b6 02             	movzbl (%edx),%eax
  800b42:	0f b6 19             	movzbl (%ecx),%ebx
  800b45:	38 d8                	cmp    %bl,%al
  800b47:	74 0a                	je     800b53 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800b49:	0f b6 c0             	movzbl %al,%eax
  800b4c:	0f b6 db             	movzbl %bl,%ebx
  800b4f:	29 d8                	sub    %ebx,%eax
  800b51:	eb 0f                	jmp    800b62 <memcmp+0x35>
		s1++, s2++;
  800b53:	83 c2 01             	add    $0x1,%edx
  800b56:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800b59:	39 f2                	cmp    %esi,%edx
  800b5b:	75 e2                	jne    800b3f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800b5d:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800b62:	5b                   	pop    %ebx
  800b63:	5e                   	pop    %esi
  800b64:	5d                   	pop    %ebp
  800b65:	c3                   	ret    

00800b66 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800b66:	55                   	push   %ebp
  800b67:	89 e5                	mov    %esp,%ebp
  800b69:	8b 45 08             	mov    0x8(%ebp),%eax
  800b6c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800b6f:	89 c2                	mov    %eax,%edx
  800b71:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800b74:	eb 07                	jmp    800b7d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800b76:	38 08                	cmp    %cl,(%eax)
  800b78:	74 07                	je     800b81 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800b7a:	83 c0 01             	add    $0x1,%eax
  800b7d:	39 d0                	cmp    %edx,%eax
  800b7f:	72 f5                	jb     800b76 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800b81:	5d                   	pop    %ebp
  800b82:	c3                   	ret    

00800b83 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800b83:	55                   	push   %ebp
  800b84:	89 e5                	mov    %esp,%ebp
  800b86:	57                   	push   %edi
  800b87:	56                   	push   %esi
  800b88:	53                   	push   %ebx
  800b89:	8b 55 08             	mov    0x8(%ebp),%edx
  800b8c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b8f:	eb 03                	jmp    800b94 <strtol+0x11>
		s++;
  800b91:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b94:	0f b6 0a             	movzbl (%edx),%ecx
  800b97:	80 f9 09             	cmp    $0x9,%cl
  800b9a:	74 f5                	je     800b91 <strtol+0xe>
  800b9c:	80 f9 20             	cmp    $0x20,%cl
  800b9f:	74 f0                	je     800b91 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800ba1:	80 f9 2b             	cmp    $0x2b,%cl
  800ba4:	75 0a                	jne    800bb0 <strtol+0x2d>
		s++;
  800ba6:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800ba9:	bf 00 00 00 00       	mov    $0x0,%edi
  800bae:	eb 11                	jmp    800bc1 <strtol+0x3e>
  800bb0:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800bb5:	80 f9 2d             	cmp    $0x2d,%cl
  800bb8:	75 07                	jne    800bc1 <strtol+0x3e>
		s++, neg = 1;
  800bba:	8d 52 01             	lea    0x1(%edx),%edx
  800bbd:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800bc1:	a9 ef ff ff ff       	test   $0xffffffef,%eax
  800bc6:	75 15                	jne    800bdd <strtol+0x5a>
  800bc8:	80 3a 30             	cmpb   $0x30,(%edx)
  800bcb:	75 10                	jne    800bdd <strtol+0x5a>
  800bcd:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800bd1:	75 0a                	jne    800bdd <strtol+0x5a>
		s += 2, base = 16;
  800bd3:	83 c2 02             	add    $0x2,%edx
  800bd6:	b8 10 00 00 00       	mov    $0x10,%eax
  800bdb:	eb 10                	jmp    800bed <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
  800bdd:	85 c0                	test   %eax,%eax
  800bdf:	75 0c                	jne    800bed <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800be1:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800be3:	80 3a 30             	cmpb   $0x30,(%edx)
  800be6:	75 05                	jne    800bed <strtol+0x6a>
		s++, base = 8;
  800be8:	83 c2 01             	add    $0x1,%edx
  800beb:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
  800bed:	bb 00 00 00 00       	mov    $0x0,%ebx
  800bf2:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800bf5:	0f b6 0a             	movzbl (%edx),%ecx
  800bf8:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800bfb:	89 f0                	mov    %esi,%eax
  800bfd:	3c 09                	cmp    $0x9,%al
  800bff:	77 08                	ja     800c09 <strtol+0x86>
			dig = *s - '0';
  800c01:	0f be c9             	movsbl %cl,%ecx
  800c04:	83 e9 30             	sub    $0x30,%ecx
  800c07:	eb 20                	jmp    800c29 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
  800c09:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800c0c:	89 f0                	mov    %esi,%eax
  800c0e:	3c 19                	cmp    $0x19,%al
  800c10:	77 08                	ja     800c1a <strtol+0x97>
			dig = *s - 'a' + 10;
  800c12:	0f be c9             	movsbl %cl,%ecx
  800c15:	83 e9 57             	sub    $0x57,%ecx
  800c18:	eb 0f                	jmp    800c29 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
  800c1a:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800c1d:	89 f0                	mov    %esi,%eax
  800c1f:	3c 19                	cmp    $0x19,%al
  800c21:	77 16                	ja     800c39 <strtol+0xb6>
			dig = *s - 'A' + 10;
  800c23:	0f be c9             	movsbl %cl,%ecx
  800c26:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800c29:	3b 4d 10             	cmp    0x10(%ebp),%ecx
  800c2c:	7d 0f                	jge    800c3d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
  800c2e:	83 c2 01             	add    $0x1,%edx
  800c31:	0f af 5d 10          	imul   0x10(%ebp),%ebx
  800c35:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
  800c37:	eb bc                	jmp    800bf5 <strtol+0x72>
  800c39:	89 d8                	mov    %ebx,%eax
  800c3b:	eb 02                	jmp    800c3f <strtol+0xbc>
  800c3d:	89 d8                	mov    %ebx,%eax

	if (endptr)
  800c3f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800c43:	74 05                	je     800c4a <strtol+0xc7>
		*endptr = (char *) s;
  800c45:	8b 75 0c             	mov    0xc(%ebp),%esi
  800c48:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
  800c4a:	f7 d8                	neg    %eax
  800c4c:	85 ff                	test   %edi,%edi
  800c4e:	0f 44 c3             	cmove  %ebx,%eax
}
  800c51:	5b                   	pop    %ebx
  800c52:	5e                   	pop    %esi
  800c53:	5f                   	pop    %edi
  800c54:	5d                   	pop    %ebp
  800c55:	c3                   	ret    

00800c56 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800c56:	55                   	push   %ebp
  800c57:	89 e5                	mov    %esp,%ebp
  800c59:	57                   	push   %edi
  800c5a:	56                   	push   %esi
  800c5b:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c5c:	b8 00 00 00 00       	mov    $0x0,%eax
  800c61:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c64:	8b 55 08             	mov    0x8(%ebp),%edx
  800c67:	89 c3                	mov    %eax,%ebx
  800c69:	89 c7                	mov    %eax,%edi
  800c6b:	89 c6                	mov    %eax,%esi
  800c6d:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800c6f:	5b                   	pop    %ebx
  800c70:	5e                   	pop    %esi
  800c71:	5f                   	pop    %edi
  800c72:	5d                   	pop    %ebp
  800c73:	c3                   	ret    

00800c74 <sys_cgetc>:

int
sys_cgetc(void)
{
  800c74:	55                   	push   %ebp
  800c75:	89 e5                	mov    %esp,%ebp
  800c77:	57                   	push   %edi
  800c78:	56                   	push   %esi
  800c79:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c7a:	ba 00 00 00 00       	mov    $0x0,%edx
  800c7f:	b8 01 00 00 00       	mov    $0x1,%eax
  800c84:	89 d1                	mov    %edx,%ecx
  800c86:	89 d3                	mov    %edx,%ebx
  800c88:	89 d7                	mov    %edx,%edi
  800c8a:	89 d6                	mov    %edx,%esi
  800c8c:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800c8e:	5b                   	pop    %ebx
  800c8f:	5e                   	pop    %esi
  800c90:	5f                   	pop    %edi
  800c91:	5d                   	pop    %ebp
  800c92:	c3                   	ret    

00800c93 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800c93:	55                   	push   %ebp
  800c94:	89 e5                	mov    %esp,%ebp
  800c96:	57                   	push   %edi
  800c97:	56                   	push   %esi
  800c98:	53                   	push   %ebx
  800c99:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c9c:	b9 00 00 00 00       	mov    $0x0,%ecx
  800ca1:	b8 03 00 00 00       	mov    $0x3,%eax
  800ca6:	8b 55 08             	mov    0x8(%ebp),%edx
  800ca9:	89 cb                	mov    %ecx,%ebx
  800cab:	89 cf                	mov    %ecx,%edi
  800cad:	89 ce                	mov    %ecx,%esi
  800caf:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800cb1:	85 c0                	test   %eax,%eax
  800cb3:	7e 28                	jle    800cdd <sys_env_destroy+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800cb5:	89 44 24 10          	mov    %eax,0x10(%esp)
  800cb9:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800cc0:	00 
  800cc1:	c7 44 24 08 44 1a 80 	movl   $0x801a44,0x8(%esp)
  800cc8:	00 
  800cc9:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800cd0:	00 
  800cd1:	c7 04 24 61 1a 80 00 	movl   $0x801a61,(%esp)
  800cd8:	e8 d5 06 00 00       	call   8013b2 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800cdd:	83 c4 2c             	add    $0x2c,%esp
  800ce0:	5b                   	pop    %ebx
  800ce1:	5e                   	pop    %esi
  800ce2:	5f                   	pop    %edi
  800ce3:	5d                   	pop    %ebp
  800ce4:	c3                   	ret    

00800ce5 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800ce5:	55                   	push   %ebp
  800ce6:	89 e5                	mov    %esp,%ebp
  800ce8:	57                   	push   %edi
  800ce9:	56                   	push   %esi
  800cea:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ceb:	ba 00 00 00 00       	mov    $0x0,%edx
  800cf0:	b8 02 00 00 00       	mov    $0x2,%eax
  800cf5:	89 d1                	mov    %edx,%ecx
  800cf7:	89 d3                	mov    %edx,%ebx
  800cf9:	89 d7                	mov    %edx,%edi
  800cfb:	89 d6                	mov    %edx,%esi
  800cfd:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800cff:	5b                   	pop    %ebx
  800d00:	5e                   	pop    %esi
  800d01:	5f                   	pop    %edi
  800d02:	5d                   	pop    %ebp
  800d03:	c3                   	ret    

00800d04 <sys_yield>:

void
sys_yield(void)
{
  800d04:	55                   	push   %ebp
  800d05:	89 e5                	mov    %esp,%ebp
  800d07:	57                   	push   %edi
  800d08:	56                   	push   %esi
  800d09:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d0a:	ba 00 00 00 00       	mov    $0x0,%edx
  800d0f:	b8 0a 00 00 00       	mov    $0xa,%eax
  800d14:	89 d1                	mov    %edx,%ecx
  800d16:	89 d3                	mov    %edx,%ebx
  800d18:	89 d7                	mov    %edx,%edi
  800d1a:	89 d6                	mov    %edx,%esi
  800d1c:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800d1e:	5b                   	pop    %ebx
  800d1f:	5e                   	pop    %esi
  800d20:	5f                   	pop    %edi
  800d21:	5d                   	pop    %ebp
  800d22:	c3                   	ret    

00800d23 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800d23:	55                   	push   %ebp
  800d24:	89 e5                	mov    %esp,%ebp
  800d26:	57                   	push   %edi
  800d27:	56                   	push   %esi
  800d28:	53                   	push   %ebx
  800d29:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d2c:	be 00 00 00 00       	mov    $0x0,%esi
  800d31:	b8 04 00 00 00       	mov    $0x4,%eax
  800d36:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d39:	8b 55 08             	mov    0x8(%ebp),%edx
  800d3c:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800d3f:	89 f7                	mov    %esi,%edi
  800d41:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800d43:	85 c0                	test   %eax,%eax
  800d45:	7e 28                	jle    800d6f <sys_page_alloc+0x4c>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d47:	89 44 24 10          	mov    %eax,0x10(%esp)
  800d4b:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
  800d52:	00 
  800d53:	c7 44 24 08 44 1a 80 	movl   $0x801a44,0x8(%esp)
  800d5a:	00 
  800d5b:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800d62:	00 
  800d63:	c7 04 24 61 1a 80 00 	movl   $0x801a61,(%esp)
  800d6a:	e8 43 06 00 00       	call   8013b2 <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  800d6f:	83 c4 2c             	add    $0x2c,%esp
  800d72:	5b                   	pop    %ebx
  800d73:	5e                   	pop    %esi
  800d74:	5f                   	pop    %edi
  800d75:	5d                   	pop    %ebp
  800d76:	c3                   	ret    

00800d77 <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800d77:	55                   	push   %ebp
  800d78:	89 e5                	mov    %esp,%ebp
  800d7a:	57                   	push   %edi
  800d7b:	56                   	push   %esi
  800d7c:	53                   	push   %ebx
  800d7d:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d80:	b8 05 00 00 00       	mov    $0x5,%eax
  800d85:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d88:	8b 55 08             	mov    0x8(%ebp),%edx
  800d8b:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800d8e:	8b 7d 14             	mov    0x14(%ebp),%edi
  800d91:	8b 75 18             	mov    0x18(%ebp),%esi
  800d94:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800d96:	85 c0                	test   %eax,%eax
  800d98:	7e 28                	jle    800dc2 <sys_page_map+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d9a:	89 44 24 10          	mov    %eax,0x10(%esp)
  800d9e:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
  800da5:	00 
  800da6:	c7 44 24 08 44 1a 80 	movl   $0x801a44,0x8(%esp)
  800dad:	00 
  800dae:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800db5:	00 
  800db6:	c7 04 24 61 1a 80 00 	movl   $0x801a61,(%esp)
  800dbd:	e8 f0 05 00 00       	call   8013b2 <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  800dc2:	83 c4 2c             	add    $0x2c,%esp
  800dc5:	5b                   	pop    %ebx
  800dc6:	5e                   	pop    %esi
  800dc7:	5f                   	pop    %edi
  800dc8:	5d                   	pop    %ebp
  800dc9:	c3                   	ret    

00800dca <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  800dca:	55                   	push   %ebp
  800dcb:	89 e5                	mov    %esp,%ebp
  800dcd:	57                   	push   %edi
  800dce:	56                   	push   %esi
  800dcf:	53                   	push   %ebx
  800dd0:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800dd3:	bb 00 00 00 00       	mov    $0x0,%ebx
  800dd8:	b8 06 00 00 00       	mov    $0x6,%eax
  800ddd:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800de0:	8b 55 08             	mov    0x8(%ebp),%edx
  800de3:	89 df                	mov    %ebx,%edi
  800de5:	89 de                	mov    %ebx,%esi
  800de7:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800de9:	85 c0                	test   %eax,%eax
  800deb:	7e 28                	jle    800e15 <sys_page_unmap+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800ded:	89 44 24 10          	mov    %eax,0x10(%esp)
  800df1:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
  800df8:	00 
  800df9:	c7 44 24 08 44 1a 80 	movl   $0x801a44,0x8(%esp)
  800e00:	00 
  800e01:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800e08:	00 
  800e09:	c7 04 24 61 1a 80 00 	movl   $0x801a61,(%esp)
  800e10:	e8 9d 05 00 00       	call   8013b2 <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800e15:	83 c4 2c             	add    $0x2c,%esp
  800e18:	5b                   	pop    %ebx
  800e19:	5e                   	pop    %esi
  800e1a:	5f                   	pop    %edi
  800e1b:	5d                   	pop    %ebp
  800e1c:	c3                   	ret    

00800e1d <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800e1d:	55                   	push   %ebp
  800e1e:	89 e5                	mov    %esp,%ebp
  800e20:	57                   	push   %edi
  800e21:	56                   	push   %esi
  800e22:	53                   	push   %ebx
  800e23:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800e26:	bb 00 00 00 00       	mov    $0x0,%ebx
  800e2b:	b8 08 00 00 00       	mov    $0x8,%eax
  800e30:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800e33:	8b 55 08             	mov    0x8(%ebp),%edx
  800e36:	89 df                	mov    %ebx,%edi
  800e38:	89 de                	mov    %ebx,%esi
  800e3a:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800e3c:	85 c0                	test   %eax,%eax
  800e3e:	7e 28                	jle    800e68 <sys_env_set_status+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800e40:	89 44 24 10          	mov    %eax,0x10(%esp)
  800e44:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  800e4b:	00 
  800e4c:	c7 44 24 08 44 1a 80 	movl   $0x801a44,0x8(%esp)
  800e53:	00 
  800e54:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800e5b:	00 
  800e5c:	c7 04 24 61 1a 80 00 	movl   $0x801a61,(%esp)
  800e63:	e8 4a 05 00 00       	call   8013b2 <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800e68:	83 c4 2c             	add    $0x2c,%esp
  800e6b:	5b                   	pop    %ebx
  800e6c:	5e                   	pop    %esi
  800e6d:	5f                   	pop    %edi
  800e6e:	5d                   	pop    %ebp
  800e6f:	c3                   	ret    

00800e70 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800e70:	55                   	push   %ebp
  800e71:	89 e5                	mov    %esp,%ebp
  800e73:	57                   	push   %edi
  800e74:	56                   	push   %esi
  800e75:	53                   	push   %ebx
  800e76:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800e79:	bb 00 00 00 00       	mov    $0x0,%ebx
  800e7e:	b8 09 00 00 00       	mov    $0x9,%eax
  800e83:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800e86:	8b 55 08             	mov    0x8(%ebp),%edx
  800e89:	89 df                	mov    %ebx,%edi
  800e8b:	89 de                	mov    %ebx,%esi
  800e8d:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800e8f:	85 c0                	test   %eax,%eax
  800e91:	7e 28                	jle    800ebb <sys_env_set_pgfault_upcall+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800e93:	89 44 24 10          	mov    %eax,0x10(%esp)
  800e97:	c7 44 24 0c 09 00 00 	movl   $0x9,0xc(%esp)
  800e9e:	00 
  800e9f:	c7 44 24 08 44 1a 80 	movl   $0x801a44,0x8(%esp)
  800ea6:	00 
  800ea7:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800eae:	00 
  800eaf:	c7 04 24 61 1a 80 00 	movl   $0x801a61,(%esp)
  800eb6:	e8 f7 04 00 00       	call   8013b2 <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  800ebb:	83 c4 2c             	add    $0x2c,%esp
  800ebe:	5b                   	pop    %ebx
  800ebf:	5e                   	pop    %esi
  800ec0:	5f                   	pop    %edi
  800ec1:	5d                   	pop    %ebp
  800ec2:	c3                   	ret    

00800ec3 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800ec3:	55                   	push   %ebp
  800ec4:	89 e5                	mov    %esp,%ebp
  800ec6:	57                   	push   %edi
  800ec7:	56                   	push   %esi
  800ec8:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ec9:	be 00 00 00 00       	mov    $0x0,%esi
  800ece:	b8 0b 00 00 00       	mov    $0xb,%eax
  800ed3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800ed6:	8b 55 08             	mov    0x8(%ebp),%edx
  800ed9:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800edc:	8b 7d 14             	mov    0x14(%ebp),%edi
  800edf:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  800ee1:	5b                   	pop    %ebx
  800ee2:	5e                   	pop    %esi
  800ee3:	5f                   	pop    %edi
  800ee4:	5d                   	pop    %ebp
  800ee5:	c3                   	ret    

00800ee6 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800ee6:	55                   	push   %ebp
  800ee7:	89 e5                	mov    %esp,%ebp
  800ee9:	57                   	push   %edi
  800eea:	56                   	push   %esi
  800eeb:	53                   	push   %ebx
  800eec:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800eef:	b9 00 00 00 00       	mov    $0x0,%ecx
  800ef4:	b8 0c 00 00 00       	mov    $0xc,%eax
  800ef9:	8b 55 08             	mov    0x8(%ebp),%edx
  800efc:	89 cb                	mov    %ecx,%ebx
  800efe:	89 cf                	mov    %ecx,%edi
  800f00:	89 ce                	mov    %ecx,%esi
  800f02:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800f04:	85 c0                	test   %eax,%eax
  800f06:	7e 28                	jle    800f30 <sys_ipc_recv+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800f08:	89 44 24 10          	mov    %eax,0x10(%esp)
  800f0c:	c7 44 24 0c 0c 00 00 	movl   $0xc,0xc(%esp)
  800f13:	00 
  800f14:	c7 44 24 08 44 1a 80 	movl   $0x801a44,0x8(%esp)
  800f1b:	00 
  800f1c:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800f23:	00 
  800f24:	c7 04 24 61 1a 80 00 	movl   $0x801a61,(%esp)
  800f2b:	e8 82 04 00 00       	call   8013b2 <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  800f30:	83 c4 2c             	add    $0x2c,%esp
  800f33:	5b                   	pop    %ebx
  800f34:	5e                   	pop    %esi
  800f35:	5f                   	pop    %edi
  800f36:	5d                   	pop    %ebp
  800f37:	c3                   	ret    

00800f38 <pgfault>:
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
  800f38:	55                   	push   %ebp
  800f39:	89 e5                	mov    %esp,%ebp
  800f3b:	53                   	push   %ebx
  800f3c:	83 ec 24             	sub    $0x24,%esp
  800f3f:	8b 45 08             	mov    0x8(%ebp),%eax
	void *addr = (void *) utf->utf_fault_va;
  800f42:	8b 10                	mov    (%eax),%edx
	uint32_t err = utf->utf_err;
  800f44:	8b 48 04             	mov    0x4(%eax),%ecx

	// LAB 4: Your code here.
	//cprintf("err=%d",err);
	//cprintf("im here = %x",(uvpt[PGNUM((uint32_t)addr)] & (PTE_W|PTE_COW)));

	if((uvpt[PGNUM((uint32_t)addr)] & (PTE_W|PTE_COW)) == 0  && (err & FEC_WR) )
  800f47:	89 d0                	mov    %edx,%eax
  800f49:	c1 e8 0c             	shr    $0xc,%eax
  800f4c:	8b 04 85 00 00 40 ef 	mov    -0x10c00000(,%eax,4),%eax
  800f53:	a9 02 08 00 00       	test   $0x802,%eax
  800f58:	75 21                	jne    800f7b <pgfault+0x43>
  800f5a:	f6 c1 02             	test   $0x2,%cl
  800f5d:	74 1c                	je     800f7b <pgfault+0x43>
		panic("Trying to write on a read only page or the error is not a Write error");
  800f5f:	c7 44 24 08 70 1a 80 	movl   $0x801a70,0x8(%esp)
  800f66:	00 
  800f67:	c7 44 24 04 22 00 00 	movl   $0x22,0x4(%esp)
  800f6e:	00 
  800f6f:	c7 04 24 e2 1a 80 00 	movl   $0x801ae2,(%esp)
  800f76:	e8 37 04 00 00       	call   8013b2 <_panic>
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.

	// LAB 4: Your code here.
	void * vAddr = (void *)(ROUNDDOWN((uint32_t) addr, PGSIZE));
  800f7b:	89 d3                	mov    %edx,%ebx
  800f7d:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	if ((r = sys_page_alloc(0, (void*) PFTEMP, PTE_P|PTE_U|PTE_W)) < 0)
  800f83:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  800f8a:	00 
  800f8b:	c7 44 24 04 00 f0 7f 	movl   $0x7ff000,0x4(%esp)
  800f92:	00 
  800f93:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800f9a:	e8 84 fd ff ff       	call   800d23 <sys_page_alloc>
  800f9f:	85 c0                	test   %eax,%eax
  800fa1:	79 20                	jns    800fc3 <pgfault+0x8b>
		panic("sys_page_alloc: %e", r);
  800fa3:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800fa7:	c7 44 24 08 ed 1a 80 	movl   $0x801aed,0x8(%esp)
  800fae:	00 
  800faf:	c7 44 24 04 2d 00 00 	movl   $0x2d,0x4(%esp)
  800fb6:	00 
  800fb7:	c7 04 24 e2 1a 80 00 	movl   $0x801ae2,(%esp)
  800fbe:	e8 ef 03 00 00       	call   8013b2 <_panic>
		
	memmove((void *)PFTEMP, vAddr, PGSIZE);
  800fc3:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  800fca:	00 
  800fcb:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800fcf:	c7 04 24 00 f0 7f 00 	movl   $0x7ff000,(%esp)
  800fd6:	e8 c9 fa ff ff       	call   800aa4 <memmove>
	
	if ((r = sys_page_map(0, (void *)PFTEMP, 0, vAddr, PTE_P|PTE_U|PTE_W)) < 0)
  800fdb:	c7 44 24 10 07 00 00 	movl   $0x7,0x10(%esp)
  800fe2:	00 
  800fe3:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  800fe7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  800fee:	00 
  800fef:	c7 44 24 04 00 f0 7f 	movl   $0x7ff000,0x4(%esp)
  800ff6:	00 
  800ff7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800ffe:	e8 74 fd ff ff       	call   800d77 <sys_page_map>
  801003:	85 c0                	test   %eax,%eax
  801005:	79 20                	jns    801027 <pgfault+0xef>
		panic("sys_page_map: %e", r);
  801007:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80100b:	c7 44 24 08 00 1b 80 	movl   $0x801b00,0x8(%esp)
  801012:	00 
  801013:	c7 44 24 04 32 00 00 	movl   $0x32,0x4(%esp)
  80101a:	00 
  80101b:	c7 04 24 e2 1a 80 00 	movl   $0x801ae2,(%esp)
  801022:	e8 8b 03 00 00       	call   8013b2 <_panic>
		
	
	
	if ((r = sys_page_unmap(0, PFTEMP)) < 0)
  801027:	c7 44 24 04 00 f0 7f 	movl   $0x7ff000,0x4(%esp)
  80102e:	00 
  80102f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  801036:	e8 8f fd ff ff       	call   800dca <sys_page_unmap>
  80103b:	85 c0                	test   %eax,%eax
  80103d:	79 20                	jns    80105f <pgfault+0x127>
		panic("sys_page_unmap: %e", r);
  80103f:	89 44 24 0c          	mov    %eax,0xc(%esp)
  801043:	c7 44 24 08 11 1b 80 	movl   $0x801b11,0x8(%esp)
  80104a:	00 
  80104b:	c7 44 24 04 37 00 00 	movl   $0x37,0x4(%esp)
  801052:	00 
  801053:	c7 04 24 e2 1a 80 00 	movl   $0x801ae2,(%esp)
  80105a:	e8 53 03 00 00       	call   8013b2 <_panic>

}
  80105f:	83 c4 24             	add    $0x24,%esp
  801062:	5b                   	pop    %ebx
  801063:	5d                   	pop    %ebp
  801064:	c3                   	ret    

00801065 <fork>:
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
  801065:	55                   	push   %ebp
  801066:	89 e5                	mov    %esp,%ebp
  801068:	57                   	push   %edi
  801069:	56                   	push   %esi
  80106a:	53                   	push   %ebx
  80106b:	83 ec 2c             	sub    $0x2c,%esp
	// LAB 4: Your code here.
	envid_t envid;
	extern unsigned char end[];
	uint32_t pn;
	
	set_pgfault_handler(pgfault);
  80106e:	c7 04 24 38 0f 80 00 	movl   $0x800f38,(%esp)
  801075:	e8 8e 03 00 00       	call   801408 <set_pgfault_handler>
// This must be inlined.  Exercise for reader: why?
static inline envid_t __attribute__((always_inline))
sys_exofork(void)
{
	envid_t ret;
	asm volatile("int %2"
  80107a:	b8 07 00 00 00       	mov    $0x7,%eax
  80107f:	cd 30                	int    $0x30
  801081:	89 c7                	mov    %eax,%edi
  801083:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	
	envid = sys_exofork();
	//cprintf("envId=%d",envid);
	if (envid < 0)
  801086:	85 c0                	test   %eax,%eax
  801088:	79 20                	jns    8010aa <fork+0x45>
		panic("sys_exofork: %e", envid);
  80108a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80108e:	c7 44 24 08 24 1b 80 	movl   $0x801b24,0x8(%esp)
  801095:	00 
  801096:	c7 44 24 04 83 00 00 	movl   $0x83,0x4(%esp)
  80109d:	00 
  80109e:	c7 04 24 e2 1a 80 00 	movl   $0x801ae2,(%esp)
  8010a5:	e8 08 03 00 00       	call   8013b2 <_panic>
	if (envid == 0) {
  8010aa:	bb 00 08 00 00       	mov    $0x800,%ebx
  8010af:	85 c0                	test   %eax,%eax
  8010b1:	75 21                	jne    8010d4 <fork+0x6f>
		// We're the child.
		// The copied value of the global variable 'thisenv'
		// is no longer valid (it refers to the parent!).
		// Fix it and return 0.
		thisenv = &envs[ENVX(sys_getenvid())];
  8010b3:	e8 2d fc ff ff       	call   800ce5 <sys_getenvid>
  8010b8:	25 ff 03 00 00       	and    $0x3ff,%eax
  8010bd:	6b c0 7c             	imul   $0x7c,%eax,%eax
  8010c0:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  8010c5:	a3 0c 20 80 00       	mov    %eax,0x80200c
		return 0;
  8010ca:	b8 00 00 00 00       	mov    $0x0,%eax
  8010cf:	e9 38 02 00 00       	jmp    80130c <fork+0x2a7>
	}
	uint32_t i=0;
	for (pn =  PGNUM(UTEXT); pn < PGNUM(UXSTACKTOP - PGSIZE); pn += 1)
	{
		if(!(uvpd[PDX(pn<<PGSHIFT)] & PTE_P)) continue;
  8010d4:	89 d8                	mov    %ebx,%eax
  8010d6:	c1 e0 0c             	shl    $0xc,%eax
  8010d9:	89 c2                	mov    %eax,%edx
  8010db:	c1 ea 16             	shr    $0x16,%edx
  8010de:	8b 14 95 00 d0 7b ef 	mov    -0x10843000(,%edx,4),%edx
  8010e5:	f6 c2 01             	test   $0x1,%dl
  8010e8:	0f 84 69 01 00 00    	je     801257 <fork+0x1f2>
		if(!(uvpt[pn] & PTE_P)) continue;
  8010ee:	8b 14 9d 00 00 40 ef 	mov    -0x10c00000(,%ebx,4),%edx
  8010f5:	f6 c2 01             	test   $0x1,%dl
  8010f8:	0f 84 59 01 00 00    	je     801257 <fork+0x1f2>
		if((pn << PGSHIFT) < (UXSTACKTOP - PGSIZE))
  8010fe:	3d ff ef bf ee       	cmp    $0xeebfefff,%eax
  801103:	0f 87 4e 01 00 00    	ja     801257 <fork+0x1f2>
  801109:	89 c6                	mov    %eax,%esi
		int perm = 0;
		int perm1 =0;
		perm |= PTE_P|PTE_U|PTE_COW;
		perm1 |= PTE_P|PTE_U;

	if((uvpt[pn] & PTE_W) || (uvpt[pn] & PTE_COW))
  80110b:	8b 04 9d 00 00 40 ef 	mov    -0x10c00000(,%ebx,4),%eax
  801112:	a8 02                	test   $0x2,%al
  801114:	75 10                	jne    801126 <fork+0xc1>
  801116:	8b 04 9d 00 00 40 ef 	mov    -0x10c00000(,%ebx,4),%eax
  80111d:	f6 c4 08             	test   $0x8,%ah
  801120:	0f 84 93 00 00 00    	je     8011b9 <fork+0x154>
	{
		
	
		if ((r = sys_page_map(0, address, envid, address, perm)) < 0)
  801126:	c7 44 24 10 05 08 00 	movl   $0x805,0x10(%esp)
  80112d:	00 
  80112e:	89 74 24 0c          	mov    %esi,0xc(%esp)
  801132:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  801135:	89 44 24 08          	mov    %eax,0x8(%esp)
  801139:	89 74 24 04          	mov    %esi,0x4(%esp)
  80113d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  801144:	e8 2e fc ff ff       	call   800d77 <sys_page_map>
  801149:	85 c0                	test   %eax,%eax
  80114b:	79 20                	jns    80116d <fork+0x108>
			panic("sys_page_map: %e", r);
  80114d:	89 44 24 0c          	mov    %eax,0xc(%esp)
  801151:	c7 44 24 08 00 1b 80 	movl   $0x801b00,0x8(%esp)
  801158:	00 
  801159:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
  801160:	00 
  801161:	c7 04 24 e2 1a 80 00 	movl   $0x801ae2,(%esp)
  801168:	e8 45 02 00 00       	call   8013b2 <_panic>
		if ((r = sys_page_map(0, address, 0, address, perm)) < 0)
  80116d:	c7 44 24 10 05 08 00 	movl   $0x805,0x10(%esp)
  801174:	00 
  801175:	89 74 24 0c          	mov    %esi,0xc(%esp)
  801179:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  801180:	00 
  801181:	89 74 24 04          	mov    %esi,0x4(%esp)
  801185:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  80118c:	e8 e6 fb ff ff       	call   800d77 <sys_page_map>
  801191:	85 c0                	test   %eax,%eax
  801193:	0f 89 be 00 00 00    	jns    801257 <fork+0x1f2>
			panic("sys_page_map: %e", r);
  801199:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80119d:	c7 44 24 08 00 1b 80 	movl   $0x801b00,0x8(%esp)
  8011a4:	00 
  8011a5:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  8011ac:	00 
  8011ad:	c7 04 24 e2 1a 80 00 	movl   $0x801ae2,(%esp)
  8011b4:	e8 f9 01 00 00       	call   8013b2 <_panic>
	}

	else if(uvpt[pn] & PTE_U)
  8011b9:	8b 04 9d 00 00 40 ef 	mov    -0x10c00000(,%ebx,4),%eax
  8011c0:	a8 04                	test   $0x4,%al
  8011c2:	0f 84 8f 00 00 00    	je     801257 <fork+0x1f2>
	{
		if ((r = sys_page_map(0, address, envid, address, perm1)) < 0)
  8011c8:	c7 44 24 10 05 00 00 	movl   $0x5,0x10(%esp)
  8011cf:	00 
  8011d0:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8011d4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8011d7:	89 44 24 08          	mov    %eax,0x8(%esp)
  8011db:	89 74 24 04          	mov    %esi,0x4(%esp)
  8011df:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8011e6:	e8 8c fb ff ff       	call   800d77 <sys_page_map>
  8011eb:	85 c0                	test   %eax,%eax
  8011ed:	79 20                	jns    80120f <fork+0x1aa>
			panic("sys_page_map: %e", r);
  8011ef:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8011f3:	c7 44 24 08 00 1b 80 	movl   $0x801b00,0x8(%esp)
  8011fa:	00 
  8011fb:	c7 44 24 04 5e 00 00 	movl   $0x5e,0x4(%esp)
  801202:	00 
  801203:	c7 04 24 e2 1a 80 00 	movl   $0x801ae2,(%esp)
  80120a:	e8 a3 01 00 00       	call   8013b2 <_panic>
		if ((r = sys_page_map(0, address, 0, address, perm1)) < 0)
  80120f:	c7 44 24 10 05 00 00 	movl   $0x5,0x10(%esp)
  801216:	00 
  801217:	89 74 24 0c          	mov    %esi,0xc(%esp)
  80121b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  801222:	00 
  801223:	89 74 24 04          	mov    %esi,0x4(%esp)
  801227:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  80122e:	e8 44 fb ff ff       	call   800d77 <sys_page_map>
  801233:	85 c0                	test   %eax,%eax
  801235:	79 20                	jns    801257 <fork+0x1f2>
			panic("sys_page_map: %e", r);
  801237:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80123b:	c7 44 24 08 00 1b 80 	movl   $0x801b00,0x8(%esp)
  801242:	00 
  801243:	c7 44 24 04 60 00 00 	movl   $0x60,0x4(%esp)
  80124a:	00 
  80124b:	c7 04 24 e2 1a 80 00 	movl   $0x801ae2,(%esp)
  801252:	e8 5b 01 00 00       	call   8013b2 <_panic>
		// Fix it and return 0.
		thisenv = &envs[ENVX(sys_getenvid())];
		return 0;
	}
	uint32_t i=0;
	for (pn =  PGNUM(UTEXT); pn < PGNUM(UXSTACKTOP - PGSIZE); pn += 1)
  801257:	83 c3 01             	add    $0x1,%ebx
  80125a:	81 fb ff eb 0e 00    	cmp    $0xeebff,%ebx
  801260:	0f 85 6e fe ff ff    	jne    8010d4 <fork+0x6f>
	
	//panic("im here");
	
		
	int r;
	if ((r = sys_page_alloc(envid, (void *)(UXSTACKTOP-PGSIZE), PTE_P|PTE_U|PTE_W)) < 0)
  801266:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  80126d:	00 
  80126e:	c7 44 24 04 00 f0 bf 	movl   $0xeebff000,0x4(%esp)
  801275:	ee 
  801276:	89 3c 24             	mov    %edi,(%esp)
  801279:	e8 a5 fa ff ff       	call   800d23 <sys_page_alloc>
  80127e:	85 c0                	test   %eax,%eax
  801280:	79 20                	jns    8012a2 <fork+0x23d>
		panic("sys_page_alloc: %e", r);
  801282:	89 44 24 0c          	mov    %eax,0xc(%esp)
  801286:	c7 44 24 08 ed 1a 80 	movl   $0x801aed,0x8(%esp)
  80128d:	00 
  80128e:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
  801295:	00 
  801296:	c7 04 24 e2 1a 80 00 	movl   $0x801ae2,(%esp)
  80129d:	e8 10 01 00 00       	call   8013b2 <_panic>
		
	int status;
	if((status =sys_env_set_pgfault_upcall(envid, thisenv->env_pgfault_upcall)) < 0)
  8012a2:	a1 0c 20 80 00       	mov    0x80200c,%eax
  8012a7:	8b 40 60             	mov    0x60(%eax),%eax
  8012aa:	89 44 24 04          	mov    %eax,0x4(%esp)
  8012ae:	89 3c 24             	mov    %edi,(%esp)
  8012b1:	e8 ba fb ff ff       	call   800e70 <sys_env_set_pgfault_upcall>
  8012b6:	85 c0                	test   %eax,%eax
  8012b8:	79 1c                	jns    8012d6 <fork+0x271>
		panic("Bad Environment in user pagefault handler");
  8012ba:	c7 44 24 08 b8 1a 80 	movl   $0x801ab8,0x8(%esp)
  8012c1:	00 
  8012c2:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  8012c9:	00 
  8012ca:	c7 04 24 e2 1a 80 00 	movl   $0x801ae2,(%esp)
  8012d1:	e8 dc 00 00 00       	call   8013b2 <_panic>
			
	if ((r = sys_env_set_status(envid, ENV_RUNNABLE)) < 0)
  8012d6:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
  8012dd:	00 
  8012de:	89 3c 24             	mov    %edi,(%esp)
  8012e1:	e8 37 fb ff ff       	call   800e1d <sys_env_set_status>
  8012e6:	85 c0                	test   %eax,%eax
  8012e8:	79 20                	jns    80130a <fork+0x2a5>
		panic("sys_env_set_status: %e", r);
  8012ea:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8012ee:	c7 44 24 08 34 1b 80 	movl   $0x801b34,0x8(%esp)
  8012f5:	00 
  8012f6:	c7 44 24 04 a3 00 00 	movl   $0xa3,0x4(%esp)
  8012fd:	00 
  8012fe:	c7 04 24 e2 1a 80 00 	movl   $0x801ae2,(%esp)
  801305:	e8 a8 00 00 00       	call   8013b2 <_panic>
		
	return envid;
  80130a:	89 f8                	mov    %edi,%eax
}
  80130c:	83 c4 2c             	add    $0x2c,%esp
  80130f:	5b                   	pop    %ebx
  801310:	5e                   	pop    %esi
  801311:	5f                   	pop    %edi
  801312:	5d                   	pop    %ebp
  801313:	c3                   	ret    

00801314 <sfork>:

// Challenge!
int
sfork(void)
{
  801314:	55                   	push   %ebp
  801315:	89 e5                	mov    %esp,%ebp
  801317:	83 ec 18             	sub    $0x18,%esp
	panic("sfork not implemented");
  80131a:	c7 44 24 08 4b 1b 80 	movl   $0x801b4b,0x8(%esp)
  801321:	00 
  801322:	c7 44 24 04 ac 00 00 	movl   $0xac,0x4(%esp)
  801329:	00 
  80132a:	c7 04 24 e2 1a 80 00 	movl   $0x801ae2,(%esp)
  801331:	e8 7c 00 00 00       	call   8013b2 <_panic>

00801336 <ipc_recv>:
//   If 'pg' is null, pass sys_ipc_recv a value that it will understand
//   as meaning "no page".  (Zero is not the right value, since that's
//   a perfectly valid place to map a page.)
int32_t
ipc_recv(envid_t *from_env_store, void *pg, int *perm_store)
{
  801336:	55                   	push   %ebp
  801337:	89 e5                	mov    %esp,%ebp
  801339:	83 ec 18             	sub    $0x18,%esp
	

	// LAB 4: Your code here.
	panic("ipc_recv not implemented");
  80133c:	c7 44 24 08 61 1b 80 	movl   $0x801b61,0x8(%esp)
  801343:	00 
  801344:	c7 44 24 04 1c 00 00 	movl   $0x1c,0x4(%esp)
  80134b:	00 
  80134c:	c7 04 24 7a 1b 80 00 	movl   $0x801b7a,(%esp)
  801353:	e8 5a 00 00 00       	call   8013b2 <_panic>

00801358 <ipc_send>:
//   Use sys_yield() to be CPU-friendly.
//   If 'pg' is null, pass sys_ipc_try_send a value that it will understand
//   as meaning "no page".  (Zero is not the right value.)
void
ipc_send(envid_t to_env, uint32_t val, void *pg, int perm)
{
  801358:	55                   	push   %ebp
  801359:	89 e5                	mov    %esp,%ebp
  80135b:	83 ec 18             	sub    $0x18,%esp
	// LAB 4: Your code here.
	panic("ipc_send not implemented");
  80135e:	c7 44 24 08 84 1b 80 	movl   $0x801b84,0x8(%esp)
  801365:	00 
  801366:	c7 44 24 04 2c 00 00 	movl   $0x2c,0x4(%esp)
  80136d:	00 
  80136e:	c7 04 24 7a 1b 80 00 	movl   $0x801b7a,(%esp)
  801375:	e8 38 00 00 00       	call   8013b2 <_panic>

0080137a <ipc_find_env>:
// Find the first environment of the given type.  We'll use this to
// find special environments.
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
  80137a:	55                   	push   %ebp
  80137b:	89 e5                	mov    %esp,%ebp
  80137d:	8b 4d 08             	mov    0x8(%ebp),%ecx
	int i;
	for (i = 0; i < NENV; i++)
  801380:	b8 00 00 00 00       	mov    $0x0,%eax
		if (envs[i].env_type == type)
  801385:	6b d0 7c             	imul   $0x7c,%eax,%edx
  801388:	81 c2 00 00 c0 ee    	add    $0xeec00000,%edx
  80138e:	8b 52 50             	mov    0x50(%edx),%edx
  801391:	39 ca                	cmp    %ecx,%edx
  801393:	75 0d                	jne    8013a2 <ipc_find_env+0x28>
			return envs[i].env_id;
  801395:	6b c0 7c             	imul   $0x7c,%eax,%eax
  801398:	05 08 00 c0 ee       	add    $0xeec00008,%eax
  80139d:	8b 40 40             	mov    0x40(%eax),%eax
  8013a0:	eb 0e                	jmp    8013b0 <ipc_find_env+0x36>
// Returns 0 if no such environment exists.
envid_t
ipc_find_env(enum EnvType type)
{
	int i;
	for (i = 0; i < NENV; i++)
  8013a2:	83 c0 01             	add    $0x1,%eax
  8013a5:	3d 00 04 00 00       	cmp    $0x400,%eax
  8013aa:	75 d9                	jne    801385 <ipc_find_env+0xb>
		if (envs[i].env_type == type)
			return envs[i].env_id;
	return 0;
  8013ac:	66 b8 00 00          	mov    $0x0,%ax
}
  8013b0:	5d                   	pop    %ebp
  8013b1:	c3                   	ret    

008013b2 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  8013b2:	55                   	push   %ebp
  8013b3:	89 e5                	mov    %esp,%ebp
  8013b5:	56                   	push   %esi
  8013b6:	53                   	push   %ebx
  8013b7:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  8013ba:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  8013bd:	8b 35 08 20 80 00    	mov    0x802008,%esi
  8013c3:	e8 1d f9 ff ff       	call   800ce5 <sys_getenvid>
  8013c8:	8b 55 0c             	mov    0xc(%ebp),%edx
  8013cb:	89 54 24 10          	mov    %edx,0x10(%esp)
  8013cf:	8b 55 08             	mov    0x8(%ebp),%edx
  8013d2:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8013d6:	89 74 24 08          	mov    %esi,0x8(%esp)
  8013da:	89 44 24 04          	mov    %eax,0x4(%esp)
  8013de:	c7 04 24 a0 1b 80 00 	movl   $0x801ba0,(%esp)
  8013e5:	e8 f5 ee ff ff       	call   8002df <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  8013ea:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8013ee:	8b 45 10             	mov    0x10(%ebp),%eax
  8013f1:	89 04 24             	mov    %eax,(%esp)
  8013f4:	e8 85 ee ff ff       	call   80027e <vcprintf>
	cprintf("\n");
  8013f9:	c7 04 24 52 17 80 00 	movl   $0x801752,(%esp)
  801400:	e8 da ee ff ff       	call   8002df <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  801405:	cc                   	int3   
  801406:	eb fd                	jmp    801405 <_panic+0x53>

00801408 <set_pgfault_handler>:
// at UXSTACKTOP), and tell the kernel to call the assembly-language
// _pgfault_upcall routine when a page fault occurs.
//
void
set_pgfault_handler(void (*handler)(struct UTrapframe *utf))
{
  801408:	55                   	push   %ebp
  801409:	89 e5                	mov    %esp,%ebp
  80140b:	83 ec 18             	sub    $0x18,%esp
	int r;

	if (_pgfault_handler==0)
  80140e:	83 3d 10 20 80 00 00 	cmpl   $0x0,0x802010
  801415:	75 58                	jne    80146f <set_pgfault_handler+0x67>
	{
		// First time through!
		// LAB 4: Your code here.
		int check;
		check=sys_page_alloc(thisenv->env_id, (void *)(UXSTACKTOP-PGSIZE),  PTE_U|PTE_W|PTE_P);
  801417:	a1 0c 20 80 00       	mov    0x80200c,%eax
  80141c:	8b 40 48             	mov    0x48(%eax),%eax
  80141f:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  801426:	00 
  801427:	c7 44 24 04 00 f0 bf 	movl   $0xeebff000,0x4(%esp)
  80142e:	ee 
  80142f:	89 04 24             	mov    %eax,(%esp)
  801432:	e8 ec f8 ff ff       	call   800d23 <sys_page_alloc>
		if(check<0)
  801437:	85 c0                	test   %eax,%eax
  801439:	79 1c                	jns    801457 <set_pgfault_handler+0x4f>
		{
			panic("Sys_page alloc failed");
  80143b:	c7 44 24 08 c4 1b 80 	movl   $0x801bc4,0x8(%esp)
  801442:	00 
  801443:	c7 44 24 04 25 00 00 	movl   $0x25,0x4(%esp)
  80144a:	00 
  80144b:	c7 04 24 da 1b 80 00 	movl   $0x801bda,(%esp)
  801452:	e8 5b ff ff ff       	call   8013b2 <_panic>
		}
		
		sys_env_set_pgfault_upcall(thisenv->env_id, _pgfault_upcall);
  801457:	a1 0c 20 80 00       	mov    0x80200c,%eax
  80145c:	8b 40 48             	mov    0x48(%eax),%eax
  80145f:	c7 44 24 04 79 14 80 	movl   $0x801479,0x4(%esp)
  801466:	00 
  801467:	89 04 24             	mov    %eax,(%esp)
  80146a:	e8 01 fa ff ff       	call   800e70 <sys_env_set_pgfault_upcall>

		//panic("set_pgfault_handler not implemented");
	}

	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
  80146f:	8b 45 08             	mov    0x8(%ebp),%eax
  801472:	a3 10 20 80 00       	mov    %eax,0x802010
}
  801477:	c9                   	leave  
  801478:	c3                   	ret    

00801479 <_pgfault_upcall>:

.text
.globl _pgfault_upcall
_pgfault_upcall:
	// Call the C page fault handler.
	pushl %esp			// function argument: pointer to UTF
  801479:	54                   	push   %esp
	movl _pgfault_handler, %eax
  80147a:	a1 10 20 80 00       	mov    0x802010,%eax
	call *%eax
  80147f:	ff d0                	call   *%eax
	addl $4, %esp			// pop function argument
  801481:	83 c4 04             	add    $0x4,%esp
	// may find that you have to rearrange your code in non-obvious
	// ways as registers become unavailable as scratch space.
	//
	// LAB 4: Your code here.
	
		movl %esp,%ebx      // Store current esp at bottom
  801484:	89 e3                	mov    %esp,%ebx
		movl 40(%esp),%eax   // store eip value
  801486:	8b 44 24 28          	mov    0x28(%esp),%eax
		movl 48(%esp),%esp   // get new esp value
  80148a:	8b 64 24 30          	mov    0x30(%esp),%esp
		pushl %eax          // push eip in the free space
  80148e:	50                   	push   %eax
		movl %ebx,%esp	    // get back to prev	
  80148f:	89 dc                	mov    %ebx,%esp
		subl $4,48(%esp)
  801491:	83 6c 24 30 04       	subl   $0x4,0x30(%esp)
		
	// Restore the trap-time1 registers.  After you do this, you
	// can no longer modify any general-purpose registers.
	// LAB 4: Your code here.
		
		popl %eax //fault_va
  801496:	58                   	pop    %eax
		popl %eax //err
  801497:	58                   	pop    %eax
		popal
  801498:	61                   	popa   
	// Restore eflags from the stack.  After you do this, you can
	// no longer use arithmetic operations or anything else that
	// modifies eflags.
	// LAB 4: Your code here.

		addl $4, %esp
  801499:	83 c4 04             	add    $0x4,%esp
		popfl
  80149c:	9d                   	popf   


	// Switch back to the adjusted trap-time stack.
	// LAB 4: Your code here.

		popl %esp		
  80149d:	5c                   	pop    %esp


	// Return to re-execute the instruction that faulted.
	// LAB 4: Your code here.

		ret
  80149e:	c3                   	ret    
  80149f:	90                   	nop

008014a0 <__udivdi3>:
  8014a0:	55                   	push   %ebp
  8014a1:	57                   	push   %edi
  8014a2:	56                   	push   %esi
  8014a3:	83 ec 0c             	sub    $0xc,%esp
  8014a6:	8b 44 24 28          	mov    0x28(%esp),%eax
  8014aa:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  8014ae:	8b 6c 24 20          	mov    0x20(%esp),%ebp
  8014b2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  8014b6:	85 c0                	test   %eax,%eax
  8014b8:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8014bc:	89 ea                	mov    %ebp,%edx
  8014be:	89 0c 24             	mov    %ecx,(%esp)
  8014c1:	75 2d                	jne    8014f0 <__udivdi3+0x50>
  8014c3:	39 e9                	cmp    %ebp,%ecx
  8014c5:	77 61                	ja     801528 <__udivdi3+0x88>
  8014c7:	85 c9                	test   %ecx,%ecx
  8014c9:	89 ce                	mov    %ecx,%esi
  8014cb:	75 0b                	jne    8014d8 <__udivdi3+0x38>
  8014cd:	b8 01 00 00 00       	mov    $0x1,%eax
  8014d2:	31 d2                	xor    %edx,%edx
  8014d4:	f7 f1                	div    %ecx
  8014d6:	89 c6                	mov    %eax,%esi
  8014d8:	31 d2                	xor    %edx,%edx
  8014da:	89 e8                	mov    %ebp,%eax
  8014dc:	f7 f6                	div    %esi
  8014de:	89 c5                	mov    %eax,%ebp
  8014e0:	89 f8                	mov    %edi,%eax
  8014e2:	f7 f6                	div    %esi
  8014e4:	89 ea                	mov    %ebp,%edx
  8014e6:	83 c4 0c             	add    $0xc,%esp
  8014e9:	5e                   	pop    %esi
  8014ea:	5f                   	pop    %edi
  8014eb:	5d                   	pop    %ebp
  8014ec:	c3                   	ret    
  8014ed:	8d 76 00             	lea    0x0(%esi),%esi
  8014f0:	39 e8                	cmp    %ebp,%eax
  8014f2:	77 24                	ja     801518 <__udivdi3+0x78>
  8014f4:	0f bd e8             	bsr    %eax,%ebp
  8014f7:	83 f5 1f             	xor    $0x1f,%ebp
  8014fa:	75 3c                	jne    801538 <__udivdi3+0x98>
  8014fc:	8b 74 24 04          	mov    0x4(%esp),%esi
  801500:	39 34 24             	cmp    %esi,(%esp)
  801503:	0f 86 9f 00 00 00    	jbe    8015a8 <__udivdi3+0x108>
  801509:	39 d0                	cmp    %edx,%eax
  80150b:	0f 82 97 00 00 00    	jb     8015a8 <__udivdi3+0x108>
  801511:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801518:	31 d2                	xor    %edx,%edx
  80151a:	31 c0                	xor    %eax,%eax
  80151c:	83 c4 0c             	add    $0xc,%esp
  80151f:	5e                   	pop    %esi
  801520:	5f                   	pop    %edi
  801521:	5d                   	pop    %ebp
  801522:	c3                   	ret    
  801523:	90                   	nop
  801524:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801528:	89 f8                	mov    %edi,%eax
  80152a:	f7 f1                	div    %ecx
  80152c:	31 d2                	xor    %edx,%edx
  80152e:	83 c4 0c             	add    $0xc,%esp
  801531:	5e                   	pop    %esi
  801532:	5f                   	pop    %edi
  801533:	5d                   	pop    %ebp
  801534:	c3                   	ret    
  801535:	8d 76 00             	lea    0x0(%esi),%esi
  801538:	89 e9                	mov    %ebp,%ecx
  80153a:	8b 3c 24             	mov    (%esp),%edi
  80153d:	d3 e0                	shl    %cl,%eax
  80153f:	89 c6                	mov    %eax,%esi
  801541:	b8 20 00 00 00       	mov    $0x20,%eax
  801546:	29 e8                	sub    %ebp,%eax
  801548:	89 c1                	mov    %eax,%ecx
  80154a:	d3 ef                	shr    %cl,%edi
  80154c:	89 e9                	mov    %ebp,%ecx
  80154e:	89 7c 24 08          	mov    %edi,0x8(%esp)
  801552:	8b 3c 24             	mov    (%esp),%edi
  801555:	09 74 24 08          	or     %esi,0x8(%esp)
  801559:	89 d6                	mov    %edx,%esi
  80155b:	d3 e7                	shl    %cl,%edi
  80155d:	89 c1                	mov    %eax,%ecx
  80155f:	89 3c 24             	mov    %edi,(%esp)
  801562:	8b 7c 24 04          	mov    0x4(%esp),%edi
  801566:	d3 ee                	shr    %cl,%esi
  801568:	89 e9                	mov    %ebp,%ecx
  80156a:	d3 e2                	shl    %cl,%edx
  80156c:	89 c1                	mov    %eax,%ecx
  80156e:	d3 ef                	shr    %cl,%edi
  801570:	09 d7                	or     %edx,%edi
  801572:	89 f2                	mov    %esi,%edx
  801574:	89 f8                	mov    %edi,%eax
  801576:	f7 74 24 08          	divl   0x8(%esp)
  80157a:	89 d6                	mov    %edx,%esi
  80157c:	89 c7                	mov    %eax,%edi
  80157e:	f7 24 24             	mull   (%esp)
  801581:	39 d6                	cmp    %edx,%esi
  801583:	89 14 24             	mov    %edx,(%esp)
  801586:	72 30                	jb     8015b8 <__udivdi3+0x118>
  801588:	8b 54 24 04          	mov    0x4(%esp),%edx
  80158c:	89 e9                	mov    %ebp,%ecx
  80158e:	d3 e2                	shl    %cl,%edx
  801590:	39 c2                	cmp    %eax,%edx
  801592:	73 05                	jae    801599 <__udivdi3+0xf9>
  801594:	3b 34 24             	cmp    (%esp),%esi
  801597:	74 1f                	je     8015b8 <__udivdi3+0x118>
  801599:	89 f8                	mov    %edi,%eax
  80159b:	31 d2                	xor    %edx,%edx
  80159d:	e9 7a ff ff ff       	jmp    80151c <__udivdi3+0x7c>
  8015a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  8015a8:	31 d2                	xor    %edx,%edx
  8015aa:	b8 01 00 00 00       	mov    $0x1,%eax
  8015af:	e9 68 ff ff ff       	jmp    80151c <__udivdi3+0x7c>
  8015b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8015b8:	8d 47 ff             	lea    -0x1(%edi),%eax
  8015bb:	31 d2                	xor    %edx,%edx
  8015bd:	83 c4 0c             	add    $0xc,%esp
  8015c0:	5e                   	pop    %esi
  8015c1:	5f                   	pop    %edi
  8015c2:	5d                   	pop    %ebp
  8015c3:	c3                   	ret    
  8015c4:	66 90                	xchg   %ax,%ax
  8015c6:	66 90                	xchg   %ax,%ax
  8015c8:	66 90                	xchg   %ax,%ax
  8015ca:	66 90                	xchg   %ax,%ax
  8015cc:	66 90                	xchg   %ax,%ax
  8015ce:	66 90                	xchg   %ax,%ax

008015d0 <__umoddi3>:
  8015d0:	55                   	push   %ebp
  8015d1:	57                   	push   %edi
  8015d2:	56                   	push   %esi
  8015d3:	83 ec 14             	sub    $0x14,%esp
  8015d6:	8b 44 24 28          	mov    0x28(%esp),%eax
  8015da:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  8015de:	8b 74 24 2c          	mov    0x2c(%esp),%esi
  8015e2:	89 c7                	mov    %eax,%edi
  8015e4:	89 44 24 04          	mov    %eax,0x4(%esp)
  8015e8:	8b 44 24 30          	mov    0x30(%esp),%eax
  8015ec:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  8015f0:	89 34 24             	mov    %esi,(%esp)
  8015f3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8015f7:	85 c0                	test   %eax,%eax
  8015f9:	89 c2                	mov    %eax,%edx
  8015fb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  8015ff:	75 17                	jne    801618 <__umoddi3+0x48>
  801601:	39 fe                	cmp    %edi,%esi
  801603:	76 4b                	jbe    801650 <__umoddi3+0x80>
  801605:	89 c8                	mov    %ecx,%eax
  801607:	89 fa                	mov    %edi,%edx
  801609:	f7 f6                	div    %esi
  80160b:	89 d0                	mov    %edx,%eax
  80160d:	31 d2                	xor    %edx,%edx
  80160f:	83 c4 14             	add    $0x14,%esp
  801612:	5e                   	pop    %esi
  801613:	5f                   	pop    %edi
  801614:	5d                   	pop    %ebp
  801615:	c3                   	ret    
  801616:	66 90                	xchg   %ax,%ax
  801618:	39 f8                	cmp    %edi,%eax
  80161a:	77 54                	ja     801670 <__umoddi3+0xa0>
  80161c:	0f bd e8             	bsr    %eax,%ebp
  80161f:	83 f5 1f             	xor    $0x1f,%ebp
  801622:	75 5c                	jne    801680 <__umoddi3+0xb0>
  801624:	8b 7c 24 08          	mov    0x8(%esp),%edi
  801628:	39 3c 24             	cmp    %edi,(%esp)
  80162b:	0f 87 e7 00 00 00    	ja     801718 <__umoddi3+0x148>
  801631:	8b 7c 24 04          	mov    0x4(%esp),%edi
  801635:	29 f1                	sub    %esi,%ecx
  801637:	19 c7                	sbb    %eax,%edi
  801639:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80163d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  801641:	8b 44 24 08          	mov    0x8(%esp),%eax
  801645:	8b 54 24 0c          	mov    0xc(%esp),%edx
  801649:	83 c4 14             	add    $0x14,%esp
  80164c:	5e                   	pop    %esi
  80164d:	5f                   	pop    %edi
  80164e:	5d                   	pop    %ebp
  80164f:	c3                   	ret    
  801650:	85 f6                	test   %esi,%esi
  801652:	89 f5                	mov    %esi,%ebp
  801654:	75 0b                	jne    801661 <__umoddi3+0x91>
  801656:	b8 01 00 00 00       	mov    $0x1,%eax
  80165b:	31 d2                	xor    %edx,%edx
  80165d:	f7 f6                	div    %esi
  80165f:	89 c5                	mov    %eax,%ebp
  801661:	8b 44 24 04          	mov    0x4(%esp),%eax
  801665:	31 d2                	xor    %edx,%edx
  801667:	f7 f5                	div    %ebp
  801669:	89 c8                	mov    %ecx,%eax
  80166b:	f7 f5                	div    %ebp
  80166d:	eb 9c                	jmp    80160b <__umoddi3+0x3b>
  80166f:	90                   	nop
  801670:	89 c8                	mov    %ecx,%eax
  801672:	89 fa                	mov    %edi,%edx
  801674:	83 c4 14             	add    $0x14,%esp
  801677:	5e                   	pop    %esi
  801678:	5f                   	pop    %edi
  801679:	5d                   	pop    %ebp
  80167a:	c3                   	ret    
  80167b:	90                   	nop
  80167c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801680:	8b 04 24             	mov    (%esp),%eax
  801683:	be 20 00 00 00       	mov    $0x20,%esi
  801688:	89 e9                	mov    %ebp,%ecx
  80168a:	29 ee                	sub    %ebp,%esi
  80168c:	d3 e2                	shl    %cl,%edx
  80168e:	89 f1                	mov    %esi,%ecx
  801690:	d3 e8                	shr    %cl,%eax
  801692:	89 e9                	mov    %ebp,%ecx
  801694:	89 44 24 04          	mov    %eax,0x4(%esp)
  801698:	8b 04 24             	mov    (%esp),%eax
  80169b:	09 54 24 04          	or     %edx,0x4(%esp)
  80169f:	89 fa                	mov    %edi,%edx
  8016a1:	d3 e0                	shl    %cl,%eax
  8016a3:	89 f1                	mov    %esi,%ecx
  8016a5:	89 44 24 08          	mov    %eax,0x8(%esp)
  8016a9:	8b 44 24 10          	mov    0x10(%esp),%eax
  8016ad:	d3 ea                	shr    %cl,%edx
  8016af:	89 e9                	mov    %ebp,%ecx
  8016b1:	d3 e7                	shl    %cl,%edi
  8016b3:	89 f1                	mov    %esi,%ecx
  8016b5:	d3 e8                	shr    %cl,%eax
  8016b7:	89 e9                	mov    %ebp,%ecx
  8016b9:	09 f8                	or     %edi,%eax
  8016bb:	8b 7c 24 10          	mov    0x10(%esp),%edi
  8016bf:	f7 74 24 04          	divl   0x4(%esp)
  8016c3:	d3 e7                	shl    %cl,%edi
  8016c5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  8016c9:	89 d7                	mov    %edx,%edi
  8016cb:	f7 64 24 08          	mull   0x8(%esp)
  8016cf:	39 d7                	cmp    %edx,%edi
  8016d1:	89 c1                	mov    %eax,%ecx
  8016d3:	89 14 24             	mov    %edx,(%esp)
  8016d6:	72 2c                	jb     801704 <__umoddi3+0x134>
  8016d8:	39 44 24 0c          	cmp    %eax,0xc(%esp)
  8016dc:	72 22                	jb     801700 <__umoddi3+0x130>
  8016de:	8b 44 24 0c          	mov    0xc(%esp),%eax
  8016e2:	29 c8                	sub    %ecx,%eax
  8016e4:	19 d7                	sbb    %edx,%edi
  8016e6:	89 e9                	mov    %ebp,%ecx
  8016e8:	89 fa                	mov    %edi,%edx
  8016ea:	d3 e8                	shr    %cl,%eax
  8016ec:	89 f1                	mov    %esi,%ecx
  8016ee:	d3 e2                	shl    %cl,%edx
  8016f0:	89 e9                	mov    %ebp,%ecx
  8016f2:	d3 ef                	shr    %cl,%edi
  8016f4:	09 d0                	or     %edx,%eax
  8016f6:	89 fa                	mov    %edi,%edx
  8016f8:	83 c4 14             	add    $0x14,%esp
  8016fb:	5e                   	pop    %esi
  8016fc:	5f                   	pop    %edi
  8016fd:	5d                   	pop    %ebp
  8016fe:	c3                   	ret    
  8016ff:	90                   	nop
  801700:	39 d7                	cmp    %edx,%edi
  801702:	75 da                	jne    8016de <__umoddi3+0x10e>
  801704:	8b 14 24             	mov    (%esp),%edx
  801707:	89 c1                	mov    %eax,%ecx
  801709:	2b 4c 24 08          	sub    0x8(%esp),%ecx
  80170d:	1b 54 24 04          	sbb    0x4(%esp),%edx
  801711:	eb cb                	jmp    8016de <__umoddi3+0x10e>
  801713:	90                   	nop
  801714:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801718:	3b 44 24 0c          	cmp    0xc(%esp),%eax
  80171c:	0f 82 0f ff ff ff    	jb     801631 <__umoddi3+0x61>
  801722:	e9 1a ff ff ff       	jmp    801641 <__umoddi3+0x71>
