import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/services.dart';

class WalletScreen extends ConsumerStatefulWidget {
  static const route = '/wallet';
  const WalletScreen({super.key});
  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final jobIdCtrl = TextEditingController();
  final amountCtrl = TextEditingController(text: '1500');
  String result = '';

  Future<void> _intent() async {
    final api = ref.read(apiProvider);
    final res = await api.createPaymentIntent(jobIdCtrl.text.trim(), int.tryParse(amountCtrl.text.trim()) ?? 0);
    setState(() => result = res.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet / Payments')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          TextField(controller: jobIdCtrl, decoration: const InputDecoration(labelText: 'Job ID')),
          TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Amount (Rs)'), keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          FilledButton(onPressed: _intent, child: const Text('Create Payment Intent')),
          const SizedBox(height: 12),
          SelectableText(result),
        ]),
      ),
    );
  }
}
