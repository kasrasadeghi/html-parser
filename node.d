module node;

import std.stdio;      // writeln
import std.algorithm;  // each
import std.string;     // splitLines
import std.array;      // replicate

class Node {
  this(string value, Node parent) {
    this.value  = value;
    this.parent = parent;
  }

  string value;
  Node[] children;
  Node parent;
}

string indent(string block, int level) {
  string prefix = " ".replicate(level);
  return block.splitLines.map!(a => prefix ~ a).join("\n");
}

void writeNode(Node node, int level) {
  indent(node.value, level * 2).writeln;
  node.children.each!(a => a.writeNode(level + 1));
}
