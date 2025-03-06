class HydrationLog {
  int? id;
  int userId;
  double amount;
  String timestamp;

  HydrationLog({
    this.id,
    required this.userId,
    required this.amount,
    required this.timestamp,
  });

  factory HydrationLog.fromMap(Map<String, dynamic> map) => HydrationLog(
        id: map['id'],
        userId: map['user_id'],
        amount: map['amount'],
        timestamp: map['timestamp'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'amount': amount,
        'timestamp': timestamp,
      };
}
