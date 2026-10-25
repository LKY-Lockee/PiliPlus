#coding=utf-8
#!/usr/bin/python
import json
import os
from urllib import parse

import requests
import urllib3

import crypto_protocol_dh  # noqa: F401
from pili_host.pycompat import load_module_from_path

urllib3.disable_warnings()

PLUGIN_DOWNLOAD_TIMEOUT = 20

gParam = {
    'SpiderList': {},
    'SpiderPath': {},
    'SpiderParam': {},
}


def createFile(file_path):
    if os.path.exists(file_path) is False:
        os.makedirs(file_path)


def _isRemote(url):
    return url.startswith('http://') or url.startswith('https://')


def _moduleName(path_or_url):
    return path_or_url.split('/')[-1].split('.')[0]


def redirectResponse(tUrl):
    rsp = requests.get(tUrl, allow_redirects=False, verify=False,
                       timeout=PLUGIN_DOWNLOAD_TIMEOUT)
    if 'Location' in rsp.headers:
        return redirectResponse(rsp.headers['Location'])
    return rsp


def downloadFile(name, url):
    rsp = redirectResponse(url)
    with open(name, 'wb') as f:
        f.write(rsp.content)


def downloadPlugin(basePath, url):
    createFile(basePath)
    if url.startswith('file://'):
        py_name = url.replace('file://', '')
    elif _isRemote(url):
        name = _moduleName(url)
        py_name = os.path.join(basePath, name + '.py')
        try:
            downloadFile(py_name, url)
        except Exception:
            print(f'{url} =======================================> error')
            return ''
    else:
        local = gParam['SpiderPath'].get(url)
        if local and os.path.exists(local):
            py_name = local
        else:
            return ''
    if not os.path.exists(py_name):
        return ''
    name = _moduleName(py_name)
    gParam['SpiderPath'][name] = py_name
    param_list = parse.parse_qs(parse.urlparse(url).query).get('extend')
    if param_list:
        gParam['SpiderParam'][name] = param_list[0]
    return py_name


def registerPluginAlias(alias, fileName):
    if alias is None or alias == '':
        return
    name = _moduleName(fileName)
    gParam['SpiderPath'][alias] = fileName
    param = gParam['SpiderParam'].get(name, '')
    if param:
        gParam['SpiderParam'][alias] = param


def loadFromDisk(fileName):
    name = _moduleName(fileName)
    sp = gParam['SpiderList'].get(name)
    if sp is not None:
        return sp
    module = load_module_from_path(name, fileName)
    sp = module.Spider()
    gParam['SpiderList'][name] = sp
    return sp


def str2json(content):
    return json.loads(content)


def getDependenceList(ru):
    get_dependence = getattr(ru, 'getDependence', None)
    if callable(get_dependence):
        result = get_dependence()
        return result if result is not None else []
    return []


def setExtendInfo(ru, extend):
    setter = getattr(ru, 'setExtendInfo', None)
    if callable(setter):
        setter(extend)
    else:
        setattr(ru, 'extend', extend)


def getDependence(ru):
    return getDependenceList(ru)


def getName(ru):
    return ru.getName()


def init(ru, extend=""):
    spo_list = []
    for key in getDependenceList(ru):
        sp = gParam['SpiderList'].get(key)
        if sp is None:
            path = gParam['SpiderPath'].get(key)
            if path and os.path.exists(path):
                sp = loadFromDisk(path)
        if sp is not None:
            setExtendInfo(sp, gParam['SpiderParam'].get(key, ''))
            spo_list.append(sp)
    setExtendInfo(ru, extend)
    ru.init(spo_list if len(spo_list) > 0 else extend)


def homeContent(ru, flt):
    return json.dumps(ru.homeContent(flt), ensure_ascii=False)


def homeVideoContent(ru):
    return json.dumps(ru.homeVideoContent(), ensure_ascii=False)


def categoryContent(ru, tid, pg, flt, extend):
    return json.dumps(ru.categoryContent(tid, pg, flt, str2json(extend)),
                      ensure_ascii=False)


def detailContent(ru, array):
    return json.dumps(ru.detailContent(str2json(array)), ensure_ascii=False)


def playerContent(ru, flag, id_, vip_flags):
    return json.dumps(ru.playerContent(flag, id_, str2json(vip_flags)),
                      ensure_ascii=False)


def liveContent(ru, url):
    return ru.liveContent(url)


def searchContent(ru, key, quick):
    return json.dumps(ru.searchContent(key, quick), ensure_ascii=False)


def localProxy(ru, param):
    if isinstance(param, str):
        param = str2json(param)
    return ru.localProxy(param)


def destroy(ru):
    ru.destroy()


def run():
    pass


if __name__ == '__main__':
    run()
