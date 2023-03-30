import "package:flutter/material.dart";

import "../../utils/widgets.dart";
import "../../models/buyer.dart";
import "buyers_list.dart";

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
