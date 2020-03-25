# Build the kernel, then generate a release CPIO

all: kernel
	find . | grep -v "README.md" | grep -v "cpio" | grep -v "Makefile" | grep -v ".git" | cpio -o > photon.cpio

kernel:
	make -C ksrc
