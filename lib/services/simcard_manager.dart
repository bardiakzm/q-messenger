import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_number/mobile_number.dart';

final selectedSimProvider = StateProvider<int>((ref) => 0);
final simCardProvider = StateProvider<List<SimCard>>((ref) => []);

class SimManager {
  static Future<List<SimCard>> getSimCards() async {
    print('getting sim info');

    // Request multiple permissions
    Map<Permission, PermissionStatus> statuses =
        await [
          Permission.phone,
          Permission.contacts, // Some devices need this for SIM access
        ].request();

    if (statuses[Permission.phone]!.isGranted) {
      print('phone permission granted');

      try {
        List<SimCard> sims = await MobileNumber.getSimCards ?? [];
        print('number of simcards: ${sims.length}');
        return sims;
      } catch (e) {
        print('Error getting SIM cards: $e');
        return [];
      }
    } else {
      print('phone permission denied');
      return [];
    }
  }
}

final loadSimProvider = FutureProvider<void>((ref) async {
  final sims = await SimManager.getSimCards();
  ref.watch(simCardProvider.notifier).update((state) => sims ?? []);
});
