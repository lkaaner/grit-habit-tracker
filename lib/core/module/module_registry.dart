import 'module_interface.dart';
import '../../features/finance/finance_module.dart';
import '../../features/fitness/fitness_module.dart';
import '../../features/productivity/productivity_module.dart';

class ModuleRegistry {
  ModuleRegistry._();
  static final ModuleRegistry instance = ModuleRegistry._();

  final List<AppModule> _modules = [
    FinanceModule(),
    FitnessModule(),
    ProductivityModule(),
  ];

  List<AppModule> get modules => List.unmodifiable(_modules);

  /// Tüm kayıtlı modüllerin Hive ayarlamalarını başlatır.
  Future<void> initializeModules() async {
    for (var module in _modules) {
      module.registerHiveAdapters();
      await module.initHiveBoxes();
    }
  }

  /// Tüm kayıtlı modüllerin Hive kutularını güvenle kapatır.
  Future<void> disposeModules() async {
    for (var module in _modules) {
      await module.closeHiveBoxes();
    }
  }
}
