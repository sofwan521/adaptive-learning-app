import 'package:equatable/equatable.dart';

import '../irt/score_scale.dart';

/// Hasil estimasi kemampuan: rata-rata posterior (theta)
/// dan simpangan baku posterior (SE).
///
/// Immutable + Equatable (tanpa code generation).
/// Logika murni — tanpa import Flutter.
class AbilityEstimate extends Equatable {
  final double theta;
  final double se;

  const AbilityEstimate({
    required this.theta,
    required this.se,
  });

  /// Skor kemampuan dalam persen (0..100).
  double get percent => thetaToPercent(theta);

  factory AbilityEstimate.fromJson(Map<String, dynamic> json) {
    return AbilityEstimate(
      theta: (json['theta'] as num? ?? 0.0).toDouble(),
      se: (json['se'] as num? ?? 1.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theta': theta,
      'se': se,
    };
  }

  @override
  List<Object?> get props => [theta, se];
}
