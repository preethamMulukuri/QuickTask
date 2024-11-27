import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import './login_page.dart';
import './home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Parse().initialize(
    'teuDJCMqZPnN6QmZyyAqAP48exGAnJR1SmOpniKv', // Replace with Application ID
    'https://parseapi.back4app.com', // Back4App API URL
    clientKey: 'roYtvS3HqOoMS5WTuy8csmmzUX0gM2CWOA3BevCx', // Replace with Client Key
    autoSendSessionId: true
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quick Task',
      theme: ThemeData(
        primarySwatch: Colors.blue, // Customize the theme if needed
      ),
      initialRoute: '/', // The first screen shown when the app starts
      routes: {
        '/': (context) => LoginPage(), // Login page route
        '/home': (context) => HomePage(), // Home page route
      },
    );
  }
}