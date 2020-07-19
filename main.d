import std.stdio;       // writeln
import std.file;        // readText
import std.algorithm;   // find
import std.range;       // each
import std.string;      // strip

struct Node {
  this(string value, Node* parent) {
    this.value  = value;
    this.parent = parent;
  }

  string value;
  Node[] children;
  Node* parent;
}

void writeNode(ref Node node, int level) {
  // "1 ".repeat(level).join.write;
  (level + 1).iota.write;
  node.value.writeln;
  node.children.each!(a => a.writeNode(level + 1));
}

void main() {
  string S = "test.html".readText;

  auto root = Node("root", null);

  Node* curr = &root;

  void handle(string el) {
    if (el.startsWith("<!")) return;

    curr.children ~= Node(el.strip, curr);

    if (el.startsWith("</")) {
      if (curr)
        curr = curr.parent;
      return;
    }

    if (el.startsWith("<")) {
      curr = &curr.children[$ - 1];
    }
  }

  while (S.length != 0) {
    auto inner_open = S.findSplitBefore("<");
    auto inner = inner_open[0];
    handle(inner);
    auto open  = inner_open[1];

    auto tag_rest = open.findSplitAfter(">");
    auto tag = tag_rest[0];
    handle(tag);
    S = tag_rest[1];
  }

  writeNode(root, 0);
}
