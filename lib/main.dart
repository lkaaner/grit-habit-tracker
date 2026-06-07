import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/database/hive_service.dart';
import 'features/finance/presentation/pages/finance_page.dart';
import 'features/fitness/presentation/pages/fitness_page.dart';
import 'features/productivity/presentation/pages/productivity_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Hive yerel veritabanı altyapısını ve modül kutularını başlat
  try {
    await HiveService.instance.init();
    debugPrint("Hive veritabanı altyapısı başarıyla başlatıldı.");
  } catch (e) {
    debugPrint("Hive başlatılırken hata oluştu: $e");
  }

  // Riverpod ProviderScope ile uygulamayı sarmalıyoruz
  runApp(
    const ProviderScope(
      child: PersonalDashboardApp(),
    ),
  );
}

class PersonalDashboardApp extends StatelessWidget {
  const PersonalDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      theme: CupertinoThemeData(
        primaryColor: const Color(0xFF8B5CF6), // Lila/Mor accent
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090A0F),
        barBackgroundColor: const Color(0xFF16171D),
        textTheme: CupertinoTextThemeData(
          textStyle: GoogleFonts.outfit(color: CupertinoColors.white),
          navTitleTextStyle: GoogleFonts.outfit(color: CupertinoColors.white, fontWeight: FontWeight.bold),
          navLargeTitleTextStyle: GoogleFonts.outfit(color: CupertinoColors.white, fontWeight: FontWeight.bold),
        ),
      ),
      home: const DashboardShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  @override
  void dispose() {
    // Uygulama kapanırken Hive kutularını güvenle kapat
    HiveService.instance.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: const Color(0xFF16171D),
        activeColor: const Color(0xFF8B5CF6),
        inactiveColor: const Color(0xFF9EA0A5),
        border: const Border(
          top: BorderSide(color: Color(0xFF2C2C35), width: 0.5),
        ),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.money_dollar),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.heart_fill),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.checkmark_circle),
            label: '',
          ),
        ],
      ),
      tabBuilder: (BuildContext context, int index) {
        return CupertinoTabView(
          builder: (BuildContext context) {
            switch (index) {
              case 0:
                return const FinancePage();
              case 1:
                return const FitnessPage();
              case 2:
                return const ProductivityPage();
              default:
                return const FinancePage();
            }
          },
        );
      },
    );
  }
}
