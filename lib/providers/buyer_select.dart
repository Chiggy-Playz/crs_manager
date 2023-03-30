import 'package:flutter/foundation.dart';

import '../models/buyer.dart';

class BuyerSelectionProvider extends ChangeNotifier {

  List<Buyer> selectedBuyers = [];

  void addBuyer(Buyer buyer) {
    selectedBuyers.add(buyer);
    notifyListeners();
  }

  void removeBuyer(Buyer buyer) {
    selectedBuyers.remove(buyer);
    notifyListeners();
  }
}