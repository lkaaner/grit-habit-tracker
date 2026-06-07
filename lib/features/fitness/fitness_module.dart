import 'package:hive/hive.dart';
import '../../core/module/module_interface.dart';
import '../../core/database/hive_models.dart';

class FitnessModule implements AppModule {
  @override
  String get moduleName => 'fitness';

  @override
  void registerHiveAdapters() {
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(CalorieLogAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(WaterLogAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(WorkoutLogAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(WeightLogAdapter());
    }
  }

  @override
  Future<void> initHiveBoxes() async {
    await Hive.openBox<CalorieLog>('fitness_calories');
    await Hive.openBox<WaterLog>('fitness_water');
    await Hive.openBox<WorkoutLog>('fitness_workouts');
    await Hive.openBox<WeightLog>('fitness_weights');
    await Hive.openBox<String>('fitness_templates');
    await Hive.openBox<String>('fitness_offdays');
    await Hive.openBox('fitness_settings');
  }

  @override
  Future<void> closeHiveBoxes() async {
    if (Hive.isBoxOpen('fitness_calories')) {
      await Hive.box<CalorieLog>('fitness_calories').close();
    }
    if (Hive.isBoxOpen('fitness_water')) {
      await Hive.box<WaterLog>('fitness_water').close();
    }
    if (Hive.isBoxOpen('fitness_workouts')) {
      await Hive.box<WorkoutLog>('fitness_workouts').close();
    }
    if (Hive.isBoxOpen('fitness_weights')) {
      await Hive.box<WeightLog>('fitness_weights').close();
    }
    if (Hive.isBoxOpen('fitness_templates')) {
      await Hive.box<String>('fitness_templates').close();
    }
    if (Hive.isBoxOpen('fitness_offdays')) {
      await Hive.box<String>('fitness_offdays').close();
    }
    if (Hive.isBoxOpen('fitness_settings')) {
      await Hive.box('fitness_settings').close();
    }
  }
}
