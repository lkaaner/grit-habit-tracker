import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/database/hive_service.dart';
import 'features/finance/presentation/pages/finance_page.dart';
import 'features/fitness/presentation/pages/fitness_page.dart';
import 'features/productivity/presentation/pages/productivity_page.dart';

import 'core/providers/system_provider.dart';

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

class DashboardShell extends ConsumerStatefulWidget {
  const DashboardShell({super.key});

  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell> {
  @override
  void dispose() {
    // Uygulama kapanırken Hive kutularını güvenle kapat
    HiveService.instance.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final systemState = ref.watch(systemProvider);

    final activeTabs = <Map<String, dynamic>>[];
    
    if (systemState.isFinanceEnabled) {
      activeTabs.add({
        'item': const BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.money_dollar),
          label: '',
        ),
        'builder': (BuildContext context) => const FinancePage(),
      });
    }
    
    if (systemState.isFitnessEnabled) {
      activeTabs.add({
        'item': const BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.heart_fill),
          label: '',
        ),
        'builder': (BuildContext context) => const FitnessPage(),
      });
    }
    
    if (systemState.isProductivityEnabled) {
      activeTabs.add({
        'item': const BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.checkmark_circle),
          label: '',
        ),
        'builder': (BuildContext context) => const ProductivityPage(),
      });
    }

    // Güvenlik önlemi: Eğer hepsi kapalıysa (normalde olamaz) varsayılan olarak finans göster
    if (activeTabs.isEmpty) {
      activeTabs.add({
        'item': const BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.money_dollar),
          label: '',
        ),
        'builder': (BuildContext context) => const FinancePage(),
      });
    }

    final String tabsKey = '${systemState.isFinanceEnabled}_${systemState.isFitnessEnabled}_${systemState.isProductivityEnabled}';

    return CupertinoTabScaffold(
      key: ValueKey(tabsKey),
      tabBar: CupertinoTabBar(
        backgroundColor: const Color(0xFF16171D),
        activeColor: const Color(0xFF8B5CF6),
        inactiveColor: const Color(0xFF9EA0A5),
        border: const Border(
          top: BorderSide(color: Color(0xFF2C2C35), width: 0.5),
        ),
        items: activeTabs.map((t) => t['item'] as BottomNavigationBarItem).toList(),
      ),
      tabBuilder: (BuildContext context, int index) {
        return CupertinoTabView(
          builder: (BuildContext context) {
            if (index < activeTabs.length) {
              return (activeTabs[index]['builder'] as WidgetBuilder)(context);
            }
            return const FinancePage();
          },
        );
      },
    );
  }
}
