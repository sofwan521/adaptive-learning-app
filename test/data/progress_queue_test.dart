import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:adaptive_learning_app/core/error/app_exception.dart';
import 'package:adaptive_learning_app/data/datasources/pending_response_store.dart';
import 'package:adaptive_learning_app/data/repositories/progress_repository_impl.dart';
import 'package:adaptive_learning_app/domain/models/pending_response.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockAuth extends Mock implements GoTrueClient {}

class MockPendingStore extends Mock implements PendingResponseStore {}

class MockResponseSender extends Mock {
  Future<void> call(Map<String, dynamic> row);
}

const _user = User(
  id: 'siswa-1',
  appMetadata: {},
  userMetadata: {},
  aud: '',
  createdAt: '2024-01-01T00:00:00Z',
);

const _r1 = PendingResponse(
  id: 'local-1',
  sessionId: 'sesi-1',
  itemId: 'soal-1',
  selectedIndex: 2,
  isCorrect: true,
  thetaAfter: 0.5,
);

const _r2 = PendingResponse(
  id: 'local-2',
  sessionId: 'sesi-1',
  itemId: 'soal-2',
  selectedIndex: 0,
  isCorrect: false,
);

void main() {
  late MockSupabaseClient client;
  late MockAuth auth;
  late MockPendingStore store;
  late MockResponseSender sender;
  late SupabaseProgressRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    auth = MockAuth();
    store = MockPendingStore();
    sender = MockResponseSender();
    when(() => client.auth).thenReturn(auth);
    when(() => auth.currentUser).thenReturn(_user);
    repo = SupabaseProgressRepository(
      client: client,
      pendingStore: store,
      responseSender: sender.call,
    );
  });

  group('saveResponse', () {
    test('terkirim saat daring dan tidak menyentuh antrean', () async {
      when(() => sender(any())).thenAnswer((_) async {});

      final status = await repo.saveResponse(_r1);

      expect(status, ResponseSyncStatus.sent);
      verify(() => sender(any())).called(1);
      verifyNever(() => store.saveAll(any()));
    });

    test('mengirim baris Supabase yang benar', () async {
      when(() => sender(any())).thenAnswer((_) async {});

      await repo.saveResponse(_r1);

      final captured = verify(() => sender(captureAny())).captured;
      final row = captured.single as Map;
      expect(row['item_id'], 'soal-1');
      expect(row['student_id'], 'siswa-1');
      expect(row['session_id'], 'sesi-1');
      expect(row['selected_index'], 2);
      expect(row['is_correct'], isTrue);
    });

    test('tersimpan ke antrean saat luring', () async {
      when(() => sender(any()))
          .thenThrow(const SocketException('Jaringan mati'));
      when(() => store.loadAll()).thenAnswer((_) async => []);
      when(() => store.saveAll(any())).thenAnswer((_) async {});

      final status = await repo.saveResponse(_r1);

      expect(status, ResponseSyncStatus.queued);
      verify(() => store.saveAll([_r1])).called(1);
    });

    test('galat non-jaringan dipetakan ke AppException', () async {
      when(() => sender(any())).thenThrow(const PostgrestException(
        message: 'new row violates row-level security',
        code: '42501',
      ));

      expect(
        () => repo.saveResponse(_r1),
        throwsA(isA<AppException>().having(
          (e) => e.message,
          'message',
          contains('akses'),
        )),
      );
      verifyNever(() => store.saveAll(any()));
    });
  });

  group('flushPending', () {
    test('terkirim semua saat pulih dan antrean dibersihkan', () async {
      when(() => store.loadAll()).thenAnswer((_) async => [_r1, _r2]);
      when(() => sender(any())).thenAnswer((_) async {});
      when(() => store.saveAll(any())).thenAnswer((_) async {});

      final sent = await repo.flushPending();

      expect(sent, 2);
      verify(() => sender(any())).called(2);
      verify(() => store.saveAll([])).called(1);
    });

    test('gagal sebagian: yang terkirim dihapus, sisanya dipertahankan',
        () async {
      when(() => store.loadAll()).thenAnswer((_) async => [_r1, _r2]);
      when(() => store.saveAll(any())).thenAnswer((_) async {});
      var calls = 0;
      when(() => sender(any())).thenAnswer((_) async {
        calls++;
        if (calls == 2) throw const SocketException('Putus lagi');
      });

      final sent = await repo.flushPending();

      expect(sent, 1);
      verify(() => store.saveAll([_r2])).called(1);
    });

    test('antrean kosong tidak menyentuh jaringan', () async {
      when(() => store.loadAll()).thenAnswer((_) async => []);

      expect(await repo.flushPending(), 0);
      verifyNever(() => sender(any()));
      verifyNever(() => store.saveAll(any()));
    });

    test('pendingCount memantulkan isi antrean', () async {
      when(() => store.loadAll()).thenAnswer((_) async => [_r1, _r2]);
      expect(await repo.pendingCount(), 2);
    });
  });

  group('SharedPreferencesPendingStore', () {
    test('simpan-muat pulang-pergi utuh', () async {
      SharedPreferences.setMockInitialValues({});
      const storage = SharedPreferencesPendingStore();

      expect(await storage.loadAll(), isEmpty);
      await storage.saveAll([_r1, _r2]);
      expect(await storage.loadAll(), [_r1, _r2]);
      await storage.saveAll([]);
      expect(await storage.loadAll(), isEmpty);
    });
  });

  group('mapToAppException', () {
    test('kredensial salah berbahasa Indonesia', () {
      final mapped = mapToAppException(
        const AuthException('Invalid login credentials'),
      );
      expect(mapped.message, contains('kata sandi salah'));
    });

    test('surel sudah terdaftar berbahasa Indonesia', () {
      final mapped = mapToAppException(
        const AuthException('User already registered'),
      );
      expect(mapped.message, contains('sudah terdaftar'));
    });

    test('isOfflineError membedakan galat jaringan', () {
      expect(isOfflineError(const SocketException('x')), isTrue);
      expect(
        isOfflineError(const PostgrestException(
          message: 'new row violates row-level security',
          code: '42501',
        )),
        isFalse,
      );
      expect(isOfflineError(Exception('aneh')), isFalse);
    });
  });
}
