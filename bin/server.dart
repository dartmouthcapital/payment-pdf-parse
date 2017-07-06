#!/usr/bin/env dart
import 'dart:io';
import 'package:shelf/shelf_io.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_exception_handler/shelf_exception_handler.dart';
import 'package:shelf_route/shelf_route.dart';

import '../lib/router.dart' as appRouter;

main(List<String> args) {
    Handler handler = const Pipeline()
        .addMiddleware(exceptionHandler())
        .addMiddleware(logRequests())
        .addMiddleware(appRouter.appMiddleware)
        .addHandler(appRouter.appRouter.handler);

    printRoutes(appRouter.appRouter);

    String host = Platform.environment.containsKey('SHELF_HTTP_HOST') ?
        Platform.environment['SHELF_HTTP_HOST'] : InternetAddress.LOOPBACK_IP_V4.host;
    int port = Platform.environment.containsKey('SHELF_HTTP_PORT') ?
        int.parse(Platform.environment['SHELF_HTTP_PORT']) : 8080;

    serve(handler, host, port).then((server) {
        print('Serving at http://${server.address.host}:${server.port}');
    }).catchError((error, stackTrace) {
        print(error);
        print(stackTrace);
    });
}
