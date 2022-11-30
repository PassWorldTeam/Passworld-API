import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';

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
    final List<String> required = ["mail", "password"];

    if (await checkRequiredFields(required, req)) {
      return Response.ok('true');
    }

    return Response.badRequest();
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
  static Response createAccount(Request req) {
    return Response.ok("");
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
      List<String> fields, Request req) async {
    // json object read -> check dic keys
    var tmp = await req.readAsString();
    final body = json.decode(tmp);
    bool check = false;
    for (String s in fields) {
      if (body['$s'] == "") {
        return false;
      }
    }
    return true;
  }
}
