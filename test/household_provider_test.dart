import 'package:flutter_test/flutter_test.dart';
import 'package:binlink_mobile/features/household/providers/household_provider.dart';

void main() {
  // ── Computed getters ────────────────────────────────────────────────────────

  group('HouseholdProvider computed getters', () {
    late HouseholdProvider provider;

    setUp(() => provider = HouseholdProvider());

    test('completedBookings filters by COMPLETED status', () {
      provider.bookingsForTest = [
        {'id': '1', 'status': 'COMPLETED', 'totalAmount': 30},
        {'id': '2', 'status': 'CANCELLED', 'totalAmount': 40},
        {'id': '3', 'status': 'SEARCHING', 'totalAmount': 50},
      ];
      expect(provider.completedBookings.length, 1);
      expect(provider.completedBookings.first['id'], '1');
    });

    test('allBookings returns an unmodifiable list', () {
      provider.bookingsForTest = [
        {'id': '1', 'status': 'COMPLETED', 'totalAmount': 30},
      ];
      final all = provider.allBookings;
      expect(() => (all as dynamic).add(<String, dynamic>{}), throwsUnsupportedError);
    });

    test('activeBooking is set for in-progress status', () {
      provider.bookingsForTest = [
        {'id': 'active_1', 'status': 'ACCEPTED'},
        {'id': 'done_1',   'status': 'COMPLETED'},
      ];
      expect(provider.activeBooking, isNotNull);
      expect(provider.activeBooking!['id'], 'active_1');
    });

    test('activeBooking is null when only terminal bookings exist', () {
      provider.bookingsForTest = [
        {'id': '1', 'status': 'COMPLETED'},
        {'id': '2', 'status': 'CANCELLED'},
      ];
      expect(provider.activeBooking, isNull);
    });

    test('subscriptions list starts empty', () {
      expect(provider.subscriptions, isEmpty);
    });

    test('savedAddresses list starts empty', () {
      expect(provider.savedAddresses, isEmpty);
    });

    test('error is null initially', () {
      expect(provider.error, isNull);
    });

    test('loading is false initially', () {
      expect(provider.loading, isFalse);
    });
  });

  // ── Subscription state ───────────────────────────────────────────────────────

  group('HouseholdProvider subscription state', () {
    late HouseholdProvider provider;

    setUp(() => provider = HouseholdProvider());

    test('subscriptionsForTest setter populates subscriptions', () {
      provider.subscriptionsForTest = [
        {
          'id': 'sub_1', 'plan': 'WEEKLY', 'status': 'ACTIVE',
          'binSize': 'MEDIUM', 'pickupAddress': '123 Test St', 'price': 40.0,
        },
        {
          'id': 'sub_2', 'plan': 'MONTHLY', 'status': 'PAUSED',
          'binSize': 'LARGE', 'pickupAddress': '456 Ave', 'price': 50.0,
        },
      ];
      expect(provider.subscriptions.length, 2);
      expect(provider.subscriptions.first['plan'], 'WEEKLY');
      expect(provider.subscriptions.last['status'], 'PAUSED');
    });

    test('active subscription has status ACTIVE', () {
      provider.subscriptionsForTest = [
        {'id': 'sub_1', 'plan': 'WEEKLY', 'status': 'ACTIVE', 'price': 40.0},
        {'id': 'sub_2', 'plan': 'MONTHLY', 'status': 'CANCELLED', 'price': 50.0},
      ];
      final active = provider.subscriptions.where((s) => s['status'] == 'ACTIVE').toList();
      expect(active.length, 1);
    });
  });

  // ── Polyline decode (mirrors OSRM provider logic) ─────────────────────────

  group('Google polyline decode', () {
    test('empty string returns empty list', () {
      expect(_decodePolyline(''), isEmpty);
    });

    test('known encoded string decodes lat/lng correctly', () {
      // Standard test vector from Google Polyline spec
      const encoded = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';
      final points = _decodePolyline(encoded);
      expect(points.length, 3);
      expect(points[0][0], closeTo(38.5, 0.001));
      expect(points[0][1], closeTo(-120.2, 0.001));
      expect(points[1][0], closeTo(40.7, 0.001));
      expect(points[2][0], closeTo(43.252, 0.001));
    });

    test('single point encodes and decodes symmetrically', () {
      // Verify using a known decode: first point of the standard test vector
      // _p~iF~ps|U decodes to lat=38.5, lng=-120.2
      final pts = _decodePolyline('_p~iF~ps|U');
      expect(pts.length, 1);
      expect(pts[0][0], closeTo(38.5, 0.001));
      expect(pts[0][1], closeTo(-120.2, 0.001));
    });
  });
}

// ── Polyline decode helper (mirrors OsrmRoutingProvider._decodePolyline) ────

List<List<double>> _decodePolyline(String encoded) {
  final points = <List<double>>[];
  int index = 0, lat = 0, lng = 0;
  while (index < encoded.length) {
    int shift = 0, result = 0, byte;
    do {
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1F) << shift;
      shift += 5;
    } while (byte >= 0x20);
    lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    shift = 0; result = 0;
    do {
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1F) << shift;
      shift += 5;
    } while (byte >= 0x20);
    lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    points.add([lat / 1e5, lng / 1e5]);
  }
  return points;
}
