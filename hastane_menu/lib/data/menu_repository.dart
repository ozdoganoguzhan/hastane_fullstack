import 'package:hastane_menu/core/network/api_client.dart';
import 'package:hastane_menu/data/dto/hbys_menu_dto.dart';
import 'package:hastane_menu/data/menu_data.dart';
import 'package:hastane_menu/models/menu_models.dart';

/// Aylık menü kaynağı sözleşmesi. UI bunun arkasındaki kaynağı (dummy/remote)
/// bilmez; [MenuService] üzerinden erişilir.
abstract interface class MenuRepository {
  /// [year]/[month] ayının tüm günlük menüleri.
  Future<List<DailyMenu>> monthlyMenu(int year, int month);
}

/// Backend hazır olana kadar kullanılan dummy kaynak (yerel rotasyon).
///
/// Demo (kullanıcı adı/şifre) oturumda da bu kaynak kullanılır.
class DummyMenuRepository implements MenuRepository {
  const DummyMenuRepository();

  @override
  Future<List<DailyMenu>> monthlyMenu(int year, int month) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return DummyMenuData.month(year, month);
  }
}

/// Kendi REST API'mizden (HBYS proxy) menü çeken gerçek kaynak.
///
/// ⚠️ Endpoint yolu **bize** aittir (`/menu/aylik`); Turkcell'in
/// `/aylik-yemek-listesi/get-kayit-list` yolu DEĞİL. Yanıt gövdesi HBYS ile
/// birebirdir ve [HbysMenuDto] ile parse edilir. Token gerekiyorsa
/// [tokenProvider] ile sağlanır (bkz. §15 — Bearer ~60 dk geçerli).
class RemoteMenuRepository implements MenuRepository {
  RemoteMenuRepository({ApiClient? client, this.tokenProvider})
    : _client = client ?? ApiClient();

  final ApiClient _client;
  final Future<String?> Function()? tokenProvider;

  @override
  Future<List<DailyMenu>> monthlyMenu(int year, int month) async {
    final token = await tokenProvider?.call();
    final json = await _client.getJson(
      '/menu/aylik',
      query: {'yil': year, 'ay': month},
      token: token,
    );
    if (json is Map<String, dynamic>) {
      return HbysMenuDto.listFromResponse(json);
    }
    return const [];
  }
}
