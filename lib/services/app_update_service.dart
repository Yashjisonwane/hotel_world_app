import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';

class AppUpdateService {
  static const String currentVersion = '1.0.24';
  static const int currentBuildNumber = 25;
  static const String githubRepo = 'Yashjisonwane/hotel_world_app';

  /// Checks GitHub Releases for the latest version of Hotel World App
  static Future<void> checkForUpdate(BuildContext context, {bool silent = false}) async {
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 8),
          headers: {'Accept': 'application/vnd.github.v3+json'},
        ),
      );

      final res = await dio.get('https://api.github.com/repos/$githubRepo/releases/latest');
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        final String tagName = (data['tag_name'] ?? '').toString().trim();
        final String cleanLatest = tagName.replaceAll(RegExp(r'^[vV]'), '').trim();
        final String releaseTitle = (data['name'] ?? 'Naya Update $tagName').toString();
        final String releaseNotes = (data['body'] ?? 'Performance improvements aur naye features.').toString();
        final List assets = (data['assets'] as List?) ?? [];

        // Find APK or IPA URL
        String? downloadUrl;
        if (Platform.isAndroid) {
          for (final a in assets) {
            final name = (a['name'] ?? '').toString().toLowerCase();
            if (name.endsWith('.apk')) {
              downloadUrl = a['browser_download_url']?.toString();
              break;
            }
          }
        } else if (Platform.isIOS) {
          for (final a in assets) {
            final name = (a['name'] ?? '').toString().toLowerCase();
            if (name.endsWith('.ipa') || name.endsWith('.zip')) {
              downloadUrl = a['browser_download_url']?.toString();
              break;
            }
          }
        }

        downloadUrl ??= data['html_url']?.toString();

        if (_isNewerVersion(cleanLatest, currentVersion)) {
          if (context.mounted) {
            _showUpdateDialog(
              context,
              latestVersion: cleanLatest,
              title: releaseTitle,
              notes: releaseNotes,
              downloadUrl: downloadUrl,
            );
          }
          return;
        }
      }

      if (!silent && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aapki app already latest version (v$currentVersion) par hai ✓'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!silent && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update check nahi ho saka: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Compares semantic versions (e.g. "1.0.1" > "1.0.0")
  static bool _isNewerVersion(String latest, String current) {
    try {
      final lParts = latest.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      final cParts = current.split('.').map((p) => int.tryParse(p) ?? 0).toList();

      while (lParts.length < 3) {
        lParts.add(0);
      }
      while (cParts.length < 3) {
        cParts.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (lParts[i] > cParts[i]) return true;
        if (lParts[i] < cParts[i]) return false;
      }
      return false;
    } catch (_) {
      return latest.isNotEmpty && latest != current;
    }
  }

  /// Displays the Hotel World Update Dialog
  static void _showUpdateDialog(
    BuildContext context, {
    required String latestVersion,
    required String title,
    required String notes,
    required String? downloadUrl,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary500.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary500),
                  ),
                  child: const Icon(Icons.system_update_rounded, color: AppColors.primary400, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Naya Update Aaya Hai!',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Version v$latestVersion (Installed: v$currentVersion)',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    notes.isNotEmpty ? notes : 'Is update me naye fixes aur features shamil hain.',
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155), height: 1.4),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '💡 Note: Update karne par aapka purana quotation data ya login delete nahi hoga.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF047857), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Baad Me', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('Abhi Update Karein'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary500,
                foregroundColor: AppColors.slate950,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                if (downloadUrl != null && downloadUrl.isNotEmpty) {
                  _startInAppDownload(context, downloadUrl);
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// Downloads the APK directly inside the app with a live progress dialog and opens the installer
  static Future<void> _startInAppDownload(BuildContext context, String url) async {
    final progressNotifier = ValueNotifier<double>(0.0);
    bool isCancelled = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.system_update_rounded, color: AppColors.primary500),
              SizedBox(width: 10),
              Text('Update Download Ho Raha Hai', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          content: ValueListenableBuilder<double>(
            valueListenable: progressNotifier,
            builder: (ctx, prog, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: prog > 0 ? prog : null,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        prog > 0 ? '${(prog * 100).toInt()}% Downloaded' : 'Connecting...',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                      ),
                      const Text(
                        'Direct APK Update',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                isCancelled = true;
                Navigator.pop(dialogCtx);
              },
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
          ],
        );
      },
    );

    try {
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/HotelWorld-Update.apk';

      final oldFile = File(savePath);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(minutes: 5),
          followRedirects: true,
          maxRedirects: 10,
        ),
      );

      // Candidate 1: Render backend stream (immune to Indian ISP githubusercontent blocks)
      // Candidate 2: Direct GitHub Release URL
      final downloadCandidates = [
        'https://hotelworld-backend.onrender.com/api/app/latest-apk',
        url,
      ];

      bool downloaded = false;
      String? lastError;

      for (final candidate in downloadCandidates) {
        if (isCancelled) break;
        try {
          await dio.download(
            candidate,
            savePath,
            onReceiveProgress: (received, total) {
              if (!isCancelled && total > 0) {
                progressNotifier.value = received / total;
              }
            },
          );
          final downloadedFile = File(savePath);
          if (await downloadedFile.exists() && (await downloadedFile.length()) > 1000000) {
            downloaded = true;
            break;
          }
        } catch (candidateErr) {
          lastError = candidateErr.toString();
        }
      }

      if (context.mounted && !isCancelled) {
        Navigator.of(context, rootNavigator: true).pop(); // Close progress dialog
        if (downloaded) {
          final res = await OpenFilex.open(savePath, type: 'application/vnd.android.package-archive');
          if (res.type != ResultType.done) {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
        } else {
          throw Exception(lastError ?? 'APK download verify fail');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download error: $e. Browser se open kiya ja raha hai...'),
            backgroundColor: AppColors.error,
          ),
        );
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    }
  }
}

