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
  String? simpleField;

  ComponentB(this.componentA);

  @timed
  @paramLogged
  void doComponentB0Job(String param) {
    print('component B0 job: $param');
    componentA.doComponentAJob();
  }

  @paramLogged
  @timed
  void doComponentB1Job(String param) {
    print('component B1 job: $param');
  }
}

@component
class ComponentC extends ComponentB {
  ComponentC(ComponentA componentA) : super(componentA);

  @timed
  @paramLogged
  void doComponentC0Job(String param) {
    print('component C0 job: $param');
  }
}

@component
abstract class ComponentD extends ComponentC {
  ComponentD(ComponentA componentA) : super(componentA);

  @DbQuery("select * from table where id = @id")
  void doComponentDJob(String id) {}
}
