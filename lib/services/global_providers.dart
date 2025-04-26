import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionNotifier extends StateNotifier<List<String>> {
  PermissionNotifier() : super([]);

  Future<void> checkPermissions() async {
    final List<String> notGranted = await _checkAllPermissions();
    state = notGranted;
  }

  Future<List<String>> _checkAllPermissions() async {
    var smsStatus = await Permission.sms.status;
    var phoneStatus = await Permission.phone.status;
    var contactsStatus = await Permission.contacts.status;

    List<String> notGrantedPerms = [];
    if (!smsStatus.isGranted) {
      notGrantedPerms.add('sms');
    }
    if (!phoneStatus.isGranted) {
      notGrantedPerms.add('phone');
    }
    if (!contactsStatus.isGranted) {
      notGrantedPerms.add('contacts');
    }
    return notGrantedPerms;
  }
}

final permissionProvider =
    StateNotifierProvider<PermissionNotifier, List<String>>((ref) {
      return PermissionNotifier();
    });
