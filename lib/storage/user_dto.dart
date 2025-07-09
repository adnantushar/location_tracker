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
