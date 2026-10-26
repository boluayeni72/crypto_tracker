class NewsArticle {
  final String title;
  final String url;
  final String source;
  final DateTime publishedOn;
  final String imageUrl;

  NewsArticle({
    required this.title,
    required this.url,
    required this.source,
    required this.publishedOn,
    this.imageUrl = '',
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] as String? ?? 'Untitled',
      url: json['link'] as String? ?? '',
      source: json['source'] as String? ?? 'Unknown',
      publishedOn: DateTime.tryParse(json['pubDate'] as String? ?? '') ?? DateTime.now(),
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }
}