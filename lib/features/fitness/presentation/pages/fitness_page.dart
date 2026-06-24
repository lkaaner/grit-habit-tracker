import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/hive_models.dart';
import '../../../../core/widgets/settings_modal.dart';
import '../controllers/fitness_provider.dart';

class FitnessPage extends ConsumerStatefulWidget {
  const FitnessPage({super.key});

  @override
  ConsumerState<FitnessPage> createState() => _FitnessPageState();
}

class _FitnessPageState extends ConsumerState<FitnessPage> {
  final TextEditingController _exerciseController = TextEditingController();
  final TextEditingController _setsController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  final TextEditingController _workoutWeightController = TextEditingController();

  final TextEditingController _calorieAmountController = TextEditingController();
  final TextEditingController _calorieDescController = TextEditingController();
  final TextEditingController _proteinInputController = TextEditingController();
  final TextEditingController _carbInputController = TextEditingController();
  final TextEditingController _fatInputController = TextEditingController();

  final TextEditingController _waterInputController = TextEditingController();

  final TextEditingController _heightController = TextEditingController();
  final CupertinoThemeData _cupertinoTheme = const CupertinoThemeData(brightness: Brightness.dark);
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _targetWeightController = TextEditingController();
  final TextEditingController _weightLogController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  final TextEditingController _stepsController = TextEditingController();
  final TextEditingController _cardioSpeedController = TextEditingController();
  final TextEditingController _cardioInclineController = TextEditingController();
  final TextEditingController _cardioDurationController = TextEditingController();

  String _selectedGender = 'erkek';

  bool _isBmrExpanded = false; // Kalori hesaplayıcı açılır menü kontrolü
  bool _isWaterInfoExpanded = false; // Su bilgisi açılır menü kontrolü
  bool _isMacroInfoExpanded = false; // Makro bilgisi açılır menü kontrolü
  bool _isCalorieExpanded = true; // Kalori takibi açılır menü kontrolü
  bool _isWorkoutsExpanded = true; // Antrenmanlarım açılır menü kontrolü
  bool _isCardioExpanded = true; // Kardiyo açılır menü kontrolü
  bool _isWeightExpanded = true; // Ağırlık takibi açılır menü kontrolü
  final Set<String> _expandedExercises = {}; // Genişletilmiş egzersizler kümesi

