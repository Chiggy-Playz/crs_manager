import 'package:crs_manager/models/template.dart';

class FieldValue {
  const FieldValue({
    required this.field,
    required this.value,
  });

  final Field field;
  final dynamic value;
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
}
