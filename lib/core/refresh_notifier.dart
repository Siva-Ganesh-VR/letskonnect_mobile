import 'package:flutter/foundation.dart';

class RefreshNotifier {
  static final leadsRefresh = ValueNotifier<int>(0);

  static void refreshLeads() {
    leadsRefresh.value++;
  }
}
