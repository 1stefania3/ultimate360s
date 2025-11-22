import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Importa tus pantallas
import 'screens/index.dart';
import 'screens/login.dart';
import 'screens/register.dart';
import 'screens/home.dart';
import 'screens/welcome_screen.dart'; 
import 'screens/feed_screen.dart';
import 'screens/cuenta.dart';
import 'screens/miperfil.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Inicializa Firebase
  Future<FirebaseApp> _initializeFirebase() async {
    return await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeFirebase(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return MaterialApp(
            title: 'Ultimate360s',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              fontFamily: 'Montserrat', // Aplica Montserrat en toda la app
            ),
            // 👇 Pantalla inicial actual
            home: const IndexScreen(),
            // 👇 Rutas con nombre
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/home': (context) => HomeScreen(),
              '/index': (context) => const IndexScreen(),
              '/welcome': (context) => const WelcomeScreen(), 
              '/feed': (context) => FeedPage(),
              '/cuenta': (context) => const CuentaPage(),
              '/perfil': (context) => const PerfilPage(),
            


            },
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('Error initializing Firebase: ${snapshot.error}'),
              ),
            ),
          );
        }

        // Mientras se inicializa Firebase
        return const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }
}
