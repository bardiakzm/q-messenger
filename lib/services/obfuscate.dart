import 'package:flutter_dotenv/flutter_dotenv.dart';

Map<String, String> obfuscationMap = {};

class Obfuscate {
  static Map<String, String> loadObfuscationMap() {
    return Map.fromEntries(
      dotenv.env.entries
          .where(
            (entry) => entry.key.startsWith("OBF_FA2_"),
          ) // Filter obfuscation keys
          .map(
            (entry) =>
                MapEntry(entry.key.substring(8).toLowerCase(), entry.value),
          ), // Remove "OBF_FA2_" prefix
    );
  }

  static void setObfuscationMap() {
    obfuscationMap = loadObfuscationMap();
  }

  static String obfuscateText(String text, Map<String, String> obfuscationMap) {
    // Split by first colon to preserve the tag
    final parts = text.split(':');
    if (parts.length < 2) {
      return text; // Return original text if no colon found
    }

    final tag = parts[0];
    // Join remaining parts back with colon in case there are multiple colons
    final contentToObfuscate = parts.sublist(1).join(':');

    // Obfuscate with spaces between words
    final obfuscatedContent = contentToObfuscate
        .split('')
        .map((char) => obfuscationMap[char.toLowerCase()] ?? char)
        .join(' '); // Add space between substituted words

    return '$tag:$obfuscatedContent';
  }

  static String deobfuscateText(
    String text,
    Map<String, String> obfuscationMap,
  ) {
    // Split by first colon to preserve the tag
    final parts = text.split(':');
    if (parts.length < 2) {
      return text; // Return original text if no colon found
    }

    final tag = parts[0];
    // Join remaining parts back with colon in case there are multiple colons
    final obfuscatedContent = parts.sublist(1).join(':');

    // Create reverse mapping
    Map<String, String> reverseMap = obfuscationMap.map(
      (key, value) => MapEntry(value, key),
    );

    // Split by spaces and deobfuscate each word
    final deobfuscatedContent = obfuscatedContent
        .split(' ')
        .where((word) => word.isNotEmpty) // Filter out empty strings
        .map((word) => reverseMap[word] ?? word)
        .join(''); // Join without spaces

    return '$tag:$deobfuscatedContent';
  }
}
