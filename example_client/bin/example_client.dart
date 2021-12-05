import 'package:example_client/components.dart';
import 'package:example_client/generated/summer.dart';

void main(List<String> arguments) {
  final componentB = summer<ComponentB>();
  componentB.doComponentB0Job('test-param0');
  print("-----------------------------------");
  componentB.doComponentB1Job('test-param1');
  print("-----------------------------------");

  final componentD = summer<ComponentD>();
  componentD.doComponentDJob("test");
  componentD.componentA.doComponentAJob();
  print("-----------------------------------");
}
