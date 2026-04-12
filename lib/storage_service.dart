import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'transaction.dart';
import 'category_service.dart';

class StorageService {
  static const String _fileName = 'transactions.json';

  static Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  // Save all transactions to the JSON file
  static Future<void> saveTransactions(List<Transaction> transactions) async {
    final file = await _getFile();
    final List<Map<String, dynamic>> jsonList = transactions.map((t) => {
      'id': t.id,
      'title': t.title,
      'description': t.description,
      'category': t.category,
      'account': t.account,
      'amount': t.amount,
      'isIncome': t.isIncome,
      'dateTime': t.dateTime.toIso8601String(),
    }).toList();

    final jsonString = jsonEncode({'transactions': jsonList});
    await file.writeAsString(jsonString);
  }

  // Load transactions from the JSON file
  static Future<List<Transaction>> loadTransactions() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return [];

      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString);
      final List<dynamic> jsonList = jsonData['transactions'];

      return jsonList.map((item) => Transaction(
        id: item['id'],
        title: item['title'],
        description: item['description'],
        category: item['category'],
        account: item['account'] ?? 'Cash',
        amount: item['amount'].toDouble(),
        isIncome: item['isIncome'],
        dateTime: DateTime.parse(item['dateTime']),
      )).toList();
    } catch (e) {
      return [];
    }
  }

  // Export everything — transactions + categories + accounts
  static Future<String?> exportAll() async {
    try {
      // Load transactions
      final transFile = await _getFile();
      List<dynamic> transactions = [];
      if (await transFile.exists()) {
        final data = jsonDecode(await transFile.readAsString());
        transactions = data['transactions'] ?? [];
      }

      // Load categories and accounts
      final catData = await CategoryService.loadAll();
      final expenseCats = (catData['expense'] as List<CategoryItem>)
          .map((c) => c.toJson())
          .toList();
      final incomeCats = (catData['income'] as List<CategoryItem>)
          .map((c) => c.toJson())
          .toList();
      final accounts = (catData['accounts'] as List<AccountItem>)
          .map((a) => a.toJson())
          .toList();

      // Combine everything into one backup
      final backup = jsonEncode({
        'transactions': transactions,
        'categories': {
          'expense': expenseCats,
          'income': incomeCats,
        },
        'accounts': accounts,
      });

      // Save via file picker
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Backup File',
        fileName: 'money_manager_backup.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: utf8.encode(backup),
      );

      if (savePath != null) return savePath;

      // Fallback to Downloads
      final downloadsDir = Directory('/storage/emulated/0/Download');
      final exportFile = File(
        '${downloadsDir.path}/money_manager_backup.json',
      );
      await exportFile.writeAsString(backup);
      return exportFile.path;
    } catch (e) {
      return null;
    }
  }

  // Import everything — transactions + categories + accounts
  static Future<Map<String, dynamic>?> importAll() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) return null;

    try {
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString);

      // Parse transactions
      final List<dynamic> jsonList = data['transactions'] ?? [];
      final transactions = jsonList.map((item) => Transaction(
        id: item['id'],
        title: item['title'],
        description: item['description'],
        category: item['category'],
        account: item['account'] ?? 'Cash',
        amount: item['amount'].toDouble(),
        isIncome: item['isIncome'],
        dateTime: DateTime.parse(item['dateTime']),
      )).toList();

      // Parse categories
      List<CategoryItem> expenseCats = [];
      List<CategoryItem> incomeCats = [];
      if (data['categories'] != null) {
        expenseCats = (data['categories']['expense'] as List? ?? [])
            .map((c) => CategoryItem.fromJson(c))
            .toList();
        incomeCats = (data['categories']['income'] as List? ?? [])
            .map((c) => CategoryItem.fromJson(c))
            .toList();
      }

      // Parse accounts
      List<AccountItem> accounts = [];
      if (data['accounts'] != null) {
        accounts = (data['accounts'] as List)
            .map((a) => AccountItem.fromJson(a))
            .toList();
      }

      // Save categories and accounts locally
      if (expenseCats.isNotEmpty || incomeCats.isNotEmpty || accounts.isNotEmpty) {
        await CategoryService.saveAll(expenseCats, incomeCats, accounts);
      }

      return {
        'transactions': transactions,
        'expenseCats': expenseCats,
        'incomeCats': incomeCats,
        'accounts': accounts,
      };
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveDarkMode(bool isDark) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/settings.json');
    await file.writeAsString(jsonEncode({'darkMode': isDark}));
  }

  static Future<bool> loadDarkMode() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/settings.json');
      if (!await file.exists()) return false;
      final data = jsonDecode(await file.readAsString());
      return data['darkMode'] ?? false;
    } catch (e) {
      return false;
    }
  }
}