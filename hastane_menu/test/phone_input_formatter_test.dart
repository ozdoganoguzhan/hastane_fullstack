import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hastane_menu/core/utils/phone_input_formatter.dart';

/// Kullanıcının alana yazdığını taklit eder: verilen metni formatter'dan
/// geçirip ekranda görünecek hâli döner.
String typed(String raw) {
  const formatter = TurkishPhoneInputFormatter();
  return formatter
      .formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(
          text: raw,
          selection: TextSelection.collapsed(offset: raw.length),
        ),
      )
      .text;
}

void main() {
  group('digitsOf — normalizasyon', () {
    test('sade 10 hane olduğu gibi kalır', () {
      expect(TurkishPhoneInputFormatter.digitsOf('5321234567'), '5321234567');
    });

    test('başındaki 0 atılır', () {
      expect(TurkishPhoneInputFormatter.digitsOf('05321234567'), '5321234567');
    });

    test('+90 / 90 ülke kodu atılır', () {
      expect(TurkishPhoneInputFormatter.digitsOf('+905321234567'), '5321234567');
      expect(TurkishPhoneInputFormatter.digitsOf('905321234567'), '5321234567');
    });

    test('biçimlenmiş metin tekrar okunabilir (idempotent)', () {
      expect(TurkishPhoneInputFormatter.digitsOf('532 123 45 67'), '5321234567');
    });

    test('10 haneden fazlası KESİLİR — asıl şikâyet buydu', () {
      expect(
        TurkishPhoneInputFormatter.digitsOf('53212345679999999999'),
        '5321234567',
      );
    });

    test('harf ve semboller yok sayılır', () {
      expect(TurkishPhoneInputFormatter.digitsOf('(532) 123-45-67'), '5321234567');
      expect(TurkishPhoneInputFormatter.digitsOf('abc'), '');
    });

    test('5 ile başlama ZORUNLU DEĞİL — sadece 0 engellenir', () {
      expect(TurkishPhoneInputFormatter.digitsOf('2121234567'), '2121234567');
      expect(TurkishPhoneInputFormatter.digitsOf('4441234567'), '4441234567');
    });

    test('kullanıcı başa 0 koyamaz (+90 öneki zaten var)', () {
      expect(TurkishPhoneInputFormatter.digitsOf('0'), '');
      expect(TurkishPhoneInputFormatter.digitsOf('00'), '');
      expect(TurkishPhoneInputFormatter.digitsOf('02121234567'), '2121234567');
    });

    test('90 ile başlayan 10 haneli değer kırpılmaz', () {
      // 10 haneyi aşmadığı için ülke kodu sayılmamalı.
      expect(TurkishPhoneInputFormatter.digitsOf('9012345678'), '9012345678');
    });
  });

  group('format — görünüm', () {
    test('kademeli yazımda gruplar oluşur', () {
      expect(typed('5'), '5');
      expect(typed('532'), '532');
      expect(typed('5321'), '532 1');
      expect(typed('532123'), '532 123');
      expect(typed('5321234'), '532 123 4');
      expect(typed('53212345'), '532 123 45');
      expect(typed('532123456'), '532 123 45 6');
      expect(typed('5321234567'), '532 123 45 67');
    });

    test('fazla hane girilemez', () {
      expect(typed('532123456789999'), '532 123 45 67');
    });

    test('yapıştırılan uluslararası biçim düzelir', () {
      expect(typed('+90 532 123 45 67'), '532 123 45 67');
    });

    test('boş giriş boş kalır', () {
      expect(typed(''), '');
    });
  });

  group('imleç', () {
    test('sona yazarken imleç metnin sonunda kalır', () {
      const formatter = TurkishPhoneInputFormatter();
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '5321',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      expect(result.text, '532 1');
      // 4 hane girildi → imleç 4. hanenin ardında (boşluk atlanarak).
      expect(result.selection.baseOffset, 5);
    });

    test('ortadan düzenlemede imleç hane sayısını takip eder', () {
      const formatter = TurkishPhoneInputFormatter();
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: '532 123 45 67'),
        const TextEditingValue(
          text: '5329 123 45 67', // 4. haneden sonra '9' eklendi
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      expect(result.text, '532 912 34 56');
      expect(result.selection.baseOffset, 5); // "532 9" → 4 hane geçildi
    });
  });
}
