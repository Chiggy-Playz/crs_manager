import "package:crs_manager/screens/buyers/buyers_list.dart";
import "package:crs_manager/utils/widgets.dart";
import "package:flutter/material.dart";

import "../../models/buyer.dart";

class ChooseBuyer extends StatelessWidget {
  const ChooseBuyer({super.key, required this.onBuyerSelected});

  final void Function(Buyer) onBuyerSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TransparentAppBar(
        title: const Text("Choose Buyer"),
      ),
      body: BuyersList(onBuyerSelected: onBuyerSelected,)
    );
  }
}
