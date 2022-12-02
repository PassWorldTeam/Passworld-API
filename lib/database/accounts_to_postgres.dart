import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:postgres/postgres.dart';

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

  static Future<void> createAccountTable() async {
    await openConnection();
    await connection
        .query(
            "CREATE TABLE IF NOT EXISTS \"Account\"(id TEXT PRIMARY KEY,hash TEXT NOT NULL,salt TEXT NOT NULL,twofa VARCHAR(50)[],passwords INTEGER[])")
        .then((value) {
      print("🟦 Account Table Created");
    });
  }

  // Add support for twoFa if needed
  static Future<void> create(String email, String hash,
      String salt /*, List<String> twoFaStr*/) async {
    await connection.query("INSERT INTO \"Account\" VALUES(@id,@hash,@salt)",
        substitutionValues: {
          "id": email,
          "hash": hash,
          "salt": salt /*,
          "twofa": twoFaStr*/
        });
    selectHashById(email);//Testing if the user is created
    print("✅ Account succesfully created");
  }

  static Future<String> selectHashById(String id) async {
    List<List<dynamic>> results = await connection.query(
        "SELECT hash FROM \"Account\" WHERE id=@identifiant",
        substitutionValues: {"identifiant": id});
    
    if(results.length<1){
      throw PostgreSQLException("No user for this id",severity: PostgreSQLSeverity.error);
    }
    if(results.length>1){
      throw PostgreSQLException("WARNING ! : multiple user with this id",severity: PostgreSQLSeverity.unknown);
    }
    return results[0][0];
  }

  static Future<List<Int>> selectPassFileById(String id) async {
    List<List<dynamic>> results = await connection.query("SELECT passwords FROM \"Account\" WHERE id=@identifiant",
    substitutionValues: {"identifiant" : id});
    
    if(results.length<1){
      throw PostgreSQLException("No user for this id",severity: PostgreSQLSeverity.error);
    }
    if(results.length>1){
      throw PostgreSQLException("WARNING ! : multiple user with this id",severity: PostgreSQLSeverity.unknown);
    }

    return results[0][0];
  }

  static Future<void> updatePass(
      String identifiant, String hash, String salt) async {
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


  static Future<void> updateFilePass(String identifiant, File passwordFile) async {
    List<int> passwordBlob =utf8.encode(await passwordFile.readAsString(encoding: utf8));

    if (selectHashById(identifiant) == null) {
      return;
    } else {
      await connection.query(
          "UPDATE \"Account\" SET passwords=@p WHERE id=@identifiant",
          substitutionValues: {"identifiant": identifiant, "p": passwordBlob});
    }
  }

  static Future<void> updateTwoFa(String identifiant, List<String> tfa) async {
    List<String> twoFaStr = List.empty(growable: true);

    if (selectHashById(identifiant) == null) {
      return;
    } else {
      await connection.query(
          "UPDATE \"Account\" SET twofa=@tfa WHERE id=@identifiant",
          substitutionValues: {"identifiant": identifiant, "tfa": tfa});
    }
  }

  static Future<void> deleteById(String id) async {
    var deletion = 1;
    await connection.query("DELETE FROM \"Account\" WHERE id=@identifiant",
        substitutionValues: {"identifiant": id});

    try{
      selectHashById(id);
    }
    on PostgreSQLException catch(e){

      if(e.severity==PostgreSQLSeverity.error){
        deletion = 0;
      }
    }

    if(deletion==1){
      throw PostgreSQLException("User not deleted",severity: PostgreSQLSeverity.unknown);
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

  static Future<void> flushUsers() async{

    await connection.query("DELETE FROM \"Account\" ");

    List<List<dynamic>> rows = await connection.query("SELECT COUNT(*) FROM \"Account\" ");

    if(rows[0][0]!=0){
      throw PostgreSQLException("Flush of users did not succeed",severity: PostgreSQLSeverity.unknown);
    }

    print("🟥 ADMIN: all users deleted");


  }

  static Future<void> flushTable() async {
    await connection.query("DROP TABLE \"Account\" ");

    try{

    await connection.query("SELECT * FROM \"Account\" ");
    throw PostgreSQLException('Table Not dropped',severity: PostgreSQLSeverity.unknown);
    }on PostgreSQLException{
      print("🟥 ADMIN: tables droped");}
    
  }




}
