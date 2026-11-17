import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Kết quả sau khi nén ảnh
class CompressedFile {
  final String name;
  final Uint8List bytes;
  final int originalSize;
  final int compressedSize;

  const CompressedFile({
    required this.name,
    required this.bytes,
    required this.originalSize,
    required this.compressedSize,
  });

  bool get wasCompressed => compressedSize < originalSize;
  
  double get compressionRatio =>
      originalSize > 0 ? (1 - (compressedSize / originalSize)) * 100 : 0;

  String get readableOriginalSize => _formatBytes(originalSize);
  String get readableCompressedSize => _formatBytes(compressedSize);

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Tiện ích nén ảnh tự động cho các minh chứng và upload hồ sơ sinh viên
class ImageCompressor {
  static const int defaultMaxDimension = 1600;
  static const int defaultQuality = 80;
  static const int minSizeBytesForCompression = 300 * 1024; // 300 KB

  /// Kiểm tra file có phải là định dạng hình ảnh nén được không
  static bool isCompressibleImage(String fileName) {
    final lower = fileName.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.bmp');
  }

  /// Nén dữ liệu ảnh trong Isolate chạy ngầm để giữ UI mượt mà 60fps
  static Future<CompressedFile> compressImage({
    required String fileName,
    required Uint8List bytes,
    int maxDimension = defaultMaxDimension,
    int quality = defaultQuality,
  }) async {
    final originalSize = bytes.length;
    if (!isCompressibleImage(fileName) || originalSize < minSizeBytesForCompression) {
      return CompressedFile(
        name: fileName,
        bytes: bytes,
        originalSize: originalSize,
        compressedSize: originalSize,
      );
    }

    try {
      final compressedBytes = await compute(
        _compressInIsolate,
        _CompressTask(
          bytes: bytes,
          maxDimension: maxDimension,
          quality: quality,
        ),
      );

      final extIndex = fileName.lastIndexOf('.');
      final baseName = extIndex != -1 ? fileName.substring(0, extIndex) : fileName;
      final newName = '$baseName.jpg';

      if (compressedBytes != null && compressedBytes.length < originalSize) {
        debugPrint(
          '[ImageCompressor] Nén thành công $fileName: '
          '${CompressedFile._formatBytes(originalSize)} -> '
          '${CompressedFile._formatBytes(compressedBytes.length)} '
          '(-${((1 - compressedBytes.length / originalSize) * 100).toStringAsFixed(0)}%)',
        );
        return CompressedFile(
          name: newName,
          bytes: compressedBytes,
          originalSize: originalSize,
          compressedSize: compressedBytes.length,
        );
      }
    } catch (e) {
      debugPrint('[ImageCompressor] Lỗi khi nén ảnh: $e');
    }

    return CompressedFile(
      name: fileName,
      bytes: bytes,
      originalSize: originalSize,
      compressedSize: originalSize,
    );
  }

  static Uint8List? _compressInIsolate(_CompressTask task) {
    final image = img.decodeImage(task.bytes);
    if (image == null) return null;

    img.Image resized = image;
    final maxDim = task.maxDimension;
    if (image.width > maxDim || image.height > maxDim) {
      if (image.width >= image.height) {
        resized = img.copyResize(
          image,
          width: maxDim,
          interpolation: img.Interpolation.linear,
        );
      } else {
        resized = img.copyResize(
          image,
          height: maxDim,
          interpolation: img.Interpolation.linear,
        );
      }
    }

    final jpgBytes = img.encodeJpg(resized, quality: task.quality);
    return Uint8List.fromList(jpgBytes);
  }
}

class _CompressTask {
  final Uint8List bytes;
  final int maxDimension;
  final int quality;

  _CompressTask({
    required this.bytes,
    required this.maxDimension,
    required this.quality,
  });
}
