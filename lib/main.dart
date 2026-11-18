import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/bacheca_screen.dart';
import 'services/sessione.dart';

/// Permette alla bacheca di sapere quando torna in primo piano.
final routeObserver = RouteObserver<ModalRoute<void>>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('it_IT');
  final sessione = await Sessione.carica();
  runApp(BachecaApp(sessione: sessione));
}

class BachecaApp extends StatelessWidget {
  const BachecaApp({super.key, required this.sessione});

  final Sessione sessione;

  @override
  Widget build(BuildContext context) {
    return SessioneScope(
      sessione: sessione,
      child: MaterialApp(
        title: 'Bacheca Lavoro',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme:
              ColorScheme.fromSeed(seedColor: const Color(0xFF0B6E4F)),
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
        ),
        navigatorObservers: [routeObserver],
        home: const BachecaScreen(),
      ),
    );
  }
}
