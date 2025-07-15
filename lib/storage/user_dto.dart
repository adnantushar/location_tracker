class UserDto {
  final int userid;

  UserDto({required this.userid});

  Map<String, dynamic> toJson() {
    return {'userid': userid};
  }

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(userid: json['userid']);
  }
}
class UserModel {
  final int userId;
  final String email;
  final String fullname;
  final String? token;

  UserModel({
    required this.userId,
    required this.email,
    required this.fullname,
    this.token,
  });

  factory UserModel.fromStorage({
    required int userId,
    required String email,
    required String fullname,
    String? token,
  }) {
    return UserModel(
      userId: userId,
      email: email,
      fullname: fullname,
      token: token,
    );
  }
}
