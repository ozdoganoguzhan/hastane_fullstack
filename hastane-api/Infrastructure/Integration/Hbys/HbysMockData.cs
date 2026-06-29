using System.Globalization;
using System.Text.Json.Nodes;

namespace Ozi.Infrastructure.Integration.Hbys;

/// <summary>
/// HBYS intranet'ten erişilemediğinde (geliştirme/sunum) örnek veri üretir.
/// Çıktı, gerçek HBYS gövdesiyle birebir aynı alan adlarını kullanır.
/// </summary>
public static class HbysMockData
{
    private static readonly string[] Breakfast =
    [
        "BEYAZ PEYNİR (95 kcal)", "YEŞİL ZEYTİN (85 kcal)", "KAKAOLU FINDIK KREMASI (173 kcal)",
        "ÇAY (77 kcal)", "DOMATES (22 kcal)", "SALATALIK (16 kcal)", "BAL (64 kcal)",
        "TEREYAĞI (102 kcal)", "HAŞLANMIŞ YUMURTA (78 kcal)", "SİYAH ZEYTİN (115 kcal)",
        "MENEMEN (210 kcal)", "SİMİT (250 kcal)"
    ];

    private static readonly string[] Lunch =
    [
        "TERBİYELİ TEL ŞEHRİYE ÇORBA (192 kcal)", "PİLAV ÜSTÜ ET DÖNER (423 kcal)",
        "MEVSİM SALATA (108 kcal)", "AYRAN (64 kcal)", "MERCİMEK ÇORBA (180 kcal)",
        "TAVUK SOTE (320 kcal)", "BULGUR PİLAVI (240 kcal)", "CACIK (90 kcal)",
        "EZOGELİN ÇORBA (160 kcal)", "İZMİR KÖFTE (380 kcal)", "PİRİNÇ PİLAVI (260 kcal)",
        "KOMPOSTO (120 kcal)"
    ];

    private static readonly string[] Dinner =
    [
        "BROKOLİ ÇORBA (147 kcal)", "MANTI (354 kcal)", "BÖRÜLCE SALATASI (270 kcal)",
        "PORTAKAL (98 kcal)", "DOMATES ÇORBA (130 kcal)", "FIRIN TAVUK (290 kcal)",
        "ŞEHRİYELİ PİRİNÇ PİLAVI (250 kcal)", "YOĞURT (60 kcal)", "YAYLA ÇORBA (155 kcal)",
        "KARNIYARIK (340 kcal)", "ELMA (52 kcal)", "İRMİK HELVASI (320 kcal)"
    ];

    public static JsonNode MonthlyMenu(int yil, int ay)
    {
        var data = new JsonArray();

        if (yil < 1 || ay is < 1 or > 12)
            return new JsonObject { ["data"] = data };

        var days = DateTime.DaysInMonth(yil, ay);
        for (var day = 1; day <= days; day++)
        {
            var date = new DateTime(yil, ay, day);
            var record = new JsonObject
            {
                ["id"] = 12000 + ay * 100 + day,
                ["yil"] = yil,
                ["ay"] = ay,
                ["tarih"] = date.ToString("dd.MM.yyyy 00:00:00", CultureInfo.InvariantCulture)
            };

            FillMeal(record, "kahvalti", Breakfast, day, baseId: 500);
            FillMeal(record, "ogle", Lunch, day, baseId: 10000);
            FillMeal(record, "aksam", Dinner, day, baseId: 800);

            data.Add(record);
        }

        return new JsonObject { ["data"] = data };
    }

    private static void FillMeal(JsonObject record, string prefix, string[] pool, int day, int baseId)
    {
        var start = day * 4 % pool.Length;
        for (var slot = 1; slot <= 4; slot++)
        {
            var idx = (start + slot - 1) % pool.Length;
            record[$"{prefix}Y{slot}Id"] = baseId + idx;
            record[$"{prefix}Y{slot}Adi"] = pool[idx];
        }
    }

    public static JsonNode Personnel(string cepTel)
    {
        var digits = new string(cepTel.Where(char.IsDigit).ToArray());
        if (digits.Length < 10)
            return new JsonObject { ["data"] = null, ["present"] = false };

        return new JsonObject
        {
            ["data"] = new JsonObject
            {
                ["adiSoyadi"] = "DEMO PERSONEL",
                ["personelKartNo"] = digits[^10..]
            },
            ["present"] = true
        };
    }
}
