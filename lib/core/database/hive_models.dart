import 'package:hive/hive.dart';

part 'hive_models.g.dart';

// ==========================================
// 1. ÜRETKENLİK MODÜLÜ MODELLERİ
// ==========================================

@HiveType(typeId: 0)
class Todo extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final bool isCompleted; // Görevler için geçerli

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final bool isHabit; // Alışkanlık mı yoksa tek seferlik görev mi?

  @HiveField(5)
  final int streak; // Alışkanlık zinciri (Grit tarzı - 🔥)

  @HiveField(6)
  final int colorIndex; // Grit tarzı kart rengi (0: Yeşil, 1: Mavi, 2: Turuncu, 3: Mor)

  @HiveField(7)
  final List<String> completedDates; // Alışkanlığın tamamlandığı tarihler (yyyy-MM-dd formatında)

  Todo({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.date,
    this.isHabit = false,
    this.streak = 0,
    this.colorIndex = 0,
    List<String>? completedDates,
  }) : completedDates = completedDates ?? const [];

  Todo copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? date,
    bool? isHabit,
    int? streak,
    int? colorIndex,
    List<String>? completedDates,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      date: date ?? this.date,
      isHabit: isHabit ?? this.isHabit,
      streak: streak ?? this.streak,
      colorIndex: colorIndex ?? this.colorIndex,
      completedDates: completedDates ?? this.completedDates,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
        'date': date.toIso8601String(),
        'isHabit': isHabit,
        'streak': streak,
        'colorIndex': colorIndex,
        'completedDates': completedDates,
      };

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
        id: json['id'] as String,
        title: json['title'] as String,
        isCompleted: json['isCompleted'] as bool,
        date: DateTime.parse(json['date'] as String),
        isHabit: json['isHabit'] as bool? ?? false,
        streak: json['streak'] as int? ?? 0,
        colorIndex: json['colorIndex'] as int? ?? 0,
        completedDates: List<String>.from(json['completedDates'] as List? ?? []),
      );
}

@HiveType(typeId: 1)
class Note extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String content;

  @HiveField(2)
  final DateTime date;

  Note({
    required this.id,
    required this.content,
    required this.date,
  });

  Note copyWith({
    String? id,
    String? content,
    DateTime? date,
  }) {
    return Note(
      id: id ?? this.id,
      content: content ?? this.content,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'date': date.toIso8601String(),
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'] as String,
        content: json['content'] as String,
        date: DateTime.parse(json['date'] as String),
      );
}

// ==========================================
// 2. FITNESS & SAĞLIK MODÜLÜ MODELLERİ
// ==========================================

@HiveType(typeId: 2)
class CalorieLog extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int amount;

  @HiveField(2)
  final String type; // 'taken' veya 'burned'

  @HiveField(3)
  final String description;

  @HiveField(4)
  final DateTime date;

  CalorieLog({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'type': type,
        'description': description,
        'date': date.toIso8601String(),
      };

  factory CalorieLog.fromJson(Map<String, dynamic> json) => CalorieLog(
        id: json['id'] as String,
        amount: json['amount'] as int,
        type: json['type'] as String,
        description: json['description'] as String,
        date: DateTime.parse(json['date'] as String),
      );
}

@HiveType(typeId: 3)
class WaterLog extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int amount; // ml

  @HiveField(2)
  final DateTime date;

  WaterLog({
    required this.id,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'date': date.toIso8601String(),
      };

  factory WaterLog.fromJson(Map<String, dynamic> json) => WaterLog(
        id: json['id'] as String,
        amount: json['amount'] as int,
        date: DateTime.parse(json['date'] as String),
      );
}

@HiveType(typeId: 4)
class WorkoutLog extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String exerciseName;

  @HiveField(2)
  final int sets;

  @HiveField(3)
  final int reps;

  @HiveField(4)
  final double weight; // kg

  @HiveField(5)
  final DateTime date;

  WorkoutLog({
    required this.id,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.weight,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'exerciseName': exerciseName,
        'sets': sets,
        'reps': reps,
        'weight': weight,
        'date': date.toIso8601String(),
      };

  factory WorkoutLog.fromJson(Map<String, dynamic> json) => WorkoutLog(
        id: json['id'] as String,
        exerciseName: json['exerciseName'] as String,
        sets: json['sets'] as int,
        reps: json['reps'] as int,
        weight: (json['weight'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
      );
}

@HiveType(typeId: 5)
class WeightLog extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double weight; // kg

  @HiveField(2)
  final DateTime date;

  WeightLog({
    required this.id,
    required this.weight,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'weight': weight,
        'date': date.toIso8601String(),
      };

  factory WeightLog.fromJson(Map<String, dynamic> json) => WeightLog(
        id: json['id'] as String,
        weight: (json['weight'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
      );
}

// ==========================================
// 3. FİNANS MODÜLÜ MODELLERİ
// ==========================================

@HiveType(typeId: 6)
class Transaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final bool isIncome; // true: Gelir, false: Gider

  @HiveField(4)
  final String category; // Yemek, Ulaşım, Diğer (Gider) veya Maaş, Diğer (Gelir)

  @HiveField(5)
  final DateTime date;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.category,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'isIncome': isIncome,
        'category': category,
        'date': date.toIso8601String(),
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String,
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        isIncome: json['isIncome'] as bool,
        category: json['category'] as String,
        date: DateTime.parse(json['date'] as String),
      );
}

@HiveType(typeId: 7)
class Debt extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String person;

  @HiveField(2)
  final double amount; // Aylık taksit tutarı

  @HiveField(3)
  final int monthsDuration; // Toplam vade süresi (ay)

  @HiveField(4)
  final DateTime startDate; // Borcun başlangıç tarihi

  @HiveField(5)
  final List<String> paidMonths; // Ödenen ayların listesi (yyyy-MM)

  Debt({
    required this.id,
    required this.person,
    required this.amount,
    required this.monthsDuration,
    required this.startDate,
    List<String>? paidMonths,
  }) : paidMonths = paidMonths ?? const [];

  Debt copyWith({
    String? id,
    String? person,
    double? amount,
    int? monthsDuration,
    DateTime? startDate,
    List<String>? paidMonths,
  }) {
    return Debt(
      id: id ?? this.id,
      person: person ?? this.person,
      amount: amount ?? this.amount,
      monthsDuration: monthsDuration ?? this.monthsDuration,
      startDate: startDate ?? this.startDate,
      paidMonths: paidMonths ?? this.paidMonths,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'person': person,
        'amount': amount,
        'monthsDuration': monthsDuration,
        'startDate': startDate.toIso8601String(),
        'paidMonths': paidMonths,
      };

  factory Debt.fromJson(Map<String, dynamic> json) => Debt(
        id: json['id'] as String,
        person: json['person'] as String,
        amount: (json['amount'] as num).toDouble(),
        monthsDuration: json['monthsDuration'] as int? ?? 1,
        startDate: DateTime.parse(json['startDate'] as String),
        paidMonths: List<String>.from(json['paidMonths'] as List? ?? []),
      );
}
