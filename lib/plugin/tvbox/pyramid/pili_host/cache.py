#coding=utf-8
import threading
import time


class PyCache:
    def __init__(self):
        self._data = {}
        self._lock = threading.Lock()

    def get(self, key):
        with self._lock:
            item = self._data.get(key)
            if item is None:
                return None
            value, expires = item
            if expires is not None and expires < time.time():
                del self._data[key]
                return None
            return value

    def set(self, key, value, ttl=None):
        if not isinstance(value, str):
            return
        with self._lock:
            expires = time.time() + ttl if ttl else None
            self._data[key] = (value, expires)

    def delete(self, key):
        with self._lock:
            self._data.pop(key, None)

    def clear(self):
        with self._lock:
            self._data.clear()


PY_CACHE = PyCache()
