import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// A release newer than the installed build.
class UpdateInfo {
  const UpdateInfo({required this.version, required this.notes, required this.apkUrl, required this.sizeBytes});
  final String version;
  final String notes;
  final String apkUrl;
  final int sizeBytes;

  String get sizeLabel => sizeBytes <= 0 ? '' : '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// In-app updates from GitHub Releases: the latest release's `.apk` asset is
/// downloaded and handed to Android's package installer. Publishing a new
/// release (tool/release.sh) is all it takes for phones to see an update.
class Updater {
  Updater({http.Client? client}) : _http = client ?? http.Client();
  final http.Client _http;

  static const repo = 'hilal1709/cv-ready';

  Future<String> installedVersion() async => (await PackageInfo.fromPlatform()).version;

  /// Returns the newer release, or null when already up to date.
  Future<UpdateInfo?> check() async {
    final res = await _http
        .get(
          Uri.parse('https://api.github.com/repos/$repo/releases/latest'),
          headers: {'Accept': 'application/vnd.github+json'},
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 404) return null; // no release published yet
    if (res.statusCode != 200) {
      throw Exception('Server pembaruan membalas ${res.statusCode}.');
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final tag = '${j['tag_name'] ?? ''}'.replaceFirst(RegExp(r'^[vV]'), '');
    final assets = (j['assets'] as List? ?? const []).whereType<Map>();
    final apk = assets.where((a) => '${a['name']}'.toLowerCase().endsWith('.apk')).firstOrNull;
    if (tag.isEmpty || apk == null) return null;
    if (compareVersions(tag, await installedVersion()) <= 0) return null;
    return UpdateInfo(
      version: tag,
      notes: '${j['body'] ?? ''}'.trim(),
      apkUrl: '${apk['browser_download_url']}',
      sizeBytes: (apk['size'] as num?)?.toInt() ?? 0,
    );
  }

  /// Streams download progress, then opens Android's install prompt.
  Stream<OtaEvent> install(UpdateInfo info) =>
      OtaUpdate().execute(info.apkUrl, destinationFilename: 'cv-ready-${info.version}.apk');

  /// Dotted-number comparison ("1.10.0" > "1.9.2"); non-numeric parts count as 0.
  static int compareVersions(String a, String b) {
    List<int> parts(String v) =>
        v.split('+').first.split('.').map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0).toList();
    final x = parts(a), y = parts(b);
    for (var i = 0; i < (x.length > y.length ? x.length : y.length); i++) {
      final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
      if (d != 0) return d.sign;
    }
    return 0;
  }
}
