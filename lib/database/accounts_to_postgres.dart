import 'dart:convert';
import 'dart:io';
import 'package:postgres/postgres.dart';

class AccountsToPostgres {
  /* Dev
  final connection = PostgreSQLConnection("localhost", 5432, 'passworld',
      username: 'pass', password: '1p2a3s4s5');
  */

  // Production
  final connection = PostgreSQLConnection(Platform.environment["DB_SERVER"]!,
      5432, Platform.environment["DB_DATABASE"]!,
      username: Platform.environment["DB_USER"],
      password: Platform.environment["DB_PASSWORD"]);

  AccountsToPostgres() {
    initConnection();
  }

  void initConnection() async {
    await connection.open().then((value) {
      print("PostgreSQL connection opened");
    });
  }

  @override
  void create(
      String email, String hash, String salt, List<String> twoFaStr) async {
    connection.query(
        "INSERT INTO \"Account\" VALUES(@id,@hash,@salt,@twofa,@passwords)",
        substitutionValues: {
          "id": email,
          "hash": hash,
          "salt": salt,
          "twofa": twoFaStr
        });
    print("Account succesfully created");
  }

  @override
  Future<String> selectHashById(String id) async {
    List<List<dynamic>> results = await connection.query(
        "SELECT hash FROM \"Account\" WHERE id=@identifiant",
        substitutionValues: {"identifiant": id});

    return results[0][0];
  }

  @override
  void updatePass(String identifiant, String hash, String salt) async {
    if (selectHashById(identifiant) == null) {
      return;
    } else {
      await connection.query(
          "UPDATE \"Account\" SET hash=@h, salt=@s  WHERE id=@identifiant",
          substitutionValues: {
            "identifiant": identifiant,
            "h": hash,
            "s": salt
          });
    }
  }

  @override
  void updateFilePass(String identifiant, File passwordFile) async {
    List<int> passwordBlob =
        utf8.encode(await passwordFile.readAsString(encoding: utf8));

    if (selectHashById(identifiant) == null) {
      return;
    } else {
      await connection.query(
          "UPDATE \"Account\" SET passwords=@p WHERE id=@identifiant",
          substitutionValues: {"identifiant": identifiant, "p": passwordBlob});
    }
  }

  @override
  void updateTwoFa(String identifiant, List<String> tfa) async {
    List<String> twoFaStr = List.empty(growable: true);

    if (selectHashById(identifiant) == null) {
      return;
    } else {
      await connection.query(
          "UPDATE \"Account\" SET twofa=@tfa WHERE id=@identifiant",
          substitutionValues: {"identifiant": identifiant, "tfa": tfa});
    }
  }

  @override
  void DeleteById(String id) async {
    await connection.query("DELETE FROM \"Account\" WHERE id=@identifiant",
        substitutionValues: {"identifiant": id});
  }
}
