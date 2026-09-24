"""Run on the target desk: python3 nvim/tests/startup_bench.py --runs 5.
Measures headless config startup; excludes first-use plugin/LSP latency.
Uses the installed plugins/cache; never clears caches or installs tools itself.
"""
import argparse, json, os, pathlib, re, shutil, statistics, subprocess, tempfile
parser = argparse.ArgumentParser()
parser.add_argument('--runs', type=int, default=5)
args = parser.parse_args()
if not 1 <= args.runs <= 30:
    parser.error('--runs must be between 1 and 30')
exe = os.environ.get('NVIM_BIN') or shutil.which('nvim')
if not exe:
    parser.error('set NVIM_BIN or install Neovim')
root = pathlib.Path(__file__).resolve().parents[2]
env = dict(os.environ, XDG_CONFIG_HOME=str(root))
samples = []
with tempfile.TemporaryDirectory() as tmp:
    for i in range(args.runs):
        log = pathlib.Path(tmp) / str(i)
        run = subprocess.run([exe, '--headless', '--startuptime', str(log), '+qa!'],
                             env=env, cwd=root, capture_output=True, text=True, timeout=30)
        if run.returncode:
            raise SystemExit(run.stderr)
        times = [float(m[1]) for line in log.read_text().splitlines()
                 if (m := re.match(r'^(\d+\.\d+).*NVIM STARTED', line))]
        if not times:
            raise SystemExit('No startup marker; inspect Neovim startup manually')
        samples.append(times[-1])
print(json.dumps({'scope': 'headless startup, existing cache; not LSP or UI latency',
                  'nvim': subprocess.check_output([exe, '--version'], text=True).splitlines()[0],
                  'first_ms': samples[0], 'runs_ms': samples,
                  'median_ms': statistics.median(samples)}, indent=2))
