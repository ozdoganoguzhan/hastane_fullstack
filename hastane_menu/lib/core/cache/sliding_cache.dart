import 'package:hastane_menu/core/constants/app_config.dart';

/// Kayan süreli (sliding expiration) **bellek içi** önbellek.
///
/// Her okumada süre sıfırlanır; [ttl] boyunca hiç dokunulmayan kayıt düşer ve
/// bir sonraki istekte kaynaktan yeniden çekilir. Amaç: her ekran açılışında
/// HBYS'ye istek atmamak.
///
/// ⚠️ Yalnızca bellektedir — diske yazılmaz. Uygulama kapanınca temizlenir;
/// böylece ağ dışında (hastane WiFi'ı yokken) eski veri gösterilmez
/// (bkz. AGENTS.md §4.0 — offline/gömülü veri konulmaz).
class SlidingCache<K, V> {
  SlidingCache({Duration? ttl}) : ttl = ttl ?? AppConfig.cacheSlidingExpiration;

  final Duration ttl;
  final Map<K, _Entry<V>> _entries = {};

  /// Geçerli kayıt varsa döner ve süresini sıfırlar; yoksa `null`.
  V? get(K key) {
    final entry = _entries[key];
    if (entry == null) return null;

    if (DateTime.now().isAfter(entry.expiresAt)) {
      _entries.remove(key);
      return null;
    }

    // Sliding: erişim süreyi tazeler.
    entry.expiresAt = DateTime.now().add(ttl);
    return entry.value;
  }

  void set(K key, V value) {
    _entries[key] = _Entry(value, DateTime.now().add(ttl));
    _prune();
  }

  /// Önbellekte varsa onu, yoksa [loader] ile üretip saklayarak döner.
  Future<V> getOrLoad(K key, Future<V> Function() loader) async {
    final cached = get(key);
    if (cached != null) return cached;

    final value = await loader();
    set(key, value);
    return value;
  }

  void remove(K key) => _entries.remove(key);

  void clear() => _entries.clear();

  void _prune() {
    final now = DateTime.now();
    _entries.removeWhere((_, entry) => now.isAfter(entry.expiresAt));
  }
}

class _Entry<V> {
  _Entry(this.value, this.expiresAt);
  final V value;
  DateTime expiresAt;
}
