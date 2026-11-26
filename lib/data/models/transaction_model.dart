enum TransactionType { income, expense, transfer }

class TransactionModel {
  final String id;
  final TransactionType type;
  final double amount;
  final String categoryId;
  final String accountId;
  final String? toAccountId;
  final DateTime date;
  final String? note;
  final String? paymentMethod;
  final String? attachmentPath;
  final bool isRecurring;
  final String? recurringFrequency;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.accountId,
    this.toAccountId,
    required this.date,
    this.note,
    this.paymentMethod,
    this.attachmentPath,
    this.isRecurring = false,
    this.recurringFrequency,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'amount': amount,
      'categoryId': categoryId,
      'accountId': accountId,
      'toAccountId': toAccountId,
      'date': date.toIso8601String(),
      'note': note,
      'paymentMethod': paymentMethod,
      'attachmentPath': attachmentPath,
      'isRecurring': isRecurring ? 1 : 0,
      'recurringFrequency': recurringFrequency,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
      ),
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['categoryId'] as String,
      accountId: map['accountId'] as String,
      toAccountId: map['toAccountId'] as String?,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      paymentMethod: map['paymentMethod'] as String?,
      attachmentPath: map['attachmentPath'] as String?,
      isRecurring: map['isRecurring'] == 1 || map['isRecurring'] == true,
      recurringFrequency: map['recurringFrequency'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  TransactionModel copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    String? categoryId,
    String? accountId,
    String? toAccountId,
    DateTime? date,
    String? note,
    String? paymentMethod,
    String? attachmentPath,
    bool? isRecurring,
    String? recurringFrequency,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      date: date ?? this.date,
      note: note ?? this.note,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, type: ${type.name}, amount: $amount, '
        'categoryId: $categoryId, accountId: $accountId, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
