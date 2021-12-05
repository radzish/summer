import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart' as code;
import 'package:summer_generator/summer_generator.dart';

class ParamLoggedGenerator extends AnnotatedMethodGenerator {
  @override
  AnnotatedMethodGeneratorResult generate(ClassElement component, MethodElement method, String annotationName) {
    final superCall = code
        .refer("super.${method.displayName}")
        .call(
          _buildMethodPositionalParamNames(method),
          _buildMethodNamedParamNames(method),
        )
        .statement;

    return AnnotatedMethodGeneratorResult(
      methodBody: '''
        print('paramLogged ${component.name}.${method.name}: start');
        print('${component.name}.${method.name} params: [${_buildMethodParamNames(method).map((param) => '\$param').join('|')}]');
        ${superCall.accept(code.DartEmitter())}
        print('paramLogged ${component.name}.${method.name}: finish');      
      ''',
    );
  }

  Iterable<code.Expression> _buildMethodPositionalParamNames(FunctionTypedElement method) {
    return method.parameters
        .where((param) => param.isPositional)
        .map((param) => code.refer(param.displayName).expression);
  }

  Iterable<String> _buildMethodParamNames(FunctionTypedElement method) {
    return method.parameters.map((param) => param.name);
  }

  Map<String, code.Expression> _buildMethodNamedParamNames(FunctionTypedElement method) {
    final paramNames = method.parameters.where((param) => param.isNamed).map((param) => param.displayName);
    return {
      for (var param in paramNames) param: code.refer(param).expression,
    };
  }
}
