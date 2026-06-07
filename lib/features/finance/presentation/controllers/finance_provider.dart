import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../../core/database/hive_models.dart';

class FinanceState {
  final List<Transaction> transactions;
  final List<Debt> debts;
  final String selectedCategoryFilter; // 'Tümü', 'Yemek', 'Ulaşım', 'Diğer'
  final DateTime selectedMonth; // Seçilen ay (Örn. 2026-06-01)

  FinanceState({
    required this.transactions,
    required this.debts,
    this.selectedCategoryFilter = 'Tümü',
    required this.selectedMonth,
  });

  // Seçilen aya ait işlemler
  List<Transaction> get monthlyTransactions {
    return transactions.where((t) {
      return t.date.year == selectedMonth.year &&
          t.date.month == selectedMonth.month;
    }).toList();
  }

  double get totalIncome => monthlyTransactions
      .where((t) => t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense => monthlyTransactions
      .where((t) => !t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get netBalance => totalIncome - totalExpense;

  List<Transaction> get filteredTransactions {
    // Tarihe göre tersten sıralıyoruz (en yeni en üstte)
    final list = List<Transaction>.from(monthlyTransactions)
      ..sort((a, b) => b.date.compareTo(a.date));
      
    if (selectedCategoryFilter == 'Tümü') {
      return list;
    }
    return list.where((t) => t.category == selectedCategoryFilter).toList();
  }

  // Seçilen ayda aktif olan borçlar
  List<Debt> get activeDebts {
    return debts.where((d) {
      final startMonth = DateTime(d.startDate.year, d.startDate.month, 1);
      // Toplam taksit süresi boyunca aktif
      final endMonth = DateTime(startMonth.year, startMonth.month + d.monthsDuration, 1);
      return !selectedMonth.isBefore(startMonth) && selectedMonth.isBefore(endMonth);
    }).toList();
  }

  FinanceState copyWith({
    List<Transaction>? transactions,
    List<Debt>? debts,
    String? selectedCategoryFilter,
    DateTime? selectedMonth,
  }) {
    return FinanceState(
      transactions: transactions ?? this.transactions,
      debts: debts ?? this.debts,
      selectedCategoryFilter: selectedCategoryFilter ?? this.selectedCategoryFilter,
      selectedMonth: selectedMonth ?? this.selectedMonth,
    );
  }
}

class FinanceNotifier extends StateNotifier<FinanceState> {
  FinanceNotifier() : super(FinanceState(
    transactions: [],
    debts: [],
    selectedMonth: DateTime(DateTime.now().year, DateTime.now().month, 1),
  ));

  late final Box<Transaction> _transactionBox;
  late final Box<Debt> _debtBox;

  void init() {
    _transactionBox = Hive.box<Transaction>('finance_transactions');
    _debtBox = Hive.box<Debt>('finance_debts');
    loadData();
  }

  void loadData() {
    final transactions = _transactionBox.values.toList();
    final debts = _debtBox.values.toList();

    state = state.copyWith(
      transactions: transactions,
      debts: debts,
    );
  }

  void changeSelectedMonth(DateTime month) {
    state = state.copyWith(selectedMonth: DateTime(month.year, month.month, 1));
  }

  Future<void> addTransaction(
      String title, double amount, bool isIncome, String category, {DateTime? customDate}) async {
    final date = customDate ?? (state.selectedMonth.year == DateTime.now().year && state.selectedMonth.month == DateTime.now().month
        ? DateTime.now()
        : DateTime(state.selectedMonth.year, state.selectedMonth.month, 15));
    
    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.isEmpty ? (isIncome ? 'Gelir' : 'Gider') : title,
      amount: amount,
      isIncome: isIncome,
      category: category,
      date: date,
    );
    await _transactionBox.add(transaction);
    loadData();
  }

  Future<void> deleteTransaction(String id) async {
    final index = _transactionBox.values.toList().indexWhere((t) => t.id == id);
    if (index != -1) {
      await _transactionBox.deleteAt(index);
      loadData();
    }
  }

  Future<void> addDebt(
      String person, double amount, int monthsDuration, DateTime startDate) async {
    final debt = Debt(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      person: person.isEmpty ? 'Bilinmeyen Kişi' : person,
      amount: amount,
      monthsDuration: monthsDuration,
      startDate: DateTime(startDate.year, startDate.month, 1), // Ayın 1'i olarak kaydedelim
      paidMonths: [],
    );
    await _debtBox.add(debt);
    loadData();
  }

  Future<void> toggleDebtPaidForMonth(String id, String monthKey) async {
    final index = _debtBox.values.toList().indexWhere((d) => d.id == id);
    if (index != -1) {
      final existing = _debtBox.getAt(index)!;
      final completedList = List<String>.from(existing.paidMonths);
      
      if (completedList.contains(monthKey)) {
        completedList.remove(monthKey);
      } else {
        completedList.add(monthKey);
      }

      final updated = existing.copyWith(paidMonths: completedList);
      await _debtBox.putAt(index, updated);
      loadData();
    }
  }

  Future<void> deleteDebt(String id) async {
    final index = _debtBox.values.toList().indexWhere((d) => d.id == id);
    if (index != -1) {
      await _debtBox.deleteAt(index);
      loadData();
    }
  }

  void changeCategoryFilter(String category) {
    state = state.copyWith(selectedCategoryFilter: category);
  }
}

final financeProvider =
    StateNotifierProvider<FinanceNotifier, FinanceState>((ref) {
  return FinanceNotifier()..init();
});
