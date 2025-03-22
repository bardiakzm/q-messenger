import 'package:flutter/material.dart';
import 'package:q_messenger/services/sms_service.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsImportScreen extends StatefulWidget {
  @override
  _SmsImportScreenState createState() => _SmsImportScreenState();
}

class _SmsImportScreenState extends State<SmsImportScreen> {
  List<SmsMessage> _messages = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _requestPermissionAndLoadMessages();
  }

  Future<void> _requestPermissionAndLoadMessages() async {
    setState(() => _loading = true);

    var status = await Permission.sms.status;
    if (!status.isGranted) {
      status = await Permission.sms.request();
      if (!status.isGranted) {
        setState(() => _loading = false);
        return;
      }
    }

    final messages = await SmsService.getAllMessages();
    setState(() {
      _messages = messages;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SMS Messages')),
      body:
          _loading
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return ListTile(
                    title: Text(message.address),
                    subtitle: Text(message.body),
                    trailing: Text(
                      message.dateTime.toString().substring(0, 16),
                    ),
                  );
                },
              ),
    );
  }
}
