import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'pages/pizza_home_page.dart';
import 'services/cart_service.dart';
import 'services/order_service.dart';
import 'constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser les données de localisation française
  await initializeDateFormatting(AppConstants.frenchLocale, null);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartService()),
        ChangeNotifierProvider(create: (_) => OrderService()),
      ],
      child: MaterialApp(
        title: 'TurboPizza',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const PizzaHomePage(),
      ),
    );
  }
}
