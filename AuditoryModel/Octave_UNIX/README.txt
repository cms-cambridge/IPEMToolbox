To use the AuditoryModel with the IPEM Toolbox and GNU Octave:

  sudo apt-get install build-essential octave-dev
  # Or on older Debian/Ubuntu: octave-pkg-dev

  make
  make install

After you compile this version, make sure the IPEMProcessAuditoryModel.m
file and the compiled mex binary were copied to IPEMToolbox/Common.

For a ready-made container (Octave 10.3), see the repository Dockerfile.
