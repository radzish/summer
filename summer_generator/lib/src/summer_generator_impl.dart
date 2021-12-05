import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';
import 'package:summer_generator/summer_generator.dart';

class SummerBuilder implements Builder {
  @override
  Future build(BuildStep buildStep) async {
    // final assets = await buildStep
    //     .findAssets(Glob("lib/**"))
    //     //TODO seems like IDEA appends '~' in the process of updating file in 'watch' mode - need to skip those
    //     //think of better approach
    //     .where((asset) => !asset.path.endsWith("~"))
    //     .toList();
    //

    final componentLibraries = <LibraryElement>{};

    final graph = await PackageGraph.forThisPackage();
    final rootComponentLibraries = await findPackageComponentLibraries(graph, buildStep);
    componentLibraries.addAll(rootComponentLibraries);

    final packages = graph.allPackages;

    for (final package in packages.keys) {
      final packageComponentLibraries = await findPackageComponentLibraries(graph, buildStep, package: package);
      componentLibraries.addAll(packageComponentLibraries);
    }

    final generatedAssets = await buildStep.findAssets(Glob("lib/generated/**")).toList();
    final generatedLibraries = await Future.wait(generatedAssets.map((asset) => buildStep.resolver.libraryFor(asset)));

    final imports = {
      "import 'package:summer_core/summer_core.dart';",
      ..._generateImports(generatedLibraries),
      ..._generateImports(componentLibraries),
    };
    final components = await _generateComponentImpls(componentLibraries, generatedLibraries);
    final summerInstance = _generateSummerInstance(components);

    var code = '''
    ${imports.join('\n')}

    ${components.map((component) => component.implCode).join('\n\n')}

    $summerInstance
    ''';

    code = formatter.format(code);

    await buildStep.writeAsString(AssetId(buildStep.inputId.package, 'lib/generated/summer.dart'), code);
  }

  Future<Iterable<LibraryElement>> findPackageComponentLibraries(
    PackageGraph graph,
    BuildStep buildStep, {
    String? package,
  }) async {

    try {
      final assetReader = FileBasedAssetReader(graph);
      final assets = await assetReader
          .findAssets(Glob('lib/**'), package: package)
          //TODO seems like IDEA appends '~' in the process of updating file in 'watch' mode - need to skip those
          .where((asset) => !asset.path.endsWith('~'))
          .toList();

      if(package != 'example_extensions_lib' && package != 'example_client') {
        return [];
      }

      print("!!!!!!!!!!!!!!!!!! ${package}");


      final libraries = await Future.wait(assets.map((asset) => buildStep.resolver.libraryFor(asset)));

      final packageComponentLibraries =
          libraries.where((library) => LibraryReader(library).annotatedWith(componentChecker).isNotEmpty);
      return packageComponentLibraries;
    } catch (e) {
      return [];
    }
  }

  @override
  final buildExtensions = const {
    r'$lib$': ['generated/summer.dart']
  };

  Iterable<String> _generateImports(Iterable<LibraryElement> libraries) {
    return libraries.map((library) => "import '${library.librarySource.uri}';");
  }

  Future<Iterable<_ComponentImplementationResult>> _generateComponentImpls(
    Iterable<LibraryElement> libraries,
    Iterable<LibraryElement> generatedLibraries,
  ) async {
    return libraries
        .map((library) => LibraryReader(library))
        .expand((reader) => reader.annotatedWith(componentChecker))
        .map((annotatedComponent) => annotatedComponent.element as ClassElement)
        .map(
      (component) {
        final name = component.name;
        final implName = '\$${component.name}';
        final dependencies = _resolveComponentDependencies(component);
        final sourceCode =
            _generateComponentImplDeclaration(component, name, implName, generatedLibraries, dependencies);
        return _ComponentImplementationResult(name, implName, sourceCode, dependencies);
      },
    );
  }

  String _generateComponentImplDeclaration(
    ClassElement component,
    String name,
    String implName,
    Iterable<LibraryElement> generatedLibraries,
    List<String> dependencies,
  ) {
    if (component.isAbstract) {
      return _generateAbstractComponentImplDeclaration(component, name, implName, generatedLibraries);
    } else {
      return _generateConcreteComponentImplDeclaration(component, name, implName, generatedLibraries, dependencies);
    }
  }

