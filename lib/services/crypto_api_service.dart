import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto_tracker/models/crypto_coin.dart';

class CryptoApiService {
  static const String _baseUrl = 'https://api.coingecko.com/api/v3';
 Future<List<CryptoCoin>> getCoins(String currency) async {
  final url = Uri.parse(
    '$_baseUrl/coins/markets?vs_currency=$currency&order=market_cap_desc&per_page=250&page=1',
  );

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => CryptoCoin.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load coins');
  }
}

  Future<List<double>> getPriceHistory(String coinId, String range) async {
    int days;
    int? trimToPoints;

    switch (range) {
      case '1H':
        days = 1;
        trimToPoints = 12;
        break;
      case '2H':
        days = 1;
        trimToPoints = 24;
        break;
      case '4H':
        days = 1;
        trimToPoints = 48;
        break;
      case '6H':
        days = 1;
        trimToPoints = 72;
        break;
      case '8H':
        days = 1;
        trimToPoints = 96;
        break;
      case '12H':
        days = 1;
        trimToPoints = 144;
        break;
      case '3D':
        days = 3;
        trimToPoints = null;
        break;
      case '1W':
        days = 7;
        trimToPoints = null;
        break;
      default:
        days = 1;
        trimToPoints = 144;
    }

    final url = Uri.parse(
      '$_baseUrl/coins/$coinId/market_chart?vs_currency=usd&days=$days',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> prices = data['prices'];
      final allPrices = prices
          .map((point) => (point[1] as num).toDouble())
          .toList();

      if (trimToPoints != null && allPrices.length > trimToPoints) {
        return allPrices.sublist(allPrices.length - trimToPoints);
      }
      return allPrices;
    } else {
      throw Exception('Failed to load price history');
    }
  }

  Future<CryptoCoin> getCoinById(String coinId) async {
    final url = Uri.parse(
      '$_baseUrl/coins/markets?vs_currency=usd&ids=$coinId',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return CryptoCoin.fromJson(data.first);
    } else {
      throw Exception('Failed to refresh coin data');
    }
  }
}
