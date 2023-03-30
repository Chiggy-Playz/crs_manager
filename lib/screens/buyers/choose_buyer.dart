import "package:crs_manager/providers/buyer_select.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../../utils/widgets.dart";
import "buyers_list.dart";

class ChooseBuyer extends StatelessWidget {
  const ChooseBuyer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BuyerSelectionProvider>(
      builder: (context, selector, child) {
        return Scaffold(
          appBar: TransparentAppBar(
            title: const Text("Choose Buyer"),
          ),
          body: const BuyersList(),
          floatingActionButton: !selector.multiple
              ? null
              : FloatingActionButton(
                  onPressed: () {
                    Navigator.of(context).pop(selector.selectedBuyers);
                  },
                  child: const Icon(Icons.check),
                ),
        );
      },
    );
  }
}
