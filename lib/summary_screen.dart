import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'transaction.dart';
import 'category_service.dart';
import 'category_detail_screen.dart';

class SummaryScreen extends StatefulWidget {
  final List<Transaction> transactions;
  final List<CategoryItem> expenseCategories;
  final List<CategoryItem> incomeCategories;
  final List<AccountItem> accounts;

  const SummaryScreen({
    super.key,
    required this.transactions,
    required this.expenseCategories,
    required this.incomeCategories,
    required this.accounts,
  });

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  String _filterMode = 'month';
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  bool _showingIncome = false;
  int _touchedIndex = -1;

  List<Transaction> get _filtered {
    switch (_filterMode) {
      case 'day':
        return widget.transactions.where((t) {
          return t.dateTime.year == _selectedDay.year &&
              t.dateTime.month == _selectedDay.month &&
              t.dateTime.day == _selectedDay.day;
        }).toList();
      case 'range':
        if (_rangeStart == null || _rangeEnd == null) return [];
        final end = DateTime(
          _rangeEnd!.year, _rangeEnd!.month, _rangeEnd!.day, 23, 59, 59,
        );
        return widget.transactions.where((t) {
          return t.dateTime.isAfter(
              _rangeStart!.subtract(const Duration(seconds: 1))) &&
              t.dateTime.isBefore(end.add(const Duration(seconds: 1)));
        }).toList();
      default:
        return widget.transactions.where((t) {
          return t.dateTime.year == _selectedMonth.year &&
              t.dateTime.month == _selectedMonth.month;
        }).toList();
    }
  }

  double get _totalIncome => _filtered
      .where((t) => t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _totalExpense => _filtered
      .where((t) => !t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  Map<String, double> get _categoryTotals {
    final relevant = _filtered.where((t) => t.isIncome == _showingIncome);
    Map<String, double> totals = {};
    for (var t in relevant) {
      totals[t.title] = (totals[t.title] ?? 0) + t.amount;
    }
    return totals;
  }

  Map<String, double> get _accountTotals {
    Map<String, double> totals = {};
    for (var t in _filtered) {
      final amount = t.isIncome ? t.amount : -t.amount;
      totals[t.account] = (totals[t.account] ?? 0) + amount;
    }
    return totals;
  }

  String _getCategoryIcon(String categoryName) {
    final allCats = [
      ...widget.expenseCategories,
      ...widget.incomeCategories,
    ];
    final match = allCats.where((c) => c.name == categoryName);
    if (match.isNotEmpty) return match.first.icon;
    return '💰';
  }

  String _getAccountIcon(String accountName) {
    final match = widget.accounts.where((a) => a.name == accountName);
    if (match.isNotEmpty) return match.first.icon;
    return '💰';
  }

  void _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDay = picked);
  }

