import 'package:crypto_tracker/models/price_alert.dart';
import 'package:crypto_tracker/services/price_alert_database_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/crypto_coin.dart';
import '../models/favourite_coin.dart';
import '../services/crypto_api_service.dart';
import '../services/favourites_database_helper.dart';
import 'dart:async';
import 'package:crypto_tracker/services/live_trade_service.dart';
import 'package:crypto_tracker/models/live_trade.dart';
import 'package:provider/provider.dart';
import '../provider/crypto_provider.dart';
import '../utils/currency_helper.dart';

class CoinDetailScreen extends StatefulWidget {
  final CryptoCoin coin;

  const CoinDetailScreen({super.key, required this.coin});

  @override
  State<CoinDetailScreen> createState() => _CoinDetailScreenState();
}

class _CoinDetailScreenState extends State<CoinDetailScreen> {
  bool _isFavorite = false;
  bool _hasActiveAlerts = false;
  List<double> _priceHistory = [];
  bool _isChartLoading = true;
  late CryptoCoin _currentCoin;
  final CryptoApiService _apiService = CryptoApiService();
  Timer? _refreshTimer;
  String _selectedRange = '1H';
  final LiveTradeService _tradeService = LiveTradeService();
  StreamSubscription<LiveTrade>? _tradeSubscription;
  List<LiveTrade> _liveTrades = [];

