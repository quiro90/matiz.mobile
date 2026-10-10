import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'platform/platform_bridge.dart';
import 'state/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final dir = await getApplicationSupportDirectory();
  final controller = AppController(dataDir: dir.path, platform: PlatformBridge())..load();
  runApp(MatizApp(controller: controller));
}
