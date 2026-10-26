import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dart_rss/dart_rss.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:intl/intl.dart';
import '../models/news_article.dart';

class NewsApiService {
  final _unescape = HtmlUnescape();
  final _dateFormat = DateFormat('EEE, dd MMM yyyy HH:mm:ss Z');

  Future<List<NewsArticle>> getNews() async {
    final url = Uri.parse('https://www.coindesk.com/arc/outboundfeeds/rss/');

    try {
      final response = await http.get(url);

      print('STATUS CODE: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final rssFeed = RssFeed.parse(body);
        final items = rssFeed.items;

        print('ARTICLES RETURNED: ${items.length}');

        return items.take(50).map((item) {
          final cleanTitle = _unescape.convert(item.title ?? 'Untitled');
          final publishedDate = _parseDate(item.pubDate?.toString() ?? '');
          final imageUrl = _extractImageUrl(item);

          return NewsArticle(
            title: cleanTitle,
            url: item.link ?? '',
            source: 'CoinDesk',
            publishedOn: publishedDate,
            imageUrl: imageUrl,
          );
        }).toList();
      } else {
        throw Exception('Failed to fetch news');
      }
    } catch (e) {
      print('ERROR: $e');
      rethrow;
    }
  }

  DateTime _parseDate(String dateString) {
    try {
      return _dateFormat.parse(dateString);
    } catch (e) {
      return DateTime.now();
    }
  }

  String _extractImageUrl(RssItem item) {
    try {
      // Try media:content first (CoinDesk primary method)
      if (item.media?.contents != null && item.media!.contents.isNotEmpty) {
        final content = item.media!.contents.first;
        if (content.url != null && content.url!.isNotEmpty) {
          return content.url!;
        }
      }

      // Try media:thumbnail
      if (item.media?.thumbnails != null && item.media!.thumbnails.isNotEmpty) {
        final thumbnail = item.media!.thumbnails.first;
        if (thumbnail.url != null && thumbnail.url!.isNotEmpty) {
          return thumbnail.url!;
        }
      }

      // Try enclosure tag
      final enclosureUrl = item.enclosure?.url;
      if (enclosureUrl != null && enclosureUrl.isNotEmpty) {
        return enclosureUrl;
      }

      // Extract from description HTML as last resort
      final description = item.description;
      if (description != null && description.isNotEmpty) {
        final imgRegex = RegExp(r'<img[^>]+src="([^">]+)"');
        final match = imgRegex.firstMatch(description);
        final imageUrl = match?.group(1);
        if (imageUrl != null && imageUrl.isNotEmpty) {
          return imageUrl;
        }
      }

      return '';
    } catch (e) {
      print('IMAGE EXTRACTION ERROR: $e');
      return '';
    }
  }
}
