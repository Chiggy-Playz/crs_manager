import 'package:crs_manager/providers/database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../models/buyer.dart';

typedef VoidBCallback = void Function(Buyer buyer);
final Widget brokenMagnifyingGlassSvg = SvgPicture.asset(
  "assets/images/broken_magnifying_glass.svg",
  semanticsLabel: "Broken Magnifying Glass",
);

class BuyersList extends StatefulWidget {
  final VoidBCallback onBuyerSelected;
  const BuyersList({super.key, required this.onBuyerSelected});

  @override
  State<BuyersList> createState() => _BuyersListState();
}

class _BuyersListState extends State<BuyersList> {
  bool sortAscending = true;
  String filter = "";
  var filterController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseModel>(
      builder: (context, value, child) {
        List<Buyer> buyers = value.buyers
            .where(
              (buyer) =>
                  buyer.name.toLowerCase().contains(filter.toLowerCase()) ||
                  buyer.address.toLowerCase().contains(filter.toLowerCase()),
            )
            .toList();

        return Padding(
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
              buyers.isNotEmpty
                  ? Expanded(
                      child: ListView.builder(
                        itemCount: buyers.length,
                        itemBuilder: (context, index) {
                          Buyer buyer = sortAscending
                              ? buyers[index]
                              : buyers[buyers.length - index - 1];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 6.0, horizontal: 6.0),
                            elevation: 4,
                            child: ListTile(
                              title: Text(buyer.name),
                              subtitle: Text(buyer.address.split("\n")[0]),
                              onTap: () => widget.onBuyerSelected(buyer),
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
                          const Text("No buyers found :("),
                        ],
                      )),
                    )
            ],
          ),
        );
      },
    );
  }
}
