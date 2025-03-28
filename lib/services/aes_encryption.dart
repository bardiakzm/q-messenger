import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:archive/archive.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Aes {
  static final _key = encrypt.Key.fromUtf8(dotenv.env['ENCRYPTION_KEY']!);

  ///Encrypt
  static Map<String, String> encryptMessage(String plaintext) {
    final compressed = _compress(utf8.encode(plaintext));
    final iv = encrypt.IV.fromLength(16); //random iv

    final encrypter = encrypt.Encrypter(
      encrypt.AES(_key, mode: encrypt.AESMode.cbc),
    );
    final encrypted = encrypter.encryptBytes(compressed, iv: iv);

    return {
      'ciphertext': base64Encode(encrypted.bytes), //base 64
      'iv': base64Encode(iv.bytes), //returning iv for decrypt
      'tag': 'qmsa1', //tag
    };
  }

  ///Decrypts
  static String decryptMessage(String ciphertext, String ivBase64) {
    final iv = encrypt.IV.fromBase64(ivBase64);
    final encryptedBytes = base64Decode(ciphertext); //reverse b64

    final encrypter = encrypt.Encrypter(
      encrypt.AES(_key, mode: encrypt.AESMode.cbc),
    );
    final decrypted = encrypter.decryptBytes(
      encrypt.Encrypted(encryptedBytes),
      iv: iv,
    );
    return utf8.decode(_decompress(decrypted));
  }

  ///Compresses data using GZip
  static Uint8List _compress(List<int> data) {
    final encoder = GZipEncoder();
    return Uint8List.fromList(encoder.encode(data)!);
  }

  ///Decompresses data using GZip
  static List<int> _decompress(List<int> compressedData) {
    final decoder = GZipDecoder();
    return decoder.decodeBytes(compressedData);
  }
}
