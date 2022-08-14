import 'dart:io';
import 'package:path/path.dart' as path;
import '../parser.dart';

class ProfitStarsParser extends Parser {
    List<String> ignoreHashes = [
        'B4DB9B8349449A77318EF65E04CA848F309230C2',  // gray bar
        '958B3475E8E7745285E2804F949D48D8C61C1B48',  // red/orange header, windows
        'D84B02FFAC03442C251CE1BC30E79ECC0166FB48'  // red/orange header, linux
    ];

    List<String> parseText([String fileName = 'batch.txt']) {
        var file = new File(workingPath + ps + fileName),
            contents = file.readAsStringSync();
        if (!contents.contains('Jack Henry & Associates, Inc.')) {
            throw new ParseException('Not a ProfitStars PDF.');
        }
        var references = [],
            referenceExp = new RegExp(r"(PM|AM|/\d{2})\s{1,10}([A-Z0-9]{9,11})\s+", multiLine: true),
            amountsExp = new RegExp(r"sale[\s]+([\d\.,]+)", multiLine: true),
            countExp = new RegExp(r"(\d+) Check 21 TRANSACTIONS FOR CREDIT"),
            referenceMatches = new List.from(referenceExp.allMatches(contents)),
            amountsMatches = new List.from(amountsExp.allMatches(contents)),
            countMatch = countExp.firstMatch(contents),
            expectedCount = int.parse(countMatch != null ? countMatch.group(1) : '0');

        // debug
        // for (int i = 0; i < referenceMatches.length; i++) {
        //     log(referenceMatches[i].group(0));
        // }
        // for (int i = 0; i < amountsMatches.length; i++) {
        //     log(amountsMatches[i].group(0));
        // }

        if (expectedCount != referenceMatches.length) {
            throw new ParseException('The expected number of checks (${expectedCount}) does not match the number found (${referenceMatches.length}).');
        }
        if (referenceMatches.length != amountsMatches.length) {
            throw new ParseException('The number of checks (${referenceMatches.length}) does not match the number of amounts found (${amountsMatches.length}).');
        }
        for (int i = 0; i < referenceMatches.length; i++) {
            Match reference = referenceMatches[i],
                  amount = amountsMatches[i];
            int cents = (double.parse(amount.group(1).replaceAll(',', '')) * 100).round();
            references.add(reference.group(2) + '-' + cents.toString());
        }
        return references;
    }

    void processImages(List<String> references) {
        var nameExp = new RegExp(r"images-(\d+)");
        int index = 0;
        for (File file in workingDirectorySorted()) {
            var baseName = path.basenameWithoutExtension(file.path),
                match = nameExp.firstMatch(baseName);

            // debug
            // log(baseName);
            // log(match.group(0));

            if (match == null) {
                continue;
            }
            var count = int.parse(match.group(1));
            if (count % 2 != 0 || ignoreFile(file)) {
                continue;
            }
            if (index >= references.length) {
                throw new ParseException('More images than reference numbers were found.');
            }
            var newName = 'PNG8:$outputPath$ps${references[index++]}.png';
            Process.runSync(
                'magick',
                // locally, this works better
                //[baseName + '.pbm', '-colors', '8', '-resize', '700', '-channel', 'RGB', '-negate', newName],
                // in the built image, this works better
                [baseName + '.pbm', '-colors', '8', '-resize', '700', '-colorspace', 'RGB', newName],
                workingDirectory: workingPath
            );
        }
        if (index == 0) {
            throw new ParseException('No images were available for processing.');
        }
    }
}