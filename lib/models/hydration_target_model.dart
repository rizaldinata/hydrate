class HydrationTarget {
  int id;
  int userId;
  double target;
  String date;

  HydrationTarget({
    required this.id,
    required this.userId,
    required this.target,
    required this.date,
  });

  factory HydrationTarget.fromMap(Map<String, dynamic> map) => HydrationTarget(
        id: map['id'],
        userId: map['user_id'],
        target: map['target'],
        date: map['date'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'target': target,
        'date': date,
      };
}
