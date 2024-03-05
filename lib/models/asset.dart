import 'dart:convert';

import 'package:crs_manager/models/template.dart';
import 'package:crs_manager/utils/template_string.dart';

import 'challan.dart';

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

class AdditionalCost {
  AdditionalCost({
    required this.amount,
    required this.reason,
    required this.when,
  });

  int amount;
  String reason;
  DateTime when;

  factory AdditionalCost.fromJson(String str) =>
      AdditionalCost.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory AdditionalCost.fromMap(Map<String, dynamic> json) => AdditionalCost(
        amount: json["amount"],
        reason: json["reason"],
        when: DateTime.parse(json["when"]).toLocal(),
      );

  Map<String, dynamic> toMap() => {
        "amount": amount,
        "reason": reason,
        "when": when.toIso8601String(),
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
  List<AdditionalCost> additionalCost;
  String purchasedFrom;
  Template template;
  Map<String, FieldValue> customFields;
  String notes;
  int recoveredCost;

  Map<String, String> get rawCustomFields =>
      Map<String, FieldValue>.from(customFields).map(
        (k, v) => MapEntry<String, String>(
          k,
          v.getValue().toString(),
        ),
      );

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
      additionalCost: List.from(json["additional_cost"])
          .map((e) => AdditionalCost.fromMap(e))
          .toList(),
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
        "additional_cost": additionalCost.map((e) => e.toMap()).toList(),
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

  Map<String, String> convertTemplateStrings() {
    Map<String, String> things = {};
    Map<String, String> fieldsToProcess = Map.from(template.productLink);
    fieldsToProcess["metadata"] = template.metadata;

    fieldsToProcess.forEach((name, value) {
      // If product link is empty, skip. No need to process it.
      if (value.isEmpty) {
        things[name] = '';
        return;
      }

      // For each field in the template, check if the product link contains the field name.
      // If it does, replace it with the default value of the field.
      for (var field in template.fields) {
        if (!value.contains("{${field.name}}")) {
          continue;
        }

        String toReplace = "{${field.name}}";
        String toReplaceWith = "{${field.name}}";

        // If boolean, we check what the value of the field is and replace it with the appropriate value.
        if (field.type == FieldType.checkbox) {
          String key = customFields[field.name]!.value.toString();
          if (field.templates.containsKey(key)) {
            toReplaceWith = field.templates[key]!;
          }
        }

        if (field.type == FieldType.text) {
          if (field.templates.containsKey("empty") &&
              customFields[field.name]!.value.isEmpty) {
            toReplaceWith = field.templates["empty"]!;
          }
        }

        value = value.replaceAll(toReplace, toReplaceWith);
      }
      things[name] = value;
    });
    return things.map<String, String>((key, value) =>
        MapEntry(key, TemplateString(value).format(rawCustomFields)));
  }
}

class AssetHistory {
  int id;
  String assetUuid;
  DateTime when;
  Map<String, dynamic> changes;
  int? challanId;
  ChallanType? challanType;

  AssetHistory({
    required this.id,
    required this.assetUuid,
    required this.when,
    required this.changes,
    this.challanId,
    this.challanType,
  });

  factory AssetHistory.fromJson(String str) =>
      AssetHistory.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory AssetHistory.fromMap(Map<String, dynamic> json) => AssetHistory(
        id: json["id"],
        assetUuid: json["asset_uuid"],
        when: DateTime.parse(json["when"]).toLocal(),
        changes: json["changes"],
        challanId: json["challan_id"],
        challanType: json["challan_type"] == null
            ? null
            : ChallanType.values[json["challan_type"]],
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "asset_uuid": assetUuid,
        "when": when.toIso8601String(),
        "changes": changes,
        "challan_id": challanId,
        "challan_type": challanType!.index,
      };
}
