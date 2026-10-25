#coding=utf-8
import os
from urllib import parse


class Proxy:
    def getUrl(self, local=True):
        return os.environ.get('PILI_PROXY_BASE',
                              'http://127.0.0.1:0/proxy')

    def getPort(self):
        try:
            netloc = parse.urlsplit(self.getUrl(True)).netloc
            return int(netloc.rsplit(':', 1)[1])
        except Exception:
            return 0