  String _generateConcreteComponentImplDeclaration(
    ClassElement component,
    String name,
    String implName,
    Iterable<LibraryElement> generatedLibraries,
    List<String> dependencies,
  ) {
    final mixins = _generateConcreteComponentImplMixins(component, generatedLibraries);
    final extending = _resolveExtendingClass(component);
    final delegatingDependencyFields = _generateDependencyFields(component);
    final delegatingMethods = _generateDelegatingMethods(component);
    final implConstructor = _generateComponentImplConstructor(component);
    final decoratorConstructor = _generateComponentDecoratorConstructor(component);

    return '''
    class $implName extends ${implName}Decorator ${mixins.isNotEmpty ? ' with ${mixins.join(', ')}' : ''} {
      $implConstructor
    }
    
    abstract class ${implName}Decorator ${extending != null ? 'extends $extending' : ''} implements $name {
      final $name \$ref;
      $decoratorConstructor
      ${delegatingDependencyFields.join('\n\n')}
      ${delegatingMethods.join('\n\n')}
    }
    ''';
  }

  String? _resolveExtendingClass(ClassElement component) {
    final superType = component.supertype;
    if (superType == null) {
      return null;
    }

    if (!superType.element.metadata.any((annotation) => componentChecker.isExactly(annotation.element!))) {
      return superType.getDisplayString(withNullability: true);
    }

    return '\$${superType.getDisplayString(withNullability: true)}';
  }

  String _generateAbstractComponentImplDeclaration(
    ClassElement component,
    String name,
    String implName,
    Iterable<LibraryElement> generatedLibraries,
  ) {
    final concreteMethodsMixins = _generateConcreteComponentImplMixins(component, generatedLibraries);
    final abstractMethodsMixins = _generateAbstractComponentImplMixins(component, generatedLibraries);
    final extending = _resolveExtendingClass(component);
    final delegatingDependencyFields = _generateDependencyFields(component);
    final delegatingMethods = _generateDelegatingMethods(component);
    final defaultImplConstructor = _generateComponentDefaultImplConstructor(component);
    final implConstructor = _generateComponentImplConstructor(component);
    final decoratorConstructor = _generateComponentDecoratorConstructor(component, '\$${component.name}DefaultImpl');

    return '''
    class $implName extends ${implName}Decorator ${concreteMethodsMixins.isNotEmpty ? ' with ${concreteMethodsMixins.join(', ')}' : ''} {
      $implConstructor
    }
    
    class \$${name}DefaultImpl extends $name ${abstractMethodsMixins.isNotEmpty ? ' with ${abstractMethodsMixins.join(', ')}' : ''} {
      $defaultImplConstructor
    }
    
    abstract class ${implName}Decorator ${extending != null ? 'extends $extending' : ''} implements $name {
      final $name \$ref;
      $decoratorConstructor
      ${delegatingDependencyFields.join('\n\n')}
      ${delegatingMethods.join('\n\n')}
    }
    ''';
  }

  Iterable<String> _generateDependencyFields(ClassElement component) => component.fields.map(_generateDependencyField);

  String _generateDependencyField(FieldElement field) {
    String? getter;
    String? setter = "";

    if (field.getter != null) {
      final declaration = field.getter!.getDisplayString(withNullability: true);
      final name = field.getter!.name;
      getter = '''
        @override
        $declaration => \$ref.$name;
      ''';
    }

    if (field.setter != null) {
      final name = field.name;
      setter = '''
        @override
        void set $name(${_parameterDeclarations(field.setter!)}) => \$ref.$name = ${_parameterNames(field.setter!)};
      ''';
    }

    return '''
      $getter
      $setter
    ''';
  }

  Iterable<String> _generateDelegatingMethods(ClassElement component) =>
      component.methods.map(_generateDelegatingMethod);

  String _generateDelegatingMethod(MethodElement method) {
    final declaration = method.getDisplayString(withNullability: true);
    final name = method.name;
    return '''
      @override
      $declaration => \$ref.$name(${_parameterNames(method)});
    ''';
  }

  Iterable<String> _generateConcreteComponentImplMixins(
          ClassElement component, Iterable<LibraryElement> mixinLibraries) =>
      component.methods
          .where((method) => method.metadata.isNotEmpty)
          .where((method) => !method.isAbstract)
          .expand((method) => _generateMethodMixins(component, method, mixinLibraries));

  Iterable<String> _generateAbstractComponentImplMixins(
          ClassElement component, Iterable<LibraryElement> mixinLibraries) =>
      component.methods
          .where((method) => method.metadata.isNotEmpty)
          .where((method) => !method.isAbstract)
          .expand((method) => _generateMethodMixins(component, method, mixinLibraries));

