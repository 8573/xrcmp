import std.exception;
import std.file;
import std.getopt;
import std.regex;
import std.stdio;

int main(string[] args) {

	bool debugMode = false;
	bool showHelp = false;
	bool markRows = false;
	bool markColumns = false;
	bool showTotal = false;
	bool showOnlyShared = false;
	ushort minColumnWidth = 1;
	ushort maxColumnWidth = ushort.max;
	string pattern = `\S+`;
	string totalColumnTitle = "(ALL)";

	{
		auto error = collectExceptionMsg(
			getopt(
				args,
				std.getopt.config.noPassThrough,
				"debug", &debugMode,
				"pattern|p", &pattern,
				"total|t", &showTotal,
				"shared|s", &showOnlyShared,
				"mark-both|mb", () {
					markColumns = true;
					markRows = true;
				},
				"mark-columns|mc", &markColumns,
				"mark-rows|mr", &markRows,
				"max-column-width|maxw", &maxColumnWidth,
				"min-column-width|minw", &minColumnWidth,
				"help", &showHelp
			      )
			);
		if (error != null) {
			writeln(error);
			return 2;
		}
	}

	if (showHelp) {
		writeln(
`xrcmp [options] <files>

Cross-references the files, and prints a table of the occurrences of each match
of the search pattern in each file.

   Options:
      --help
         Print this help text, then exit.
      --pattern=<pattern>, --p=<pattern>
         Defaults to ‘\S+’, i.e. all sequences of non-whitespace characters.
         See <http://dlang.org/phobos/std_regex.html> for a description of the
         pattern syntax (in the “Pattern syntax” section).
      --total, --t
         Print an extra column showing the total occurrences of each match.
      --shared, --s
         Don’t show matches that don’t occur in multiple files.
      --mark-columns, --mc      --mark-rows, --mr      --mark-both, --mb
         Print borders between columns/rows/both.
      --max-column-width=<0..65535>, --maxw=<0..65535>
      --min-column-width=<0..65535>, --minw=<0..65535>`);
		return 2;
	}

	args = args[1..$];

	if (args.length < 2) {
		writeln("usage: xrcmp {options} {files} | xrcmp --help");
		return 2;
	}

	auto rx = regex(pattern, "g");

	immutable(size_t[string])[string] matchListsByFile;
	//          ^------|--------|---- matchQty
	//                 +--------|---- match
	//                          +---- filename

	foreach (filename; args) {
		auto error = collectExceptionMsg(
			matchListsByFile[filename] = processFile(filename, rx)
		);
		if (error != null) {
			writeln(error);
			return 1;
		}
	}

	immutable(size_t[string])[string] matchListsByMatch;
	//          ^------|--------|---- matchQty
	//                 +--------|---- filename
	//                          +---- match

	size_t[string] matchTotals;
	// ^-----|---- matchQty
	//       +---- match

	size_t[string] matchFiles;
	// ^-----|---- (quantity of files in which match occurs)
	//       +---- match

	string[] matches;

	foreach (filename, matchList; matchListsByFile) {
		foreach (match, matchQty; matchList) {
			matches ~= match;
			matchListsByMatch[match][filename] = matchQty;
			matchTotals[match] += matchQty;
			matchFiles[match] += 1;
		}
	}

	int columnWidth = clampToInt(
		greater(greater(greatestLength(matches),
				greatestLength(args)),
			totalColumnTitle.length - 2),
		minColumnWidth, maxColumnWidth) + 2;

	void writeN(char c, size_t n) {
		foreach (i; 0..n) {
			write(c);
		}
	}
	void writePad(size_t contentWidth = 0, char paddingChar = ' ') {
		int n = columnWidth - clampToInt(
			contentWidth, 0, maxColumnWidth);
		if (n > 0) {
			writeN(paddingChar, n);
		}
	}
	void markColumn(string border) {
		write(' ');
		if (markColumns) {
			write(border);
		}
	}

	if (debugMode) {
		writeln("column width: ", columnWidth);
	}

	writePad();
	write(' ');
	if (showTotal) {
		markColumn("| ");
		writePad(totalColumnTitle.length);
		write(totalColumnTitle);
	}
	foreach (filename; args) {
		markColumn("| ");
		writePad(filename.length + 2);
		write('‘', filename, '’');
	}
	writeln();

	foreach (match, matchQtyPerFile; matchListsByMatch) {
		if (showOnlyShared && matchFiles[match] < 2) {
			continue;
		}
		if (markRows) {
			writeN('-', columnWidth);
			foreach (i; 0..(args.length + showTotal)) {
				if (markColumns) {
					write("-+");
				}
				writeN('-', columnWidth + 1);
			}
			writeln();
		}
		write('‘', match, '’');
		writePad(match.length + 2);
		if (showTotal) {
			markColumn(" |");
			writef("%*s", columnWidth, matchTotals.get(match, 0));
		}
		foreach (filename; args) {
			markColumn(" |");
			writef("%*s", columnWidth,
				matchQtyPerFile.get(filename, 0));
		}
		writeln();
	}

	return 0;
}

immutable(size_t[string]) processFile(string filename, Regex!char rx) {
	return processText(readText(filename), rx);
}

immutable(size_t[string]) processText(string text, Regex!char rx) {
	size_t[string] matchList;
	foreach (m; match(text, rx)) {
		matchList[m.hit] += 1;
	}
	return cast(immutable) matchList.dup;
}

@safe pure nothrow size_t greater(size_t x, size_t y) {
	if (x > y) {
		return x;
	}
	else {
		return y;
	}
}

@safe pure nothrow size_t greatestLength(string[] strings) {
	size_t l = 0;
	foreach (s; strings) {
		if (s.length > l) {
			l = s.length;
		}
	}
	return l;
}

@safe pure nothrow int clampToInt(size_t n, int min, int max)
	in {
		assert(min <= max);
	}
	out (result) {
		assert(result >= min && result <= max);
	}
body {
	if (n < max) {
		if (n > min) {
			return cast(int) n;
		}
		else {
			return min;
		}
	}
	else {
		return max;
	}
}
