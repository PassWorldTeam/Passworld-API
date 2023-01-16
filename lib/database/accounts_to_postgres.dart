import 'dart:convert';
import 'dart:io';
import 'package:postgres/postgres.dart';

class AccountsToPostgres {
  /* Dev Coco */
  // static final connection = PostgreSQLConnection("localhost", 5432, 'passworld',
  //     username: 'pass', password: '1p2a3s4s5');

  /* Dev RemRem */
  // static final connection = PostgreSQLConnection("localhost", 5432, 'passworld',
  //     username: 'hel', password: '');

  /* Production */
  static final connection = PostgreSQLConnection(
      Platform.environment["DB_SERVER"]!,
      5432,
      Platform.environment["DB_DATABASE"]!,
      username: Platform.environment["DB_USER"],
      password: Platform.environment["DB_PASSWORD"]);

  AccountsToPostgres() {
    //initConnection();
  }

  // Open connection to database
  static Future<void> openConnection() async {
    await connection.open().then((value) {
      print("🟢 PassWorld DB connection opened");
    });
  }

  // Close connection to database
  static void closeConnection() async {
    connection.close().then((value) {
      print("🔴 PassWorld DB connection closed");
    });
  }

  // Create tables and other things for the database
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

  // Create user account
  static Future<void> createAccount(
      String mail, String hash, String salt) async {
    await connection.query(
        "INSERT INTO \"Account\" VALUES(nextval('plus1id'),@mail,@hash,@salt)",
        substitutionValues: {"mail": mail, "hash": hash, "salt": salt});
  }

  static Future<void> deleteAccount(String mail) async {
    await connection.query("DELETE FROM \"Account\" WHERE mail=@mail",
        substitutionValues: {"mail": mail});
  }

  // get user passord hash by mail
  static Future<String> selectHashByMail(String mail) async {
    List<List<dynamic>> results = await connection.query(
        "SELECT hash FROM \"Account\" WHERE mail=@mail",
        substitutionValues: {"mail": mail});

    return results[0][0];
  }

  // check if mail is already used in database
  static Future<String> selectMailByMail(String mail) async {
    List<List<dynamic>> results = await connection.query(
        "SELECT mail FROM \"Account\" WHERE mail=@mail",
        substitutionValues: {"mail": mail});

    return results[0][0];
  }

  // Update user password
  static Future<void> updatePassword(
      String mail, String newHash, String newSalt) async {
    if (selectHashByMail(mail) == null) {
      return;
    } else {
      await connection.query(
          "UPDATE \"Account\" SET hash=@newHash and salt=@salt WHERE mail=@mail",
          substitutionValues: {
            "mail": mail,
            "newHash": newHash,
            "newSalt": newSalt
          });
      print("✅ Passworld succesfully updated");
    }
  }

  // Update user password file
  static Future<void> updatePasswordFile(String mail, File passwordFile) async {
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

  // Update user twoFa
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

  // Update user mail
  static Future<void> updateMail(String mail, String newMail) async {
    if (selectHashByMail(mail) == null) {
      return;
    } else {
      await connection.query(
          "UPDATE \"Account\" SET mail=@newMail WHERE mail=@mail",
          substitutionValues: {"newMail": newMail, "mail": mail});
      print("✅ Mail succesfully updated");
    }
  }

  // ADMIN: get infos on all users
  static Future<PostgreSQLResult> getAllUsers() async {
    PostgreSQLResult res =
        await connection.query("SELECT id, hash, salt from \"Account\"");
    print("🟥 ADMIN: get all users");
    return res;
  }
}
