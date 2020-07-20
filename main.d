import parser;
import node;

import std.path;        // absolutePath
import std.stdio;       // write[f]ln
import std.file;        // exists

void main(string[] args) {
  if (args.length != 2) {
    "usage: ./html-parser example.html".writeln;
    return;
  }

  if (! args[1].exists) {
    "file '%s' does not exist".writefln(args[1].absolutePath);
    return;
  }

  Options options;
  Node root = parse(options, args[1]);
  writeNode(root, 0);
}
