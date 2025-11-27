import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'auth_storage.dart';

class AuthProvider extends ChangeNotifier {
  final String baseUrl;
  AuthProvider({required this.baseUrl});

  String? _token;
  String? _refreshToken;
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;

  Future<void> loadFromStorage() async {
    _isLoading = true;
    notifyListeners();
    _token = await AuthStorage.readToken();
    _refreshToken = await AuthStorage.readRefreshToken();
    if (_token != null) {
      try {
        final res = await http.get(Uri.parse('$baseUrl/auth/me'), headers: {'Authorization': 'Bearer $_token'});
        if (res.statusCode == 200) {
          _user = jsonDecode(res.body) as Map<String, dynamic>;
          final active = _user != null ? _user!['active_context'] : null;
          if (active == null) {
            try {
              final contexts = await getContexts();
              if (contexts != null) {
                final unidades = contexts['unidades'] as List<dynamic>?;
                final regionais = contexts['regionais'] as List<dynamic>?;
                if ((unidades != null && unidades.length == 1) && (regionais == null || regionais.isEmpty)) {
                  final id = unidades.first['unidade_id'] ?? unidades.first['id'];
                  await selectContext('unidade', id is int ? id : int.tryParse(id?.toString() ?? ''));
                } else if ((regionais != null && regionais.length == 1) && (unidades == null || unidades.isEmpty)) {
                  final id = regionais.first['pessoa_id'] ?? regionais.first['id'];
                  await selectContext('regional', id is int ? id : int.tryParse(id?.toString() ?? ''));
                }
              }
            } catch (_) {}
          }
        } else {
          final refreshed = await tryRefresh();
          if (!refreshed) {
            await logout();
          }
        }
      } catch (_) {
      }
    }
    notifyListeners();
    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getContexts() async {
    if (_token == null) return null;
    try {
      final res = await http.get(Uri.parse('$baseUrl/auth/contexts'), headers: {'Authorization': 'Bearer $_token'});
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> selectContext(String tipo, int? id) async {
    if (_token == null) return false;
    try {
      final Map<String, dynamic> body = {'tipo': tipo};
      if (id != null) body['id'] = id;
      final res = await http.post(
        Uri.parse('$baseUrl/auth/select-context'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_token'},
        body: jsonEncode(body),
      );
      if (res.statusCode == 200) {
        final parsed = jsonDecode(res.body) as Map<String, dynamic>;
        final access = parsed['access_token'] as String?;
        final refresh = parsed['refresh_token'] as String?;
        if (access != null) {
          await setToken(access, refresh: refresh);
          try {
            final me = await http.get(Uri.parse('$baseUrl/auth/me'), headers: {'Authorization': 'Bearer $access'});
            if (me.statusCode == 200) _user = jsonDecode(me.body) as Map<String, dynamic>;
          } catch (_) {}
          notifyListeners();
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  Future<void> setToken(String access, {String? refresh, Map<String,dynamic>? userData}) async {
    _token = access;
    if (refresh != null) {
      _refreshToken = refresh;
      await AuthStorage.saveRefreshToken(refresh);
    }
    await AuthStorage.saveToken(access);
    if (userData != null) _user = userData;
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _refreshToken = null;
    _user = null;
    await AuthStorage.removeToken();
    await AuthStorage.removeRefreshToken();
    notifyListeners();
  }

  Future<bool> tryRefresh() async {
    if (_refreshToken == null) return false;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': _refreshToken}),
      );
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final newAccess = json['access_token'] as String?;
        if (newAccess != null) {
          _token = newAccess;
          await AuthStorage.saveToken(newAccess);
          try {
            final me = await http.get(Uri.parse('$baseUrl/auth/me'), headers: {'Authorization': 'Bearer $_token'});
            if (me.statusCode == 200) _user = jsonDecode(me.body) as Map<String, dynamic>;
          } catch (_) {}
          notifyListeners();
          return true;
        }
      }
    } catch (_) {}
    return false;
  }
}
