import 'dart:convert';

import 'buyer.dart';
import 'challan.dart';


class InwardChallan extends ChallanBase {
  String receivedBy;

  InwardChallan({
    required int id,
    required int number,
    required String session,
    required DateTime createdAt,
    required Buyer buyer,
    required List<Product> products,
    required int productsValue,
    notes = "",
    required this.receivedBy,
    required String vehicleNumber,
    required bool cancelled,
  }) : super(
          id: id,
          number: number,
          session: session,
          createdAt: createdAt,
          buyer: buyer,
          products: products,
          productsValue: productsValue,
          notes: notes,
          vehicleNumber: vehicleNumber,
          cancelled: cancelled,
        );

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
