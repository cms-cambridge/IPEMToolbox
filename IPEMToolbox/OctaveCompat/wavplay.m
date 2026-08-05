function wavplay(y, Fs, varargin)
% Headless-friendly stub for MATLAB wavplay.
%
% In Docker / non-interactive environments audio playback is skipped.
% When a display/audio device is available, sound() is used.

  if (nargin < 1)
    return;
  end
  if (nargin < 2) || isempty(Fs)
    Fs = 22050;
  end

  syncMode = true;
  if (nargin >= 3) && ischar(varargin{1})
    syncMode = strcmpi(varargin{1}, 'sync');
  end

  try
    if exist('sound', 'builtin') || exist('sound', 'file')
      sound(y, Fs);
      if syncMode
        % MATLAB audio is usually samples-by-channels, but several IPEM
        % helpers pass mono as a row vector (1xN). Use the sample count,
        % not size(y,1), so 'sync' blocks for the full duration.
        if (isvector(y))
          nSamples = numel(y);
        else
          nSamples = size(y, 1);
        end
        pause(nSamples / Fs + 0.05);
      end
    else
      warning('wavplay: playback unavailable; skipping audio output');
    end
  catch
    warning('wavplay: playback failed; skipping audio output');
  end
end
