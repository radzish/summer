import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:source_gen/source_gen.dart';
import 'package:summer_core/summer_core.dart';
import 'package:summer_generator/src/summer_generator_impl.dart';

export 'src/summer_generator_api.dart';

final componentChecker = TypeChecker.fromRuntime(Component);
final formatter = DartFormatter();

Builder summerBuilder(BuilderOptions _) => SummerBuilder();
