import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  String base1 =
      'https://codefirst.iut.uca.fr/containers/passworld-api-remiarnal';

  String base2 = 'localhost:8080';

  Uri baseURL = Uri.parse("$base2/auth");
  String body = """
{
  "mail" : "haha", 
  "password" : "haha"
}
""";

  var res = await http.post(baseURL, body: body);
  print(res.body);
}
