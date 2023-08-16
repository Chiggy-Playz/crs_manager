import 'dart:convert';

import 'package:crs_manager/models/template.dart';

class FieldValue {
  FieldValue({
    required this.field,
    required this.value,
  }) {
    if (value is String && field.type == FieldType.datetime) {
      value = DateTime.parse(
        value,
      ).toLocal();
    } else {
      value = value;
    }
  }

  Field field;
  dynamic value;

  dynamic getValue() {
    return value is DateTime
        ? (value as DateTime).toUtc().toIso8601String()
        : value;
  }
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

  factory Asset.fromMap(Map<String, dynamic> json) {
    Template template = Template.fromMap(json["template"]);

    return Asset(
      id: json["id"],
      uuid: json["uuid"],
      createdAt: DateTime.parse(json["created_at"]).toLocal(),
      location: json["location"],
      purchaseCost: json["purchase_cost"],
      purchaseDate: DateTime.parse(json["purchase_date"]).toLocal(),
      additionalCost: json["additional_cost"],
      purchasedFrom: json["purchased_from"],
      template: template,
      customFields: Map.from(json["custom_fields"]).map(
        (fieldName, fieldValue) => MapEntry<String, FieldValue>(
          fieldName,
          FieldValue(
            field: template.fields
                .where((element) => fieldName == element.name)
                .first,
            value: fieldValue,
          ),
        ),
      ),
      notes: json["notes"],
      recoveredCost: json["recovered_cost"],
    );
  }

  Map<String, dynamic> toMap() => {
        "id": id,
        "uuid": uuid,
        "created_at": createdAt.toIso8601String(),
        "location": location,
        "purchase_cost": purchaseCost,
        "purchase_date": purchaseDate.toIso8601String(),
        "additional_cost": additionalCost,
        "purchased_from": purchasedFrom,
        "template": template.id,
        "custom_fields": Map.from(customFields).map(
          (k, v) => MapEntry<String, dynamic>(
            k,
            v.getValue(),
          ),
        ),
        "notes": notes,
        "recovered_cost": recoveredCost,
      };
}

class AssetHistory {
  int id;
  int assetId;
  DateTime when;
  Map<String, dynamic> changes;

  AssetHistory({
    required this.id,
    required this.assetId,
    required this.when,
    required this.changes,
  });

  factory AssetHistory.fromJson(String str) =>
      AssetHistory.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory AssetHistory.fromMap(Map<String, dynamic> json) => AssetHistory(
        id: json["id"],
        assetId: json["asset_id"],
        when: DateTime.parse(json["when"]).toLocal(),
        changes: json["changes"],
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "asset_id": assetId,
        "when": when.toIso8601String(),
        "changes": changes,
      };
}
