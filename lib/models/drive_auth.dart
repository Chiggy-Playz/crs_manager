class Token {
  String accessToken;
  int expiresIn;

  DateTime _createdAt = DateTime.now();

  Token({
    required this.accessToken,
    required this.expiresIn,
  });

  get isExpired {
    return _createdAt
        .add(Duration(seconds: expiresIn))
        .isBefore(DateTime.now());
  }
}

class File {
  String id;
  String name;
  String mimeType;
  String? parentId;

  File({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.parentId,
  });

  factory File.fromMap(Map<String, dynamic> json) => File(
        id: json["id"],
        name: json["name"],
        mimeType: json["mimeType"],
        parentId: json["parents"]?[0],
      );

}
