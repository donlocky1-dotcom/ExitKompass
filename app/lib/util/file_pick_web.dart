import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'file_pick_types.dart';

/// Picks a file on the web with a native hidden `<input type="file">`. This is
/// far more reliable on iOS Safari than the file_picker plugin.
Future<PickedFile?> pickCvFile() {
  final completer = Completer<PickedFile?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = '.pdf,.png,.jpg,.jpeg,application/pdf,image/png,image/jpeg'
    ..multiple = false;

  input.addEventListener(
    'change',
    (web.Event _) {
      final files = input.files;
      if (files == null || files.length == 0) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }
      final file = files.item(0)!;
      final reader = web.FileReader();
      reader.addEventListener(
        'load',
        (web.Event _) {
          final result = reader.result;
          if (result.isA<JSArrayBuffer>()) {
            final bytes = (result as JSArrayBuffer).toDart.asUint8List();
            if (!completer.isCompleted) {
              completer.complete(PickedFile(
                bytes: bytes,
                name: file.name,
                mimeType: file.type,
              ));
            }
          } else if (!completer.isCompleted) {
            completer.complete(null);
          }
        }.toJS,
      );
      reader.addEventListener(
        'error',
        (web.Event _) {
          if (!completer.isCompleted) completer.complete(null);
        }.toJS,
      );
      reader.readAsArrayBuffer(file);
    }.toJS,
  );

  // Fired by some browsers when the dialog is dismissed without a choice.
  input.addEventListener(
    'cancel',
    (web.Event _) {
      if (!completer.isCompleted) completer.complete(null);
    }.toJS,
  );

  input.click();
  return completer.future;
}
