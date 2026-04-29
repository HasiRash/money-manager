import 'package:flutter/material.dart';
import 'transaction.dart';
import 'add_transaction.dart';
import 'category_service.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String categoryName;
  final String categoryIcon;
  final bool isIncome;
  final List<Transaction> transactions;
  final List<CategoryItem> expenseCategories;
  final List<CategoryItem> incomeCategories;
  final List<AccountItem> accounts;

  const CategoryDetailScreen({
    super.key,
    required this.categoryName,
    required this.categoryIcon,
    required this.isIncome,
    required this.transactions,
    required this.expenseCategories,
    required this.incomeCategories,
    required this.accounts,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  late List<Transaction> _transactions;

  @override
  void initState() {
    super.initState();
    _transactions = List.from(widget.transactions);
    _sortTransactions();
  }

  void _sortTransactions() {
    _transactions.sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  double get _total =>
      _transactions.fold(0.0, (sum, t) => sum + t.amount);

  String _formatAmount(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
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

  String _formatDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
        ? 12
        : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  void _openEdit(Transaction t) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(
          existingTransaction: t,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (result == 'delete') {
          _transactions.removeWhere((tx) => tx.id == t.id);
        } else {
          final index = _transactions.indexWhere((tx) => tx.id == t.id);
          if (index != -1) {
            _transactions[index] = result;
          }
        }
        _sortTransactions();
      });

      // Pass result back to summary screen
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isIncome ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.categoryIcon,
                style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              widget.categoryName,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: color,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Total banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: color,
            child: Column(
              children: [
                Text(
                  widget.isIncome ? 'Total Income' : 'Total Expense',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'LKR ${_formatAmount(_total)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_transactions.length} transaction${_transactions.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          // Transaction list
          Expanded(
            child: _transactions.isEmpty
                ? const Center(
              child: Text('No transactions',
                  style: TextStyle(color: Colors.grey)),
            )
                : ListView.builder(
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final t = _transactions[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: widget.isIncome
                        ? Colors.green[100]
                        : Colors.red[100],
                    child: Text(
                      widget.categoryIcon,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  title: t.description.isNotEmpty
                      ? Text(t.description)
                      : Text(t.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.account,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                      Text(
                        '${_formatDate(t.dateTime)}  ${_formatTime(t.dateTime)}',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: Text(
                    '${widget.isIncome ? '+' : '-'}LKR ${_formatAmount(t.amount)}',
                    style: TextStyle(
                      color: widget.isIncome
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () => _openEdit(t),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}