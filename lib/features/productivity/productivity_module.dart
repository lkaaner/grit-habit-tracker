import 'package:hive/hive.dart';
import '../../core/module/module_interface.dart';
import '../../core/database/hive_models.dart';

class ProductivityModule implements AppModule {
  @override
  String get moduleName => 'productivity';

  @override
  void registerHiveAdapters() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TodoAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(NoteAdapter());
    }
  }

  @override
  Future<void> initHiveBoxes() async {
    await Hive.openBox<Todo>('productivity_todos');
    await Hive.openBox<Note>('productivity_notes');
  }

  @override
  Future<void> closeHiveBoxes() async {
    if (Hive.isBoxOpen('productivity_todos')) {
      await Hive.box<Todo>('productivity_todos').close();
    }
    if (Hive.isBoxOpen('productivity_notes')) {
      await Hive.box<Note>('productivity_notes').close();
    }
  }
}
