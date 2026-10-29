import 'package:flutter_test/flutter_test.dart';
import 'package:ridego/features/pricing/data/pricing_service.dart';
import 'package:ridego/features/search/data/search_repository.dart';

void main() {
  group('Phase 4: Automatic Pricing Engine & Search Tests', () {
    late PricingService pricingService;
    late SearchRepository searchRepository;

    setUp(() {
      pricingService = PricingService();
      searchRepository = SearchRepository();
    });

    test(
      'Authoritative fare calculation for shared van trip with terminal fee',
      () async {
        // 1 passenger shared van Catbalogan to Tacloban
        final quote = await pricingService.calculateAuthoritativeFare(
          originLocation: 'Catbalogan City',
          destinationLocation: 'Tacloban City',
          category: 'Van',
          passengers: 1,
          isPrivate: false,
        );

        expect(quote.isValid, isTrue);
        expect(quote.baseFare, 150.0);
        expect(quote.terminalFee, 10.0);
        expect(quote.totalFare, 160.0); // (150 * 1) + 10
        expect(quote.currency, 'PHP');
      },
    );

    test('Authoritative fare calculation for multiple passengers', () async {
      // 3 passengers shared van
      final quote = await pricingService.calculateAuthoritativeFare(
        originLocation: 'Catbalogan City',
        destinationLocation: 'Tacloban City',
        category: 'Van',
        passengers: 3,
        isPrivate: false,
      );

      expect(quote.isValid, isTrue);
      expect(quote.passengers, 3);
      expect(quote.totalFare, 460.0); // (150 * 3) + 10
    });

    test(
      'Authoritative fare calculation for private vehicle booking',
      () async {
        // Private vehicle car booking
        final quote = await pricingService.calculateAuthoritativeFare(
          originLocation: 'Catbalogan City',
          destinationLocation: 'Tacloban City',
          category: 'Car',
          passengers: 4,
          isPrivate: true,
        );

        expect(quote.isValid, isTrue);
        expect(quote.isPrivate, isTrue);
        // Private travel: base_fare + terminal_fee (fixed for vehicle, not multiplied per passenger)
        expect(quote.totalFare, 360.0); // 350 + 10
      },
    );

    test('Rejection of identical origin and destination', () async {
      final quote = await pricingService.calculateAuthoritativeFare(
        originLocation: 'Catbalogan City',
        destinationLocation: 'Catbalogan City',
        category: 'Van',
        passengers: 1,
      );

      expect(quote.isValid, isFalse);
      expect(quote.errorMessage, contains('cannot be identical'));
    });

    test('Search filtering by vehicle category', () async {
      final busResults = await searchRepository.searchTrips(
        category: 'Bus',
        availableOnly: false,
      );

      expect(busResults.isNotEmpty, isTrue);
      for (final item in busResults) {
        expect(item.category.toLowerCase(), 'bus');
      }
    });

    test('Search sorting by price ascending and descending', () async {
      final ascResults = await searchRepository.searchTrips(
        sortBy: 'price_asc',
        availableOnly: false,
      );

      for (int i = 0; i < ascResults.length - 1; i++) {
        expect(ascResults[i].fare <= ascResults[i + 1].fare, isTrue);
      }

      final descResults = await searchRepository.searchTrips(
        sortBy: 'price_desc',
        availableOnly: false,
      );

      for (int i = 0; i < descResults.length - 1; i++) {
        expect(descResults[i].fare >= descResults[i + 1].fare, isTrue);
      }
    });

    test(
      'Availability filter only returns trips with sufficient capacity',
      () async {
        final highDemandResults = await searchRepository.searchTrips(
          passengers: 10,
          availableOnly: true,
        );

        for (final item in highDemandResults) {
          expect(item.availableCapacity >= 10, isTrue);
        }
      },
    );
  });
}
