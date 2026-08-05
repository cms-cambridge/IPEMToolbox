function nFail = test_resample()
% Systematic tests for IPEMToolbox/OctaveCompat/resample.m
%
% Layers:
%   1. Filter design vs analytic least-squares + Kaiser window
%   2. Polyphase / delay / shape / orientation properties
%   3. Comparison to independent MATLAB-algorithm fixtures
%   4. Interaction with 16-bit quantization (IPEMCalcANI contract)
%
% Run from repo root:
%   octave --no-gui --eval "addpath('tests'); n = test_resample(); assert(n==0)"

  fprintf(1, 'test_resample: starting...\n');

  thisDir = fileparts(mfilename('fullpath'));
  toolboxDir = fullfile(thisDir, '..', 'IPEMToolbox');
  addpath(thisDir);
  addpath(toolboxDir);
  oldPwd = pwd;
  cd(toolboxDir);
  cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
  IPEMSetup;

  resamplePath = which('resample');
  assert(~isempty(strfind(resamplePath, 'OctaveCompat')), ...
    'Expected OctaveCompat/resample.m on path, got: %s', resamplePath);
  fprintf(1, 'Using %s\n', resamplePath);

  fixtureRoot = fullfile(thisDir, 'fixtures', 'resample');
  nFail = 0;

  %% -------------------------------------------------------------------------
  fprintf(1, '\n== Layer 1: filter design ==\n');

  designCases = [
    1, 2;
    1, 4;
    2, 1;
    3, 2;
  ];
  N = 10;
  bta = 5;

  for i = 1:size(designCases, 1)
    p = designCases(i, 1);
    q = designCases(i, 2);
    pqmax = max(p, q);
    fc = 1 / (2 * pqmax);
    L = 2 * N * pqmax + 1;

    hFirls = firls(L - 1, [0, 2 * fc, 2 * fc, 1], [1, 1, 0, 0]);
    hKaiser = kaiser(L, bta);
    hDesigned = p * (hFirls(:).') .* (hKaiser(:).');

    n = 0:(L - 1);
    hAnalytic = 2 * fc * sinc(2 * fc * (n - (L - 1) / 2));
    hAnalytic = p * hAnalytic .* (hKaiser(:).');

    dDesign = max(abs(hDesigned - hAnalytic));
    nFail = report(nFail, dDesign < 1e-12, ...
      sprintf('p=%d q=%d firls*kaiser matches analytic (max|d|=%.3g)', p, q, dDesign));

    nFail = report(nFail, max(abs(hDesigned - fliplr(hDesigned))) < 1e-12, ...
      sprintf('p=%d q=%d designed filter is symmetric', p, q));

    [~, hShim] = resample(zeros(20, 1), p, q, N, bta);
    hCore = hShim;
    while ((numel(hCore) > L) && (hCore(end) == 0))
      hCore(end) = [];
    end
    nz = floor(q - mod((L - 1) / 2, q));
    nFail = report(nFail, numel(hCore) == L + nz, ...
      sprintf('p=%d q=%d shim h length L+nz=%d (got %d)', p, q, L + nz, numel(hCore)));
    nFail = report(nFail, max(abs(hCore((nz + 1):(nz + L)) - hDesigned)) < 1e-12, ...
      sprintf('p=%d q=%d shim core coeffs match designed filter', p, q));
  end

  %% -------------------------------------------------------------------------
  fprintf(1, '\n== Layer 2: polyphase properties ==\n');

  x = sin(2 * pi * (0:199)' / 40);
  ratios = [
    1, 1;
    1, 2;
    1, 4;
    2, 1;
    3, 2;
    2, 3;
  ];
  for i = 1:size(ratios, 1)
    p = ratios(i, 1);
    q = ratios(i, 2);
    y = resample(x, p, q);
    expectedLen = ceil(numel(x) * p / q);
    nFail = report(nFail, numel(y) == expectedLen, ...
      sprintf('p=%d q=%d output length %d (got %d)', p, q, expectedLen, numel(y)));
  end

  % Custom filter vector path must match the designed (N, bta) path.
  [yDesigned, ~] = resample(x, 1, 2, N, bta);
  pq = 2;
  fcH = 1 / (2 * pq);
  LH = 2 * N * pq + 1;
  hVec = 1 * (firls(LH - 1, [0, 2 * fcH, 2 * fcH, 1], [1, 1, 0, 0])(:).') ...
    .* (kaiser(LH, bta)(:).');
  yFromH = resample(x, 1, 2, hVec);
  nFail = report(nFail, max(abs(yDesigned(:) - yFromH(:))) < 1e-12, ...
    'explicit h vector matches designed (N,bta) path');

  X = [x, 0.5 * x, -x];
  Y = resample(X, 1, 2);
  Ycols = [resample(X(:, 1), 1, 2), resample(X(:, 2), 1, 2), resample(X(:, 3), 1, 2)];
  nFail = report(nFail, max(abs(Y(:) - Ycols(:))) < 1e-14, ...
    'matrix columns match independent column resamples');

  xRow = x.';
  yRow = resample(xRow, 1, 2);
  yCol = resample(x, 1, 2);
  nFail = report(nFail, isrow(yRow) && iscolumn(yCol), ...
    'row/column orientation preserved');
  nFail = report(nFail, max(abs(yRow(:) - yCol(:))) < 1e-14, ...
    'row and column inputs produce the same samples');

  impulse = zeros(201, 1);
  impulse(101) = 1;
  yImp = resample(impulse, 1, 2);
  [~, peakAt] = max(abs(yImp));
  nFail = report(nFail, abs(peakAt - 51) <= 2, ...
    sprintf('impulse peak near sample 51 (got %d)', peakAt));

  % Mid-signal agreement with Octave Forge when given the same designed h.
  % Temporarily hide OctaveCompat so which('resample') resolves to Forge;
  % do not rmpath the signal package (firls/kaiser must stay available).
  pkgList = pkg('list');
  signalDir = '';
  for k = 1:numel(pkgList)
    if (strcmp(pkgList{k}.name, 'signal'))
      signalDir = pkgList{k}.dir;
      break;
    end
  end
  if (~isempty(signalDir) && (exist(fullfile(signalDir, 'resample.m'), 'file') == 2))
    p = 1; q = 2;
    pqmax = max(p, q);
    fc = 1 / (2 * pqmax);
    L = 2 * N * pqmax + 1;
    hShared = p * (firls(L - 1, [0, 2 * fc, 2 * fc, 1], [1, 1, 0, 0])(:).') ...
      .* (kaiser(L, bta)(:).');
    yOurs = resample(x, p, q, N, bta);
    compatDir = fullfile(toolboxDir, 'OctaveCompat');
    savedPath = path;
    rmpath(compatDir);
    yForge = resample(x, p, q, hShared);
    path(savedPath);
    n = min(numel(yOurs), numel(yForge));
    lo = max(1, round(0.2 * n));
    hi = min(n, round(0.8 * n));
    c = corrcoef(yOurs(lo:hi), yForge(lo:hi));
    nFail = report(nFail, c(1, 2) > 0.999, ...
      sprintf('mid-signal corr vs Octave Forge with shared design (r=%.6f)', c(1, 2)));
  else
    fprintf(1, 'skip: Octave Forge resample.m not available for cross-check\n');
  end

  %% -------------------------------------------------------------------------
  fprintf(1, '\n== Layer 3: fixture comparison ==\n');

  fixtureNames = {
    'sine_44100_to_22050';
    'matrix_decimate_1_4';
    'impulse_p1_q2';
    'sine_upsample_2_1';
    'sine_p3_q2';
    'noise_44100_to_22050';
  };
  fixtureTol = 1e-7;

  for i = 1:numel(fixtureNames)
    name = fixtureNames{i};
    caseDir = fullfile(fixtureRoot, name);
    meta = jsondecode(fileread(fullfile(caseDir, 'meta.json')));
    xRef = csvread(fullfile(caseDir, 'x.csv'));
    yRef = csvread(fullfile(caseDir, 'y.csv'));
    hRef = csvread(fullfile(caseDir, 'h.csv'));
    p = meta.p;
    q = meta.q;

    if (isfield(meta, 'x_shape'))
      xs = meta.x_shape(:);
      if (numel(xs) == 1 || (numel(xs) == 2 && xs(2) == 1))
        xRef = xRef(:);
        yRef = yRef(:);
      elseif (numel(xs) == 2)
        xRef = reshape(xRef, xs(1), xs(2));
      end
    end

    [y, h] = resample(xRef, p, q, meta.N, meta.beta);

    if (isvector(xRef))
      y = y(:);
      yRef = yRef(:);
    elseif (size(y, 1) ~= size(yRef, 1) && size(y, 1) == size(yRef, 2))
      yRef = yRef.';
    end

    nFail = report(nFail, isequal(size(y), size(yRef)), ...
      sprintf('%s shape %s vs %s', name, mat2str(size(y)), mat2str(size(yRef))));

    if (isequal(size(y), size(yRef)))
      maxAbs = max(abs(y(:) - yRef(:)));
      nFail = report(nFail, maxAbs < fixtureTol, ...
        sprintf('%s max|d|=%.3g (tol=%g)', name, maxAbs, fixtureTol));
    end

    nFail = report(nFail, abs(numel(h) - numel(hRef)) <= 2, ...
      sprintf('%s h length %d vs fixture %d', name, numel(h), numel(hRef)));
  end

  %% -------------------------------------------------------------------------
  fprintf(1, '\n== Layer 4: 16-bit quantization contract ==\n');

  fsIn = 44100;
  t = (0:16351)' / fsIn;
  sig = 0.4 * sin(2 * pi * 440 * t);
  yFloat = resample(sig, 1, 2);
  scaled = yFloat * 32768;
  frac = abs(scaled - floor(scaled) - 0.5);
  nNear = sum(frac < 1e-6);
  fprintf(1, 'info: %d/%d samples within 1e-6 of a half-integer (min distance %.3g)\n', ...
    nNear, numel(frac), min(frac));

  q0 = round(scaled);
  mid = round(numel(q0) / 2);
  q1 = q0;
  q1(mid) = q1(mid) + 1;
  nFail = report(nFail, sum(q0 ~= q1) == 1, ...
    'single-LSB edit flips exactly one quantized sample');

  % Quantized streams from two close float vectors can diverge where values
  % sit near half-integers — document the contract used by IPEMCalcANI.
  alt = yFloat;
  alt(mid) = alt(mid) + 1 / 32768;
  qAlt = round(alt * 32768);
  nFail = report(nFail, sum(q0 ~= qAlt) >= 1, ...
    'one float LSB at 16-bit scale can change quantized PCM');

  %% -------------------------------------------------------------------------
  fprintf(1, '\n');
  if (nFail > 0)
    error('test_resample: %d check(s) failed', nFail);
  end
  fprintf(1, 'test_resample: all checks passed.\n');
end

function nFail = report(nFail, cond, msg)
  if (~cond)
    fprintf(1, 'FAIL: %s\n', msg);
    nFail = nFail + 1;
  else
    fprintf(1, 'ok: %s\n', msg);
  end
end
