function wavwrite(y, varargin)
% Compatibility shim for MATLAB wavwrite using audiowrite.
%
% Supports:
%   wavwrite(y, filename)
%   wavwrite(y, Fs, filename)
%   wavwrite(y, Fs, nbits, filename)

  if (nargin < 2)
    error('wavwrite: at least y and filename are required');
  end

  Fs = 8000;
  nbits = 16;
  filename = '';

  if (nargin == 2)
    filename = varargin{1};
  elseif (nargin == 3)
    Fs = varargin{1};
    filename = varargin{2};
  elseif (nargin >= 4)
    Fs = varargin{1};
    nbits = varargin{2};
    filename = varargin{3};
  end

  if isempty(filename) || ~ischar(filename)
    error('wavwrite: filename must be a string');
  end

  audiowrite(filename, y, Fs, 'BitsPerSample', nbits);
end
