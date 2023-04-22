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

class DriveFile {
  String id;
  String name;
  String mimeType;
  String? parentId;

  DriveFile({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.parentId,
  });

  factory DriveFile.fromMap(Map<String, dynamic> json) => DriveFile(
        id: json["id"],
        name: json["name"],
        mimeType: json["mimeType"],
        parentId: json["parents"]?[0],
      );
}
