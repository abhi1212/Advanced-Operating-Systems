// implement fork from user space

#include <inc/string.h>
#include <inc/lib.h>

// PTE_COW marks copy-on-write page table entries.
// It is one of the bits explicitly allocated to user processes (PTE_AVAIL).
#define PTE_COW		0x800

extern void _pgfault_upcall(void);

//
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
	void *addr = (void *) utf->utf_fault_va;
	uint32_t err = utf->utf_err;
	int r;

	// Check that the faulting access was (1) a write, and (2) to a
	// copy-on-write page.  If not, panic.
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).

	// LAB 4: Your code here.
	//cprintf("err=%d",err);
	//cprintf("im here = %x",(uvpt[PGNUM((uint32_t)addr)] & (PTE_W|PTE_COW)));

	if((uvpt[PGNUM((uint32_t)addr)] & (PTE_W|PTE_COW)) == 0  && (err & FEC_WR) )
		panic("Trying to write on a read only page or the error is not a Write error");

	// Allocate a new page, map it at a temporary location (PFTEMP),
	// copy the data from the old page to the new page, then move the new
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.

	// LAB 4: Your code here.
	void * vAddr = (void *)(ROUNDDOWN((uint32_t) addr, PGSIZE));
	if ((r = sys_page_alloc(0, (void*) PFTEMP, PTE_P|PTE_U|PTE_W)) < 0)
		panic("sys_page_alloc: %e", r);
		
	memmove((void *)PFTEMP, vAddr, PGSIZE);
	
	if ((r = sys_page_map(0, (void *)PFTEMP, 0, vAddr, PTE_P|PTE_U|PTE_W)) < 0)
		panic("sys_page_map: %e", r);
		
	
	
	if ((r = sys_page_unmap(0, PFTEMP)) < 0)
		panic("sys_page_unmap: %e", r);

}

//
// Map our virtual page pn (address pn*PGSIZE) into the target envid
// at the same virtual address.  If the page is writable or copy-on-write,
// the new mapping must be created copy-on-write, and then our mapping must be
// marked copy-on-write as well.  (Exercise: Why do we need to mark ours
// copy-on-write again if it was already copy-on-write at the beginning of
// this function?)
//
// Returns: 0 on success, < 0 on error.
// It is also OK to panic on error.
//
static int
duppage(envid_t envid, unsigned pn)
{
	int r;
	void * address = (void *)(pn*PGSIZE);
	
		int perm = 0;
		int perm1 =0;
		perm |= PTE_P|PTE_U|PTE_COW;
		perm1 |= PTE_P|PTE_U;

	if((uvpt[pn] & PTE_W) || (uvpt[pn] & PTE_COW))
	{
		
	
		if ((r = sys_page_map(0, address, envid, address, perm)) < 0)
			panic("sys_page_map: %e", r);
		if ((r = sys_page_map(0, address, 0, address, perm)) < 0)
			panic("sys_page_map: %e", r);
	}

	else if(uvpt[pn] & PTE_U)
	{
		if ((r = sys_page_map(0, address, envid, address, perm1)) < 0)
			panic("sys_page_map: %e", r);
		if ((r = sys_page_map(0, address, 0, address, perm1)) < 0)
			panic("sys_page_map: %e", r);
	}

	return 0;
}

//
// User-level fork with copy-on-write.
// Set up our page fault handler appropriately.
// Create a child.
// Copy our address space and page fault handler setup to the child.
// Then mark the child as runnable and return.
//
// Returns: child's envid to the parent, 0 to the child, < 0 on error.
// It is also OK to panic on error.
//
// Hint:
//   Use uvpd, uvpt, and duppage.
//   Remember to fix "thisenv" in the child process.
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
	// LAB 4: Your code here.
	envid_t envid;
	extern unsigned char end[];
	uint32_t pn;
	
	set_pgfault_handler(pgfault);
	
	envid = sys_exofork();
	//cprintf("envId=%d",envid);
	if (envid < 0)
		panic("sys_exofork: %e", envid);
	if (envid == 0) {
		// We're the child.
		// The copied value of the global variable 'thisenv'
		// is no longer valid (it refers to the parent!).
		// Fix it and return 0.
		thisenv = &envs[ENVX(sys_getenvid())];
		return 0;
	}
	uint32_t i=0;
	for (pn =  PGNUM(UTEXT); pn < PGNUM(UXSTACKTOP - PGSIZE); pn += 1)
	{
		if(!(uvpd[PDX(pn<<PGSHIFT)] & PTE_P)) continue;
		if(!(uvpt[pn] & PTE_P)) continue;
		if((pn << PGSHIFT) < (UXSTACKTOP - PGSIZE))
		duppage(envid, pn);	
		//i++;
		//cprintf("i=%d",i);
	}
	
	//panic("im here");
	
		
	int r;
	if ((r = sys_page_alloc(envid, (void *)(UXSTACKTOP-PGSIZE), PTE_P|PTE_U|PTE_W)) < 0)
		panic("sys_page_alloc: %e", r);
		
	int status;
	if((status =sys_env_set_pgfault_upcall(envid, thisenv->env_pgfault_upcall)) < 0)
		panic("Bad Environment in user pagefault handler");
			
	if ((r = sys_env_set_status(envid, ENV_RUNNABLE)) < 0)
		panic("sys_env_set_status: %e", r);
		
	return envid;
}

// Challenge!
int
sfork(void)
{
	panic("sfork not implemented");
	return -E_INVAL;
}
