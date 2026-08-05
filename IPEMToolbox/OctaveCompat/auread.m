function varargout = auread(filename, varargin)
% Compatibility shim for MATLAB auread using audioread.
% Same calling conventions as wavread for the IPEMToolbox usage.

  [varargout{1:nargout}] = wavread(filename, varargin{:});
end
