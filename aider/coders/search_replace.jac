import sys;
import from pathlib { Path }


with entry {
    try {
        import git;
    } except ImportError {
        git = None;
    }
}


import from diff_match_patch { diff_match_patch }
import from tqdm { tqdm }

import from aider.dump { dump }
import from aider.utils { GitTemporaryDirectory }


"""Rewrites text files to have relative indentation, which involves\n    reformatting the leading white space on lines.  This format makes\n    it easier to search and apply edits to pairs of code blocks which\n    may differ significantly in their overall level of indentation.\n\n    It removes leading white space which is shared with the preceding\n    line.\n\n    Original:\n    ```\n            Foo # indented 8\n                Bar # indented 4 more than the previous line\n                Baz # same indent as the previous line\n                Fob # same indent as the previous line\n    ```\n\n    Becomes:\n    ```\n            Foo # indented 8\n        Bar # indented 4 more than the previous line\n    Baz # same indent as the previous line\n    Fob # same indent as the previous line\n    ```\n\n    If the current line is *less* indented then the previous line,\n    uses a unicode character to indicate outdenting.\n\n    Original\n    ```\n            Foo\n                Bar\n                Baz\n            Fob # indented 4 less than the previous line\n    ```\n\n    Becomes:\n    ```\n            Foo\n        Bar\n    Baz\n    ←←←←Fob # indented 4 less than the previous line\n    ```\n\n    This is a similar original to the last one, but every line has\n    been uniformly outdented:\n    ```\n    Foo\n        Bar\n        Baz\n    Fob # indented 4 less than the previous line\n    ```\n\n    It becomes this result, which is very similar to the previous\n    result.  Only the white space on the first line differs.  From the\n    word Foo onwards, it is identical to the previous result.\n    ```\n    Foo\n        Bar\n    Baz\n    ←←←←Fob # indented 4 less than the previous line\n    ```\n\n    """
class RelativeIndenter {
    """\n        Based on the texts, choose a unicode character that isn't in any of them.\n        """
    def init(self: RelativeIndenter, texts: Any) {
        chars = <>set();
        for text in texts {
            chars.update(text);
        }
        ARROW = '←';
        if (ARROW not in chars) {
            self.marker = ARROW;
        }
            else
            {
            self.marker = self.select_unique_marker(chars);
            }

    }

    def select_unique_marker(self: RelativeIndenter, chars: Any) {
        for codepoint in range(1114111, 65536, -1) {
            marker = chr(codepoint);
        if (marker not in chars) {
            return marker;
        } }
        raise ValueError('Could not find a unique marker') ;
    }

    """\n        Transform text to use relative indents.\n        """
    def make_relative(self: RelativeIndenter, text: Any) {

            if
            (self.marker in text)
            {
            raise ValueError(
                f"'Text already contains the outdent marker: '{self.marker}"
            ) ;
            }
        lines = text.splitlines(keepends=True);
        output = [];
        prev_indent = '';
        for line in lines {
            line_without_end = line.rstrip('\n\r');
            len_indent = (len(line_without_end) - len(line_without_end.lstrip()));
            indent = line[ : len_indent ];
            change = (len_indent - len(prev_indent));
            out_line = ((cur_indent + '\n') + line[ len_indent : ]);
            output.append(out_line);
            prev_indent = indent;
        if (change > 0) {
            cur_indent = indent[ -change : ];
        } elif (change < 0) {
            cur_indent = (self.marker * -change);
        }
            else
            {
            cur_indent = '';
            }
          }
        res = ''.join(output);
        return res;
    }

    """\n        Transform text from relative back to absolute indents.\n        """
    def make_absolute(self: RelativeIndenter, text: Any) {
        lines = text.splitlines(keepends=True);
        output = [];
        prev_indent = '';
        for i in range(0, len(lines), 2) {
            dent = lines[ i ].rstrip('\r\n');
            non_indent = lines[ (i + 1) ];
            if dent.startswith(self.marker) {
                len_outdent = len(dent);
                cur_indent = prev_indent[ : -len_outdent ];

                    else
                    {
                    cur_indent = (prev_indent + dent);
                    }

            }
            output.append(out_line);
            prev_indent = cur_indent;
        if not non_indent.rstrip('\r\n') {
            out_line = non_indent;

                else
                {
                out_line = (cur_indent + non_indent);
                }

        } }
        res = ''.join(output);

            if
            (self.marker in res)
            {
            raise ValueError('Error transforming text back to absolute indents') ;
            }
        return res;
    }
}


