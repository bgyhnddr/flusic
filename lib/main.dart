import 'package:flutter/material.dart';

import 'pages/app.dart';
import 'utils/initial.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initial();
  runApp(App());
}
