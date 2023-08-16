import 'package:crs_manager/providers/asset_select.dart';
import 'package:crs_manager/providers/buyer_select.dart';
import 'package:crs_manager/screens/assets/asset_list.dart';
import 'package:crs_manager/screens/assets/asset_page.dart';
import 'package:crs_manager/screens/challans/search/search_page.dart';
import 'package:crs_manager/screens/settings.dart';
import 'package:crs_manager/screens/templates/template_page.dart';
import 'package:crs_manager/screens/templates/templates_list.dart';
import 'package:provider/provider.dart';

import '../providers/database.dart';
import 'buyers/buyer_page.dart';
import 'buyers/buyers_list.dart';
import 'challans/challans_list.dart';
import '../utils/widgets.dart';
import 'package:flutter/material.dart';

import 'challans/new_challan.dart';

const List<BottomNavigationBarItem> dropDownItems = [
  BottomNavigationBarItem(
    label: "Challans",
    icon: Icon(
      Icons.list,
    ),
  ),
  BottomNavigationBarItem(
    label: "Buyers",
    icon: Icon(
      Icons.person,
    ),
  ),
  BottomNavigationBarItem(
    label: "Assets",
    icon: Icon(
      Icons.cases_outlined,
    ),
  ),
  BottomNavigationBarItem(
    label: "Templates",
    icon: Icon(
      Icons.widgets,
    ),
  ),
  BottomNavigationBarItem(
    label: "History",
    icon: Icon(
      Icons.history,
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

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageViewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TappableAppBar(
        onTap: () {
          // Search
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const SearchPage(),
            ),
          );
        },
        appBar: TransparentAppBar(
          title: const Text("CRS Manager"),
          actions: getActions(),
        ),
      ),
      body: PageView(
        controller: _pageViewController,
        children: [
          Consumer<DatabaseModel>(
            builder: (context, value, child) => ChallansList(
              challans: value.challans,
            ),
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
          ChangeNotifierProvider(
            create: (_) => AssetSelectionProvider(
              onAssetSelected: (asset) => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AssetPage(
                    asset: asset,
                  ),
                ),
              ),
            ),
            child: const AssetList(),
          ),
          const Center(child: TemplatesList()),
          const Center(
            child: Text("History"),
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
              curve: Curves.bounceIn);
        },
        items: dropDownItems,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: _fabAction,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _fabAction() {
    switch (_activePage) {
      case 0: // Challan
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const NewChallanPage(),
        ));
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
      case 3: // Template
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const TemplatePage(),
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
