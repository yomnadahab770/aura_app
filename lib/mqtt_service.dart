import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class MqttService {
  static final MqttService _instance = MqttService._internal();
  factory MqttService() => _instance;
  MqttService._internal();

  WebSocketChannel? _channel;
  Function(Map<String, dynamic>)? onAlertReceived;

  Future<void> connect() async {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('wss://broker.hivemq.com:8884/mqtt'),
      );

      // إرسال CONNECT packet
      _channel!.sink.add(_buildConnectPacket());

      // الاشتراك في التوبيك بعد ثانية
      Future.delayed(const Duration(seconds: 1), () {
        _channel!.sink.add(_buildSubscribePacket('aura/alerts'));
        print('✅ Subscribed to aura/alerts');
      });

      // استقبال الرسائل
      _channel!.stream.listen((data) {
        try {
          if (data is List<int>) {
            final payload = _extractPayload(data);
            if (payload != null) {
              final json = jsonDecode(payload);
              if (onAlertReceived != null) {
                onAlertReceived!(json);
              }
            }
          }
        } catch (e) {
          print('Error: $e');
        }
      });

      print('✅ WebSocket Connected');
    } catch (e) {
      print('❌ Connection Failed: $e');
    }
  }

  List<int> _buildConnectPacket() {
    final clientId = 'aura_flutter_${DateTime.now().millisecondsSinceEpoch}';
    final clientIdBytes = utf8.encode(clientId);
    final payload = [
      0x00, 0x04, 0x4D, 0x51, 0x54, 0x54, // MQTT
      0x04, 0x02, 0x00, 0x3C, // version, flags, keepalive
      0x00, clientIdBytes.length,
      ...clientIdBytes,
    ];
    return [0x10, payload.length, ...payload];
  }

  List<int> _buildSubscribePacket(String topic) {
    final topicBytes = utf8.encode(topic);
    final payload = [0x00, 0x01, 0x00, topicBytes.length, ...topicBytes, 0x00];
    return [0x82, payload.length, ...payload];
  }

  String? _extractPayload(List<int> data) {
    try {
      if (data[0] != 0x30) return null;
      int topicLength = (data[2] << 8) | data[3];
      int payloadStart = 4 + topicLength;
      final payloadBytes = data.sublist(payloadStart);
      return utf8.decode(payloadBytes);
    } catch (e) {
      return null;
    }
  }

  void disconnect() {
    _channel?.sink.close();
  }
}
