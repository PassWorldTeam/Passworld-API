import 'dart:io';
import 'package:r_api/api.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

// Configure routes.
final _router = Router()
  // GET
  ..get('/', API.rootHandler)
  ..get('/auth', API.authenticator)
  ..get('/user/down-password-file', API.downloadPasswordDb)
  // POST
  ..post('/user/create-account', API.createAccount)
  // PUT
  ..put('/user/change-master-password', API.changeMasterPassword)
  ..put('/user/up-password-file', API.uploadPasswordDb)
  ..put('/user/change-mail', API.changeMail)
  // DELETE
  ..delete('/user/delete-account', API.deleteAccount);

/*
Response _fileHandler(Request req) {
  final String _basePath = '/home/hel/Projets/r_api/res/';
  final String reqFile = path.join(_basePath, req.params['file']);
  File file = File(reqFile ?? ''); //technique du pauvre 2
  Stream<List<int>> fileStream = file.openRead();
  return Response.ok(fileStream, headers: {
    'Content-Type': 'application/octet-stream',
    'Content-Disposition': 'attachment, filename="$reqFile"'
  });
}

Future<bool> fileExist(String path) {
  Future<bool> exist = File(path).exists();
  print(exist);
  return exist;
}
*/

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = 'localhost';

  // Configure a pipeline that logs requests.
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
