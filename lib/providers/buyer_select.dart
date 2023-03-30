import 'package:flutter/foundation.dart';

import '../models/buyer.dart';


typedef VoidBCallback = void Function(Buyer buyer);

class BuyerSelectionProvider extends ChangeNotifier {
  List<Buyer> selectedBuyers = [];
  final VoidBCallback onBuyerSelected;
  final bool multiple;

  BuyerSelectionProvider({required this.onBuyerSelected, this.multiple = false});

  void addBuyer(Buyer buyer) {
    selectedBuyers.add(buyer);
    notifyListeners();
  }

  void removeBuyer(Buyer buyer) {
    selectedBuyers.remove(buyer);
    notifyListeners();
  }
}
