import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

typedef Json = Map<String, Object?>;

class Artwork {
  Artwork(Json json)
    : id = json['id'] as int,
      title = json['title'] as String,
      artist = json['artist'] as String,
      period = json['period'] as String,
      imageUrl = json['imageUrl'] as String;

  final int id;
  final String title, artist, period, imageUrl;
}

class Exhibition {
  Exhibition(Json json)
    : id = json['id'] as String,
      title = json['title'] as String,
      artworkIds = (json['artworkIds'] as List<Object?>).cast<int>();

  final String id, title;
  final List<int> artworkIds;
}

class MuseumApi {
  static String get _base =>
      const String.fromEnvironment('MUSEUM_API').isNotEmpty
      ? const String.fromEnvironment('MUSEUM_API')
      : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? 'http://10.0.2.2:8091'
      : 'http://127.0.0.1:8091';

  Future<List<Artwork>> artworks() async =>
      (await _list('artworks')).map(Artwork.new).toList();

  Future<List<Exhibition>> exhibitions() async =>
      (await _list('exhibitions')).map(Exhibition.new).toList();

  Future<List<Json>> _list(String path) async {
    final response = await _send('GET', path);
    return (jsonDecode(response) as List<Object?>).cast<Json>();
  }

  Future<void> save(String? id, String title, List<int> ids) async {
    await _send(
      id == null ? 'POST' : 'PUT',
      id == null ? 'exhibitions' : 'exhibitions/$id',
      {'title': title, 'artworkIds': ids},
    );
  }

  Future<void> delete(String id) async {
    await _send('DELETE', 'exhibitions/$id');
  }

  Future<String> _send(String method, String path, [Json? body]) async {
    final client = http.Client();
    try {
      final request = http.Request(method, Uri.parse('$_base/api/$path'));
      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(body);
      }
      final response = await client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode >= 400) {
        throw http.ClientException('HTTP ${response.statusCode}', request.url);
      }
      return utf8.decode(response.bodyBytes);
    } finally {
      client.close();
    }
  }
}
