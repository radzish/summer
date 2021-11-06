// import 'dart:mirrors';
//
// import 'package:example_extensions_lib/src/exp_lib.dart';
//
// Future<void> main() async {
//   // final graph = await PackageGraph.forThisPackage();
//   //
//   // // //TODO: find all packages having summer_extensions_generator.yaml in it
//   // // final generatorPackage = graph.allPackages['example_extensions_generator'];
//   // // print(generatorPackage);
//   //
//   // final assetReader = FileBasedAssetReader(graph);
//   // final assets = await assetReader.findAssets(Glob("summer_extension_generator.yaml"), package: "example_extensions_generator").toList();
//   // print(assets);
//   //
//
//   final libraryMirror =
//       await currentMirrorSystem().isolate.loadUri(Uri.parse("package:example_extensions_lib/src/exp_lib.dart"));
//   final classMirror = libraryMirror.declarations[Symbol("Checker")] as ClassMirror;
//   final instance = classMirror.newInstance(Symbol.empty, []).reflectee as Checker;
//
//   instance.check();
// }
