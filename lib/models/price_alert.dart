class PriceAlert {
  final int? id;
  final String coinId;
  final String coinName;
  final String? coinSymbol;
  final double targetPrice;
  final double? currentPrice;
  final bool isAbove;
  final String? imageUrl;

  PriceAlert({
    this.id,
    required this.coinId,
    required this.coinName,
    this.coinSymbol,
    required this.targetPrice,
    this.currentPrice,
    required this.isAbove,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'coinId': coinId,
      'coinName': coinName,
      'coinSymbol': coinSymbol,
      'targetPrice': targetPrice,
      'currentPrice': currentPrice,
      'isAbove': isAbove ? 1 : 0,
      'imageUrl': imageUrl,
    };
  }

  factory PriceAlert.fromMap(Map<String, dynamic> map) {
    return PriceAlert(
      id: map['id'],
      coinId: map['coinId'],
      coinName: map['coinName'],
      coinSymbol: map['coinSymbol'],
      targetPrice: map['targetPrice'],
      currentPrice: map['currentPrice'],
      isAbove: map['isAbove'] == 1,
      imageUrl: map['imageUrl'],
    );
  }
}