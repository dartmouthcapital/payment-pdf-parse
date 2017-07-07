import 'dart:io';
import 'package:path/path.dart' as path;
import '../parser.dart';

class FisParser extends Parser {
    List<String> ignoreHashes = [
        '3994E6E5754145FFA2D7E086828AA41046C8C454',  // gray box
    ];

    List<String> parseText([String fileName = 'batch.txt']) {
        var file = new File(workingPath + ps + fileName),
            contents = file.readAsStringSync(),
            references = [],
            referenceExp = new RegExp(r"Capture Sequence:\s+(\d{13})", multiLine: true),
            amountsExp = new RegExp(r"Item Amount:\s+\$([\d\.,]+)", multiLine: true),
            countExp = new RegExp(r"No of Debits:\s+(\d{1,4})"),
            referenceMatches = new List.from(referenceExp.allMatches(contents)),
            amountsMatches = new List.from(amountsExp.allMatches(contents)),
            countMatch = countExp.firstMatch(contents),
            expectedCount = int.parse(countMatch != null ? countMatch.group(1) : '0');

        referenceMatches.removeLast();  // pop to exclude the debit
        amountsMatches.removeLast();

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
            references.add(reference.group(1) + '-' + cents.toString());
        }
        return references;
    }

    void processImages(List<String> references) {
        int index = 0;
        bool isBack = false;
        for (FileSystemEntity file in workingDirectory.listSync(followLinks: false)) {
            if (!(file is File) || path.extension(file.path) != '.ppm') {
                continue;
            }
            if (ignoreFile(file)) {
                continue;
            }
            if (isBack) {
                isBack = false;
                continue;
            }
            isBack = true;
            if (index >= references.length) {
                break;
            }
            var baseName = path.basenameWithoutExtension(file.path),
                newName = 'PNG8:$outputPath$ps${references[index++]}.png';
            Process.runSync(
                'magick',
                [baseName + '.ppm', '-colors', '8', '-colorspace', 'RGB', newName],
                workingDirectory: workingPath
            );
        }
    }
}