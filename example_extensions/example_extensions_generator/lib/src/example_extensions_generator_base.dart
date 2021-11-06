
import 'package:analyzer/dart/element/element.dart';
import 'package:built_collection/built_collection.dart';
import 'package:code_builder/code_builder.dart';
import 'package:code_builder/code_builder.dart' as code;
import 'package:example_extensions_lib/example_extensions_lib.dart';
import 'package:source_gen/source_gen.dart';
import 'package:summer_generator/summer_generator.dart';

final _componentAnnotationChecker = TypeChecker.fromRuntime(Timed);

class TimedBuilder implements SummerExtensionBuilder {
  bool _isTimed(MethodElement method) {
    return method.metadata.any((annotation) {
      return annotation.toString().contains("@Timed");
      // TODO: this does not work as looks like TypeChecker does not work properly when running from already reflected library
      return _componentAnnotationChecker.isExactlyType(annotation.computeConstantValue()!.type!);
    });
  }

  @override
  code.Mixin? generate(ClassElement clazz, MethodElement method) {
    if (!_isTimed(method)) {
      return null;
    }

    final superCall = code
        .refer("super.${method.displayName}")
        .call(
          _buildMethodPositionalParamNames(method),
          _buildMethodNamedParamNames(method),
        )
        .statement;

    final statements = <code.Code>[
      code.Code("final stopwatch = Stopwatch()..start();"),
      superCall,
      code.Code("print('timed ComponentB.doComponentBJob: \${stopwatch.elapsed}');"),
    ];

    final body = code.Block((b) => b..statements = ListBuilder(statements));

    final mixinMethod = code.Method(
      (b) => b
        ..name = method.name
        ..annotations = ListBuilder([code.CodeExpression(code.Code("override"))])
        ..returns = code.Reference(method.returnType.getDisplayString(withNullability: true))
        ..requiredParameters = ListBuilder(method.parameters
            .where((parameter) => parameter.isRequiredNamed || parameter.isRequiredPositional)
            .map(_buildParameter)
            .toList())
        //TODO: add support for optional parameters
        ..body = body,
    );

    return code.Mixin(
      (b) => b
        ..name = "_${clazz.name}_timed_${method.name}"
        ..on = code.refer(clazz.name)
        ..methods = ListBuilder([mixinMethod]),
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
