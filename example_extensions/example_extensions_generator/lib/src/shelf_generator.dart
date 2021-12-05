import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart' as code;
import 'package:summer_generator/summer_generator.dart';

class RoutesResolverGenerator extends AnnotatedMethodGenerator {
  @override
  AnnotatedMethodGeneratorResult generate(ClassElement component, MethodElement method, String annotationName) {
    //TODO: move super call generator to summer generator utilities  !!!!!
    final superCall = code
        .refer("super.${method.displayName}")
        .call(
          _buildMethodPositionalParamNames(method),
          _buildMethodNamedParamNames(method),
        )
        .statement;

    return AnnotatedMethodGeneratorResult(
      imports: [
        'dart:math',
      ],
      methodBody: '''
        print('timed ${component.name}.${method.name}: start');
        final stopwatch = Stopwatch()..start();
        ${superCall.accept(code.DartEmitter())}
        print('timed ${component.name}.${method.name}: \${stopwatch.elapsed}');
        print('timed ${component.name}.${method.name}: finish');      
      ''',
    );
  }

  Iterable<code.Expression> _buildMethodPositionalParamNames(FunctionTypedElement method) {
    return method.parameters
        .where((param) => param.isPositional)
        .map((param) => code.refer(param.displayName).expression);
  }

  Map<String, code.Expression> _buildMethodNamedParamNames(FunctionTypedElement method) {
    final paramNames = method.parameters.where((param) => param.isNamed).map((param) => param.displayName);
    return {
      for (var param in paramNames) param: code.refer(param).expression,
    };
  }
}
