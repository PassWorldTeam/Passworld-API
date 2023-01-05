import 'dart:convert';
import 'dart:io';
import 'package:postgres/postgres.dart';

class AccountsToPostgres {
  /* Dev Coco */
  // static final connection = PostgreSQLConnection("localhost", 5432, 'passworld',
  //     username: 'pass', password: '1p2a3s4s5');

  /* Dev RemRem */
  static final connection = PostgreSQLConnection("localhost", 5432, 'passworld',
      username: 'hel', password: '');

  /* Production */
  // static final connection = PostgreSQLConnection(
  //     Platform.environment["DB_SERVER"]!,
  //     5432,
  //     Platform.environment["DB_DATABASE"]!,
  //     username: Platform.environment["DB_USER"],
  //     password: Platform.environment["DB_PASSWORD"]);

  AccountsToPostgres() {
    //initConnection();
  }

  static Future<void> openConnection() async {
    await connection.open().then((value) {
      print("🟢 PassWorld DB connection opened");
    });
  }

  static void closeConnection() async {
    connection.close().then((value) {
      print("🔴 PassWorld DB connection closed");
    });
  }

  static Future<void> createAccountTable() async {
    await openConnection();
    await connection.query("""
    CREATE TABLE IF NOT EXISTS \"Account\"(
              id INT PRIMARY KEY,
              mail TEXT NOT NULL UNIQUE,
              hash TEXT NOT NULL,
              salt TEXT NOT NULL,
              twofa VARCHAR(50)[],
              password_file INTEGER[]
              )""");

    await connection.query("""
    CREATE SEQUENCE IF NOT EXISTS plus1id
    INCREMENT 1
    START 1""");

    print("🟦 Account Table Created");
  }

  // Add support for twoFa if needed
  static Future<void> createAccount(
      String mail, String hash, String salt /*, List<String> twoFaStr*/) async {
    await checkMailAlreadyExist(mail); // TODO: throw execption if != null
    await connection.query(
        "INSERT INTO \"Account\" VALUES(nextval('plus1id'),@mail,@hash,@salt)",
        substitutionValues: {
          "mail": mail,
          "hash": hash,
          "salt": salt /*,
          "twofa": twoFaStr*/
        });
    print("✅ Account succesfully created");
  }

  static Future<String> selectHashByMail(String mail) async {
    List<List<dynamic>> results = await connection.query(
        "SELECT hash FROM \"Account\" WHERE mail=@mail",
        substitutionValues: {"mail": mail});

    return results[0][0];
  }

  static Future<void> checkMailAlreadyExist(String mail) async {
    List<List<dynamic>> results = await connection.query(
        "SELECT id FROM \"Account\" WHERE mail=@mail",
        substitutionValues: {"mail": mail});
    print(results[0][0]);

    return;
  }

  static Future<void> updatePass(String mail, String hash, String salt) async {
    if (selectHashByMail(mail) == null) {
      return;
    } else {
      await connection.query(
          "UPDATE \"Account\" SET hash=@hash, salt=@salt WHERE mail=@mail",
          substitutionValues: {"mail": mail, "hash": hash, "salt": salt});
    }
  }

  static Future<void> updateFilePass(String mail, File passwordFile) async {
    List<int> passwordBlob =
        utf8.encode(await passwordFile.readAsString(encoding: utf8));

    if (selectHashByMail(mail) == null) {
      return;
    } else {
      await connection.query(
          "UPDATE \"Account\" SET passwords=@p WHERE id=@identifiant",
          substitutionValues: {"identifiant": mail, "p": passwordBlob});
    }
  }

  static Future<void> updateTwoFa(String mail, List<String> tfa) async {
    List<String> twoFaStr = List.empty(growable: true);

    if (selectHashByMail(mail) == null) {
      return;
    } else {
      await connection.query(
          "UPDATE \"Account\" SET twofa=@tfa WHERE id=@identifiant",
          substitutionValues: {"identifiant": mail, "tfa": tfa});
    }
  }

  static Future<void> updateMail(String mail, String newMail) async {
    if (selectHashByMail(mail) == null) {
      return;
    } else {
      await connection.query(
          "UPDATE \"Account\" SET mail=@newMail WHERE mail=@mail",
          substitutionValues: {"newMail": newMail, "mail": mail});
    }
    print("✅ Mail succesfully updated");
  }

  static Future<void> deleteById(String id) async {
    await connection.query("DELETE FROM \"Account\" WHERE id=@identifiant",
        substitutionValues: {"identifiant": id});
  }

  //
  // ADMIN
  //

  static Future<PostgreSQLResult> getAllUsers() async {
    PostgreSQLResult res =
        await connection.query("SELECT id, hash, salt from \"Account\"");
    print("🟥 ADMIN: get all users");
    return res;
  }
}
