import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:summer_generator/summer_generator.dart';

class AnnotatedMethodGeneratorResult {
  final List<String> imports;
  final String methodBody;

  AnnotatedMethodGeneratorResult({this.imports = const [], this.methodBody = ""});
}

abstract class AnnotatedMethodGenerator {
  FutureOr<AnnotatedMethodGeneratorResult> generate(
      ClassElement component, MethodElement method, String annotationName);
}

class SummerAnnotationBuilder<T> implements Builder {
  TypeChecker get annotationChecker => TypeChecker.fromRuntime(T);

  final String _name;
  final AnnotatedMethodGenerator _generator;

  //TODO: we should reuse it from yaml configuration
  @override
  final Map<String, List<String>> buildExtensions;

  SummerAnnotationBuilder(this._name, this._generator, this.buildExtensions);

  @override
  Future build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;

    // TODO: think how to improve
    if (inputId.path.contains('lib/generated/')) {
      return;
    }

    final outputId = AssetId(
      inputId.package,
      inputId.path.replaceFirst('lib/', 'lib/generated/').replaceFirst('.dart', '.$_name.dart'),
    );

    final library = await buildStep.inputLibrary;
    final libraryReader = LibraryReader(library);

    final annotatedMethods = libraryReader
        .annotatedWith(componentChecker)
        .expand((element) => (element.element as ClassElement).methods)
        .where(
          (method) => method.metadata
              .any((annotation) => annotationChecker.isExactlyType(annotation.computeConstantValue()!.type!)),
        );

    final imports = <String>{};
    final codeParts = <String>{};

    for (final method in annotatedMethods) {
      // our mixin will depend on component - adding it in imports
      final component = method.enclosingElement as ClassElement;
      imports.add("import '${component.library.librarySource.uri}';");

      // adding import for mixin annotation
      final annotation = method.metadata
          .firstWhere((annotation) => annotationChecker.isExactlyType(annotation.computeConstantValue()!.type!));
      imports.add("import '${_resolveAnnotationUri(annotation)}';");

      // adding generated library imports and code
      final mixinResult = await _generator.generate(component, method, _name);

      // adding imports required by generated method body
      imports.addAll([for (final importUrl in mixinResult.imports) "import '$importUrl';"]);

      codeParts.add(_generateMixin(component, method, annotation, mixinResult.methodBody));
    }

    var sourceCode = {...imports, ...codeParts}.join("\n\n");
    sourceCode = formatter.format(sourceCode);

    await buildStep.writeAsString(outputId, sourceCode);
  }

  //TODO: Current implementation resolves src - library.
  //Need to find a way to resolve actual package library
  Uri _resolveAnnotationUri(ElementAnnotation annotation) => annotation.element!.librarySource!.uri;

  String _generateMixin(ClassElement component, MethodElement method, ElementAnnotation annotation, String methodBody) {
    return '''
    ${annotation.toSource()}
    mixin \$${component.name}_${annotation.element!.name!}_${method.name} on ${component.name} {
      @override
      ${method.returnType.getDisplayString(withNullability: true)} ${method.name}(${_buildMethodParameters(method)}) {
        $methodBody
      }
    }
    ''';
  }

  String _buildMethodParameters(MethodElement method) => method.parameters.map(_buildMethodParameter).join(', ');

  String _buildMethodParameter(ParameterElement parameter) => parameter.getDisplayString(withNullability: true);
}
