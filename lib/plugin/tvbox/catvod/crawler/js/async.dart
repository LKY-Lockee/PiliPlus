import 'dart:async';

/// com.github.catvod.crawler.js.Async
class Async {
  Async._();

  /// com.github.catvod.crawler.js.Async.run
  static Future<dynamic> run(void Function() kick, dynamic result) {
    if (result is! Future) {
      return Future.value(result);
    }
    final completer = Completer<dynamic>();
    final timer = Timer.periodic(
      const Duration(milliseconds: 1),
      (_) => kick(),
    );
    result.then(
      (v) {
        if (!completer.isCompleted) completer.complete(v);
      },
      onError: (Object e, StackTrace s) {
        if (!completer.isCompleted) completer.completeError(e, s);
      },
    );
    return completer.future.whenComplete(timer.cancel);
  }
}
