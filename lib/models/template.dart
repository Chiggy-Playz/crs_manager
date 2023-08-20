import 'dart:convert';

import 'package:equatable/equatable.dart';

enum FieldType { text, number, datetime, checkbox }

class Field {
  Field({
    required this.name,
    required this.type,
    required this.required,
  });

  String name;
  FieldType type;
  bool required;

  factory Field.fromJson(String str) => Field.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Field.fromMap(Map<String, dynamic> json) => Field(
        name: json["name"],
        type: FieldType.values
            .firstWhere((element) => element.name == json["type"]),
        required: json["required"],
      );

  Map<String, dynamic> toMap() => {
        "name": name,
        "type": type.name,
        "required": required,
      };
}

class Template extends Equatable {
  Template({
    required this.id,
    required this.name,
    required this.fields,
    required this.productLink,
    required this.metadata,
  });

  int id;
  String name;
  List<Field> fields;
  // Product part -> field part
  Map<String, String> productLink;
  String metadata;

  @override
  List<Object?> get props => [
        id,
        name,
      ];

  factory Template.fromJson(String str) => Template.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Template.fromMap(Map<String, dynamic> json) => Template(
        id: json["id"],
        name: json["name"],
        fields: List<Field>.from(json["fields"].map((x) => Field.fromMap(x))),
        productLink: Map.from(json["product_link"]),
        metadata: json["metadata"],
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "name": name,
        "fields": List<dynamic>.from(fields.map((x) => x.toMap())),
        "product_link": productLink,
        "metadata": metadata,
      };
}
