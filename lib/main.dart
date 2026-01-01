import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'presentation/providers/allocation_provider.dart';
import 'presentation/providers/certificate_provider.dart';
import 'presentation/providers/employee_provider.dart';
import 'presentation/screens/home/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
        ChangeNotifierProvider(create: (_) => CertificateProvider()),
        ChangeNotifierProvider(create: (_) => AllocationProvider()),
      ],
      child: MaterialApp(
        title: 'BHLD Mobile',
        debugShowCheckedModeBanner: false,

        // Localization
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('vi', 'VN'), // Vietnamese
          Locale('en', 'US'), // English
        ],
        locale: const Locale('vi', 'VN'),

        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
          cardTheme: const CardThemeData(elevation: 2),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
