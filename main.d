import std.stdio;       // writeln
import std.file;        // readText, exists
import std.path;        // absolutePath
import std.algorithm;   // find
import std.range;       // each
import std.string;      // strip

import core.stdc.stdlib; // exit

struct Options {
  bool addCloseTag = false;
  bool ignoreEmpty = true;
  bool elementNormalize = true;
  bool keepComments = false;
  bool keepScriptContents = false;
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
  auto tag = value.parseSpecial;
  acc ~= tag;
  value = value[tag.length .. $].stripLeft;

  while (value != ">") {

    // handle attributes without values, only keys (like defer in <script defer src="...">)
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

  return rest.parseSpecial;
}

string indent(string block, int level) {
  string prefix = " ".replicate(level);
  return block.splitLines.map!(a => prefix ~ a).join("\n");
}

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
  string S = args[1].readText.strip;

  auto root = new Node("<root>", null);

  Node curr = root;

  void handle(string line) {
    if (options.ignoreEmpty && line.strip == "") return;

    Node child = new Node(line.strip, curr);

    // TODO handle self-closing <tag/> elements

    if (line.startsWith("</")) {
      if (! curr) {"unmatched close tag with ".write; line.writeln;}

      // if we're closing something that did not need to be closed
      //   add its children to the ancestor that closes it
      if ("/" ~ tag(curr.value) != tag(child.value)) {

        while ("/" ~ tag(curr.value) != tag(child.value)) {
          auto parent = curr.parent;
          if (parent is null) {
            writeNode(curr, 0);
            writeln;
            "current node has no parent:".writeln;
            writeNode(child, 0);
            "ERROR: found a closing tag with no open".writeln;
            exit(0);
          }
          parent.children ~= curr.children;
          parent.children.each!((Node node) {
              node.parent = parent;
            });
          curr.children = [];
          curr = parent;
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

    // handle arbitrary contents of script tags by searching for </script
    if (open.startsWith("<script")) {
      auto script_rest = open.findSplitAfter(">");
      auto script_tag = script_rest[0];
      handle(script_tag);

      S = script_rest[1];

      auto endscript_open = S.findSplitBefore("</script");
      auto script_contents = endscript_open[0];
      if (options.keepScriptContents) {
        handle(script_contents);
      }

      open = endscript_open[1];

    } else if (open.startsWith("<!--")) {
      auto comment_rest = open.findSplitAfter("-->");
      auto comment = comment_rest[0];
      if (options.keepComments) {
        handle(comment);
      }

      S = comment_rest[1];
      continue;
    }

    // TODO handle attribute values with ">" in them

    auto element_rest = open.findSplitAfter(">");
    auto element = element_rest[0];
    handle(element);

    S = element_rest[1];
  }

  void normalize(Node node) {
    if (node.value.startsWith("<!--")) return;

    if (node.value.startsWith("<")) {
      node.value = elementNormalize(node.value);
    }

    foreach (child; node.children) {
      normalize(child);
    }
  }

  if (options.elementNormalize) {
    normalize(root);
  }

  writeNode(root, 0);
}

void test() {
  auto test = "<script defer src=\"blah-blah\"
                       integrity=\"huh-whats-that\">";

  test.writeln;
  elementNormalize(test).writeln;
}
