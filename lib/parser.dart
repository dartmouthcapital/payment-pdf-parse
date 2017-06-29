import 'dart:io';
import 'package:crypto/crypto.dart' as crypto show sha1;
import 'package:path/path.dart' as path;

String ps = Platform.pathSeparator,
    varPath = Directory.current.absolute.path + ps + 'var',
    workingPath = varPath + ps + 'work',
    outputPath = varPath + ps + 'output';

Directory workingDirectory = new Directory(workingPath),
    outputDirectory = new Directory(outputPath);

/// Parse all PDFs in the given directory
parseDirectory(String directory, [clear = false]) {
    Directory pdfDirectory = new Directory(directory);
    if (!pdfDirectory.existsSync()) {
        throw new Exception('PDF directory does not exist.');
    }
    if (clear) {
        outputDirectory.deleteSync(recursive: true);
    }
    for (File file in pdfDirectory.listSync(followLinks: false)) {
        if (file is File && path.extension(file.path) == '.pdf') {
            try {
                parsePdf(file.path);
            } catch (e) {
                String message = e is Exception ? e.message : e.toString();
                print('Error processing "${path.basename(file.path)}": $message');
            }
        }
    }
}

/// Parse a given PDF file path
parsePdf(String pathToPdf) {
    if (workingDirectory.existsSync()) {
        workingDirectory.deleteSync(recursive: true);
    }
    workingDirectory.createSync();
    outputDirectory.createSync();
    var pdf = new File(pathToPdf);
    if (!pdf.existsSync()) {
        throw new Exception('PDF file does not exist.');
    }

    // parse text
    Process.runSync('pdftotext', ['-enc', 'UTF-8', pathToPdf, 'batch.txt'], workingDirectory: workingPath);
    var references = _parseTxt();

    // parse images
    Process.runSync('pdfimages', [pathToPdf, 'images'], workingDirectory: workingPath);
    _processImages(references);

    print('${references.length} checks were processed for ${path.basename(pathToPdf)}');
}

List<String> _parseTxt([String fileName = 'batch.txt']) {
    var file = new File(workingPath + Platform.pathSeparator + fileName),
        contents = file.readAsStringSync(),
        references = [],
        referenceExp = new RegExp(r"Reference Number\r?\n([A-Z0-9]{9,11})|/[0-9]{2}\s([A-Z0-9]{9,11})", multiLine: true),  // "(?:[^:])\s([A-Z0-9]{10,11})\s"
        amountsExp = new RegExp(r"sale[\s\r\n]+([\d\.,]+)", multiLine: true),
        countExp = new RegExp(r"(\d+) Check 21 TRANSACTIONS FOR CREDIT"),
        referenceMatches = new List.from(referenceExp.allMatches(contents)),
        amountsMatches = new List.from(amountsExp.allMatches(contents)),
        countMatch = countExp.firstMatch(contents),
        expectedCount = int.parse(countMatch.group(1));

//    for (Match m in referenceMatches) {
//        print(m.group(1) ?? m.group(2));
//    }
    if (expectedCount != referenceMatches.length) {
        throw new Exception('The expected number of checks (${expectedCount}) does not match the number found (${referenceMatches.length}).');
    }
    if (referenceMatches.length != amountsMatches.length) {
        throw new Exception('The number of checks (${referenceMatches.length}) does not match the number of amounts found (${amountsMatches.length}).');
    }
    for (int i = 0; i < referenceMatches.length; i++) {
        Match reference = referenceMatches[i],
              amount = amountsMatches[i];
        int cents = (double.parse(amount.group(1).replaceAll(',', '')) * 100).round();
        references.add(reference.group(1) ?? reference.group(2) + '-' + cents.toString());
    }
    return references;
}

_processImages(List<String> references) {
    var nameExp = new RegExp(r"images-(\d+)");
    int index = 0;
    for (FileSystemEntity file in workingDirectory.listSync(followLinks: false)) {
        if (!(file is File) || path.extension(file.path) != '.ppm') {
            continue;
        }
        var baseName = path.basenameWithoutExtension(file.path),
            match = nameExp.firstMatch(baseName);
        if (match == null) {
            continue;
        }
        var count = int.parse(match.group(1));
        if (count % 2 != 0 || _ignoreFile(file)) {
            continue;
        }
        if (index >= references.length) {
            throw new Exception('More images than reference numbers were found.');
        }
        var newName = 'PNG8:$outputPath$ps${references[index++]}.png';
        Process.runSync(
            'magick',
            [baseName + '.ppm', '-colors', '8', '-resize', '700', newName],
            workingDirectory: workingPath
        );
    }
}

bool _ignoreFile(File file) {
    List ignoreHashes = [
        'B4DB9B8349449A77318EF65E04CA848F309230C2',  // gray bar
        '958B3475E8E7745285E2804F949D48D8C61C1B48'  // red/orange header
    ];
    String hash = crypto.sha1.convert(file.readAsBytesSync()).toString();
    return ignoreHashes.contains(hash.toUpperCase());
}