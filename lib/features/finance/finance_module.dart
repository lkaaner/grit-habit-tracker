import 'package:hive/hive.dart';
import '../../core/module/module_interface.dart';
import '../../core/database/hive_models.dart';

class FinanceModule implements AppModule {
  @override
  String get moduleName => 'finance';

  @override
  void registerHiveAdapters() {
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(TransactionAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(DebtAdapter());
    }
  }

  @override
  Future<void> initHiveBoxes() async {
    await Hive.openBox<Transaction>('finance_transactions');
    await Hive.openBox<Debt>('finance_debts');
  }

  @override
  Future<void> closeHiveBoxes() async {
    if (Hive.isBoxOpen('finance_transactions')) {
      await Hive.box<Transaction>('finance_transactions').close();
    }
    if (Hive.isBoxOpen('finance_debts')) {
      await Hive.box<Debt>('finance_debts').close();
    }
  }
}
