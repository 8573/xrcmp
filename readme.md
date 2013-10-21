xrcmp: Cross-referencing Comparison Utility
================================================================================

A utility to cross-reference files and print a table of the occurrences of each
match of a search pattern in each file.


Building xrcmp
--------------------------------------------------------------------------------
This project is written in [D] [1] (version 2), intended to be compiled with
the DMD compiler against the [Phobos] [2] D standard library; and uses the
[tup] [3] build system, as well as a Makefile (usable with, at least, BSD Make
and GNU Make), which is merely a convenient wrapper around tup.

Once you have the above-listed dependencies installed, you can build this
utility by running the shell command `make`.

[1]: <http://dlang.org>
[2]: <http://dlang.org/phobos/>
[3]: <http://gittup.org/tup/>
