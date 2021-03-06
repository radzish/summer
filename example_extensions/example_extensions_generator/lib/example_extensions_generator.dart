library example_extensions_generator;

import 'package:build/build.dart';
import 'package:example_extensions_generator/src/db_query_generator.dart';
import 'package:example_extensions_generator/src/param_logged_generator.dart';
import 'package:example_extensions_generator/src/timed_generator.dart';
import 'package:example_extensions_lib/example_extensions_lib.dart';
import 'package:summer_generator/summer_generator.dart';

Builder dbQueryBuilder(BuilderOptions options) => SummerAnnotationBuilder<DbQuery>(
      'dbQuery',
      DbQueryGenerator(),
      {
        "^lib/{{}}.dart": ["lib/generated/{{}}.dbQuery.dart"]
      },
    );

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
