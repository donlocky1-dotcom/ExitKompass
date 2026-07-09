/// A file the user picked, in a platform-neutral shape.
class PickedFile {
  const PickedFile({
    required this.bytes,
    required this.name,
    required this.mimeType,
  });

  final List<int> bytes;
  final String name;

  /// MIME type reported by the browser/OS ('' if unknown).
  final String mimeType;
}
