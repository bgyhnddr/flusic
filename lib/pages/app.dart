import '../services/system.dart';
import 'package:flutter/material.dart';
import 'home.dart';
import 'play.dart';

class App extends StatefulWidget {
  @override
  _AppState createState() => new _AppState();
}

class _AppState extends State<App> {
  /// initial app
  ///
  SystemService service = new SystemService();
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: service.musicService.listening >= 0
            ? Play(index: service.musicService.listening)
            : MyHomePage());
  }
}
