import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'local_db.dart';
import 'auth_storage.dart';
import 'dart:convert';

class SyncService {
  final LocalDB _db = LocalDB();

  // Simple sync: read queue and try to send
  Future<void> trySyncAll(String baseUrl) async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) return;

    final token = await AuthStorage.readToken();
    final queue = await _db.getSyncQueue();
    for (final item in queue) {
      try {
        final endpoint = item['endpoint'] as String;
        final method = item['method'] as String;
        final body = item['body'] as String?;
        final id = item['id'] as int;
        final localRef = item['local_ref'] as String?;

        final headers = <String, String>{'Content-Type': 'application/json'};
        if (token != null) headers['Authorization'] = 'Bearer $token';

        late http.Response res;
        final url = '$baseUrl${endpoint.startsWith('/') ? '' : '/'}$endpoint';
        // If body contains an acao_projeto_local_ref, try to resolve it to a server id
        String? bodyToSend = body;
        if (bodyToSend != null) {
          try {
            final parsed = json.decode(bodyToSend);
            if (parsed is Map && parsed.containsKey('acao_projeto_local_ref')) {
              final localParent = parsed['acao_projeto_local_ref']?.toString();
              if (localParent != null && localParent.isNotEmpty) {
                final serverId = await _db.getServerId(localParent);
                if (serverId == null) {
                  // Parent project not synced yet; skip this item for now
                  continue;
                }
                // set proper acao_projeto_id and remove local ref
                parsed['acao_projeto_id'] = serverId;
                parsed.remove('acao_projeto_local_ref');
                bodyToSend = json.encode(parsed);
              }
            }
          } catch (e) {
            // if parsing fails, just keep original body
            bodyToSend = body;
          }
        }

        if (method.toUpperCase() == 'POST') {
          res = await http.post(Uri.parse(url), headers: headers, body: bodyToSend);
        } else if (method.toUpperCase() == 'PUT') {
          res = await http.put(Uri.parse(url), headers: headers, body: bodyToSend);
        } else if (method.toUpperCase() == 'DELETE') {
          res = await http.delete(Uri.parse(url), headers: headers);
        } else {
          // Unsupported - remove to avoid infinite loop
          await _db.removeSyncItem(id);
          continue;
        }

        if (res.statusCode >= 200 && res.statusCode < 300) {
          // success -> remove from queue
          // if POST created a resource and we have local_ref, map ids
          try {
            final respJson = res.body.isNotEmpty ? json.decode(res.body) : null;
            int? parsedId;
            if (localRef != null && respJson != null) {
              // tentar extrair id: considerar 'id', 'project_id', 'pessoa_id' ou Prisma PK 'acao_projeto_id'
              final serverId = respJson['id'] ?? respJson['project_id'] ?? respJson['pessoa_id'] ?? respJson['acao_projeto_id'];
              if (serverId != null) {
                // serverId pode vir como int ou string - tentar converter
                if (serverId is int) parsedId = serverId;
                else if (serverId is String) parsedId = int.tryParse(serverId);

                if (parsedId != null) {
                  await _db.updateProjectServerId(localRef, parsedId);
                }
              }
            }

            // if the endpoint is project creation, remove any draft associated to this localRef
            // ONLY remove when server confirmed creation (201) or when we parsed a server id
            try {
              if (endpoint.endsWith('/project1') && localRef != null && (res.statusCode == 201 || parsedId != null)) {
                await _db.deleteDraftByLocalId(localRef);
                // Remover projeto local da tabela projects se foi criado com sucesso
                if (parsedId != null) {
                  await _db.removeLocalProject(localRef);
                }
              }
            } catch (e) {
              // ignore draft deletion errors
            }
          } catch (e) {
            // ignore parsing errors
          }

          await _db.removeSyncItem(id);
        } else {
          // keep in queue, maybe retry later
          // optionally add retry count logic
        }
      } catch (e) {
        // network or parse error - keep item
      }
    }
  }
}