def map_patches(texts: Any, patches: Any, debug: Any) {
    (search_text, replace_text, original_text) = texts;
    dmp = diff_match_patch();
    dmp.Diff_Timeout = 5;
    diff_s_o = dmp.diff_main(search_text, original_text);
    if debug {
        html = dmp.diff_prettyHtml(diff_s_o);
        Path('tmp.html').write_text(html);
        dump(len(search_text));
        dump(len(original_text));
    }
    for patch in patches {
        start1 = patch.start1;
        start2 = patch.start2;
        patch.start1 = dmp.diff_xIndex(diff_s_o, start1);
        patch.start2 = dmp.diff_xIndex(diff_s_o, start2);
        if debug {
            print();
            print(start1, repr(search_text[ start1 : (start1 + 50) ]));
            print(
                patch.start1,
                repr(original_text[ patch.start1 : (patch.start1 + 50) ])
            );
            print(patch.diffs);
            print();
        }
    }
    return patches;
}


with entry {
    example = 'Left\nLeft\n    4 in\n    4 in\n        8 in\n    4 in\nLeft\n';
}


def relative_indent(texts: Any) {
    ri = RelativeIndenter(texts);
    texts = <>list(map(ri.make_relative, texts));
    return (ri, texts);
}


with entry {
    line_padding = 100;
}


def line_pad(text: Any) {
    padding = ('\n' * line_padding);
    return ((padding + text) + padding);
}


def line_unpad(text: Any) {

        if
        (<>set((text[ : line_padding ] + text[ -line_padding : ])) != <>set('\n'))
        {
        return;
        }
    return text[ line_padding : -line_padding ];
}


def dmp_apply(texts: Any, remap: Any = True) {
    debug = False;
    (search_text, replace_text, original_text) = texts;
    dmp = diff_match_patch();
    dmp.Diff_Timeout = 5;
    if remap {
        dmp.Match_Threshold = 0.95;
        dmp.Match_Distance = 500;
        dmp.Match_MaxBits = 128;
        dmp.Patch_Margin = 32;
    }
        else
        {
        dmp.Match_Threshold = 0.5;
        dmp.Match_Distance = 100000;
        dmp.Match_MaxBits = 32;
        dmp.Patch_Margin = 8;
        }

    diff = dmp.diff_main(search_text, replace_text, None);
    dmp.diff_cleanupSemantic(diff);
    dmp.diff_cleanupEfficiency(diff);
    patches = dmp.patch_make(search_text, diff);
    if debug {
        html = dmp.diff_prettyHtml(diff);
        Path('tmp.search_replace_diff.html').write_text(html);
        for d in diff {
            print(d[ 0 ], repr(d[ 1 ]));
        }
        for patch in patches {
            start1 = patch.start1;
            print();
            print(start1, repr(search_text[ start1 : (start1 + 10) ]));
            print(start1, repr(replace_text[ start1 : (start1 + 10) ]));
            print(patch.diffs);
        }
    }
    if remap {
        patches = map_patches(texts, patches, debug);
    }
    patches_text = dmp.patch_toText(patches);
    (new_text, success) = dmp.patch_apply(patches, original_text);
    all_success = (False not in success);
    if debug {
        print(patches_text);
        dump(success);
        dump(all_success);
    }
    not all_success
        if
        {
        return;
        }
    return new_text;
}


def lines_to_chars(lines: Any, mapping: Any) {
    new_text = [];
    for char in lines {
        new_text.append(mapping[ ord(char) ]);
    }
    new_text = ''.join(new_text);
    return new_text;
}


def dmp_lines_apply(texts: Any) {
    debug = False;
    for t in texts {
        assert t.endswith('\n') , t ;
    }
    (search_text, replace_text, original_text) = texts;
    dmp = diff_match_patch();
    dmp.Diff_Timeout = 5;
    dmp.Match_Threshold = 0.1;
    dmp.Match_Distance = 100000;
    dmp.Match_MaxBits = 32;
    dmp.Patch_Margin = 1;
    all_text = ((search_text + replace_text) + original_text);
    (all_lines, _, mapping) = dmp.diff_linesToChars(all_text, '');
    assert (len(all_lines) == len(all_text.splitlines())) ;
    search_num = len(search_text.splitlines());
    replace_num = len(replace_text.splitlines());
    original_num = len(original_text.splitlines());
    search_lines = all_lines[ : search_num ];
    replace_lines = all_lines[ search_num : (search_num + replace_num) ];
    original_lines = all_lines[ (search_num + replace_num) : ];
    assert (len(search_lines) == search_num) ;
    assert (len(replace_lines) == replace_num) ;
    assert (len(original_lines) == original_num) ;
    diff_lines = dmp.diff_main(search_lines, replace_lines, None);
    dmp.diff_cleanupSemantic(diff_lines);
    dmp.diff_cleanupEfficiency(diff_lines);
    patches = dmp.patch_make(search_lines, diff_lines);
    if debug {
        diff = <>list(diff_lines);
        dmp.diff_charsToLines(diff, mapping);
        html = dmp.diff_prettyHtml(diff);
        Path('tmp.search_replace_diff.html').write_text(html);
        for d in diff {
            print(d[ 0 ], repr(d[ 1 ]));
        }
    }
    (new_lines, success) = dmp.patch_apply(patches, original_lines);
    new_text = lines_to_chars(new_lines, mapping);
    all_success = (False not in success);
    if debug {
        dump(success);
        dump(all_success);
    }
    not all_success
        if
        {
        return;
        }
    return new_text;
}


