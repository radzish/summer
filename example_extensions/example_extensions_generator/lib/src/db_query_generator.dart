import 'package:analyzer/dart/element/element.dart';
import 'package:example_extensions_lib/example_extensions_lib.dart';
import 'package:source_gen/source_gen.dart';
import 'package:summer_generator/summer_generator.dart';

final dbQueryChecker = TypeChecker.fromRuntime(DbQuery);

class DbQueryGenerator extends AnnotatedMethodGenerator {
  @override
  AnnotatedMethodGeneratorResult generate(ClassElement component, MethodElement method, String annotationName) {
    final annotation = method.metadata
        .firstWhere((annotation) => dbQueryChecker.isExactlyType(annotation.computeConstantValue()!.type!));

    final query = annotation.computeConstantValue()!.getField("query")!.toStringValue();

    return AnnotatedMethodGeneratorResult(
      methodBody: '''
        print('db query ${component.name}.${method.name}: start');
        print('performing db query "$query"');
        print('db query ${component.name}.${method.name}: finish');      
      ''',
    );
  }
}
