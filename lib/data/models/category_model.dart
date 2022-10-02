enum CategoryType { income, expense }

class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final String color;
  final CategoryType type;
  final bool isCustom;
  final double? budgetAmount;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.isCustom = false,
    this.budgetAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'type': type.name,
      'isCustom': isCustom ? 1 : 0,
      'budgetAmount': budgetAmount,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String,
      color: map['color'] as String,
      type: CategoryType.values.firstWhere(
        (e) => e.name == map['type'],
      ),
      isCustom: (map['isCustom'] as int) == 1,
      budgetAmount: map['budgetAmount'] != null
          ? (map['budgetAmount'] as num).toDouble()
          : null,
    );
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    CategoryType? type,
    bool? isCustom,
    double? budgetAmount,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      isCustom: isCustom ?? this.isCustom,
      budgetAmount: budgetAmount ?? this.budgetAmount,
    );
  }

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name, type: ${type.name}, '
        'icon: $icon, color: $color)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
