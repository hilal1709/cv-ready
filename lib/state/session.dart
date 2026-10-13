import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/auth_repository.dart';
import '../data/models.dart';

class Session extends ChangeNotifier {
  Session(this._auth);
  final AuthRepository _auth;
  static const _key = 'cvready.session';

  AppUser? _user;
  AppUser? get user => _user;
  bool get signedIn => _user != null;

  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) _user = AppUser.fromJson(jsonDecode(raw));
    } catch (_) {
      _user = null;
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_user == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, jsonEncode(_user!.toJson()));
    }
  }

  Future<void> login(String email, String password) async {
    _user = await _auth.login(email: email, password: password);
    await _persist();
    notifyListeners();
  }

  Future<void> register(String name, String email, String password) async {
    _user = await _auth.register(fullName: name, email: email, password: password);
    await _persist();
    notifyListeners();
  }

  Future<void> rename(String fullName) async {
    final u = _user;
    if (u == null) return;
    await _auth.updateName(u.id, fullName);
    _user = AppUser(id: u.id, email: u.email, fullName: fullName.trim());
    await _persist();
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    await _persist();
    notifyListeners();
  }
}
