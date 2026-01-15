class User {
  final int id;
  final String username;
  final String name;
  final int clientId;
  final String clientName;

  User({
    required this.id,
    required this.username,
    required this.name,
    required this.clientId,
    required this.clientName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      name: json['name'] as String,
      clientId: json['clientId'] as int,
      clientName: json['client']['companyName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'clientId': clientId,
      'clientName': clientName,
    };
  }
}
