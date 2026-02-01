import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/cart_provider.dart';
import '../state/catalog_provider.dart';
import '../state/customer_provider.dart';
import '../state/employee_auth_provider.dart';
import '../state/order_provider.dart';
import '../state/reports_provider.dart';
import '../state/governorates_provider.dart';
import '../state/modon_locations_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';
import 'theme.dart';

class EmployeeApp extends StatelessWidget {
  const EmployeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CatalogProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ReportsProvider()),
        ChangeNotifierProvider(create: (_) => GovernoratesProvider()..load()),
        ChangeNotifierProvider(create: (_) => ModonLocationsProvider()..loadCities()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Employee',
        theme: AppTheme.build(),
        builder: (context, child) {
          // Arabic-first UX: force RTL for a more natural layout.
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: Consumer<EmployeeAuthProvider>(
          builder: (context, auth, _) {
            if (auth.loading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (auth.authed) return const HomeShell();
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}

