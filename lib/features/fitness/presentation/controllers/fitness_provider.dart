import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../../core/database/hive_models.dart';

class WorkoutTemplate {
  final String id;
  final String name; // örn: Göğüs & Biceps
  final List<String> exerciseNames;
  final List<int> setCounts;

  WorkoutTemplate({
    required this.id,
    required this.name,
    required this.exerciseNames,
    required this.setCounts,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'exerciseNames': exerciseNames,
        'setCounts': setCounts,
      };

  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) => WorkoutTemplate(
        id: json['id'] as String,
        name: json['name'] as String,
        exerciseNames: List<String>.from(json['exerciseNames'] ?? []),
        setCounts: List<int>.from(json['setCounts'] ?? []),
      );
}

class CardioLog {
  final String id;
  final DateTime date;
  final int steps; // Adım
  final double speed; // Hız (km/h)
  final double incline; // Eğim (%)
  final int duration; // Süre (dakika)
  final int calculatedCalories; // Hesaplanan ortalama kalori
  final bool isCompleted; // Yapıldı / Yapılmadı

  CardioLog({
    required this.id,
    required this.date,
    required this.steps,
    required this.speed,
    required this.incline,
    required this.duration,
    required this.calculatedCalories,
    required this.isCompleted,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'steps': steps,
        'speed': speed,
        'incline': incline,
        'duration': duration,
        'calculatedCalories': calculatedCalories,
        'isCompleted': isCompleted,
      };

  factory CardioLog.fromJson(Map<String, dynamic> json) => CardioLog(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        steps: json['steps'] as int? ?? 0,
        speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
        incline: (json['incline'] as num?)?.toDouble() ?? 0.0,
        duration: json['duration'] as int? ?? 0,
        calculatedCalories: json['calculatedCalories'] as int? ?? 0,
        isCompleted: json['isCompleted'] as bool? ?? false,
      );

  CardioLog copyWith({
    String? id,
    DateTime? date,
    int? steps,
    double? speed,
    double? incline,
    int? duration,
    int? calculatedCalories,
    bool? isCompleted,
  }) {
    return CardioLog(
      id: id ?? this.id,
      date: date ?? this.date,
      steps: steps ?? this.steps,
      speed: speed ?? this.speed,
      incline: incline ?? this.incline,
      duration: duration ?? this.duration,
      calculatedCalories: calculatedCalories ?? this.calculatedCalories,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class FitnessState {
  final DateTime selectedDate;
  final int targetCalories;
  final List<CalorieLog> calorieLogs; // Seçilen tarihteki
  final List<WaterLog> waterLogs; // Seçilen tarihteki
  final List<WorkoutLog> workoutLogs; // Seçilen tarihteki
  final List<CardioLog> cardioLogs; // Seçilen tarihteki kardiyo kayıtları
  final List<WeightLog> weightLogs; // Grafik için tüm geçmiş
  final List<WorkoutTemplate> templates; // Tüm kayıtlı şablonlar
  final bool isTodayOffDay; // Seçili gün offday mi?
  final double userHeight; // cm
  final double userWeight; // kg
  final double targetWeight; // kg (Grafikteki hedef çizgisi)
  final int userAge; // yaş
  final String userGender; // 'erkek' veya 'kadın'

  FitnessState({
    required this.selectedDate,
    required this.targetCalories,
    required this.calorieLogs,
    required this.waterLogs,
    required this.workoutLogs,
    required this.cardioLogs,
    required this.weightLogs,
    required this.templates,
    required this.isTodayOffDay,
    this.userHeight = 175.0,
    this.userWeight = 70.0,
    this.targetWeight = 70.0,
    this.userAge = 22,
    this.userGender = 'erkek',
  });

  int get totalCaloriesTaken => calorieLogs
      .where((log) => log.type == 'taken')
      .fold(0, (sum, log) => sum + log.amount);

  int get totalCaloriesBurned => calorieLogs
      .where((log) => log.type == 'burned')
      .fold(0, (sum, log) => sum + log.amount);

  int get remainingCalories =>
      targetCalories - totalCaloriesTaken + totalCaloriesBurned;

  int get totalWaterIntake =>
      waterLogs.fold(0, (sum, log) => sum + log.amount);

  double get currentWeight =>
      weightLogs.isNotEmpty ? weightLogs.last.weight : 0.0;

  // Otomatik Su Hedefi = (Kilo x 35 ml) + 1000 ml
  int get targetWater => (userWeight * 35).round() + 1000;

  // Hedef Makrolar (Protein: Kilo * 1.76, Yağ: Kilo * 0.85, Karbonhidrat: Kalan kaloriler)
  int get targetProtein => (userWeight * 1.76).round();
  int get targetFat => (userWeight * 0.85).round();
  int get targetCarb => ((targetCalories - (targetProtein * 4) - (targetFat * 9)) / 4).round().clamp(0, 9999);

  // Tüketilen Makrolar (Açıklama satırındaki | P: | C: | F: etiketlerini parse eder)
  double get totalProteinTaken => _sumMacro('P');
  double get totalCarbTaken => _sumMacro('C');
  double get totalFatTaken => _sumMacro('F');

  double _sumMacro(String tag) {
    return calorieLogs
        .where((log) => log.type == 'taken')
        .fold(0.0, (sum, log) {
          final parts = log.description.split('| $tag:');
          if (parts.length > 1) {
            final valPart = parts[1].split('|')[0];
            return sum + (double.tryParse(valPart.trim()) ?? 0.0);
          }
          return sum;
        });
  }

  // Kalori Hesaplayıcı: Mifflin-St Jeor Formülü (Erkek/Kadın, Yaş Çarpanı)
  int get maintenanceCalories {
    if (userHeight == 0 || userWeight == 0) return 2000;
    final isMale = userGender.toLowerCase() == 'erkek';
    final bmr = (10 * userWeight) + (6.25 * userHeight) - (5 * userAge) + (isMale ? 5 : -161);
    return (bmr * 1.375).round();
  }

  int get loseWeightCalories => maintenanceCalories - 500;
  int get gainWeightCalories => maintenanceCalories + 500;

  FitnessState copyWith({
    DateTime? selectedDate,
    int? targetCalories,
    List<CalorieLog>? calorieLogs,
    List<WaterLog>? waterLogs,
    List<WorkoutLog>? workoutLogs,
    List<CardioLog>? cardioLogs,
    List<WeightLog>? weightLogs,
    List<WorkoutTemplate>? templates,
    bool? isTodayOffDay,
    double? userHeight,
    double? userWeight,
    double? targetWeight,
    int? userAge,
    String? userGender,
  }) {
    return FitnessState(
      selectedDate: selectedDate ?? this.selectedDate,
      targetCalories: targetCalories ?? this.targetCalories,
      calorieLogs: calorieLogs ?? this.calorieLogs,
      waterLogs: waterLogs ?? this.waterLogs,
      workoutLogs: workoutLogs ?? this.workoutLogs,
      cardioLogs: cardioLogs ?? this.cardioLogs,
      weightLogs: weightLogs ?? this.weightLogs,
      templates: templates ?? this.templates,
      isTodayOffDay: isTodayOffDay ?? this.isTodayOffDay,
      userHeight: userHeight ?? this.userHeight,
      userWeight: userWeight ?? this.userWeight,
      targetWeight: targetWeight ?? this.targetWeight,
      userAge: userAge ?? this.userAge,
      userGender: userGender ?? this.userGender,
    );
  }
}

class FitnessNotifier extends StateNotifier<FitnessState> {
  FitnessNotifier()
      : super(FitnessState(
          selectedDate: DateTime.now(),
          targetCalories: 2000,
          calorieLogs: [],
          waterLogs: [],
          workoutLogs: [],
          cardioLogs: [],
          weightLogs: [],
          templates: [],
          isTodayOffDay: false,
        ));

  late final Box<CalorieLog> _calorieBox;
  late final Box<WaterLog> _waterBox;
  late final Box<WorkoutLog> _workoutBox;
  late final Box<WeightLog> _weightBox;
  late final Box<String> _templateBox;
  late final Box<String> _offdayBox;
  late final Box<String> _cardioBox;
  late final Box _settingsBox;

  void init() {
    _calorieBox = Hive.box<CalorieLog>('fitness_calories');
    _waterBox = Hive.box<WaterLog>('fitness_water');
    _workoutBox = Hive.box<WorkoutLog>('fitness_workouts');
    _weightBox = Hive.box<WeightLog>('fitness_weights');
    _templateBox = Hive.box<String>('fitness_templates');
    _offdayBox = Hive.box<String>('fitness_offdays');
    _cardioBox = Hive.box<String>('fitness_cardio');
    _settingsBox = Hive.box('fitness_settings');

    // Varsayılan antrenman programlarını yükle
    if (_templateBox.isEmpty) {
      final pushId = 'default_push';
      final pushTemplate = WorkoutTemplate(
        id: pushId,
        name: 'Göğüs ve Omuz (Push Day)',
        exerciseNames: [
          'Bench press',
          'Incline dumbbell press',
          'Fly machine',
          'Shoulder press',
          'Lateral raise',
          'Triceps pushdown',
        ],
        setCounts: [2, 2, 2, 2, 2, 2],
      );
      _templateBox.put(pushId, jsonEncode(pushTemplate.toJson()));

      final pullId = 'default_pull';
      final pullTemplate = WorkoutTemplate(
        id: pullId,
        name: 'Sırt ve Biceps (Pull Day)',
        exerciseNames: [
          'Lat pulldown',
          'Barbell row',
          'Rope pullover',
          'Spider curl',
          'Hammer curl',
        ],
        setCounts: [2, 2, 3, 2, 2],
      );
      _templateBox.put(pullId, jsonEncode(pullTemplate.toJson()));

      final legId = 'default_leg';
      final legTemplate = WorkoutTemplate(
        id: legId,
        name: 'Bacak (Leg Day)',
        exerciseNames: [
          'Squat / Leg press',
          'Leg extension',
          'Leg curl (arka bacak için)',
          'Calf raise',
        ],
        setCounts: [2, 2, 2, 3],
      );
      _templateBox.put(legId, jsonEncode(legTemplate.toJson()));
    }

    loadInitialData();
  }

  void loadInitialData() {
    final height = _settingsBox.get('userHeight', defaultValue: 175.0) as double;
    final weightLogs = _weightBox.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final double weight = weightLogs.isNotEmpty 
        ? weightLogs.last.weight 
        : (_settingsBox.get('userWeight', defaultValue: 70.0) as double);
    final age = _settingsBox.get('userAge', defaultValue: 22) as int;
    final gender = _settingsBox.get('userGender', defaultValue: 'erkek') as String;
    final targetWeight = _settingsBox.get('targetWeight', defaultValue: 70.0) as double;
    final targetCalories = _settingsBox.get('targetCalories', defaultValue: 2000) as int;

    state = FitnessState(
      selectedDate: DateTime.now(),
      targetCalories: targetCalories,
      calorieLogs: [],
      waterLogs: [],
      workoutLogs: [],
      cardioLogs: [],
      weightLogs: [],
      templates: [],
      isTodayOffDay: false,
      userHeight: height,
      userWeight: weight,
      userAge: age,
      userGender: gender,
      targetWeight: targetWeight,
    );

    loadDataForDate(DateTime.now());
  }

  void changeSelectedDate(DateTime date) {
    loadDataForDate(date);
  }

  void loadTodayData() {
    loadDataForDate(DateTime.now());
  }

  void loadDataForDate(DateTime date) {
    final calorieLogs = _calorieBox.values.where((log) {
      return log.date.year == date.year &&
          log.date.month == date.month &&
          log.date.day == date.day;
    }).toList();

    final waterLogs = _waterBox.values.where((log) {
      return log.date.year == date.year &&
          log.date.month == date.month &&
          log.date.day == date.day;
    }).toList();

    final workoutLogs = _workoutBox.values.where((log) {
      return log.date.year == date.year &&
          log.date.month == date.month &&
          log.date.day == date.day;
    }).toList();

    final cardioLogs = _cardioBox.values.map((jsonStr) {
      return CardioLog.fromJson(jsonDecode(jsonStr));
    }).where((log) {
      return log.date.year == date.year &&
          log.date.month == date.month &&
          log.date.day == date.day;
    }).toList();

    final weightLogs = _weightBox.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Şablonları yükle
    final templates = _templateBox.values.map((jsonStr) {
      return WorkoutTemplate.fromJson(jsonDecode(jsonStr));
    }).toList();

    // Offday kontrolü
    final dateKey = _formatDateKey(date);
    final isTodayOffDay = _offdayBox.values.contains(dateKey);

    // Sync weight if it differs in DB
    final latestWeight = weightLogs.isNotEmpty ? weightLogs.last.weight : state.userWeight;
    if (latestWeight != state.userWeight) {
      _settingsBox.put('userWeight', latestWeight);
    }

    state = state.copyWith(
      selectedDate: date,
      calorieLogs: calorieLogs,
      waterLogs: waterLogs,
      workoutLogs: workoutLogs,
      cardioLogs: cardioLogs,
      weightLogs: weightLogs,
      templates: templates,
      isTodayOffDay: isTodayOffDay,
      userWeight: latestWeight,
    );
  }

  Future<void> addCalorieLog(int amount, String type, String description) async {
    final log = CalorieLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      type: type,
      description: description.isEmpty ? (type == 'taken' ? 'Yemek' : 'Antrenman') : description,
      date: state.selectedDate,
    );
    await _calorieBox.add(log);
    loadDataForDate(state.selectedDate);
  }

  Future<void> deleteCalorieLog(String id) async {
    final index = _calorieBox.values.toList().indexWhere((log) => log.id == id);
    if (index != -1) {
      await _calorieBox.deleteAt(index);
      loadDataForDate(state.selectedDate);
    }
  }

  Future<void> addWaterIntake(int amount) async {
    final log = WaterLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      date: state.selectedDate,
    );
    await _waterBox.add(log);
    loadDataForDate(state.selectedDate);
  }

  Future<void> removeLastWaterIntake() async {
    final date = state.selectedDate;
    final todayWaterLogs = _waterBox.values.where((log) {
      return log.date.year == date.year &&
          log.date.month == date.month &&
          log.date.day == date.day;
    }).toList();

    if (todayWaterLogs.isNotEmpty) {
      final lastLog = todayWaterLogs.last;
      final index = _waterBox.values.toList().indexOf(lastLog);
      if (index != -1) {
        await _waterBox.deleteAt(index);
      }
      loadDataForDate(state.selectedDate);
    }
  }

  Future<void> addWorkout(String exerciseName, int sets, int reps, double weight) async {
    final log = WorkoutLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      exerciseName: exerciseName,
      sets: sets,
      reps: reps,
      weight: weight,
      date: state.selectedDate,
    );
    await _workoutBox.add(log);
    loadDataForDate(state.selectedDate);
  }

  Future<void> updateWorkoutSet(String id, double weight, int reps) async {
    final index = _workoutBox.values.toList().indexWhere((w) => w.id == id);
    if (index != -1) {
      final existing = _workoutBox.getAt(index)!;
      final updated = WorkoutLog(
        id: existing.id,
        exerciseName: existing.exerciseName,
        sets: existing.sets,
        reps: reps,
        weight: weight,
        date: existing.date,
      );
      await _workoutBox.putAt(index, updated);
      loadDataForDate(state.selectedDate);
    }
  }

  Future<void> deleteWorkout(String id) async {
    final index = _workoutBox.values.toList().indexWhere((w) => w.id == id);
    if (index != -1) {
      await _workoutBox.deleteAt(index);
      loadDataForDate(state.selectedDate);
    }
  }

  // ==========================================
  // ŞABLON İŞLEMLERİ
  // ==========================================
  Future<void> addTemplate(String name, List<String> exercises, List<int> sets) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final template = WorkoutTemplate(
      id: id,
      name: name,
      exerciseNames: exercises,
      setCounts: sets,
    );
    await _templateBox.put(id, jsonEncode(template.toJson()));
    loadDataForDate(state.selectedDate);
  }

