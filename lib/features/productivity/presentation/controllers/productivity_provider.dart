import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../../core/database/hive_models.dart';

class ProductivityState {
  final List<Todo> todos; // Görevler ve Alışkanlıklar tek kutuda
  final Note? selectedDateNote;
  final DateTime selectedDate;

  ProductivityState({
    required this.todos,
    this.selectedDateNote,
    required this.selectedDate,
  });

  // Seçilen gündeki alışkanlıkları getirir
  List<Todo> get habits => todos.where((t) => t.isHabit).toList();

  // Seçilen gündeki tek seferlik görevleri getirir
  List<Todo> get tasks => todos.where((t) => !t.isHabit).toList();

  ProductivityState copyWith({
    List<Todo>? todos,
    Note? selectedDateNote,
    DateTime? selectedDate,
  }) {
    return ProductivityState(
      todos: todos ?? this.todos,
      selectedDateNote: selectedDateNote ?? this.selectedDateNote,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}

class ProductivityNotifier extends StateNotifier<ProductivityState> {
  ProductivityNotifier()
      : super(ProductivityState(
          todos: [],
          selectedDate: DateTime.now(),
        ));

  late final Box<Todo> _todoBox;
  late final Box<Note> _noteBox;

  void init() {
    _todoBox = Hive.box<Todo>('productivity_todos');
    _noteBox = Hive.box<Note>('productivity_notes');
    loadDataForDate(DateTime.now());
  }

  void changeSelectedDate(DateTime date) {
    loadDataForDate(date);
  }

  void loadTodayData() {
    loadDataForDate(DateTime.now());
  }

  void loadDataForDate(DateTime date) {
    // Alışkanlıklar her gün görünür. Tek seferlik görevler ise sadece eklendikleri gün görünür.
    final allItems = _todoBox.values.where((item) {
      if (item.isHabit) {
        // Alışkanlık başlangıç tarihinden sonrasındaysa her gün listelenecek
        // (Grit tarzında alışkanlıklar kalıcı günlük hedeflerdir)
        final startZero = DateTime(item.date.year, item.date.month, item.date.day);
        final targetZero = DateTime(date.year, date.month, date.day);
        return !targetZero.isBefore(startZero);
      } else {
        // Tek seferlik görev sadece oluşturulduğu gün listelenir
        return item.date.year == date.year &&
            item.date.month == date.month &&
            item.date.day == date.day;
      }
    }).toList();

    // Seçilen güne ait notu yükle
    final dateNote = _noteBox.values.cast<Note?>().firstWhere(
      (note) =>
          note != null &&
          note.date.year == date.year &&
          note.date.month == date.month &&
          note.date.day == date.day,
      orElse: () => null,
    );

    state = ProductivityState(
      todos: allItems,
      selectedDateNote: dateNote,
      selectedDate: date,
    );
  }

  Future<void> addHabit(String title, int colorIndex) async {
    final now = DateTime.now();
    final habit = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      isCompleted: false,
      date: now,
      isHabit: true,
      streak: 0,
      colorIndex: colorIndex,
      completedDates: [],
    );
    await _todoBox.add(habit);
    loadDataForDate(state.selectedDate);
  }

  Future<void> addTodo(String title) async {
    final todo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      isCompleted: false,
      date: state.selectedDate, // Seçili güne görev ekleme
      isHabit: false,
    );
    await _todoBox.add(todo);
    loadDataForDate(state.selectedDate);
  }

  Future<void> toggleItem(String id) async {
    final index = _todoBox.values.toList().indexWhere((t) => t.id == id);
    if (index != -1) {
      final item = _todoBox.getAt(index)!;
      final targetDateStr = _formatDateKey(state.selectedDate);

      if (item.isHabit) {
        // Alışkanlık tamamlama durumunu güncelle
        final completedList = List<String>.from(item.completedDates);
        int newStreak = item.streak;

        if (completedList.contains(targetDateStr)) {
          completedList.remove(targetDateStr);
          // Streak düşürme mantığı: eğer bozduysa 1 azalt veya sıfırla
          newStreak = (newStreak > 0) ? newStreak - 1 : 0;
        } else {
          completedList.add(targetDateStr);
          // Streak hesaplama: Eğer dün de yapıldıysa veya ilk günse zincir artar
          final yesterdayStr = _formatDateKey(state.selectedDate.subtract(const Duration(days: 1)));
          if (completedList.contains(yesterdayStr) || newStreak == 0) {
            newStreak += 1;
          }
        }

        final updated = item.copyWith(
          completedDates: completedList,
          streak: newStreak,
        );
        await _todoBox.putAt(index, updated);
      } else {
        // Görev tamamlama durumunu güncelle
        final updated = item.copyWith(isCompleted: !item.isCompleted);
        await _todoBox.putAt(index, updated);
      }
      loadDataForDate(state.selectedDate);
    }
  }

  Future<void> deleteItem(String id) async {
    final index = _todoBox.values.toList().indexWhere((t) => t.id == id);
    if (index != -1) {
      await _todoBox.deleteAt(index);
      loadDataForDate(state.selectedDate);
    }
  }

  Future<void> saveNote(String content) async {
    final date = state.selectedDate;
    final noteIndex = _noteBox.values.toList().indexWhere((note) =>
        note.date.year == date.year &&
        note.date.month == date.month &&
        note.date.day == date.day);

    if (noteIndex != -1) {
      final existing = _noteBox.getAt(noteIndex)!;
      final updated = existing.copyWith(content: content);
      await _noteBox.putAt(noteIndex, updated);
    } else {
      final newNote = Note(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        date: date,
      );
      await _noteBox.add(newNote);
    }
    loadDataForDate(date);
  }

  /// Belirli bir tarihin tüm görevlerinin/alışkanlıklarının tamamlanıp tamamlanmadığını kontrol eder.
  bool isDateFullyCompleted(DateTime date) {
    final dateStr = _formatDateKey(date);
    final targetZero = DateTime(date.year, date.month, date.day);

    final itemsForDate = _todoBox.values.where((item) {
      if (item.isHabit) {
        final startZero = DateTime(item.date.year, item.date.month, item.date.day);
        return !targetZero.isBefore(startZero);
      } else {
        return item.date.year == date.year &&
            item.date.month == date.month &&
            item.date.day == date.day;
      }
    }).toList();

    if (itemsForDate.isEmpty) return false;

    for (var item in itemsForDate) {
      if (item.isHabit) {
        if (!item.completedDates.contains(dateStr)) return false;
      } else {
        if (!item.isCompleted) return false;
      }
    }
    return true;
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

final productivityProvider =
    StateNotifierProvider<ProductivityNotifier, ProductivityState>((ref) {
  return ProductivityNotifier()..init();
});
