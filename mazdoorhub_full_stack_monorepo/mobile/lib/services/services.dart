import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------- Settings / Language ----------
class AppSettings {
  final Locale locale;
  final bool rtl;
  final String mapboxToken;
  const AppSettings({required this.locale, required this.rtl, required this.mapboxToken});
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(): super(const AppSettings(locale: Locale('en'), rtl:false, mapboxToken: '')){
    _load();
  }
  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    final lang = sp.getString('lang') ?? 'en';
    final token = sp.getString('mapbox') ?? '';
    state = AppSettings(locale: Locale(lang), rtl: lang=='ur', mapboxToken: token);
  }
  Future<void> setLang(String lang) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('lang', lang);
    state = AppSettings(locale: Locale(lang), rtl: lang=='ur', mapboxToken: state.mapboxToken);
  }
  Future<void> setMapboxToken(String token) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('mapbox', token);
    state = AppSettings(locale: state.locale, rtl: state.rtl, mapboxToken: token);
  }
}
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref)=> SettingsNotifier());

// ---------- Simple i18n loader ----------
final i18nProvider = Provider<Map<String,String>>((ref){
  final loc = ref.watch(settingsProvider).locale.languageCode;
  // In real app, load from ARB; here we read embedded assets at build time
  const en = {"app_title": "MazdoorHub", "jobs": "Jobs", "post_job": "Post Job", "chat": "Chat", "wallet": "Wallet", "create_job": "Create Job", "category": "Category", "price": "Price (Rs)", "description": "Description (optional)", "map": "Map", "list": "List", "loading": "Loading...", "job_created": "Job created", "language": "Language", "english": "English", "urdu": "Urdu"};
  const ur = {"app_title": "\u0645\u0632\u062f\u0648\u0631 \u06c1\u0628", "jobs": "\u0646\u0648\u06a9\u0631\u06cc\u0627\u06ba", "post_job": "\u0646\u0626\u06cc \u0646\u0648\u06a9\u0631\u06cc", "chat": "\u0686\u06cc\u0679", "wallet": "\u0648\u0627\u0644\u06cc\u0679", "create_job": "\u0646\u0648\u06a9\u0631\u06cc \u0628\u0646\u0627\u0626\u06cc\u06ba", "category": "\u06a9\u06cc\u0679\u06cc\u06af\u0631\u06cc", "price": "\u0642\u06cc\u0645\u062a (\u0631\u0648\u067e\u06d2)", "description": "\u062a\u0641\u0635\u06cc\u0644 (\u0627\u062e\u062a\u06cc\u0627\u0631\u06cc)", "map": "\u0646\u0642\u0634\u06c1", "list": "\u0641\u06c1\u0631\u0633\u062a", "loading": "\u0644\u0648\u0688 \u06c1\u0648 \u0631\u06c1\u0627 \u06c1\u06d2...", "job_created": "\u0646\u0648\u06a9\u0631\u06cc \u0628\u0646 \u06af\u0626\u06cc", "language": "\u0632\u0628\u0627\u0646", "english": "\u0627\u0646\u06af\u0631\u06cc\u0632\u06cc", "urdu": "\u0627\u0631\u062f\u0648"};
  return loc=='ur' ? ur : en;
});

// ---------- TTS ----------
final tts = FlutterTts();
Future<void> speak(String text) async {
  try {
    await tts.setLanguage('ur-PK');
    await tts.setSpeechRate(0.5);
    await tts.speak(text);
  } catch (_) {}
}

// ---------- API ----------
class ApiService {
  final Dio _dio;
  final String baseUrl;
  ApiService(this.baseUrl) : _dio = Dio(BaseOptions(baseUrl: baseUrl));
  Future<List<dynamic>> listJobs({required double lat, required double lng, int radius=5000}) async {
    try {
      final res = await _dio.get('/jobs', queryParameters: {'lat':lat,'lng':lng,'radius':radius});
      return (res.data as List).cast<dynamic>();
    } catch (_) {
      return []; // network fail: let caller load cache
    }
  }
  Future<Map<String,dynamic>> createJob(Map<String,dynamic> payload) async {
    final res = await _dio.post('/jobs', data: payload);
    return (res.data as Map<String,dynamic>);
  }
  Future<Map<String,dynamic>> createPaymentIntent(String jobId, int amount) async {
    final res = await _dio.post('/payments/intent', data: {'job_id': jobId, 'amount': amount, 'method':'HOSTED'});
    return (res.data as Map<String,dynamic>);
  }
}
final apiProvider = Provider<ApiService>((ref){
  const base = String.fromEnvironment('API_BASE', defaultValue: 'http://10.0.2.2:3000');
  return ApiService(base);
});

// ---------- Offline Cache (SharedPreferences JSON) ----------
class CacheService {
  Future<void> saveJobs(List<dynamic> jobs) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('jobs_cache', jsonEncode(jobs));
  }
  Future<List<dynamic>> loadJobs() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('jobs_cache'); if (raw==null) return [];
    try { return (jsonDecode(raw) as List).cast<dynamic>(); } catch (_) { return []; }
  }
}
final cacheProvider = Provider<CacheService>((_)=> CacheService());
