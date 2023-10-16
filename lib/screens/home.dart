import 'dart:async';

import 'package:crs_manager/providers/asset_select.dart';
import 'package:crs_manager/providers/buyer_select.dart';
import 'package:crs_manager/screens/assets/asset_list.dart';
import 'package:crs_manager/screens/assets/asset_page.dart';
import 'package:crs_manager/screens/assets/outer_asset_list.dart';
import 'package:crs_manager/screens/assets/detailed_asset_page.dart';
import 'package:crs_manager/screens/challans/challan_page.dart';
import 'package:crs_manager/screens/challans/inward/inward_challan_list.dart';
import 'package:crs_manager/screens/challans/inward/inward_challan_page.dart';
import 'package:crs_manager/screens/challans/search/search_page.dart';
import 'package:crs_manager/screens/settings.dart';
import 'package:crs_manager/screens/templates/templates_list.dart';
import 'package:provider/provider.dart';

import '../providers/database.dart';
import 'buyers/buyer_page.dart';
import 'buyers/buyers_list.dart';
import 'challans/challans_list.dart';
import '../utils/widgets.dart';
import 'package:flutter/material.dart';

import 'challans/new_challan.dart';

List<BottomNavigationBarItem> bottomNavBarItems = [
  const BottomNavigationBarItem(
    label: "Challans",
    icon: Icon(
      Icons.list,
    ),
  ),
  const BottomNavigationBarItem(
    label: "Buyers",
    icon: Icon(
      Icons.person,
    ),
  ),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _pageViewController = PageController();

  int _activePage = 0;
  Timer? _timer;
  // 0 - Outwards
  // 1 - Inwards
  int challanCreateMode = 0;

  @override
  void initState() {
    super.initState();
    bottomNavBarItems.add(
      BottomNavigationBarItem(
        label: "Assets",
        icon: GestureDetector(
          onPanDown: (_) {
            _timer = Timer(
                const Duration(seconds: 3),
                () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const TemplatesList(),
                      ),
                    ));
          },
          onPanCancel: () => _timer?.cancel(),
          child: const Icon(
            Icons.cases_outlined,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageViewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: TransparentAppBar(
          title: const Text("CRS Manager"),
          actions: getActions(),
          bottom: _activePage == 0
              ? TabBar(
                  tabs: const [
                    Tab(icon: Icon(Icons.arrow_upward), text: "Outward"),
                    Tab(icon: Icon(Icons.arrow_downward), text: "Inward"),
                  ],
                  onTap: (value) {
                    setState(() {
                      challanCreateMode = value;
                    });
                  },
                )
              : null,
        ),
        body: PageView(
          controller: _pageViewController,
          children: [
            TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Consumer<DatabaseModel>(
                  builder: (context, value, child) => ChallansList(
                    challans: value.challans,
                  ),
                ),
                Consumer<DatabaseModel>(
                  builder: (context, value, child) => InwardChallanList(
                    inwardChallans: value.inwardChallans,
                  ),
                )
              ],
            ),
            ChangeNotifierProvider(
              create: (_) => BuyerSelectionProvider(
                onBuyerSelected: (buyer) => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => BuyerPage(
                      buyer: buyer,
                    ),
                  ),
                ),
              ),
              child: const BuyersList(),
            ),
            OuterAssetListWidget(
              multiple: false,
              onAssetSelected: (assets) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TransactionPage(
                      assets: assets,
                    ),
                  ),
                );
              },
            ),
          ],
          onPageChanged: (index) {
            setState(() {
              _activePage = index;
            });
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
            currentIndex: _activePage,
            onTap: (index) {
              _pageViewController.animateToPage(index,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.ease);
            },
            items: bottomNavBarItems),
        floatingActionButton: FloatingActionButton(
          heroTag: null,
          onPressed: _fabAction,
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _fabAction() {
    switch (_activePage) {
      case 0: // Challan
        if (challanCreateMode == 0) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const ChallanPage(),
          ));
        } else {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const InwardChallanPage(),
          ));
        }
        break;
      case 1: // Buyer
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const BuyerPage(),
        ));
        break;
      case 2: // Asset
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const AssetPage(),
        ));
        break;

      default:
    }
  }

  List<Widget> getActions() {
    var actions = [
      IconButton(
        icon: const Icon(Icons.settings),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const SettingsPage(),
            ),
          );
        },
      ),
    ];
    if ([0].contains(_activePage)) {
      return actions
        ..addAll([
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SearchPage(),
                ),
              );
            },
          ),
        ]);
    } else {
      return actions;
    }
  }
}
