import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class SavedReceiptImages {
  final String fullImagePath;
  final String thumbnailPath;

  SavedReceiptImages({
    required this.fullImagePath,
    required this.thumbnailPath,
  });
}

class ReceiptStorageService {
  /// Saves the source image file into app storage and generates a compressed thumbnail
  static Future<SavedReceiptImages> saveReceiptWithThumbnail(File sourceFile) async {
    final docDir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory(p.join(docDir.path, 'receipts'));
    final thumbsDir = Directory(p.join(docDir.path, 'receipts', 'thumbnails'));

    if (!receiptsDir.existsSync()) {
      receiptsDir.createSync(recursive: true);
    }
    if (!thumbsDir.existsSync()) {
      thumbsDir.createSync(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = 'receipt_$timestamp.jpg';
    final thumbFilename = 'thumb_$timestamp.jpg';

    final targetFullFile = File(p.join(receiptsDir.path, filename));
    final targetThumbFile = File(p.join(thumbsDir.path, thumbFilename));

    // Copy full image
    await sourceFile.copy(targetFullFile.path);

    // Generate thumbnail using image package
    try {
      final bytes = await sourceFile.readAsBytes();
      final decodedImage = img.decodeImage(bytes);

      if (decodedImage != null) {
        // Resize to 220px max width while preserving aspect ratio
        final thumbnail = img.copyResize(
          decodedImage,
          width: 220,
          interpolation: img.Interpolation.linear,
        );

        // Encode as 75% quality JPEG for ultra-lightweight thumbnail (< 25 KB)
        final thumbBytes = img.encodeJpg(thumbnail, quality: 75);
        await targetThumbFile.writeAsBytes(thumbBytes);
      } else {
        // Fallback: copy source
        await sourceFile.copy(targetThumbFile.path);
      }
    } catch (e) {
      debugPrint('Thumbnail generation failed: $e, using full image as thumbnail');
      await sourceFile.copy(targetThumbFile.path);
    }

    return SavedReceiptImages(
      fullImagePath: targetFullFile.path,
      thumbnailPath: targetThumbFile.path,
    );
  }

  /// Delete both full image and thumbnail from disk
  static Future<void> deleteReceiptFiles({String? fullPath, String? thumbPath}) async {
    try {
      if (fullPath != null && fullPath.isNotEmpty) {
        final f = File(fullPath);
        if (f.existsSync()) {
          await f.delete();
        }
      }
      if (thumbPath != null && thumbPath.isNotEmpty) {
        final t = File(thumbPath);
        if (t.existsSync()) {
          await t.delete();
        }
      }
    } catch (e) {
      debugPrint('Error deleting receipt files: $e');
    }
  }
}
