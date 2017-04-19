#include <inc/mmu.h>
#include <inc/x86.h>
#include <inc/assert.h>
<<<<<<< HEAD
#include <inc/string.h>
=======
>>>>>>> 71c42ff5f0b3fb34395ce94852f2097724fadaa5

#include <kern/pmap.h>
#include <kern/trap.h>
#include <kern/console.h>
#include <kern/monitor.h>
#include <kern/env.h>
#include <kern/syscall.h>
<<<<<<< HEAD
#include <kern/sched.h>
#include <kern/kclock.h>
#include <kern/picirq.h>
#include <kern/cpu.h>
#include <kern/spinlock.h>
=======





#define DPLKERN 0
#define DPLUSR 3
void divide_zero();
void brkpoint();
void no_seg();
void debug();
void nmi();
void oflow();
void bound();
void illop();
void device();
void dblflt();
void tss();   
void stack(); 
void gpflt(); 
void pgflt(); 
void fperr(); 
void align(); 
void mchk();  
void simderr();

void syscalls();





>>>>>>> 71c42ff5f0b3fb34395ce94852f2097724fadaa5

static struct Taskstate ts;

/* For debugging, so print_trapframe can distinguish between printing
 * a saved trapframe and printing the current trapframe and print some
 * additional information in the latter case.
 */
static struct Trapframe *last_tf;
<<<<<<< HEAD

=======
extern uint32_t trap_handlers[];
>>>>>>> 71c42ff5f0b3fb34395ce94852f2097724fadaa5
/* Interrupt descriptor table.  (Must be built at run time because
 * shifted function addresses can't be represented in relocation records.)
 */
struct Gatedesc idt[256] = { { 0 } };
struct Pseudodesc idt_pd = {
	sizeof(idt) - 1, (uint32_t) idt
};


static const char *trapname(int trapno)
{
	static const char * const excnames[] = {
		"Divide error",
		"Debug",
		"Non-Maskable Interrupt",
		"Breakpoint",
		"Overflow",
		"BOUND Range Exceeded",
		"Invalid Opcode",
		"Device Not Available",
		"Double Fault",
		"Coprocessor Segment Overrun",
		"Invalid TSS",
		"Segment Not Present",
		"Stack Fault",
		"General Protection",
		"Page Fault",
		"(unknown trap)",
		"x87 FPU Floating-Point Error",
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

<<<<<<< HEAD
	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
		return "Hardware Interrupt";
	return "(unknown trap)";
}

#define MAX_IDT_NUM 256
#define GATE_DPL 3
extern uint32_t trap_handlers[];
=======
	if (trapno < ARRAY_SIZE(excnames))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
	return "(unknown trap)";
}

>>>>>>> 71c42ff5f0b3fb34395ce94852f2097724fadaa5

void
trap_init(void)
{
<<<<<<< HEAD
	// LAB 3: Your code here.
	// init idt structure
	int i = 0;
	for ( ; i < MAX_IDT_NUM ; i++) {
		SETGATE(idt[i], 0, GD_KT, trap_handlers[i], 0);
	}

	// init break point
	SETGATE(idt[T_BRKPT], 0, GD_KT, trap_handlers[T_BRKPT], GATE_DPL);
	// init syscall
	SETGATE(idt[T_SYSCALL], 0, GD_KT, trap_handlers[T_SYSCALL], GATE_DPL);
=======
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.
	SETGATE(idt[T_DIVIDE],0,GD_KT,divide_zero,DPLKERN);    //CSS=kernel text
    SETGATE(idt[T_BRKPT],0,GD_KT,brkpoint,DPLUSR);
    SETGATE(idt[T_SEGNP],0,GD_KT,no_seg,DPLKERN);
    SETGATE(idt[T_DEBUG],0,GD_KT,debug,DPLKERN);
    SETGATE(idt[T_NMI],0,GD_KT,nmi,DPLKERN);
    SETGATE(idt[T_OFLOW],0,GD_KT,oflow,DPLKERN);
    SETGATE(idt[T_BOUND],0,GD_KT,bound,DPLKERN);
    SETGATE(idt[T_ILLOP],0,GD_KT,illop,DPLKERN);
    SETGATE(idt[T_DEVICE],0,GD_KT,device,DPLKERN);
    SETGATE(idt[T_DBLFLT],0,GD_KT,dblflt,DPLKERN);
    SETGATE(idt[T_TSS], 0, GD_KT, tss, DPLKERN);
    SETGATE(idt[T_STACK], 0, GD_KT, stack, DPLKERN);
    SETGATE(idt[T_GPFLT], 0, GD_KT, gpflt, DPLKERN);
    SETGATE(idt[T_PGFLT], 0, GD_KT, pgflt, DPLKERN);
    SETGATE(idt[T_FPERR], 0, GD_KT, fperr, DPLKERN);
    SETGATE(idt[T_ALIGN], 0, GD_KT, align, DPLKERN);
    SETGATE(idt[T_MCHK], 0, GD_KT, mchk, DPLKERN);
    SETGATE(idt[T_SIMDERR], 0, GD_KT, simderr, DPLKERN);


    SETGATE(idt[T_SYSCALL], 0, GD_KT, syscalls, DPLUSR);


>>>>>>> 71c42ff5f0b3fb34395ce94852f2097724fadaa5

	// Per-CPU setup 
	trap_init_percpu();
}

