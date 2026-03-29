import 'package:flutter/material.dart';
import 'home_screen.dart';

// أضفنا TickerProviderStateMixin لكي نسمح للشاشة بتشغيل الأنميشن
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  
  // 🔴 متغيرات الأنميشن (الحركة)
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 1. إعداد محرك الحركة (يستغرق ثانيتين)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // 2. حركة الظهور التدريجي (Fade In)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // 3. حركة التكبير والارتداد (Bounce) للأيقونة
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    // 4. تشغيل الأنميشن فور فتح الشاشة
    _animationController.forward();

    // 5. تشغيل مؤقت الانتقال للشاشة الرئيسية
    _navigateToHome();
  }

  // دالة الانتقال بعد انتهاء الوقت
  Future<void>_navigateToHome() async {
    await Future.delayed(const Duration(seconds: 4)); // ننتظر 4 ثواني لنستمتع بالأنميشن
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        // انتقال سلس (Fade) للشاشة الرئيسية بدلاً من الانتقال الحاد
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  // تنظيف الذاكرة من محرك الأنميشن عند الخروج
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        // 🔴 السر الهندسي الأول: التدرج اللوني الفخم (Gradient) للخلفية
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green[800]!, // أخضر غامق جداً
              Colors.green[500]!, // أخضر فاتح
              Colors.teal[700]!,  // لمسة لون أزرق مخضر
            ],
          ),
        ),
        child: Stack(
          children: [
            // 🔴 الطبقة الوسطى: الشعار واسم التطبيق (مع الأنميشن)
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // تصميم الأيقونة داخل دائرة بيضاء بارزة
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha:0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 80,
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // اسم التطبيق
                      const Text(
                        'محفظتي الذكية',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'إدارة أموالك بذكاء وسهولة',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 🔴 الطبقة السفلية: توقيع المهندس (يظهر بتدرج ناعم)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // مؤشر تحميل دائري صغير وأنيق
                    const SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'تم التصميم والتطوير بواسطة',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'المهندس / عمر عارف',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2.0, // تباعد سينمائي بين الحروف
                        shadows: [
                          Shadow(
                            color: Colors.green[900]!,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}