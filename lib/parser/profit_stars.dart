import 'dart:io';
import 'package:path/path.dart' as path;
import '../parser.dart';

class ProfitStarsParser extends Parser {
    List<String> ignoreHashes = [
        'B4DB9B8349449A77318EF65E04CA848F309230C2',  // gray bar
        '958B3475E8E7745285E2804F949D48D8C61C1B48'  // red/orange header
    ];

    List<String> parseText([String fileName = 'batch.txt']) {
        var file = new File(workingPath + ps + fileName),
            contents = file.readAsStringSync(),
            references = [],
            referenceExp = new RegExp(r"Reference Number\r?\n([A-Z0-9]{9,11})|/[0-9]{2}\s([A-Z0-9]{9,11})", multiLine: true),  // "(?:[^:])\s([A-Z0-9]{10,11})\s"
            amountsExp = new RegExp(r"sale[\s\r\n]+([\d\.,]+)", multiLine: true),
            countExp = new RegExp(r"(\d+) Check 21 TRANSACTIONS FOR CREDIT"),
            referenceMatches = new List.from(referenceExp.allMatches(contents)),
            amountsMatches = new List.from(amountsExp.allMatches(contents)),
            countMatch = countExp.firstMatch(contents),
            expectedCount = int.parse(countMatch != null ? countMatch.group(1) : '0');

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

    void processImages(List<String> references) {
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
            if (count % 2 != 0 || ignoreFile(file)) {
                continue;
            }
            if (index >= references.length) {
                throw new Exception('More images than reference numbers were found.');
            }
            var newName = 'PNG8:$outputPath$ps${references[index++]}.png';
            Process.runSync(
                'magick',
                [baseName + '.ppm', '-colors', '8', '-resize', '700', '-colorspace', 'RGB', newName],
                workingDirectory: workingPath
            );
        }
    }
}