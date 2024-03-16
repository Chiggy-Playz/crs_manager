import 'package:equatable/equatable.dart';

class Vendor extends Equatable {
  Vendor({
    required this.name,
    required this.address,
    required this.gst,
    required this.codeNumber,
    required this.mobileNumber,
    required this.id,
    this.notes = "",
  });

  String name;
  String address;
  String gst;
  String codeNumber;
  String mobileNumber;
  String notes;
  int id;

  @override
  List<Object> get props => [name];

  factory Vendor.fromMap(Map<String, dynamic> json) => Vendor(
        name: json["name"],
        address: json["address"],
        gst: json["gst"],
        codeNumber: json["code_number"],
        mobileNumber: json["mobile_number"] ?? "",
        // id and alias can be missing when the map is from challan model
        id: json["id"] ?? -1,
      );

  Map<String, dynamic> toMap() => {
        "name": name,
        "address": address,
        "gst": gst,
        "code_number": codeNumber,
        "mobile_number": mobileNumber,
        "id": id,
      };
}
