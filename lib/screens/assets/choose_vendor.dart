import "package:crs_manager/models/vendor.dart";
import "package:crs_manager/providers/database.dart";
import "package:crs_manager/screens/assets/vendor_page.dart";
import "package:crs_manager/utils/constants.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:responsive_sizer/responsive_sizer.dart";

import "../../utils/widgets.dart";

class ChooseVendor extends StatefulWidget {
  const ChooseVendor({
    super.key,
    required this.onVendorSelected,
  });

  final void Function(Vendor) onVendorSelected;

  @override
  State<ChooseVendor> createState() => _ChooseVendorState();
}

class _ChooseVendorState extends State<ChooseVendor> {
  bool sortAscending = true;
  String filter = "";
  var filterController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseModel>(builder: (context, value, child) {
      List<Vendor> vendors = value.vendors
          .where(
            (vendor) =>
                vendor.name.toLowerCase().contains(filter.toLowerCase()) ||
                vendor.address.toLowerCase().contains(filter.toLowerCase()) ||
                vendor.codeNumber.toLowerCase().contains(filter.toLowerCase()),
          )
          .toList()
        ..sort((a, b) {
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });

      return Scaffold(
        appBar: TransparentAppBar(
          title: const Text("Choose Vendor"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              SizedBox(
                height: 10.h,
                child: Row(
                  children: [
                    Expanded(
                        child: TextField(
                      controller: filterController,
                      decoration: InputDecoration(
                        hintText: "Filter by name or address",
                        suffixIcon: filter.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    filter = "";
                                    filterController.clear();
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setState(() {
                          filter = value;
                        });
                      },
                    )),
                    SizedBox(width: 5.w),
                    ActionChip(
                      label: Text(sortAscending ? "Ascending" : "Descending"),
                      avatar: Icon(sortAscending
                          ? Icons.arrow_downward
                          : Icons.arrow_upward),
                      onPressed: () {
                        setState(() {
                          sortAscending = !sortAscending;
                        });
                      },
                    ),
                  ],
                ),
              ),
              vendors.isNotEmpty
                  ? Expanded(
                      child: ListView.builder(
                        itemCount: vendors.length,
                        itemBuilder: (context, index) {
                          Vendor vendor = sortAscending
                              ? vendors[index]
                              : vendors[vendors.length - index - 1];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 6.0, horizontal: 6.0),
                            elevation: 4,
                            child: ListTile(
                              title: Text(vendor.name),
                              subtitle: Text(vendor.address.split("\n")[0]),
                              onTap: () => widget.onVendorSelected(vendor),
                              onLongPress: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => VendorPage(
                                      vendor: vendor,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    )
                  : Expanded(
                      child: Center(
                          child: Column(
                        children: [
                          brokenMagnifyingGlassSvg,
                          SizedBox(height: 2.h),
                          const Text("No vendors found :("),
                        ],
                      )),
                    )
            ],
          ),
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(height: 2.h),
            FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const VendorPage(),
                ));
              },
              child: const Icon(Icons.add),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      );
    });
  }
}
