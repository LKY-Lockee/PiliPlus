import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

/// com.github.catvod.crawler.js.HtmlParser.Painfo
class _Painfo {
  /// com.github.catvod.crawler.js.HtmlParser.Painfo.nparse_rule
  String rule;

  /// com.github.catvod.crawler.js.HtmlParser.Painfo.nparse_index
  int? eqIndex;

  /// com.github.catvod.crawler.js.HtmlParser.Painfo.excludes
  List<String>? excludes;

  _Painfo(this.rule);
}

sealed class _SelToken {}

class _CssFrag extends _SelToken {
  final String text;

  _CssFrag(this.text);
}

class _Pseudo extends _SelToken {
  final String type;
  final String? arg;

  _Pseudo(this.type, this.arg);
}

/// com.github.catvod.crawler.js.HtmlParser
class HtmlParser {
  /// com.github.catvod.crawler.js.HtmlParser.p
  static final _styleUrlRe = RegExp(
    r'url\((.*?)\)',
    dotAll: true,
    multiLine: true,
  );

  static final _quoteRe = RegExp('^[\'|"](.*)[\'|"]\$');

  /// com.github.catvod.crawler.js.HtmlParser.NOADD_INDEX
  static final _noAddIndexRe = RegExp(r':eq|:lt|:gt|:first|:last|^body$|^#');

  /// com.github.catvod.crawler.js.HtmlParser.URLJOIN_ATTR
  static final _urlJoinAttrRe = RegExp(
    r'(url|src|href|-original|-src|-play|-url|style)$',
    caseSensitive: false,
  );

  /// com.github.catvod.crawler.js.HtmlParser.SPECIAL_URL
  static final _specialUrlRe = RegExp(
    r'^(ftp|magnet|thunder|ws):',
    caseSensitive: false,
  );

  static final _pseudoNameRe = RegExp(r'[A-Za-z][A-Za-z0-9_-]*');

  /// com.github.catvod.crawler.js.HtmlParser.pdfh_doc
  static final _cache = <String, Document>{};

  static const _jsoupPseudos = {
    'eq',
    'lt',
    'gt',
    'first',
    'last',
    'has',
    'contains',
  };

  static const _blockTags = {
    'html',
    'head',
    'body',
    'frameset',
    'script',
    'noscript',
    'style',
    'meta',
    'link',
    'title',
    'frame',
    'noframes',
    'section',
    'nav',
    'aside',
    'hgroup',
    'header',
    'footer',
    'p',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'ul',
    'ol',
    'pre',
    'div',
    'blockquote',
    'hr',
    'address',
    'figure',
    'figcaption',
    'form',
    'fieldset',
    'ins',
    'del',
    'dl',
    'dt',
    'dd',
    'li',
    'table',
    'caption',
    'thead',
    'tfoot',
    'tbody',
    'colgroup',
    'col',
    'tr',
    'th',
    'td',
    'video',
    'audio',
    'canvas',
    'details',
    'menu',
    'plaintext',
    'template',
    'article',
    'main',
    'svg',
    'math',
  };

  static const _cacheLimit = 4;

  HtmlParser._();

  static Document _parseDoc(String html) {
    final cached = _cache[html];
    if (cached != null) return cached;
    final doc = html_parser.parse(html);
    if (_cache.length >= _cacheLimit) {
      _cache.remove(_cache.keys.first);
    }
    _cache[html] = doc;
    return doc;
  }

  static bool _isActuallyWhitespace(int c) =>
      c == 0x20 ||
      c == 0x09 ||
      c == 0x0A ||
      c == 0x0C ||
      c == 0x0D ||
      c == 0xA0;

  static String _elementText(Element? root) {
    if (root == null) return '';
    final buf = <int>[];
    bool lastWhitespace() => buf.isNotEmpty && _isActuallyWhitespace(buf.last);

    void walk(Node node, bool isRoot) {
      if (node is Text) {
        var lastWasWhite = lastWhitespace();
        for (final rune in node.data.runes) {
          if (_isActuallyWhitespace(rune)) {
            if (lastWasWhite) continue;
            buf.add(0x20);
            lastWasWhite = true;
          } else {
            buf.add(rune);
            lastWasWhite = false;
          }
        }
      } else if (node is Element) {
        final name = node.localName ?? '';
        if (name == 'script' || name == 'style') return;
        if (!isRoot &&
            buf.isNotEmpty &&
            (_blockTags.contains(name) || name == 'br') &&
            !lastWhitespace()) {
          buf.add(0x20);
        }
        for (final child in node.nodes) {
          walk(child, false);
        }
      }
    }

    walk(root, true);
    return String.fromCharCodes(buf).trim();
  }

