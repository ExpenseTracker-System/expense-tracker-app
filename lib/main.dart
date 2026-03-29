import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // حزمة دعم اللغات
import 'package:provider/provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(create: (context) => TransactionProvider(),
    child: const ExpenseTrackerApp(),),
  );
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'إدارة المصاريف', // اسم التطبيق
      debugShowCheckedModeBanner: false, // هذه تخفي شريط "Debug" الأحمر المزعج من الزاوية
      
      // -- إعدادات دعم اللغة العربية (RTL) --
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'AE'), // نحدد أن لغتنا الأساسية هي العربية
      ],
      
      // -- الثيم المبدئي للتطبيق --
      theme: ThemeData(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100], // لون خلفية مريح للعين يشبه الصور المرفقة
      ),
      
      // -- الشاشة المؤقتة حتى نبني الشاشة الرئيسية --
      home: const SplashScreen(),
      
    );
  }
}