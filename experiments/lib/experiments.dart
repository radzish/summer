// import 'package:summer_core/summer_core.dart';

Future<void> main() async {
  final ClassD inst = _ClassD(_ClassC());

  inst.methodD();
}

class ClassA {
  void methodA() {
    print("methodA");
  }
}

class ClassB extends ClassA {
  void methodB() {
    print("methodB");
  }
}

class ClassC extends ClassB {
  void methodC() {
    print("methodC");
  }
}

class ClassD {
  final ClassC classC;

  ClassD(this.classC);

  void methodD() {
    print("methodD");
    classC.methodC();
  }
}

//abstract class example

abstract class ClassE {
  //dbquery annotation to generated impl based on
  void methodE();
}

//hierarchy with abstract class in between

class ClassF {
  void methodF() {
    print("methodF");
  }
}

abstract class ClassG extends ClassF {
  void methodG();
}

// GENERATED //

class _ClassA extends _ClassADecorator {}

abstract class _ClassADecorator implements ClassA {
  final ClassA ref = ClassA();

  void methodA() {
    ref.methodA();
  }
}

class _ClassB extends _ClassBDecorator {}

abstract class _ClassBDecorator extends _ClassA implements ClassB {
  final ClassB ref = ClassB();

  void methodB() {
    ref.methodB();
  }
}

class _ClassC extends _ClassCDecorator with _ClassC_timed_methodC {}

abstract class _ClassCDecorator extends _ClassB implements ClassC {
  final ClassC ref = ClassC();

  void methodC() {
    ref.methodC();
  }
}

mixin _ClassC_timed_methodC on ClassC {
  void methodC() {
    print("timed: before C");
    super.methodC();
    print("timed: after C");
  }
}

class _ClassD extends _ClassDDecorator with _ClassD_logged_methodD, _ClassD_timed_methodD {
  _ClassD(ClassC classC) : super(classC);
}

abstract class _ClassDDecorator implements ClassD {
  _ClassDDecorator(ClassC classC) : ref = ClassD(classC);
  final ClassD ref;

  @override
  ClassC get classC => ref.classC;

  void methodD() {
    ref.methodD();
  }
}

mixin _ClassD_timed_methodD on ClassD {
  void methodD() {
    print("timed: before D");
    super.methodD();
    print("timed: after D");
  }
}

mixin _ClassD_logged_methodD on ClassD {
  void methodD() {
    print("logged: before D");
    super.methodD();
    print("logged: after D");
  }
}

// POC of abstract class implementation

class _ClassE extends _ClassEDecorator with _ClassE_timed_methodE {}

// this is needed only for abstract classes to make their default impl
class _ClassEDefaultImpl extends ClassE with _ClassE_dbquery_methodE {}

abstract class _ClassEDecorator implements ClassE {
  final ClassE ref = _ClassEDefaultImpl();

  void methodE() {
    ref.methodE();
  }
}

// this is needed to implement abstract method
mixin _ClassE_dbquery_methodE on ClassE {
  void methodE() {
    print("dbquery impl");
  }
}

mixin _ClassE_timed_methodE on ClassE {
  void methodE() {
    print("timed: before E");
    super.methodE();
    print("timed: after E");
  }
}

// POC of abstract class extending simple implementation

class _ClassF extends _ClassFDecorator {}

abstract class _ClassFDecorator implements ClassF {
  final ClassF ref = ClassF();

  void methodF() {
    ref.methodF();
  }
}

class _ClassG extends _ClassGDecorator with _ClassG_timed_methodG {}

// this is needed only for abstract classes to make their default impl
class _ClassGDefaultImpl extends ClassG with _ClassG_dbquery_methodG {}

abstract class _ClassGDecorator extends _ClassF implements ClassG {
  final ClassG ref = _ClassGDefaultImpl();

  void methodG() {
    ref.methodG();
  }
}

// this is needed to implement abstract method
mixin _ClassG_dbquery_methodG on ClassG {
  void methodG() {
    print("dbquery impl");
  }
}

mixin _ClassG_timed_methodG on ClassG {
  void methodG() {
    print("timed: before G");
    super.methodG();
    print("timed: after G");
  }
}


// final summer = Summer(<T>() {
//   switch (T) {
//   }
// });
