import 'package:postgres/postgres.dart';

class DB2API {
  static String allUsersToJson(PostgreSQLResult data) {
    String body = "";
    int count = 0;
    for (final row in data) {
      body += userToString(row[0], row[1], row[2]);
      count++;
      if (count != data.length) body += ",";
    }
    return "[$body]";
  }

  static String userToString(String email, String hash, String salt) {
    return """{"email" : "$email", "hash" : "$hash", "salt" : "$salt"}""";
  }
}
