import 'package:flutter/material.dart';
import 'package:q_messenger/pages/conversation_list_screen.dart';
import 'package:q_messenger/pages/import_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  print('started loading env');
  await dotenv.load();
  print('loaded env');
  runApp(SecureSMSApp());
}

class SecureSMSApp extends StatelessWidget {
  const SecureSMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure SMS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      themeMode: ThemeMode.system,
      home: ConversationListScreen(),
      // home: SmsImportScreen(),
    );
  }
}
