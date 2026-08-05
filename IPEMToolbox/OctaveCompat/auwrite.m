function auwrite(y, varargin)
% Compatibility shim for MATLAB auwrite using audiowrite.
% Same calling conventions as wavwrite for the IPEMToolbox usage.

  wavwrite(y, varargin{:});
end
