import 'dart:async';
import 'dart:mirrors';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:built_collection/built_collection.dart';
import 'package:code_builder/code_builder.dart' as code;
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';
import 'package:summer_core/summer_core.dart';
import 'package:summer_generator/src/summer_generator_api.dart';

final _applicationAnnotationChecker = TypeChecker.fromRuntime(Application);
final _componentAnnotationChecker = TypeChecker.fromRuntime(Component);
final _builderInterfaceChecker = TypeChecker.fromRuntime(SummerExtensionBuilder);

class SummerGenerator extends Generator {
  final Set<SummerExtensionBuilder> _extensionBuilders = {};

  @override
  FutureOr<String?> generate(LibraryReader library, BuildStep buildStep) async {
    if (_isApplication(library)) {
      final assets =
          await buildStep.findAssets(Glob("*", recursive: true)).where((asset) => asset.extension == ".dart").toList();
      final librariesElements =
          await Future.wait(assets.map((asset) => buildStep.resolver.libraryFor(asset, allowSyntaxErrors: true)));
      final libraries =
          librariesElements.map((element) => LibraryReader(element)).where((element) => element != library).toList();

      await _initExtensionBuilders(buildStep);

      return await _generate(library, libraries, buildStep);
    }

    return null;
  }

  bool _isApplication(LibraryReader library) => library.annotatedWith(_applicationAnnotationChecker).isNotEmpty;

  Future<String> _generate(
    LibraryReader applicationLibrary,
    List<LibraryReader> otherLibraries,
    BuildStep buildStep,
  ) async {
    final result = StringBuffer();

    final classImplementationsMap = <ClassElement, code.Class>{};

    final componentElements = otherLibraries
        .expand((library) =>
            library.annotatedWith(_componentAnnotationChecker).map((annotatedElement) => annotatedElement.element))
        .cast<ClassElement>();

    for (final componentElement in componentElements) {
      final extensionMixins = _generateComponentExtensionMixins(componentElement);
      final componentClass = _generateComponentClass(componentElement, extensionMixins);

      result.writeln(_serializeSpec(componentClass));
      result.writeln("\n");

      for (final extensionMixin in extensionMixins) {
        result.writeln(_serializeSpec(extensionMixin));
        result.writeln("\n");
      }
    }

    result.writeln(_generateDi(classImplementationsMap));

    return result.toString();
  }

  Iterable<code.Mixin> _generateComponentExtensionMixins(ClassElement component) =>
      component.methods.expand((method) => _generateMethodExtensionMixins(component, method));

  Iterable<code.Mixin> _generateMethodExtensionMixins(ClassElement component, MethodElement method) {
    return _extensionBuilders
        .map((builder) => builder.generate(component, method))
        .where((mixin) => mixin != null)
        .cast();
  }

  code.Class _generateComponentClass(ClassElement componentElement, Iterable<code.Mixin> mixins) {
    return code.Class(
      (b) => b
        ..name = "_${componentElement.name}"
        ..extend = code.refer(componentElement.name)
        ..mixins = ListBuilder(mixins.map((mixin) => code.refer(mixin.name)))
      //
      ,
    );
  }

  String _generateDi(Map<ClassElement, code.Class> classImplementationsMap) {
    return "";
  }

  String _serializeSpec(code.Spec codeSpec) => codeSpec.accept(code.DartEmitter()).toString();

  Future<void> _initExtensionBuilders(BuildStep buildStep) async {
    final packageGraph = await PackageGraph.forThisPackage();
    final assetReader = FileBasedAssetReader(packageGraph);

    for (final package in packageGraph.allPackages.keys) {
      // we need this as a marker that this package has summer generators
      final configAssets =
          await assetReader.findAssets(Glob("summer_extension_generator.yaml"), package: package).toList();
      if (configAssets.isEmpty) {
        continue;
      }

      final dartAssets = await assetReader
          .findAssets(Glob("*", recursive: true), package: package)
          .where((asset) => asset.extension == ".dart")
          .toList();

      for (final dartAsset in dartAssets) {
        final library = await buildStep.resolver.libraryFor(dartAsset);
        final libraryReader = LibraryReader(library);

        final builderElements = libraryReader.allElements.where((element) {
          final isClass = element is ClassElement;
          if (!isClass) {
            return false;
          }

          return (element as ClassElement)
              .interfaces
              .any((interface) => _builderInterfaceChecker.isAssignableFromType(interface));
        });

        final libraryMirror = await currentMirrorSystem().isolate.loadUri(Uri.parse(library.identifier));

        final libraryBuilders = builderElements.map(
          (builderElement) {
            final builderMirror = libraryMirror.declarations[Symbol(builderElement.name!)] as ClassMirror;
            return builderMirror.newInstance(Symbol.empty, []).reflectee as SummerExtensionBuilder;
          },
        );

        _extensionBuilders.addAll(libraryBuilders);
      }
    }
  }
}
