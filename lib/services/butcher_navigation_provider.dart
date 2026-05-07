import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ButcherScreen {
  dashboard,
  animalIntake,
  slaughterLog,
  meatProcessing,
  batchManagement,
  stockTransfer,
  inventory,
  orders,
  wasteManagement,
  documents,
  reports,
  settings,
  profile,
  howToUse
}

class ButcherNavigationNotifier extends StateNotifier<ButcherScreen> {
  ButcherNavigationNotifier() : super(ButcherScreen.dashboard);

  void setScreen(ButcherScreen screen) => state = screen;
}

final butcherNavProvider = StateNotifierProvider<ButcherNavigationNotifier, ButcherScreen>((ref) {
  return ButcherNavigationNotifier();
});