  Iterable<String> _generateMethodMixins(
    ClassElement component,
    MethodElement method,
    Iterable<LibraryElement> mixinLibraries,
  ) =>
      method
          .metadata
          // we want outer params to be executed first
          .reversed
          .map((annotation) => _generateMethodMixin(component, method, annotation, mixinLibraries))
          .whereType<String>();

  String? _generateMethodMixin(
    ClassElement component,
    MethodElement method,
    ElementAnnotation annotation,
    Iterable<LibraryElement> mixinLibraries,
  ) {
    //TODO: think of optimization, we can resolve component mixins once and put them into map
    final componentMixins = mixinLibraries
        .expand((library) => LibraryReader(library).allElements)
        .whereType<ClassElement>()
        .where((clazz) => clazz.isMixin && clazz.superclassConstraints.contains(component.thisType));

    final methodMixin = componentMixins.firstWhereOrNull(
      (mixin) =>
          mixin.name.endsWith('_${method.name}') &&
          mixin.metadata
              .any((mixinAnnotation) => mixinAnnotation.computeConstantValue() == annotation.computeConstantValue()),
    );

    return methodMixin?.name;
  }

  String _generateComponentImplConstructor(ClassElement component) {
    final constructors = component.constructors;

    //TODO: should we support multiple constructors
    if (constructors.length > 1) {
      throw UnsupportedError("component must have one constructor max");
    }

    final constructor = constructors.first;

    // default constructor - we do not need to generate anything
    if (constructor.parameters.isEmpty) {
      return '';
    }

    //TODO: should we support named constructors?
    return '\$${component.name}(${_parameterDeclarations(constructor)}): super(${_parameterNames(constructor)});';
  }

  String _generateComponentDefaultImplConstructor(ClassElement component) {
    final constructors = component.constructors;

    //TODO: should we support multiple constructors
    if (constructors.length > 1) {
      throw UnsupportedError("component must have one constructor max");
    }

    final constructor = constructors.first;

    // default constructor - we do not need to generate anything
    if (constructor.parameters.isEmpty) {
      return '';
    }

    //TODO: should we support named constructors?
    return '\$${component.name}DefaultImpl(${_parameterDeclarations(constructor)}): super(${_parameterNames(constructor)});';
  }

  String _generateComponentDecoratorConstructor(ClassElement component, [String? refConstructorName]) {
    final constructors = component.constructors;

    //TODO: should we support multiple constructors
    if (constructors.length > 1) {
      throw UnsupportedError("component must have one constructor max");
    }

    final constructor = constructors.first;

    final superConstructor = component.supertype?.constructors.first;

    //TODO: should we support named constructors?
    return '\$${component.name}Decorator(${_parameterDeclarations(constructor)}): \$ref = ${refConstructorName ?? component.name}(${_parameterNames(constructor)}), super(${superConstructor != null ? _parameterNames(superConstructor) : ''});';
  }

  String _parameterDeclarations(ExecutableElement constructor) =>
      constructor.parameters.map((parameter) => parameter.getDisplayString(withNullability: true)).join(', ');

  String _parameterNames(ExecutableElement constructor) =>
      constructor.parameters.map((parameter) => parameter.name).join(', ');

  List<String> _resolveComponentDependencies(ClassElement component) {
    final constructors = component.constructors;

    //TODO: should we support multiple constructors
    if (constructors.length > 1) {
      throw UnsupportedError("component must have one constructor max");
    }

    final constructor = constructors.first;

    // default constructor - we do not need to generate anything
    if (constructor.parameters.isEmpty) {
      return [];
    }

    return constructor.parameters.map((param) => param.type.getDisplayString(withNullability: true)).toList();
  }

  String _generateSummerInstance(Iterable<_ComponentImplementationResult> componentResults) {
    final cases = componentResults.map(_generateSummerDeclarationComponentCase).join('\n');
    return '''
      final summer = Summer(<T>() {
        switch(T) {
          $cases
        }
      });
    ''';
  }

  String _generateSummerDeclarationComponentCase(_ComponentImplementationResult componentResult) =>
      'case ${componentResult.name}: return ${_generateSummerDeclarationComponentInstance(componentResult)};';

  String _generateSummerDeclarationComponentInstance(_ComponentImplementationResult componentResult) =>
      '${componentResult.implName}(${componentResult.dependencies.map((dependency) => 'summer<$dependency>()').join(', ')})';
}

class _ComponentImplementationResult {
  final String name;
  final String implName;
  final String implCode;
  final List<String> dependencies;

  _ComponentImplementationResult(this.name, this.implName, this.implCode, this.dependencies);
}
