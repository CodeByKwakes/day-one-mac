#!/usr/bin/env python3
"""Read JSONC without evaluating it; reject duplicate keys and unsafe approvals."""
import json
import re
import sys


def read_jsonc(text):
    # Match strings first so comment-looking text inside a string is preserved.
    tokens = re.compile(r'"(?:[^"\\\x00-\x1f]|\\.)*"|//[^\r\n]*|/\*[\s\S]*?\*/')
    text = tokens.sub(lambda m: m[0] if m[0].startswith('"') else ' ', text)
    # Remove trailing commas only outside strings. The JSON decoder below
    # rejects malformed/unterminated strings, comments and non-JSON literals.
    text = re.sub(r'"(?:[^"\\\x00-\x1f]|\\.)*"|,\s*(?=[}\]])',
                  lambda m: m[0] if m[0].startswith('"') else '', text)

    def unique(pairs):
        obj = {}
        for key, value in pairs:
            if key in obj:
                raise ValueError('duplicate key')
            obj[key] = value
        return obj

    def invalid_constant(_):
        raise ValueError('non-JSON constant')

    return json.loads(text, object_pairs_hook=unique, parse_constant=invalid_constant)


def main():
    try:
        with open(sys.argv[1], encoding='utf-8-sig') as source:
            settings = read_jsonc(source.read())
        if not isinstance(settings, dict):
            raise ValueError('expected object')
        for key in ('chat.tools.global.autoApprove', 'chat.tools.terminal.enableAutoApprove'):
            if settings.get(key) is not False:
                raise ValueError('approval setting missing or enabled')
    except (OSError, ValueError, IndexError):
        # Parser exceptions can contain the input. Keep settings out of logs.
        print('REVIEW: invalid/ambiguous JSONC or missing/unsafe approval settings.', file=sys.stderr)
        return 1
    print('PASS: default user settings file; profiles, workspace settings and policy need separate review.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
