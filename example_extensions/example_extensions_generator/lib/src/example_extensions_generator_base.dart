import 'package:analyzer/dart/element/element.dart';
import 'package:built_collection/built_collection.dart';
import 'package:code_builder/code_builder.dart';
import 'package:code_builder/code_builder.dart' as code;
import 'package:summer_generator/summer_generator.dart';

class TimedGenerator extends AnnotatedMethodGenerator {
  @override
  code.Library generate(ClassElement component, MethodElement method, String annotationName) {
    final superCall = code
        .refer("super.${method.displayName}")
        .call(
          _buildMethodPositionalParamNames(method),
          _buildMethodNamedParamNames(method),
        )
        .statement;

    final statements = <code.Code>[
      code.Code("print('timed ${component.name}.${method.name}: start');"),
      code.Code("final stopwatch = Stopwatch()..start();"),
      superCall,
      code.Code("print('timed ${component.name}.${method.name}: \${stopwatch.elapsed}');"),
      code.Code("print('timed ${component.name}.${method.name}: finish');"),
    ];

    final body = code.Block((b) => b..statements = ListBuilder(statements));

    final mixinMethod = code.Method(
      (b) => b
        ..name = method.name
        ..annotations = ListBuilder([code.CodeExpression(code.Code("override"))])
        ..returns = code.refer(method.returnType.getDisplayString(withNullability: true))
        ..requiredParameters = ListBuilder(method.parameters
            .where((parameter) => parameter.isRequiredNamed || parameter.isRequiredPositional)
            .map(_buildParameter)
            .toList())
        //TODO: add support for optional parameters
        ..body = body,
    );

    //TODO: what if we return only imports and method body ??

    return code.Library(
      (b) => b
        ..directives = ListBuilder([Directive.import("dart:math")])
        ..body = ListBuilder([
          code.Mixin(
            (b) => b
              //TODO: name should be generated outside
              ..name = "\$${component.name}_${annotationName}_${method.name}"
              ..on = code.refer(component.name)
              ..methods = ListBuilder([mixinMethod]),
          )
        ]),
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

  Parameter _buildParameter(ParameterElement e) {
    return code.Parameter(
      (b) => b
        ..name = e.name
        ..type = code.refer(e.type.getDisplayString(withNullability: true)),
    );
  }
}

class ParamLoggedGenerator extends AnnotatedMethodGenerator {
  @override
  code.Library generate(ClassElement component, MethodElement method, String annotationName) {
    final superCall = code
        .refer("super.${method.displayName}")
        .call(
      _buildMethodPositionalParamNames(method),
      _buildMethodNamedParamNames(method),
    )
        .statement;

    final statements = <code.Code>[
      code.Code("print('paramLogged ${component.name}.${method.name}: start');"),
      code.Code("print('${component.name}.${method.name} params: [${_buildMethodParamNames(method).map((param) => '\$param').join('|')}]');"),
      superCall,
      code.Code("print('paramLogged ${component.name}.${method.name}: finish');"),
    ];

    final body = code.Block((b) => b..statements = ListBuilder(statements));

    final mixinMethod = code.Method(
          (b) => b
        ..name = method.name
        ..annotations = ListBuilder([code.CodeExpression(code.Code("override"))])
        ..returns = code.refer(method.returnType.getDisplayString(withNullability: true))
        ..requiredParameters = ListBuilder(method.parameters
            .where((parameter) => parameter.isRequiredNamed || parameter.isRequiredPositional)
            .map(_buildParameter)
            .toList())
      //TODO: add support for optional parameters
        ..body = body,
    );

    //TODO: what if we return only imports and method body ??

    return code.Library(
          (b) => b
        ..directives = ListBuilder([Directive.import("dart:math")])
        ..body = ListBuilder([
          code.Mixin(
                (b) => b
            //TODO: name should be generated outside
              ..name = "\$${component.name}_${annotationName}_${method.name}"
              ..on = code.refer(component.name)
              ..methods = ListBuilder([mixinMethod]),
          )
        ]),
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

  Parameter _buildParameter(ParameterElement e) {
    return code.Parameter(
          (b) => b
        ..name = e.name
        ..type = code.refer(e.type.getDisplayString(withNullability: true)),
    );
  }
}
