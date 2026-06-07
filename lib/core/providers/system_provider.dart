import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/finance/presentation/controllers/finance_provider.dart';
import '../../features/fitness/presentation/controllers/fitness_provider.dart';
import '../../features/productivity/presentation/controllers/productivity_provider.dart';
import '../database/hive_models.dart';

class SystemState {
  final DateTime lastCheckedDate;
  final String backupStatus; // 'idle', 'loading', 'success', 'error'
  final String lastBackupPath;
  final String? backupJsonText;
  final bool isFinanceEnabled;
  final bool isFitnessEnabled;
  final bool isProductivityEnabled;

  SystemState({
    required this.lastCheckedDate,
    required this.backupStatus,
    required this.lastBackupPath,
    this.backupJsonText,
    this.isFinanceEnabled = true,
    this.isFitnessEnabled = true,
    this.isProductivityEnabled = true,
  });

  SystemState copyWith({
    DateTime? lastCheckedDate,
    String? backupStatus,
    String? lastBackupPath,
    String? backupJsonText,
    bool? isFinanceEnabled,
    bool? isFitnessEnabled,
    bool? isProductivityEnabled,
  }) {
    return SystemState(
      lastCheckedDate: lastCheckedDate ?? this.lastCheckedDate,
      backupStatus: backupStatus ?? this.backupStatus,
      lastBackupPath: lastBackupPath ?? this.lastBackupPath,
      backupJsonText: backupJsonText ?? this.backupJsonText,
      isFinanceEnabled: isFinanceEnabled ?? this.isFinanceEnabled,
      isFitnessEnabled: isFitnessEnabled ?? this.isFitnessEnabled,
      isProductivityEnabled: isProductivityEnabled ?? this.isProductivityEnabled,
    );
  }
}

class SystemNotifier extends StateNotifier<SystemState> {
  final Ref ref;
  Timer? _ticker;
  late final Box _settingsBox;

  SystemNotifier(this.ref)
      : super(SystemState(
          lastCheckedDate: DateTime.now(),
          backupStatus: 'idle',
          lastBackupPath: '',
          isFinanceEnabled: true,
          isFitnessEnabled: true,
          isProductivityEnabled: true,
        ));

