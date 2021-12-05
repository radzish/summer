import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:summer_core/summer_core.dart';

class Get {
  final String route;

  const Get(this.route);
}

class RoutesResolver {
  const RoutesResolver._();
}

const routesResolver = RoutesResolver._();

@component
abstract class SummerShelf {
  @routesResolver
  List<RouteEntry> get routes;

  Future<void> start() async {
    final router = Router();
    for (final route in routes) {
      router.add(route.verb, route.route, route.handler);
    }
    final Pipeline pipeline = Pipeline();
    final handler = pipeline.addHandler(router);
    await io.serve(handler, 'localhost', 8080);
  }
}

typedef RouteHandler = Response Function(Request);

class RouteEntry {
  final String verb;
  final String route;
  final RouteHandler handler;

  RouteEntry(this.verb, this.route, this.handler);
}
