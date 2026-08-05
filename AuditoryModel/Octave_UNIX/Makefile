# Makefile by Joren Six, IPEM, University Ghent
# joren.six@ugent.be
# Updated 2014.01.06
# Updated 2026 for modern Octave (tested target: Octave 10.3)

# Originally tested on 64-bit Debian Wheezy with Octave 3.6.
# Current Docker target: gnuoctave/octave:10.3.0

#if compiling on Mac Intel 64-bit, comment out the following line and uncomment the 
#line with the -arch x86_64 flag
GCCFLAGS = -DMATLAB_MEX_FILE -fPIC -fno-omit-frame-pointer -D_GNU_SOURCE -pthread -fexceptions -std=gnu89
OBJDIR=./Release
GCC=gcc
INCLUDE= -I../src -I../src/library -I../src/audiprog
OBJS = $(OBJDIR)/Audimod.o $(OBJDIR)/AudiProg.o $(OBJDIR)/command.o $(OBJDIR)/cpu.o $(OBJDIR)/cpupitch.o $(OBJDIR)/decimation.o $(OBJDIR)/ecebank.o $(OBJDIR)/filenames.o $(OBJDIR)/filterbank.o $(OBJDIR)/Hcmbank.o $(OBJDIR)/IPEMAuditoryModel.o $(OBJDIR)/pario.o $(OBJDIR)/sigio.o

$(OBJDIR):
	mkdir -p $(OBJDIR)

#compile the objects file and creates a mex file
all: $(OBJDIR)
	$(GCC) -c $(INCLUDE) $(GCCFLAGS) ../src/audiprog/Audimod.c    -o $(OBJDIR)/Audimod.o
	$(GCC) -c $(INCLUDE) $(GCCFLAGS) ../src/audiprog/AudiProg.c   -o $(OBJDIR)/AudiProg.o
	$(GCC) -c $(INCLUDE) $(GCCFLAGS) ../src/library/command.c     -o $(OBJDIR)/command.o
	$(GCC) -c $(INCLUDE) $(GCCFLAGS) ../src/audiprog/cpu.c        -o $(OBJDIR)/cpu.o
	$(GCC) -c $(INCLUDE) $(GCCFLAGS) ../src/audiprog/cpupitch.c   -o $(OBJDIR)/cpupitch.o
	$(GCC) -c $(INCLUDE) $(GCCFLAGS) ../src/audiprog/decimation.c -o $(OBJDIR)/decimation.o
	$(GCC) -c $(INCLUDE) $(GCCFLAGS) ../src/audiprog/ecebank.c    -o $(OBJDIR)/ecebank.o
	$(GCC) -c $(INCLUDE) $(GCCFLAGS) ../src/library/filenames.c   -o $(OBJDIR)/filenames.o
	$(GCC) -c $(INCLUDE) $(GCCFLAGS) ../src/audiprog/filterbank.c -o $(OBJDIR)/filterbank.o
	$(GCC) -c $(INCLUDE) $(GCCFLAGS) ../src/audiprog/Hcmbank.c    -o $(OBJDIR)/Hcmbank.o
	$(GCC) -c $(INCLUDE) $(GCCFLAGS) ../src/IPEMAuditoryModel.c   -o $(OBJDIR)/IPEMAuditoryModel.o
	$(GCC) -c $(INCLUDE) $(GCCFLAGS) ../src/library/pario.c       -o $(OBJDIR)/pario.o
	$(GCC) -c $(INCLUDE) $(GCCFLAGS) ../src/library/sigio.c       -o $(OBJDIR)/sigio.o
	mkoctfile --mex $(INCLUDE) IPEMProcessAuditoryModelSafe.c $(OBJS) --output $(OBJDIR)/IPEMProcessAuditoryModelSafe.mex
	

clean:
	rm -f $(OBJDIR)/*.o
	rm -f $(OBJDIR)/*.mex

install:
	cp $(OBJDIR)/IPEMProcessAuditoryModelSafe.mex ../../IPEMToolbox/Common
	cp IPEMProcessAuditoryModel.m ../../IPEMToolbox/Common
