<div align="center">

# 💰 محفظتي الذكية — Smart Wallet
### تطبيق إدارة المصاريف الشخصية

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![SQLite](https://img.shields.io/badge/SQLite-Local%20DB-003B57?style=for-the-badge&logo=sqlite&logoColor=white)](https://pub.dev/packages/sqflite)
[![Provider](https://img.shields.io/badge/Provider-State%20Mgmt-7B68EE?style=for-the-badge)](https://pub.dev/packages/provider)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

<br/>

> تطبيق Flutter احترافي لتتبع وإدارة المصاريف الشخصية بشكل ذكي وسهل، مع دعم كامل للغة العربية واتجاه RTL.

</div>

---

## 📋 جدول المحتويات

- [نظرة عامة](#-نظرة-عامة)
- [المميزات](#-المميزات)
- [لقطات الشاشة](#-لقطات-الشاشة)
- [التقنيات المستخدمة](#-التقنيات-المستخدمة)
- [هيكل المشروع](#-هيكل-المشروع)
- [المعمارية](#-المعمارية)
- [كيفية التثبيت والتشغيل](#-كيفية-التثبيت-والتشغيل)
- [كيفية الاستخدام](#-كيفية-الاستخدام)
- [المطور](#-المطور)

---

## 🌟 نظرة عامة

**محفظتي الذكية** هو تطبيق موبايل مبني بإطار عمل Flutter، يتيح للمستخدم تتبع إيراداته ومصروفاته اليومية بكل سهولة ووضوح. يعمل التطبيق بالكامل بشكل محلي (Offline First) دون الحاجة للإنترنت، مع حفظ جميع البيانات بشكل دائم على الجهاز باستخدام قاعدة بيانات SQLite.

---

## ✨ المميزات

| الميزة | الوصف |
|--------|-------|
| 🏠 **لوحة التحكم الرئيسية** | عرض الرصيد الحالي، إجمالي الإيرادات والمصروفات في لمحة واحدة |
| ➕ **إضافة إيراد / مصروف** | نموذج كامل مع التحقق من صحة البيانات واختيار التاريخ |
| ✏️ **تعديل المعاملات** | إمكانية تعديل أي معاملة سابقة بضغطة واحدة |
| 🗑️ **حذف بالسحب** | سحب الكرت لحذف المعاملة مع نافذة تأكيد لتفادي الحذف الخاطئ |
| 📊 **إحصائيات بيانية** | مخطط دائري تفاعلي يُوزّع المصروفات على الفئات بنسب مئوية |
| 🏷️ **فئات مخصصة** | إضافة فئات دخل ومصروف مخصصة تُحفظ بشكل دائم |
| 💱 **دعم عملات متعددة** | اختيار العملة (ريال، دولار، يورو، درهم، دينار، جنيه) وتطبيقها فوراً |
| 🌙 **شاشة ترحيب متحركة** | Splash Screen أنيقة مع تأثيرات Fade + Scale animations |
| 🇸🇦 **دعم اللغة العربية** | واجهة عربية كاملة مع اتجاه RTL |
| 💾 **تخزين محلي دائم** | جميع البيانات تُحفظ على الجهاز ولا تُفقَد عند إغلاق التطبيق |

---

## 📱 لقطات الشاشة

<div align="center">

| شاشة البداية | الشاشة الرئيسية | إضافة معاملة |
|:---:|:---:|:---:|
| *Splash Screen* | *Home Screen* | *Add Transaction* |

| سجل المعاملات | الإحصائيات | الإعدادات |
|:---:|:---:|:---:|
| *Transactions List* | *Statistics* | *Settings Dialog* |

</div>

---

## 🛠️ التقنيات المستخدمة

### الحزم الأساسية (Dependencies)

| الحزمة | الإصدار | الغرض |
|--------|---------|-------|
| [`sqflite`](https://pub.dev/packages/sqflite) | `any` | قاعدة بيانات SQLite للتخزين المحلي |
| [`path`](https://pub.dev/packages/path) | `any` | بناء مسارات الملفات بشكل آمن |
| [`shared_preferences`](https://pub.dev/packages/shared_preferences) | `any` | حفظ الإعدادات (العملة، الفئات) |
| [`provider`](https://pub.dev/packages/provider) | `^6.1.2` | إدارة الحالة (State Management) |
| [`pie_chart`](https://pub.dev/packages/pie_chart) | `^5.4.0` | رسم المخططات الدائرية التفاعلية |
| [`intl`](https://pub.dev/packages/intl) | `any` | دعم التنسيق الدولي والتواريخ |
| [`flutter_localizations`](https://docs.flutter.dev/development/accessibility-and-localization/internationalization) | SDK | دعم اللغة العربية واتجاه RTL |

### أدوات التطوير (Dev Dependencies)

| الحزمة | الغرض |
|--------|-------|
| [`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons) | توليد أيقونات التطبيق تلقائياً |
| [`flutter_lints`](https://pub.dev/packages/flutter_lints) | قواعد جودة الكود |

---

## 📁 هيكل المشروع

```
expense_tracker/
│
├── lib/
│   ├── main.dart                          # نقطة الدخول + إعداد Provider + MaterialApp
│   │
│   ├── models/
│   │   └── transaction_model.dart         # كيان البيانات (Data Entity)
│   │
│   ├── data/
│   │   └── database_helper.dart           # طبقة الوصول للبيانات (DAL) — SQLite Singleton
│   │
│   ├── providers/
│   │   └── transaction_provider.dart      # إدارة الحالة + Business Logic
│   │
│   ├── screens/
│   │   ├── splash_screen.dart             # شاشة البداية مع الأنيميشن
│   │   ├── home_screen.dart               # الشاشة الرئيسية — لوحة التحكم
│   │   ├── add_transaction_screen.dart    # إضافة / تعديل معاملة
│   │   ├── transactions_list_screen.dart  # سجل جميع المعاملات
│   │   └── statistics_screen.dart         # الإحصائيات والمخطط الدائري
│   │
│   └── widgets/                           # (جاهز للتوسع — مكونات مشتركة)
│
├── assets/
│   └── icons/
│       └── app_icon.png                   # أيقونة التطبيق
│
├── pubspec.yaml                           # تعريف المشروع والحزم
└── README.md                              # هذا الملف
```

---

## 🏗️ المعمارية

يتبع المشروع نمط **Layered Architecture** مع **Provider Pattern** لإدارة الحالة:

```
┌─────────────────────────────────────────────┐
│           Presentation Layer                │
│    (Screens + Widgets — UI فقط)             │
├─────────────────────────────────────────────┤
│           Business Logic Layer              │
│       (TransactionProvider — Provider)      │
├─────────────────────────────────────────────┤
│          Data Access Layer                  │
│       (DatabaseHelper — SQLite)             │
├─────────────────────────────────────────────┤
│              Data Layer                     │
│    (TransactionModel — Entity/DTO)          │
└─────────────────────────────────────────────┘
```

### أنماط التصميم المستخدمة:
- **Singleton Pattern** — `DatabaseHelper` لضمان instance واحدة لقاعدة البيانات
- **Observer Pattern** — `ChangeNotifier` + `Consumer` لتحديث الواجهة تلقائياً
- **Repository-like Pattern** — فصل منطق البيانات عن الواجهة

---

## 🚀 كيفية التثبيت والتشغيل

### المتطلبات الأساسية

قبل البدء، تأكد من تثبيت المتطلبات التالية:

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (الإصدار 3.x أو أحدث)
- [Dart SDK](https://dart.dev/get-dart) (الإصدار 3.x أو أحدث)
- [Android Studio](https://developer.android.com/studio) أو [VS Code](https://code.visualstudio.com/)
- جهاز Android / iOS أو محاكي (Emulator)

### خطوات التثبيت

**1. استنساخ المستودع (Clone the Repository)**
```bash
git clone https://github.com/omararef775/expense-tracker-app.git
cd expense_tracker
```

**2. تثبيت الحزم (Install Dependencies)**
```bash
flutter pub get
```

**3. التحقق من البيئة (Verify Setup)**
```bash
flutter doctor
```

**4. تشغيل التطبيق (Run the App)**
```bash
# تشغيل في وضع التطوير
flutter run

# تشغيل على محاكي محدد
flutter run -d emulator-5554

# تشغيل على جهاز حقيقي
flutter run -d <device-id>
```

**5. بناء ملف APK للأندرويد (Build Release APK)**
```bash
flutter build apk --release
```
> ملف الـ APK سيكون في: `build/app/outputs/flutter-apk/app-release.apk`

---

## 📖 كيفية الاستخدام

### إضافة معاملة جديدة
1. من الشاشة الرئيسية، اضغط **"إضافة إيراد"** (أخضر) أو **"إضافة مصروف"** (أحمر)
2. أدخل المبلغ، اختر الفئة، وأضف ملاحظة اختيارية
3. اضغط **"حفظ المعاملة"** — ستظهر في القائمة فوراً

### تعديل معاملة
1. اذهب إلى **"عرض سجل المعاملات بالكامل"**
2. اضغط على أي معاملة لفتح شاشة التعديل
3. عدّل البيانات واضغط **"تحديث المعاملة"**

### حذف معاملة
1. في شاشة سجل المعاملات، **اسحب الكرت من اليمين لليسار**
2. ستظهر نافذة تأكيد — اضغط **"حذف"** لتأكيد العملية

### عرض الإحصائيات
- اضغط على أيقونة 📊 في الشريط العلوي للانتقال لشاشة الإحصائيات

### تغيير العملة
- اضغط على أيقونة ⚙️ في الشريط العلوي، واختر عملتك المفضلة

### إضافة فئة مخصصة
- عند إضافة معاملة، اضغط زر ➕ بجانب قائمة الفئات وأدخل اسم الفئة الجديدة

---

## 📊 نموذج البيانات (Data Model)

```dart
class TransactionModel {
  final String   id;         // معرّف فريد (Timestamp)
  final double   amount;     // المبلغ (موجب دائماً)
  final String   category;   // الفئة (طعام، مواصلات، راتب...)
  final String   note;       // ملاحظة اختيارية
  final DateTime date;       // تاريخ المعاملة
  final bool     isIncome;   // true = إيراد | false = مصروف
}
```

---

## 🤝 المساهمة (Contributing)

المساهمات مرحب بها! للمساهمة في المشروع:

1. **Fork** المستودع
2. أنشئ فرعاً جديداً: `git checkout -b feature/amazing-feature`
3. أضف تعديلاتك: `git commit -m 'Add: amazing feature'`
4. ادفع التعديلات: `git push origin feature/amazing-feature`
5. افتح **Pull Request**

### اقتراحات للتطوير المستقبلي
- [ ] إضافة وضع الثيم الداكن (Dark Mode)
- [ ] تصدير البيانات كـ PDF أو Excel
- [ ] إضافة ميزة الميزانية الشهرية (Budget Planner)
- [ ] إضافة تنبيهات عند تجاوز الميزانية
- [ ] مزامنة البيانات مع السحابة (Firebase)
- [ ] إضافة رسوم بيانية للإيرادات والمصروفات خلال الشهر
- [ ] دعم لغات إضافية (English, Français)

---

## 📄 الترخيص (License)

هذا المشروع مرخص بموجب [رخصة MIT](LICENSE).

```
MIT License — يمكنك الاستخدام، التعديل، والتوزيع بحرية مع ذكر المصدر.
```

---

<div align="center">

## 👨‍💻 المطور

**المهندس / عمر عارف**

[![GitHub](https://img.shields.io/badge/GitHub-Follow-181717?style=for-the-badge&logo=github)](https://github.com/omararef775)

<br/>

*"أدر أموالك بذكاء وسهولة"* 💡

<br/>

⭐ **إذا أعجبك المشروع، لا تنسَ إضافة نجمة Star على GitHub!** ⭐

</div>
