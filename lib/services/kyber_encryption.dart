import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:es_compression/brotli.dart';
import 'package:xkyber_crypto/xkyber_crypto.dart';

Future<void> main() async {
  // KyberKeyPair keypair = KyberKeyPair.generate();
  // print("Public Key (${keypair.publicKey.length} bytes):");
  // print(keypair.publicKey);
  // print("Secret Key (${keypair.secretKey.length} bytes):");
  // print(keypair.secretKey);
  String text = 'hi i wonvdfgragsdfsafdasffast be there';
  List<int> input = utf8.encode(text);
  print(input);
  List<int> compressed = brotli.encode(input);
  print(compressed);
}
