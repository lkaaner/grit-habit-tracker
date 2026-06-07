import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Divider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/hive_models.dart';
import '../../../../core/widgets/settings_modal.dart';
import '../controllers/finance_provider.dart';

class FinancePage extends ConsumerStatefulWidget {
  const FinancePage({super.key});

  @override
  ConsumerState<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends ConsumerState<FinancePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _personController = TextEditingController();
  final TextEditingController _monthsController = TextEditingController();

  bool _isIncome = false;
  String _selectedCategory = 'Yemek'; // Yemek, Ulaşım, Diğer (Gider) veya Maaş, Diğer (Gelir)
  DateTime _debtStartDate = DateTime.now();

  void _showSettings(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => const SettingsModal(),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _personController.dispose();
    _monthsController.dispose();
    super.dispose();
  }

  String _formatMonthName(DateTime date) {
    final months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatTurkishCurrency(double amount) {
    final isNegative = amount < 0;
    final absVal = amount.abs();
    final formatted = absVal.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '${isNegative ? '-' : ''}$formatted TL';
  }

  void _showAddTransactionModal() {
    _titleController.clear();
    _amountController.clear();
    _isIncome = false;
    _selectedCategory = 'Yemek';

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, setModalState) {
          final categories = _isIncome 
              ? {'Maaş': 'Maaş', 'Diğer': 'Diğer'}
              : {'Yemek': 'Yemek', 'Ulaşım': 'Ulaşım', 'Diğer': 'Diğer'};

          if (!categories.containsKey(_selectedCategory)) {
            _selectedCategory = categories.keys.first;
          }

          return CupertinoActionSheet(
            title: const Text('Yeni İşlem Ekle'),
            message: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                children: [
                  CupertinoSegmentedControl<bool>(
                    groupValue: _isIncome,
                    children: const {
                      false: Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Gider')),
                      true: Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Gelir')),
                    },
                    onValueChanged: (value) {
                      setModalState(() {
                        _isIncome = value;
                        _selectedCategory = value ? 'Maaş' : 'Yemek';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: _titleController,
                    placeholder: 'Açıklama (örn: Market, Kira)...',
                    decoration: BoxDecoration(
                      color: const Color(0xFF16171D),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: _amountController,
                    placeholder: 'Tutar (TL)...',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16171D),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Kategori Seçin:',
                      style: TextStyle(fontSize: 12, color: const Color(0xFF9EA0A5))),
                  const SizedBox(height: 6),
                  CupertinoSegmentedControl<String>(
                    groupValue: _selectedCategory,
                    children: categories.map((key, val) => MapEntry(
                      key,
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: Text(val, style: const TextStyle(fontSize: 12)),
                      ),
                    )),
                    onValueChanged: (value) {
                      setModalState(() {
                        _selectedCategory = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: <CupertinoActionSheetAction>[
              CupertinoActionSheetAction(
                isDefaultAction: true,
                onPressed: () {
                  final amount = double.tryParse(_amountController.text) ?? 0.0;
                  final title = _titleController.text.trim();
                  if (amount > 0) {
                    ref.read(financeProvider.notifier).addTransaction(
                          title,
                          amount,
                          _isIncome,
                          _selectedCategory,
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
          );
        },
      ),
    );
  }

  void _showAddDebtModal() {
    _personController.clear();
    _amountController.clear();
    _monthsController.text = '12';
    _debtStartDate = DateTime.now();

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, setModalState) => CupertinoActionSheet(
          title: const Text('Yeni Taksitli Borç Ekle'),
          message: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              children: [
                CupertinoTextField(
                  controller: _personController,
                  placeholder: 'Borç veren kişi veya kurum...',
                  decoration: BoxDecoration(
                    color: const Color(0xFF16171D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: _amountController,
                  placeholder: 'Aylık Taksit Tutarı (TL)...',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16171D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: _monthsController,
                  placeholder: 'Vade (Kaç Ay? Örn: 6)...',
                  keyboardType: TextInputType.number,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16171D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Başlangıç Ayı Seçin:',
                    style: TextStyle(fontSize: 12, color: const Color(0xFF9EA0A5))),
                const SizedBox(height: 6),
                SizedBox(
                  height: 100,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: _debtStartDate,
                    onDateTimeChanged: (date) {
                      _debtStartDate = date;
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: <CupertinoActionSheetAction>[
            CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () {
                final amount = double.tryParse(_amountController.text) ?? 0.0;
                final person = _personController.text.trim();
                final months = int.tryParse(_monthsController.text) ?? 1;
                if (amount > 0 && person.isNotEmpty) {
                  ref.read(financeProvider.notifier).addDebt(
                        person,
                        amount,
                        months,
                        _debtStartDate,
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
      ),
    );
  }

  void _showAddSelector() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Finansal Kayıt Ekle'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showAddTransactionModal();
            },
            child: const Text('Gelir/Gider Ekle'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showAddDebtModal();
            },
            child: const Text('Taksitli Borç Ekle'),
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

  Map<String, double> _getCategoryExpenses(List<Transaction> transactions) {
    final Map<String, double> map = {'Yemek': 0.0, 'Ulaşım': 0.0, 'Diğer': 0.0};
    for (var tx in transactions) {
      if (!tx.isIncome) {
        final cat = map.containsKey(tx.category) ? tx.category : 'Diğer';
        map[cat] = (map[cat] ?? 0.0) + tx.amount;
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financeProvider);
    final notifier = ref.read(financeProvider.notifier);
    final isNegativeBalance = state.netBalance < 0;

    final expensesMap = _getCategoryExpenses(state.monthlyTransactions);
    final totalExpenses = expensesMap.values.fold(0.0, (sum, val) => sum + val);

    final String monthKey = "${state.selectedMonth.year}-${state.selectedMonth.month.toString().padLeft(2, '0')}";

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
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showAddSelector,
              child: const Icon(CupertinoIcons.add_circled, size: 24),
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
                    // ==========================================
                    // 1. AYLIK TAKVİM/AY DEĞİŞTİRİCİ
                    // ==========================================
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF090A0F),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              final prevMonth = DateTime(state.selectedMonth.year, state.selectedMonth.month - 1, 1);
                              notifier.changeSelectedMonth(prevMonth);
                            },
                            child: const Icon(CupertinoIcons.left_chevron),
                          ),
                          Text(
                            _formatMonthName(state.selectedMonth),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CupertinoColors.white),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              final nextMonth = DateTime(state.selectedMonth.year, state.selectedMonth.month + 1, 1);
                              notifier.changeSelectedMonth(nextMonth);
                            },
                            child: const Icon(CupertinoIcons.right_chevron),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ==========================================
                    // 2. REAKTİF BAKİYE KARTI
                    // ==========================================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16171D),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatTurkishCurrency(state.netBalance),
                            style: TextStyle(
                              color: isNegativeBalance
                                  ? const Color(0xFFEB5757) // Red
                                  : const Color(0xFF27AE60), // Green
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text(
                                    'Gelir',
                                    style: TextStyle(
                                      color: Color(0xFF9EA0A5),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatTurkishCurrency(state.totalIncome),
                                    style: const TextStyle(
                                      color: Color(0xFF27AE60),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  const Text(
                                    'Gider',
                                    style: TextStyle(
                                      color: Color(0xFF9EA0A5),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatTurkishCurrency(state.totalExpense),
                                    style: const TextStyle(
                                      color: Color(0xFFEB5757),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ==========================================
                    // 3. GİDER ANALİZİ & PASTA GRAFİK
                    // ==========================================
                    const Text(
                      'Gider Analizi',
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
                            color: CupertinoColors.systemGrey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Custom Paint Pie Chart
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: CustomPaint(
                              painter: ExpensePieChartPainter(expenses: expensesMap),
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Legends
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLegendItem('Yemek', expensesMap['Yemek'] ?? 0, totalExpenses, CupertinoColors.activeBlue),
                                const SizedBox(height: 8),
                                _buildLegendItem('Ulaşım', expensesMap['Ulaşım'] ?? 0, totalExpenses, CupertinoColors.systemOrange),
                                const SizedBox(height: 8),
                                _buildLegendItem('Diğer', expensesMap['Diğer'] ?? 0, totalExpenses, CupertinoColors.systemPurple),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ==========================================
                    // 4. İŞLEMLER LİSTESİ
                    // ==========================================
                    const Text(
                      'İşlemler',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    state.filteredTransactions.isEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            alignment: Alignment.center,
                            child: const Text('Bu ay henüz işlem eklenmedi.',
                                style: TextStyle(color: const Color(0xFF9EA0A5))),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF16171D),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: CupertinoColors.systemGrey.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: state.filteredTransactions.length,
                              separatorBuilder: (context, index) => const Divider(
                                height: 1,
                                color: CupertinoColors.separator,
                              ),
                              itemBuilder: (context, index) {
                                final tx = state.filteredTransactions[index];
                                final sign = tx.isIncome ? '+' : '-';
                                final amountColor = tx.isIncome
                                    ? CupertinoColors.activeGreen
                                    : CupertinoColors.destructiveRed;

                                return Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      Icon(
                                        tx.isIncome
                                            ? CupertinoIcons.arrow_down_right_circle_fill
                                            : CupertinoIcons.arrow_up_left_circle_fill,
                                        color: tx.isIncome ? CupertinoColors.activeGreen : CupertinoColors.destructiveRed,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(tx.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                            const SizedBox(height: 2),
                                            Text(tx.category, style: const TextStyle(fontSize: 12, color: const Color(0xFF9EA0A5))),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '$sign${_formatTurkishCurrency(tx.amount)}',
                                            style: TextStyle(
                                                color: amountColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${tx.date.day.toString().padLeft(2, '0')}/${tx.date.month.toString().padLeft(2, '0')}',
                                            style: const TextStyle(fontSize: 10, color: const Color(0xFF9EA0A5)),
                                          )
                                        ],
                                      ),
                                      const SizedBox(width: 6),
                                      CupertinoButton(
                                        padding: EdgeInsets.zero,
                                        onPressed: () {
                                          notifier.deleteTransaction(tx.id);
                                        },
                                        child: const Icon(
                                          CupertinoIcons.trash,
                                          color: CupertinoColors.destructiveRed,
                                          size: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                    const SizedBox(height: 24),

                    // ==========================================
                    // 5. TAKSİTLİ BORÇLAR LİSTESİ
                    // ==========================================
                    const Text(
                      'Borçlar',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    state.activeDebts.isEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            alignment: Alignment.center,
                            child: const Text('Bu ay aktif taksitli borç bulunmuyor.',
                                style: TextStyle(color: const Color(0xFF9EA0A5))),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF16171D),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: CupertinoColors.systemGrey.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: state.activeDebts.length,
                              separatorBuilder: (context, index) => const Divider(
                                height: 1,
                                color: CupertinoColors.separator,
                              ),
                              itemBuilder: (context, index) {
                                final debt = state.activeDebts[index];
                                final isPaidForThisMonth = debt.paidMonths.contains(monthKey);

                                // Hangi taksitte olduğunu hesaplayalım
                                final monthsDiff = (state.selectedMonth.year - debt.startDate.year) * 12 + (state.selectedMonth.month - debt.startDate.month) + 1;

                                return Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          notifier.toggleDebtPaidForMonth(debt.id, monthKey);
                                        },
                                        child: Icon(
                                          isPaidForThisMonth
                                              ? CupertinoIcons.checkmark_circle_fill
                                              : CupertinoIcons.circle,
                                          color: isPaidForThisMonth
                                              ? CupertinoColors.activeGreen
                                              : CupertinoColors.inactiveGray,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              debt.person,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                decoration: isPaidForThisMonth
                                                    ? TextDecoration.lineThrough
                                                    : TextDecoration.none,
                                                color: isPaidForThisMonth
                                                    ? const Color(0xFF9EA0A5)
                                                    : CupertinoColors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Taksit: $monthsDiff / ${debt.monthsDuration} ay',
                                              style: const TextStyle(fontSize: 12, color: const Color(0xFF9EA0A5)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            _formatTurkishCurrency(debt.amount),
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              decoration: isPaidForThisMonth ? TextDecoration.lineThrough : TextDecoration.none,
                                              color: isPaidForThisMonth ? const Color(0xFF9EA0A5) : CupertinoColors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            isPaidForThisMonth ? 'Ödendi' : 'Ödenmedi',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isPaidForThisMonth ? CupertinoColors.activeGreen : CupertinoColors.destructiveRed,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 6),
                                      CupertinoButton(
                                        padding: EdgeInsets.zero,
                                        onPressed: () {
                                          notifier.deleteDebt(debt.id);
                                        },
                                        child: const Icon(
                                          CupertinoIcons.trash,
                                          color: CupertinoColors.destructiveRed,
                                          size: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
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

  Widget _buildLegendItem(String title, double amount, double total, Color color) {
    final double percent = total > 0 ? (amount / total) * 100 : 0.0;
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 13, color: CupertinoColors.white),
          ),
        ),
        Text(
          '${_formatTurkishCurrency(amount)} (${percent.toStringAsFixed(0)}%)',
          style: const TextStyle(fontSize: 12, color: const Color(0xFF9EA0A5), fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// =========================================================================
// CUSTOM EXPENSE PIE CHART PAINTER
// =========================================================================
class ExpensePieChartPainter extends CustomPainter {
  final Map<String, double> expenses;

  ExpensePieChartPainter({required this.expenses});

  @override
  void paint(Canvas canvas, Size size) {
    final double total = expenses.values.fold(0.0, (sum, val) => sum + val);
    final double radius = size.height / 2;
    final center = Offset(size.width / 2, size.height / 2);

    if (total == 0) {
      final paint = Paint()
        ..color = CupertinoColors.systemGrey5
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, paint);

      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'Kayıt Yok',
          style: TextStyle(color: const Color(0xFF9EA0A5), fontSize: 12, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
      );
      return;
    }

    final List<Color> colors = [
      CupertinoColors.activeBlue,
      CupertinoColors.systemOrange,
      CupertinoColors.systemPurple,
    ];

    double startAngle = -math.pi / 2;
    int colorIdx = 0;

    final categories = ['Yemek', 'Ulaşım', 'Diğer'];

    for (var cat in categories) {
      final amount = expenses[cat] ?? 0.0;
      if (amount <= 0) continue;

      final sweepAngle = (amount / total) * 2 * math.pi;
      final paint = Paint()
        ..color = colors[colorIdx % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
      colorIdx++;
    }
  }

  @override
  bool shouldRepaint(covariant ExpensePieChartPainter oldDelegate) {
    return oldDelegate.expenses != expenses;
  }
}
