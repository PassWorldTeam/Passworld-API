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
    final List<String> required = ["email", "password"];
    final body = await bodyToJson(req);

    if (await checkRequiredFields(required, body)) {
      try {
        await AccountsToPostgres.selectHashById(body[required[0]]);
      } catch (e) {
        return Response(404,
            body: 'Not Found'); // no hash found -> 404 (Not Found)
      }
      return Response.ok('Succesfully Authenticated'); // 200 (Ok)
    } else {
      return Response.badRequest(
          body: 'Bad password or email !'); // 400 (Bad Request)
    }
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
    final body = await bodyToJson(req);

    if (await checkRequiredFields(required, body)) {
      // List<String> twofa = body[required[3]];
      try {
        await AccountsToPostgres.create(body[required[0]], body[required[1]],
            body[required[2]] /*, twofa*/);
      } catch (e) {
        return Response(409,
            body: 'Account already existing'); // 409 (Conflict)
      }
      return Response(201,
          body: 'Account successfully created'); // 201 (Created)
    } else {
      return Response.badRequest(body: 'Bad request'); // 400 (Bad Request)
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

  static Future<Map<String, dynamic>> bodyToJson(Request req) async {
    var tmp = await req.readAsString();
    return json.decode(tmp);
  }

  //
  // ADMIN
  //

  static Future<Response> getAllUsers(Request req) async {
    PostgreSQLResult res = await AccountsToPostgres.getAllUsers();
    String json = DB2API.allUsersToJson(res);
    return Response.ok(json,
        headers: {'Content-Type': 'application/json;charset=utf-8'});
  }
}
