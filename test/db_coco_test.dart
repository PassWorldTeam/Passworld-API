import 'dart:io';
import 'package:passworld_api/database/accounts_to_postgres.dart';
import 'package:postgres/postgres.dart';
 void main()async{
    await AccountsToPostgres.openConnection();

    await AccountsToPostgres.flushUsers();
    
    await AccountsToPostgres.flushTable();

    AccountsToPostgres.closeConnection();
}