  Future<void> init() async {
    _settingsBox = await Hive.openBox('system_settings');
    final isFinance = _settingsBox.get('isFinanceEnabled', defaultValue: true) as bool;
    final isFitness = _settingsBox.get('isFitnessEnabled', defaultValue: true) as bool;
    final isProductivity = _settingsBox.get('isProductivityEnabled', defaultValue: true) as bool;

    state = state.copyWith(
      isFinanceEnabled: isFinance,
      isFitnessEnabled: isFitness,
      isProductivityEnabled: isProductivity,
    );

    // Her 10 saniyede bir gün değişimini reaktif olarak kontrol et
    _ticker = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkMidnightReset();
    });
  }

  void toggleModule(String module) {
    if (module == 'finance') {
      if (state.isFinanceEnabled && !state.isFitnessEnabled && !state.isProductivityEnabled) return;
      final newValue = !state.isFinanceEnabled;
      _settingsBox.put('isFinanceEnabled', newValue);
      state = state.copyWith(isFinanceEnabled: newValue);
    } else if (module == 'fitness') {
      if (state.isFitnessEnabled && !state.isFinanceEnabled && !state.isProductivityEnabled) return;
      final newValue = !state.isFitnessEnabled;
      _settingsBox.put('isFitnessEnabled', newValue);
      state = state.copyWith(isFitnessEnabled: newValue);
    } else if (module == 'productivity') {
      if (state.isProductivityEnabled && !state.isFinanceEnabled && !state.isFitnessEnabled) return;
      final newValue = !state.isProductivityEnabled;
      _settingsBox.put('isProductivityEnabled', newValue);
      state = state.copyWith(isProductivityEnabled: newValue);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _checkMidnightReset() {
    final now = DateTime.now();
    final lastDate = state.lastCheckedDate;
    if (now.year != lastDate.year ||
        now.month != lastDate.month ||
        now.day != lastDate.day) {
      // Gün değişmiş! Sayaçları reaktif olarak sıfırla
      state = state.copyWith(lastCheckedDate: now);
      
      // Diğer sağlayıcıları yeni tarihe göre yeniden sorgulamaya zorla
      ref.read(productivityProvider.notifier).loadTodayData();
      ref.read(fitnessProvider.notifier).loadTodayData();
    }
  }

  /// Tüm Hive kutularındaki verileri tek bir JSON dosyası olarak yerel hafızaya kaydeder.
  Future<void> createBackup() async {
    state = state.copyWith(backupStatus: 'loading');
    try {
      final todosBox = Hive.box<Todo>('productivity_todos');
      final notesBox = Hive.box<Note>('productivity_notes');
      final caloriesBox = Hive.box<CalorieLog>('fitness_calories');
      final waterBox = Hive.box<WaterLog>('fitness_water');
      final workoutsBox = Hive.box<WorkoutLog>('fitness_workouts');
      final weightsBox = Hive.box<WeightLog>('fitness_weights');
      final transactionsBox = Hive.box<Transaction>('finance_transactions');
      final debtsBox = Hive.box<Debt>('finance_debts');

      final dataMap = {
        'todos': todosBox.values.map((e) => e.toJson()).toList(),
        'notes': notesBox.values.map((e) => e.toJson()).toList(),
        'calories': caloriesBox.values.map((e) => e.toJson()).toList(),
        'water': waterBox.values.map((e) => e.toJson()).toList(),
        'workouts': workoutsBox.values.map((e) => e.toJson()).toList(),
        'weights': weightsBox.values.map((e) => e.toJson()).toList(),
        'transactions': transactionsBox.values.map((e) => e.toJson()).toList(),
        'debts': debtsBox.values.map((e) => e.toJson()).toList(),
      };

      final jsonString = jsonEncode(dataMap);
      
      // Doküman dizinine kaydet (iOS Files uygulamasında görünmesi için)
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/personal_dashboard_backup.json');
      await file.writeAsString(jsonString);

      state = state.copyWith(
        backupStatus: 'success',
        lastBackupPath: file.path,
        backupJsonText: jsonString,
      );
    } catch (e) {
      state = state.copyWith(backupStatus: 'error: $e');
    }
  }

  /// Yerel hafızadaki yedek dosyasından verileri geri yükler.
  Future<bool> restoreBackupFromFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/personal_dashboard_backup.json');
      if (!await file.exists()) {
        state = state.copyWith(backupStatus: 'error: Yedek dosyası bulunamadı.');
        return false;
      }

      final jsonString = await file.readAsString();
      return await _restoreFromJson(jsonString);
    } catch (e) {
      state = state.copyWith(backupStatus: 'error: $e');
      return false;
    }
  }

  /// Kopyalanmış bir JSON metninden verileri geri yükler (Clipboard/Yedek kopyalama alanı için).
  Future<bool> restoreBackupFromText(String jsonString) async {
    try {
      return await _restoreFromJson(jsonString);
    } catch (e) {
      state = state.copyWith(backupStatus: 'error: Geçersiz yedek verisi.');
      return false;
    }
  }

  Future<bool> _restoreFromJson(String jsonString) async {
    try {
      final Map<String, dynamic> dataMap = jsonDecode(jsonString);

      final todosBox = Hive.box<Todo>('productivity_todos');
      final notesBox = Hive.box<Note>('productivity_notes');
      final caloriesBox = Hive.box<CalorieLog>('fitness_calories');
      final waterBox = Hive.box<WaterLog>('fitness_water');
      final workoutsBox = Hive.box<WorkoutLog>('fitness_workouts');
      final weightsBox = Hive.box<WeightLog>('fitness_weights');
      final transactionsBox = Hive.box<Transaction>('finance_transactions');
      final debtsBox = Hive.box<Debt>('finance_debts');

      // Kutuları güvenle boşalt
      await todosBox.clear();
      await notesBox.clear();
      await caloriesBox.clear();
      await waterBox.clear();
      await workoutsBox.clear();
      await weightsBox.clear();
      await transactionsBox.clear();
      await debtsBox.clear();

      // JSON'dan verileri okuyup kutulara yaz
      if (dataMap['todos'] != null) {
        for (var item in dataMap['todos']) {
          await todosBox.add(Todo.fromJson(item));
        }
      }
      if (dataMap['notes'] != null) {
        for (var item in dataMap['notes']) {
          await notesBox.add(Note.fromJson(item));
        }
      }
      if (dataMap['calories'] != null) {
        for (var item in dataMap['calories']) {
          await caloriesBox.add(CalorieLog.fromJson(item));
        }
      }
      if (dataMap['water'] != null) {
        for (var item in dataMap['water']) {
          await waterBox.add(WaterLog.fromJson(item));
        }
      }
      if (dataMap['workouts'] != null) {
        for (var item in dataMap['workouts']) {
          await workoutsBox.add(WorkoutLog.fromJson(item));
        }
      }
      if (dataMap['weights'] != null) {
        for (var item in dataMap['weights']) {
          await weightsBox.add(WeightLog.fromJson(item));
        }
      }
      if (dataMap['transactions'] != null) {
        for (var item in dataMap['transactions']) {
          await transactionsBox.add(Transaction.fromJson(item));
        }
      }
      if (dataMap['debts'] != null) {
        for (var item in dataMap['debts']) {
          await debtsBox.add(Debt.fromJson(item));
        }
      }

      // Veriler yenilendiği için tüm sağlayıcıları güncellemeye zorla
      ref.read(productivityProvider.notifier).loadTodayData();
      ref.read(fitnessProvider.notifier).loadTodayData();
      ref.read(financeProvider.notifier).loadData();

      state = state.copyWith(backupStatus: 'success');
      return true;
    } catch (e) {
      state = state.copyWith(backupStatus: 'error: $e');
      return false;
    }
  }

  /// Tüm veritabanını tamamen sıfırlar.
  Future<void> clearAllData() async {
    await Hive.box<Todo>('productivity_todos').clear();
    await Hive.box<Note>('productivity_notes').clear();
    await Hive.box<CalorieLog>('fitness_calories').clear();
    await Hive.box<WaterLog>('fitness_water').clear();
    await Hive.box<WorkoutLog>('fitness_workouts').clear();
    await Hive.box<WeightLog>('fitness_weights').clear();
    await Hive.box<Transaction>('finance_transactions').clear();
    await Hive.box<Debt>('finance_debts').clear();

    ref.read(productivityProvider.notifier).loadTodayData();
    ref.read(fitnessProvider.notifier).loadTodayData();
    ref.read(financeProvider.notifier).loadData();
  }
}

final systemProvider = StateNotifierProvider<SystemNotifier, SystemState>((ref) {
  return SystemNotifier(ref)..init();
});
