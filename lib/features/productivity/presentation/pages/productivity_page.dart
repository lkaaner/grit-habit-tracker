import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Divider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/settings_modal.dart';
import '../controllers/productivity_provider.dart';
import '../../../../core/database/hive_models.dart';

class ProductivityPage extends ConsumerStatefulWidget {
  const ProductivityPage({super.key});

  @override
  ConsumerState<ProductivityPage> createState() => _ProductivityPageState();
}

class _ProductivityPageState extends ConsumerState<ProductivityPage> {
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  DateTime? _lastSelectedDate;

  bool _isHabitsExpanded = true;
  bool _isMorningExpanded = true;
  bool _isAfternoonExpanded = true;
  bool _isEveningExpanded = true;
  bool _isTasksExpanded = true;
  bool _isNotesExpanded = true;

  final List<Color> _habitColors = const [
    Color(0xFF8B5CF6), // Mor
    Color(0xFF06B6D4), // Teal
    Color(0xFF3B82F6), // Mavi
    Color(0xFFEC4899), // Pembe
    Color(0xFF10B981), // Yeşil
  ];

  final List<LinearGradient> _habitGradients = const [
    LinearGradient(
      colors: [Color(0xFFC084FC), Color(0xFF8B5CF6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ), // Mor
    LinearGradient(
      colors: [Color(0xFF22D3EE), Color(0xFF06B6D4)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ), // Teal/Cyan
    LinearGradient(
      colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ), // Mavi
    LinearGradient(
      colors: [Color(0xFFF472B6), Color(0xFFEC4899)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ), // Pembe
    LinearGradient(
      colors: [Color(0xFF34D399), Color(0xFF10B981)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ), // Yeşil
  ];

  void _showSettings(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => const SettingsModal(),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _showAddHabitModal() {
    _titleController.clear();
    int selectedColorIndex = 0;
    String selectedTimeOfDay = 'Sabah'; // Varsayılan

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return CupertinoActionSheet(
              title: const Text('Yeni Alışkanlık Ekle'),
              message: Column(
                children: [
                  CupertinoTextField(
                    controller: _titleController,
                    placeholder: 'Alışkanlık adı (örn. Kitap Okuma)...',
                    autofocus: true,
                    decoration: BoxDecoration(
                      color: CupertinoColors.secondarySystemBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Grup / Zaman Dilimi Seçin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['Sabah', 'Öğlen', 'Akşam'].map((time) {
                      final isSelected = selectedTimeOfDay == time;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            selectedTimeOfDay = time;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF8B5CF6) : CupertinoColors.secondarySystemBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? CupertinoColors.white : CupertinoColors.transparent,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            time,
                            style: TextStyle(
                              color: isSelected ? CupertinoColors.white : const Color(0xFF9EA0A5),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Renk Seçin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(_habitColors.length, (index) {
                      final isSelected = selectedColorIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            selectedColorIndex = index;
                          });
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _habitColors[index],
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: CupertinoColors.white, width: 3)
                                : null,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
              actions: <CupertinoActionSheetAction>[
                CupertinoActionSheetAction(
                  isDefaultAction: true,
                  onPressed: () {
                    final text = _titleController.text.trim();
                    if (text.isNotEmpty) {
                      final prefixedText = '[$selectedTimeOfDay] $text';
                      ref.read(productivityProvider.notifier).addHabit(prefixedText, selectedColorIndex);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Ekle'),
                ),
              ],
              cancelButton: CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('İptal'),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddTaskModal() {
    _titleController.clear();
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Yeni Görev Ekle'),
        message: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: CupertinoTextField(
            controller: _titleController,
            placeholder: 'Görev adı...',
            autofocus: true,
            decoration: BoxDecoration(
              color: CupertinoColors.secondarySystemBackground,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              final text = _titleController.text.trim();
              if (text.isNotEmpty) {
                ref.read(productivityProvider.notifier).addTodo(text);
              }
              Navigator.pop(context);
            },
            child: const Text('Ekle'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('İptal'),
        ),
      ),
    );
  }

  void _showAddSelectionSheet() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Yeni Öge Ekle'),
        message: const Text('Eklemek istediğiniz öge türünü seçin:'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showAddHabitModal();
            },
            child: const Text('Yeni Alışkanlık (Habit)'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showAddTaskModal();
            },
            child: const Text('Yeni Görev (Yapılacaklar)'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('İptal'),
        ),
      ),
    );
  }

  String _formatSelectedDate(DateTime date) {
    final months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Bugün';
    }
    return '${date.day} ${months[date.month - 1]}';
  }

  IconData _getHabitIcon(String title) {
    final lowercaseTitle = title.toLowerCase();
    if (lowercaseTitle.contains('kitap') || lowercaseTitle.contains('oku') || lowercaseTitle.contains('read') || lowercaseTitle.contains('ders')) {
      return CupertinoIcons.book_fill;
    }
    if (lowercaseTitle.contains('spor') || lowercaseTitle.contains('antrenman') || lowercaseTitle.contains('gym') || lowercaseTitle.contains('koşu') || lowercaseTitle.contains('egzersiz') || lowercaseTitle.contains('run') || lowercaseTitle.contains('workout') || lowercaseTitle.contains('ağırlık') || lowercaseTitle.contains('fitness')) {
      return CupertinoIcons.flame_fill;
    }
    if (lowercaseTitle.contains('su') || lowercaseTitle.contains('drink') || lowercaseTitle.contains('water') || lowercaseTitle.contains('sıvı')) {
      return CupertinoIcons.drop_fill;
    }
    if (lowercaseTitle.contains('uyku') || lowercaseTitle.contains('sleep') || lowercaseTitle.contains('yat') || lowercaseTitle.contains('gece')) {
      return CupertinoIcons.moon_fill;
    }
    if (lowercaseTitle.contains('meditasyon') || lowercaseTitle.contains('nefes') || lowercaseTitle.contains('meditate') || lowercaseTitle.contains('yoga') || lowercaseTitle.contains('zihin') || lowercaseTitle.contains('sağlık')) {
      return CupertinoIcons.heart_fill;
    }
    if (lowercaseTitle.contains('kod') || lowercaseTitle.contains('yazılım') || lowercaseTitle.contains('work') || lowercaseTitle.contains('çalış') || lowercaseTitle.contains('study') || lowercaseTitle.contains('bilgisayar') || lowercaseTitle.contains('dev')) {
      return CupertinoIcons.device_laptop;
    }
    return CupertinoIcons.star_fill;
  }

  String _getCleanTitle(String title) {
    if (title.startsWith('[Sabah] ')) return title.substring(8);
    if (title.startsWith('[Öğlen] ')) return title.substring(8);
    if (title.startsWith('[Akşam] ')) return title.substring(8);
    return title;
  }

  Widget _buildHabitGroup({
    required String title,
    required IconData icon,
    required Color color,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<Todo> habits,
    required ProductivityState state,
    required ProductivityNotifier notifier,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ],
                ),
                Icon(
                  isExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                  color: color,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (isExpanded) ...[
          habits.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                  child: Text(
                    'Bu zaman diliminde alışkanlık bulunmuyor.',
                    style: TextStyle(color: const Color(0xFF9EA0A5).withOpacity(0.6), fontSize: 13),
                  ),
                )
              : Column(
                  children: habits.map((habit) {
                    final dateStr = '${state.selectedDate.year}-${state.selectedDate.month.toString().padLeft(2, '0')}-${state.selectedDate.day.toString().padLeft(2, '0')}';
                    final isCompleted = habit.completedDates.contains(dateStr);
                    final gradient = _habitGradients[habit.colorIndex % _habitGradients.length];
                    final habitColor = _habitColors[habit.colorIndex % _habitColors.length];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: habitColor.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: CupertinoColors.black.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getHabitIcon(habit.title),
                                  color: CupertinoColors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getCleanTitle(habit.title),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: CupertinoColors.white,
                                        decoration: isCompleted
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(CupertinoIcons.flame_fill, color: Colors.orange, size: 12),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Streak: ${habit.streak} gün • Her gün',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: CupertinoColors.white.withOpacity(0.85),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  showCupertinoDialog(
                                    context: context,
                                    builder: (context) => CupertinoAlertDialog(
                                      title: const Text('Silinsin mi?'),
                                      content: const Text('Bu alışkanlığı silmek istediğinize emin misiniz?'),
                                      actions: [
                                        CupertinoDialogAction(
                                          child: const Text('İptal'),
                                          onPressed: () => Navigator.pop(context),
                                        ),
                                        CupertinoDialogAction(
                                          isDestructiveAction: true,
                                          onPressed: () {
                                            notifier.deleteItem(habit.id);
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Sil'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Icon(
                                  CupertinoIcons.trash,
                                  color: CupertinoColors.white.withOpacity(0.6),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => notifier.toggleItem(habit.id),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: isCompleted ? CupertinoColors.white : CupertinoColors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: CupertinoColors.white,
                                      width: 2.0,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: isCompleted
                                      ? Icon(
                                          CupertinoIcons.checkmark,
                                          color: habitColor,
                                          size: 16,
                                        )
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productivityProvider);
    final notifier = ref.read(productivityProvider.notifier);

    // Seçilen tarih değiştiğinde not alanını güncelle
    if (_lastSelectedDate != state.selectedDate) {
      _lastSelectedDate = state.selectedDate;
      _noteController.text = state.selectedDateNote?.content ?? '';
    }

    // Pazartesi - Pazar haftalık şeridini oluştur
    final monday = state.selectedDate.subtract(Duration(days: state.selectedDate.weekday - 1));
    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));
    final weekDayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF090A0F),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==========================================
                    // CUSTOM TOP BAR (Mockup formatında)
                    // ==========================================
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => _showSettings(context),
                                child: const Icon(CupertinoIcons.settings, color: CupertinoColors.white, size: 22),
                              ),
                              const SizedBox(width: 12),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  final completedHabits = state.habits.where((h) => h.completedDates.contains('${state.selectedDate.year}-${state.selectedDate.month.toString().padLeft(2, '0')}-${state.selectedDate.day.toString().padLeft(2, '0')}')).length;
                                  showCupertinoDialog(
                                    context: context,
                                    builder: (context) => CupertinoAlertDialog(
                                      title: const Text('Günlük İstatistikler'),
                                      content: Text('Bugün ${state.habits.length} alışkanlıktan $completedHabits tanesini tamamladınız!\nStreaklerinizi korumaya devam edin.'),
                                      actions: [
                                        CupertinoDialogAction(
                                          child: const Text('Tamam'),
                                          onPressed: () => Navigator.pop(context),
                                        )
                                      ],
                                    ),
                                  );
                                },
                                child: const Icon(CupertinoIcons.graph_square, color: CupertinoColors.white, size: 22),
                              ),
                            ],
                          ),
                          Text(
                            _formatSelectedDate(state.selectedDate),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: CupertinoColors.white,
                            ),
                          ),
                          Row(
                            children: [
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  showCupertinoDialog(
                                    context: context,
                                    builder: (context) => CupertinoAlertDialog(
                                      title: const Text('Grit Takipçi'),
                                      content: const Text('Grit, günlük disiplin ve alışkanlıklarınızı takip etmenizi sağlayan minimalist bir araçtır.'),
                                      actions: [
                                        CupertinoDialogAction(
                                          child: const Text('Harika'),
                                          onPressed: () => Navigator.pop(context),
                                        )
                                      ],
                                    ),
                                  );
                                },
                                child: const Icon(CupertinoIcons.list_bullet, color: CupertinoColors.white, size: 22),
                              ),
                              const SizedBox(width: 12),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: _showAddSelectionSheet,
                                child: const Icon(CupertinoIcons.add, color: CupertinoColors.white, size: 22),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ==========================================
                    // CONNECTOR TIMELINE (Mockup formatında)
                    // ==========================================
                    Container(
                      height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16171D),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            left: 32,
                            right: 32,
                            top: 48,
                            child: Container(
                              height: 2,
                              color: const Color(0xFF8B5CF6).withOpacity(0.35),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: List.generate(7, (index) {
                              final day = weekDays[index];
                              final isSelected = day.year == state.selectedDate.year &&
                                  day.month == state.selectedDate.month &&
                                  day.day == state.selectedDate.day;
                              final isFullyCompleted = notifier.isDateFullyCompleted(day);

                              if (isSelected) {
                                return Container(
                                  width: 44,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF8B5CF6).withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      )
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        weekDayNames[index],
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: CupertinoColors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        width: 26,
                                        height: 26,
                                        decoration: const BoxDecoration(
                                          color: CupertinoColors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          day.day.toString(),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF6D28D9),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return GestureDetector(
                                onTap: () => notifier.changeSelectedDate(day),
                                behavior: HitTestBehavior.opaque,
                                child: SizedBox(
                                  width: 44,
                                  height: 76,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        weekDayNames[index],
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF9EA0A5),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: isFullyCompleted
                                              ? const Color(0xFF8B5CF6)
                                              : CupertinoColors.transparent,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFF8B5CF6),
                                            width: 1.8,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          day.day.toString(),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isFullyCompleted
                                                ? CupertinoColors.white
                                                : const Color(0xFF8B5CF6),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ==========================================
                    // HABIT TRACKER BÖLÜMÜ (AÇILIR-KAPANIR YAPI)
                    // ==========================================
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isHabitsExpanded = !_isHabitsExpanded;
                        });
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(CupertinoIcons.sparkles, color: Color(0xFF8B5CF6), size: 22),
                                SizedBox(width: 8),
                                Text(
                                  'Habit Tracker',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: CupertinoColors.white,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              _isHabitsExpanded ? CupertinoIcons.chevron_up_circle_fill : CupertinoIcons.chevron_down_circle_fill,
                              color: const Color(0xFF8B5CF6),
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (_isHabitsExpanded) ...[
                      // SABAH GRUBU
                      _buildHabitGroup(
                        title: 'Sabah',
                        icon: CupertinoIcons.sunrise_fill,
                        color: const Color(0xFFFF9500),
                        isExpanded: _isMorningExpanded,
                        onToggle: () => setState(() => _isMorningExpanded = !_isMorningExpanded),
                        habits: state.habits.where((h) => h.title.startsWith('[Sabah] ') || (!h.title.startsWith('[Öğlen] ') && !h.title.startsWith('[Akşam] '))).toList(),
                        state: state,
                        notifier: notifier,
                      ),
                      const SizedBox(height: 16),

                      // ÖĞLEN GRUBU
                      _buildHabitGroup(
                        title: 'Öğlen',
                        icon: CupertinoIcons.sun_max_fill,
                        color: const Color(0xFFFFCC00),
                        isExpanded: _isAfternoonExpanded,
                        onToggle: () => setState(() => _isAfternoonExpanded = !_isAfternoonExpanded),
                        habits: state.habits.where((h) => h.title.startsWith('[Öğlen] ')).toList(),
                        state: state,
                        notifier: notifier,
                      ),
                      const SizedBox(height: 16),

                      // AKŞAM GRUBU
                      _buildHabitGroup(
                        title: 'Akşam',
                        icon: CupertinoIcons.moon_stars_fill,
                        color: const Color(0xFF8B5CF6),
                        isExpanded: _isEveningExpanded,
                        onToggle: () => setState(() => _isEveningExpanded = !_isEveningExpanded),
                        habits: state.habits.where((h) => h.title.startsWith('[Akşam] ')).toList(),
                        state: state,
                        notifier: notifier,
                      ),
                    ],
                    const SizedBox(height: 24),

                    // ==========================================
                    // YAPILACAKLAR BÖLÜMÜ
                    // ==========================================
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isTasksExpanded = !_isTasksExpanded;
                        });
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(CupertinoIcons.square_list_fill, color: Color(0xFF06B6D4), size: 22),
                                SizedBox(width: 8),
                                Text(
                                  'Yapılacaklar',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: CupertinoColors.white,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              _isTasksExpanded ? CupertinoIcons.chevron_up_circle_fill : CupertinoIcons.chevron_down_circle_fill,
                              color: const Color(0xFF06B6D4),
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (_isTasksExpanded) ...[
                      state.tasks.isEmpty
                          ? Container(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              alignment: Alignment.center,
                              child: const Text(
                                'Görev eklemek için sağ üstteki + butonuna basın.',
                                style: TextStyle(color: Color(0xFF9EA0A5), fontSize: 14),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF16171D),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                children: List.generate(state.tasks.length, (index) {
                                  final task = state.tasks[index];
                                  return Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                        child: Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () => notifier.toggleItem(task.id),
                                              child: Icon(
                                                task.isCompleted
                                                    ? CupertinoIcons.checkmark_circle_fill
                                                    : CupertinoIcons.circle,
                                                color: task.isCompleted
                                                    ? const Color(0xFF8B5CF6)
                                                    : const Color(0xFF9EA0A5),
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Text(
                                                task.title,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  decoration: task.isCompleted
                                                      ? TextDecoration.lineThrough
                                                      : TextDecoration.none,
                                                  color: task.isCompleted
                                                      ? const Color(0xFF9EA0A5)
                                                      : CupertinoColors.white,
                                                ),
                                              ),
                                            ),
                                            CupertinoButton(
                                              padding: EdgeInsets.zero,
                                              onPressed: () => notifier.deleteItem(task.id),
                                              child: const Icon(
                                                CupertinoIcons.trash,
                                                color: CupertinoColors.destructiveRed,
                                                size: 20,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (index < state.tasks.length - 1)
                                        const Divider(
                                          height: 1,
                                          indent: 52,
                                          color: Color(0xFF2C2C35),
                                        ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                    ],
                    const SizedBox(height: 24),

                    // ==========================================
                    // NOTLARIM BÖLÜMÜ
                    // ==========================================
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isNotesExpanded = !_isNotesExpanded;
                        });
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(CupertinoIcons.pencil_outline, color: Color(0xFFEC4899), size: 22),
                                SizedBox(width: 8),
                                Text(
                                  'Notlarım',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: CupertinoColors.white,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              _isNotesExpanded ? CupertinoIcons.chevron_up_circle_fill : CupertinoIcons.chevron_down_circle_fill,
                              color: const Color(0xFFEC4899),
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (_isNotesExpanded) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF16171D),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CupertinoTextField(
                              controller: _noteController,
                              maxLines: 6,
                              minLines: 3,
                              placeholder: 'Bugün için not alın (otomatik kaydedilir)...',
                              placeholderStyle: const TextStyle(color: Color(0xFF9EA0A5)),
                              decoration: BoxDecoration(
                                color: const Color(0xFF090A0F),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              style: const TextStyle(fontSize: 15, color: CupertinoColors.white),
                              onChanged: (text) {
                                notifier.saveNote(text);
                              },
                            ),
                            const SizedBox(height: 10),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(CupertinoIcons.cloud_upload_fill, size: 14, color: Color(0xFF9EA0A5)),
                                SizedBox(width: 4),
                                Text(
                                  'Anında kaydedildi',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF9EA0A5)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
