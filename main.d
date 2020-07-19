import std.stdio;       // writeln
import std.file;        // readText
import std.algorithm;   // find
import std.range;       // each
import std.string;      // strip

struct Options {
  bool addCloseTag = false;
  bool ignoreEmpty = true;
  bool elementNormalize = true;
}

class Node {
  this(string value, Node parent) {
    this.value  = value;
    this.parent = parent;
  }

  string value;
  Node[] children;
  Node parent;
}

void writeNode(ref Node node, int level) {
  // (level + 1).iota.write; node.value.writeln;
  indent(node.value, level * 2).writeln;
  node.children.each!(a => a.writeNode(level + 1));
}

string parseSpecial(string value) {
  if (value.countUntil(" ") != -1
      && value.countUntil(" ") < value.countUntil(">")) {
    return value.findSplitBefore(" ")[0];
  } else {
    return value.findSplitBefore(">")[0];
  }
}

string elementNormalize(string value) {
  string[] acc;
  auto tag = parseSpecial(value);
  acc ~= tag;
  value = value[tag.length .. $].stripLeft;

  while (value != ">") {
    if ((value.countUntil(" ") != -1)
        && (value.countUntil(" ") < value.countUntil("="))) {

      acc  ~= value.findSplitBefore(" ")[0];
      value = value.drop(acc[$-1].length);

      value = value.stripLeft;
      continue;
    }

    acc  ~= value.findSplitAfter("=")[0];
    value = value.drop(acc[$-1].length);

    auto after = "\"" ~ value[1 .. $].findSplitAfter("\"")[0];
    acc[$-1] ~= after;
    value = value.drop(after.length);

    value = value.stripLeft;
  }

  return acc.join(" ") ~ ">";
}

string tag(string line) {
  auto rest = line.findSplitAfter("<")[1];

  return parseSpecial(rest);
}

string indent(string block, int level) {
  string prefix = " ".replicate(level);
  return block.splitLines.map!(a => prefix ~ a).join("\n");
}

void main(string[] args) {
  if (args.length != 2) {
    "usage: ./html-parser example.html".writeln;
  }

  Options options;
  string S = args[1].readText.strip;

  auto root = new Node("<root>", null);

  Node curr = root;

  void handle(string line) {

    // TODO also drop comments
    if (line.startsWith("<!")) return;
    if (options.ignoreEmpty && line.strip == "") return;

    Node child = new Node(line.strip, curr);

    // TODO handle self-closing <tag/> elements

    if (line.startsWith("</")) {
      if (! curr) {"unmatched close tag with ".write; line.writeln;}

      // if we're closing something that did not need to be closed
      //   add its children to the ancestor that closes it
      if ("/" ~ tag(curr.value) != tag(child.value)) {

        while (tag(child.value) != "/" ~ tag(curr.value)) {
          curr.parent.children ~= curr.children;
          curr.parent.children.each!((ref Node node) {
              node.parent = curr.parent;
            });
          curr.children = [];
          curr = curr.parent;
        }
      }
      if (options.addCloseTag) { curr.children ~= child; }
      curr = curr.parent;
      return;
    }

    curr.children ~= child;

    if (line.startsWith("<")) {
      curr = curr.children[$ - 1];
    }
  }

  while (S.length != 0) {
    auto inner_open = S.findSplitBefore("<");
    auto inner = inner_open[0];
    handle(inner);
    auto open  = inner_open[1];

    auto element_rest = open.findSplitAfter(">");
    auto element = element_rest[0];
    handle(element);

    S = element_rest[1];
  }

  void normalize(Node node) {
    if (node.value.startsWith("<")) {
      node.value = elementNormalize(node.value);
    }

    foreach (child; node.children) {
      normalize(child);
    }
  }

  normalize(root);

  writeNode(root, 0);
}

void test() {
  auto test = "<script defer src=\"chrome-search://local-ntp/voice.js\"
                       integrity=\"sha256-C9ctze2LhHtwL+fcPVPkmVRYjQgXTGs4xfBAzlQwGWk=\">";

  test.writeln;
  elementNormalize(test).writeln;
}
