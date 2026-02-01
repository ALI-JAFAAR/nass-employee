import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/state/employee_auth_provider.dart';
import 'src/ui/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      create: (_) => EmployeeAuthProvider()..bootstrap(),
      child: const EmployeeApp(),
    ),
  );
}
