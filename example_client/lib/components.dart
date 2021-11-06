import 'package:example_extensions_lib/example_extensions_lib.dart';
import 'package:summer_core/summer_core.dart';

@component
class ComponentA {
  @timed
  void doComponentAJob() {
    print('component A job');
  }
}

@component
class ComponentB {
  final ComponentA componentA;

  ComponentB(this.componentA);

  @timed
  @paramLogged
  void doComponentBJob(String param) {
    print('component B job: $param');
    componentA.doComponentAJob();
  }
}
