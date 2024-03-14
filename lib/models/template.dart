import 'dart:convert';

import 'package:equatable/equatable.dart';

enum FieldType { text, number, datetime, checkbox }

class Field {
  Field({
    required this.name,
    required this.type,
    required this.required,
    required this.templates,
    required this.defaultValue,
  });

  String name;
  FieldType type;
  bool required;
  Map<String, String> templates;
  dynamic defaultValue;

  factory Field.fromJson(String str) => Field.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Field.fromMap(Map<String, dynamic> json) {
    FieldType type =
        FieldType.values.firstWhere((element) => element.name == json["type"]);

    dynamic defaultValue = json["default_value"];

    if (type == FieldType.datetime && defaultValue != null) {
      defaultValue = DateTime.parse(json["default_value"]);
    }

    return Field(
      name: json["name"],
      type: type,
      required: json["required"],
      templates: Map<String, String>.from(json["templates"]),
      defaultValue: defaultValue,
    );
  }

  Map<String, dynamic> toMap() => {
        "name": name,
        "type": type.name,
        "required": required,
        "templates": templates,
        "default_value": defaultValue == null
            ? null
            : (type == FieldType.datetime
                ? (defaultValue as DateTime).toIso8601String()
                : defaultValue),
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
