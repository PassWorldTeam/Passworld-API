
import 'dart:convert';
import 'dart:io';
import 'package:postgres/postgres.dart';

class AccountsToPostgres{
  final connection = PostgreSQLConnection("localhost", 5432, 'passworld',username: 'pass',password: '1p2a3s4s5');
  
  AccountsToPostgres(){
    initConnection();
  }

  void initConnection()async{
    await connection.open().then((value){
      print("PostgreSQL connection opened");

    });
  }

  @override
  void create(String id,String hash,String salt,List<String> twoFaStr, File passwordFile ) async {
    List<int> passwordBlob = utf8.encode( await passwordFile.readAsString(encoding: utf8));
    
    
    connection.query("INSERT INTO \"Account\" VALUES(@id,@hash,@salt,@twofa,@passwords)",substitutionValues: {
    "id" : id,
    "hash" : hash,
    "salt" : salt,
    "twofa" : twoFaStr,
    "passwords" : passwordBlob
    });
  }

  @override
  Future<String> selectHashById(String id) async {
    List<List<dynamic>> results = await connection.query("SELECT hash FROM \"Account\" WHERE id=@identifiant",substitutionValues: {
      "identifiant" : id
    });
    
    connection.close();
    return results[0][0];
  }

  @override
  void updatePass(String identifiant,String hash,String salt) async {
    if(selectHashById(identifiant)==null){
      return;
    }else{
      await connection.query("UPDATE \"Account\" SET hash=@h, salt=@s  WHERE id=@identifiant",substitutionValues: {
      "identifiant" : identifiant,
      "h" : hash,
      "s" : salt
      });
    }
  }

  @override
  void updateFilePass(String identifiant, File passwordFile) async{
    List<int> passwordBlob = utf8.encode( await passwordFile.readAsString(encoding: utf8));

    if(selectHashById(identifiant)==null){
      return;
    }else{
      await connection.query("UPDATE \"Account\" SET passwords=@p WHERE id=@identifiant",substitutionValues: {
      "identifiant" : identifiant,
      "p" : passwordBlob
      });
    }
  }

  @override
  void updateTwoFa(String identifiant,List<String> tfa) async {
    List<String> twoFaStr = List.empty(growable: true);

    if(selectHashById(identifiant)==null){
      return;
    }else{
      await connection.query("UPDATE \"Account\" SET twofa=@tfa WHERE id=@identifiant",substitutionValues: {
      "identifiant" : identifiant,
      "tfa" : tfa 
      });
    }  
  }




  @override
  void DeleteById(String id) async{
    await connection.query("DELETE FROM \"Account\" WHERE id=@identifiant",substitutionValues: {
      "identifiant" : id
    });
  }
}