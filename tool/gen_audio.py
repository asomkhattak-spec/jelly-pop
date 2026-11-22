#!/usr/bin/env python3
"""Generate all Jelly Pop! sound effects as 16-bit mono WAV files.

Pure stdlib synthesis — no samples, no licensing questions. Run:
    python3 tool/gen_audio.py
Outputs to assets/audio/*.wav
"""
import math
import os
import struct
import wave

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")


def write_wav(name, samples):
    path = os.path.join(OUT, name + ".wav")
    peak = max(abs(s) for s in samples) or 1.0
    norm = 0.85 / peak if peak > 0.85 else 1.0
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = bytearray()
        for s in samples:
            v = int(max(-1.0, min(1.0, s * norm)) * 32767)
            frames += struct.pack("<h", v)
        w.writeframes(bytes(frames))
    print(f"  {name}.wav  ({len(samples)/SR:.2f}s)")


def env(i, n, attack=0.005, release=None):
    t = i / SR
    total = n / SR
    rel = release if release is not None else total * 0.6
    a = min(1.0, t / attack)
    r = min(1.0, max(0.0, (total - t) / rel))
    return a * r


def tone(freq_start, freq_end, dur, shape="sine", harm=0.0):
    n = int(dur * SR)
    out = []
    phase = 0.0
    for i in range(n):
        k = i / n
        f = freq_start + (freq_end - freq_start) * k
        phase += 2 * math.pi * f / SR
        s = math.sin(phase)
        if shape == "square":
            s = 1.0 if s >= 0 else -1.0
            s *= 0.5
        elif shape == "tri":
            s = 2 / math.pi * math.asin(math.sin(phase))
        if harm:
            s += harm * math.sin(2 * phase)
        out.append(s * env(i, n))
    return out


def mix(*layers):
    n = max(len(x) for x in layers)
    out = [0.0] * n
    for layer in layers:
        for i, s in enumerate(layer):
            out[i] += s
    return out


def delay(samples, sec):
    pad = int(sec * SR)
    return [0.0] * pad + samples


def main():
    os.makedirs(OUT, exist_ok=True)
    print("Generating Jelly Pop! audio...")

    # Pop: bright bloop, pitch rises with combo level (we ship 6 variants).
    for idx in range(6):
        base = 520 + idx * 90
        write_wav(f"pop{idx}", tone(base, base * 1.9, 0.10, harm=0.25))

    # Golden jelly: sparkly two-note chime.
    write_wav("golden", mix(
        tone(880, 1320, 0.22, "tri"),
        delay(tone(1320, 1760, 0.25, "tri"), 0.07),
    ))

    # Star pickup: rising major arpeggio.
    write_wav("star", mix(
        tone(660, 660, 0.09, "tri"),
        delay(tone(830, 830, 0.09, "tri"), 0.07),
        delay(tone(990, 1100, 0.16, "tri"), 0.14),
    ))

    # Bomb: low thud + noise burst.
    n = int(0.35 * SR)
    noise = []
    seed = 12345
    for i in range(n):
        seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
        white = (seed / 0x7FFFFFFF) * 2 - 1
        noise.append(white * env(i, n, attack=0.001, release=0.3) * 0.5)
    write_wav("bomb", mix(tone(180, 55, 0.35, harm=0.4), noise))

    # Fever start: fast ascending sweep + chord.
    write_wav("fever", mix(
        tone(300, 1500, 0.4, "saw" if False else "tri", harm=0.3),
        delay(tone(523, 523, 0.3, "tri"), 0.15),
        delay(tone(659, 659, 0.3, "tri"), 0.15),
        delay(tone(784, 1046, 0.35, "tri"), 0.15),
    ))

    # Round over: friendly descending finish.
    write_wav("over", mix(
        tone(784, 784, 0.14, "tri"),
        delay(tone(659, 659, 0.14, "tri"), 0.13),
        delay(tone(523, 523, 0.30, "tri"), 0.26),
    ))

    # New record fanfare.
    write_wav("record", mix(
        tone(523, 523, 0.11, "tri"),
        delay(tone(659, 659, 0.11, "tri"), 0.10),
        delay(tone(784, 784, 0.11, "tri"), 0.20),
        delay(tone(1046, 1046, 0.40, "tri", harm=0.2), 0.30),
    ))

    # UI tap.
    write_wav("tap", tone(700, 900, 0.06, harm=0.15))

    # Countdown tick + go.
    write_wav("tick", tone(440, 440, 0.08, "square"))
    write_wav("go", tone(880, 1200, 0.25, "tri", harm=0.2))

    # Heart lost uses bomb; purchase success reuses star.
    print("Done.")


if __name__ == "__main__":
    main()
