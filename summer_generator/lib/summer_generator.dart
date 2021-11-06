import 'package:build/build.dart';
import 'package:summer_generator/src/summer_generator_impl.dart';

import 'package:source_gen/source_gen.dart';
export 'src/summer_generator_api.dart';

Builder summer(BuilderOptions _) => LibraryBuilder(SummerGenerator());
