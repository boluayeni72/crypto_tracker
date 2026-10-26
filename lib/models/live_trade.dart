class LiveTrade {
  final double price;
  final double quantity;
  final bool isBuyerMaker;
  final DateTime time;

  LiveTrade({
    required this.price,
    required this.quantity,
    required this.isBuyerMaker,
    required this.time,
  });

  factory LiveTrade.fromJson(Map<String, dynamic> json) {
    return LiveTrade(
      price: double.parse(json['p']),
      quantity: double.parse(json['q']),
      isBuyerMaker: json['m'],
      time: DateTime.fromMillisecondsSinceEpoch(json['T']),
    );
  }
}
