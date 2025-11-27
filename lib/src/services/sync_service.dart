import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'local_db.dart';
import 'auth_storage.dart';
import 'dart:convert';

class SyncService {
  final LocalDB _db = LocalDB();

  Future<void> trySyncAll(String baseUrl) async {
    final dynamic conn = await Connectivity().checkConnectivity();
    try {
      if (conn == ConnectivityResult.none) return;
      if (conn is Iterable) {
        final list = conn.cast<ConnectivityResult>();
        if (list.every((c) => c == ConnectivityResult.none)) return;
      }
    } catch (_) {}

    final token = await AuthStorage.readToken();
    final queue = await _db.getSyncQueue();
    for (final item in queue) {
      final id = item['id'] as int;
      try {
        final endpoint = item['endpoint'] as String;
        final method = item['method'] as String;
        final body = item['body'] as String?;
        final localRef = item['local_ref'] as String?;

        final headers = <String, String>{'Content-Type': 'application/json'};
        if (token != null) headers['Authorization'] = 'Bearer $token';

        late http.Response res;
        final url = '$baseUrl${endpoint.startsWith('/') ? '' : '/'}$endpoint';
        String? bodyToSend = body;
        if (bodyToSend != null) {
          try {
            final parsed = json.decode(bodyToSend);
            if (parsed is Map && parsed.containsKey('acao_projeto_local_ref')) {
              final localParent = parsed['acao_projeto_local_ref']?.toString();
              if (localParent != null && localParent.isNotEmpty) {
                final serverId = await _db.getServerId(localParent);
                if (serverId == null) {
                  continue;
                }
                parsed['acao_projeto_id'] = serverId;
                parsed.remove('acao_projeto_local_ref');
                bodyToSend = json.encode(parsed);
              }
            }
          } catch (e) {
            bodyToSend = body;
          }
        }

        if (method.toUpperCase() == 'POST') {
          res = await http.post(Uri.parse(url),
              headers: headers, body: bodyToSend);
        } else if (method.toUpperCase() == 'PUT') {
          res = await http.put(Uri.parse(url),
              headers: headers, body: bodyToSend);
        } else if (method.toUpperCase() == 'DELETE') {
          res = await http.delete(Uri.parse(url), headers: headers);
        } else {
          await _db.removeSyncItem(id);
          continue;
        }

        if (res.statusCode >= 200 && res.statusCode < 300) {
          try {
            final respJson = res.body.isNotEmpty ? json.decode(res.body) : null;
            int? parsedId;
            if (localRef != null &&
                respJson != null &&
                endpoint.endsWith('/project1')) {
              final serverId = respJson['acao_projeto_id'] ?? respJson['id'];
              if (serverId != null) {
                if (serverId is int) {
                  parsedId = serverId;
                } else if (serverId is String) {
                  parsedId = int.tryParse(serverId);
                }

                if (parsedId != null) {
                  await _db.updateProjectServerId(localRef, parsedId);
                }
              }
            }

            try {
              if (endpoint.endsWith('/project1') &&
                  localRef != null &&
                  (res.statusCode == 201 || parsedId != null)) {
                await _db.deleteDraftByLocalId(localRef);
                if (parsedId != null) {
                  await _db.removeLocalProject(localRef);
                }
              }
            } catch (e) {
              debugPrint('  ⚠️ Erro ao remover draft: $e');
            }
          } catch (e) {
            debugPrint('  ⚠️ Erro ao parsear resposta: $e');
          }

          await _db.removeSyncItem(id);
        } else {
          debugPrint(
              '  ❌ Sync #$id falhou com status ${res.statusCode}: ${res.body}');
        }
      } catch (e) {
        debugPrint('  ❌ Erro de rede/parse no sync #$id: $e');
      }
    }
  }
}