  void _showSettings(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => const SettingsModal(),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(fitnessProvider);
      _heightController.text = state.userHeight.toStringAsFixed(0);
      _weightController.text = state.userWeight.toStringAsFixed(0);
      _targetWeightController.text = state.targetWeight.toStringAsFixed(0);
      _ageController.text = state.userAge.toString();
      setState(() {
        _selectedGender = state.userGender;
      });
    });
  }

  @override
  void dispose() {
    _exerciseController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _workoutWeightController.dispose();
    _calorieAmountController.dispose();
    _calorieDescController.dispose();
    _proteinInputController.dispose();
    _carbInputController.dispose();
    _fatInputController.dispose();
    _waterInputController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    _weightLogController.dispose();
    _ageController.dispose();
    _stepsController.dispose();
    _cardioSpeedController.dispose();
    _cardioInclineController.dispose();
    _cardioDurationController.dispose();
    super.dispose();
  }

  Widget _buildPresetChip({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: CupertinoColors.activeBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CupertinoColors.activeBlue.withOpacity(0.2)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, color: CupertinoColors.activeBlue, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showFoodInputDialog(String foodName, bool isGrams) {
    final controller = TextEditingController();
    showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: Text('$foodName Miktarı'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isGrams ? 'Lütfen gram cinsinden miktarı girin:' : 'Lütfen adet cinsinden miktarı girin:',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: controller,
                  placeholder: isGrams ? 'örn. 150' : 'örn. 3',
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16171D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('İptal'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                final val = double.tryParse(controller.text) ?? 0.0;
                if (val > 0) {
                  double kcal = 0.0;
                  double p = 0.0;
                  double c = 0.0;
                  double f = 0.0;
                  String desc = '';

                  if (foodName == 'Pilav') {
                    kcal = (130 * val) / 100;
                    c = (28.0 * val) / 100;
                    p = (2.7 * val) / 100;
                    f = (0.3 * val) / 100;
                    desc = 'Pilav (${val.round()}g)';
                  } else if (foodName == 'Tavuk Göğsü') {
                    kcal = (165 * val) / 100;
                    c = 0.0;
                    p = (31.0 * val) / 100;
                    f = (3.6 * val) / 100;
                    desc = 'Tavuk Göğsü (${val.round()}g)';
                  } else if (foodName == 'Yumurta') {
                    kcal = 75 * val;
                    c = 0.6 * val;
                    p = 6.3 * val;
                    f = 5.0 * val;
                    desc = 'Yumurta (${val.round()} Adet)';
                  } else if (foodName == 'Patates') {
                    kcal = (87 * val) / 100;
                    c = (20.0 * val) / 100;
                    p = (1.9 * val) / 100;
                    f = (0.1 * val) / 100;
                    desc = 'Patates (${val.round()}g)';
                  } else if (foodName == 'Gong (Paket)') {
                    kcal = 294 * val;
                    c = 45.63 * val;
                    p = 3.71 * val;
                    f = 10.37 * val;
                    desc = 'Gong (${val.toStringAsFixed(1).replaceAll('.0', '')} Paket)';
                  } else if (foodName == 'Gong (Adet)') {
                    kcal = 50 * val;
                    c = 7.84 * val;
                    p = 0.64 * val;
                    f = 1.78 * val;
                    desc = 'Gong (${val.toStringAsFixed(1).replaceAll('.0', '')} Adet)';
                  }

                  _calorieAmountController.text = kcal.round().toString();
                  _calorieDescController.text = desc;
                  _proteinInputController.text = p.toStringAsFixed(1).replaceAll('.0', '');
                  _carbInputController.text = c.toStringAsFixed(1).replaceAll('.0', '');
                  _fatInputController.text = f.toStringAsFixed(1).replaceAll('.0', '');
                }
                Navigator.pop(dialogContext);
              },
              child: const Text('Hesapla'),
            ),
          ],
        );
      },
    );
  }

  void _showAddCalorieModal(bool isTaken) {
    _calorieAmountController.clear();
    _calorieDescController.clear();
    _proteinInputController.clear();
    _carbInputController.clear();
    _fatInputController.clear();

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(isTaken ? 'Alınan Kalori Ekle' : 'Yakılan Kalori Ekle'),
        message: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoTextField(
                  controller: _calorieAmountController,
                  placeholder: 'Kalori miktarı (kcal)...',
                  keyboardType: TextInputType.number,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16171D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: _calorieDescController,
                  placeholder: 'Açıklama (örn: Yulaf Ezmesi, Koşu)...',
                  decoration: BoxDecoration(
                    color: const Color(0xFF16171D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                if (isTaken) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoTextField(
                          controller: _proteinInputController,
                          placeholder: 'P (g)...',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16171D),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CupertinoTextField(
                          controller: _carbInputController,
                          placeholder: 'C (g)...',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16171D),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CupertinoTextField(
                          controller: _fatInputController,
                          placeholder: 'F (g)...',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16171D),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Yemek Şablonları / Pratik Seçim:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF9EA0A5)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPresetChip(
                        label: '🍚 Pilav',
                        onTap: () => _showFoodInputDialog('Pilav', true),
                      ),
                      _buildPresetChip(
                        label: '🍗 Tavuk Göğsü',
                        onTap: () => _showFoodInputDialog('Tavuk Göğsü', true),
                      ),
                      _buildPresetChip(
                        label: '🥚 Yumurta',
                        onTap: () => _showFoodInputDialog('Yumurta', false),
                      ),
                      _buildPresetChip(
                        label: '🥔 Patates',
                        onTap: () => _showFoodInputDialog('Patates', true),
                      ),
                      _buildPresetChip(
                        label: '🍿 Gong (Paket)',
                        onTap: () => _showFoodInputDialog('Gong (Paket)', false),
                      ),
                      _buildPresetChip(
                        label: '🍿 Gong (Adet)',
                        onTap: () => _showFoodInputDialog('Gong (Adet)', false),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              final amount = (double.tryParse(_calorieAmountController.text.replaceAll(',', '.')) ?? 0.0).round();
              final friendlyDesc = _calorieDescController.text.trim();
              final protVal = double.tryParse(_proteinInputController.text.replaceAll(',', '.')) ?? 0.0;
              final carbVal = double.tryParse(_carbInputController.text.replaceAll(',', '.')) ?? 0.0;
              final fatVal = double.tryParse(_fatInputController.text.replaceAll(',', '.')) ?? 0.0;

              if (amount > 0) {
                String finalDesc = friendlyDesc;
                if (isTaken) {
                  finalDesc = '$friendlyDesc | P: ${protVal.toStringAsFixed(1)} | C: ${carbVal.toStringAsFixed(1)} | F: ${fatVal.toStringAsFixed(1)}';
                }
                ref.read(fitnessProvider.notifier).addCalorieLog(
                      amount,
                      isTaken ? 'taken' : 'burned',
                      finalDesc,
                    );
              }
              Navigator.pop(context);
            },
            child: const Text('Ekle'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
      ),
    );
  }

  void _showAddCardioModal() {
    _stepsController.clear();
    _cardioSpeedController.clear();
    _cardioInclineController.clear();
    _cardioDurationController.clear();
    
    int activeTab = 0; // 0: Adım, 1: Koşu Bandı
    
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return CupertinoTheme(
              data: _cupertinoTheme,
              child: CupertinoActionSheet(
                title: const Text('Yeni Kardiyo / Koşu Ekle'),
                message: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Segmented Control
                      CupertinoSegmentedControl<int>(
                        groupValue: activeTab,
                        children: const {
                          0: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text('Adım Takibi', style: TextStyle(fontSize: 13, color: CupertinoColors.white)),
                          ),
                          1: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text('Koşu Bandı', style: TextStyle(fontSize: 13, color: CupertinoColors.white)),
                          ),
                        },
                        onValueChanged: (int val) {
                          setModalState(() {
                            activeTab = val;
                          });
                        },
                        selectedColor: CupertinoColors.activeBlue,
                        borderColor: CupertinoColors.activeBlue,
                      ),
                      const SizedBox(height: 16),
                      if (activeTab == 0) ...[
                        CupertinoTextField(
                          controller: _stepsController,
                          placeholder: 'Adım sayısı (örn: 10000)...',
                          keyboardType: TextInputType.number,
                          decoration: BoxDecoration(
                            color: const Color(0xFF16171D),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onChanged: (val) {
                            setModalState(() {});
                          },
                        ),
                        const SizedBox(height: 12),
                        Builder(builder: (context) {
                          final steps = int.tryParse(_stepsController.text) ?? 0;
                          final estCalories = (steps * 0.04).round();
                          return Text(
                            'Ortalama Yakılan Kalori: $estCalories kcal',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: CupertinoColors.activeGreen,
                            ),
                          );
                        }),
                      ] else ...[
                        CupertinoTextField(
                          controller: _cardioSpeedController,
                          placeholder: 'Hız (km/h) (örn: 8.5)...',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16171D),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onChanged: (val) {
                            setModalState(() {});
                          },
                        ),
                        const SizedBox(height: 8),
                        CupertinoTextField(
                          controller: _cardioInclineController,
                          placeholder: 'Eğim (%) (örn: 2)...',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16171D),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onChanged: (val) {
                            setModalState(() {});
                          },
                        ),
                        const SizedBox(height: 8),
                        CupertinoTextField(
                          controller: _cardioDurationController,
                          placeholder: 'Süre (dakika) (örn: 30)...',
                          keyboardType: TextInputType.number,
                          decoration: BoxDecoration(
                            color: const Color(0xFF16171D),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onChanged: (val) {
                            setModalState(() {});
                          },
                        ),
                        const SizedBox(height: 12),
                        Builder(builder: (context) {
                          final speed = double.tryParse(_cardioSpeedController.text.replaceAll(',', '.')) ?? 0.0;
                          final incline = double.tryParse(_cardioInclineController.text.replaceAll(',', '.')) ?? 0.0;
                          final duration = int.tryParse(_cardioDurationController.text) ?? 0;
                          final estCalories = ref.read(fitnessProvider.notifier).calculateCardioCalories(
                            speed: speed,
                            incline: incline,
                            duration: duration,
                          );
                          return Text(
                            'Ortalama Yakılan Kalori: $estCalories kcal',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: CupertinoColors.activeGreen,
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
                actions: <CupertinoActionSheetAction>[
                  CupertinoActionSheetAction(
                    isDefaultAction: true,
                    onPressed: () {
                      final notifier = ref.read(fitnessProvider.notifier);
                      if (activeTab == 0) {
                        final steps = int.tryParse(_stepsController.text) ?? 0;
                        if (steps > 0) {
                          final calories = (steps * 0.04).round();
                          notifier.addCardioLog(
                            steps: steps,
                            speed: 0.0,
                            incline: 0.0,
                            duration: 0,
                            calculatedCalories: calories,
                            isCompleted: true,
                          );
                        }
                      } else {
                        final speed = double.tryParse(_cardioSpeedController.text.replaceAll(',', '.')) ?? 0.0;
                        final incline = double.tryParse(_cardioInclineController.text.replaceAll(',', '.')) ?? 0.0;
                        final duration = int.tryParse(_cardioDurationController.text) ?? 0;
                        if (duration > 0) {
                          final calories = notifier.calculateCardioCalories(
                            speed: speed,
                            incline: incline,
                            duration: duration,
                          );
                          notifier.addCardioLog(
                            steps: 0,
                            speed: speed,
                            incline: incline,
                            duration: duration,
                            calculatedCalories: calories,
                            isCompleted: true,
                          );
                        }
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
          },
        );
      },
    );
  }

  void _showAddWorkoutModal({String? prefilledName}) {
    _exerciseController.text = prefilledName ?? '';
    _setsController.text = '1';
    _repsController.clear();
    _workoutWeightController.clear();

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(prefilledName != null ? '$prefilledName için Yeni Set Ekle' : 'Yeni Egzersiz Ekle'),
        message: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            children: [
              if (prefilledName == null) ...[
                CupertinoTextField(
                  controller: _exerciseController,
                  placeholder: 'Egzersiz Adı (örn: Squat)...',
                  decoration: BoxDecoration(
                    color: const Color(0xFF16171D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: CupertinoTextField(
                      controller: _repsController,
                      placeholder: 'Tekrar...',
                      keyboardType: TextInputType.number,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16171D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CupertinoTextField(
                      controller: _workoutWeightController,
                      placeholder: 'Kilo (kg)...',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16171D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              final name = _exerciseController.text.trim();
              final reps = int.tryParse(_repsController.text) ?? 0;
              final weight = double.tryParse(_workoutWeightController.text) ?? 0.0;

              if (name.isNotEmpty && reps > 0) {
                // Egzersize ait kaçıncı set olduğunu bul
                final state = ref.read(fitnessProvider);
                final currentSetsCount = state.workoutLogs.where((w) => w.exerciseName == name).length;
                ref.read(fitnessProvider.notifier).addWorkout(name, currentSetsCount + 1, reps, weight);
              }
              Navigator.pop(context);
            },
            child: const Text('Ekle'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
      ),
    );
  }

  void _showEditSetModal(WorkoutLog log) {
    final weightController = TextEditingController(text: log.weight > 0 ? log.weight.toString() : '');
    final repsController = TextEditingController(text: log.reps > 0 ? log.reps.toString() : '');

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text('${log.exerciseName} - Set ${log.sets} Düzenle'),
        message: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: weightController,
                  placeholder: 'Ağırlık (kg)...',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16171D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CupertinoTextField(
                  controller: repsController,
                  placeholder: 'Tekrar...',
                  keyboardType: TextInputType.number,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16171D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              final weight = double.tryParse(weightController.text) ?? 0.0;
              final reps = int.tryParse(repsController.text) ?? 0;
              ref.read(fitnessProvider.notifier).updateWorkoutSet(log.id, weight, reps);
              Navigator.pop(context);
            },
            child: const Text('Kaydet'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
      ),
    );
  }

  void _showCreateTemplateModal({WorkoutTemplate? existingTemplate}) {
    final nameController = TextEditingController(text: existingTemplate?.name ?? '');
    List<Map<String, dynamic>> tempExercises;
    if (existingTemplate != null) {
      tempExercises = List.generate(existingTemplate.exerciseNames.length, (i) {
        return {
          'name': TextEditingController(text: existingTemplate.exerciseNames[i]),
          'sets': TextEditingController(text: existingTemplate.setCounts[i].toString()),
        };
      });
    } else {
      tempExercises = [
        {'name': TextEditingController(), 'sets': TextEditingController(text: '4')}
      ];
    }

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return CupertinoActionSheet(
              title: Text(existingTemplate != null ? 'Antrenman Şablonunu Düzenle' : 'Yeni Antrenman Şablonu'),
              message: Container(
                constraints: const BoxConstraints(maxHeight: 280),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      CupertinoTextField(
                        controller: nameController,
                        placeholder: 'Şablon İsmi (örn: Bacak Günü)...',
                        decoration: BoxDecoration(
                          color: const Color(0xFF16171D),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Egzersizler ve Set Sayıları', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      Column(
                        children: List.generate(tempExercises.length, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: CupertinoTextField(
                                    controller: tempExercises[index]['name'],
                                    placeholder: 'Egzersiz ismi...',
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16171D),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 1,
                                  child: CupertinoTextField(
                                    controller: tempExercises[index]['sets'],
                                    placeholder: 'Set',
                                    keyboardType: TextInputType.number,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16171D),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    setModalState(() {
                                      tempExercises.removeAt(index);
                                    });
                                  },
                                  child: const Icon(CupertinoIcons.minus_circle, color: CupertinoColors.destructiveRed),
                                )
                              ],
                            ),
                          );
                        }),
                      ),
                      CupertinoButton(
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.add_circled, size: 16),
                            SizedBox(width: 4),
                            Text('Egzersiz Ekle', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                        onPressed: () {
                          setModalState(() {
                            tempExercises.add({
                              'name': TextEditingController(),
                              'sets': TextEditingController(text: '4')
                            });
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <CupertinoActionSheetAction>[
                CupertinoActionSheetAction(
                  isDefaultAction: true,
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty && tempExercises.isNotEmpty) {
                      final exercises = tempExercises
                          .map((e) => (e['name'] as TextEditingController).text.trim())
                          .where((t) => t.isNotEmpty)
                          .toList();
                      final sets = tempExercises
                          .map((e) => int.tryParse((e['sets'] as TextEditingController).text) ?? 4)
                          .toList();
                      
                      if (exercises.isNotEmpty) {
                        if (existingTemplate != null) {
                          ref.read(fitnessProvider.notifier).updateTemplate(
                                existingTemplate.id,
                                name,
                                exercises,
                                sets,
                              );
                        } else {
                          ref.read(fitnessProvider.notifier).addTemplate(name, exercises, sets);
                        }
                      }
                    }
                    Navigator.pop(context);
                  },
                  child: Text(existingTemplate != null ? 'Güncellemeleri Kaydet' : 'Şablonu Kaydet'),
                ),
              ],
              cancelButton: CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
            );
          },
        );
      },
    );
  }

  void _showTemplateOptions(WorkoutTemplate template) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(template.name),
        message: const Text('Bu antrenman programı için bir işlem seçin:'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              ref.read(fitnessProvider.notifier).applyTemplate(template.id);
            },
            child: const Text('Uygula (Bugüne Tanımla)'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showCreateTemplateModal(existingTemplate: template);
            },
            child: const Text('Düzenle (Şablonu Güncelle)'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              ref.read(fitnessProvider.notifier).deleteTemplate(template.id);
            },
            child: const Text('Sil'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
      ),
    );
  }

  Map<String, List<WorkoutLog>> _groupWorkouts(List<WorkoutLog> logs) {
    final Map<String, List<WorkoutLog>> map = {};
    for (var log in logs) {
      if (!map.containsKey(log.exerciseName)) {
        map[log.exerciseName] = [];
      }
      map[log.exerciseName]!.add(log);
    }
    // Set sayılarına göre sırala
    map.forEach((key, list) {
      list.sort((a, b) => a.sets.compareTo(b.sets));
    });
    return map;
  }

  Widget _buildMacroCard(String title, double taken, int target, Color color) {
    final takenStr = taken.toStringAsFixed(1).replaceAll('.0', '');
    final progress = target > 0 ? (taken / target).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF16171D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: CupertinoColors.white),
                  ),
                ],
              ),
              Text(
                '$takenStr/$target g',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: CupertinoColors.white),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Progress Bar
          Container(
            height: 3,
            width: double.infinity,
            decoration: BoxDecoration(
              color: CupertinoColors.separator.withOpacity(0.3),
              borderRadius: BorderRadius.circular(1.5),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fitnessProvider);
    final notifier = ref.read(fitnessProvider.notifier);

    final monday = state.selectedDate.subtract(Duration(days: state.selectedDate.weekday - 1));
    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));
    final weekDayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    final groupedWorkouts = _groupWorkouts(state.workoutLogs);

    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const SizedBox.shrink(),
            middle: const SizedBox.shrink(),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.settings, size: 22),
              onPressed: () => _showSettings(context),
            ),
          ),
          SliverToBoxAdapter(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. HAFTALIK PZT-PAZ SEÇİM ŞERİDİ (YÖN OKLARIYLA)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF090A0F),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              final prevWeek = state.selectedDate.subtract(const Duration(days: 7));
                              notifier.changeSelectedDate(prevWeek);
                            },
                            child: const Icon(CupertinoIcons.left_chevron, size: 20),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: List.generate(7, (index) {
                                final day = weekDays[index];
                                final isSelected = day.year == state.selectedDate.year &&
                                    day.month == state.selectedDate.month &&
                                    day.day == state.selectedDate.day;

                                return GestureDetector(
                                  onTap: () => notifier.changeSelectedDate(day),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? CupertinoColors.activeBlue
                                          : CupertinoColors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          weekDayNames[index],
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? CupertinoColors.white
                                                : const Color(0xFF9EA0A5),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          day.day.toString(),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? CupertinoColors.white
                                                : CupertinoColors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              final nextWeek = state.selectedDate.add(const Duration(days: 7));
                              notifier.changeSelectedDate(nextWeek);
                            },
                            child: const Icon(CupertinoIcons.right_chevron, size: 20),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ==========================================
                    // 2. KALORİ TAKİBİ KARTI
                    // ==========================================
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isCalorieExpanded = !_isCalorieExpanded;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16171D),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Kalori Takibi',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CupertinoColors.white),
                            ),
                            Icon(
                              _isCalorieExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                              color: CupertinoColors.activeBlue,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_isCalorieExpanded) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sol Sütun: Kalori Kartı
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              height: 200,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [CupertinoColors.systemOrange, Colors.deepOrange],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.deepOrange.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'KALORİ',
                                        style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                      ),
                                      const SizedBox(height: 4),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          '${state.totalCaloriesTaken}/${state.targetCalories}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      const Text(
                                        'kcal',
                                        style: TextStyle(color: Colors.white70, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: CupertinoColors.white.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('Kalan:', style: TextStyle(color: Colors.white, fontSize: 10)),
                                            Text('${state.remainingCalories}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: CupertinoColors.white.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('Yakılan:', style: TextStyle(color: Colors.white, fontSize: 10)),
                                            Text('${state.totalCaloriesBurned}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: CupertinoButton(
                                          color: CupertinoColors.white.withOpacity(0.25),
                                          padding: EdgeInsets.zero,
                                          minSize: 28,
                                          borderRadius: BorderRadius.circular(8),
                                          onPressed: () => _showAddCalorieModal(true),
                                          child: const Icon(CupertinoIcons.plus, size: 14, color: Colors.white),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: CupertinoButton(
                                          color: CupertinoColors.white.withOpacity(0.25),
                                          padding: EdgeInsets.zero,
                                          minSize: 28,
                                          borderRadius: BorderRadius.circular(8),
                                          onPressed: () => _showAddCalorieModal(false),
                                          child: const Icon(CupertinoIcons.minus, size: 14, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Sağ Sütun: Makrolar Listesi (3 Adet Horizontal Kart)
                          Expanded(
                            flex: 1,
                            child: SizedBox(
                              height: 200,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: _buildMacroCard('Protein', state.totalProteinTaken, state.targetProtein, CupertinoColors.systemPink)),
                                  const SizedBox(height: 6),
                                  Expanded(child: _buildMacroCard('Karb', state.totalCarbTaken, state.targetCarb, CupertinoColors.systemTeal)),
                                  const SizedBox(height: 6),
                                  Expanded(child: _buildMacroCard('Yağ', state.totalFatTaken, state.targetFat, CupertinoColors.systemOrange)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ==========================================
                      // BUGÜNKÜ YEMEKLER & AKTİVİTELER LİSTESİ
                      // ==========================================
                      const Text(
                        'Bugünkü Yemekler & Aktiviteler',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9EA0A5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      state.calorieLogs.isEmpty
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFF16171D),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Bugün henüz kalori kaydı eklenmedi.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9EA0A5),
                                ),
                              ),
                            )
                          : Column(
                              children: state.calorieLogs.map((log) {
                                final isFood = log.type == 'taken';
                                final parts = log.description.split('|');
                                final name = parts[0].trim();
                                final hasMacros = parts.length > 1;
                                final macros = hasMacros
                                    ? parts.skip(1).join(' | ').trim()
                                    : '';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16171D),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isFood
                                            ? CupertinoIcons.square_list
                                            : CupertinoIcons.sportscourt,
                                        color: isFood
                                            ? CupertinoColors.activeOrange
                                            : CupertinoColors.activeBlue,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: CupertinoColors.white,
                                              ),
                                            ),
                                            if (hasMacros) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                macros,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Color(0xFF9EA0A5),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Text(
                                        isFood
                                            ? '+${log.amount} kcal'
                                            : '-${log.amount} kcal',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isFood
                                              ? CupertinoColors.activeOrange
                                              : CupertinoColors.systemRed,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      CupertinoButton(
                                        padding: EdgeInsets.zero,
                                        minSize: 32,
                                        onPressed: () => notifier.deleteCalorieLog(log.id),
                                        child: const Icon(
                                          CupertinoIcons.trash,
                                          color: CupertinoColors.destructiveRed,
                                          size: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                      const SizedBox(height: 24),

                      // ==========================================
                      // 3. BOY/KİLO KALORİ HESAPLAYICI (AÇILIR-KAPANIR YAPI)
                      // ==========================================
                      GestureDetector(
                      onTap: () {
                        setState(() {
                          _isBmrExpanded = !_isBmrExpanded;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16171D),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Kalori Hedef Hesaplayıcı (TDEE/BMR)',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CupertinoColors.white),
                            ),
                            Icon(
                              _isBmrExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                              color: CupertinoColors.activeBlue,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (_isBmrExpanded) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16171D),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: CupertinoColors.systemGrey.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Boy (cm)', style: TextStyle(fontSize: 12, color: const Color(0xFF9EA0A5))),
                                      const SizedBox(height: 4),
                                      CupertinoTextField(
                                        controller: _heightController,
                                        placeholder: 'örn. 180',
                                        keyboardType: TextInputType.number,
                                        onChanged: (val) {
                                          final height = double.tryParse(val) ?? 0;
                                          notifier.updateCalculatorInputs(height: height);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Kilo (kg)', style: TextStyle(fontSize: 12, color: const Color(0xFF9EA0A5))),
                                      const SizedBox(height: 4),
                                      CupertinoTextField(
                                        controller: _weightController,
                                        placeholder: 'örn. 75',
                                        keyboardType: TextInputType.number,
                                        onChanged: (val) {
                                          final weight = double.tryParse(val) ?? 0;
                                          notifier.updateCalculatorInputs(weight: weight);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Yaş', style: TextStyle(fontSize: 12, color: const Color(0xFF9EA0A5))),
                                      const SizedBox(height: 4),
                                      CupertinoTextField(
                                        controller: _ageController,
                                        placeholder: 'örn. 25',
                                        keyboardType: TextInputType.number,
                                        onChanged: (val) {
                                          final age = int.tryParse(val) ?? 0;
                                          if (age > 0) {
                                            notifier.updateCalculatorInputs(age: age);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Cinsiyet', style: TextStyle(fontSize: 12, color: const Color(0xFF9EA0A5))),
                                      const SizedBox(height: 4),
                                      SizedBox(
                                        width: double.infinity,
                                        child: CupertinoSegmentedControl<String>(
                                          groupValue: _selectedGender,
                                          selectedColor: CupertinoColors.activeBlue,
                                          unselectedColor: const Color(0xFF16171D),
                                          borderColor: CupertinoColors.activeBlue.withOpacity(0.5),
                                          children: const {
                                            'erkek': Padding(
                                              padding: EdgeInsets.symmetric(vertical: 4),
                                              child: Text('Erkek', style: TextStyle(fontSize: 12)),
                                            ),
                                            'kadın': Padding(
                                              padding: EdgeInsets.symmetric(vertical: 4),
                                              child: Text('Kadın', style: TextStyle(fontSize: 12)),
                                            ),
                                          },
                                          onValueChanged: (val) {
                                            setState(() {
                                              _selectedGender = val;
                                            });
                                            notifier.updateCalculatorInputs(gender: val);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Formül Sonuçları (Hedef Olarak Ayarlamak İçin Dokunun):',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF9EA0A5)),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => notifier.updateTargetCalories(state.maintenanceCalories),
                              child: _buildCalculationOptionCard(
                                title: 'Kilo Koruma (Maintenance TDEE)',
                                calories: state.maintenanceCalories,
                                description: 'Kilonuzu korumak için almanız gereken miktar',
                                isActive: state.targetCalories == state.maintenanceCalories,
                                userWeight: state.userWeight,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => notifier.updateTargetCalories(state.loseWeightCalories),
                              child: _buildCalculationOptionCard(
                                title: 'Kilo Verme (Diyet/Definisyon)',
                                calories: state.loseWeightCalories,
                                description: 'Sağlıklı şekilde kilo vermek için',
                                isActive: state.targetCalories == state.loseWeightCalories,
                                userWeight: state.userWeight,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => notifier.updateTargetCalories(state.gainWeightCalories),
                              child: _buildCalculationOptionCard(
                                title: 'Kilo Alma (Hacim/Bulking)',
                                calories: state.gainWeightCalories,
                                description: 'Kas kütlesi eklemek ve kilo almak için',
                                isActive: state.targetCalories == state.gainWeightCalories,
                                userWeight: state.userWeight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 8),

                    // ==========================================
                    // 3b. MAKRO BİLGİLENDİRME KARTI (AÇILIR-KAPANIR YAPI)
                    // ==========================================
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isMacroInfoExpanded = !_isMacroInfoExpanded;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16171D),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Makro Besinler Hakkında Bilgi',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CupertinoColors.white),
                            ),
                            Icon(
                              _isMacroInfoExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                              color: CupertinoColors.activeBlue,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (_isMacroInfoExpanded) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16171D),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: CupertinoColors.systemGrey.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Makro besinler ya da kısaca "makrolar", vücudun enerji ve yapı taşı olarak kullandığı üç temel besin grubunu ifade eder: protein, karbonhidrat ve yağ. Her birinin farklı işlevleri, farklı enerji değerleri ve vücut kompozisyonu üzerinde farklı etkileri vardır. Kalori saymak "ne kadar yiyeceğini" söylerken, makro takibi "ne yiyeceğini" belirler.\n\n'
                          'Enerji değerleri açısından: Protein ve karbonhidrat gram başına 4 kcal, yağ ise gram başına 9 kcal sağlar. Bu fark, aynı kalori miktarını farklı gramaj kombinasyonlarıyla karşılayabileceğiniz anlamına gelir. Örneğin 2000 kcal\'lik bir plan; 200g protein (800 kcal) + 175g karbonhidrat (700 kcal) + 55g yağ (500 kcal) şeklinde düzenlenebilir.\n\n'
                          'Makro hesaplaması üç adımda gerçekleşir. Önce TDEE belirlenir, ardından hedefe göre (kilo verme, koruma veya kas kazanımı) toplam kalori ayarlanır. Son adımda bu kalori miktarı üç makroya dağıtılır. Bu hesap makinesi bu dağılımı otomatik olarak yapar.\n\n'
                          'Uygulamamızda makro dağılımı şu şekilde hesaplanır:\n'
                          '• Protein: Kilo × 1.76 gram\n'
                          '• Yağ: Kilo × 0.85 gram\n'
                          '• Karbonhidrat: Kalan kaloriler / 4 gram',
                          style: TextStyle(fontSize: 12, color: const Color(0xFF9EA0A5), height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 16),

                    // ==========================================
                    // 4. OTOMATİK SU TAKİBİ BÖLÜMÜ
                    // ==========================================
                    const Text(
                      'Su Takibi',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16171D),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.systemGrey.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Bugün Alınan',
                                      style: TextStyle(color: const Color(0xFF9EA0A5), fontSize: 13)),
                                  const SizedBox(height: 2),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        '${state.totalWaterIntake}',
                                        style: const TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            color: CupertinoColors.activeBlue),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '/ ${state.targetWater} ml',
                                        style: const TextStyle(fontSize: 14, color: const Color(0xFF9EA0A5)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (state.totalWaterIntake > 0)
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () => notifier.removeLastWaterIntake(),
                                  child: const Row(
                                    children: [
                                      Icon(CupertinoIcons.arrow_counterclockwise_circle, size: 20),
                                      SizedBox(width: 4),
                                      Text('Geri Al', style: TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: CupertinoTextField(
                                  controller: _waterInputController,
                                  placeholder: 'Miktar ekle (ml)...',
                                  keyboardType: TextInputType.number,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16171D),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: CupertinoButton(
                                  color: CupertinoColors.activeBlue,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  onPressed: () {
                                    final amount = int.tryParse(_waterInputController.text) ?? 0;
                                    if (amount > 0) {
                                      notifier.addWaterIntake(amount);
                                      _waterInputController.clear();
                                      FocusScope.of(context).unfocus();
                                    }
                                  },
                                  child: const Text('Ekle', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isWaterInfoExpanded = !_isWaterInfoExpanded;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: CupertinoColors.activeBlue.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(CupertinoIcons.info_circle, size: 16, color: CupertinoColors.activeBlue),
                                      SizedBox(width: 6),
                                      Text(
                                        'Su Tüketimi Hakkında Bilgi',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: CupertinoColors.activeBlue),
                                      ),
                                    ],
                                  ),
                                  Icon(
                                    _isWaterInfoExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                                    size: 14,
                                    color: CupertinoColors.activeBlue,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_isWaterInfoExpanded) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF090A0F),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Su, insan vücudunun yüzde 60\'ını oluşturan ve neredeyse tüm metabolik süreçlerin temelini oluşturan vazgeçilmez bir bileşendir. Besin maddelerini taşımak, vücut ısısını düzenlemek, eklemleri yağlamak, atık maddeleri uzaklaştırmak ve biyokimyasal reaksiyonlara ortam hazırlamak suyun başlıca görevleri arasındadır. Yeterli su tüketimi, hem sağlık hem de fiziksel performans açısından kalori ya da protein kadar kritik öneme sahiptir.\n\n'
                                'Günlük su ihtiyacı kişiden kişiye önemli ölçüde değişir. Bu hesap makinesi, vücut ağırlığınızı, aktivite düzeyinizi ve iklim koşullarınızı birlikte değerlendirerek kişiselleştirilmiş bir tavsiye sunar. Yaygın kullanılan temel formül; vücut ağırlığının kilogramı başına 30-35 ml su olarak hesaplanmasıdır. Buna göre 70 kg bir birey için günlük temel su ihtiyacı 2.1-2.45 litre olarak belirlenir.\n\n'
                                'Egzersiz, su ihtiyacını önemli ölçüde artırır. Egzersiz sırasında kaybedilen sıvıyı yerine koymak için her 30 dakikalık aktivite için su tüketimini artırmak önemlidir.',
                                style: TextStyle(fontSize: 12, color: const Color(0xFF9EA0A5), height: 1.4),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ==========================================
                    // 5. ANTRENMAN GÜNLÜĞÜ & ŞABLON SİSTEMİ
                    // ==========================================
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isWorkoutsExpanded = !_isWorkoutsExpanded;
                        });
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16171D),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Antrenmanlarım',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CupertinoColors.white),
                            ),
                            Row(
                              children: [
                                const Text('Off Day', style: TextStyle(fontSize: 12, color: const Color(0xFF9EA0A5))),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () {}, // Prevent panel collapse when tapping switch
                                  child: CupertinoSwitch(
                                    value: state.isTodayOffDay,
                                    onChanged: (val) => notifier.toggleOffDay(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _isWorkoutsExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                                  color: CupertinoColors.activeBlue,
                                  size: 20,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_isWorkoutsExpanded) ...[
                      if (state.isTodayOffDay) ...[
                        // COZY DINLENME KARTI (OFF DAY)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF090A0F),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: CupertinoColors.separator.withOpacity(0.5)),
                          ),
                          child: const Column(
                            children: [
                              Icon(CupertinoIcons.bed_double_fill, size: 48, color: CupertinoColors.activeBlue),
                              SizedBox(height: 12),
                              Text(
                                'Off Day 🛌',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Bugün dinlenme günü. Kaslarını dinlendir, bol bol su iç ve yeni antrenman gününe enerji depola!',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, color: const Color(0xFF9EA0A5), height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // SPOR ŞABLONLARI SEÇİM BARI
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Programlarım / Şablonlar:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF9EA0A5)),
                            ),
                            CupertinoButton(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              onPressed: () => _showCreateTemplateModal(),
                              child: const Row(
                                children: [
                                  Icon(CupertinoIcons.add_circled_solid, size: 16),
                                  SizedBox(width: 4),
                                  Text('Program Oluştur', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 38,
                          child: state.templates.isEmpty
                              ? const Center(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text('Kayıtlı antrenman programı bulunmuyor.', style: TextStyle(fontSize: 12, color: CupertinoColors.placeholderText)),
                                  ),
                                )
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: state.templates.length,
                                  itemBuilder: (context, index) {
                                    final template = state.templates[index];
                                    return Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      child: GestureDetector(
                                        onTap: () => _showTemplateOptions(template),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: CupertinoColors.activeBlue.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: CupertinoColors.activeBlue.withOpacity(0.3)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(CupertinoIcons.sportscourt, size: 14, color: CupertinoColors.activeBlue),
                                              const SizedBox(width: 6),
                                              Text(
                                                template.name,
                                                style: const TextStyle(fontSize: 13, color: CupertinoColors.activeBlue, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 16),

                        // HAREKET VE SET KAYITLARI
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Egzersiz Listesi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF9EA0A5))),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => _showAddWorkoutModal(),
                              child: const Row(
                                children: [
                                  Icon(CupertinoIcons.add, size: 16),
                                  SizedBox(width: 4),
                                  Text('Hareket Ekle', style: TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        groupedWorkouts.isEmpty
                            ? Container(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                alignment: Alignment.center,
                                child: const Text('Bugün henüz hareket eklenmedi veya şablon yüklenmedi.',
                                    style: TextStyle(color: const Color(0xFF9EA0A5), fontSize: 13)),
                              )
                            : Column(
                                children: groupedWorkouts.keys.map((exerciseName) {
                                  final setsList = groupedWorkouts[exerciseName]!;
                                  final isExpanded = _expandedExercises.contains(exerciseName);

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16171D),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: CupertinoColors.systemGrey.withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        // Egzersiz Başlık Satırı (Tıklanabilir)
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              if (isExpanded) {
                                                _expandedExercises.remove(exerciseName);
                                              } else {
                                                _expandedExercises.add(exerciseName);
                                              }
                                            });
                                          },
                                          behavior: HitTestBehavior.opaque,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF16171D),
                                              borderRadius: isExpanded
                                                  ? const BorderRadius.only(
                                                      topLeft: Radius.circular(14),
                                                      topRight: Radius.circular(14),
                                                    )
                                                  : BorderRadius.circular(14),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      isExpanded
                                                          ? CupertinoIcons.chevron_down
                                                          : CupertinoIcons.chevron_right,
                                                      size: 14,
                                                      color: const Color(0xFF9EA0A5),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      exerciseName,
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                    ),
                                                  ],
                                                ),
                                                CupertinoButton(
                                                  padding: EdgeInsets.zero,
                                                  minSize: 0,
                                                  onPressed: () => _showAddWorkoutModal(prefilledName: exerciseName),
                                                  child: const Row(
                                                    children: [
                                                      Icon(CupertinoIcons.add, size: 14),
                                                      SizedBox(width: 2),
                                                      Text('Set Ekle', style: TextStyle(fontSize: 12)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Setlerin Listesi (Sadece genişletilmişse)
                                        if (isExpanded)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                                            child: Column(
                                              children: setsList.map((log) {
                                                final isLogged = log.reps > 0 || log.weight > 0;
                                                return Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        'Set ${log.sets}:',
                                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                      ),
                                                      GestureDetector(
                                                        onTap: () => _showEditSetModal(log),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                          decoration: BoxDecoration(
                                                            color: isLogged
                                                                ? CupertinoColors.activeBlue.withOpacity(0.05)
                                                                : const Color(0xFF090A0F),
                                                            borderRadius: BorderRadius.circular(8),
                                                            border: Border.all(
                                                              color: isLogged ? CupertinoColors.activeBlue.withOpacity(0.2) : CupertinoColors.transparent,
                                                            ),
                                                          ),
                                                          child: Text(
                                                            isLogged
                                                                ? '${log.weight} kg x ${log.reps} tekrar'
                                                                : 'Değer girilmedi (Dokun)',
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              fontWeight: isLogged ? FontWeight.bold : FontWeight.normal,
                                                              color: isLogged ? CupertinoColors.activeBlue : const Color(0xFF9EA0A5),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      CupertinoButton(
                                                        padding: EdgeInsets.zero,
                                                        onPressed: () => notifier.deleteWorkout(log.id),
                                                        child: const Icon(CupertinoIcons.trash, color: CupertinoColors.destructiveRed, size: 18),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                    ],
                  ],
                  const SizedBox(height: 24),
                  _buildCardioSection(state, notifier),
                  const SizedBox(height: 24),

                    // ==========================================
                    // 6. AĞIRLIK TAKİBİ VE ÖZEL GRAFİK
                    // ==========================================
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isWeightExpanded = !_isWeightExpanded;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16171D),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Ağırlık Takibi & Hedef Kilo',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CupertinoColors.white),
                            ),
                            Icon(
                              _isWeightExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                              color: CupertinoColors.activeBlue,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_isWeightExpanded) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16171D),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: CupertinoColors.systemGrey.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Güncel Kilo',
                                          style: TextStyle(color: const Color(0xFF9EA0A5), fontSize: 12)),
                                      const SizedBox(height: 2),
                                      Text(
                                        state.currentWeight > 0 ? '${state.currentWeight} kg' : '-- kg',
                                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Hedef Kilo',
                                          style: TextStyle(color: const Color(0xFF9EA0A5), fontSize: 12)),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${state.targetWeight} kg',
                                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: CupertinoColors.systemRed),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              height: 180,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFF16171D),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: CustomPaint(
                                painter: WeightChartPainter(
                                  logs: state.weightLogs,
                                  targetWeight: state.targetWeight,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Ağırlık Kaydet (kg)', style: TextStyle(fontSize: 11, color: const Color(0xFF9EA0A5))),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: CupertinoTextField(
                                              controller: _weightLogController,
                                              placeholder: '72.5',
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          CupertinoButton(
                                            color: CupertinoColors.activeGreen,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            onPressed: () {
                                              final weight = double.tryParse(_weightLogController.text) ?? 0.0;
                                              if (weight > 0) {
                                                notifier.addWeight(weight);
                                                _weightLogController.clear();
                                                FocusScope.of(context).unfocus();
                                              }
                                            },
                                            child: const Icon(CupertinoIcons.checkmark, size: 14),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Hedef Kilo Değiştir', style: TextStyle(fontSize: 11, color: const Color(0xFF9EA0A5))),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: CupertinoTextField(
                                              controller: _targetWeightController,
                                              placeholder: '70.0',
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              onChanged: (val) {
                                                final target = double.tryParse(val) ?? 70.0;
                                                notifier.updateTargetWeight(target);
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCardioSection(FitnessState state, FitnessNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isCardioExpanded = !_isCardioExpanded;
            });
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF16171D),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(CupertinoIcons.sportscourt, color: CupertinoColors.activeGreen, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Kardiyo & Koşu Takibi',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CupertinoColors.white),
                    ),
                  ],
                ),
                Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 0,
                      onPressed: _showAddCardioModal,
                      child: const Icon(CupertinoIcons.add_circled_solid, color: CupertinoColors.activeGreen, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      _isCardioExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                      color: CupertinoColors.activeGreen,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_isCardioExpanded) ...[
          state.cardioLogs.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16171D),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Bugün henüz kardiyo veya koşu kaydı eklenmedi.',
                    style: TextStyle(color: Color(0xFF9EA0A5), fontSize: 13),
                  ),
                )
              : Column(
                  children: state.cardioLogs.map((log) {
                    final isStep = log.steps > 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16171D),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: CupertinoColors.activeGreen.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isStep ? CupertinoIcons.wind : CupertinoIcons.sportscourt_fill,
                              color: CupertinoColors.activeGreen,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isStep ? 'Adım Takibi' : 'Koşu Bandı',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: CupertinoColors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isStep
                                      ? '${log.steps} Adım • ~${log.calculatedCalories} kcal'
                                      : 'Hız: ${log.speed} km/h • Eğim: %${log.incline} • ${log.duration} dk • ~${log.calculatedCalories} kcal',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9EA0A5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Completed Checkbox
                          GestureDetector(
                            onTap: () => notifier.toggleCardioCompleted(log.id),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: log.isCompleted
                                    ? CupertinoColors.activeGreen
                                    : CupertinoColors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: CupertinoColors.activeGreen,
                                  width: 2.0,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: log.isCompleted
                                  ? const Icon(
                                      CupertinoIcons.checkmark,
                                      color: CupertinoColors.black,
                                      size: 14,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            minSize: 0,
                            onPressed: () => notifier.deleteCardioLog(log.id),
                            child: const Icon(
                              CupertinoIcons.trash,
                              color: CupertinoColors.destructiveRed,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ],
    );
  }

  Widget _buildCalculationOptionCard({
    required String title,
    required int calories,
    required String description,
    required bool isActive,
    required double userWeight,
  }) {
    final p = (userWeight * 1.76).round();
    final f = (userWeight * 0.85).round();
    final c = ((calories - (p * 4) - (f * 9)) / 4).round().clamp(0, 9999);

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive
            ? CupertinoColors.activeBlue.withOpacity(0.08)
            : const Color(0xFF16171D),
        borderRadius: BorderRadius.circular(10),
        border: isActive
            ? Border.all(color: CupertinoColors.activeBlue, width: 1.5)
            : Border.all(color: CupertinoColors.transparent),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isActive ? CupertinoColors.activeBlue : CupertinoColors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11, color: const Color(0xFF9EA0A5)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hedef: $p g P | $c g C | $f g F',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? CupertinoColors.activeBlue.withOpacity(0.8) : const Color(0xFF9EA0A5),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$calories kcal',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: isActive ? CupertinoColors.activeBlue : CupertinoColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// CUSTOMWEIGHT LINE CHART PAINTER
// =========================================================================
class WeightChartPainter extends CustomPainter {
  final List<WeightLog> logs;
  final double targetWeight;

  WeightChartPainter({required this.logs, required this.targetWeight});

  @override
  void paint(Canvas canvas, Size size) {
    if (logs.isEmpty) {
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'Kayıt bulunamadı. Kilo kaydedin.',
          style: TextStyle(color: const Color(0xFF9EA0A5), fontSize: 13),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2),
      );
      return;
    }

    final paint = Paint()
      ..color = CupertinoColors.activeBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = CupertinoColors.activeBlue
      ..style = PaintingStyle.fill;

    final targetPaint = Paint()
      ..color = CupertinoColors.systemRed
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final gridPaint = Paint()
      ..color = CupertinoColors.separator
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    double minW = targetWeight;
    double maxW = targetWeight;
    for (var log in logs) {
      if (log.weight < minW) minW = log.weight;
      if (log.weight > maxW) maxW = log.weight;
    }

    minW -= 2;
    maxW += 2;
    if (minW < 0) minW = 0;
    if (maxW == minW) maxW += 4;

    final double range = maxW - minW;

    double getX(int index) {
      if (logs.length <= 1) return size.width / 2;
      return (index / (logs.length - 1)) * (size.width - 60) + 20;
    }

    double getY(double weight) {
      final ratio = (weight - minW) / range;
      return size.height - (ratio * (size.height - 40) + 20);
    }

    const int gridCount = 3;
    for (int i = 0; i <= gridCount; i++) {
      final y = 20 + i * (size.height - 40) / gridCount;
      canvas.drawLine(Offset(20, y), Offset(size.width - 20, y), gridPaint);
      
      final labelW = maxW - i * range / gridCount;
      final textPainter = TextPainter(
        text: TextSpan(
          text: labelW.toStringAsFixed(1),
          style: const TextStyle(color: const Color(0xFF9EA0A5), fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(size.width - 40, y - 12));
    }

    final targetY = getY(targetWeight);
    double curX = 20;
    const double dashWidth = 5;
    const double dashSpace = 3;
    while (curX < size.width - 20) {
      canvas.drawLine(Offset(curX, targetY), Offset(curX + dashWidth, targetY), targetPaint);
      curX += dashWidth + dashSpace;
    }
    
    final targetLabelPainter = TextPainter(
      text: TextSpan(
        text: 'Hedef: $targetWeight kg',
        style: const TextStyle(color: CupertinoColors.systemRed, fontSize: 9, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    targetLabelPainter.paint(canvas, Offset(25, targetY - 13));

    final path = Path();
    for (int i = 0; i < logs.length; i++) {
      final x = getX(i);
      final y = getY(logs[i].weight);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);

    for (int i = 0; i < logs.length; i++) {
      final x = getX(i);
      final y = getY(logs[i].weight);
      canvas.drawCircle(Offset(x, y), 4, dotPaint);

      final valPainter = TextPainter(
        text: TextSpan(
          text: '${logs[i].weight}',
          style: const TextStyle(color: CupertinoColors.white, fontSize: 9, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      valPainter.paint(canvas, Offset(x - valPainter.width / 2, y - 16));
      
      final dateStr = '${logs[i].date.day}/${logs[i].date.month}';
      final datePainter = TextPainter(
        text: TextSpan(
          text: dateStr,
          style: const TextStyle(color: const Color(0xFF9EA0A5), fontSize: 8),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      datePainter.paint(canvas, Offset(x - datePainter.width / 2, size.height - 12));
    }
  }

  @override
  bool shouldRepaint(covariant WeightChartPainter oldDelegate) {
    return oldDelegate.logs != logs || oldDelegate.targetWeight != targetWeight;
  }
}
