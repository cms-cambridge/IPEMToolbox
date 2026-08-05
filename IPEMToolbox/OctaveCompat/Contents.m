% IPEM Toolbox - Octave compatibility helpers
%
% Compatibility shims for running the IPEM Toolbox under GNU Octave:
%   wavread   - MATLAB wavread API via audioread
%   wavwrite  - MATLAB wavwrite API via audiowrite
%   wavplay   - Headless-friendly playback stub
%   auread    - MATLAB auread API via audioread
%   auwrite   - MATLAB auwrite API via audiowrite
%   resample  - MATLAB-compatible anti-aliasing filter design
%
% resample matters for numerical agreement with historic MATLAB results:
% Octave's signal package designs a different anti-aliasing filter, which
% shifts decimated auditory nerve images by ~3e-2 and running correlations
% by ~1.5e-4. See tests/leman2000_pipeline_test.m.
%
% Note: Octave 10 provides textread natively; no shim is needed.
