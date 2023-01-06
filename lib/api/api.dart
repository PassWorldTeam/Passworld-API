import 'dart:io';
import 'package:passworld_api/db_to_api.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import 'package:passworld_api/database/accounts_to_postgres.dart';

// Class for all static function that handles api routes
class API {
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
        await AccountsToPostgres.selectHashByMail(body[required[0]]);
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

  // Create account
  static Future<Response> createAccount(Request req) async {
    final List<String> required = ["email", "password", "salt"];
    final body = await bodyToJson(req);

    if (await checkRequiredFields(required, body)) {
      // List<String> twofa = body[required[3]];
      try {
        await AccountsToPostgres.createAccount(body[required[0]],
            body[required[1]], body[required[2]] /*, twofa*/);
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

  // Delete Account
  static Future<Response> deleteAccount(Request req) async {
    final List<String> required = ["email", "password"];
    final body = await bodyToJson(req);

    if (await checkRequiredFields(required, body)) {
      try {
        await AccountsToPostgres.deleteAccount(
            body[required[0]], body[required[1]]);
      } catch (e) {
        return Response(409,
            body: 'There was a problem with deletion'); // 409 (Conflict)
      }
      return Response(200, body: 'Account successfully deleted'); // 200 (OK)
    } else {
      return Response.badRequest(body: 'Bad request'); // 400 (Bad Request)
    }
  }

  // Update master password
  static Future<Response> changeMasterPassword(Request req) async {
    final List<String> required = ["email", "newPassword", "newSalt"];
    final body = await bodyToJson(req);

    if (await checkRequiredFields(required, body)) {
      try {
        await AccountsToPostgres.updatePassword(
            body[required[0]], body[required[1]], body[required[2]]);
      } catch (e) {
        return Response(403,
            body: 'This is not the good password'); // 403 (Forbidden)
      }
      return Response(201,
          body: 'user\'s password succesfully changed'); // 201 (Created)
    } else {
      return Response.badRequest(body: 'Bad request'); // 400 (Bad Request)
    }
  }

  // Update mail
  static Future<Response> changeMail(Request req) async {
    final List<String> required = ["email", "newMail"];
    final body = await bodyToJson(req);

    if (await checkRequiredFields(required, body)) {
      try {
        await AccountsToPostgres.updateMail(
            body[required[0]], body[required[1]]);
      } catch (e) {
        return Response(403,
            body: 'This is not the good password'); // 403 (Forbidden)
      }
      return Response(201,
          body: 'user\'s mail succesfully changed'); // 201 (Created)
    } else {
      return Response.badRequest(body: 'Bad request'); // 400 (Bad Request)
    }
  }

  // Upload sqlite password file
  static Future<Response> uploadPasswordDb(Request req) async {
    sleep(Duration(seconds: 20));
    Stream<List<int>> fileStream =
        await req.read(); // await is needed even if IDE say no
    List<List<int>> tmpFile = await fileStream.toList();
    List<int> fileAsBytes = tmpFile[0];

    File file = File("./passfile");
    file.writeAsBytes(fileAsBytes);

    print(await file.stat());

    //File test = File("./haha.yu");
    //await test.writeAsBytes(listBytes);
    //print(await test.stat());

    //print("Bytes: $listBytes");
    //print("Lenght: $size");
    return Response.ok("API: file received");
  }

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
