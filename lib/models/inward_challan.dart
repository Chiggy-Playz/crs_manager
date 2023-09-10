import 'dart:convert';

import 'buyer.dart';
import 'challan.dart';

class InwardChallan {
  int id;
  int number;
  String session;
  DateTime createdAt;
  Buyer buyer;
  List<Product> products;
  int productsValue;
  String notes;
  String receivedBy;
  String vehicleNumber;
  bool cancelled;

  InwardChallan({
    required this.id,
    required this.number,
    required this.session,
    required this.createdAt,
    required this.buyer,
    required this.products,
    required this.productsValue,
    this.notes = "",
    required this.receivedBy,
    required this.vehicleNumber,
    required this.cancelled,
  });

  factory InwardChallan.fromJson(String str) =>
      InwardChallan.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory InwardChallan.fromMap(Map<String, dynamic> json) => InwardChallan(
        id: json["id"],
        number: json["number"],
        session: json["session"],
        createdAt: DateTime.parse(json["created_at"]).toLocal(),
        buyer: Buyer.fromMap(json["buyer"]),
        products:
            List<Product>.from(json["products"].map((x) => Product.fromMap(x))),
        productsValue: json["products_value"],
        notes: json["notes"],
        receivedBy: json["received_by"],
        vehicleNumber: json["vehicle_number"],
        cancelled: json["cancelled"],
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "number": number,
        "session": session,
        "created_at": createdAt.toIso8601String(),
        "buyer": buyer.toMap(),
        "products": List<dynamic>.from(products.map((x) => x.toMap())),
        "products_value": productsValue,
        "notes": notes,
        "received_by": receivedBy,
        "vehicle_number": vehicleNumber,
        "cancelled": cancelled,
      };
}
