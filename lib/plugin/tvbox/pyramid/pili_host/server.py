#coding=utf-8
import base64
import json
import os
import secrets
import threading
import traceback
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib import parse

import app
from pili_host.cache import PY_CACHE


class PythonHostServer(ThreadingHTTPServer):
    daemon_threads = True
    allow_reuse_address = False

    def __init__(self, cache_dir):
        self.pyToken = secrets.token_hex(16)
        self.pyCacheDir = cache_dir
        self.pySpiders = {}
        self.pyLocks = {}
        self.pyEnsureLock = threading.Lock()
        super().__init__(('127.0.0.1', 0), PythonHostHandler)

    def spider_lock(self, site_key):
        lock = self.pyLocks.get(site_key)
        if lock is None:
            lock = threading.Lock()
            self.pyLocks[site_key] = lock
        return lock


class PythonHostHandler(BaseHTTPRequestHandler):
    protocol_version = 'HTTP/1.1'
    server_version = 'PiliPythonHost/1.0'

    def log_message(self, fmt, *args):
        pass

    def _send_json(self, obj, status=200):
        body = json.dumps(obj, ensure_ascii=False).encode('utf-8')
        self.send_response(status)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _read_body(self):
        length = int(self.headers.get('Content-Length') or 0)
        if length <= 0:
            return {}
        raw = self.rfile.read(length)
        if not raw:
            return {}
        decoded = json.loads(raw.decode('utf-8'))
        return decoded if isinstance(decoded, dict) else {}

    def do_GET(self):
        if self.path.split('?')[0] == '/health':
            self._send_json({'ok': True})
        else:
            self._send_json({'ok': False, 'error': 'not found'}, status=404)

    def do_POST(self):
        path = self.path.split('?')[0]
        try:
            body = self._read_body()
        except Exception as e:
            self._send_json({'ok': False, 'error': f'bad request: {e}'},
                            status=400)
            return
        if body.get('token') != self.server.pyToken:
            self._send_json({'ok': False, 'error': 'forbidden'}, status=403)
            return
        handler = {
            '/health': self._handle_health,
            '/ensure': self._handle_ensure,
            '/call': self._handle_call,
            '/proxy': self._handle_proxy,
            '/cache': self._handle_cache,
            '/clear': self._handle_clear,
        }.get(path)
        if handler is None:
            self._send_json({'ok': False, 'error': 'not found'}, status=404)
            return
        try:
            self._send_json(handler(body))
        except Exception as e:
            traceback.print_exc()
            self._send_json({'ok': False, 'error': str(e)})

    def _handle_health(self, body):
        return {'ok': True}

    def _handle_ensure(self, body):
        server = self.server
        site_key = str(body.get('siteKey') or '')
        api = str(body.get('api') or '')
        ext = body.get('ext') or ''
        if not isinstance(ext, str):
            ext = json.dumps(ext, ensure_ascii=False)
        if not ext:
            extend = parse.parse_qs(
                parse.urlparse(api).query, keep_blank_values=True).get('extend')
            if extend:
                ext = extend[0]
        if not site_key or not api:
            raise Exception('ensure: siteKey/api required')
        with server.pyEnsureLock:
            if site_key in server.pySpiders:
                return {'ok': True}
            path = app.downloadPlugin(server.pyCacheDir, api)
            if not path:
                raise Exception(f'插件下载失败: {api}')
            sp = app.loadFromDisk(path)
            try:
                sp.siteKey = site_key
            except Exception:
                pass
            for dep in app.getDependence(sp):
                dep = str(dep)
                if not dep:
                    continue
                dep_url = _resolveDependenceUrl(api, dep)
                if not dep_url:
                    raise Exception(f'依赖插件不存在: {dep}')
                dep_path = app.downloadPlugin(server.pyCacheDir, dep_url)
                if not dep_path:
                    raise Exception(f'依赖插件加载失败: {dep}')
                app.registerPluginAlias(dep, dep_path)
            app.init(sp, ext)
            server.pySpiders[site_key] = sp
            return {'ok': True}

    def _handle_call(self, body):
        server = self.server
        site_key = str(body.get('siteKey') or '')
        method = str(body.get('method') or '')
        args = body.get('args')
        if not isinstance(args, list):
            args = []
        sp = server.pySpiders.get(site_key)
        if sp is None:
            raise Exception(f'spider not loaded: {site_key}')
        with server.spider_lock(site_key):
            data = self._invoke(sp, site_key, method, args)
        return {'ok': True, 'data': data}

    @staticmethod
    def _invoke(sp, site_key, method, args):
        if method == 'home':
            return app.homeContent(sp, bool(args[0]) if args else True)
        if method == 'homeVod':
            return app.homeVideoContent(sp)
        if method == 'category':
            extend = args[3] if len(args) > 3 else {}
            if not isinstance(extend, str):
                extend = json.dumps(extend, ensure_ascii=False)
            return app.categoryContent(
                sp,
                str(args[0]) if len(args) > 0 else '',
                str(args[1]) if len(args) > 1 else '1',
                bool(args[2]) if len(args) > 2 else True,
                extend,
            )
        if method == 'detail':
            ids = args[0] if args else []
            if not isinstance(ids, str):
                ids = json.dumps(ids, ensure_ascii=False)
            return app.detailContent(sp, ids)
        if method == 'search':
            return app.searchContent(
                sp,
                str(args[0]) if args else '',
                bool(args[1]) if len(args) > 1 else False,
            )
        if method == 'play':
            vip_flags = args[2] if len(args) > 2 else []
            if not isinstance(vip_flags, str):
                vip_flags = json.dumps(vip_flags, ensure_ascii=False)
            data = app.playerContent(
                sp,
                str(args[0]) if args else '',
                str(args[1]) if len(args) > 1 else '',
                vip_flags,
            )
            return _replaceLocalUrl(data, site_key)
        raise Exception(f'unknown method: {method}')

    def _handle_proxy(self, body):
        server = self.server
        site_key = str(body.get('siteKey') or '')
        params = body.get('params') or {}
        sp = server.pySpiders.get(site_key)
        if sp is None:
            raise Exception(f'spider not loaded: {site_key}')
        with server.spider_lock(site_key):
            result = app.localProxy(sp, params)
        if result is None:
            return {'ok': True, 'data': None}
        if not isinstance(result, (list, tuple)):
            raise Exception('proxy: invalid result')
        result = list(result)
        if len(result) < 3:
            raise Exception('proxy: invalid result')
        content = result[2]
        if isinstance(content, (bytes, bytearray)):
            result[2] = base64.b64encode(bytes(content)).decode('utf-8')
            while len(result) < 5:
                result.append(None)
            result[4] = 1
        elif len(result) > 4 and result[4] == 1 and isinstance(content, str) \
                and 'base64,' in content:
            result[2] = content.split('base64,', 1)[1]
        if len(result) > 3 and isinstance(result[3], dict):
            result[3] = {str(k): str(v) for k, v in result[3].items()}
        return {'ok': True, 'data': result}

    def _handle_cache(self, body):
        action = str(body.get('do') or '')
        key = str(body.get('key') or '')
        if not key:
            raise Exception('cache: key required')
        if action == 'get':
            return {'ok': True, 'data': PY_CACHE.get(key)}
        if action == 'set':
            value = body.get('value')
            if isinstance(value, (dict, list)):
                value = json.dumps(value, ensure_ascii=False)
            PY_CACHE.set(key, str(value or ''))
            return {'ok': True, 'data': 'succeed'}
        if action == 'del':
            PY_CACHE.delete(key)
            return {'ok': True, 'data': 'succeed'}
        raise Exception(f'cache: unknown action {action}')

    def _handle_clear(self, body):
        server = self.server
        with server.pyEnsureLock:
            for sp in server.pySpiders.values():
                try:
                    sp.destroy()
                except Exception:
                    pass
            server.pySpiders.clear()
            server.pyLocks.clear()
            app.gParam['SpiderList'].clear()
            app.gParam['SpiderPath'].clear()
            app.gParam['SpiderParam'].clear()
        return {'ok': True}


def _resolveDependenceUrl(base_url, dep):
    if not dep:
        return ''
    if not dep.endswith('.py'):
        dep = dep + '.py'
    try:
        return parse.urljoin(base_url, dep)
    except Exception:
        return ''


def _proxyPlayUrl(site_key):
    base = os.environ.get('PILI_PROXY_BASE', '')
    if not base:
        return ''
    return f'{base}?do=py&siteKey={parse.quote(str(site_key))}'


def _replaceLocalUrl(content, site_key):
    magic = 'http://127.0.0.1:UndCover/proxy'
    url = _proxyPlayUrl(site_key)
    if not url:
        return content
    return content.replace(magic, url)


def create_server(cache_dir=''):
    if cache_dir and not os.path.exists(cache_dir):
        os.makedirs(cache_dir, exist_ok=True)
    return PythonHostServer(cache_dir=cache_dir)
