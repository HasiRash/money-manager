import 'package:flutter/material.dart';
import 'add_transaction.dart';
import 'transaction.dart';
import 'summary_screen.dart';
import 'storage_service.dart';
import 'splash_screen.dart';
import 'category_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadDarkMode();
  }

  void _loadDarkMode() async {
    final isDark = await StorageService.loadDarkMode();
    setState(() => _isDarkMode = isDark);
  }

  void toggleDarkMode() {
    setState(() => _isDarkMode = !_isDarkMode);
    StorageService.saveDarkMode(_isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Money Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _currentIndex = 0;
  List<Transaction> _transactions = [];
  List<CategoryItem> _expenseCategories = [];
  List<CategoryItem> _incomeCategories = [];
  List<AccountItem> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final transactions = await StorageService.loadTransactions();
    final catData = await CategoryService.loadAll();
    setState(() {
      _transactions = transactions;
      _transactions.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      _expenseCategories = catData['expense']!;
      _incomeCategories = catData['income']!;
      _accounts = catData['accounts']!;
      _isLoading = false;
    });
  }

  void _openAddTransaction({Transaction? existing}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(
          existingTransaction: existing,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (result == 'delete') {
          _transactions.removeWhere((t) => t.id == existing!.id);
        } else if (existing != null) {
          final index = _transactions.indexWhere((t) => t.id == existing.id);
          _transactions[index] = result;
        } else {
          _transactions.add(result);
        }
        _transactions.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      });
      await StorageService.saveTransactions(_transactions);
    }
  }

  void _deleteTransaction(String id) async {
    setState(() {
      _transactions.removeWhere((t) => t.id == id);
    });
    await StorageService.saveTransactions(_transactions);
  }

  void _exportData() async {
    final path = await StorageService.exportAll();
    if (mounted) {
      if (path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup saved successfully! ✅'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _importData() async {
    final result = await StorageService.importAll();
    if (result != null) {
      final transactions = result['transactions'] as List<Transaction>;
      final catData = await CategoryService.loadAll();
      setState(() {
        _transactions = transactions;
        _transactions.sort((a, b) => b.dateTime.compareTo(a.dateTime));
        _expenseCategories = catData['expense']!;
        _incomeCategories = catData['income']!;
        _accounts = catData['accounts']!;
      });
      await StorageService.saveTransactions(_transactions);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data imported successfully! ✅'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Import failed. Please select a valid backup file.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
      );
    }

    return Scaffold(
      body: _currentIndex == 0
          ? HomeScreen(
        transactions: _transactions,
        onAdd: _openAddTransaction,
        onDelete: _deleteTransaction,
        onExport: _exportData,
        onImport: _importData,
        expenseCategories: _expenseCategories,
        incomeCategories: _incomeCategories,
        accounts: _accounts,
      )
          : SummaryScreen(
        transactions: _transactions,
        expenseCategories: _expenseCategories,
        incomeCategories: _incomeCategories,
        accounts: _accounts,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.green[700],
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Summary',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final List<Transaction> transactions;
  final Function({Transaction? existing}) onAdd;
  final Function(String) onDelete;
  final Function() onExport;
  final Function() onImport;
  final List<CategoryItem> expenseCategories;
  final List<CategoryItem> incomeCategories;
  final List<AccountItem> accounts;

  const HomeScreen({
    super.key,
    required this.transactions,
    required this.onAdd,
    required this.onDelete,
    required this.onExport,
    required this.onImport,
    required this.expenseCategories,
    required this.incomeCategories,
    required this.accounts,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  String _filterType = 'all'; // all, income, expense
  String _filterAccount = 'all';
  String _filterCategory = 'all';
  bool _showFilters = false;
  final _searchController = TextEditingController();

  List<Transaction> get _filtered {
    return widget.transactions.where((t) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesDesc = t.description.toLowerCase().contains(query);
        final matchesCat = t.title.toLowerCase().contains(query);
        if (!matchesDesc && !matchesCat) return false;
      }

      // Income/Expense filter
      if (_filterType == 'income' && !t.isIncome) return false;
      if (_filterType == 'expense' && t.isIncome) return false;

      // Account filter
      if (_filterAccount != 'all' && t.account != _filterAccount) return false;

      // Category filter
      if (_filterCategory != 'all' && t.title != _filterCategory) return false;

      return true;
    }).toList();
  }

  Map<String, List<Transaction>> _groupByDate(List<Transaction> transactions) {
    Map<String, List<Transaction>> grouped = {};
    for (var t in transactions) {
      final key = '${t.dateTime.year}-${t.dateTime.month}-${t.dateTime.day}';
      if (grouped[key] == null) grouped[key] = [];
      grouped[key]!.add(t);
    }
    return grouped;
  }

  String _formatDateHeader(String key) {
    final parts = key.split('-');
    final date = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
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

  String _getCategoryIcon(String category) {
    final allCats = [
      ...widget.expenseCategories,
      ...widget.incomeCategories,
    ];
    final match = allCats.where((c) => c.name == category);
    if (match.isNotEmpty) return match.first.icon;
    return '💰';
  }

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

  bool get _hasActiveFilters =>
      _filterType != 'all' ||
          _filterAccount != 'all' ||
          _filterCategory != 'all';

  void _clearFilters() {
    setState(() {
      _filterType = 'all';
      _filterAccount = 'all';
      _filterCategory = 'all';
      _searchQuery = '';
      _searchController.clear();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final grouped = _groupByDate(filtered);
    final dateKeys = grouped.keys.toList();

    final allCategories = [
      ...widget.expenseCategories,
      ...widget.incomeCategories,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Money Manager',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _hasActiveFilters ? Colors.yellow : Colors.white,
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'import') widget.onImport();
              if (value == 'export') widget.onExport();
              if (value == 'darkmode') {
                MyApp.of(context)?.toggleDarkMode();
              }
            },
            itemBuilder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return [
                PopupMenuItem(
                  value: 'darkmode',
                  child: Row(
                    children: [
                      Icon(
                        isDark ? Icons.light_mode : Icons.dark_mode,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 12),
                      Text(isDark ? 'Light Mode' : 'Dark Mode'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'import',
                  child: Row(
                    children: [
                      Icon(Icons.upload_file, color: Colors.green),
                      SizedBox(width: 12),
                      Text('Import Data'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.download, color: Colors.green),
                      SizedBox(width: 12),
                      Text('Export Data'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                  }),
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Filters panel
          if (_showFilters) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Income/Expense toggle
                  Row(
                    children: [
                      _filterChip('All', 'all', _filterType, (v) =>
                          setState(() => _filterType = v)),
                      const SizedBox(width: 8),
                      _filterChip('💚 Income', 'income', _filterType, (v) =>
                          setState(() => _filterType = v)),
                      const SizedBox(width: 8),
                      _filterChip('❤️ Expense', 'expense', _filterType, (v) =>
                          setState(() => _filterType = v)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Account filter
                  Row(
                    children: [
                      const Text('Account: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _filterAccount,
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem(
                                value: 'all', child: Text('All Accounts')),
                            ...widget.accounts.map((a) => DropdownMenuItem(
                              value: a.name,
                              child: Text('${a.icon} ${a.name}'),
                            )),
                          ],
                          onChanged: (val) =>
                              setState(() => _filterAccount = val!),
                        ),
                      ),
                    ],
                  ),

                  // Category filter
                  Row(
                    children: [
                      const Text('Category: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _filterCategory,
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem(
                                value: 'all', child: Text('All Categories')),
                            ...allCategories.map((c) => DropdownMenuItem(
                              value: c.name,
                              child: Text('${c.icon} ${c.name}'),
                            )),
                          ],
                          onChanged: (val) =>
                              setState(() => _filterCategory = val!),
                        ),
                      ),
                    ],
                  ),

                  // Clear filters
                  if (_hasActiveFilters)
                    TextButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.clear_all, color: Colors.red),
                      label: const Text('Clear Filters',
                          style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],

          // Results count when filtering
          if (_searchQuery.isNotEmpty || _hasActiveFilters)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filtered.length} transaction${filtered.length == 1 ? '' : 's'} found',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear',
                        style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),

          // Transaction list
          Expanded(
            child: filtered.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _searchQuery.isNotEmpty || _hasActiveFilters
                        ? '🔍'
                        : '💰',
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _searchQuery.isNotEmpty || _hasActiveFilters
                        ? 'No transactions match your search'
                        : 'No transactions yet',
                    style: const TextStyle(
                        fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _searchQuery.isNotEmpty || _hasActiveFilters
                        ? 'Try different search terms'
                        : 'Tap + to add your first one!',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: dateKeys.length,
              itemBuilder: (context, index) {
                final key = dateKeys[index];
                final dayTransactions = grouped[key]!;
                final dayTotal = dayTransactions.fold(
                  0.0,
                      (sum, t) =>
                  sum + (t.isIncome ? t.amount : -t.amount),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                      const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDateHeader(key),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '${dayTotal >= 0 ? '+' : ''}LKR ${_formatAmount(dayTotal.abs())}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: dayTotal >= 0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...dayTransactions.map(
                          (t) => Dismissible(
                        key: Key(t.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete,
                              color: Colors.white),
                        ),
                        onDismissed: (_) => widget.onDelete(t.id),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: t.isIncome
                                ? Colors.green[100]
                                : Colors.red[100],
                            child: Text(
                              _getCategoryIcon(t.title),
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          title: Text(
                            t.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              if (t.description.isNotEmpty)
                                Text(t.description),
                              Text(
                                t.account,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${t.isIncome ? '+' : '-'}LKR ${_formatAmount(t.amount)}',
                                style: TextStyle(
                                  color: t.isIncome
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _formatTime(t.dateTime),
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                          onTap: () => widget.onAdd(existing: t),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => widget.onAdd(),
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _filterChip(
      String label,
      String value,
      String currentValue,
      Function(String) onTap,
      ) {
    final isSelected = currentValue == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[700] : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight:
            isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}