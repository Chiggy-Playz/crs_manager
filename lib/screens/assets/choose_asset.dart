import 'package:crs_manager/providers/asset_select.dart';
import 'package:crs_manager/screens/assets/asset_list.dart';
import 'package:crs_manager/screens/assets/asset_page.dart';
import 'package:crs_manager/utils/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class ChooseAsset extends StatelessWidget {
  const ChooseAsset({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AssetSelectionProvider>(
      builder: (context, selector, child) {
        return Scaffold(
          appBar: TransparentAppBar(
            title: const Text("Choose Asset"),
          ),
          body: const AssetList(),
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (selector.multiple)
                FloatingActionButton(
                  heroTag: "Save",
                  onPressed: () {
                    Navigator.of(context).pop(selector.selectedAssets);
                  },
                  child: const Icon(Icons.check),
                ),
              SizedBox(height: 2.h),
              FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const AssetPage(),
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
