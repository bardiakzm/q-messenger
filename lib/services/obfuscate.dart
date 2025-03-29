import 'package:flutter_dotenv/flutter_dotenv.dart';

Map<String, String> obfuscationMap = {};

class Obfuscate {
  static Map<String, String> loadObfuscationMap() {
    return Map.fromEntries(
      dotenv.env.entries
          .where(
            (entry) => entry.key.startsWith("OBF_"),
          ) // Filter obfuscation keys
          .map(
            (entry) =>
                MapEntry(entry.key.substring(4).toLowerCase(), entry.value),
          ), // Remove "OBF_" prefix
    );
  }

  static void setObfuscationMap() {
    obfuscationMap = loadObfuscationMap();
  }

  static String obfuscateText(String text, Map<String, String> obfuscationMap) {
    return text
        .split('')
        .map((char) => obfuscationMap[char.toLowerCase()] ?? char)
        .join('');
  }

  static String deobfuscateText(
    String text,
    Map<String, String> obfuscationMap,
  ) {
    Map<String, String> reverseMap = obfuscationMap.map(
      (key, value) => MapEntry(value, key),
    );
    return text.split('').map((char) => reverseMap[char] ?? char).join('');
  }
}
