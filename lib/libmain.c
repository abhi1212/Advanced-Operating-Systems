// Called from entry.S to get us going.
<<<<<<< HEAD
// entry.S already took care of defining envs, pages, vpd, and vpt.
=======
// entry.S already took care of defining envs, pages, uvpd, and uvpt.
>>>>>>> 71c42ff5f0b3fb34395ce94852f2097724fadaa5

#include <inc/lib.h>

extern void umain(int argc, char **argv);

const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
<<<<<<< HEAD
	// reference inc/env.h
	envid_t eid = sys_getenvid();
	thisenv = (struct Env *) envs + ENVX(eid);
=======
	
	thisenv = (struct Env*)envs + ENVX(sys_getenvid());
>>>>>>> 71c42ff5f0b3fb34395ce94852f2097724fadaa5

	// save the name of the program so that panic() can use it
	if (argc > 0)
		binaryname = argv[0];

	// call user main routine
	umain(argc, argv);

	// exit gracefully
	exit();
}

