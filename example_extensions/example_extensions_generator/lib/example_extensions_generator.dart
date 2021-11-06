library example_extensions_generator;

import 'package:build/build.dart';
import 'package:example_extensions_generator/src/example_extensions_generator_base.dart';
import 'package:example_extensions_lib/example_extensions_lib.dart';
import 'package:summer_generator/summer_generator.dart';

export 'src/example_extensions_generator_base.dart';

Builder timedBuilder(BuilderOptions options) => SummerAnnotationBuilder<Timed>(
      'timed',
      TimedGenerator(),
      {
        "^lib/{{}}.dart": ["lib/generated/{{}}.timed.dart"]
      },
    );

Builder paramLoggedBuilder(BuilderOptions options) => SummerAnnotationBuilder<ParamLogged>(
      'paramLogged',
      ParamLoggedGenerator(),
      {
        "^lib/{{}}.dart": ["lib/generated/{{}}.paramLogged.dart"]
      },
    );
