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

//==== Node Core =================================

Node dup(Node node) {
  auto result = new Node(node.value, node.parent);
  result.children = node.children.dup;
  return result;
}

Node[] dup(Node[] children) {
  Node[] acc;
  foreach (c; children) {
    acc ~= c.dup;
  }
  return acc;
}

string indent(string block, int level) {
  string prefix = " ".replicate(level);
  return block.splitLines.map!(a => prefix ~ a).join("\n");
}

void writeNode(int maxlevel = -1)(Node node, int level = 0) {

  if (node is null) {
    indent("null", level * 2).writeln;
    return;
  }

  indent(node.value, level * 2).writeln;
  static if (maxlevel == -1) {
    node.children.each!(a => a.writeNode(level + 1));
  } else {
    if (level > maxlevel) return;
    node.children.each!(a => a.writeNode!(maxlevel)(level + 1));
  }
}

void mutateNode(Node node, void delegate(Node) f) {
  f(node);

  foreach (child; node.children) {
    mutateNode(child, f);
  }
}

Node[] flatNode(Node node) {
  Node[] acc;
  mutateNode(node, (Node n) {
      acc ~= n;
    });
  return acc;
}

// does not apply f to node, only children
Node applyNode(Node node, Node[] delegate(Node) f) {
  Node copy = new Node(node.value, null);

  // copy all of the children using the expander function
  foreach (old_child; node.children) {
    Node[] new_children = f(old_child);
    foreach (new_child; new_children) {
      new_child.parent = copy;
    }
    copy.children ~= new_children;
  }

  // apply the function to all of the children
  foreach (ref child; copy.children) {
    child = applyNode(child, f);
  }

  return copy;
}

Node trimNode(Node node, bool delegate(Node) f) {
  return applyNode(node, n => (f(n) ? [] : [n]));
}

Node index(Node node, size_t index) {
  return node.children[index];
}

Node index(Node node, size_t[] indices) {
  Node curr = node;
  foreach (i; indices) {
    if (i >= curr.children.length) {
      return null;
    }
    curr = curr.children[i];
  }
  return curr;
}

//==== Node HTML ===================================================

string parseSpecial(string value) {
  if (value.countUntil(" ") != -1
      && value.countUntil(" ") < value.countUntil(">")) {
    return value.findSplitBefore(" ")[0];
  } else {
    return value.findSplitBefore(">")[0];
  }
}

string tag(string line) {
  auto rest = line.findSplitAfter("<")[1];

  return rest.parseSpecial;
}

// trims subtrees that match any tag in tags
Node trimTagsNode(Node node, string[] tags) {
  return trimNode(node, (Node node) {
      return node.value.startsWith("<")
        && tags.any!(t => node.value.startsWith("<" ~ t));
    });
}
