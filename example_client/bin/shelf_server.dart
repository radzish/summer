import 'package:example_client/generated/summer.dart';
import 'package:example_extensions_lib/example_extensions_lib.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:summer_core/summer_core.dart';

Future<void> main(List<String> arguments) async {
  final summerShelf = summer<SummerShelf>();

  await summerShelf.start();

  // var app = Router();
  //
  // app.get('/hello', (Request request) {
  //   return Response.ok('hello-world');
  // });
  //
  // app.get('/user/<user>', (Request request, String user) {
  //   return Response.ok('hello $user');
  // });
  //
  // var handler = Pipeline().addHandler(app);
  //
  // await io.serve(handler, 'localhost', 8080);
}