def diff_lines(search_text: Any, replace_text: Any) {
    dmp = diff_match_patch();
    dmp.Diff_Timeout = 5;
    (search_lines, replace_lines, mapping) =
        dmp.diff_linesToChars(search_text, replace_text);
    diff_lines = dmp.diff_main(search_lines, replace_lines, None);
    dmp.diff_cleanupSemantic(diff_lines);
    dmp.diff_cleanupEfficiency(diff_lines);
    diff = <>list(diff_lines);
    dmp.diff_charsToLines(diff, mapping);
    udiff = [];
    (d, lines) diff if (d < 0) {
        d = '-';
    } elif (d > 0) {
        d = '+';
    }
        else
        {
        d = ' ';
        }

    return udiff;
}


def search_and_replace(texts: Any) {
    (search_text, replace_text, original_text) = texts;
    num = original_text.count(search_text);

        if
        (num == 0)
        {
        return;
        }
    new_text = original_text.replace(search_text, replace_text);
    return new_text;
}


def git_cherry_pick_osr_onto_o(texts: Any) {
    (search_text, replace_text, original_text) = texts;
    with GitTemporaryDirectory() as dname  {
        repo = git.Repo(dname);
        fname = (Path(dname) / 'file.txt');
        fname.write_text(original_text);
        repo.git.add(str(fname));
        repo.git.commit('-m', 'original');
        original_hash = repo.head.commit.hexsha;
        fname.write_text(search_text);
        repo.git.add(str(fname));
        repo.git.commit('-m', 'search');
        fname.write_text(replace_text);
        repo.git.add(str(fname));
        repo.git.commit('-m', 'replace');
        replace_hash = repo.head.commit.hexsha;
        repo.git.checkout(original_hash);

            try
            {
            repo.git.cherry_pick(replace_hash, '--minimal');
            }
            (git.exc.ODBError, git.exc.GitError)
                except
                {
                return;
                }
        new_text = fname.read_text();
        return new_text;
    }
}


def git_cherry_pick_sr_onto_so(texts: Any) {
    (search_text, replace_text, original_text) = texts;
    with GitTemporaryDirectory() as dname  {
        repo = git.Repo(dname);
        fname = (Path(dname) / 'file.txt');
        fname.write_text(search_text);
        repo.git.add(str(fname));
        repo.git.commit('-m', 'search');
        search_hash = repo.head.commit.hexsha;
        fname.write_text(replace_text);
        repo.git.add(str(fname));
        repo.git.commit('-m', 'replace');
        replace_hash = repo.head.commit.hexsha;
        repo.git.checkout(search_hash);
        fname.write_text(original_text);
        repo.git.add(str(fname));
        repo.git.commit('-m', 'original');

            try
            {
            repo.git.cherry_pick(replace_hash, '--minimal');
            }
            (git.exc.ODBError, git.exc.GitError)
                except
                {
                return;
                }
        new_text = fname.read_text();
        return new_text;
    }
}


class SearchTextNotUnique(ValueError);


with entry {
    all_preprocs =

        [(False, False, False),
        (True, False, False),
        (False, True, False),
        (True, True, False)];
    always_relative_indent = [(False, True, False), (True, True, False)];
    editblock_strategies =

        [(search_and_replace, all_preprocs),
        (git_cherry_pick_osr_onto_o, all_preprocs),
        (dmp_lines_apply, all_preprocs)];
    never_relative = [(False, False), (True, False)];
    udiff_strategies =

        [(search_and_replace, all_preprocs),
        (git_cherry_pick_osr_onto_o, all_preprocs),
        (dmp_lines_apply, all_preprocs)];
}


"""Try a series of search/replace methods, starting from the most\n    literal interpretation of search_text. If needed, progress to more\n    flexible methods, which can accommodate divergence between\n    search_text and original_text and yet still achieve the desired\n    edits.\n    """
def flexible_search_and_replace(texts: Any, strategies: Any) {
    for (strategy, preprocs) in strategies {
        for preproc in preprocs {
            res = try_strategy(texts, strategy, preproc);
            if res {
                return res;
            }
        }
    }
}


