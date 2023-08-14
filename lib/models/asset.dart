import 'dart:convert';

import 'package:crs_manager/models/template.dart';
import 'package:equatable/equatable.dart';

class FieldValue {
  const FieldValue({
    required this.field,
    required this.value,
  });

  final Field field;
  final dynamic value;

  factory FieldValue.fromJson(String str) =>
      FieldValue.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory FieldValue.fromMap(Map<String, dynamic> json) {
    var field = Field.fromMap(json["field"]);
    return FieldValue(
      field: field,
      value: field.type != FieldType.datetime ? json["value"] : DateTime.parse(json["value"]),
    );
  }

  Map<String, dynamic> toMap() => {
        "field": field.toMap(),
        "value": value is DateTime
            ? (value as DateTime).toUtc().toIso8601String()
            : value,
      };
}

class Asset {
  Asset({
    required this.id,
    required this.uuid,
    required this.createdAt,
    required this.location,
    required this.purchaseCost,
    required this.purchaseDate,
    required this.additionalCost,
    required this.purchasedFrom,
    required this.template,
    required this.customFields,
    required this.notes,
    required this.recoveredCost,
  });

  int id;
  String uuid;
  DateTime createdAt;
  String location;
  int purchaseCost;
  DateTime purchaseDate;
  int additionalCost;
  String purchasedFrom;
  Template template;
  Map<String, FieldValue> customFields;
  String notes;
  int recoveredCost;

  factory Asset.fromJson(String str) => Asset.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Asset.fromMap(Map<String, dynamic> json) => Asset(
        id: json["id"],
        uuid: json["uuid"],
        createdAt: DateTime.parse(json["created_at"]),
        location: json["location"],
        purchaseCost: json["purchase_cost"],
        purchaseDate: DateTime.parse(json["purchase_date"]),
        additionalCost: json["additional_cost"],
        purchasedFrom: json["purchased_from"],
        template: Template.fromMap(json["template"]),
        customFields: Map.from(json["custom_fields"]).map(
          (k, v) => MapEntry<String, FieldValue>(
            k,
            FieldValue.fromMap(
              Map<String, dynamic>.from(v),
            ),
          ),
        ),
        notes: json["notes"],
        recoveredCost: json["recovered_cost"],
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "uuid": uuid,
        "created_at": createdAt.toIso8601String(),
        "location": location,
        "purchase_cost": purchaseCost,
        "purchase_date": purchaseDate.toIso8601String(),
        "additional_cost": additionalCost,
        "purchased_from": purchasedFrom,
        "template": template.toMap(),
        "custom_fields": Map.from(customFields).map(
          (k, v) => MapEntry<String, dynamic>(
            k,
            v.toMap(),
          ),
        ),
        "notes": notes,
        "recovered_cost": recoveredCost,
      };
}
