#coding=utf-8
#!/usr/bin/python
import json
import os
import sys

sys.dont_write_bytecode = True

_APP_DIR = os.environ.get('PILI_PY_APP_DIR', '')
if not _APP_DIR:
    try:
        _APP_DIR = os.path.dirname(os.path.abspath(__file__))
    except NameError:
        pass
if _APP_DIR and os.path.isdir(_APP_DIR) and _APP_DIR not in sys.path:
    sys.path.insert(0, _APP_DIR)

from pili_host.server import create_server  # noqa: E402


def main():
    host_file = os.environ.get('PILI_PY_HOST_FILE', '')
    cache_dir = os.environ.get('PILI_PY_CACHE', '')
    server = create_server(cache_dir=cache_dir)
    port = server.server_address[1]
    if host_file:
        info = json.dumps({'port': port, 'token': server.pyToken})
        tmp_file = host_file + '.tmp'
        with open(tmp_file, 'w', encoding='utf-8') as f:
            f.write(info)
        os.replace(tmp_file, host_file)
    server.serve_forever()


if __name__ == '__main__':
    main()
