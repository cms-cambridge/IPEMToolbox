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
        pause(size(y, 1) / Fs + 0.05);
      end
    else
      warning('wavplay: playback unavailable; skipping audio output');
    end
  catch
    warning('wavplay: playback failed; skipping audio output');
  end
end
