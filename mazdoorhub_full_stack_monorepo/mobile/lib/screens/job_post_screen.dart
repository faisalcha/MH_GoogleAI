import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/services.dart';

class JobPostScreen extends ConsumerStatefulWidget {
  static const route = '/post';
  const JobPostScreen({super.key});
  @override
  ConsumerState<JobPostScreen> createState() => _JobPostScreenState();
}

class _JobPostScreenState extends ConsumerState<JobPostScreen> {
  final formKey = GlobalKey<FormState>();
  final catCtrl = TextEditingController(text: 'Plumbing');
  final priceCtrl = TextEditingController(text: '1500');
  final descCtrl = TextEditingController();

  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) return;
    final api = ref.read(apiProvider);
    final payload = {
      'employer_user_id': '00000000-0000-0000-0000-000000000001',
      'category': catCtrl.text.trim(),
      'price': int.tryParse(priceCtrl.text.trim()) ?? 0,
      'lat': 24.8607,
      'lng': 67.0011,
      'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
    };
    final res = await api.createJob(payload);
    if (context.mounted) {
      final t = ref.read(i18nProvider);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${t['job_created']}: ${res['id']}')));
      await speak('نوکری بن گئی');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(i18nProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t['create_job']!)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(controller: catCtrl, decoration: InputDecoration(labelText: t['category']!), validator: (v)=> v==null||v.isEmpty?'Required':null),
              TextFormField(controller: priceCtrl, decoration: InputDecoration(labelText: t['price']!), keyboardType: TextInputType.number, validator: (v)=> v==null||v.isEmpty?'Required':null),
              TextFormField(controller: descCtrl, decoration: InputDecoration(labelText: t['description']!)),
              const SizedBox(height: 20),
              FilledButton(onPressed: _submit, child: Text(t['create_job']!))
            ],
          ),
        ),
      ),
    );
  }
}