  Future<void> updateTemplate(String id, String name, List<String> exercises, List<int> sets) async {
    final template = WorkoutTemplate(
      id: id,
      name: name,
      exerciseNames: exercises,
      setCounts: sets,
    );
    await _templateBox.put(id, jsonEncode(template.toJson()));
    loadDataForDate(state.selectedDate);
  }

  Future<void> deleteTemplate(String id) async {
    await _templateBox.delete(id);
    loadDataForDate(state.selectedDate);
  }

  Future<void> applyTemplate(String templateId) async {
    final jsonStr = _templateBox.get(templateId);
    if (jsonStr != null) {
      final template = WorkoutTemplate.fromJson(jsonDecode(jsonStr));
      
      // Şablondaki her hareket ve set için boş loglar oluştur (Ağırlık: 0, Tekrar: 0)
      for (int i = 0; i < template.exerciseNames.length; i++) {
        final exercise = template.exerciseNames[i];
        final setTotal = template.setCounts[i];
        
        for (int setNum = 1; setNum <= setTotal; setNum++) {
          final log = WorkoutLog(
            id: '${DateTime.now().millisecondsSinceEpoch}_${exercise}_${setNum}',
            exerciseName: exercise,
            sets: setNum, // Hangi set olduğunu 'sets' alanında tutuyoruz
            reps: 0,
            weight: 0.0,
            date: state.selectedDate,
          );
          await _workoutBox.add(log);
        }
      }
      
      // Eğer gün offday olarak işaretliyse, otomatik olarak offday'i kaldır
      final dateKey = _formatDateKey(state.selectedDate);
      if (_offdayBox.values.contains(dateKey)) {
        final keyIndex = _offdayBox.values.toList().indexOf(dateKey);
        if (keyIndex != -1) {
          await _offdayBox.deleteAt(keyIndex);
        }
      }
      
      loadDataForDate(state.selectedDate);
    }
  }

