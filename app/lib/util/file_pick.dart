import 'file_pick_types.dart';
// Web uses a native <input type="file"> (reliable on iOS Safari); other
// platforms use file_picker. The right implementation is chosen at compile
// time so the wrong SDK library is never pulled in.
import 'file_pick_io.dart'
    if (dart.library.js_interop) 'file_pick_web.dart' as impl;

export 'file_pick_types.dart';

/// Opens a file picker for a CV (PDF or image) and returns the chosen file,
/// or null if the user cancelled.
Future<PickedFile?> pickCvFile() => impl.pickCvFile();
