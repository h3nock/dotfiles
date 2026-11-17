"""Run with: python3 -m unittest discover -s rex/tests -v"""
import base64
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest

CONFIG = Path(__file__).resolve().parents[1] / '.config/rex'
spec = importlib.util.spec_from_file_location('scrollback', CONFIG / 'scrollback.py')
scrollback = importlib.util.module_from_spec(spec)
spec.loader.exec_module(scrollback)


class CopyModeTests(unittest.TestCase):
    def test_replay_contains_only_text_and_colors(self):
        raw = b'\x1b[31mred\x1b[0m\r\n\x1b]52;c;ZXZpbA==\x07safe\x1b[2J\x1b]8;;https://example.com\x1b\\link\x1b]8;;\x1b\\'
        self.assertEqual(scrollback.display_text(raw), '\x1b[31mred\x1b[0m\nsafelink\n')

    @unittest.skipUnless(shutil.which('nvim'), 'Neovim required')
    def test_yanks(self):
        # Long rows exercise soft-wrap repair, including UTF-8 and selection in reverse.
        fixtures = [
            ('word', '\x1b[31mhello world\x1b[0m\n', 'gg0vey', 'hello'),
            ('line', 'hello world\n', 'ggyy', 'hello world\n'),
            ('wrapped', 'abcdefghij' * 6 + '\n', 'Vggy', 'abcdefghij' * 6 + '\n'),
            ('unicode', '你好 world ' * 8 + 'end\n', 'Vggy', '你好 world ' * 8 + 'end\n'),
            ('reverse', 'first\nsecond\n', 'Vky', 'first\nsecond\n'),
            ('rectangle', 'abcdef\nghijkl\n', 'gg0\x16jly', 'ab\ngh'),
        ]
        for name, text, keys, expected in fixtures:
            with self.subTest(name=name), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                page = root / 'page.vt'
                page.write_text(text)
                # Restrict the selection to actual output, excluding empty terminal rows.
                script = root / 'select.lua'
                script.write_text('vim.cmd.normal({ ' + json.dumps(keys).replace('\\u0016', '\\22') + ', bang = true })')
                env = {**os.environ, 'REX_COPY_SETTINGS': json.dumps({'file': str(page)})}
                result = subprocess.run([
                    'nvim', '--headless', '-u', str(CONFIG / 'copy_mode.lua'), '-i', 'NONE', '-n',
                    '-c', 'set columns=20 lines=10',
                    '-c', "autocmd User RexCopyLoaded lua vim.schedule(function() dofile(" + json.dumps(str(script)) + ") end)",
                ], env=env, capture_output=True, timeout=15)
                output = result.stdout + result.stderr
                self.assertEqual(result.returncode, 0, output.decode(errors='replace'))
                match = re.search(rb'\x1b]52;[^;]*;([A-Za-z0-9+/=]*)', output)
                self.assertIsNotNone(match, output.decode(errors='replace'))
                self.assertEqual(base64.b64decode(match[1]).decode(), expected)


if __name__ == '__main__':
    unittest.main()
