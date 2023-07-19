enum ConditionType {
  // Challans containing buyers
  buyers,
  // Challans containing keyword in products
  product,
  // Challan's created at belonging to date range
  date,
  // Challan containing the keyword anywhere
  raw,
  // field key value pair
  fields
}

class Condition<T>{
  ConditionType type;
  T value;

  Condition({required this.type, required this.value});
}

String? conditionTypeToName(ConditionType? type) {
  switch (type) {
    case ConditionType.buyers:
      return "Buyer(s)";
    case ConditionType.product:
      return "Product";
    case ConditionType.date:
      return "Date Range";
    case ConditionType.raw:
      return "Raw";
    case ConditionType.fields:
      return "Fields";
    default:
      return null;
  }
}
