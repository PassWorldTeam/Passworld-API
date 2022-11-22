import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class API {
  /*---------------|
  |-------GET------|
  |---------------*/

  // Default response for /
  static Response rootHandler(Request req) {
    return Response.ok('Greetings from PassWorld!\n');
  }

  // Request for authentification
  // Compare given cyphered_hash_password with db cyphered_hash_password
  // Return boolean -> true (hash match) false (no match)
  static Response authenticator(Request req) {
    final mail = req.params['mail'];
    final password = req.params['cyphered_password_hash'];

    return Response.ok('true');
  }

  // Request sqlite password db
  // Check auth
  // Return sqlite file
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

  static Response createAccount(Request req) {
    return Response.ok("");
  }

  /*---------------|
  |-------PUT------|
  |---------------*/

  static Response changeMasterPassword(Request req) {
    return Response.ok("master password chnaged");
  }

  static Response changeMail(Request req) {
    return Response.ok("master password chnaged");
  }

  static Response uploadPasswordDb(Request req) {
    return Response.ok("");
  }

  /*---------------|
  |-----DELETE-----|
  |---------------*/

  static Response deleteAccount(Request req) {
    return Response.ok("");
  }
}
