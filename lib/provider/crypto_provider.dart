import 'package:crypto_tracker/services/notification_service.dart';
import 'package:crypto_tracker/services/price_alert_database_helper.dart';
import 'package:flutter/material.dart';
import 'package:crypto_tracker/models/crypto_coin.dart';
import 'package:crypto_tracker/services/crypto_api_service.dart';

class CryptoProvider extends ChangeNotifier {
  final CryptoApiService _apiService = CryptoApiService();
  List<CryptoCoin> _coins = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _currency = 'usd';

  List<CryptoCoin> get coins => _coins;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get currency => _currency;

  Future<void> fetchCoins() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _coins = await _apiService.getCoins(_currency);
      await _checkAlerts();
    } catch (e) {
       print('COIN FETCH ERROR: $e');
      _errorMessage = 'Failed to load coins. Please try again.';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> changeCurrency(String newCurrency) async {
    _currency = newCurrency;
    await fetchCoins();
  }

  Future<void> _checkAlerts() async {
    final alerts = await PriceAlertDatabaseHelper.instance.getAlerts();

    for (final alert in alerts) {
      final matchingCoin = _coins
          .where((c) => c.id == alert.coinId)
          .firstOrNull;
      if (matchingCoin == null) continue;

      final triggered = alert.isAbove
          ? matchingCoin.currentPrice >= alert.targetPrice
          : matchingCoin.currentPrice <= alert.targetPrice;

      if (triggered) {
        await NotificationService.showNotification(
          '${alert.coinSymbol?.toUpperCase()} ${alert.isAbove ? 'Breaks' : 'Falls'}',
          '${alert.coinSymbol?.toUpperCase()} ${alert.isAbove ? 'breaks above' : 'falls below'} \$${alert.targetPrice.toStringAsFixed(2)} and is now at \$${alert.currentPrice?.toStringAsFixed(2)}.Learn More.',
        );
        await PriceAlertDatabaseHelper.instance.deleteAlert(alert.id!);
      }
    }
  }
}
