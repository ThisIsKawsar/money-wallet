class GoalModel {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String icon;
  final String color;
  final DateTime? deadline;
  final DateTime createdAt;

  GoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.icon,
    required this.color,
    this.deadline,
    required this.createdAt,
  });

  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  bool get isCompleted => currentAmount >= targetAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'icon': icon,
      'color': color,
      'deadline': deadline?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GoalModel.fromMap(Map<String, dynamic> map) {
    return GoalModel(
      id: map['id'] as String,
      name: map['name'] as String,
      targetAmount: (map['targetAmount'] as num).toDouble(),
      currentAmount: (map['currentAmount'] as num).toDouble(),
      icon: map['icon'] as String,
      color: map['color'] as String,
      deadline: map['deadline'] != null
          ? DateTime.parse(map['deadline'] as String)
          : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  GoalModel copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    String? icon,
    String? color,
    DateTime? deadline,
    DateTime? createdAt,
  }) {
    return GoalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'GoalModel(id: $id, name: $name, target: $targetAmount, '
        'current: $currentAmount, progress: ${(progress * 100).toStringAsFixed(1)}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoalModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
