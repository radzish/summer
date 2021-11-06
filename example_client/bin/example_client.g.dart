// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// SummerGenerator
// **************************************************************************

class _ComponentA extends ComponentA with _ComponentA_timed_doComponentAJob {}

mixin _ComponentA_timed_doComponentAJob on ComponentA {
  @override
  void doComponentAJob() {
    final stopwatch = Stopwatch()..start();
    super.doComponentAJob();
    print('timed ComponentB.doComponentBJob: ${stopwatch.elapsed}');
  }
}

class _ComponentB extends ComponentB with _ComponentB_timed_doComponentBJob {}

mixin _ComponentB_timed_doComponentBJob on ComponentB {
  @override
  void doComponentBJob(String param) {
    final stopwatch = Stopwatch()..start();
    super.doComponentBJob(param);
    print('timed ComponentB.doComponentBJob: ${stopwatch.elapsed}');
  }
}
