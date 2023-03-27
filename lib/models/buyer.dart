class Buyer {
    Buyer({
        required this.name,
        required this.address,
        required this.gst,
        required this.state,
        required this.id,
    });

    String name;
    String address;
    String gst;
    String state;
    int id;

    factory Buyer.fromMap(Map<String, dynamic> json) => Buyer(
        name: json["name"],
        address: json["address"],
        gst: json["gst"],
        state: json["state"],
        // id can be missing when the map is from challan model
        id: json["id"] ?? -1,
    );

    Map<String, dynamic> toMap() => {
        "name": name,
        "address": address,
        "gst": gst,
        "state": state,
        "id": id,
    };
}
