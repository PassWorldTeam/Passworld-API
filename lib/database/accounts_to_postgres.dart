import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:postgres/postgres.dart';

/* 🟥 🟧 🟨 🟩 🟦 🟪 🟫 ⬛ ⬜ */

class AccountsToPostgres {
  static final connection = PostgreSQLConnection("localhost", 5432, 'passworld',
      username: 'pass', password: '1p2a3s4s5');

  /* Dev RemRem */
  // static final connection = PostgreSQLConnection("localhost", 5432, 'passworld',
  //     username: 'hel', password: '');

  /* Error severity:
      - error : no user
      - unknown : DB logic problem
  */

  /* Production */
  /*static final connection = PostgreSQLConnection(
      Platform.environment["DB_SERVER"]!,
      5432,
      Platform.environment["DB_DATABASE"]!,
      username: Platform.environment["DB_USER"],
      password: Platform.environment["DB_PASSWORD"]);
  */
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
    await initLogs();
  }

  // Create user account
  static Future<void> createAccount(
      String mail, String hash, String salt) async {
    await connection.query(
        "INSERT INTO \"Account\" VALUES(nextval('plus1id'),@mail,@hash,@salt)",
        substitutionValues: {"mail": mail, "hash": hash, "salt": salt});
  }

  // get user passord hash by mail
  static Future<String> selectHashByMail(String mail) async {
    List<List<dynamic>> results = await connection.query(
        "SELECT hash FROM \"Account\" WHERE mail=@mail",
        substitutionValues: {"mail": mail});

    if (results.length < 1) {
      throw PostgreSQLException("No user for this id",
          severity: PostgreSQLSeverity.error);
    }
    if (results.length > 1) {
      throw PostgreSQLException("WARNING ! : multiple user with this id",
          severity: PostgreSQLSeverity.unknown);
    }
    return results[0][0];
  }

  // check if mail is already used in database
  static Future<String> selectMailByMail(String mail) async {
    List<List<dynamic>> results = await connection.query(
        "SELECT mail FROM \"Account\" WHERE mail=@mail",
        substitutionValues: {"mail": mail});

    return results[0][0];
  }

  static Future<List<Int>> selectPassFileById(String id) async {
    List<List<dynamic>> results = await connection.query(
        "SELECT passwords FROM \"Account\" WHERE id=@identifiant",
        substitutionValues: {"identifiant": id});

    if (results.length < 1) {
      throw PostgreSQLException("No user for this id",
          severity: PostgreSQLSeverity.error);
    }
    if (results.length > 1) {
      throw PostgreSQLException("WARNING ! : multiple user with this id",
          severity: PostgreSQLSeverity.unknown);
    }

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

  static Future<void> deleteAccount(String mail) async {
    var deletion = 1;
    await connection.query("DELETE FROM \"Account\" WHERE mail=@mail",
        substitutionValues: {"mail": mail});

    try {
      selectHashByMail(mail);
    } on PostgreSQLException catch (e) {
      if (e.severity == PostgreSQLSeverity.error) {
        deletion = 0;
      }
    }

    if (deletion == 1) {
      throw PostgreSQLException("User not deleted",
          severity: PostgreSQLSeverity.unknown);
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

  //
  // ADMIN
  //

  static Future<PostgreSQLResult> getAllUsers() async {
    PostgreSQLResult res =
        await connection.query("SELECT id, hash, salt from \"Account\"");
    print("🟥 ADMIN: get all users");
    return res;
  }

  static Future<void> flushUsers() async {
    await connection.query("DELETE FROM \"Account\" ");

    List<List<dynamic>> rows =
        await connection.query("SELECT COUNT(*) FROM \"Account\" ");

    if (rows[0][0] != 0) {
      throw PostgreSQLException("Flush of users did not succeed",
          severity: PostgreSQLSeverity.unknown);
    }

    print("🟥 ADMIN: all users deleted");
  }

  static Future<void> flushTable() async {
    await connection.query("DROP TABLE \"Account\" ");

    try {
      await connection.query("SELECT * FROM \"Account\" ");
      throw PostgreSQLException('Table Not dropped',
          severity: PostgreSQLSeverity.unknown);
    } on PostgreSQLException {
      print("🟥 ADMIN: tables droped");
    }
  }

  static Future<void> createLogsTable() async {
    await connection
        .query(
            "CREATE TABLE IF NOT EXISTS Log(wwhen TIMESTAMP,wwho char(20),whow char(20),wwhat varchar(800));")
        .then((value) {
      print("⬜ ADMIN: Logs table created");
    });
  }

  static Future<void> createLogingFunction() async {
    await connection
        .query(
            "CREATE OR REPLACE FUNCTION log()RETURNS TRIGGER AS \$\$ BEGIN IF(TG_OP='DELETE')THEN INSERT INTO Log VALUES(CURRENT_TIMESTAMP,current_role,TG_OP,OLD.id||' '||OLD.hash||' '||OLD.salt); RETURN OLD; ELSEIF(TG_OP='INSERT')THEN INSERT INTO Log VALUES(CURRENT_TIMESTAMP,current_role,TG_OP,NEW.id||' '||NEW.hash||' '||NEW.salt);RETURN NEW; ELSE INSERT INTO Log VALUES(CURRENT_TIMESTAMP,current_role,TG_OP,OLD.id||' '||OLD.hash||' '||OLD.salt||' => '||NEW.id||' '||NEW.hash||' '||NEW.salt); RETURN NEW; END IF; END; \$\$ LANGUAGE plpgsql;")
        .then((value) {
      print("⬜ ADMIN: Logs function created");
    });
  }

  static Future<void> createTriggerLogs() async {
    await connection
        .query(
            "CREATE TRIGGER trace_delete BEFORE DELETE OR INSERT OR UPDATE ON \"Account\" FOR EACH ROW EXECUTE FUNCTION log ();")
        .then((value) {
      print("⬜ ADMIN: Logs trigger created");
    });
  }

  static Future<void> dropTrggerLogs() async {
    await connection
        .query("DROP Trigger trace_delete ON \"Account\" ")
        .then((value) {
      print("⬛  ADMIN: Logs trigger dropped");
    });
  }

  static Future<void> flushLogs() async {
    await connection.query("DELETE FROM Log").then((value) {
      print("⬛  ADMIN: Logs flushed");
    });
  }

  static Future<void> initLogs() async {
    await createLogsTable();
    await createLogingFunction();
    createTriggerLogs();
  }
}
