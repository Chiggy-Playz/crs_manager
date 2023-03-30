import 'package:crs_manager/screens/challans/search_page.dart';

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
    label: "Models",
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
  List<Widget> _actions = [];

  @override
  void initState() {
    super.initState();
    _updateActions(_activePage);
  }

  @override
  void dispose() {
    _pageViewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TransparentAppBar(
        title: const Text("CRS Manager"),
        actions: _actions,
      ),
      body: PageView(
        controller: _pageViewController,
        children: [
          const ChallansList(),
          BuyersList(
            onBuyerSelected: (buyer) =>
                Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => BuyerPage(
                buyer: buyer,
              ),
            )),
          ),
          const Center(
            child: Text("Assets"),
          ),
          const Center(
            child: Text("Models"),
          ),
          const Center(
            child: Text("History"),
          ),
        ],
        onPageChanged: (index) {
          setState(() {
            _activePage = index;
            _updateActions(index);
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
      default:
    }
  }

  void _updateActions(int index) {
    if ([0].contains(index)) {
      _actions = [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SearchPage()));
          },
        ),
      ];
    } else {
      _actions = [];
    }
  }
}
