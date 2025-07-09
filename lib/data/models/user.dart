class User {
  final int? id;
  final String fullname;
  final String email;
  final String dob;
  final String koumoku1;
  final String koumoku2;


  User({
    this.id,
    required this.fullname,
    required this.email,
    required this.dob,
    required this.koumoku1,
    required this.koumoku2,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      fullname: json['fullname'] ?? '',
      email: json['email'] ?? '',
      dob: json['dob'] ?? '',
      koumoku1: json['koumoku1'] ?? '',
      koumoku2: json['koumoku2'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "fullname": fullname,
      "email": email,
      "dob": dob,
      "koumoku1": koumoku1,
      "koumoku2": koumoku2,
    };
  }
}
