import 'package:flutter/material.dart';
import 'package:spendly/achievements_page.dart';
import 'package:spendly/budget_page.dart';
import 'package:spendly/create_account.dart';
import 'package:spendly/homepage.dart';
import 'package:spendly/login_page.dart';
import 'package:spendly/main_screen.dart';
import 'package:spendly/transactions_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: LoginPage(),
    routes: {
      '/create-account': (context) => const CreateAccountPage(),
      '/login': (context) => const LoginPage(),
      '/home': (context) => const HomePage(),
      '/transactions': (context) => const TransactionsPage(),
      '/budget': (context) => const BudgetPage(),
      '/achievements': (context) => const AchievementsPage(),
      '/main': (context) => const MainScreen(),
    },
  ));
}
