enum AccountType { cash, bank, credit, mobile, savings, ewallet }

class AccountModel {
  final String id;
  final String name;
  final AccountType type;
  final String icon;
  final String color;
  double balance;
  final String currency;
  final bool isDefault;
  final DateTime createdAt;

  AccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.balance = 0.0,
    this.currency = 'USD',
    this.isDefault = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'icon': icon,
      'color': color,
      'balance': balance,
      'currency': currency,
      'isDefault': isDefault ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      id: map['id'] as String,
      name: map['name'] as String,
      type: AccountType.values.firstWhere(
        (e) => e.name == map['type'],
      ),
      icon: map['icon'] as String,
      color: map['color'] as String,
      balance: (map['balance'] as num).toDouble(),
      currency: map['currency'] as String,
      isDefault: (map['isDefault'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  AccountModel copyWith({
    String? id,
    String? name,
    AccountType? type,
    String? icon,
    String? color,
    double? balance,
    String? currency,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'AccountModel(id: $id, name: $name, type: ${type.name}, '
        'balance: $balance, currency: $currency)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccountModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
