import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart' as code;

abstract class SummerExtensionBuilder {
  code.Mixin? generate(ClassElement component, MethodElement method);
}
