import 'package:passworld_api/db_to_api.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import 'package:passworld_api/database/accounts_to_postgres.dart';

// Class for all static function that handles api routes
class API {
  /*---------------|
  |-------GET------|
  |---------------*/

  // Default response for /
  static Response rootHandler(Request req) {
    return Response.ok('Greetings from PassWorld!\n');
  }

  // Check for authentication
  static Future<Response> authenticator(Request req) async {
    // final List<String> required = ["email", "password"];

    // if (await checkRequiredFields(required, req)) {
    //   return Response.ok('true');
    // } else {
    //   return Response.badRequest();
    // }
    return Response(404);
  }

  // Download sqlite password file
  static Response downloadPasswordDb(Request req) {
    final mail = req.params['mail'];
    final password = req.params['cyphered_password_hash'];

    // Database query -> return file (List<int>)
    // Create stream from List<int>
    // Rename file -> db_password_<mail>_<date>
    // Send file

    return Response.ok("");

    /*
  Stream<List<int>> fileStream = file.openRead();
  return Response.ok(fileStream, headers: {
    'Content-Type': 'application/octet-stream',
    'Content-Disposition': 'attachment, filename="$reqFile"'
  });
  */
  }
  /*---------------|
  |------POST------|
  |---------------*/

  // Create account
  static Future<Response> createAccount(Request req) async {
    final List<String> required = ["email", "password", "salt"];
    var tmp = await req.readAsString();
    final Map<String, dynamic> body = json.decode(tmp);

    if (await checkRequiredFields(required, body)) {
      // List<String> twofa = body[required[3]];
      await AccountsToPostgres.create(
          body[required[0]], body[required[1]], body[required[2]] /*, twofa*/);
      return Response.ok('true');
    } else {
      return Response.badRequest();
    }
  }

  /*---------------|
  |-------PUT------|
  |---------------*/

  // Update master password
  static Response changeMasterPassword(Request req) {
    return Response.ok("master password chnaged");
  }

  // Update mail
  static Response changeMail(Request req) {
    return Response.ok("master password chnaged");
  }

  // Upload sqlite password file
  static Response uploadPasswordDb(Request req) {
    return Response.ok("");
  }

  /*---------------|
  |-----DELETE-----|
  |---------------*/

  // Delete account
  static Response deleteAccount(Request req) {
    return Response.ok("");
  }

  /*---------------|
  |-------MISC-----|
  |---------------*/

  // Check if required fields are in req body
  static Future<bool> checkRequiredFields(
      List<String> fields, Map<String, dynamic> body) async {
    // json object read -> check dic keys
    for (String itFields in fields) {
      if (!body.containsKey(itFields)) {
        print(itFields);
        return false;
      }
      if (body[itFields] == "") {
        print(itFields);
        return false;
      }
    }
    return true;
  }

  //
  // ADMIN
  //

  static Future<Response> getAllUsers(Request req) async {
    PostgreSQLResult res = await AccountsToPostgres.getAllUsers();
    String json = DB2API.map2Json(res);
    return Response.ok(json);
  }
}
