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

abstract class ParserCommand extends Command {
    Parser provider(type) {
        var parser = Parser.provider(type);
        if (parser == null) {
            throw new UsageException('"provider" option must be either "ps" or "fis".', '-p ps');
        }
        parser.logger = print;
        return parser;
    }
}

/// File parser command
class FileParserCommand extends ParserCommand {
    final String name = 'file';
    final String description = 'Parse a single PDF file.';

    FileParserCommand() {
        argParser
            ..addOption('file', abbr: 'f', help: 'Path of the PDF file to parse.')
            ..addOption('provider', abbr: 'p', help: 'PDF Provider - "ps" or "fis".')
            ..addFlag('clear', abbr: 'c', help: 'Clear output directory.', negatable: false)
            ..addFlag('zip', abbr: 'z', help: 'Zip up output images.', negatable: false);
    }

    run() {
        var path = argResults['file'];
        if (path == null) {
            throw new UsageException('"file" option must be set.', 'file -f /path/to/pdf');
        }
        provider(argResults['provider'])
            .parsePdf(path, clear: argResults['clear'], zip: argResults['zip']);
    }
}

/// Directory parser command
class DirectoryParserCommand extends ParserCommand {
    final String name = 'directory';
    final String description = 'Parse a directory of PDFs.';

    DirectoryParserCommand() {
        argParser
            ..addOption('directory', abbr: 'd', help: 'Directory containing PDF files to parse.')
            ..addOption('provider', abbr: 'p', help: 'PDF Provider - "ps" or "fis".')
            ..addFlag('clear', abbr: 'c', help: 'Clear output directory.', negatable: false)
            ..addFlag('zip', abbr: 'z', help: 'Zip up output images.', negatable: false);
    }

    run() {
        var path = argResults['directory'];
        if (path == null) {
            throw new UsageException('"directory" option must be set.', 'directory -d /path/to/pdfs');
        }
        provider(argResults['provider'])
            .parseDirectory(path, clear: argResults['clear'], zip: argResults['zip']);
    }
}