class Transaction {
  final String id;
  String title;
  String description;
  String category;
  String account;
  double amount;
  bool isIncome;
  DateTime dateTime;

  Transaction({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.account,
    required this.amount,
    required this.isIncome,
    required this.dateTime,
  });
}