import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';
import 'package:code_builder/code_builder.dart' as code;
import 'package:source_gen/source_gen.dart';
import 'package:summer_generator/summer_generator.dart';

abstract class AnnotatedMethodGenerator {
  FutureOr<code.Library> generate(ClassElement component, MethodElement method, String annotationName);
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

      // adding generated library imports and code
      var mixinLibrary = await _generator.generate(component, method, _name);

      // adding annotation to mixin
      final annotation = method.metadata
          .firstWhere((annotation) => annotationChecker.isExactlyType(annotation.computeConstantValue()!.type!));
      final annotationValue = annotation.toSource();
      final pureAnnotation = annotationValue.substring(1); // removing @
      mixinLibrary = mixinLibrary.rebuild(
        (lb) => lb.body.map((mixin) => (mixin as code.Mixin).rebuild(
            (mb) => mb..annotations = ListBuilder([...mb.annotations.build(), code.refer(pureAnnotation).expression]))),
      );
      imports.add("import '${annotation.element!.library!.librarySource.uri}';");

      imports.addAll(mixinLibrary.directives.map((directive) => directive.accept(code.DartEmitter()).toString()));

      codeParts.addAll(mixinLibrary.body.map((body) => body.accept(code.DartEmitter()).toString()));
    }

    var sourceCode = {...imports, ...codeParts}.join("\n\n");
    sourceCode = formatter.format(sourceCode);

    await buildStep.writeAsString(outputId, sourceCode);
  }
}
