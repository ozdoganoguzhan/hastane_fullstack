import 'dart:async';
import 'package:flutter/widgets.dart';

/// Hafif servis-locator + reaktif state yöneticisi.
///
/// alal_mobile projesindeki `StateManager` mimarisinin sade bir uyarlamasıdır.
/// 3. parti state kütüphanesi (BLoC, Riverpod, Provider) KULLANILMAZ.
///
/// Kısayollar:
///   `$get<T>()`      -> kayıtlı servisi al
///   `$state<T>()`    -> tip bazlı ReactiveState al
///   `$set<T>(value)` -> tip bazlı state değerini yaz
class StateManager {
  StateManager._();
  static final StateManager _instance = StateManager._();
  static StateManager get instance => _instance;

  final Map<Type, dynamic> _services = {};
  final Map<Type, ReactiveState<dynamic>> _states = {};

  // === Service Locator ===

  void register<T extends Object>(T service) => _services[T] = service;

  void registerLazy<T extends Object>(T Function() factory) =>
      _services[T] = _LazyService<T>(factory);

  T get<T extends Object>() {
    final service = _services[T];
    if (service == null) {
      throw StateError(
        'Service of type $T not registered. Call register<$T>() first.',
      );
    }
    if (service is _LazyService<T>) {
      final instance = service.getInstance();
      _services[T] = instance;
      return instance;
    }
    return service as T;
  }

  T? tryGet<T extends Object>() {
    final service = _services[T];
    if (service == null) return null;
    if (service is _LazyService<T>) {
      final instance = service.getInstance();
      _services[T] = instance;
      return instance;
    }
    return service as T;
  }

  bool isRegistered<T extends Object>() => _services.containsKey(T);

  // === Reactive State ===

  ReactiveState<T> state<T>([T? initialValue]) {
    if (!_states.containsKey(T)) {
      _states[T] = ReactiveState<T>(initialValue);
    }
    return _states[T] as ReactiveState<T>;
  }

  void set<T>(T value) => state<T>().value = value;

  T? getValue<T>() => state<T>().value;

  void reset() {
    for (final service in _services.values) {
      if (service is IDisposable) service.dispose();
    }
    for (final state in _states.values) {
      state.dispose();
    }
    _services.clear();
    _states.clear();
  }
}

/// Değişiklikleri dinleyicilere ve broadcast stream'e yayan reaktif değer.
class ReactiveState<T> {
  T? _value;
  final List<void Function(T? value)> _listeners = [];
  final StreamController<T?> _streamController =
      StreamController<T?>.broadcast();

  ReactiveState([this._value]);

  T? get value => _value;

  set value(T? newValue) {
    if (_value != newValue) {
      _value = newValue;
      _notify();
    }
  }

  void refresh() => _notify();

  void update(T Function(T? current) updater) => value = updater(_value);

  Stream<T?> get stream => _streamController.stream;

  void addListener(void Function(T? value) listener) =>
      _listeners.add(listener);

  void removeListener(void Function(T? value) listener) =>
      _listeners.remove(listener);

  void _notify() {
    for (final listener in List.of(_listeners)) {
      listener(_value);
    }
    if (!_streamController.isClosed) _streamController.add(_value);
  }

  void dispose() {
    _listeners.clear();
    _streamController.close();
  }
}

/// register edilen servis bunu implement ederse reset sırasında dispose edilir.
abstract interface class IDisposable {
  void dispose();
}

class _LazyService<T> {
  final T Function() _factory;
  T? _instance;
  _LazyService(this._factory);
  T getInstance() => _instance ??= _factory();
}

// === Top-level kısayollar ===

// ignore: non_constant_identifier_names
StateManager get SM => StateManager.instance;

T $get<T extends Object>() => SM.get<T>();

ReactiveState<T> $state<T>([T? initialValue]) => SM.state<T>(initialValue);

void $set<T>(T value) => SM.set<T>(value);

/// `state.builder((value) => Widget)` -> StreamBuilder kısayolu.
extension ReactiveStateBuilder<T> on ReactiveState<T> {
  StreamBuilder<T?> builder(Widget Function(T? value) build) {
    return StreamBuilder<T?>(
      stream: stream,
      initialData: value,
      builder: (context, snapshot) => build(snapshot.data),
    );
  }
}
