import 'package:example_client/generated/summer.dart';
import 'package:summer_core/summer_core.dart';
import 'package:example_client/components.dart';

@application
void main(List<String> arguments) {
  final componentB = summer<ComponentB>();
  componentB.doComponentB0Job('test-param0');
  componentB.doComponentB1Job('test-param1');
}
