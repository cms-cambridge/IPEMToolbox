# pyLeman2000 Octave backend — delivery branch

These files are **not part of the IPEM Toolbox**. They belong in
[cms-cambridge/pyLeman2000](https://github.com/cms-cambridge/pyLeman2000).

They are staged here only because the cloud agent that produced them could push
to this repository but not to pyLeman2000. Delete this branch once the changes
have landed there.

## What it contains

A license-free **GNU Octave Docker backend** for pyLeman2000, built from this
toolbox fork instead of the MATLAB Compiler Runtime image.

| Path | Purpose |
|------|---------|
| `docker/octave/Dockerfile` | Octave 10.3 image; clones this fork at a pinned SHA, builds the auditory-model MEX, installs Octave Forge `signal` |
| `docker/octave/leman_2000.m` | Octave port of `leman_2000.m` (same JSON schema as the MATLAB binary) |
| `docker/octave/leman_2000_docker.sh` | Entrypoint matching the MATLAB MCR CLI, so `docker_runner.py` works unchanged |
| `scripts/build_octave_image.sh` | Convenience build script |
| `src/pyleman2000/docker_runner.py` | Adds `DEFAULT_OCTAVE_IMAGE` |
| `src/pyleman2000/__init__.py` | Exports `DEFAULT_IMAGE` and `DEFAULT_OCTAVE_IMAGE` |
| `src/pyleman2000/api.py` | Docstring notes the Octave backend option |
| `tests/test_octave_backend.py` | Integration check, skipped when the image is not built |
| `pyproject.toml` | Includes `/docker` in the sdist |
| `README.pyleman2000.md` | Updated pyLeman2000 README (backend table, build instructions) |
| `pyLeman2000-octave-backend.patch` | The same changes as a `git am`-able patch |

The Dockerfile pins `IPEM_REF` to a commit of this fork. Update that pin when
the toolbox PR merges.

## How to apply

Preferred, from a pyLeman2000 checkout:

```bash
git clone https://github.com/cms-cambridge/pyLeman2000.git
cd pyLeman2000
git checkout -b cursor/octave-backend-900c

curl -L -o /tmp/octave-backend.patch \
  https://raw.githubusercontent.com/cms-cambridge/IPEMToolbox/cursor/pyleman2000-octave-backend-900c/pyleman2000-octave-backend/pyLeman2000-octave-backend.patch

git am /tmp/octave-backend.patch
git push -u origin cursor/octave-backend-900c
```

If `git am` conflicts (for example pyLeman2000 has moved on), copy the files in
this directory over the matching paths instead and commit them.

## Verification already performed

Built as `pyleman2000-octave:dev` and run against the packaged `hihat.wav`
through the Python API:

- 104 running-correlation rows and 12 windowed rows, as expected
- metadata matches `0.3707936508 s`, 1 channel, 44100 Hz
- max |Δ| versus the MATLAB snapshots in `tests/snapshots/`: **2.7×10⁻⁶**

That is close but not bit-identical, so the existing `1e-12` snapshot tests
still require the MATLAB image. See the toolbox README for the analysis.
