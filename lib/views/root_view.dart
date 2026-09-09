import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import 'auth_view.dart';
import 'home_view.dart';

class RootView extends StatelessWidget {
  const RootView({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return app.token == null ? const AuthView() : const HomeView();
  }
}
