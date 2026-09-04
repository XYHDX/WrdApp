import 'dart:math';

final Random _random = Random.secure();

/// A random UUID v4, upper-case like Foundation's `UUID().uuidString`, so
/// identifiers written by the Swift app and by this app look the same.
String newId() {
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant
  final hex =
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// Fixed library identifiers — the same ones the Swift app used
/// (`D0000000-0000-4000-8000-%012d`), so saved awrād keep their identity.
String fixedId(int n) => 'D0000000-0000-4000-8000-${n.toString().padLeft(12, '0')}';
