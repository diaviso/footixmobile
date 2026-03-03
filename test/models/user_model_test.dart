import 'package:flutter_test/flutter_test.dart';
import 'package:footix/data/models/user_model.dart';

void main() {
  group('UserModel', () {
    final sampleJson = {
      'id': 'u1',
      'email': 'test@example.com',
      'firstName': 'Jean',
      'lastName': 'Dupont',
      'country': 'France',
      'city': 'Paris',
      'avatar': '/uploads/avatar.jpg',
      'role': 'USER',
      'isEmailVerified': true,
      'stars': 42,
      'showInLeaderboard': true,
      'emailNotifications': true,
      'pushNotifications': false,
      'marketingEmails': false,
      'createdAt': '2024-01-01T00:00:00.000Z',
      'updatedAt': '2024-06-01T00:00:00.000Z',
    };

    test('fromJson parses all fields correctly', () {
      final user = UserModel.fromJson(sampleJson);

      expect(user.id, 'u1');
      expect(user.email, 'test@example.com');
      expect(user.firstName, 'Jean');
      expect(user.lastName, 'Dupont');
      expect(user.country, 'France');
      expect(user.city, 'Paris');
      expect(user.avatar, '/uploads/avatar.jpg');
      expect(user.role, 'USER');
      expect(user.isEmailVerified, true);
      expect(user.stars, 42);
      expect(user.showInLeaderboard, true);
      expect(user.emailNotifications, true);
      expect(user.pushNotifications, false);
      expect(user.marketingEmails, false);
    });

    test('fromJson handles missing optional fields with defaults', () {
      final user = UserModel.fromJson({
        'id': 'u2',
        'email': 'min@test.com',
        'firstName': 'A',
        'lastName': 'B',
        'createdAt': '2024-01-01',
        'updatedAt': '2024-01-01',
      });

      expect(user.role, 'USER');
      expect(user.isEmailVerified, false);
      expect(user.stars, 0);
      expect(user.showInLeaderboard, true);
      expect(user.country, isNull);
      expect(user.city, isNull);
      expect(user.avatar, isNull);
      expect(user.emailNotifications, true);
      expect(user.pushNotifications, true);
      expect(user.marketingEmails, false);
    });

    test('toJson produces correct map', () {
      final user = UserModel.fromJson(sampleJson);
      final json = user.toJson();

      expect(json['id'], 'u1');
      expect(json['email'], 'test@example.com');
      expect(json['firstName'], 'Jean');
      expect(json['stars'], 42);
      expect(json['emailNotifications'], true);
      expect(json['pushNotifications'], false);
    });

    test('fullName concatenates first and last name', () {
      final user = UserModel.fromJson(sampleJson);
      expect(user.fullName, 'Jean Dupont');
    });

    test('isAdmin returns true for ADMIN role', () {
      final admin = UserModel.fromJson({...sampleJson, 'role': 'ADMIN'});
      expect(admin.isAdmin, true);

      final user = UserModel.fromJson(sampleJson);
      expect(user.isAdmin, false);
    });

    test('copyWith creates new instance with overridden fields', () {
      final user = UserModel.fromJson(sampleJson);
      final updated = user.copyWith(firstName: 'Pierre', stars: 100);

      expect(updated.firstName, 'Pierre');
      expect(updated.stars, 100);
      expect(updated.id, 'u1');
      expect(updated.email, 'test@example.com');
      expect(updated.lastName, 'Dupont');
    });

    test('copyWith preserves all fields when no overrides', () {
      final user = UserModel.fromJson(sampleJson);
      final copy = user.copyWith();

      expect(copy.id, user.id);
      expect(copy.email, user.email);
      expect(copy.firstName, user.firstName);
      expect(copy.lastName, user.lastName);
      expect(copy.stars, user.stars);
      expect(copy.emailNotifications, user.emailNotifications);
    });
  });
}
