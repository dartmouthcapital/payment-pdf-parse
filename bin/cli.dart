#!/usr/bin/env dart
import 'dart:io';
import 'package:args/command_runner.dart';
import '../lib/parser.dart';

main(List<String> args) {
    var runner = new CommandRunner('ppp-cli', 'Payment PDF Parser CLI')
        ..addCommand(new FileParserCommand())
        ..addCommand(new DirectoryParserCommand());

    runner
        .run(args)
        .catchError((e, stackTrace) {
            String message = e is Exception ? e.message : e.toString();
            print(message);
            //print(stackTrace);
            exit(64);
        });
}

/// File parser command
class FileParserCommand extends Command {
    final String name = 'file';
    final String description = 'Parse a single PDF file.';

    FileParserCommand() {
        argParser.addOption('file', abbr: 'f', help: 'Path of the PDF file to parse.');
    }

    run() {
        var path = argResults['file'];
        if (path == null) {
            throw new UsageException('"file" option must be set.', 'file -f /path/to/pdf');
        }
        parsePdf(path);
    }
}

/// Directory parser command
class DirectoryParserCommand extends Command {
    final String name = 'directory';
    final String description = 'Parse a directory of PDFs.';

    DirectoryParserCommand() {
        argParser
            ..addOption('directory', abbr: 'd', help: 'Directory containing PDF files to parse.')
            ..addFlag('clear', abbr: 'c', help: 'Clear output directory.', negatable: false);
    }

    run() {
        var path = argResults['directory'];
        if (path == null) {
            throw new UsageException('"directory" option must be set.', 'directory -d /path/to/pdfs');
        }
        parseDirectory(path, argResults['clear']);
    }
}