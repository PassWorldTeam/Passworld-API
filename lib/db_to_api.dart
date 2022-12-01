import 'dart:convert';
import 'package:postgres/postgres.dart';

class DB2API {
  static String map2Json(PostgreSQLResult data) {
    return jsonEncode(data);
  }
}
