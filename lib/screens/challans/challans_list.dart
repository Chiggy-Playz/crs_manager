import 'package:crs_manager/screens/challans/new_challan.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/challan.dart';
import 'challan_pageview.dart';

final DateFormat cardFormatter = DateFormat('HH:mm:ss  dd-MM-yyyy');

class ChallansList extends StatefulWidget {
  const ChallansList({
    super.key,
    required this.challans,
  });

  final List<Challan> challans;

  @override
  State<ChallansList> createState() => _ChallansListState();
}

class _ChallansListState extends State<ChallansList> {
  final scrollController = ScrollController();
  late Offset _tapDownPosition;

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: DraggableScrollbar.rrect(
        controller: scrollController,
        heightScrollThumb: 48,
        backgroundColor: Theme.of(context).colorScheme.primary,
        labelTextBuilder: (offsetY) {
          var challan = widget.challans.elementAt(offsetY ~/ 90);
          String month =
              DateFormat("MMMM").format(challan.createdAt).substring(0, 3);
          String year = challan.session
              .toString()
              .split("-")
              .map((e) => e.substring(2))
              .join("-");
          return Text("$month $year",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
              ));
        },
        child: challansToListView(widget.challans),
      ),
    );
  }

  ListView challansToListView(List<Challan> challans) {
    return ListView.builder(
      shrinkWrap: true,
      controller: scrollController,
      itemCount: challans.length,
      itemBuilder: (context, index) {
        return challanCard(challans, index);
      },
    );
  }

  Widget challanCard(List<Challan> challans, int index) {
    Challan challan = challans[index];
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

    return GestureDetector(
      onTapDown: (TapDownDetails details) {
        _tapDownPosition = details.globalPosition;
      },
      onLongPress: () async {
        final overlay =
            Overlay.of(context).context.findRenderObject() as RenderBox;

        var value = await showMenu<int>(
          context: context,
          items: const [
            PopupMenuItem(value: 0, child: Text("Copy Challan")),
          ],
          position: RelativeRect.fromLTRB(
            _tapDownPosition.dx,
            _tapDownPosition.dy,
            overlay.size.width - _tapDownPosition.dx,
            overlay.size.height - _tapDownPosition.dy,
          ),
        );

        if (value == null) {
          return;
        }
        if (!mounted) return;

        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => NewChallanPage(
                  copyFromChallan: challan,
                )));
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 6),
        elevation: 12,
        color: challan.cancelled
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).cardColor,
        child: ListTile(
          title: Text(challan.buyer.name),
          subtitle: Text(cardFormatter.format(challan.createdAt)),
          leading:
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(challan.number.toString()),
            Text(
              challan.session
                  .toString()
                  .split("-")
                  .map((e) => e.substring(2))
                  .join("-"),
            ),
          ]),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              trailing,
              if (challan.received) ...[
                const SizedBox(
                  width: 4,
                ),
                Icon(
                  Icons.check,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
              if (challan.billNumber != null) ...[
                const SizedBox(
                  width: 4,
                ),
                Icon(
                  Icons.receipt_long,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ],
          ),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => ChallanPageView(
              challans: challans,
              initialIndex: index,
            ),
          )),
        ),
      ),
    );
  }
}
