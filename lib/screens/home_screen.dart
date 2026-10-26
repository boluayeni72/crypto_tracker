import 'package:crypto_tracker/utils/currency_helper.dart';
import 'package:flutter/material.dart';
import 'package:crypto_tracker/provider/crypto_provider.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'coin_detail_screen.dart';
import 'alerts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<CryptoProvider>(context, listen: false).fetchCoins(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 100, height: 14, color: Colors.white),
                const SizedBox(height: 6),
                Container(width: 60, height: 12, color: Colors.white),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(width: 70, height: 14, color: Colors.white),
              const SizedBox(height: 6),
              Container(width: 50, height: 12, color: Colors.white),
            ],
          ),
        ],
      ),
    );
  }
  Future<void> refreshCoins() async {
  await Provider.of<CryptoProvider>(context, listen: false).fetchCoins();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1030),
      appBar: AppBar(
        title: const Text('Crypto Tracker'),
        backgroundColor: const Color(0xFF1A1030),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.currency_exchange, color: Color(0xFFE5C687)),
            color: const Color(0xFF2A1B3D),
            onSelected: (value) {
              Provider.of<CryptoProvider>(
                context,
                listen: false,
              ).changeCurrency(value);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'usd',
                child: Text('USD', style: TextStyle(color: Colors.white)),
              ),
              PopupMenuItem(
                value: 'eur',
                child: Text('EUR', style: TextStyle(color: Colors.white)),
              ),
              PopupMenuItem(
                value: 'gbp',
                child: Text('GBP', style: TextStyle(color: Colors.white)),
              ),
              PopupMenuItem(
                value: 'ngn',
                child: Text('NGN', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFFE5C687),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AlertsScreen()),
              );
            },
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE5C687).withOpacity(0.2),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 17),
                  decoration: InputDecoration(
                    hintText: 'Search coins...',
                    hintStyle: const TextStyle(
                      color: Color(0xFFB9A9D0),
                      fontSize: 17,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFFE5C687),
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xFFB9A9D0),
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
            ),
            Expanded(
              child: Consumer<CryptoProvider>(
                builder: (context, cryptoProvider, child) {
                  if (cryptoProvider.isLoading) {
                    return Shimmer.fromColors(
                      baseColor: Colors.white.withOpacity(0.06),
                      highlightColor: Colors.white.withOpacity(0.2),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        itemCount: 8,
                        itemBuilder: (context, index) => _buildShimmerCard(),
                      ),
                    );
                  }
                  if (cryptoProvider.errorMessage != null) {
                    return RefreshIndicator(
                      color: const Color(0xFFE5C687),
                      backgroundColor: const Color(0xFF2A1B3D),
                      onRefresh: () => cryptoProvider.fetchCoins(),
                      child: ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: Center(
                              child: Text(
                                cryptoProvider.errorMessage!,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final filteredCoins = _searchQuery.isEmpty
                      ? cryptoProvider.coins
                      : cryptoProvider.coins.where((coin) {
                          return coin.name.toLowerCase().contains(
                                _searchQuery,
                              ) ||
                              coin.symbol.toLowerCase().contains(_searchQuery);
                        }).toList();

                  if (filteredCoins.isEmpty) {
                    return Center(
                      child: Text(
                        'No coins found for "$_searchQuery"',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: const Color(0xFFE5C687),
                    backgroundColor: const Color(0xFF2A1B3D),
                    onRefresh: () => cryptoProvider.fetchCoins(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: filteredCoins.length,
                      itemBuilder: (context, index) {
                        final coin = filteredCoins[index];
                        final isPositive = coin.priceChangePercentage24h >= 0;
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFE5C687).withOpacity(0.25),
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CoinDetailScreen(coin: coin),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                ClipOval(
                                  child: Image.network(
                                    coin.image,
                                    width: 42,
                                    height: 42,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        coin.name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        coin.symbol.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFB9A9D0),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${currencySymbol(cryptoProvider.currency)}${coin.currentPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFE5C687),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isPositive
                                            ? const Color(0x2634C759)
                                            : const Color(0x26E04949),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${isPositive ? '+' : ''}${coin.priceChangePercentage24h.toStringAsFixed(2)}%',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isPositive
                                              ? const Color(0xFF5FE0A0)
                                              : const Color(0xFFF08080),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
