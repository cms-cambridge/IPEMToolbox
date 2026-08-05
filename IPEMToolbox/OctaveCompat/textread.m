function varargout = textread(filename, formatSpec, varargin)
% Minimal textread shim for Octave (ANI file loading).
%
% Supports the IPEM usage:
%   data = textread(filename, '%f');

  if (nargin < 1)
    error('textread: filename is required');
  end
  if (nargin < 2) || isempty(formatSpec)
    formatSpec = '%f';
  end

  fid = fopen(filename, 'r');
  if (fid < 0)
    error('textread: could not open file %s', filename);
  end
  data = fscanf(fid, formatSpec);
  fclose(fid);

  varargout{1} = data;
  for i = 2:max(1, nargout)
    varargout{i} = [];
  end
end
