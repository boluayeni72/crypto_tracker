import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/price_alert.dart';
import '../services/price_alert_database_helper.dart';
import '../provider/crypto_provider.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<PriceAlert> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
    });
    final alerts = await PriceAlertDatabaseHelper.instance.getAlerts();
    setState(() {
      _alerts = alerts;
      _isLoading = false;
    });
  }

  Future<void> _deleteAlert(int id) async {
    await PriceAlertDatabaseHelper.instance.deleteAlert(id);
    _loadAlerts();
  }

  Future<void> _showEditAlertDialog(PriceAlert alert) async {
    final controller = TextEditingController(
      text: alert.targetPrice.toString(),
    );
    bool isAbove = alert.isAbove;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2A1B3D),
              title: Text(
                'Edit Alert — ${alert.coinSymbol?.toUpperCase() ?? alert.coinName}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
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
                      await PriceAlertDatabaseHelper.instance.updateAlert(
                        PriceAlert(
                          id: alert.id,
                          coinId: alert.coinId,
                          coinName: alert.coinName,
                          coinSymbol: alert.coinSymbol,
                          targetPrice: price,
                          currentPrice: alert.currentPrice,
                          isAbove: isAbove,
                          imageUrl: alert.imageUrl,
                        ),
                      );
                      if (context.mounted) Navigator.pop(context);
                      _loadAlerts();
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

  double? _liveCurrentPrice(CryptoProvider provider, PriceAlert alert) {
    try {
      final coin = provider.coins.firstWhere((c) => c.id == alert.coinId);
      return coin.currentPrice;
    } catch (e) {
      return alert.currentPrice;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cryptoProvider = Provider.of<CryptoProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1030),
      appBar: AppBar(
        title: const Text('Price Alerts'),
        backgroundColor: const Color(0xFF1A1030),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A1B3D), Color(0xFF1A1030)],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFE5C687)),
              )
            : _alerts.isEmpty
                ? const Center(
                    child: Text(
                      'No alerts set yet.',
                      style: TextStyle(color: Color(0xFFB9A9D0)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _alerts.length,
                    itemBuilder: (context, index) {
                      final alert = _alerts[index];
                      final accentColor = alert.isAbove
                          ? const Color(0xFF5FE0A0)
                          : const Color(0xFFF08080);
                      final liveCurrent = _liveCurrentPrice(cryptoProvider, alert);

                      double progress = 0;
                      if (liveCurrent != null && liveCurrent > 0 && alert.targetPrice > 0) {
                        if (alert.isAbove) {
                          progress = (liveCurrent / alert.targetPrice).clamp(0.0, 1.0);
                        } else {
                          progress = (alert.targetPrice / liveCurrent).clamp(0.0, 1.0);
                        }
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: accentColor.withOpacity(0.5),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ClipOval(
                                  child: (alert.imageUrl != null && alert.imageUrl!.isNotEmpty)
                                      ? Image.network(
                                          alert.imageUrl!,
                                          width: 36,
                                          height: 36,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              Container(
                                            width: 36,
                                            height: 36,
                                            color: const Color(0xFF2A1B3D),
                                            child: const Icon(
                                              Icons.currency_bitcoin,
                                              color: Color(0xFFE5C687),
                                              size: 20,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          width: 36,
                                          height: 36,
                                          color: const Color(0xFF2A1B3D),
                                          child: const Icon(
                                            Icons.currency_bitcoin,
                                            color: Color(0xFFE5C687),
                                            size: 20,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        alert.coinName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        alert.coinSymbol?.toUpperCase() ?? '',
                                        style: const TextStyle(
                                          color: Color(0xFFB9A9D0),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        alert.isAbove
                                            ? Icons.arrow_upward
                                            : Icons.arrow_downward,
                                        color: accentColor,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        alert.isAbove ? 'Above' : 'Below',
                                        style: TextStyle(
                                          color: accentColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Current',
                                      style: TextStyle(
                                        color: Color(0xFFB9A9D0),
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      liveCurrent != null
                                          ? '\$${liveCurrent.toStringAsFixed(2)}'
                                          : '—',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white.withOpacity(0.3),
                                  size: 16,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Target',
                                      style: TextStyle(
                                        color: Color(0xFFB9A9D0),
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      '\$${alert.targetPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Color(0xFFE5C687),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: Colors.white.withOpacity(0.08),
                                color: accentColor,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Color(0xFFE5C687),
                                    size: 20,
                                  ),
                                  onPressed: () => _showEditAlertDialog(alert),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Color(0xFFF08080),
                                    size: 20,
                                  ),
                                  onPressed: () => _deleteAlert(alert.id!),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}