  static List<String> _splitTrimTrailing(String input, String sep) {
    final parts = input.split(sep);
    var end = parts.length;
    while (end > 1 && parts[end - 1].isEmpty) {
      end--;
    }
    return parts.sublist(0, end);
  }

  static String _lastToken(String seg) {
    final pss = seg.split(' ');
    var i = pss.length - 1;
    while (i >= 0 && pss[i].isEmpty) {
      i--;
    }
    return i >= 0 ? pss[i] : '';
  }

  /// com.github.catvod.crawler.js.HtmlParser.parseHikerToJq
  static String _hikerToJq(String parse, bool first) {
    if (parse.contains('&&')) {
      final parses = _splitTrimTrailing(parse, '&&');
      final newParses = <String>[];
      for (var i = 0; i < parses.length; i++) {
        final seg = parses[i];
        final ps = _lastToken(seg);
        if (!_noAddIndexRe.hasMatch(ps)) {
          if (!first && i >= parses.length - 1) {
            newParses.add(seg);
          } else {
            newParses.add('$seg:eq(0)');
          }
        } else {
          newParses.add(seg);
        }
      }
      return newParses.join(' ');
    }
    final ps = _lastToken(parse);
    if (!_noAddIndexRe.hasMatch(ps) && first) {
      parse = '$parse:eq(0)';
    }
    return parse;
  }

  /// com.github.catvod.crawler.js.HtmlParser.getParseInfo
  static _Painfo _getParseInfo(String nparse) {
    final info = _Painfo(nparse);
    if (nparse.contains(':eq')) {
      final parts = nparse.split(':');
      info.rule = parts[0];
      var pos = parts.length > 1 ? parts[1] : '';
      if (info.rule.contains('--')) {
        final rules = info.rule.split('--');
        info
          ..excludes = rules.sublist(1)
          ..rule = rules[0];
      } else if (pos.contains('--')) {
        final rules = pos.split('--');
        info.excludes = rules.sublist(1);
        pos = rules[0];
      }
      info.eqIndex =
          int.tryParse(pos.replaceAll('eq(', '').replaceAll(')', '')) ?? 0;
    } else if (nparse.contains('--')) {
      final rules = nparse.split('--');
      info
        ..excludes = rules.sublist(1)
        ..rule = rules[0];
    }
    return info;
  }

  /// com.github.catvod.crawler.js.HtmlParser.parseOneRule
  static List<Element> _parseOneRule(
    Document doc,
    String nparse,
    List<Element> ret,
  ) {
    final info = _getParseInfo(nparse);
    var result = _applySelectorPipeline(doc, info.rule, ret);
    if (info.eqIndex != null) {
      var idx = info.eqIndex!;
      if (idx < 0) idx = result.length + idx;
      result = (idx >= 0 && idx < result.length) ? [result[idx]] : <Element>[];
    }
    if (info.excludes != null && result.isNotEmpty) {
      result = [for (final e in result) e.clone(true)];
      for (final ex in info.excludes!) {
        if (ex.isEmpty) continue;
        for (final e in result) {
          try {
            for (final m in e.querySelectorAll(ex)) {
              m.remove();
            }
          } catch (_) {}
        }
      }
    }
    return result;
  }

  static List<Element> _applySelectorPipeline(
    Document doc,
    String selector,
    List<Element> source,
  ) {
    List<Element>? current = source.isEmpty ? null : source;
    var prevPseudo = false;
    for (final token in _tokenize(selector)) {
      switch (token) {
        case _CssFrag(:final text):
          if (text.isEmpty) break;
          current = _applyCssToken(doc, text, current, prevPseudo);
          prevPseudo = false;
        case _Pseudo(:final type, :final arg):
          current ??= doc.querySelectorAll('*').toList();
          current = _applyPseudo(current, type, arg);
          prevPseudo = true;
      }
    }
    return current ?? <Element>[];
  }

  static List<Element> _applyCssToken(
    Document doc,
    String frag,
    List<Element>? current,
    bool prevPseudo,
  ) {
    switch (frag[0]) {
      case '>':
        return _selectChildren(doc, frag.substring(1), current);
      case '+':
        return _selectSiblings(doc, frag.substring(1), current, adjacent: true);
      case '~':
        return _selectSiblings(
          doc,
          frag.substring(1),
          current,
          adjacent: false,
        );
    }
    if (prevPseudo && current != null) {
      return current.where((e) => _matches(e, frag)).toList();
    }
    return _applyCss(doc, frag, current);
  }

