import 'dart:convert';
import 'package:crypto_tracker/models/live_trade.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class LiveTradeService {
  WebSocketChannel? _channel;

  Stream<LiveTrade> connect(String symbol) {
    final wsUrl = Uri.parse(
      'wss://stream.binance.com:9443/ws/${symbol.toLowerCase()}usdt@trade',
    );
    _channel = WebSocketChannel.connect(wsUrl);

    return _channel!.stream.map((message) {
      final data = jsonDecode(message);
      return LiveTrade.fromJson(data);
    });
  }

  void disconnect() {
    _channel?.sink.close();
  }
}
