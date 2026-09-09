import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'theme.dart';
import 'views/root_view.dart';

void main() {
  runApp(const VoidTerminalApp());
}

class VoidTerminalApp extends StatelessWidget {
  const VoidTerminalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: '虚空终端',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.dark),
        darkTheme: buildTheme(Brightness.dark),
        home: const RootView(),
      ),
    );
  }
}