  static List<Element> _applyCss(
    Document doc,
    String frag,
    List<Element>? current,
  ) {
    if (current == null) {
      try {
        return doc.querySelectorAll(frag).toList();
      } catch (_) {
        return <Element>[];
      }
    }
    if (current.isEmpty) return current;
    final out = <Element>[];
    for (final e in current) {
      try {
        out.addAll(e.querySelectorAll(frag));
      } catch (_) {
        return <Element>[];
      }
    }
    return out;
  }

  static List<Element> _selectChildren(
    Document doc,
    String frag,
    List<Element>? current,
  ) {
    if (current == null) return _applyCss(doc, frag, null);
    final out = <Element>[];
    for (final e in current) {
      for (final c in e.children) {
        if (_matches(c, frag)) out.add(c);
      }
    }
    return out;
  }

  static List<Element> _selectSiblings(
    Document doc,
    String frag,
    List<Element>? current, {
    required bool adjacent,
  }) {
    if (current == null) return _applyCss(doc, frag, null);
    final out = <Element>[];
    for (final e in current) {
      var sib = e.nextElementSibling;
      while (sib != null) {
        if (_matches(sib, frag)) out.add(sib);
        if (adjacent) break;
        sib = sib.nextElementSibling;
      }
    }
    return out;
  }

  static bool _matches(Element e, String selector) {
    final parent = e.parent;
    if (parent == null) return false;
    try {
      return parent.querySelectorAll(selector).contains(e);
    } catch (_) {
      return false;
    }
  }

  static List<Element> _applyPseudo(
    List<Element> els,
    String type,
    String? arg,
  ) {
    switch (type) {
      case 'first':
        return els.isEmpty ? els : [els.first];
      case 'last':
        return els.isEmpty ? els : [els.last];
      case 'eq':
        final n = int.tryParse(arg ?? '') ?? 0;
        final idx = n < 0 ? els.length + n : n;
        return (idx >= 0 && idx < els.length) ? [els[idx]] : <Element>[];
      case 'lt':
        var n = int.tryParse(arg ?? '') ?? 0;
        if (n < 0) n = els.length + n;
        if (n < 0) n = 0;
        return els.take(n).toList();
      case 'gt':
        var n = int.tryParse(arg ?? '') ?? 0;
        if (n < 0) n = els.length + n;
        return els.skip(n + 1).toList();
      case 'has':
        final sel = arg ?? '';
        if (sel.isEmpty) return els;
        return els.where((e) {
          try {
            return e.querySelector(sel) != null;
          } catch (_) {
            return false;
          }
        }).toList();
      case 'contains':
        final needle = (arg ?? '').toLowerCase();
        return els
            .where((e) => _elementText(e).toLowerCase().contains(needle))
            .toList();
      default:
        return els;
    }
  }

  static List<_SelToken> _tokenize(String selector) {
    final tokens = <_SelToken>[];
    final css = StringBuffer();
    var i = 0;
    final n = selector.length;
    var bracketDepth = 0;
    var parenDepth = 0;
    String? quote;
    while (i < n) {
      final ch = selector[i];
      if (quote != null) {
        css.write(ch);
        if (ch == '\\' && i + 1 < n) {
          css.write(selector[i + 1]);
          i += 2;
          continue;
        }
        if (ch == quote) quote = null;
        i++;
        continue;
      }
      if (ch == '"' || ch == "'") {
        quote = ch;
        css.write(ch);
        i++;
        continue;
      }
      if (ch == '\\') {
        css.write(ch);
        if (i + 1 < n) {
          css.write(selector[i + 1]);
          i += 2;
        } else {
          i++;
        }
        continue;
      }
      if (ch == '[') {
        bracketDepth++;
        css.write(ch);
        i++;
        continue;
      }
      if (ch == ']') {
        if (bracketDepth > 0) bracketDepth--;
        css.write(ch);
        i++;
        continue;
      }
      if (ch == '(') {
        parenDepth++;
        css.write(ch);
        i++;
        continue;
      }
      if (ch == ')') {
        if (parenDepth > 0) parenDepth--;
        css.write(ch);
        i++;
        continue;
      }
      if (ch == ':' && bracketDepth == 0 && parenDepth == 0) {
        final m = _pseudoNameRe.matchAsPrefix(selector, i + 1);
        final name = m?.group(0);
        if (name != null && _jsoupPseudos.contains(name)) {
          if (css.isNotEmpty) {
            tokens.add(_CssFrag(css.toString()));
            css.clear();
          }
          var j = m!.end;
          String? arg;
          if (j < n && selector[j] == '(') {
            final end = _matchParen(selector, j);
            if (end < 0) {
              css.write(selector.substring(i));
              i = n;
              continue;
            }
            arg = selector.substring(j + 1, end - 1).trim();
            j = end;
          }
          tokens.add(_Pseudo(name, arg));
          i = j;
          continue;
        }
      }
      css.write(ch);
      i++;
    }
    if (css.isNotEmpty) tokens.add(_CssFrag(css.toString()));
    return tokens;
  }

