import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final archiveDownloaderProvider = Provider<ArchiveDownloader>((ref) {
  return const ArchiveDownloader();
});

class ArchiveDownloader {
  const ArchiveDownloader();

  static const MethodChannel _channel = MethodChannel(
    'smartguard/archive_downloader',
  );

  Future<void> downloadToDownloads({
    required String url,
    required String fileName,
    Map<String, String>? headers,
  }) {
    return _channel.invokeMethod<void>('downloadToDownloads', {
      'url': url,
      'fileName': fileName,
      if (headers != null && headers.isNotEmpty) 'headers': headers,
    });
  }
}
