"""Generate original loopable synth cues; only Python's standard library is used."""
from pathlib import Path
import math
import random
import struct
import wave

ROOT = Path(__file__).resolve().parents[1] / 'assets/audio/music'
RATE = 22050

def render(name, bpm, roots, melody, seed):
    beat = 60.0 / bpm
    duration = beat * 32
    rng = random.Random(seed)
    out = bytearray()
    for frame in range(round(duration * RATE)):
        t = frame / RATE
        step = int(t / (beat / 2))
        bar = min(3, int(t / (beat * 8)))
        root = roots[bar]
        local = t % (beat / 2)
        freq = 440 * 2 ** ((root - 69) / 12)
        bass = math.sin(math.tau * freq * t) * math.exp(-local * 10) * .18
        note = root + 24 + melody[step % len(melody)]
        lead_hz = 440 * 2 ** ((note - 69) / 12)
        lead = (math.sin(math.tau * lead_hz * t) + .25 * math.sin(math.tau * 2 * lead_hz * t)) * math.exp(-local * 14) * .095
        kick_t = t % beat
        kick = math.sin(math.tau * (48 * kick_t + 3 * (1 - math.exp(-kick_t * 30)))) * math.exp(-kick_t * 23) * .23
        snare_t = (t + beat) % (beat * 2)
        noise = rng.uniform(-1, 1)
        snare = noise * math.exp(-snare_t * 38) * .16
        hat = noise * math.exp(-local * 140) * .065
        # A short edge fade avoids clicks without changing the musical grid.
        edge = min(1, t / .008, (duration - t) / .008)
        sample = max(-1, min(1, (bass + lead + kick + snare + hat) * edge))
        out.extend(struct.pack('<h', round(sample * 32767)))
    ROOT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(ROOT / f'{name}.wav'), 'wb') as wav:
        wav.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        wav.writeframes(out)

if __name__ == '__main__':
    render('coastal_assault', 132, [40, 43, 38, 45], [0, 7, 12, 10, 7, 3, 5, 7], 1)
    render('dust_convoy', 116, [38, 39, 43, 38], [0, 1, 7, 8, 7, 3, 1, 0], 2)
    render('foundry_pulse', 144, [36, 36, 39, 34], [0, 12, 7, 0, 10, 7, 3, 7], 3)
    render('boss_overdrive', 156, [40, 41, 38, 40], [0, 12, 0, 7, 1, 13, 7, 10], 4)
