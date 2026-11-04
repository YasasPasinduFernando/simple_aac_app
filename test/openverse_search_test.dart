import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:simple_aac_app/services/openverse_search_provider.dart';

void main() {
  group('OpenverseSearchProvider Tests', () {
    test('Correctly parses and ranks CC0 results ahead of standard CC', () async {
      final mockData = {
        'result_count': 2,
        'results': [
          {
            'id': 'img1',
            'title': 'Attribution Cat',
            'url': 'https://example.com/cat1.jpg',
            'thumbnail': 'https://example.com/thumb1.jpg',
            'creator': 'Photographer A',
            'license': 'by',
          },
          {
            'id': 'img2',
            'title': 'Public Domain Cat',
            'url': 'https://example.com/cat2.jpg',
            'thumbnail': 'https://example.com/thumb2.jpg',
            'creator': 'Photographer B',
            'license': 'cc0',
          }
        ]
      };

      final client = MockClient((request) async {
        expect(request.url.queryParameters['q'], 'cat');
        expect(request.url.queryParameters['mature'], 'false');
        expect(request.url.queryParameters['license'], contains('cc0,pdm,by'));
        return http.Response(json.encode(mockData), 200, headers: {'content-type': 'application/json'});
      });

      final provider = OpenverseSearchProvider(client);
      final results = await provider.searchImages('cat');

      expect(results.length, 2);
      // img2 (cc0) must be ranked first over img1 (by)
      expect(results.first.id, 'img2');
      expect(results.first.isPublicDomainOrCc0, isTrue);
      expect(results.last.id, 'img1');
    });

    test('Handles 429 Rate Limit with SearchRateLimitException', () async {
      final client = MockClient((request) async {
        return http.Response('Too many requests', 429);
      });

      final provider = OpenverseSearchProvider(client);
      expect(
        () => provider.searchImages('water'),
        throwsA(isA<SearchRateLimitException>()),
      );
    });

    test('Handles empty query safely', () async {
      final client = MockClient((request) async => http.Response('{}', 200));
      final provider = OpenverseSearchProvider(client);
      final results = await provider.searchImages('   ');
      expect(results, isEmpty);
    });
  });
}
