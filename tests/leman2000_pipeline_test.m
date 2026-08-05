% Pipeline smoke test for Leman (2000) contextuality functions under Octave.
% Mirrors leman_2000.m stages and compares running correlations to pyLeman2000
% R/MATLAB snapshots when SNAPSHOT_CSV is provided.

fprintf(1, 'Leman 2000 pipeline test starting...\n');

thisDir = fileparts(mfilename('fullpath'));
toolboxDir = fullfile(thisDir, '..', 'IPEMToolbox');
addpath(toolboxDir);
cd(toolboxDir);
IPEMSetup;

wavPath = getenv('IPEM_TEST_WAV');
if isempty(wavPath)
  error('Set IPEM_TEST_WAV to a .wav path');
end

snapshotCsv = getenv('IPEM_SNAPSHOT_CSV');
tol = str2double(getenv('IPEM_CORR_TOL'));
if isnan(tol) || isempty(tol)
  tol = 1e-4;  % Octave vs MATLAB; snapshots use 1e-12 against MATLAB binary
end

[inDir, inKey, inExt] = fileparts(wavPath);
inName = [inKey, inExt];
[s, fs] = IPEMReadSoundFile(inName, inDir);
numChannels = size(s, 1);
if (numChannels == 2)
  s = (s(1, :) + s(2, :)) / 2;
end
audioLengthSec = length(s) / fs;
fprintf(1, 'Audio: length=%.10f s channels=%d fs=%.1f\n', audioLengthSec, numChannels, fs);

fprintf(1, 'Stage: IPEMCalcANI...\n');
[ANI, ANIFreq, ANIFilterFreqs] = IPEMCalcANI(s, fs);
assert(size(ANI, 1) == 40, 'ANI channels');
assert(numel(ANIFilterFreqs) == 40, 'ANI filter freqs');
fprintf(1, 'ANI size=%s freq=%.4f\n', mat2str(size(ANI)), ANIFreq);

fprintf(1, 'Stage: IPEMPeriodicityPitch...\n');
[PP, PPFreq, PPPeriods, PPFANI] = IPEMPeriodicityPitch(ANI, ANIFreq);
assert(~isempty(PP), 'PP empty');
assert(PPFreq > 0, 'PPFreq');
fprintf(1, 'PP size=%s freq=%.4f periods=%d\n', mat2str(size(PP)), PPFreq, numel(PPPeriods));

localDecays = [0.1, 0.2];
globalDecays = [1.0, 2.0];
rows = {};
rowIdx = 0;

for gi = 1:numel(globalDecays)
  for li = 1:numel(localDecays)
    localDecay = localDecays(li);
    globalDecay = globalDecays(gi);
    fprintf(1, 'Stage: IPEMContextualityIndex local=%.3f global=%.3f...\n', localDecay, globalDecay);
    [~, ~, ~, ~, runningCorr] = IPEMContextualityIndex( ...
      PP, PPFreq, PPPeriods, [], localDecay, globalDecay, [], 0);
    assert(numel(runningCorr) > 1, 'running correlation too short');
    timeSec = linspace(0, audioLengthSec, numel(runningCorr));
    for t = 1:numel(runningCorr)
      rowIdx = rowIdx + 1;
      rows{rowIdx, 1} = localDecay;
      rows{rowIdx, 2} = globalDecay;
      rows{rowIdx, 3} = timeSec(t);
      rows{rowIdx, 4} = runningCorr(t);
    end
  end
end

fprintf(1, 'Computed %d correlation samples across %d param combos\n', rowIdx, numel(localDecays) * numel(globalDecays));

outCsv = getenv('IPEM_OUT_CSV');
if ~isempty(outCsv)
  fid = fopen(outCsv, 'w');
  fprintf(fid, 'local_decay_sec,global_decay_sec,time_sec,running_correlation\n');
  for i = 1:rowIdx
    fprintf(fid, '%.12g,%.12g,%.12g,%.12g\n', rows{i, 1}, rows{i, 2}, rows{i, 3}, rows{i, 4});
  end
  fclose(fid);
  fprintf(1, 'Wrote %s\n', outCsv);
end

% Metadata checks against known hihat fixture when length matches snapshot.
if abs(audioLengthSec - 0.3707936508) < 1e-6 && abs(fs - 44100) < 1e-6
  fprintf(1, 'Metadata matches hihat fixture expectations.\n');
else
  fprintf(1, 'WARNING: audio metadata differs from hihat snapshot fixture.\n');
end

if ~isempty(snapshotCsv)
  fprintf(1, 'Comparing to snapshot %s (tol=%g)...\n', snapshotCsv, tol);
  snap = dlmread(snapshotCsv, ',', 1, 0);
  assert(size(snap, 1) == rowIdx, 'row count mismatch: got %d expected %d', rowIdx, size(snap, 1));
  maxAbs = 0;
  maxRel = 0;
  nFail = 0;
  for i = 1:rowIdx
    assert(abs(rows{i, 1} - snap(i, 1)) < 1e-9, 'local decay mismatch at row %d', i);
    assert(abs(rows{i, 2} - snap(i, 2)) < 1e-9, 'global decay mismatch at row %d', i);
    assert(abs(rows{i, 3} - snap(i, 3)) < 1e-8, 'time mismatch at row %d', i);
    got = rows{i, 4};
    expv = snap(i, 4);
    absErr = abs(got - expv);
    relErr = absErr / max(1, abs(expv));
    maxAbs = max(maxAbs, absErr);
    maxRel = max(maxRel, relErr);
    if (absErr > tol) && (relErr > tol)
      nFail = nFail + 1;
      if (nFail <= 5)
        fprintf(1, 'DIFF row %d t=%.6f got=%.12g exp=%.12g abs=%.3g rel=%.3g\n', ...
          i, rows{i, 3}, got, expv, absErr, relErr);
      end
    end
  end
  fprintf(1, 'Snapshot compare: maxAbs=%.6g maxRel=%.6g nFail=%d/%d\n', maxAbs, maxRel, nFail, rowIdx);
  if (nFail > 0)
    error('Snapshot comparison failed for %d/%d samples at tol=%g', nFail, rowIdx, tol);
  end
  fprintf(1, 'Snapshot comparison passed at tol=%g\n', tol);
end

fprintf(1, 'Leman 2000 pipeline test passed (functions ran successfully).\n');
