import 'package:file_picker/file_picker.dart';

import 'file_pick_types.dart';

/// Picks a file on native platforms (Android/iOS) via file_picker.
Future<PickedFile?> pickCvFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;
  final f = result.files.first;
  final bytes = f.bytes;
  if (bytes == null) return null;
  return PickedFile(
    bytes: bytes,
    name: f.name,
    mimeType: _mimeForExtension(f.extension) ?? '',
  );
}

String? _mimeForExtension(String? ext) => switch (ext?.toLowerCase()) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => null,
    };