<<<<<<< HEAD
extern struct Segdesc gdt[];
=======
>>>>>>> 71c42ff5f0b3fb34395ce94852f2097724fadaa5
// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
<<<<<<< HEAD
	// The example code here sets up the Task State Segment (TSS) and
	// the TSS descriptor for CPU 0. But it is incorrect if we are
	// running on other CPUs because each CPU has its own kernel stack.
	// Fix the code so that it works for all CPUs.
	//
	// Hints:
	//   - The macro "thiscpu" always refers to the current CPU's
	//     struct Cpu;
	//   - The ID of the current CPU is given by cpunum() or
	//     thiscpu->cpu_id;
	//   - Use "thiscpu->cpu_ts" as the TSS for the current CPU,
	//     rather than the global "ts" variable;
	//   - Use gdt[(GD_TSS0 >> 3) + i] for CPU i's TSS descriptor;
	//   - You mapped the per-CPU kernel stacks in mem_init_mp()
	//
	// ltr sets a 'busy' flag in the TSS selector, so if you
	// accidentally load the same TSS on more than one CPU, you'll
	// get a triple fault.  If you set up an individual CPU's TSS
	// wrong, you may not get a fault until you try to return from
	// user space on that CPU.
	//
	// LAB 4: Your code here:

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	struct Taskstate *pts = &thiscpu->cpu_ts;
	uint32_t cid = cpunum();
	pts->ts_esp0 = KSTACKTOP - (KSTKSIZE + KSTKGAP) * cid;
	pts->ts_ss0 = GD_KD;

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3) + cid] = SEG16(STS_T32A, (uint32_t) (pts),
					sizeof(struct Taskstate), 0);
	gdt[(GD_TSS0 >> 3) + cid].sd_s = 0;

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0 + cid * sizeof(struct Segdesc));
=======
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
	ts.ts_ss0 = GD_KD;

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);
>>>>>>> 71c42ff5f0b3fb34395ce94852f2097724fadaa5

	// Load the IDT
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
<<<<<<< HEAD
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
=======
	cprintf("TRAP frame at %p\n", tf);
>>>>>>> 71c42ff5f0b3fb34395ce94852f2097724fadaa5
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
		cprintf("  cr2  0x%08x\n", rcr2());
	cprintf("  err  0x%08x", tf->tf_err);
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
	cprintf("  eip  0x%08x\n", tf->tf_eip);
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
	if ((tf->tf_cs & 3) != 0) {
		cprintf("  esp  0x%08x\n", tf->tf_esp);
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
	}
}

void
print_regs(struct PushRegs *regs)
{
	cprintf("  edi  0x%08x\n", regs->reg_edi);
	cprintf("  esi  0x%08x\n", regs->reg_esi);
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
	cprintf("  edx  0x%08x\n", regs->reg_edx);
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
	cprintf("  eax  0x%08x\n", regs->reg_eax);
}

<<<<<<< HEAD

#define Mregs(tf, reg) tf->tf_regs.reg_##reg

static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.

	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
		cprintf("Spurious interrupt on irq 7\n");
		print_trapframe(tf);
		return;
	}

	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	switch(tf->tf_trapno) {
	case T_PGFLT:
		page_fault_handler(tf);
        return;
	case T_BRKPT:
	case T_DEBUG:
		print_trapframe(tf);
		monitor(tf);
        return;
	case T_SYSCALL:
		tf->tf_regs.reg_eax = syscall(
					Mregs(tf,eax),
					Mregs(tf,edx),
					Mregs(tf,ecx),
					Mregs(tf,ebx),
					Mregs(tf,edi),
					Mregs(tf,esi));
	    return;	
    };

	if (tf->tf_trapno == IRQ_OFFSET + IRQ_TIMER) {
		lapic_eoi();
		sched_yield();
        return;
    }

    print_trapframe(tf);
    if (tf->tf_cs == GD_KT) {
        panic("unhandled trap in kernel");
    } else {
        env_destroy(curenv);
    }
=======
static void
trap_dispatch(struct Trapframe *tf)
{
	int rval=0;
		//cprintf("error interruot %x\n", tf->tf_err);
	// Handle processor exceptions.
	// LAB 3: Your code here.
	if(tf->tf_trapno==14)
       {
        page_fault_handler(tf);
        return;
	}
	
	if(tf->tf_trapno==3)
	{
	monitor(tf);
	return;	
		
	}
	
	if(tf->tf_trapno==T_SYSCALL)
	{
	rval= syscall(tf->tf_regs.reg_eax,tf->tf_regs.reg_edx,tf->tf_regs.reg_ecx,tf->tf_regs.reg_ebx,tf->tf_regs.reg_edi,tf->tf_regs.reg_esi);
	tf->tf_regs.reg_eax = rval;
	
	return;
	}

        
        
	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
	if (tf->tf_cs == GD_KT)
		panic("unhandled trap in kernel");
	else {
		env_destroy(curenv);
		return;
	}
>>>>>>> 71c42ff5f0b3fb34395ce94852f2097724fadaa5
}

