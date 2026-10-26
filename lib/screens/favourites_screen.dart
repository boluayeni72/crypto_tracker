import 'package:flutter/material.dart';
import '../models/favourite_coin.dart';
import '../services/favourites_database_helper.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => FavouritesScreenState();
}

class FavouritesScreenState extends State<FavouritesScreen> {
  List<FavouriteCoin> _favourites = [];

  @override
  void initState() {
    super.initState();
    loadFavourites();
  }

  Future<void> loadFavourites() async {
    final favourites = await FavouritesDatabaseHelper.instance.getFavourites();
    setState(() {
      _favourites = favourites;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1030),
      appBar: AppBar(
        title: const Text('Watchlist'),
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
        child: _favourites.isEmpty
            ? const Center(
                child: Text(
                  'No favourites yet',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : RefreshIndicator(
                color: const Color(0xFFE5C687),
                backgroundColor: const Color(0xFF2A1B3D),
                onRefresh: loadFavourites,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: _favourites.length,
                  itemBuilder: (context, index) {
                    final coin = _favourites[index];
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                          Text(
                            '\$${coin.currentPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE5C687),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () async {
                              await FavouritesDatabaseHelper.instance
                                  .removeFavourite(coin.id);
                              loadFavourites();
                            },
                            icon: const Icon(
                              Icons.star,
                              color: Color(0xFFF08080),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
