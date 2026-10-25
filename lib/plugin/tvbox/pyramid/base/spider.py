#coding=utf-8
import os
import re
import json
import time
import requests
from lxml import etree
from urllib import parse
from abc import abstractmethod, ABCMeta

from base.localProxy import Proxy
from pili_host.cache import PY_CACHE
from pili_host.pycompat import load_module_from_path


def _plugin_candidate_paths(name):
    paths = []
    cache_dir = os.environ.get('PILI_PY_CACHE', '')
    if cache_dir:
        paths.append(os.path.join(cache_dir, f'{name}.py'))
    app_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    paths.append(os.path.join(app_dir, f'{name}.py'))
    return paths


class Spider(metaclass=ABCMeta):
    _instance = None

    def __init__(self):
        self.extend = ''

    def __new__(cls, *args, **kwargs):
        if cls._instance:
            return cls._instance
        else:
            cls._instance = super().__new__(cls)
            return cls._instance

    @abstractmethod
    def init(self, extend=""):
        pass

    def homeContent(self, filter):
        pass

    def homeVideoContent(self):
        pass

    def categoryContent(self, tid, pg, filter, extend):
        pass

    def detailContent(self, ids):
        pass

    def searchContent(self, key, quick, pg="1"):
        pass

    def playerContent(self, flag, id, vipFlags):
        pass

    def liveContent(self, url):
        pass

    def localProxy(self, param):
        pass

    def isVideoFormat(self, url):
        pass

    def manualVideoCheck(self):
        pass

    def action(self, action):
        pass

    def destroy(self):
        pass

    def getName(self):
        pass

    def getDependence(self):
        return []

    def setExtendInfo(self, extend):
        self.extend = extend

    def loadSpider(self, name):
        return self.loadModule(name).Spider()

    def loadModule(self, name, fileName=None):
        path = fileName
        if not path:
            candidates = _plugin_candidate_paths(name)
            path = next((c for c in candidates if os.path.exists(c)),
                        candidates[0])
        return load_module_from_path(name, path)

    def regStr(self, src, reg=None, group=1):
        if reg is None:
            return ''
        match = None
        try:
            match = re.search(reg, src)
        except Exception:
            pass
        if not match:
            try:
                match = re.search(src, reg)
            except Exception:
                pass
        return match.group(group) if match else ''

    def removeHtmlTags(self, src):
        clean = re.compile('<.*?>')
        return re.sub(clean, '', src)

    def cleanText(self, src):
        clean = re.sub('[\U0001F600-\U0001F64F\U0001F300-\U0001F5FF\U0001F680-\U0001F6FF\U0001F1E0-\U0001F1FF]', '',
                       src)
        return clean

    def fetch(self, url, headers=None, cookies=None, params=None, timeout=15, verify=True, stream=False,
              allow_redirects=True):
        rsp = requests.get(url, params=params, cookies=cookies, headers=headers, timeout=timeout, verify=verify,
                           stream=stream, allow_redirects=allow_redirects)
        rsp.encoding = 'utf-8'
        return rsp

    def _clean_header_value(self, value):
        cleaned = value.strip()
        if cleaned.startswith("<!DOCTYPE html>"):
            cleaned = "DefaultValue"
        return cleaned

    def post(self, url, data=None, headers=None, cookies=None, params=None, json=None, timeout=15, verify=True, stream=False, allow_redirects=True):
        if headers:
            headers = {k: self._clean_header_value(v) for k, v in headers.items()}

        rsp = requests.post(url, params=params, data=data, json=json, cookies=cookies, headers=headers, timeout=timeout, verify=verify,
                            stream=stream, allow_redirects=allow_redirects)
        rsp.encoding = 'utf-8'
        return rsp

    def postJson(self, url, json, headers=None, cookies=None):
        rsp = requests.post(url, json=json, headers=headers, cookies=cookies)
        rsp.encoding = 'utf-8'
        return rsp

    def html(self, content):
        return etree.HTML(content)

    def xpText(self, root, expr):
        ele = root.xpath(expr)
        if len(ele) == 0:
            return ''
        else:
            return ele[0]

    def str2json(self, content):
        return json.loads(content)

    def json2str(self, content):
        return json.dumps(content, ensure_ascii=False)

    def getProxyUrl(self, local=True):
        url = Proxy.getUrl(self, local)
        site_key = getattr(self, 'siteKey', '')
        if site_key:
            return f'{url}?do=py&siteKey={parse.quote(str(site_key))}'
        return f'{url}?do=py'

    def log(self, msg):
        if isinstance(msg, dict) or isinstance(msg, list):
            print(json.dumps(msg, ensure_ascii=False))
        else:
            print(f'{msg}')

    def getCache(self, key):
        value = PY_CACHE.get(key)
        if not value:
            return None
        if value.startswith('{') and value.endswith('}') or value.startswith('[') and value.endswith(']'):
            try:
                value = json.loads(value)
            except Exception:
                return value
            if type(value) == dict:
                if 'expiresAt' not in value or value['expiresAt'] >= int(time.time()):
                    return value
                else:
                    self.delCache(key)
                    return None
        return value

    def setCache(self, key, value):
        try:
            if type(value) in [int, float]:
                value = str(value)
            if not value:
                return 'failed'
            if type(value) == dict or type(value) == list:
                value = json.dumps(value, ensure_ascii=False)
            PY_CACHE.set(key, str(value))
            return 'succeed'
        except Exception:
            return 'failed'

    def delCache(self, key):
        try:
            PY_CACHE.delete(key)
            return 'succeed'
        except Exception:
            return 'failed'
