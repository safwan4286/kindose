// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:math' as math;

import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/asymmetric/api.dart';

class Encryption {
  static Encryption? _instance;

  Encryption._internal();

  static Encryption get instance {
    _instance ??= Encryption._internal();
    return _instance!;
  }

  /// used to know the status whether encryption enabled or not
  bool status = true;

  String apiSecret = "\$^_n!@e*&t_*&%r!_*@y1#*2^_*!@";

  Future<String> encryptData({
    required String data,
    required AesTreasure aesTreasure,
  }) async {
    Stopwatch stopwatch = Stopwatch()..start();

    String aesEncryptedText = await _aesEncrypt(
      data: data,
      aesTreasure: aesTreasure,
    );
    stopwatch.stop();
    return aesEncryptedText;
  }

  Future<String> _aesEncrypt({
    required String data,
    required AesTreasure aesTreasure,
  }) async {
    final key = enc.Key.fromUtf8(aesTreasure.key);
    final iv = enc.IV.fromUtf8(aesTreasure.iv);

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(data, iv: iv);

    String divider = "XmQpNzEkLoVuB";
    String keyIvRsaEncrypted = await _rsaEncryption(
      aesEncryptedText: "${aesTreasure.key}${aesTreasure.iv}",
    );
    return "$keyIvRsaEncrypted$divider${encrypted.base64}";
  }

  Future<String> _rsaEncryption({required String aesEncryptedText}) async {
    String publicKeyString =
        '''-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAqt+YpePb8hP7lmUmYxNlsmSXSKj1HyaND33d8syjfNOYDg6OpiS3yb+bu84J6OWJQ38x8b/+C2u1Kqz+Umbgag2rIE8seS0kes9Sv+JrcrpuZuPjCihD4qmb7ZgykDjHSsWyOiW6yuUESFFa8+fvgpa71OEffJHZp1emKSUgMeqPHS9Nd2T4Cz/+l5E0cvzwaSD1FttC7FiMtEsQqwRzAaqb/rEA8qom56r06kc4dWJWDzTkRTwP3Qn+gd0J3/3Bqv6q9Mv3a2uUShCC02t6y+1szR8ZpMVHNoTOw8LhSxpLYn3+eZZeERhwCpp/WdgMxww7M4pNHS5j+rYu047uOQIDAQAB\n-----END PUBLIC KEY-----''';

    enc.RSAKeyParser keyParser = enc.RSAKeyParser();

    RSAAsymmetricKey publicKeyParser = keyParser.parse(publicKeyString);
    final publicKey = RSAPublicKey(
      publicKeyParser.modulus!,
      publicKeyParser.exponent!,
    );

    final encrypter = enc.Encrypter(enc.RSA(publicKey: publicKey));

    final encrypted = encrypter.encrypt(aesEncryptedText);
    return encrypted.base64;
  }

  Future<String> aesDecrypt({
    required String data,
    required AesTreasure aesTreasure,
  }) async {
    Stopwatch stopwatch = Stopwatch()..start();

    final key = enc.Key.fromUtf8(aesTreasure.key);
    final iv = enc.IV.fromUtf8(aesTreasure.iv);

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final decrypted = encrypter.decrypt64(data, iv: iv);

    stopwatch.stop();
    return decrypted;
  }

  Future<String> onlyAESEncryption({
    required String data,
    required String keyInString,
    required String ivInString,
  }) async {
    final key = enc.Key.fromUtf8(keyInString);
    final iv = enc.IV.fromUtf8(ivInString);

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(data, iv: iv);

    return encrypted.base64;
  }

  Future<String> decryptData({
    required String data,
    required AesTreasure aesTreasure,
  }) async {
    String sepratedData;
    String divider = "XmQpNzEkLoVuB";

    if (data.contains(divider)) {
      var tempData = data.split(divider);
      sepratedData = tempData[1];
    } else {
      sepratedData = data;
    }

    final key = enc.Key.fromUtf8(aesTreasure.key);
    final iv = enc.IV.fromUtf8(aesTreasure.iv);

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final decrypted = encrypter.decrypt64(sepratedData, iv: iv);

    return decrypted;
  }

  String _randomString() {
    String chars1 =
        "qwe=rtyui=op!lm@n=b#vcxz%=as^dfg&hj=k*lQWE=RTYUIOPL=MNBVCX=ZASDFG=HJKL12=3456=7=89";
    StringBuffer sb1 = StringBuffer();
    math.Random random1 = math.Random();
    for (int i = 0; i < 10; i++) {
      String c1 = chars1[random1.nextInt(chars1.length)];
      sb1.write(c1);
    }
    return sb1.toString();
  }

  String _generateString(String jsonData) {
    Base64Codec BASE64 = const Base64Codec();
    String randomString1 = _randomString();
    String randomString2 = _randomString();

    var bytesData = utf8.encode(jsonData);
    String jsonDatabase64 = BASE64.encode(bytesData);

    String Encodedbase64String = randomString1 + jsonDatabase64 + randomString2;

    var bytesInLatin1 = utf8.encode(Encodedbase64String);
    return BASE64.encode(bytesInLatin1);
  }

  final String _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final math.Random _rnd = math.Random();

  String getRandomString(int length) => String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length)),
    ),
  );
}

class AesTreasure {
  final String key;
  final String iv;

  const AesTreasure({required this.key, required this.iv});
}
