#!/usr/bin/env python3
"""Verify that every changed code hunk carries an `// ATCHG` marker.

Ported from the Atatus Flutter agent's `tools/verify_atchg.py`, which enforces the same
convention there. Every Atatus-specific modification to the forked dd sources must be
annotated with an `// ATCHG` comment so the Atatus delta stays reviewable against upstream.

Usage:
    tools/verify_atchg.py                 # check all local (unstaged + staged) changes
    tools/verify_atchg.py <file> [...]    # check only the given files
    tools/verify_atchg.py --base <ref>    # check the diff against a base revision

Intended for changes made *on top of* the Atatus baseline. Running it with `--base` against the
pre-rebrand history also reports the mechanical `dd` -> `Atatus` rename, which is documented
as a single class of change in CHANGE.md rather than annotated file by file.
"""
import argparse
import re
import subprocess
import sys

CODE_SUFFIXES = ('.swift', '.h', '.m', '.mm', '.c', '.cpp', '.kt', '.java', '.dart')
HUNK_RE = re.compile(r'@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@')


def collect_diff(base, target_files):
    cmd = ['git', 'diff', '-U1']
    if base:
        cmd.append(base)
    if target_files:
        cmd.extend(['--'] + target_files)
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print('Error: failed to run git diff.', file=sys.stderr)
        sys.exit(1)
    return result.stdout


def verify(diff):
    if not diff.strip():
        print('No changes detected in target files.')
        return True

    lines = diff.splitlines()
    current_file = None
    all_ok = True
    i = 0

    while i < len(lines):
        line = lines[i]
        if line.startswith('+++ b/'):
            current_file = line[6:]
        elif line.startswith('@@ ') and current_file:
            if HUNK_RE.match(line) and current_file.endswith(CODE_SUFFIXES):
                hunk = []
                i += 1
                while i < len(lines) and not lines[i].startswith('@@') and not lines[i].startswith('diff '):
                    hunk.append(lines[i])
                    i += 1
                i -= 1
                if not any('ATCHG' in hunk_line for hunk_line in hunk):
                    print(f"Warning: missing '// ATCHG' comment in file: {current_file}")
                    print('Hunk content:')
                    for hunk_line in hunk:
                        print(f'  {hunk_line}')
                    print('-' * 40)
                    all_ok = False
        i += 1

    if all_ok:
        print("Success: all changes contain '// ATCHG' comments.")
    return all_ok


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('files', nargs='*', help='Limit the check to these paths.')
    parser.add_argument('--base', help='Base revision to diff against (e.g. the fork point).')
    args = parser.parse_args()

    if not verify(collect_diff(args.base, args.files)):
        sys.exit(1)


if __name__ == '__main__':
    main()
