import 'package:crs_manager/models/inward_challan.dart';
import 'package:crs_manager/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import 'inward_challan_page.dart';

class InwardChallanList extends StatefulWidget {
  const InwardChallanList({super.key, required this.inwardChallans});

  final List<InwardChallan> inwardChallans;

  @override
  State<InwardChallanList> createState() => _InwardChallanListState();
}

class _InwardChallanListState extends State<InwardChallanList> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: inwardChallanToListView(),
    );
  }

  Widget inwardChallanToListView() {
    return ListView.builder(
      itemCount: widget.inwardChallans.length,
      itemBuilder: (context, index) {
        return inwardChallanToCard(index);
      },
    );
  }

  Widget inwardChallanToCard(int index) {
    var inwardChallan = widget.inwardChallans[index];
    Widget productCount = Text(inwardChallan.products
        .fold(0, (previousValue, element) => previousValue + element.quantity)
        .toString());
    Widget trailing = inwardChallan.productsValue == 0
        ? productCount
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              productCount,
              Text(inwardChallan.productsValue.toString()),
            ],
          );
    return Card(
      elevation: 12,
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 6),
      color: inwardChallan.cancelled
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).cardColor,
      child: ListTile(
        title: Text(inwardChallan.buyer.name),
        subtitle: Text(formatterDate.format(inwardChallan.createdAt)),
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(inwardChallan.number.toString()),
            Text(
              inwardChallan.session
                  .toString()
                  .split("-")
                  .map((e) => e.substring(2))
                  .join("-"),
            ),
          ],
        ),
        trailing: trailing,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => InwardChallanPage(
            inwardChallan: inwardChallan,
          ),
        )),
      ),
    );
  }
}
