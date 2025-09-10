import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/services.dart';
import 'job_post_screen.dart';
import 'chat_screen.dart';
import 'wallet_screen.dart';

class JobsScreen extends ConsumerStatefulWidget {
  static const route = '/jobs';
  const JobsScreen({super.key});
  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen> {
  List<dynamic> jobs = [];
  bool loading = false;
  bool showMap = true;

  Future<void> _load() async {
    setState(()=> loading = true);
    final cache = ref.read(cacheProvider);
    // show cached immediately
    final cached = await cache.loadJobs();
    if (cached.isNotEmpty) setState(()=> jobs = cached);
    try {
      final api = ref.read(apiProvider);
      final fresh = await api.listJobs(lat: 24.8607, lng: 67.0011, radius: 8000);
      if (fresh.isNotEmpty) {
        setState(()=> jobs = fresh);
        await cache.saveJobs(fresh);
      }
    } finally { if (mounted) setState(()=> loading = false); }
  }

  @override
  void initState() {
    super.initState();
    unawaited(speak('نوکریوں کی فہرست لوڈ ہو رہی ہے'));
    unawaited(_load());
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(i18nProvider);
    final settings = ref.watch(settingsProvider);
    final token = settings.mapboxToken;
    final center = const LatLng(24.8607, 67.0011);
    final markers = jobs.map((j){
      final lat = (j['lat'] ?? 24.8607) * 1.0;
      final lng = (j['lng'] ?? 67.0011) * 1.0;
      return Marker(
        width: 40, height: 40,
        point: LatLng(lat, lng),
        child: const Icon(Icons.location_pin, size: 36, color: Colors.red),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(t['jobs']!),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v)=> ref.read(settingsProvider.notifier).setLang(v),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'en', child: Text(t['english']!)),
              PopupMenuItem(value: 'ur', child: Text(t['urdu']!)),
            ],
            icon: const Icon(Icons.language),
            tooltip: t['language'],
          ),
          IconButton(
            tooltip: 'Mapbox token',
            onPressed: () async {
              final ctrl = TextEditingController(text: token);
              final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                title: const Text('Mapbox Token'),
                content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'pk.xxxxx')),
                actions: [TextButton(onPressed: ()=> Navigator.pop(context,false), child: const Text('Cancel')),
                  FilledButton(onPressed: ()=> Navigator.pop(context,true), child: const Text('Save'))],
              ));
              if (ok==true) {
                await ref.read(settingsProvider.notifier).setMapboxToken(ctrl.text.trim());
                if (mounted) setState((){});
              }
            },
            icon: const Icon(Icons.map),
          )
        ],
      ),
      body: loading && jobs.isEmpty
        ? Center(child: Text(t['loading']!))
        : Column(
          children: [
            // Map/List toggle
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  FilterChip(label: Text(t['map']!), selected: showMap, onSelected: (v)=> setState(()=> showMap = true)),
                  const SizedBox(width: 8),
                  FilterChip(label: Text(t['list']!), selected: !showMap, onSelected: (v)=> setState(()=> showMap = false)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _launchWhatsApp('+923001234567', 'MazdoorHub help needed'),
                    icon: const Icon(Icons.whatsapp),
                    tooltip: 'WhatsApp'
                  )
                ],
              ),
            ),
            Expanded(
              child: showMap
                ? FlutterMap(
                    options: MapOptions(initialCenter: center, initialZoom: 11),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token={token}',
                        additionalOptions: {'token': token},
                        userAgentPackageName: 'com.mazdoorhub.app',
                        attributionBuilder: (_) => const Text('© Mapbox © OpenStreetMap'),
                      ),
                      MarkerLayer(markers: markers),
                    ],
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      itemCount: jobs.length,
                      itemBuilder: (_, i){
                        final j = jobs[i] as Map<String,dynamic>;
                        return ListTile(
                          leading: const Icon(Icons.work),
                          title: Text('${j['category']} • Rs ${j['price']}'),
                          subtitle: Text(j['description'] ?? '—'),
                          trailing: Text((j['created_at']??'').toString().substring(0,10)),
                        );
                      },
                    ),
                  ),
            ),
          ],
        ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'post',
            onPressed: () => Navigator.pushNamed(context, JobPostScreen.route).then((_)=> _load()),
            label: Text(t['post_job']!), icon: const Icon(Icons.add)),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'chat',
            onPressed: () => Navigator.pushNamed(context, ChatScreen.route),
            label: Text(t['chat']!), icon: const Icon(Icons.chat)),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'wallet',
            onPressed: () => Navigator.pushNamed(context, WalletScreen.route),
            label: Text(t['wallet']!), icon: const Icon(Icons.account_balance_wallet)),
        ],
      ),
    );
  }
}

Future<void> _launchWhatsApp(String phone, String text) async {
  final uri = Uri.parse('https://wa.me/${phone.replaceAll('+','')}?text=${Uri.encodeComponent(text)}');
  if (await canLaunchUrl(uri)) { await launchUrl(uri, mode: LaunchMode.externalApplication); }
}
