import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'local_db.dart';
import 'sync_service.dart';

class AppInit {
  final LocalDB _db = LocalDB();
  final SyncService _sync = SyncService();

  Future<void> initialize(String baseUrl) async {
    Connectivity().onConnectivityChanged.listen((dynamic event) async {
      if (event is ConnectivityResult) {
        if (event != ConnectivityResult.none) {
          await _sync.trySyncAll(baseUrl);
        }
      } else if (event is Iterable) {
        final list = event.whereType<ConnectivityResult>();
        if (list.any((e) => e != ConnectivityResult.none)) {
          await _sync.trySyncAll(baseUrl);
        }
      }
    });

    try {
      final res = await http.get(Uri.parse('$baseUrl/sync/lookup'));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json.containsKey('eixos')) {
          await _db.clearLookup('eixo');
          for (final item in json['eixos']) {
            await _db.insertLookup('eixo', jsonEncode(item),
                serverId: item['id']);
          }
        }
        if (json.containsKey('temas')) {
          await _db.clearLookup('tema');
          for (final item in json['temas']) {
            await _db.insertLookup('tema', jsonEncode(item),
                serverId: item['id']);
          }
        }
      }
    } catch (_) {}
  }
}
