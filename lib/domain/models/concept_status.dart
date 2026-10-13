/// Status penguasaan sebuah konsep.
///
/// `locked` → prasyarat belum tuntas.
/// `open` → bisa dipelajari.
/// `learning` → sedang dipelajari.
/// `mastered` → sudah dikuasai.
///
/// Logika murni — tanpa import Flutter.
enum ConceptStatus {
  locked,
  open,
  learning,
  mastered;

  /// Parse dari string. Default ke [locked].
  static ConceptStatus fromString(String? value) {
    switch (value) {
      case 'open':
        return ConceptStatus.open;
      case 'learning':
        return ConceptStatus.learning;
      case 'mastered':
        return ConceptStatus.mastered;
      case 'locked':
      default:
        return ConceptStatus.locked;
    }
  }

  /// Label Bahasa Indonesia untuk UI.
  String get label {
    switch (this) {
      case ConceptStatus.locked:
        return 'Terkunci';
      case ConceptStatus.open:
        return 'Terbuka';
      case ConceptStatus.learning:
        return 'Dipelajari';
      case ConceptStatus.mastered:
        return 'Dikuasai';
    }
  }
}
