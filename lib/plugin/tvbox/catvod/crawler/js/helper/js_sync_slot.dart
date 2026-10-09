import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

class JsSyncSlot {
  final Pointer<Int64> _mem;

  int get address => _mem.address;
  bool get requested => _mem[0] == 1;
  bool get done => _mem[0] == 2;
  int get status => _mem[1];

  JsSyncSlot() : _mem = malloc<Int64>(4) {
    reset();
  }

  JsSyncSlot.fromAddress(int addr) : _mem = Pointer<Int64>.fromAddress(addr);

  void markRequested() => _mem[0] = 1;

  void reset() {
    _mem[0] = 0;
    _mem[1] = 0;
    _mem[2] = 0;
    _mem[3] = 0;
  }

  void respond(String body, {int status = 0}) {
    final bytes = utf8.encode(body);
    final len = bytes.isEmpty ? 1 : bytes.length;
    final p = malloc<Uint8>(len);
    if (bytes.isNotEmpty) {
      p.asTypedList(bytes.length).setAll(0, bytes);
    }
    _mem[2] = p.address;
    _mem[3] = bytes.length;
    _mem[1] = status;
    _mem[0] = 2;
  }

  String readAndFree() {
    final addr = _mem[2];
    final len = _mem[3];
    String body = '';
    if (addr != 0) {
      final p = Pointer<Uint8>.fromAddress(addr);
      if (len > 0) body = utf8.decode(p.asTypedList(len).toList());
      malloc.free(p);
    }
    reset();
    return body;
  }

  bool wait({Duration timeout = const Duration(seconds: 30)}) {
    final sw = Stopwatch()..start();
    while (!done) {
      if (sw.elapsed > timeout) return false;
      sleep(const Duration(microseconds: 200));
    }
    return true;
  }

  void dispose() {
    if (_mem[0] == 2) readAndFree();
    malloc.free(_mem);
  }
}