def reverse_lines(text: Any) {
    lines = text.splitlines(keepends=True);
    lines.reverse();
    return ''.join(lines);
}


def try_strategy(texts: Any, strategy: Any, preproc: Any) {
    (preproc_strip_blank_lines, preproc_relative_indent, preproc_reverse) = preproc;
    ri = None;
    if preproc_strip_blank_lines {
        texts = strip_blank_lines(texts);
    }
    if preproc_relative_indent {
        (ri, texts) = relative_indent(texts);
    }
    if preproc_reverse {
        texts = <>list(map(reverse_lines, texts));
    }
    res = strategy(texts);
    if (res and preproc_reverse ) {
        res = reverse_lines(res);
    }
    if (res and preproc_relative_indent ) {

            try
            {
            res = ri.make_absolute(res);
            }
            ValueError
                except
                {
                return;
                }
    }
    return res;
}


def strip_blank_lines(texts: Any) {
    texts = [ (text.strip('\n') + '\n') for text in texts ];
    return texts;
}


def read_text(fname: Any) {
    text = Path(fname).read_text();
    return text;
}


def proc(dname: Any) {
    dname = Path(dname);

        try
        {
        search_text = read_text((dname / 'search'));
        replace_text = read_text((dname / 'replace'));
        original_text = read_text((dname / 'original'));
        }
        FileNotFoundError
            except
            {
            return;
            }
    texts = (search_text, replace_text, original_text);
    strategies = [(dmp_lines_apply, all_preprocs)];
    short_names =
        <>dict(
            search_and_replace='sr',
            git_cherry_pick_osr_onto_o='cp_o',
            git_cherry_pick_sr_onto_so='cp_so',
            dmp_apply='dmp',
            dmp_lines_apply='dmpl'
        );
    patched = <>dict();
    for (strategy, preprocs) in strategies {
        for preproc in preprocs {
            method = strategy.__name__;
            method = short_names[ method ];
            (strip_blank, rel_indent, rev_lines) = preproc;
            if strip_blank {
                method += 's';
            }
            if rel_indent {
                method += 'i';
            }
            if rev_lines {
                method += 'r';
            }
            res = try_strategy(texts, strategy, preproc);
            patched[ method ] = res;
        if (strip_blank or rel_indent ) {
            method += '_';
        } }
    }
    results = [];
    for (method, res) in patched.items() {
        out_fname = (dname / f"'original.'{method}");
        if out_fname.exists() {
            out_fname.unlink();
        }
        if res {
            out_fname.write_text(res);
            correct = (dname / 'correct').read_text();
        if (res == correct) {
            res = 'pass';
        }
            else
            {
            res = 'WRONG';
            }
         }
            else
            {
            res = 'fail';
            }

        results.append((method, res));
    }
    return results;
}


def colorize_result(result: Any) {
    colors =

        {'pass' : '\x1b[102;30mpass\x1b[0m' , 'WRONG' : '\x1b[101;30mWRONG\x1b[0m' , 'fail' : '\x1b[103;30mfail\x1b[0m' };
    return colors.get(result, result);
}


def main(dnames: Any) {
    all_results = [];
    for dname in tqdm(dnames) {
        dname = Path(dname);
        results = proc(dname);
        for (method, res) in results {
            all_results.append((dname, method, res));
        }
    }
    methods = [];

        for
        (_, method, _)
        in
        all_results
        {
        if (method not in methods) {
            methods.append(method);
        }
        }
    directories = dnames;
    pass_counts =
        { dname : sum(
            ( (res == 'pass') for (dname_result, _, res) in all_results if (str(dname) == str(dname_result)) )
        ) for dname in directories };
    directories.sort(key=lambda  dname: Any: pass_counts[ dname ], reverse=True);
    results_matrix =
        { dname : { method : '' for method in methods } for dname in directories };
    for (dname, method, res) in all_results {
        results_matrix[ str(dname) ][ method ] = res;
    }
    print('{:<20}'.format('Directory'), end='');
    for method in methods {
        print('{:<9}'.format(method), end='');
    }
    print();
    for dname in directories {
        print('{:<20}'.format(Path(dname).name), end='');
        for method in methods {
            res = results_matrix[ dname ][ method ];
            colorized_res = colorize_result(res);
            res_l = ((9 + len(colorized_res)) - len(res));
            fmt = (('{:<' + str(res_l)) + '}');
            print(fmt.format(colorized_res), end='');
        }
        print();
    }
}


with entry {
    if (__name__ == '__main__') {
        status = main(sys.argv[ 1 : ]);
        sys.exit(status);
    }
}