  static int _matchParen(String s, int openIdx) {
    var depth = 0;
    String? quote;
    for (var i = openIdx; i < s.length; i++) {
      final ch = s[i];
      if (quote != null) {
        if (ch == '\\') {
          i++;
          continue;
        }
        if (ch == quote) quote = null;
        continue;
      }
      if (ch == '"' || ch == "'") {
        quote = ch;
        continue;
      }
      if (ch == '\\') {
        i++;
        continue;
      }
      if (ch == '(') {
        depth++;
      } else if (ch == ')') {
        depth--;
        if (depth == 0) return i + 1;
      }
    }
    return -1;
  }

  /// com.github.catvod.crawler.js.HtmlParser.joinUrl
  static String joinUrl(String parent, String child) {
    if (parent.isEmpty) return child;
    try {
      return Uri.parse(parent).resolve(child).toString();
    } catch (_) {
      return parent;
    }
  }

  /// com.github.catvod.crawler.js.HtmlParser.parseDomForUrl
  static String parseDomForUrl(String html, String rule, [String addUrl = '']) {
    try {
      final doc = _parseDoc(html);
      if (rule == 'body&&Text' || rule == 'Text') {
        return _elementText(doc.documentElement);
      }
      if (rule == 'body&&Html' || rule == 'Html') {
        return doc.documentElement?.innerHtml ?? '';
      }
      var option = '';
      if (rule.contains('&&')) {
        var rs = _splitTrimTrailing(rule, '&&');
        if (rs.isNotEmpty) {
          option = rs.last;
          rule = rs.sublist(0, rs.length - 1).join('&&');
        }
      }
      rule = _hikerToJq(rule, true);
      var els = <Element>[];
      for (final seg in rule.split(' ')) {
        els = _parseOneRule(doc, seg, els);
        if (els.isEmpty) return '';
      }
      String result;
      if (option.isNotEmpty) {
        if (option == 'Text') {
          result = els.map(_elementText).join(' ');
        } else if (option == 'Html') {
          result = els.map((e) => e.innerHtml).join('\n');
        } else {
          var attr = '';
          for (final e in els) {
            final value = e.attributes[option];
            if (value != null) {
              attr = value;
              break;
            }
          }
          result = attr;
          if (option.toLowerCase().contains('style') &&
              result.contains('url(')) {
            final m = _styleUrlRe.firstMatch(result);
            if (m != null) result = m.group(1)!;
            if (result.isNotEmpty) {
              result = result.replaceAllMapped(
                _quoteRe,
                (m) => m.group(1) ?? '',
              );
            }
          }
          if (result.isNotEmpty && addUrl.isNotEmpty) {
            if (_urlJoinAttrRe.hasMatch(option) &&
                !_specialUrlRe.hasMatch(result)) {
              if (result.contains('http')) {
                result = result.substring(result.indexOf('http'));
              } else {
                result = joinUrl(addUrl, result);
              }
            }
          }
        }
      } else {
        result = els.map((e) => e.outerHtml).join('\n');
      }
      return result;
    } catch (_) {
      return '';
    }
  }

  /// com.github.catvod.crawler.js.HtmlParser.parseDomForArray
  static List<String> parseDomForArray(String html, String rule) {
    try {
      final doc = _parseDoc(html);
      rule = _hikerToJq(rule, false);
      var els = <Element>[];
      for (final seg in rule.split(' ')) {
        els = _parseOneRule(doc, seg, els);
        if (els.isEmpty) return [];
      }
      return [for (final e in els) e.outerHtml];
    } catch (_) {
      return [];
    }
  }

  /// com.github.catvod.crawler.js.HtmlParser.parseDomForList
  static List<String> parseDomForList(
    String html,
    String p1,
    String listText,
    String listUrl,
    String addUrl,
  ) {
    try {
      final items = parseDomForArray(html, p1);
      return [
        for (final it in items)
          '${parseDomForUrl(it, listText, '').trim()}\$${parseDomForUrl(it, listUrl, addUrl)}',
      ];
    } catch (_) {
      return [];
    }
  }
}
