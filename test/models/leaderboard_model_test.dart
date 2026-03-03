import 'package:flutter_test/flutter_test.dart';
import 'package:footix/data/models/leaderboard_model.dart';

void main() {
  group('LeaderboardEntryModel', () {
    test('fromJson parses all fields', () {
      final entry = LeaderboardEntryModel.fromJson({
        'rank': 1,
        'userId': 'u1',
        'firstName': 'Jean',
        'lastName': 'Dupont',
        'avatar': '/img/avatar.jpg',
        'stars': 150,
      });

      expect(entry.rank, 1);
      expect(entry.userId, 'u1');
      expect(entry.firstName, 'Jean');
      expect(entry.lastName, 'Dupont');
      expect(entry.avatar, '/img/avatar.jpg');
      expect(entry.stars, 150);
    });

    test('fullName concatenates names', () {
      final entry = LeaderboardEntryModel.fromJson({
        'rank': 2,
        'userId': 'u2',
        'firstName': 'Marie',
        'lastName': 'Martin',
        'stars': 100,
      });
      expect(entry.fullName, 'Marie Martin');
    });

    test('fromJson handles missing fields with defaults', () {
      final entry = LeaderboardEntryModel.fromJson({});
      expect(entry.rank, 0);
      expect(entry.userId, '');
      expect(entry.firstName, '');
      expect(entry.lastName, '');
      expect(entry.avatar, isNull);
      expect(entry.stars, 0);
    });

    test('fromJson uses id fallback for userId', () {
      final entry = LeaderboardEntryModel.fromJson({
        'id': 'fallback-id',
        'rank': 5,
        'stars': 10,
      });
      expect(entry.userId, 'fallback-id');
    });
  });

  group('UserPositionModel', () {
    test('fromJson parses all fields', () {
      final pos = UserPositionModel.fromJson({
        'rank': 42,
        'stars': 85,
        'totalUsers': 500,
      });

      expect(pos.rank, 42);
      expect(pos.stars, 85);
      expect(pos.totalUsers, 500);
    });

    test('fromJson handles missing fields', () {
      final pos = UserPositionModel.fromJson({});
      expect(pos.rank, 0);
      expect(pos.stars, 0);
      expect(pos.totalUsers, 0);
    });
  });
}
