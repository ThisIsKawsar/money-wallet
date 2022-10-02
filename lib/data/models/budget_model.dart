enum BudgetPeriod { weekly, monthly, yearly }

class BudgetModel {
  final String id;
  final String? categoryId;
  final double amount;
  final BudgetPeriod period;
  final DateTime startDate;

  BudgetModel({
    required this.id,
    this.categoryId,
    required this.amount,
    required this.period,
    required this.startDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'amount': amount,
      'period': period.name,
      'startDate': startDate.toIso8601String(),
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as String,
      categoryId: map['categoryId'] as String?,
      amount: (map['amount'] as num).toDouble(),
      period: BudgetPeriod.values.firstWhere(
        (e) => e.name == map['period'],
      ),
      startDate: DateTime.parse(map['startDate'] as String),
    );
  }

  BudgetModel copyWith({
    String? id,
    String? categoryId,
    double? amount,
    BudgetPeriod? period,
    DateTime? startDate,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
    );
  }

  @override
  String toString() {
    return 'BudgetModel(id: $id, categoryId: $categoryId, amount: $amount, '
        'period: ${period.name}, startDate: $startDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BudgetModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
