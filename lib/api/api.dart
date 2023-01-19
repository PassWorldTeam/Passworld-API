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

  static Future<Response> getSalt(Request req) async {
    final List<String> required = ["email"];
    final body = await bodyToJson(req);

    if (await checkRequiredFields(required, body)) {
      try {
        String salt =
            await AccountsToPostgres.selectSaltByMail(body[required[0]]);
        return Response(200, body: salt);
      } catch (e) {
        return Response(204, body: 'Account already existing'); // No content
      }
    } else {
      return Response.badRequest(body: 'bad body');
    }
  }

  // Check for authentication
  static Future<Response> authenticator(Request req) async {
    final List<String> required = ["email", "password"];
    final body = await bodyToJson(req);

    if (await checkRequiredFields(required, body)) {
      if (await checkAuthentication(body[required[0]], body[required[1]])) {
        return Response.ok('Succesfully Authenticated');
      } else {
        return Response.unauthorized('Bad password or email !'); // 401
      }
    } else {
      return Response.badRequest(body: 'bad body'); // 401
    }
  }

  // Create account
  static Future<Response> createAccount(Request req) async {
    final List<String> required = ["email", "password", "salt"];
    final body = await bodyToJson(req);

    if (await checkRequiredFields(required, body)) {
      try {
        await AccountsToPostgres.createAccount(
            body[required[0]], body[required[1]], body[required[2]]);
      } catch (e) {
        return Response(409,
            body: 'Account already existing'); // 409 (Conflict)
      }
      print("✅ Account succesfully created");
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
        if (await checkAuthentication(body[required[0]], body[required[1]])) {
          await AccountsToPostgres.deleteAccount(body[required[0]]);
        } else {
          return Response(403,
              body:
                  'You haven\'t provided the good password or mail'); // 403 (Forbidden)
        }
      } catch (e, s) {
        print("Exception $e");
        print("Stacktrace $s");
        return Response(409,
            body: 'There was a problem with deletion'); // 409 (Conflict)
      }
      print("✅ Account succesfully deleted");
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
    final List<String> required = ["email", "password", "file"];
    final body = await bodyToJson(req);

    if (await checkRequiredFields(required, body)) {
      try {
        if (await checkAuthentication(body[required[0]], body[required[1]])) {
          String fileAsBytes = body[required[2]];
          var arrayBytes = fileAsBytes.split(',');
          arrayBytes.removeLast();
          List<int> arrayBytes2 = arrayBytes.map(int.parse).toList();
          await AccountsToPostgres.updatePasswordFile(
              body[required[0]], arrayBytes2);
        } else {
          return Response(403); // 403 (Forbidden)
        }
      } catch (e, s) {
        print("Exception $e");
        print("Stacktrace $s");
        return Response(409,
            body: 'There was a problem with upload'); // 409 (Conflict)
      }
      print("✅ PassWord file succesfully uploaded");
      return Response(201,
          body: 'PassWord file succesfully uploaded'); // 20 (OK)
    } else {
      return Response.badRequest(body: 'Bad request'); // 400 (Bad Request)
    }
  }

  // Download sqlite password file
  static Future<Response> downloadPasswordDb(Request req) async {
    final List<String> required = ["email", "password"];
    final body = await bodyToJson(req);

    if (await checkRequiredFields(required, body)) {
      try {
        if (await checkAuthentication(body[required[0]], body[required[1]])) {
          List<int> file =
              await AccountsToPostgres.getPasswordFile(body[required[0]]);
          print("✅ PassWord file succesfully downloaded");
          return Response(200, body: file.toString());
        } else {
          return Response(403); // 403 (Forbidden)
        }
      } catch (e, s) {
        print("Exception $e");
        print("Stacktrace $s");
        return Response(409,
            body: 'There was a problem with upload'); // 409 (Conflict)
      } // 200 (OK)
    } else {
      return Response.badRequest(body: 'Bad request'); // 400 (Bad Request)
    }
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

  static Future<bool> checkAuthentication(
      String givedMail, String givedPassword) async {
    try {
      if (!await checkMail(givedMail)) return false;
    } catch (e) {
      // catch if there is nothing in result of checkMail
      return false;
    }
    if (!await checkPassword(givedMail, givedPassword)) return false;
    print("authentication successed !!!");
    return true;
  }

  static Future<bool> checkPassword(
      String givedMail, String givedPassword) async {
    print("check hash...");
    var hash = await AccountsToPostgres.selectHashByMail(givedMail);

    if (hash == givedPassword) {
      print("hash is good");
      return true;
    }
    print("hash is bad");
    return false;
  }

  static Future<bool> checkMail(String givedMail) async {
    print("check mail...");
    var mail = await AccountsToPostgres.selectMailByMail(givedMail);

    if (mail == givedMail) {
      print("mail is good");
      return true;
    }
    print("mail is bad");
    return false;
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
