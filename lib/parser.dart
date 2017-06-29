import 'dart:io';
import 'package:crypto/crypto.dart' as crypto show sha1;
import 'package:meta/meta.dart' show protected;
import 'package:path/path.dart' as path;

String ps = Platform.pathSeparator;

abstract class Parser {
    List<String> ignoreHashes = [];
    Directory _outputDirectory;
    Directory _workingDirectory;

    String get varPath => Directory.current.absolute.path + ps + 'var';
    String get workingPath => varPath + ps + 'work';
    String get outputPath => varPath + ps + 'output';

    Directory get outputDirectory {
        if (_outputDirectory == null) {
            _outputDirectory = new Directory(outputPath);
        }
        return _outputDirectory;
    }

    Directory get workingDirectory {
        if (_workingDirectory == null) {
            _workingDirectory = new Directory(workingPath);
        }
        return _workingDirectory;
    }

    /// Parse all PDFs in the given directory
    parseDirectory(String directory, [clear = false]) {
        Directory pdfDirectory = new Directory(directory);
        if (!pdfDirectory.existsSync()) {
            throw new Exception('PDF directory does not exist.');
        }
        if (clear && outputDirectory.existsSync()) {
            _clearDirectory(outputDirectory);
        }
        for (File file in pdfDirectory.listSync(followLinks: false)) {
            if (path.extension(file.path) == '.pdf') {
                try {
                    parsePdf(file.path);
                } catch (e, stackTrace) {
                    String message = e is Exception ? e.message : e.toString();
                    print('Error processing "${path.basename(file.path)}": $message');
                    //print(stackTrace);
                    exit(1);
                }
            }
        }
    }

    /// Parse a given PDF file path
    parsePdf(String pathToPdf, [clear = false]) {
        if (!workingDirectory.existsSync()) {
            workingDirectory.createSync();
        }
        _clearDirectory(workingDirectory);
        if (!outputDirectory.existsSync()) {
            outputDirectory.createSync();
        }
        else if (clear) {
            _clearDirectory(outputDirectory);
        }
        var pdf = new File(pathToPdf);
        if (!pdf.existsSync()) {
            throw new Exception('PDF file does not exist.');
        }

        // parse text
        Process.runSync('pdftotext', ['-enc', 'UTF-8', pathToPdf, 'batch.txt'], workingDirectory: workingPath);
        var references = parseText();

        // parse images
        Process.runSync('pdfimages', [pathToPdf, 'images'], workingDirectory: workingPath);
        processImages(references);

        print('${references.length} checks were processed for ${path.basename(pathToPdf)}');
    }

    void _clearDirectory(Directory directory) {
        for (File file in directory.listSync(followLinks: false)) {
            file.deleteSync();
        }
    }

    @protected
    bool ignoreFile(File file) {
        String hash = crypto.sha1.convert(file.readAsBytesSync()).toString();
        return ignoreHashes.contains(hash.toUpperCase());
    }

    @protected
    List<String> parseText([String fileName = 'batch.txt']);

    @protected
    void processImages(List<String> references);
}