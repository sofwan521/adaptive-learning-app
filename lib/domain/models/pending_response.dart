import 'package:equatable/equatable.dart';

/// Satu jawaban yang menunggu dikirim ke backend (antrean luring).
///
/// `studentId` sengaja tidak disimpan: diisi dari sesi aktif saat
/// pengiriman agar aman bila akun berganti.
///
/// Immutable + Equatable (tanpa code generation).
/// Logika murni — tanpa import Flutter.
class PendingResponse extends Equatable {
  final String id;
  final String sessionId;
  final String itemId;
  final int selectedIndex;
  final bool isCorrect;
  final double? thetaAfter;

  const PendingResponse({
    required this.id,
    required this.sessionId,
    required this.itemId,
    required this.selectedIndex,
    required this.isCorrect,
    this.thetaAfter,
  });

  factory PendingResponse.fromJson(Map<String, dynamic> json) {
    return PendingResponse(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      itemId: json['itemId'] as String,
      selectedIndex: json['selectedIndex'] as int? ?? 0,
      isCorrect: json['correct'] as bool? ?? false,
      thetaAfter: (json['thetaAfter'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'itemId': itemId,
      'selectedIndex': selectedIndex,
      'correct': isCorrect,
      'thetaAfter': thetaAfter,
    };
  }

  @override
  List<Object?> get props =>
      [id, sessionId, itemId, selectedIndex, isCorrect, thetaAfter];
}

/// Hasil percobaan penyimpanan satu respons.
enum ResponseSyncStatus {
  /// Terkirim ke backend.
  sent,

  /// Gagal terkirim (luring) dan masuk antrean lokal.
  queued,
}
