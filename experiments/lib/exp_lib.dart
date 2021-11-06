import 'dart:mirrors';

import 'package:example_extensions_lib/example_extensions_lib.dart';

class Checker {
  void check() {
    final mirror = reflectClass(Timed);
    print("!!!!!!! ${mirror}");
    print("!!!!!!! ${mirror.owner}");
  }
}
