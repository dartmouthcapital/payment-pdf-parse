import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart' as crypto show sha1;
import 'package:meta/meta.dart' show protected;
import 'package:path/path.dart' as path;
import 'parser/fis.dart';
import 'parser/profit_stars.dart';

String ps = Platform.pathSeparator;

abstract class Parser {
    List<String> ignoreHashes = [];
    File _archive;
    var logger;
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

    File get archive {
        if (_archive != null) {
            return _archive;
        }
        throw new Exception('Archive output has not been generated.');
    }

    /// Provider factory
    static Parser provider(type) {
        switch (type) {
            case 'ps':
            case 'profitstars':
                return new ProfitStarsParser();
            case 'fis':
                return new FisParser();
            default:
                return null;
        }
    }

    /// Parse all PDFs in the given directory
    parseDirectory(String directory, {clear = false, zip = false}) {
        Directory pdfDirectory = new Directory(directory);
        if (!pdfDirectory.existsSync()) {
            throw new Exception('PDF directory does not exist.');
        }
        if ((clear || zip) && outputDirectory.existsSync()) {
            _clearDirectory(outputDirectory);
        }
        for (File file in pdfDirectory.listSync(followLinks: false)) {
            if (path.extension(file.path) == '.pdf') {
                try {
                    parsePdf(file.path);
                } catch (e) {
                    String message = e is Exception ? e.message : e.toString();
                    log('Error processing "${path.basename(file.path)}": $message');
                }
            }
        }
        if (zip) {
            _archiveOutput(path.basename(directory));
        }
    }

    /// Parse a given PDF file path
    parsePdf(String pathToPdf, {clear = false, zip = false}) {
        if (!workingDirectory.existsSync()) {
            workingDirectory.createSync();
        }
        _clearDirectory(workingDirectory);
        if (!outputDirectory.existsSync()) {
            outputDirectory.createSync();
        }
        else if (clear || zip) {
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

        if (zip) {
            _archiveOutput(path.basenameWithoutExtension(pathToPdf));
        }
        log('${references.length} checks were processed for ${path.basename(pathToPdf)}');
    }

    /// Parse PDF binary content
    parsePdfContent(List<int> pdfContent, {clear = false, zip = false}) {
        File pdf = new File(varPath + ps + 'upload.pdf');
        pdf.writeAsBytesSync(pdfContent, mode: FileMode.WRITE_ONLY);
        parsePdf(pdf.path, clear: clear, zip: zip);
    }

    void _clearDirectory(Directory directory) {
        for (File file in directory.listSync(followLinks: false)) {
            file.deleteSync();
        }
    }

    void _archiveOutput(archiveName) {
        Archive zipArchive = new Archive();
        for (File file in outputDirectory.listSync(followLinks: false)) {
            var bytes = file.readAsBytesSync(),
                archiveFile = new ArchiveFile(path.basename(file.path), bytes.length, bytes);
            zipArchive.addFile(archiveFile);
        }
        List<int> zip = new ZipEncoder().encode(zipArchive);
        _archive = new File(outputPath + ps + archiveName + '.zip');
        _archive.writeAsBytesSync(zip);
        log(archiveName + '.zip created');
    }

    @protected
    bool ignoreFile(File file) {
        String hash = crypto.sha1.convert(file.readAsBytesSync()).toString();
        return ignoreHashes.contains(hash.toUpperCase());
    }

    @protected
    void log(String message) {
        if (logger != null) {
            logger(message);
        }
    }

    @protected
    List<String> parseText([String fileName = 'batch.txt']);

    @protected
    void processImages(List<String> references);
}