class FavouriteCoin {
  final String id;
  final String name;
  final String symbol;
  final String image;
  final double currentPrice;
  FavouriteCoin({
    required this.id,
    required this.name,
    required this.symbol,
    required this.image,
    required this.currentPrice,
  });
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'symbol': symbol,
      'image': image,
      'currentPrice': currentPrice,
    };
  }

  factory FavouriteCoin.fromMap(Map<String, dynamic> map) {
    return FavouriteCoin(
      id: map['id'],
      name: map['name'],
      symbol: map['symbol'],
      image: map['image'],
      currentPrice: map['currentPrice'],
    );
  }
}
