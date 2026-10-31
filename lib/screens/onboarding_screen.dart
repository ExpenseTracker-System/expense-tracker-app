import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class OnboardingItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class OnboardingScreen extends StatefulWidget {
  final bool isFromHome;

  const OnboardingScreen({super.key, this.isFromHome = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingItem> _pages = const [
    OnboardingItem(
      title: 'أهلاً بك في محفظتي الذكية',
      description:
          'سجّل إيراداتك ومصروفاتك اليومية بضغطة زر واحدة من الشاشة الرئيسية، مع تحديد الفئة والتاريخ والملاحظات، وسيعمل التطبيق بسرعة فائقة حتى بدون اتصال بالإنترنت!',
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFF1565C0),
    ),
    OnboardingItem(
      title: 'محافظ متعددة لكل احتياجاتك',
      description:
          'اضغط على اسم المحفظة في أعلى الشاشة الرئيسية للتنقل بين محافظك أو إنشاء محافظ جديدة مستقلة (مثل: المحفظة الشخصية، مصاريف العمل، مصاريف المشروع) ولكل محفظة رصيدها وإحصائياتها الخاصة.',
      icon: Icons.folder_copy_rounded,
      color: Color(0xFF00796B),
    ),
    OnboardingItem(
      title: 'بحث ذكي، فلترة، وحذف متعدد',
      description:
          'من "سجل المعاملات" يمكنك البحث بالكلمات أو الفلترة بين تاريخين محددين، كما يمكنك الضغط مطولاً على أي معاملة لتحديد عدة معاملات وحذفها دفعة واحدة، أو فتح شاشة المخطط الدائري لمعرفة أين تذهب أموالك.',
      icon: Icons.pie_chart_rounded,
      color: Color(0xFF6A1B9A),
    ),
    OnboardingItem(
      title: 'حساب سحابي ومزامنة تلقائية',
      description:
          'اضغط على أيقونة السحابة ☁️ أو زر الإعدادات ⚙️ في أعلى الشاشة الرئيسية لإنشاء حسابك السحابي. سيقوم التطبيق بحفظ نسخة احتياطية تلقائية من جميع محافظك ومعاملاتك لتستعيدها من أي هاتف وفي أي وقت!',
      icon: Icons.cloud_sync_rounded,
      color: Color(0xFF2E7D32),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    if (!mounted) return;
    if (widget.isFromHome) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final OnboardingItem currentPage = _pages[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _finishOnboarding,
            child: Text(
              'تخطي',
              style: TextStyle(
                color: currentPage.color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (int index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final item = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: item.color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.icon,
                            size: 80,
                            color: item.color,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: item.color,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          item.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // مؤشر النقاط وأزرار التنقل
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (index) {
                      final bool isSelected = _currentIndex == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 10,
                        width: isSelected ? 28 : 10,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? currentPage.color
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(5),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentIndex < _pages.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _finishOnboarding();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentPage.color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _currentIndex == _pages.length - 1
                            ? 'ابدأ استخدام التطبيق الآن'
                            : 'التالي',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}