  void _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _rangeStart != null && _rangeEnd != null
          ? DateTimeRange(start: _rangeStart!, end: _rangeEnd!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _rangeStart = picked.start;
        _rangeEnd = picked.end;
      });
    }
  }

  String _formatMonth(DateTime dt) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dt.month]} ${dt.year}';
  }

  String _formatDay(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  String _formatAmount(double amount) {
    final parts = amount.abs().toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final buffer = StringBuffer();
    int count = 0;
    for (int i = intPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write(',');
      buffer.write(intPart[i]);
      count++;
    }
    return '${buffer.toString().split('').reversed.join()}.$decPart';
  }

  Widget _filterChip(String label, String mode) {
    final isSelected = _filterMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _filterMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.green[600],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.green[700] : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildDateNavigator() {
    if (_filterMode == 'day') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() =>
            _selectedDay = _selectedDay.subtract(const Duration(days: 1))),
          ),
          GestureDetector(
            onTap: _pickDay,
            child: Text(
              _formatDay(_selectedDay),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() =>
            _selectedDay = _selectedDay.add(const Duration(days: 1))),
          ),
        ],
      );
    }

    if (_filterMode == 'range') {
      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _rangeStart ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _rangeStart = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Start Date',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          _rangeStart == null
                              ? 'Pick date'
                              : _formatDay(_rangeStart!),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _rangeStart == null
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('→',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _rangeEnd ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _rangeEnd = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('End Date',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          _rangeEnd == null
                              ? 'Pick date'
                              : _formatDay(_rangeEnd!),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _rangeEnd == null
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => setState(() => _selectedMonth =
              DateTime(_selectedMonth.year, _selectedMonth.month - 1)),
        ),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedMonth,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setState(() =>
              _selectedMonth = DateTime(picked.year, picked.month));
            }
          },
          child: Text(
            _formatMonth(_selectedMonth),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => setState(() => _selectedMonth =
              DateTime(_selectedMonth.year, _selectedMonth.month + 1)),
        ),
      ],
    );
  }

  Widget _buildPieChart(Map<String, double> totals) {
    if (totals.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('No data for this period',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final colors = [
      Colors.blue, Colors.orange, Colors.purple, Colors.teal,
      Colors.pink, Colors.amber, Colors.cyan, Colors.indigo,
    ];

    final entries = totals.entries.toList();
    final total = totals.values.fold(0.0, (a, b) => a + b);

    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (event, response) {
              setState(() {
                if (response == null || response.touchedSection == null) {
                  _touchedIndex = -1;
                } else {
                  _touchedIndex =
                      response.touchedSection!.touchedSectionIndex;
                }
              });
            },
          ),
          sections: List.generate(entries.length, (i) {
            final isTouched = i == _touchedIndex;
            final percentage = (entries[i].value / total * 100);
            return PieChartSectionData(
              color: colors[i % colors.length],
              value: entries[i].value,
              title: '${percentage.toStringAsFixed(1)}%',
              radius: isTouched ? 80 : 65,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }),
          centerSpaceRadius: 40,
          sectionsSpace: 2,
        ),
      ),
    );
  }

  Widget _buildCategoryList(Map<String, double> totals) {
    if (totals.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No transactions found',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final total = totals.values.fold(0.0, (a, b) => a + b);
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = [
      Colors.blue, Colors.orange, Colors.purple, Colors.teal,
      Colors.pink, Colors.amber, Colors.cyan, Colors.indigo,
    ];

    return Column(
      children: List.generate(sorted.length, (i) {
        final entry = sorted[i];
        final percentage = entry.value / total;

        return GestureDetector(
          onTap: () async {
            final catTransactions = _filtered
                .where((t) =>
            t.title == entry.key &&
                t.isIncome == _showingIncome)
                .toList();

            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CategoryDetailScreen(
                  categoryName: entry.key,
                  categoryIcon: _getCategoryIcon(entry.key),
                  isIncome: _showingIncome,
                  transactions: catTransactions,
                  expenseCategories: widget.expenseCategories,
                  incomeCategories: widget.incomeCategories,
                  accounts: widget.accounts,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(_getCategoryIcon(entry.key),
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(entry.key,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'LKR ${_formatAmount(entry.value)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _showingIncome
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        Text(
                          '${(percentage * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Colors.grey[200],
                    color: colors[i % colors.length],
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAccountBreakdown() {
    final totals = _accountTotals;
    if (totals.isEmpty) return const SizedBox.shrink();

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Account Summary',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        ...sorted.map((entry) {
          final isPositive = entry.value >= 0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(_getAccountIcon(entry.key),
                        style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Text(entry.key,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                Text(
                  '${isPositive ? '+' : '-'}LKR ${_formatAmount(entry.value)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          );
        }),
        const Divider(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final totals = _categoryTotals;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Summary',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Colors.green[700],
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  _filterChip('📅 Day', 'day'),
                  const SizedBox(width: 8),
                  _filterChip('🗓 Month', 'month'),
                  const SizedBox(width: 8),
                  _filterChip('📆 Range', 'range'),
                ],
              ),
            ),
            Container(
              color: Theme.of(context).cardColor,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: _buildDateNavigator(),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[400]!),
                      ),
                      child: Column(
                        children: [
                          const Text('Income',
                              style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            'LKR ${_formatAmount(_totalIncome)}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[400]!),
                      ),
                      child: Column(
                        children: [
                          const Text('Expenses',
                              style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            'LKR ${_formatAmount(_totalExpense)}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[400]!),
                      ),
                      child: Column(
                        children: [
                          const Text('Balance',
                              style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            'LKR ${_formatAmount(_totalIncome - _totalExpense)}',
                            style: TextStyle(
                              color: (_totalIncome - _totalExpense) >= 0
                                  ? Colors.blue
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Account breakdown
            _buildAccountBreakdown(),

            // Income / Expense toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _showingIncome = false;
                        _touchedIndex = -1;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_showingIncome ? Colors.red : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '❤️ Expenses',
                            style: TextStyle(
                              color: !_showingIncome ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _showingIncome = true;
                        _touchedIndex = -1;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _showingIncome ? Colors.green : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '💚 Income',
                            style: TextStyle(
                              color: _showingIncome ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            _buildPieChart(totals),
            const SizedBox(height: 8),
            _buildCategoryList(totals),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}