  final List<String> _ranges = [
    '1H',
    '2H',
    '4H',
    '6H',
    '8H',
    '12H',
    '3D',
    '1W',
  ];
  @override
  void initState() {
    super.initState();
    _currentCoin = widget.coin;
    _checkFavorite();
    _checkActiveAlerts();
    _loadPriceHistory();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _refreshAll();
    });
    _tradeSubscription = _tradeService
        .connect(widget.coin.symbol)
        .listen(
          (trade) {
            setState(() {
              _liveTrades.insert(0, trade);
              if (_liveTrades.length > 20) {
                _liveTrades = _liveTrades.sublist(0, 20);
              }
            });
          },
          onError: (error) {
            // Silently ignore — likely means this coin isn't listed on Binance
          },
        );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tradeSubscription?.cancel();
    _tradeService.disconnect();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    try {
      final updatedCoin = await _apiService.getCoinById(widget.coin.id);
      final history = await _apiService.getPriceHistory(
        widget.coin.id,
        _selectedRange,
      );
      setState(() {
        _currentCoin = updatedCoin;
        _priceHistory = history;
      });
    } catch (e) {
      // silently keep old data if refresh fails
    }
  }

  Future<void> _loadPriceHistory() async {
    try {
      final history = await CryptoApiService().getPriceHistory(
        widget.coin.id,
        _selectedRange,
      );
      setState(() {
        _priceHistory = history;
        _isChartLoading = false;
      });
    } catch (e) {
      setState(() {
        _isChartLoading = false;
      });
    }
  }

  Future<void> _checkFavorite() async {
    final result = await FavouritesDatabaseHelper.instance.isFavourite(
      widget.coin.id,
    );
    setState(() {
      _isFavorite = result;
    });
  }

  Future<void> _checkActiveAlerts() async {
    final alerts = await PriceAlertDatabaseHelper.instance.getAlerts();
    final hasAlert = alerts.any((alert) => alert.coinId == widget.coin.id);
    if (mounted) {
      setState(() {
        _hasActiveAlerts = hasAlert;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorite) {
      await FavouritesDatabaseHelper.instance.removeFavourite(widget.coin.id);
    } else {
      final favCoin = FavouriteCoin(
        id: widget.coin.id,
        symbol: widget.coin.symbol,
        name: widget.coin.name,
        image: widget.coin.image,
        currentPrice: widget.coin.currentPrice,
      );
      await FavouritesDatabaseHelper.instance.addFavourite(favCoin);
    }
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  Future<void> _changeRange(String range) async {
    setState(() {
      _selectedRange = range;
      _isChartLoading = true;
    });
    await _loadPriceHistory();
  }

  Future<void> _showSetAlertDialog() async {
    final controller = TextEditingController();
    bool isAbove = true;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2A1B3D),
              title: const Text(
                'Set Price Alert',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Target price',
                      labelStyle: TextStyle(color: Color(0xFFB9A9D0)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text(
                            'Above',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          value: true,
                          groupValue: isAbove,
                          activeColor: const Color(0xFFE5C687),
                          onChanged: (value) =>
                              setDialogState(() => isAbove = value!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          title: const Text(
                            'Below',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          value: false,
                          groupValue: isAbove,
                          activeColor: const Color(0xFFE5C687),
                          onChanged: (value) =>
                              setDialogState(() => isAbove = value!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFFB9A9D0)),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                  
                    final price = double.tryParse(controller.text);
                    
                    if (price != null) {
                      try {
                        await PriceAlertDatabaseHelper.instance.addAlert(
                          PriceAlert(
                            coinId: _currentCoin.id,
                            coinName: _currentCoin.name,
                            coinSymbol: _currentCoin.symbol,
                            targetPrice: price,
                            currentPrice: _currentCoin.currentPrice,
                            isAbove: isAbove,
                            imageUrl: _currentCoin.image,
                          ),
                        );
                       
                        if (context.mounted) Navigator.pop(context);
                        _checkActiveAlerts();
                      } catch (e) {
                        print('SAVE ALERT ERROR: $e');
                      }
                    } else {
                      print('PRICE IS NULL - invalid input');
                    }
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Color(0xFFE5C687)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTradeRow(LiveTrade trade) {
    final isSell = trade.isBuyerMaker;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '\$${trade.price.toStringAsFixed(2)}',
            style: TextStyle(
              color: isSell ? const Color(0xFFF08080) : const Color(0xFF5FE0A0),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          Text(
            trade.quantity.toStringAsFixed(5),
            style: const TextStyle(color: Color(0xFFB9A9D0), fontSize: 12),
          ),
          Text(
            '${trade.time.hour.toString().padLeft(2, '0')}:${trade.time.minute.toString().padLeft(2, '0')}:${trade.time.second.toString().padLeft(2, '0')}',
            style: const TextStyle(color: Color(0xFFB9A9D0), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (_isChartLoading) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFE5C687)),
        ),
      );
    }

    if (_priceHistory.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Chart unavailable',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _priceHistory
                  .asMap()
                  .entries
                  .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
                  .toList(),
              isCurved: true,
              color: const Color(0xFFE5C687),
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0x26E5C687),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = widget.coin.priceChangePercentage24h >= 0;
    final cryptoProvider = Provider.of<CryptoProvider>(context);
    final symbol = currencySymbol(cryptoProvider.currency);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1030),
      appBar: AppBar(
        title: Text(widget.coin.symbol.toUpperCase()),
        backgroundColor: const Color(0xFF1A1030),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star : Icons.star_border,
              color: const Color(0xFFE5C687),
            ),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: Icon(
              _hasActiveAlerts
                  ? Icons.notifications
                  : Icons.notifications_outlined,
              color: const Color(0xFFE5C687),
            ),
            onPressed: _showSetAlertDialog,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A1B3D), Color(0xFF1A1030)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipOval(
                    child: Image.network(
                      widget.coin.image,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${widget.coin.name}',
                    style: const TextStyle(
                      color: Color(0xFFB9A9D0),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                '$symbol${_currentCoin.currentPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE5C687),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isPositive
                      ? const Color(0x2634C759)
                      : const Color(0x26E04949),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${isPositive ? '+' : ''}${widget.coin.priceChangePercentage24h.toStringAsFixed(2)}% (24h)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isPositive
                        ? const Color(0xFF5FE0A0)
                        : const Color(0xFFF08080),
                  ),
                ),
              ),
              SizedBox(
                height: 55,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _ranges.map((range) {
                    final isSelected = range == _selectedRange;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(range),
                        selected: isSelected,
                        onSelected: (_) => _changeRange(range),
                        backgroundColor: const Color(0xFF2A1B3D),
                        selectedColor: const Color(0xFFE5C687),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFFE5C687)
                                : const Color(0xFFE5C687).withOpacity(0.4),
                          ),
                        ),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFF1A1030)
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              _buildChart(),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
                children: [
                  _statCard(
                    'Market Cap',
                    '$symbol${_formatLargeNumber(_currentCoin.marketCap)}',
                  ),
                  _statCard(
                    '24h Volume',
                    '$symbol${_formatLargeNumber(_currentCoin.totalVolume)}',
                  ),
                  _statCard(
                    '24h High',
                    '$symbol${_currentCoin.high24h.toStringAsFixed(2)}',
                  ),
                  _statCard(
                    '24h Low',
                    '$symbol${_currentCoin.low24h.toStringAsFixed(2)}',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Live Trades',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              if (_liveTrades.isEmpty)
                const Text(
                  'Waiting for live trades... (unavailable for some coins)',
                  style: TextStyle(color: Color(0xFFB9A9D0), fontSize: 12),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE5C687).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: _liveTrades
                        .map((trade) => _buildTradeRow(trade))
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5C687).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFFB9A9D0), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLargeNumber(double number) {
    if (number >= 1e9) return '${(number / 1e9).toStringAsFixed(2)}B';
    if (number >= 1e6) return '${(number / 1e6).toStringAsFixed(2)}M';
    return number.toStringAsFixed(2);
  }
}
