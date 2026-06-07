import 'package:hive_flutter/hive_flutter.dart';
import '../module/module_registry.dart';

class HiveService {
  HiveService._();
  static final HiveService instance = HiveService._();

  /// Yerel veritabanını ve tüm modüllerin Hive kutularını/adapter'larını başlatır.
  Future<void> init() async {
    // Hive'ı Flutter ve platforma özgü yollarla entegre şekilde başlatır.
    await Hive.initFlutter();
    
    // Tüm kayıtlı modüllerin kendi kutularını ve adapter'larını initialize etmesini sağlar.
    await ModuleRegistry.instance.initializeModules();
  }

  /// Uygulama kapanırken tüm Hive kutularını ve Hive veritabanını güvenle kapatır.
  Future<void> close() async {
    await ModuleRegistry.instance.disposeModules();
    if (Hive.isBoxOpen('system_settings')) {
      await Hive.box('system_settings').close();
    }
    await Hive.close();
  }
}
