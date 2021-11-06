import 'package:summer_core/summer_core.dart';
import 'package:example_client/components.dart';

@application
void main(List<String> arguments) {
  final componentB = di<ComponentB>();
  componentB.doComponentBJob('test-param');
}
