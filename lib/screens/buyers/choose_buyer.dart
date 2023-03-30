import "package:crs_manager/providers/buyer_select.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../../utils/widgets.dart";
import "../../models/buyer.dart";
import "buyers_list.dart";

class ChooseBuyer extends StatelessWidget {
  const ChooseBuyer(
      {super.key, required this.onBuyerSelected, this.multiple = false});

  final void Function(Buyer) onBuyerSelected;
  final bool multiple;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TransparentAppBar(
        title: const Text("Choose Buyer"),
      ),
      body: BuyersList(
        multiple: multiple,
        onBuyerSelected: onBuyerSelected,
      ),
      floatingActionButton: !multiple
          ? null
          : Consumer<BuyerSelectionProvider>(
              builder: (context, selector, child) {
                return FloatingActionButton(
                  onPressed: () {
                    Navigator.of(context).pop(selector.selectedBuyers);
                  },
                  child: const Icon(Icons.check),
                );
              },
            ),
    );
  }
}
