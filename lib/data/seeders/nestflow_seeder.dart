import 'package:nestflow/core/constants/app_strings.dart';

import 'export.dart';
import 'seeder.dart';

class NestFlowSeeder extends Seeder {
  @override
  Future<void> seed() async {
    // TODO: Enhancement
    if (!AppStrings.isDemo) {
      await CategorySeeder().seed();
      await WalletSeeder().seed();
    }
  }
}
