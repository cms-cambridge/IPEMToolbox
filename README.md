# IPEM Toolbox (Octave port)

License-free fork of the [IPEM Toolbox](https://github.com/IPEM/IPEMToolbox) for perception-based music analysis, updated to run under **GNU Octave 10.3** instead of historic MATLAB.

This port was produced with an LLM coding agent (Cursor). Treat it as a maintained compatibility layer over the original GPL sources, not as a line-by-line human rewrite of the scientific models.

The C auditory model and the MATLAB `.m` analysis code are unchanged in intent. What changed is the runtime: Octave, modern package APIs, and a small set of shims so results stay close to the MATLAB reference used by [pyLeman2000](https://github.com/cms-cambridge/pyLeman2000) / [leman_2000](https://github.com/pmcharrison/leman_2000).

Docker packaging for the Leman (2000) contextuality pipeline lives in **pyLeman2000**, which builds an image from this fork. This repository ships the toolbox only.

## What changed in this fork

| Area | Change |
|------|--------|
| **`IPEMToolbox/OctaveCompat/`** | Shims for `wavread` / `wavwrite` / `wavplay` / `auread` / `auwrite` (via `audioread` / `audiowrite`), and a **MATLAB-compatible `resample`** |
| **`IPEMSetup`** | Detects Octave, loads the `signal` package, adds `OctaveCompat` to the path, skips MATLAB-only `path2rc` |
| **`IPEMSetupPreferences`** | Octave-safe `prefdir` (no create-directory argument) |
| **`IPEMContextualityIndex`** | Warning-state save/restore that works when Octave’s `warning` returns one output |
| **`AuditoryModel/Octave_UNIX`** | Makefile fixed for modern `make`/`gcc`; MEX gateway gets explicit prototypes |
| **`tests/`** | Headless Octave smoke test and Leman-2000 pipeline check |

Not supported under Octave: the GUIDE UI `IPEMMECReSynthUI`.

### Why `resample` was reimplemented

Octave’s `signal` package and MATLAB design different anti-aliasing filters for `resample`. In this toolbox that matters: `IPEMCalcANI` resamples the input to 22.05 kHz and then decimates the auditory-nerve image by 4. Using Octave’s default filter shifted Leman-2000 running correlations by about **1.5×10⁻⁴** versus the MATLAB MCR reference. The shim reproduces MATLAB’s `firls` + `kaiser(N=10, β=5)` design.

## Snapshot / numerical testing

We compared this Octave build to the pinned MATLAB Runtime image behind pyLeman2000:

`ghcr.io/pmcharrison/leman_2000@sha256:08d5ce84b9844954473832af65188f8f56fdfc8bcc3c64e0307e532a062e2442`

Pipeline under test (same stages as `leman_2000.m`):

1. `IPEMReadSoundFile`
2. `IPEMCalcANI`
3. `IPEMPeriodicityPitch`
4. `IPEMContextualityIndex` (local/global leaky integration → running Pearson correlation)

Fixture: pyLeman2000’s packaged `hihat.wav`, with local decays `[0.1, 0.2]` and global decays `[1.0, 2.0]` (104 correlation samples). Reference values are the R/MATLAB snapshot CSVs in pyLeman2000 (`tests/snapshots/r_hihat_*.csv`).

| Condition | max \|Δ\| in `running_correlation` |
|-----------|-------------------------------------|
| 44.1 kHz input, Octave default `resample` | ~1.5×10⁻⁴ |
| 44.1 kHz input, MATLAB-compatible `resample` shim | **~2.7×10⁻⁶** |
| 22.05 kHz input (no input resampling) | **~5×10⁻¹¹** |

`running_correlation` is dimensionless Pearson *r* on [-1, 1]. On this fixture MATLAB values lie in about [0.95, 1.0], so 2.7×10⁻⁶ is a change in the sixth decimal place—negligible for interpretation, but not bit-identical to pyLeman2000’s `1e-12` MATLAB snapshots.

**Root cause of the residual (44.1 kHz):** after matching the filter design, the remaining gap is MathWorks’ compiled `resample`/`upfirdn` vs our reimplementation, amplified by `IPEMCalcANI` writing a 16-bit temp WAV before the C model. Differential tests ruled out the auditory-model C sources (byte-identical), compiler flags, and the audio I/O shims.

**TODO:** snapshot-test `OctaveCompat/resample` outputs against true MATLAB `resample` (generate fixtures once under licensed MATLAB or a tiny compiled helper; expect near-match, not bit-identity).

## Quick start (Octave)

```bash
# Dependencies (Debian/Ubuntu)
sudo apt-get install build-essential octave octave-dev
# signal package: apt install octave-signal   OR   pkg install -forge signal

cd AuditoryModel/Octave_UNIX
make && make install

cd ../../IPEMToolbox
octave --no-gui --eval "IPEMSetup"

# Headless checks
octave --no-gui --eval "run('../tests/smoke_test_octave.m')"
```

For the full Leman (2000) Docker/Python workflow, use [pyLeman2000](https://github.com/cms-cambridge/pyLeman2000).

## Citation

If you use the IPEM Toolbox in research, please cite:

> Leman, M., Lesaffre, M., & Tanghe, K. (2001). *An introduction to the IPEM Toolbox for Perception-Based Music Analysis.* Conference Program and Abstracts of SMPC 2001, Kingston.

Selected work that builds on these models:

- Leman, M. (2000). An auditory model of the role of short-term memory in probe-tone ratings. *Music Perception, 17*(4), 481–509.
- Janata, P., et al. (2002). The cortical topography of tonal structures underlying Western music. *Science, 298*(5601), 2167–2170.
- Bigand, E., et al. (2014). Empirical evidence for musical syntax processing? *Frontiers in Systems Neuroscience, 8*, 94.

Upstream project and manual: [IPEM/IPEMToolbox](https://github.com/IPEM/IPEMToolbox). Auditory model: Van Immerseel & Martens (ELIS, Ghent). Later UNIX/Octave Makefiles: Stefan Tomic; 64-bit Windows/MATLAB 8 notes: Jane Lee.

## License

GPL (IPEM Toolbox MATLAB code and auditory-model C code), as in the upstream release.
