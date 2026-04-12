import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CategoryItem {
  String name;
  String icon;

  CategoryItem({
    required this.name,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'icon': icon,
  };

  factory CategoryItem.fromJson(Map<String, dynamic> json) => CategoryItem(
    name: json['name'],
    icon: json['icon'],
  );
}

class AccountItem {
  String name;
  String icon;

  AccountItem({
    required this.name,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'icon': icon,
  };

  factory AccountItem.fromJson(Map<String, dynamic> json) => AccountItem(
    name: json['name'],
    icon: json['icon'],
  );
}

class CategoryService {
  static const String _fileName = 'categories.json';

  static final List<CategoryItem> _defaultExpenseCategories = [
    CategoryItem(name: 'Food & Drinks', icon: '🍔'),
    CategoryItem(name: 'Transport', icon: '🚌'),
    CategoryItem(name: 'Shopping', icon: '🛍️'),
    CategoryItem(name: 'Bills & Utilities', icon: '💡'),
    CategoryItem(name: 'Health', icon: '🏥'),
    CategoryItem(name: 'Education', icon: '📚'),
    CategoryItem(name: 'Entertainment', icon: '🎬'),
    CategoryItem(name: 'Other Expense', icon: '💰'),
  ];

  static final List<CategoryItem> _defaultIncomeCategories = [
    CategoryItem(name: 'Salary', icon: '💼'),
    CategoryItem(name: 'Freelance', icon: '💻'),
    CategoryItem(name: 'Business', icon: '🏢'),
    CategoryItem(name: 'Investment', icon: '📈'),
    CategoryItem(name: 'Gift', icon: '🎁'),
    CategoryItem(name: 'Other Income', icon: '💰'),
  ];

  static final List<AccountItem> _defaultAccounts = [
    AccountItem(name: 'Cash', icon: '💵'),
    AccountItem(name: 'Card', icon: '💳'),
    AccountItem(name: 'Bank Account', icon: '🏦'),
  ];

  static Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  static Future<void> saveAll(
      List<CategoryItem> expense,
      List<CategoryItem> income,
      List<AccountItem> accounts,
      ) async {
    final file = await _getFile();
    final data = {
      'expense': expense.map((c) => c.toJson()).toList(),
      'income': income.map((c) => c.toJson()).toList(),
      'accounts': accounts.map((a) => a.toJson()).toList(),
    };
    await file.writeAsString(jsonEncode(data));
  }

  static Future<Map<String, dynamic>> loadAll() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) {
        return {
          'expense': List<CategoryItem>.from(_defaultExpenseCategories),
          'income': List<CategoryItem>.from(_defaultIncomeCategories),
          'accounts': List<AccountItem>.from(_defaultAccounts),
        };
      }

      final raw = await file.readAsString();
      if (raw.isEmpty) {
        return {
          'expense': List<CategoryItem>.from(_defaultExpenseCategories),
          'income': List<CategoryItem>.from(_defaultIncomeCategories),
          'accounts': List<AccountItem>.from(_defaultAccounts),
        };
      }

      final data = jsonDecode(raw);

      final expense = data['expense'] != null
          ? (data['expense'] as List)
          .map((c) => CategoryItem.fromJson(c))
          .toList()
          : List<CategoryItem>.from(_defaultExpenseCategories);

      final income = data['income'] != null
          ? (data['income'] as List)
          .map((c) => CategoryItem.fromJson(c))
          .toList()
          : List<CategoryItem>.from(_defaultIncomeCategories);

      final accounts = data['accounts'] != null
          ? (data['accounts'] as List)
          .map((a) => AccountItem.fromJson(a))
          .toList()
          : List<AccountItem>.from(_defaultAccounts);

      return {
        'expense': expense,
        'income': income,
        'accounts': accounts,
      };
    } catch (e) {
      return {
        'expense': List<CategoryItem>.from(_defaultExpenseCategories),
        'income': List<CategoryItem>.from(_defaultIncomeCategories),
        'accounts': List<AccountItem>.from(_defaultAccounts),
      };
    }
  }
}