% Smoke test for the IPEM Toolbox under GNU Octave.
% Generates a short tone, computes an auditory nerve image, and checks shape.

fprintf(1, 'IPEM Octave smoke test starting...\n');

thisDir = fileparts(mfilename('fullpath'));
toolboxDir = fullfile(thisDir, '..', 'IPEMToolbox');
addpath(toolboxDir);
cd(toolboxDir);

IPEMSetup;

% Prefer a non-interactive graphics toolkit when available.
try
  available = available_graphics_toolkits();
  if any(strcmp(available, 'gnuplot'))
    graphics_toolkit('gnuplot');
  end
catch
  % Ignore toolkit selection failures in headless environments.
end

fs = 22050;
t = 0:(1/fs):0.25;
signal = 0.4 * sin(2 * pi * 440 * t);

fprintf(1, 'Computing ANI for a 440 Hz tone (%.2f s)...\n', t(end));
[ANI, ANIFreq, ANIFilterFreqs] = IPEMCalcANI(signal, fs, [], 0);

assert(~isempty(ANI), 'ANI is empty');
assert(size(ANI, 1) == 40, 'Expected 40 ANI channels, got %d', size(ANI, 1));
assert(size(ANI, 2) > 10, 'ANI has too few samples (%d)', size(ANI, 2));
assert(numel(ANIFilterFreqs) == 40, 'Expected 40 filter frequencies');
assert(ANIFreq > 0, 'ANIFreq should be positive');

% Also exercise wavread/wavwrite shims via a round-trip.
tmpWav = fullfile(IPEMRootDir('code'), 'Temp', 'smoke_tone.wav');
wavwrite(signal(:), fs, 16, tmpWav);
[yRoundTrip, fsRoundTrip] = wavread(tmpWav);
assert(abs(fsRoundTrip - fs) < 1e-6, 'Sample rate mismatch after wav round-trip');
assert(size(yRoundTrip, 1) == numel(signal), 'Sample count mismatch after wav round-trip');
delete(tmpWav);

fprintf(1, 'OK: ANI size=%s ANIFreq=%.2f Hz\n', mat2str(size(ANI)), ANIFreq);
fprintf(1, 'IPEM Octave smoke test passed.\n');
