import 'package:crs_manager/models/inward_challan.dart';
import 'package:crs_manager/screens/challans/challan_page.dart';
import 'package:crs_manager/screens/challans/inward/inward_challan_page.dart';
import 'package:flutter/material.dart';

import '../../../models/buyer.dart';
import '../../../models/challan.dart';
import '../../../utils/constants.dart';

class TreeViewWidget extends StatefulWidget {
  const TreeViewWidget({super.key, required this.challans});

  final List<ChallanBase> challans;

  @override
  State<TreeViewWidget> createState() => _TreeViewWidgetState();
}

class _TreeViewWidgetState extends State<TreeViewWidget> {
  Map<Buyer, List<ChallanBase>> challansSortedByBuyer = {};
  List<Buyer> buyersSortedByName = [];
  // Challans merged, but sorted by buyer
  // Buyers A, B ,c
  // so list will be A, A, B, B, B, C, C....
  List<ChallanBase> buyerOrderedChallans = [];
  List<bool> _isOpen = [];
  List<bool> _checked = [];

  @override
  void initState() {
    super.initState();

    for (ChallanBase challan in widget.challans) {
      challansSortedByBuyer
          .putIfAbsent(challan.buyer, () => <ChallanBase>[])
          .add(challan);
    }
    buyersSortedByName = challansSortedByBuyer.keys.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    for (Buyer buyer in buyersSortedByName) {
      buyerOrderedChallans.addAll(challansSortedByBuyer[buyer]!);
    }

    _isOpen = List<bool>.filled(buyersSortedByName.length, false);
    _checked = List<bool>.filled(buyerOrderedChallans.length, false);
  }

  @override
  Widget build(BuildContext context) {
    // Create a expansion panel list for each buyer
    // And a challans list for that buyer in that expansion panel
    return ExpansionPanelList(
      elevation: 12,
      children: List.generate(
        challansSortedByBuyer.length,
        (buyerIndex) {
          var buyerChallans =
              challansSortedByBuyer[buyersSortedByName[buyerIndex]]!;
          return ExpansionPanel(
            headerBuilder: (context, isExpanded) {
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(buyersSortedByName[buyerIndex].name),
                onTap: () {
                  setState(() {
                    _isOpen[buyerIndex] = !_isOpen[buyerIndex];
                  });
                },
              );
            },
            body: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: buyerChallans.length,
              itemBuilder: (context, challanIndex) {
                var challan = buyerChallans[challanIndex];
                int challanIndexInList = buyerOrderedChallans.indexOf(challan);
                return ListTile(
                  leading: Column(children: [
                    Text(challan.number.toString()),
                    Text(
                      challan.session
                          .split("-")
                          .map((element) => element.replaceFirst("20", ""))
                          .join("-"),
                    ),
                  ]),
                  title: Text(formatterDate.format(challan.createdAt)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (challan is InwardChallan)
                        Icon(Icons.arrow_downward,
                            color: Theme.of(context).colorScheme.primary),
                      Checkbox(
                        value: _checked[challanIndexInList],
                        onChanged: (value) {
                          setState(() {
                            _checked[challanIndexInList] = value!;
                          });
                        },
                      ),
                    ],
                  ),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) {
                      if (challan is Challan) {
                        return ChallanPage(
                          challan: challan,
                        );
                      } else if (challan is InwardChallan) {
                        return InwardChallanPage(
                          inwardChallan: challan,
                        );
                      }
                      return const Placeholder();
                    },
                  )),
                );
              },
            ),
            isExpanded: _isOpen[buyerIndex],
          );
        },
      ),
      expansionCallback: (panelIndex, isExpanded) {
        setState(() {
          _isOpen[panelIndex] = !_isOpen[panelIndex];
        });
      },
    );
  }
}
