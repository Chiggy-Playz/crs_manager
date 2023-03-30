import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/challan.dart';
import '../../providers/database.dart';
import 'challan_page.dart';

final DateFormat cardFormatter = DateFormat('HH:mm:ss  dd-MM-yyyy');

class ChallansList extends StatefulWidget {
  const ChallansList({super.key});

  @override
  State<ChallansList> createState() => _ChallansListState();
}

class _ChallansListState extends State<ChallansList> {
  final scrollController = ScrollController();

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseModel>(
      builder: (context, value, child) {
        var challans = value.challans;

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: DraggableScrollbar.rrect(
            controller: scrollController,
            heightScrollThumb: 48,
            backgroundColor: Theme.of(context).colorScheme.primary,
            labelTextBuilder: (offsetY) {
              var challan = challans.elementAt(offsetY ~/ 90);
              String month =
                  DateFormat("MMMM").format(challan.createdAt).substring(0, 3);
              String year = challan.session.replaceAll("20", "");
              return Text("$month $year",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ));
            },
            child: challansToListView(challans),
          ),
        );
      },
    );
  }

  ListView challansToListView(List<Challan> challans) {
    return ListView.builder(
      controller: scrollController,
      itemCount: challans.length,
      itemBuilder: (context, index) {
        Challan challan = challans[index];
        return challanCard(challan);
      },
    );
  }

  Card challanCard(Challan challan) {
    Widget productCount = Text(challan.products
        .fold(0, (previousValue, element) => previousValue + element.quantity)
        .toString());
    Widget trailing = challan.productsValue == 0
        ? productCount
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              productCount,
              Text(challan.productsValue.toString()),
            ],
          );
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 6),
      elevation: 12,
      color: challan.cancelled
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).cardColor,
      child: ListTile(
        title: Text(challan.buyer.name),
        subtitle: Text(cardFormatter.format(challan.createdAt)),
        leading: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(challan.number.toString()),
          Text(
            challan.session.toString().replaceAll("20", ""),
          ),
        ]),
        trailing: challan.received
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  trailing,
                  const SizedBox(
                    width: 4,
                  ),
                  Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.primary,
                  )
                ],
              )
            : trailing,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ChallanPage(
            challan: challan,
          ),
        )),
      ),
    );
  }
}
