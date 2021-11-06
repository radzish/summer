class Summer {
  final Function<T>() resolver;

  const Summer(this.resolver);

  T call<T>() {
    return resolver<T>();
  }
}

class Component {
  const Component._();
}

const component = Component._();

class Application {
  const Application._();
}

const application = Application._();
