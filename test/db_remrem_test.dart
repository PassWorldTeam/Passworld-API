import 'dart:io';

import 'package:passworld_api/database/accounts_to_postgres.dart';
import 'package:passworld_api/db_to_api.dart';

void main() async {
  await AccountsToPostgres.createAccountTable();
  await AccountsToPostgres.create("remremc@gmail.com", "hehehe", "tameare");
  var res = await AccountsToPostgres.getAllUsers();
  for (final row in res) {
    stdout.write(row[0]);
    stdout.write(row[1]);
    print(row[2]);
  }
  //print(res.runtimeType);
  String json = DB2API.map2Json(res);
  print(json);
  AccountsToPostgres.closeConnection();
  return;
}
