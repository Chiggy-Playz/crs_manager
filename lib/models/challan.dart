import 'buyer.dart';

class Challan {
  Challan({
    required this.id,
    required this.number,
    required this.session,
    required this.createdAt,
    required this.buyer,
    required this.products,
    required this.productsValue,
    required this.billNumber,
    required this.deliveredBy,
    required this.vehicleNumber,
    required this.notes,
    required this.received,
    required this.cancelled,
    required this.digitallySigned,
    required this.photoId,
  });

  int id;
  int number;
  String session;
  DateTime createdAt;
  Buyer buyer;
  List<Product> products;
  int productsValue;
  int? billNumber;
  String deliveredBy;
  String vehicleNumber;
  String notes;
  bool received;
  bool cancelled;
  bool digitallySigned;
  String photoId;

  factory Challan.fromMap(Map<String, dynamic> json) => Challan(
        id: json["id"],
        number: json["number"],
        session: json["session"],
        createdAt: DateTime.parse(
          json["created_at"],
        ).toLocal(),
        buyer: Buyer.fromMap(json["buyer"]),
        products:
            List<Product>.from(json["products"].map((x) => Product.fromMap(x))),
        productsValue: json["products_value"],
        billNumber: json["bill_number"],
        deliveredBy: json["delivered_by"],
        vehicleNumber: json["vehicle_number"],
        notes: json["notes"],
        received: json["received"],
        cancelled: json["cancelled"],
        digitallySigned: json["digitally_signed"],
        photoId: json["photo_id"],
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "number": number,
        "session": session,
        "created_at": createdAt.toIso8601String(),
        "buyer": buyer.toMap(),
        "products": List<dynamic>.from(products.map((x) => x.toMap())),
        "products_value": productsValue,
        "bill_number": billNumber,
        "delivered_by": deliveredBy,
        "vehicle_number": vehicleNumber,
        "notes": notes,
        "received": received,
        "cancelled": cancelled,
        "digitally_signed": digitallySigned,
        "photo_id": photoId,
      };
}

class Product {
  Product({
    required this.description,
    required this.quantity,
    required this.quantityUnit,
    required this.serial,
    required this.additionalDescription,
  });

  String description;
  int quantity;
  String quantityUnit;
  String serial;
  String additionalDescription;

  factory Product.fromMap(Map<String, dynamic> json) => Product(
        description: json["description"],
        quantity: json["quantity"],
        // These fields may be missing and are completely optional
        quantityUnit: json["quantity_unit"] ?? "",
        serial: json["serial"] ?? "",
        additionalDescription: json["additional_description"] ?? "",
      );

  Map<String, dynamic> toMap() => {
        "description": description,
        "quantity": quantity,
        "quantityUnit": quantityUnit,
        "serial": serial,
        "additionalDescription": additionalDescription,
      };
}
