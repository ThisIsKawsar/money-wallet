enum DebtType { owe, owed }

class DebtModel {
  final String id;
  final String name;
  final DebtType type;
  final double amount;
  final double paid;
  final String person;
  final DateTime? dueDate;
  final String? note;

  DebtModel({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    this.paid = 0.0,
    required this.person,
    this.dueDate,
    this.note,
  });

  double get remaining => amount - paid;

  bool get isSettled => paid >= amount;

  double get progress =>
      amount > 0 ? (paid / amount).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'amount': amount,
      'paid': paid,
      'person': person,
      'dueDate': dueDate?.toIso8601String(),
      'note': note,
    };
  }

  factory DebtModel.fromMap(Map<String, dynamic> map) {
    return DebtModel(
      id: map['id'] as String,
      name: map['name'] as String,
      type: DebtType.values.firstWhere(
        (e) => e.name == map['type'],
      ),
      amount: (map['amount'] as num).toDouble(),
      paid: (map['paid'] as num).toDouble(),
      person: map['person'] as String,
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'] as String)
          : null,
      note: map['note'] as String?,
    );
  }

  DebtModel copyWith({
    String? id,
    String? name,
    DebtType? type,
    double? amount,
    double? paid,
    String? person,
    DateTime? dueDate,
    String? note,
  }) {
    return DebtModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      paid: paid ?? this.paid,
      person: person ?? this.person,
      dueDate: dueDate ?? this.dueDate,
      note: note ?? this.note,
    );
  }

  @override
  String toString() {
    return 'DebtModel(id: $id, name: $name, type: ${type.name}, '
        'amount: $amount, paid: $paid, person: $person)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DebtModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
