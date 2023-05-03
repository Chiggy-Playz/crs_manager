import "package:crs_manager/providers/buyer_select.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:responsive_sizer/responsive_sizer.dart";

import "../../utils/widgets.dart";
import "buyer_page.dart";
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
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (selector.multiple)
                FloatingActionButton(
                  onPressed: () {
                    Navigator.of(context).pop(selector.selectedBuyers);
                  },
                  child: const Icon(Icons.check),
                ),
              SizedBox(height: 2.h),
              FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const BuyerPage(),
                  ));
                },
                child: const Icon(Icons.add),
              ),
              SizedBox(height: 2.h),
            ],
          ),
        );
      },
    );
  }
}
