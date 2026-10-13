import 'package:equatable/equatable.dart';

/// Satu respons siswa untuk estimasi EAP.
///
/// Menyimpan parameter soal (2PL) beserta kebenaran jawaban,
/// sehingga estimasi tidak perlu mencari soal aslinya.
///
/// Immutable + Equatable (tanpa code generation).
/// Logika murni — tanpa import Flutter.
class ResponseRecord extends Equatable {
  final double a;
  final double b;
  final bool correct;

  const ResponseRecord({
    required this.a,
    required this.b,
    required this.correct,
  });

  factory ResponseRecord.fromJson(Map<String, dynamic> json) {
    return ResponseRecord(
      a: (json['a'] as num? ?? 1.0).toDouble(),
      b: (json['b'] as num? ?? 0.0).toDouble(),
      correct: json['correct'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'a': a,
      'b': b,
      'correct': correct,
    };
  }

  @override
  List<Object?> get props => [a, b, correct];
}
