import 'dart:io';
import 'package:http_exception/http_exception.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_route/shelf_route.dart';
import 'parser.dart';

Router appRouter = router()
    ..post('/{?provider}', (Request request) async {
        var bin = new BytesBuilder(),
            provider = getPathParameter(request, 'provider') ?? 'ps';
        Parser parser = Parser.provider(provider);
        if (parser == null) {
            throw new BadRequestException(null, 'Provider parameter is missing or invalid.');
        }
        await for (var bytes in request.read()) {
            bin.add(bytes);
        }
        try {
            parser.parsePdfContent(bin.toBytes(), zip: true);
            return new Response.ok(parser.archive.openRead(), headers: {'Content-Type': 'application/zip'});
        } catch (e) {
            if (e is Exception) {
                throw new HttpException(500, e.message); // ignore: conflicting_dart_import
            }
            throw e;
        }
    })
    ..add('/', ['OPTIONS'], (Request request) {
        return new Response.ok('Ok');
    });

Middleware appMiddleware = createMiddleware(
    requestHandler: _reqHandler,
    responseHandler: _respHandler
);

Response _reqHandler(Request request) {
    if (!['POST', 'OPTIONS'].contains(request.method)) {
        throw new MethodNotAllowed();
    }
    return null;
}

Response _respHandler(Response response) {
    return response.change(headers: _CORSHeader);
}

Map _CORSHeader = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Origin, X-Requested-With, Content-Type, Accept',
    'Access-Control-Allow-Methods': 'POST, OPTIONS'
};
