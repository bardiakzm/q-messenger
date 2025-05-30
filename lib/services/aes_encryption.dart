import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:es_compression/brotli.dart';
import 'package:archive/archive.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Aes {
  static final _key = encrypt.Key.fromUtf8(dotenv.env['ENCRYPTION_KEY']!);
  static const int _brotliLevel = 4;

  static Map<String, String> encryptMessage(String plaintext) {
    try {
      final compressed = _compressGzip(utf8.encode(plaintext));
      final iv = encrypt.IV.fromLength(16);

      final encrypter = encrypt.Encrypter(
        encrypt.AES(_key, mode: encrypt.AESMode.cbc),
      );
      final encrypted = encrypter.encryptBytes(compressed, iv: iv);

      final hexEncrypted = encrypted.bytes
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join('');
      final hexIV = iv.bytes
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join('');

      return {
        'ciphertext': hexEncrypted,
        'iv': hexIV,
        'tag': 'qmsa2', // qmsa2 for Gzip and qmsa3 for brotli
      };
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  ///Decrypt with automatic compression detection
  static String decryptMessage(
    String hexCiphertext,
    String hexIV, [
    String? tag,
  ]) {
    try {
      final encryptedBytes = Uint8List.fromList(
        List.generate(
          hexCiphertext.length ~/ 2,
          (i) =>
              int.parse(hexCiphertext.substring(i * 2, i * 2 + 2), radix: 16),
        ),
      );

      final ivBytes = Uint8List.fromList(
        List.generate(
          hexIV.length ~/ 2,
          (i) => int.parse(hexIV.substring(i * 2, i * 2 + 2), radix: 16),
        ),
      );

      final iv = encrypt.IV(ivBytes);
      final encrypter = encrypt.Encrypter(
        encrypt.AES(_key, mode: encrypt.AESMode.cbc),
      );

      final decrypted = encrypter.decryptBytes(
        encrypt.Encrypted(encryptedBytes),
        iv: iv,
      );

      // Auto-detect compression format based on tag
      if (tag == 'qmsa3') {
        // New Brotli format
        return utf8.decode(_decompressBrotli(decrypted));
      } else {
        // Legacy GZIP format (qmsa2 or null)
        return utf8.decode(_decompressGzip(decrypted));
      }
    } catch (e) {
      // Fallback: try both decompression methods
      try {
        final encryptedBytes = Uint8List.fromList(
          List.generate(
            hexCiphertext.length ~/ 2,
            (i) =>
                int.parse(hexCiphertext.substring(i * 2, i * 2 + 2), radix: 16),
          ),
        );
        final ivBytes = Uint8List.fromList(
          List.generate(
            hexIV.length ~/ 2,
            (i) => int.parse(hexIV.substring(i * 2, i * 2 + 2), radix: 16),
          ),
        );
        final iv = encrypt.IV(ivBytes);
        final encrypter = encrypt.Encrypter(
          encrypt.AES(_key, mode: encrypt.AESMode.cbc),
        );
        final decrypted = encrypter.decryptBytes(
          encrypt.Encrypted(encryptedBytes),
          iv: iv,
        );

        // Try Brotli first, then GZIP
        try {
          return utf8.decode(_decompressBrotli(decrypted));
        } catch (_) {
          return utf8.decode(_decompressGzip(decrypted));
        }
      } catch (fallbackError) {
        throw Exception('All decryption methods failed: $e, $fallbackError');
      }
    }
  }

  // Brotli compression methods
  static Uint8List _compressBrotli(List<int> data) {
    final compressed = brotli.encode(data);
    return Uint8List.fromList(compressed);
  }

  static List<int> _decompressBrotli(List<int> compressedData) {
    return brotli.decode(compressedData);
  }

  // Legacy GZIP methods (for backward compatibility)
  static Uint8List _compressGzip(List<int> data) {
    final encoder = GZipEncoder();
    return Uint8List.fromList(encoder.encode(data));
  }

  static List<int> _decompressGzip(List<int> compressedData) {
    final decoder = GZipDecoder();
    return decoder.decodeBytes(compressedData);
  }

  // Legacy method for old clients
  @deprecated
  static Uint8List _compress(List<int> data) => _compressGzip(data);

  @deprecated
  static List<int> _decompress(List<int> compressedData) =>
      _decompressGzip(compressedData);
}
