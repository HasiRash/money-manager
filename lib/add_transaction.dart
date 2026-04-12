import 'package:flutter/material.dart';
import 'transaction.dart';
import 'category_service.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? existingTransaction;

  const AddTransactionScreen({super.key, this.existingTransaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  bool _isIncome = false;
  String _selectedCategory = '';
  String _selectedAccount = '';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  List<CategoryItem> _expenseCategories = [];
  List<CategoryItem> _incomeCategories = [];
  List<AccountItem> _accounts = [];
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() async {
    final data = await CategoryService.loadAll();
    setState(() {
      _expenseCategories = data['expense']!;
      _incomeCategories = data['income']!;
      _accounts = data['accounts']!;
      _loadingCategories = false;

      if (widget.existingTransaction != null) {
        final t = widget.existingTransaction!;
        _descriptionController.text = t.description;
        _amountController.text = t.amount.toString();
        _isIncome = t.isIncome;
        _selectedCategory = t.title;
        _selectedAccount = t.account;
        _selectedDate = t.dateTime;
        _selectedTime = TimeOfDay.fromDateTime(t.dateTime);
      } else {
        _selectedCategory = _expenseCategories.isNotEmpty
            ? _expenseCategories[0].name
            : '';
        _selectedAccount =
        _accounts.isNotEmpty ? _accounts[0].name : '';
      }
    });
  }

  List<CategoryItem> get _currentCategories =>
      _isIncome ? _incomeCategories : _expenseCategories;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // ── Category helpers ──────────────────────────────────────────

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final iconController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: iconController,
              decoration: const InputDecoration(
                labelText: 'Icon (emoji)',
                hintText: 'e.g. 🎮',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g. Gaming',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final newCat = CategoryItem(
                  name: nameController.text,
                  icon: iconController.text.isNotEmpty
                      ? iconController.text
                      : '💰',
                );
                setState(() {
                  if (_isIncome) {
                    _incomeCategories.add(newCat);
                  } else {
                    _expenseCategories.add(newCat);
                  }
                  _selectedCategory = newCat.name;
                });
                await CategoryService.saveAll(
                    _expenseCategories, _incomeCategories, _accounts);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(CategoryItem cat) {
    final nameController = TextEditingController(text: cat.name);
    final iconController = TextEditingController(text: cat.icon);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: iconController,
              decoration: const InputDecoration(
                labelText: 'Icon (emoji)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  cat.name = nameController.text;
                  cat.icon = iconController.text.isNotEmpty
                      ? iconController.text
                      : cat.icon;
                });
                await CategoryService.saveAll(
                    _expenseCategories, _incomeCategories, _accounts);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryDialog(CategoryItem cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete "${cat.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              setState(() {
                if (_isIncome) {
                  _incomeCategories.remove(cat);
                } else {
                  _expenseCategories.remove(cat);
                }
                if (_selectedCategory == cat.name) {
                  _selectedCategory = _currentCategories.isNotEmpty
                      ? _currentCategories[0].name
                      : '';
                }
              });
              await CategoryService.saveAll(
                  _expenseCategories, _incomeCategories, _accounts);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  void _showManageCategories() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final cats = _isIncome ? _incomeCategories : _expenseCategories;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isIncome
                          ? 'Manage Income Categories'
                          : 'Manage Expense Categories',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                ...cats.map((cat) => ListTile(
                  leading: Text(cat.icon,
                      style: const TextStyle(fontSize: 22)),
                  title: Text(cat.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit,
                            size: 20, color: Colors.green),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showEditCategoryDialog(cat);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            size: 20, color: Colors.red),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showDeleteCategoryDialog(cat);
                        },
                      ),
                    ],
                  ),
                )),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.add, color: Colors.green[700]),
                  title: Text('Add New Category',
                      style: TextStyle(color: Colors.green[700])),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAddCategoryDialog();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showManageAccounts() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Manage Accounts',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                ..._accounts.map((acc) => ListTile(
                  leading: Text(acc.icon,
                      style: const TextStyle(fontSize: 22)),
                  title: Text(acc.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit,
                            size: 20, color: Colors.green),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showEditAccountDialog(acc);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            size: 20, color: Colors.red),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showDeleteAccountDialog(acc);
                        },
                      ),
                    ],
                  ),
                )),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.add, color: Colors.green[700]),
                  title: Text('Add New Account',
                      style: TextStyle(color: Colors.green[700])),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAddAccountDialog();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
  // ── Account helpers ───────────────────────────────────────────

  void _showAddAccountDialog() {
    final nameController = TextEditingController();
    final iconController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: iconController,
              decoration: const InputDecoration(
                labelText: 'Icon (emoji)',
                hintText: 'e.g. 💰',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Account Name',
                hintText: 'e.g. Savings',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final newAcc = AccountItem(
                  name: nameController.text,
                  icon: iconController.text.isNotEmpty
                      ? iconController.text
                      : _isIncome ? '💵' : '💰',
                );
                setState(() {
                  _accounts.add(newAcc);
                  _selectedAccount = newAcc.name;
                });
                await CategoryService.saveAll(
                    _expenseCategories, _incomeCategories, _accounts);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditAccountDialog(AccountItem acc) {
    final nameController = TextEditingController(text: acc.name);
    final iconController = TextEditingController(text: acc.icon);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: iconController,
              decoration: const InputDecoration(
                labelText: 'Icon (emoji)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Account Name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  acc.name = nameController.text;
                  acc.icon = iconController.text.isNotEmpty
                      ? iconController.text
                      : acc.icon;
                });
                await CategoryService.saveAll(
                    _expenseCategories, _incomeCategories, _accounts);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(AccountItem acc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text('Delete "${acc.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              setState(() {
                _accounts.remove(acc);
                if (_selectedAccount == acc.name) {
                  _selectedAccount =
                  _accounts.isNotEmpty ? _accounts[0].name : '';
                }
              });
              await CategoryService.saveAll(
                  _expenseCategories, _incomeCategories, _accounts);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── Save ──────────────────────────────────────────────────────

  void _save() {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    final double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final finalDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final transaction = Transaction(
      id: widget.existingTransaction?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _selectedCategory,
      description: _descriptionController.text,
      category: _isIncome ? 'Income' : 'Expense',
      account: _selectedAccount,
      amount: amount,
      isIncome: _isIncome,
      dateTime: finalDateTime,
    );

    Navigator.pop(context, transaction);
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingTransaction != null
            ? 'Edit Transaction'
            : 'Add Transaction'),
        backgroundColor: _isIncome ? Colors.green : Colors.red,
        foregroundColor: Colors.white,
        actions: [
          if (widget.existingTransaction != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Transaction'),
                    content: const Text(
                        'Are you sure you want to delete this transaction?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.pop(context, 'delete');
                        },
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _loadingCategories
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Income / Expense toggle
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _isIncome = false;
                      _selectedCategory =
                      _expenseCategories.isNotEmpty
                          ? _expenseCategories[0].name
                          : '';
                    }),
                    child: Container(
                      padding:
                      const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isIncome
                            ? Colors.red
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Expense',
                          style: TextStyle(
                            color: !_isIncome
                                ? Colors.white
                                : Colors.black,
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
                      _isIncome = true;
                      _selectedCategory =
                      _incomeCategories.isNotEmpty
                          ? _incomeCategories[0].name
                          : '';
                    }),
                    child: Container(
                      padding:
                      const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isIncome
                            ? Colors.green
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Income',
                          style: TextStyle(
                            color: _isIncome
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Category
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Category',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () => _showManageCategories(),
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('Manage',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategory.isEmpty ? null : _selectedCategory,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: _currentCategories.map((cat) {
                return DropdownMenuItem(
                  value: cat.name,
                  child: Row(
                    children: [
                      Text(cat.icon),
                      const SizedBox(width: 8),
                      Text(cat.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedCategory = val);
                }
              },
            ),
            const SizedBox(height: 20),

            // Account
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Account',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () => _showManageAccounts(),
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('Manage',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedAccount.isEmpty ? null : _selectedAccount,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: _accounts.map((acc) {
                return DropdownMenuItem(
                  value: acc.name,
                  child: Row(
                    children: [
                      Text(acc.icon),
                      const SizedBox(width: 8),
                      Text(acc.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedAccount = val);
                }
              },
            ),
            const SizedBox(height: 20),

            // Description
            const Text('Description (optional)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'e.g. Lunch at cafe with friends',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            // Amount
            const Text('Amount (LKR)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                    child: const Text(
                      'LKR',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey[300]),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: '0.00',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Date and Time
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 18),
                          const SizedBox(width: 8),
                          Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickTime,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 18),
                          const SizedBox(width: 8),
                          Text(_selectedTime.format(context)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  _isIncome ? Colors.green : Colors.red,
                  padding:
                  const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Transaction',
                  style: TextStyle(
                      color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}