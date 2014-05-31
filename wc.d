#!/usr/bin/env rdmd
import std.stdio;
import std.algorithm : max;
import std.string : format;
import std.getopt : getopt;

static const PROGRAM_NAME = "dwc";
static const USAGE = format("usage: %s [OPTION]... [FILE]...\n", PROGRAM_NAME);
static const HELP =
"Print newline, word, and byte counts for each FILE, and a total line if
more than one FILE is specified.  With no FILE, or when FILE is -,
read standard input.  A word is a non-zero-length sequence of characters
delimited by white space.
The options below may be used to select which counts are printed, always in
the following order: newline, word, character.
  -m, --chars            print the character counts
  -l, --lines            print the newline counts
  -w, --words            print the word counds";

struct options {
  bool words, chars, lines, help;
  string[] files;
}

struct counts {
  ulong wc; // word count
  ulong lc; // line count
  ulong cc; // char count
}

counts total; // total counts

void usage()
{
  writefln(USAGE);
  writeln(HELP);
}

int main(string[] args)
{
  try {
    options opts = getopts(args);

    if(opts.help) {
      usage();
      return 0;
    }

    if(opts.files.length == 0) {
      wc(stdin, opts);
    }
    else {
      File* f;
      foreach(fn; opts.files) {
        f = new File(fn);
        auto cnts = wc(*f, opts);

        writecounts(fn, cnts, opts);
      }
    }
  }
  catch(Exception e) {
    writeln(e.msg);
    usage();
    return 1;
  }
  return 0;
}

void writecounts(string fn, counts cnts, options opts)
{
  auto nwidth = getmaxwidth(cnts);
  string format_int = " %*s";

  if (opts.lines) writef(format_int, nwidth, cnts.lc);
  if (opts.words) writef(format_int, nwidth, cnts.wc);
  if (opts.chars) writef(format_int, nwidth, cnts.cc);

  writef(" %s\n", fn);
}

uint getmaxwidth(counts cnts) {
  auto wc_w = getwidth(cnts.wc);
  auto cc_w = getwidth(cnts.cc);
  auto lc_w = getwidth(cnts.lc);
  return max(wc_w, cc_w, lc_w);
}

uint getwidth(ulong i) {
  uint m = 1;

  while(i > 0) {
    i /= 10;
    m++;
  }

  return m < 7 ? 7 : m;
}

counts wc(ref File f, options opts)
{
  counts cnts;
  cnts.cc = f.size;

  if (cnts.cc < 10_000_000) {
    if (!opts.lines && !opts.chars && !opts.words) return cnts;
    foreach (l; f.byLine()) {
      cnts.lc++;

      auto inword = false;
      foreach (j, c; l) {
        switch (c) {
          case '\t':
          case '\r':
          case '\f':
          case '\v':
          case ' ':
            cnts.wc += inword;
            inword = false;
            break;
          default:
            inword = true;
            if (j == l.length - 1) cnts.wc++;
            break;
        }
      }
    }
  }
  else {
    //auto b = new BufferedFile(f); <- this gives me an error; are the docs wrong?
  }

  return cnts;
}

options getopts(ref string[] args) {
  options opts;

  getopt(
    args,
    std.getopt.config.bundling,
    "chars|c", &opts.chars,
    "lines|l", &opts.lines,
    "words|w", &opts.words,
    "help|h", &opts.help
  );
  opts.files = args[1..$];

  if (!opts.chars && !opts.lines && !opts.words) {
    opts.chars = opts.lines = opts.words = true;
  }

  return opts;
}
