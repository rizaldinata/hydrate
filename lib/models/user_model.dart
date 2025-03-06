class User {
  int? id;
  String name;

  User({this.id, required this.name});

  factory User.fromMap(Map<String, dynamic> map) => User(
        id: map['id'],
        name: map['name'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
      };
}
