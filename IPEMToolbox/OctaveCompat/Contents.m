% IPEM Toolbox - Octave compatibility helpers
%
% Compatibility shims for running the IPEM Toolbox under GNU Octave:
%   wavread   - MATLAB wavread API via audioread
%   wavwrite  - MATLAB wavwrite API via audiowrite
%   wavplay   - Headless-friendly playback stub
%   auread    - MATLAB auread API via audioread
%   auwrite   - MATLAB auwrite API via audiowrite
%
% Note: Octave 10 provides textread natively; no shim is needed.
