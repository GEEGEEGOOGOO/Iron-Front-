"""Run headless Godot regressions with isolated saves and bounded execution."""
import argparse
import json
from pathlib import Path
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--godot', default='godot')
parser.add_argument('--timeout', type=int, default=90)
args = parser.parse_args()
results = []
log_dir = ROOT / 'test-results'
log_dir.mkdir(exist_ok=True)

def execute(name, command, marker=None):
    started = time.monotonic()
    try:
        proc = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, timeout=args.timeout)
        output = proc.stdout + proc.stderr
        ok = proc.returncode == 0 and not any(token in output for token in ['SCRIPT ERROR:', 'ERROR:', 'REGRESSION FAIL'])
        if marker:
            ok = ok and marker in output
        code = proc.returncode
    except subprocess.TimeoutExpired as error:
        output = 'TIMEOUT\n' + str(error.stdout or '') + str(error.stderr or '')
        ok, code = False, -1
    (log_dir / f'{name}.log').write_text(output)
    results.append(dict(test=name, passed=ok, exit_code=code, seconds=round(time.monotonic()-started, 2)))
    print(f'{"PASS" if ok else "FAIL"} {name} ({results[-1]["seconds"]}s)', flush=True)
    return ok

if execute('import', [args.godot, '--headless', '--path', str(ROOT), '--editor', '--quit']):
    with tempfile.TemporaryDirectory(prefix='iron-front-tests-') as tmp:
        for scene in sorted((ROOT / 'tests').glob('*.tscn')):
            marker = 'SMOKE PASS' if scene.stem == 'smoke' else scene.stem.replace('_', ' ').upper() + ' PASS'
            execute(scene.stem, [args.godot, '--headless', '--path', str(ROOT), str(scene), '--', '--save-path=' + str(Path(tmp) / (scene.stem + '.json'))], marker)
(log_dir / 'summary.json').write_text(json.dumps(results, indent=2) + '\n')
raise SystemExit(0 if results and all(r['passed'] for r in results) else 1)
