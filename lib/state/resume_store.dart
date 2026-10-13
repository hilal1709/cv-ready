import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/db.dart';
import '../data/models.dart';
import '../data/resume_repository.dart';
import '../services/ats_scorer.dart';

enum SaveState { idle, saving, saved, failed }

class ResumeStore extends ChangeNotifier {
  ResumeStore(this._repo);
  final ResumeRepository _repo;

  String? _userId;
  List<Resume> _items = [];
  bool _loading = false;
  String? _error;
  final Map<String, Timer> _debounce = {};
  final Map<String, SaveState> _saveState = {};

  List<Resume> get items => _items;
  bool get loading => _loading;
  String? get error => _error;
  SaveState saveStateOf(String id) => _saveState[id] ?? SaveState.idle;

  Resume? byId(String id) => _items.where((r) => r.id == id).firstOrNull;

  Future<void> bind(String? userId) async {
    if (_userId == userId) return;
    _userId = userId;
    _items = [];
    if (userId != null) await refresh();
    notifyListeners();
  }

  Future<void> refresh() async {
    final uid = _userId;
    if (uid == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _repo.list(uid);
    } catch (e) {
      _error = e is DbException ? e.message : 'Ada yang tidak beres. Tarik ke bawah untuk mencoba lagi.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Resume> create({required String title, required CvTemplate template, ResumeData? data}) async {
    final r = await _repo.create(_userId!, title: title, template: template, data: data);
    _items = [r, ..._items];
    notifyListeners();
    return r;
  }

  Future<Resume> duplicate(Resume r) async {
    await flush(r.id);
    final copy = await _repo.duplicate(_userId!, r);
    _items = [copy, ..._items];
    notifyListeners();
    return copy;
  }

  Future<void> delete(Resume r) async {
    _debounce.remove(r.id)?.cancel();
    await _repo.delete(_userId!, r.id);
    _items = _items.where((x) => x.id != r.id).toList();
    notifyListeners();
  }

  /// Call after any in-place edit; saves ~0.9 s after the last change.
  void touch(Resume r) {
    _saveState[r.id] = SaveState.saving;
    notifyListeners();
    _debounce[r.id]?.cancel();
    _debounce[r.id] = Timer(const Duration(milliseconds: 900), () => _save(r));
  }

  Future<void> flush(String id) async {
    final t = _debounce.remove(id);
    if (t != null && t.isActive) {
      t.cancel();
      final r = byId(id);
      if (r != null) await _save(r);
    }
  }

  Future<void> _save(Resume r) async {
    _debounce.remove(r.id);
    try {
      r.updatedAt = await _repo.save(_userId!, r);
      _saveState[r.id] = SaveState.saved;
      _items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (_) {
      _saveState[r.id] = SaveState.failed;
    }
    notifyListeners();
  }

  Future<void> retrySave(Resume r) => _save(r);

  int scoreOf(Resume r) => AtsScorer.score(r.data).percent;

  @override
  void dispose() {
    for (final t in _debounce.values) {
      t.cancel();
    }
    super.dispose();
  }
}
