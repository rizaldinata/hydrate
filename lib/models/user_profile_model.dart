class UserProfile {
  int id;
  int userId;
  String gender;
  double weight;

  UserProfile({
    required this.id,
    required this.userId,
    required this.gender,
    required this.weight,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        id: map['id'],
        userId: map['user_id'],
        gender: map['gender'],
        weight: map['weight'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'gender': gender,
        'weight': weight,
      };
}
