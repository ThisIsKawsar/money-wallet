class ReminderModel {
  final String id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final bool isRecurring;
  final String? recurringFrequency;
  final bool isPaid;
  final String? categoryId;

  ReminderModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    this.isRecurring = false,
    this.recurringFrequency,
    this.isPaid = false,
    this.categoryId,
  });

  bool get isOverdue => !isPaid && dueDate.isBefore(DateTime.now());

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'isRecurring': isRecurring ? 1 : 0,
      'recurringFrequency': recurringFrequency,
      'isPaid': isPaid ? 1 : 0,
      'categoryId': categoryId,
    };
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    return ReminderModel(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      dueDate: DateTime.parse(map['dueDate'] as String),
      isRecurring: (map['isRecurring'] as int) == 1,
      recurringFrequency: map['recurringFrequency'] as String?,
      isPaid: (map['isPaid'] as int) == 1,
      categoryId: map['categoryId'] as String?,
    );
  }

  ReminderModel copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? dueDate,
    bool? isRecurring,
    String? recurringFrequency,
    bool? isPaid,
    String? categoryId,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
      isPaid: isPaid ?? this.isPaid,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  @override
  String toString() {
    return 'ReminderModel(id: $id, title: $title, amount: $amount, '
        'dueDate: $dueDate, isPaid: $isPaid)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReminderModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
