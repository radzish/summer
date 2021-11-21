class Timed {
  const Timed._();
}

const timed = Timed._();

class ParamLogged {
  const ParamLogged._();
}

const paramLogged = ParamLogged._();

class DbQuery {
  final String query;

  const DbQuery(this.query);
}