  // ==========================================
  // OFF DAY İŞLEMLERİ
  // ==========================================
  Future<void> toggleOffDay() async {
    final dateKey = _formatDateKey(state.selectedDate);
    final isOffDay = _offdayBox.values.contains(dateKey);

    if (isOffDay) {
      final index = _offdayBox.values.toList().indexOf(dateKey);
      if (index != -1) {
        await _offdayBox.deleteAt(index);
      }
    } else {
      await _offdayBox.add(dateKey);
      
      // Off day yapıldığında o günkü mevcut antrenmanları temizle
      final todayWorkouts = _workoutBox.values.where((w) {
        return w.date.year == state.selectedDate.year &&
            w.date.month == state.selectedDate.month &&
            w.date.day == state.selectedDate.day;
      }).toList();
      
      for (var w in todayWorkouts) {
        final idx = _workoutBox.values.toList().indexOf(w);
        if (idx != -1) {
          await _workoutBox.deleteAt(idx);
        }
      }
    }
    loadDataForDate(state.selectedDate);
  }

  Future<void> addWeight(double weight) async {
    final date = state.selectedDate;
    final weightIndex = _weightBox.values.toList().indexWhere((log) =>
        log.date.year == date.year &&
        log.date.month == date.month &&
        log.date.day == date.day);

    if (weightIndex != -1) {
      final log = WeightLog(
        id: _weightBox.getAt(weightIndex)!.id,
        weight: weight,
        date: date,
      );
      await _weightBox.putAt(weightIndex, log);
    } else {
      final log = WeightLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        weight: weight,
        date: date,
      );
      await _weightBox.add(log);
    }
    _settingsBox.put('userWeight', weight);
    state = state.copyWith(userWeight: weight);
    loadDataForDate(state.selectedDate);
  }

  void updateCalculatorInputs({double? height, double? weight, int? age, String? gender}) {
    final newHeight = height ?? state.userHeight;
    final newWeight = weight ?? state.userWeight;
    final newAge = age ?? state.userAge;
    final newGender = gender ?? state.userGender;

    _settingsBox.put('userHeight', newHeight);
    _settingsBox.put('userWeight', newWeight);
    _settingsBox.put('userAge', newAge);
    _settingsBox.put('userGender', newGender);

    state = state.copyWith(
      userHeight: newHeight,
      userWeight: newWeight,
      userAge: newAge,
      userGender: newGender,
    );
  }

  void updateTargetWeight(double target) {
    _settingsBox.put('targetWeight', target);
    state = state.copyWith(targetWeight: target);
  }

  void updateTargetCalories(int target) {
    _settingsBox.put('targetCalories', target);
    state = state.copyWith(targetCalories: target);
  }

  // ==========================================
  // KARDİYO & KOŞU İŞLEMLERİ
  // ==========================================
  int calculateCardioCalories({
    required double speed,
    required double incline,
    required int duration,
  }) {
    if (duration <= 0 || state.userWeight <= 0) return 0;
    
    // Hız m/dak cinsine çevrilir: 1 km/h = 1000m / 60dak = 16.67 m/dak
    final speedMins = speed * 16.67;
    final grade = incline / 100.0;
    
    double vo2 = 0.0;
    if (speed <= 6.0) {
      // Yürüyüş formülü
      vo2 = (0.1 * speedMins) + (1.8 * speedMins * grade) + 3.5;
    } else {
      // Koşu formülü
      vo2 = (0.2 * speedMins) + (0.9 * speedMins * grade) + 3.5;
    }
    
    // Dakika başına kalori = VO2 * ağırlık * 0.005
    final calPerMin = vo2 * state.userWeight * 0.005;
    return (calPerMin * duration).round();
  }

  Future<void> addCardioLog({
    required int steps,
    required double speed,
    required double incline,
    required int duration,
    required int calculatedCalories,
    bool isCompleted = false,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final log = CardioLog(
      id: id,
      date: state.selectedDate,
      steps: steps,
      speed: speed,
      incline: incline,
      duration: duration,
      calculatedCalories: calculatedCalories,
      isCompleted: isCompleted,
    );
    await _cardioBox.put(id, jsonEncode(log.toJson()));
    
    // Eğer doğrudan yapıldı işaretli eklendiyse ve kalori varsa yakılan kaloriye otomatik ekle
    if (isCompleted && calculatedCalories > 0) {
      final desc = steps > 0 ? "Kardiyo: $steps Adım" : "Kardiyo: $duration dk Koşu (%$incline Eğim, $speed km/h)";
      await addCalorieLog(calculatedCalories, 'burned', desc);
    }
    
    loadDataForDate(state.selectedDate);
  }

  Future<void> toggleCardioCompleted(String id) async {
    final jsonStr = _cardioBox.get(id);
    if (jsonStr != null) {
      final existing = CardioLog.fromJson(jsonDecode(jsonStr));
      final wasCompleted = existing.isCompleted;
      final updated = existing.copyWith(isCompleted: !wasCompleted);
      
      await _cardioBox.put(id, jsonEncode(updated.toJson()));
      
      final desc = existing.steps > 0 
          ? "Kardiyo: ${existing.steps} Adım" 
          : "Kardiyo: ${existing.duration} dk Koşu (%${existing.incline} Eğim, ${existing.speed} km/h)";

      if (updated.isCompleted && updated.calculatedCalories > 0) {
        // Otomatik ekle
        await addCalorieLog(updated.calculatedCalories, 'burned', desc);
      } else if (!updated.isCompleted && wasCompleted && updated.calculatedCalories > 0) {
        // Sil
        final calorieIndex = _calorieBox.values.toList().indexWhere((log) => 
          log.date.year == state.selectedDate.year &&
          log.date.month == state.selectedDate.month &&
          log.date.day == state.selectedDate.day &&
          log.type == 'burned' &&
          log.amount == updated.calculatedCalories &&
          log.description == desc
        );
        if (calorieIndex != -1) {
          await _calorieBox.deleteAt(calorieIndex);
        }
      }
      
      loadDataForDate(state.selectedDate);
    }
  }

  Future<void> deleteCardioLog(String id) async {
    final jsonStr = _cardioBox.get(id);
    if (jsonStr != null) {
      final log = CardioLog.fromJson(jsonDecode(jsonStr));
      if (log.isCompleted && log.calculatedCalories > 0) {
        final desc = log.steps > 0 
            ? "Kardiyo: ${log.steps} Adım" 
            : "Kardiyo: ${log.duration} dk Koşu (%${log.incline} Eğim, ${log.speed} km/h)";
        final calorieIndex = _calorieBox.values.toList().indexWhere((cLog) => 
          cLog.date.year == state.selectedDate.year &&
          cLog.date.month == state.selectedDate.month &&
          cLog.date.day == state.selectedDate.day &&
          cLog.type == 'burned' &&
          cLog.amount == log.calculatedCalories &&
          cLog.description == desc
        );
        if (calorieIndex != -1) {
          await _calorieBox.deleteAt(calorieIndex);
        }
      }
      await _cardioBox.delete(id);
      loadDataForDate(state.selectedDate);
    }
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

final fitnessProvider =
    StateNotifierProvider<FitnessNotifier, FitnessState>((ref) {
  return FitnessNotifier()..init();
});
