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

    test('Multi-source search filters noise, deduplicates photos, and mixes AAC symbols', () async {
      final client = MockClient((request) async {
        final host = request.url.host;
        final q = request.url.queryParameters['gsrsearch'] ?? '';
        if (host == 'api.arasaac.org') {
          return http.Response(
            json.encode([
              {
                '_id': 6911,
                'aac': true,
                'keywords': [
                  {'keyword': 'rice'},
                ],
              },
              {
                '_id': 9999,
                'aac': false,
                'keywords': [
                  {'keyword': 'unrelated yacht'},
                ],
              },
            ]),
            200,
          );
        }
        if (host == 'simple.wikipedia.org' || host == 'en.wikipedia.org') {
          expect(q, 'rice');
          return http.Response(
            json.encode({
              'query': {
                'pages': {
                  '2': {
                    'pageid': 2,
                    'index': 2,
                    'title': 'Condoleezza Rice',
                    'description': 'American diplomat and politician',
                    'thumbnail': {'source': 'https://thumb.wikimedia.org/condo.jpg'},
                    'original': {'source': 'https://upload.wikimedia.org/condo.jpg'},
                  },
                  '1': {
                    'pageid': 1,
                    'index': 1,
                    'title': 'Rice',
                    'description': 'cereal grain and staple food',
                    'thumbnail': {'source': 'https://thumb.wikimedia.org/500px-Rice_Bowl.jpg'},
                    'original': {'source': 'https://upload.wikimedia.org/Rice_Bowl.jpg'},
                  },
                },
              },
            }),
            200,
          );
        }
        if (host == 'commons.wikimedia.org') {
          return http.Response(
            json.encode({
              'query': {
                'pages': {
                  '10': {
                    'pageid': 10,
                    'index': 2,
                    'title': 'File:Bath_panorama.jpg',
                    'imageinfo': [
                      {
                        'mime': 'image/jpeg',
                        'url': 'https://upload.wikimedia.org/Bath_panorama.jpg',
                        'thumburl': 'https://thumb.wikimedia.org/Bath_panorama.jpg',
                      }
                    ],
                  },
                  '11': {
                    'pageid': 11,
                    'index': 1,
                    'title': 'File:Cooked_white_rice.jpg',
                    'imageinfo': [
                      {
                        'mime': 'image/jpeg',
                        'url': 'https://upload.wikimedia.org/Cooked_white_rice.jpg',
                        'thumburl': 'https://thumb.wikimedia.org/Cooked_white_rice.jpg',
                      }
                    ],
                  },
                },
              },
            }),
            200,
          );
        }
        return http.Response('{}', 504);
      });

      final provider = OpenverseSearchProvider(client, true);
      final results = await provider.searchImages('rice');

      expect(results.any((r) => r.title.contains('Condoleezza')), isFalse);
      expect(results.any((r) => r.title.contains('Bath panorama')), isFalse);
      expect(results.any((r) => r.id == 'arasaac_9999'), isFalse);
      // Duplicate Rice_Bowl across SimpleWiki & EnWiki is collapsed into one entry.
      expect(results.where((r) => r.imageUrl.contains('Rice_Bowl.jpg')).length, 1);
      expect(results.any((r) => r.id == 'arasaac_6911' && r.isSymbol), isTrue);
      expect(results.any((r) => r.imageUrl.contains('Cooked_white_rice.jpg')), isTrue);
    });

    test('Multi-source search bridges unmapped Sinhala query via Wikipedia langlinks', () async {
      final client = MockClient((request) async {
        final host = request.url.host;
        if (host == 'si.wikipedia.org') {
          return http.Response(
            json.encode({
              'query': {
                'pages': {
                  '55': {
                    'pageid': 55,
                    'index': 1,
                    'title': 'කිරිබත්',
                    'langlinks': [
                      {'lang': 'en', '*': 'Kiribath'},
                    ],
                    'thumbnail': {'source': 'https://thumb.wikimedia.org/Kiribath.jpg'},
                    'original': {'source': 'https://upload.wikimedia.org/Kiribath.jpg'},
                  },
                },
              },
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (host == 'en.wikipedia.org' || host == 'simple.wikipedia.org') {
          expect(request.url.queryParameters['gsrsearch'], 'kiribath');
          return http.Response('{"query": {"pages": {}}}', 200);
        }
        return http.Response('[]', 200);
      });

      final provider = OpenverseSearchProvider(client, true);
      final results = await provider.searchImages('කිරිබත්');

      expect(results.length, 1);
      expect(results.first.title, 'Kiribath');
      expect(results.first.imageUrl, 'https://upload.wikimedia.org/Kiribath.jpg');
    });
  });
}
