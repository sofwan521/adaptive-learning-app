import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_learning_app/core/error/app_exception.dart';
import 'package:adaptive_learning_app/data/repositories/concept_repository_impl.dart';
import 'package:adaptive_learning_app/data/repositories/gamification_repository_impl.dart';
import 'package:adaptive_learning_app/data/repositories/progress_repository_impl.dart';
import 'package:adaptive_learning_app/domain/models/concept_status.dart';
import 'package:adaptive_learning_app/features/student/application/student_providers.dart';

import '../helpers/repository_fakes.dart';

/// Container uji dengan retry Riverpod dinonaktifkan.
///
/// Riverpod 3 mengulang FutureProvider yang galat dengan backoff
/// eksponensial; untuk uji, galat harus terlihat langsung.
ProviderContainer _container({
  FakeConceptRepository? concepts,
  FakeProgressRepository? progress,
  FakeGamificationRepository? gamification,
}) {
  return ProviderContainer.test(
    overrides: [
      conceptRepositoryProvider.overrideWithValue(
        concepts ?? FakeConceptRepository(),
      ),
      progressRepositoryProvider.overrideWithValue(
        progress ?? FakeProgressRepository(),
      ),
      gamificationRepositoryProvider.overrideWithValue(
        gamification ?? FakeGamificationRepository(),
      ),
    ],
    retry: (_, __) => null,
  );
}

void main() {
  group('ringkasan belajar siswa', () {
    test('status dihitung dari state: mastered/learning/locked', () async {
      final container = _container(
        progress: FakeProgressRepository(
          states: [masteredState('K01'), learningState('K02')],
        ),
      );

      final statuses = await container.read(conceptStatusesProvider.future);

      expect(statuses['K01'], ConceptStatus.mastered);
      expect(statuses['K02'], ConceptStatus.learning);
      expect(statuses['K03'], ConceptStatus.locked);
    });

    test('lanjutan memakai learning terakhir menurut topologis', () async {
      final container = _container(
        progress: FakeProgressRepository(
          states: [masteredState('K01'), learningState('K02')],
        ),
      );

      final concept = await container.read(continueConceptProvider.future);

      expect(concept?.id, 'K02');
    });

    test('tanpa learning memakai open pertama', () async {
      final container = _container(
        progress: FakeProgressRepository(
          states: [masteredState('K01'), masteredState('K02')],
        ),
      );

      final concept = await container.read(continueConceptProvider.future);

      expect(concept?.id, 'K03');
    });

    test('semua mastered berarti tak ada lanjutan', () async {
      final container = _container(
        progress: FakeProgressRepository(
          states: [
            masteredState('K01'),
            masteredState('K02'),
            masteredState('K03'),
          ],
        ),
      );

      expect(
        await container.read(continueConceptProvider.future),
        isNull,
      );
    });

    test('target harian memakai ambang 5 soal', () async {
      final container = _container(
        progress: FakeProgressRepository(answeredToday: 3),
      );

      final daily = await container.read(dailyProgressProvider.future);

      expect(daily.answered, 3);
      expect(daily.target, 5);
    });

    test('galat backend diteruskan ke UI', () async {
      final container = _container(
        progress: FakeProgressRepository()
          ..failure = const AppException('Gagal memuat data.'),
      );

      await expectLater(
        container.read(continueConceptProvider.future),
        throwsA(isA<AppException>()),
      );
    });
  });
}
