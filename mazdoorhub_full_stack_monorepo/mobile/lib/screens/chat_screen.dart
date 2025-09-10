import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  static const route = '/chat';
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late WebSocketChannel _channel;
  final _ctrl = TextEditingController();
  final List<String> _log = [];

  @override
  void initState() {
    super.initState();
    const wsUrl = String.fromEnvironment('WS_URL', defaultValue: 'ws://localhost:3001');
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    _channel.stream.listen((event) async {
      setState(() { _log.add('← $event'); });
      await _persist();
    });
    _restore();
  }

  Future<void> _restore() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('chat_log'); if (raw==null) return;
    setState(() => _log.addAll(List<String>.from(jsonDecode(raw))));
  }

  Future<void> _persist() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('chat_log', jsonEncode(_log));
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  void _send() async {
    if (_ctrl.text.isEmpty) return;
    final msg = jsonEncode({'type':'message','text':_ctrl.text});
    _channel.sink.add(msg);
    setState(() => _log.add('→ ${_ctrl.text}'));
    _ctrl.clear();
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat (MVP)')),
      body: Column(children: [
        Expanded(child: ListView.builder(itemCount: _log.length, itemBuilder: (_,i)=> ListTile(title: Text(_log[i])))),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(children:[
            Expanded(child: TextField(controller:_ctrl, decoration: const InputDecoration(hintText:'Type message'))),
            IconButton(onPressed:_send, icon: const Icon(Icons.send))
          ]),
        )
      ]),
    );
  }
}