void
trap(struct Trapframe *tf)
{
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");

<<<<<<< HEAD
	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
		asm volatile("hlt");

=======
>>>>>>> 71c42ff5f0b3fb34395ce94852f2097724fadaa5
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));

<<<<<<< HEAD
	if ((tf->tf_cs & 3) == 3) {
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		lock_kernel();
		assert(curenv);

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
			env_free(curenv);
			curenv = NULL;
			sched_yield();
		}

=======
	cprintf("Incoming TRAP frame at %p\n", tf);

	if ((tf->tf_cs & 3) == 3) {
		// Trapped from user mode.
		assert(curenv);

>>>>>>> 71c42ff5f0b3fb34395ce94852f2097724fadaa5
		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

<<<<<<< HEAD
	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
		env_run(curenv);
	else
		sched_yield();
=======
	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
	env_run(curenv);
>>>>>>> 71c42ff5f0b3fb34395ce94852f2097724fadaa5
}


void
page_fault_handler(struct Trapframe *tf)
{
	uint32_t fault_va;

	// Read processor's CR2 register to find the faulting address
	fault_va = rcr2();

	// Handle kernel-mode page faults.
<<<<<<< HEAD

	// LAB 3: Your code here.
	if ((tf->tf_cs & 0x1) == 0) {
	      print_trapframe(tf);
	      panic("Kernel page fault");
	}
=======
	if((tf->tf_cs & 3)==0)
	    panic("page fault kernel mode");

	// LAB 3: Your code here.
>>>>>>> 71c42ff5f0b3fb34395ce94852f2097724fadaa5

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

<<<<<<< HEAD
	// Call the environment's page fault upcall, if one exists.  Set up a
	// page fault stack frame on the user exception stack (below
	// UXSTACKTOP), then branch to curenv->env_pgfault_upcall.
	//
	// The page fault upcall might cause another page fault, in which case
	// we branch to the page fault upcall recursively, pushing another
	// page fault stack frame on top of the user exception stack.
	//
	// The trap handler needs one word of scratch space at the top of the
	// trap-time stack in order to return.  In the non-recursive case, we
	// don't have to worry about this because the top of the regular user
	// stack is free.  In the recursive case, this means we have to leave
	// an extra word between the current top of the exception stack and
	// the new stack frame because the exception stack _is_ the trap-time
	// stack.
	//
	// If there's no page fault upcall, the environment didn't allocate a
	// page for its exception stack or can't write to it, or the exception
	// stack overflows, then destroy the environment that caused the fault.
	// Note that the grade script assumes you will first check for the page
	// fault upcall and print the "user fault va" message below if there is
	// none.  The remaining three checks can be combined into a single test.
	//
	// Hints:
	//   user_mem_assert() and env_run() are useful here.
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.
	if (!curenv->env_pgfault_upcall)
		goto userfault;

	if (USTACKTOP < tf->tf_esp && tf->tf_esp < UXSTACKTOP - PGSIZE)
		goto userfault;

	{
		void *dststack;
		// reference: inc/trap.h: 59 ~ 86
		struct UTrapframe utf;
		utf.utf_fault_va = fault_va;
		utf.utf_err = tf->tf_err;
		utf.utf_regs = tf->tf_regs;
		utf.utf_eip = tf->tf_eip;
		utf.utf_eflags = tf->tf_eflags;
		utf.utf_esp = tf->tf_esp;

		if (UXSTACKTOP - PGSIZE <= tf->tf_esp
		    && tf->tf_esp <= UXSTACKTOP - 1) {
			dststack = (void *)(tf->tf_esp - sizeof(struct UTrapframe) - 4);
		} else {
			dststack = (void *)(UXSTACKTOP - sizeof(struct UTrapframe));
		}

		user_mem_assert(curenv, dststack, sizeof(struct UTrapframe), PTE_P | PTE_W | PTE_U);
		memmove(dststack, (void *)&utf, sizeof(struct UTrapframe));
		tf->tf_eip = (uint32_t) curenv->env_pgfault_upcall;
		tf->tf_esp = (uint32_t) dststack;

		env_run(curenv);
		
	}
userfault:
=======
>>>>>>> 71c42ff5f0b3fb34395ce94852f2097724fadaa5
	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
<<<<<<< HEAD

	user_mem_assert(curenv, (void*)fault_va, 1, PTE_U | PTE_P);

=======
>>>>>>> 71c42ff5f0b3fb34395ce94852f2097724fadaa5
	env_destroy(curenv);
}

