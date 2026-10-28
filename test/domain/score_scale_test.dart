import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_learning_app/domain/irt/score_scale.dart';

void main() {
  group('thetaToPercent', () {
    test('theta 0 setara 50 persen', () {
      expect(thetaToPercent(0), closeTo(50, 1e-9));
    });

    test('naik monoton terhadap theta', () {
      expect(thetaToPercent(-1), lessThan(thetaToPercent(0)));
      expect(thetaToPercent(1), greaterThan(thetaToPercent(0)));
    });

    test('clamp pada batas skala', () {
      final low = 100 / (1 + exp(minThetaScale.abs()));
      expect(
        thetaToPercent(-100),
        closeTo(100 / (1 + exp(4)), 1e-9),
      );
      expect(thetaToPercent(100), closeTo(100 / (1 + exp(-4)), 1e-9));
      expect(thetaToPercent(-100), closeTo(low, 1e-9));
    });

    test('selalu berada pada 0..100', () {
      for (var theta = -10.0; theta <= 10.0; theta += 0.5) {
        final percent = thetaToPercent(theta);
        expect(percent, inInclusiveRange(0, 100));
      }
    });
  });

  group('percentToTheta', () {
    test('50 persen setara theta 0', () {
      expect(percentToTheta(50), closeTo(0, 1e-9));
    });

    test('invers thetaToPercent', () {
      for (var theta = -3.5; theta <= 3.5; theta += 0.25) {
        expect(
          percentToTheta(thetaToPercent(theta)),
          closeTo(theta, 1e-6),
        );
      }
    });

    test('clamp persen ekstrem tetap hingga', () {
      expect(percentToTheta(0).isFinite, isTrue);
      expect(percentToTheta(100).isFinite, isTrue);
      expect(percentToTheta(-20), lessThan(0));
      expect(percentToTheta(120), greaterThan(0));
    });
  });

  group('formatPercent', () {
    test('membulatkan dan membatasi 0..100', () {
      expect(formatPercent(72.4), '72%');
      expect(formatPercent(72.6), '73%');
      expect(formatPercent(-5), '0%');
      expect(formatPercent(150), '100%');
    });
  });
}
