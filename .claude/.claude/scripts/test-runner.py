#!/usr/bin/env python3
# .claude/hooks/smart-test-runner.py

import json
import sys
import subprocess

data = json.load(sys.stdin)
file_path = data.get('tool_input', {}).get('file_path', '')

# Determine what tests to run based on what changed
if 'src/' in file_path:
    if '.test.' in file_path:
        # Changed a test file - run just that test
        test_file = file_path.replace('src/', '').replace('.ts', '')
        subprocess.run(['npm', 'test', '--', test_file])
    else:
        # Changed source - run related tests
        test_pattern = file_path.replace('src/', '').replace('.ts', '*.test.ts')
        subprocess.run(['npm', 'test', '--', f'**/{test_pattern}'])
