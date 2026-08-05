function varargout = wavread(filename, varargin)
% Compatibility shim for MATLAB wavread using audioread.
%
% Supports:
%   [y, Fs] = wavread(filename)
%   [y, Fs, nbits] = wavread(filename)
%   [y, Fs] = wavread(filename, N)
%   [y, Fs] = wavread(filename, [N1 N2])
%   siz = wavread(filename, 'size')
%   [siz, Fs] = wavread(filename, 'size')

  if (nargin < 1)
    error('wavread: filename is required');
  end

  info = audioinfo(filename);
  nSamples = info.TotalSamples;
  nChannels = info.NumChannels;
  Fs = info.SampleRate;
  if isfield(info, 'BitsPerSample')
    nbits = info.BitsPerSample;
  else
    nbits = 16;
  end

  if (nargin >= 2) && ischar(varargin{1}) && strcmpi(varargin{1}, 'size')
    varargout{1} = [nSamples, nChannels];
    if (nargout >= 2)
      varargout{2} = Fs;
    end
    if (nargout >= 3)
      varargout{3} = nbits;
    end
    return;
  end

  if (nargin < 2) || isempty(varargin{1})
    y = audioread(filename);
  else
    rangeArg = varargin{1};
    if isscalar(rangeArg)
      samples = [1, rangeArg];
    else
      samples = rangeArg(:).';
    end
    y = audioread(filename, samples);
  end

  varargout{1} = y;
  if (nargout >= 2)
    varargout{2} = Fs;
  end
  if (nargout >= 3)
    varargout{3} = nbits;
  end
end
