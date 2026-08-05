#!/usr/bin/env python3
"""Generate reference fixtures for OctaveCompat/resample.m.

Implements MathWorks' documented resample algorithm independently of the
Octave shim:

  h = p * firls(L-1, [0 2*fc 2*fc 1], [1 1 0 0]) .* kaiser(L, beta)
  then upsample → FIR filter → downsample with MATLAB-style delay alignment.

Fixtures are compared by tests/test_resample.m. Regenerate with:

  python3 tests/generate_resample_fixtures.py
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from scipy.signal import firls, lfilter
from scipy.signal.windows import kaiser

OUT_DIR = Path(__file__).resolve().parent / "fixtures" / "resample"


def matlab_resample(
    x: np.ndarray,
    p: int,
    q: int,
    n: int = 10,
    beta: float = 5.0,
) -> tuple[np.ndarray, np.ndarray]:
    """Approximate MATLAB resample for real vectors/matrices (column-wise)."""
    x = np.asarray(x, dtype=float)
    is_row = x.ndim == 1 or (x.ndim == 2 and x.shape[0] == 1 and x.shape[1] > 1)
    if x.ndim == 1:
        cols = x.reshape(-1, 1)
    elif is_row:
        cols = x.reshape(-1, 1)
    else:
        cols = x

    # Keep integer ratios as given (IPEM uses exact 1/2 and 1/4).
    p = int(p)
    q = int(q)
    g = np.gcd(p, q)
    p //= int(g)
    q //= int(g)

    pqmax = max(p, q)
    fc = 1.0 / (2.0 * pqmax)
    L = 2 * n * pqmax + 1
    h_firls = firls(L, [0, 2 * fc, 2 * fc, 1], [1, 1, 0, 0])
    h_kaiser = kaiser(L, beta)
    h = p * h_firls * h_kaiser

    Lhalf = (L - 1) / 2.0
    nz = int(np.floor(q - np.mod(Lhalf, q)))
    h = np.concatenate([np.zeros(nz), h])
    Lhalf = Lhalf + nz
    delay = int(np.floor(np.ceil(Lhalf) / q))

    Lx = cols.shape[0]
    Ly = int(np.ceil(Lx * p / q))
    nz1 = 0
    while np.ceil(((Lx - 1) * p + len(h) + nz1) / q) - delay < Ly:
        nz1 += 1
    h_padded = np.concatenate([h, np.zeros(nz1)])

    y_cols = np.zeros((Ly, cols.shape[1]))
    for c in range(cols.shape[1]):
        if p > 1:
            upsampled = np.zeros(Lx * p)
            upsampled[::p] = cols[:, c]
        else:
            upsampled = cols[:, c]
        filtered = lfilter(h_padded, [1.0], np.concatenate([upsampled, np.zeros(len(h_padded))]))
        yc = filtered[::q]
        yc = yc[delay:]
        yc = yc[:Ly]
        y_cols[:, c] = yc

    if is_row or x.ndim == 1:
        return y_cols.ravel(), h
    return y_cols, h


def save_case(name: str, x: np.ndarray, p: int, q: int, **kwargs) -> None:
    y, h = matlab_resample(x, p, q, **kwargs)
    case_dir = OUT_DIR / name
    case_dir.mkdir(parents=True, exist_ok=True)
    np.savetxt(case_dir / "x.csv", np.atleast_2d(x) if x.ndim > 1 and x.shape[0] > 1 else x, delimiter=",")
    np.savetxt(case_dir / "y.csv", np.atleast_2d(y) if y.ndim > 1 and y.shape[0] > 1 else y, delimiter=",")
    np.savetxt(case_dir / "h.csv", h, delimiter=",")
    meta = {
        "p": p,
        "q": q,
        "N": kwargs.get("n", 10),
        "beta": kwargs.get("beta", 5.0),
        "x_shape": list(np.atleast_1d(x).shape),
        "y_shape": list(np.atleast_1d(y).shape),
        "h_len": int(len(h)),
        "note": "Reference from independent Python reimplementation of MATLAB resample",
    }
    (case_dir / "meta.json").write_text(json.dumps(meta, indent=2) + "\n")
    print(f"wrote {case_dir}  x{tuple(x.shape)} -> y{tuple(np.atleast_1d(y).shape)}  h={len(h)}")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    rng = np.random.default_rng(0)

    # IPEM input path: 44100 -> 22050 (p=1, q=2)
    t = np.arange(800) / 44100.0
    sine = 0.5 * np.sin(2 * np.pi * 440.0 * t)
    save_case("sine_44100_to_22050", sine, 1, 2)

    # IPEM ANI decimation: p=1, q=4 on a multi-channel matrix
    ani = rng.normal(size=(200, 4)) * 0.1
    # store as channels x samples to match IPEM orientation after transpose in callers;
    # our shim treats matrices column-wise, so fixture uses samples x channels
    save_case("matrix_decimate_1_4", ani, 1, 4)

    # Impulse response alignment
    impulse = np.zeros(101)
    impulse[50] = 1.0
    save_case("impulse_p1_q2", impulse, 1, 2)

    # Upsample
    short = np.sin(2 * np.pi * np.linspace(0, 4, 50, endpoint=False))
    save_case("sine_upsample_2_1", short, 2, 1)

    # Non-trivial rational ratio
    save_case("sine_p3_q2", sine[:300], 3, 2)

    # Longer hihat-like noise burst at 44.1k -> 22.05k
    noise = rng.normal(size=16352) * 0.05
    save_case("noise_44100_to_22050", noise, 1, 2)

    print(f"Fixtures written under {OUT_DIR}")


if __name__ == "__main__":
    main()
