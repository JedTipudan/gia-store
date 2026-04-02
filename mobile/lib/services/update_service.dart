import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static const _versionUrl =
      'https://raw.githubusercontent.com/JedTipudan/gia-store/main/version.txt';
  static const _downloadUrl =
      'https://github.com/JedTipudan/gia-store/releases/latest';

  static Future<UpdateInfo?> checkForUpdate(String currentVersion) async {
    try {
      final response = await http
          .get(Uri.parse(_versionUrl))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;

      final lines = response.body.trim().split('\n');
      String latestVersion = '';
      String downloadUrl = _downloadUrl;
      List<String> notesList = [];

      for (final rawLine in lines) {
        final line = rawLine.trim();
        if (line.startsWith('version=')) {
          latestVersion = line.substring(line.indexOf('=') + 1).trim();
        } else if (line.startsWith('download=')) {
          downloadUrl = line.substring(line.indexOf('=') + 1).trim();
        } else if (line.startsWith('-')) {
          notesList.add(line);
        }
      }

      if (latestVersion.isEmpty) return null;
      if (_isNewer(latestVersion, currentVersion)) {
        return UpdateInfo(
          version: latestVersion,
          downloadUrl: downloadUrl,
          releaseNotes: notesList.join('\n'),
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static bool _isNewer(String latest, String current) {
    final l = latest.split('.').map(int.tryParse).toList();
    final c = current.split('.').map(int.tryParse).toList();
    for (int i = 0; i < 3; i++) {
      final lv = (i < l.length ? l[i] : 0) ?? 0;
      final cv = (i < c.length ? c[i] : 0) ?? 0;
      if (lv > cv) return true;
      if (lv < cv) return false;
    }
    return false;
  }

  static Future<void> openDownload(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class UpdateInfo {
  final String version;
  final String downloadUrl;
  final String releaseNotes;
  UpdateInfo({required this.version, required this.downloadUrl, required this.releaseNotes});
}
