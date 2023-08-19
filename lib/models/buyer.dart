import 'package:equatable/equatable.dart';

class Buyer extends Equatable {
  Buyer({
    required this.name,
    required this.address,
    required this.gst,
    required this.state,
    required this.alias,
    required this.id,
  });

  String name;
  String address;
  String gst;
  String state;
  String alias;
  int id;

  @override
  List<Object> get props => [name];

  factory Buyer.fromMap(Map<String, dynamic> json) => Buyer(
        name: json["name"],
        address: json["address"],
        gst: json["gst"],
        state: json["state"],
        // id and alias can be missing when the map is from challan model
        id: json["id"] ?? -1,
        alias: json["alias"] ?? "",

      );

  Map<String, dynamic> toMap() => {
        "name": name,
        "address": address,
        "gst": gst,
        "state": state,
        "alias": alias,
        "id": id,
      };
}
