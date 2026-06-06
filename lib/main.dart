import 'package:flutter/material.dart';
//import 'package:gspr/LoginScreen.dart';
//import 'HomeScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'telateste.dart'; // Import da tela de teste
import 'firebase_options.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Basta trocar HomeScreen() por LoginScreen() aqui:
      home: const WidgetTestScreen(),
    );
  }
}