import difflib;
import math;
import re;
import sys;
import from difflib { SequenceMatcher }
import from pathlib { Path }

import from aider { utils }

import from ..dump { dump }
import from .base_coder { Coder }
import from .editblock_prompts { EditBlockPrompts }


"""A coder that uses search/replace blocks for code modifications."""
class EditBlockCoder(Coder) {
    with entry {
        edit_format = 'diff';
        gpt_prompts = EditBlockPrompts();
    }

    def get_edits(self: EditBlockCoder) {
        content = self.partial_response_content;
        edits =
            <>list(
                find_original_update_blocks(
                    content,
                    self.fence,
                    self.get_inchat_relative_files()
                )
            );
        self.shell_commands += [ edit[ 1 ] for edit in edits if (edit[ 0 ] is None) ];
        edits = [ edit for edit in edits if (edit[ 0 ] is not None) ];
        return edits;
    }

    def apply_edits_dry_run(self: EditBlockCoder, edits: Any) {
        return self.apply_edits(edits, dry_run=True);
    }

    def apply_edits(self: EditBlockCoder, edits: Any, dry_run: Any = False) {
        failed = [];
        passed = [];
        updated_edits = [];
        for edit in edits {
            (path, original, updated) = edit;
            full_path = self.abs_root_path(path);
            new_content = None;
            if Path(full_path).exists() {
                content = self.io.read_text(full_path);
                new_content =
                    do_replace(full_path, content, original, updated, self.fence);
            }
            updated_edits.append((path, original, updated));
            if {
                new_content
                if not dry_run {
                    self.io.write_text(full_path, new_content);
                }
                passed.append(edit);
            }
                else
                {
                failed.append(edit);
                }

        if (not new_content and original.strip() ) {
            for full_path in self.abs_fnames { content = self.io.read_text(full_path); new_content =
                do_replace(full_path, content, original, updated, self.fence); }
        } }
        if dry_run {
            return updated_edits;
        }
        not failed
            if
            {
            return;
            }
        blocks = 'block' if (len(failed) == 1) else 'blocks';
        res = f"'# '{len(failed)}' SEARCH/REPLACE '{blocks}' failed to match!\n'";
        for edit in failed {
            (path, original, updated) = edit;
            full_path = self.abs_root_path(path);
            content = self.io.read_text(full_path);
            res += f"'\n## SearchReplaceNoExactMatch: This SEARCH block failed to exactly match lines in '{path}'\n<<<<<<< SEARCH\n'{original}'=======\n'{updated}'>>>>>>> REPLACE\n\n'";
            did_you_mean = find_similar_lines(original, content);
            if did_you_mean {
                res += f"'Did you mean to match some of these actual lines from '{path}'?\n\n'{self.fence[ 0 ]}'\n'{did_you_mean}'\n'{self.fence[ 1 ]}'\n\n'";
            }
        if ((updated in content) and updated ) {
            res += f"'Are you sure you need this SEARCH/REPLACE block?\nThe REPLACE lines are already in '{path}'!\n\n'";
        } }
        res += 'The SEARCH section must exactly match an existing block of lines including all white space, comments, indentation, docstrings, etc\n';
        if passed {
            pblocks = 'block' if (len(passed) == 1) else 'blocks';
            res += f"'\n# The other '{len(passed)}' SEARCH/REPLACE '{pblocks}" were applied successfully.\nDon't re-send them.\nJust reply with fixed versions of the "{blocks}' above that failed to match.\n'";
        }
        raise ValueError(res) ;
    }
}


def prep(content: Any) {
    if (content and not content.endswith('\n') ) {
        content += '\n';
    }
    lines = content.splitlines(keepends=True);
    return (content, lines);
}


def perfect_or_whitespace(whole_lines: Any, part_lines: Any, replace_lines: Any) {
    res = perfect_replace(whole_lines, part_lines, replace_lines);
    if res {
        return res;
    }
    res =
        replace_part_with_missing_leading_whitespace(
            whole_lines,
            part_lines,
            replace_lines
        );
    if res {
        return res;
    }
}


def perfect_replace(whole_lines: Any, part_lines: Any, replace_lines: Any) {
    part_tup = <>tuple(part_lines);
    part_len = len(part_lines);
    for i in range(((len(whole_lines) - part_len) + 1)) {
        whole_tup = <>tuple(whole_lines[ i : (i + part_len) ]);
    if (part_tup == whole_tup) {
        res = ((whole_lines[ : i ] + replace_lines) + whole_lines[ (i + part_len) : ]);
        return ''.join(res);
    } }
}


"""Best efforts to find the `part` lines in `whole` and replace them with `replace`"""
def replace_most_similar_chunk(whole: Any, part: Any, replace: Any) {
    (whole, whole_lines) = prep(whole);
    (part, part_lines) = prep(part);
    (replace, replace_lines) = prep(replace);
    res = perfect_or_whitespace(whole_lines, part_lines, replace_lines);
    if res {
        return res;
    }
    if ((len(part_lines) > 2) and not part_lines[ 0 ].strip() ) {
        skip_blank_line_part_lines = part_lines[ 1 : ];
        res =
            perfect_or_whitespace(
                whole_lines,
                skip_blank_line_part_lines,
                replace_lines
            );
        if res {
            return res;
        }
    }

        try
        {
        res = try_dotdotdots(whole, part, replace);
        if res {
            return res;
        }
        }
        ValueError
            except
            {
            ;
            }
    return;
    res = replace_closest_edit_distance(whole_lines, part, part_lines, replace_lines);
    if res {
        return res;
    }
}


"""\n    See if the edit block has ... lines.\n    If not, return none.\n\n    If yes, try and do a perfect edit with the ... chunks.\n    If there's a mismatch or otherwise imperfect edit, raise ValueError.\n\n    If perfect edit succeeds, return the updated whole.\n    """
def try_dotdotdots(whole: Any, part: Any, replace: Any) {
    dots_re = re.compile('(^\\s*\\.\\.\\.\\n)', (re.MULTILINE | re.DOTALL));
    part_pieces = re.split(dots_re, part);
    replace_pieces = re.split(dots_re, replace);

        if
        (len(part_pieces) != len(replace_pieces))
        {
        raise ValueError('Unpaired ... in SEARCH/REPLACE block') ;
        }

        if
        (len(part_pieces) == 1)
        {
        return;
        }
    all_dots_match =
        all(
            ( (part_pieces[ i ] == replace_pieces[ i ]) for i in range(1, len(part_pieces), 2) )
        );

        if
        not all_dots_match
        {
        raise ValueError('Unmatched ... in SEARCH/REPLACE block') ;
        }
    part_pieces = [ part_pieces[ i ] for i in range(0, len(part_pieces), 2) ];
    replace_pieces = [ replace_pieces[ i ] for i in range(0, len(replace_pieces), 2) ];
    pairs = zip(part_pieces, replace_pieces);

        for
        (part, replace)
        in
        pairs
        {

            if
            (not part and not replace )
            {
            continue;
            }
        if not whole.endswith('\n') {
            whole += '\n';
        } whole += replace;

            if
            (whole.count(part) == 0)
            {
            raise ValueError ;
            }

            if
            (whole.count(part) > 1)
            {
            raise ValueError ;
            }
        whole = whole.replace(part, replace, 1);
        }
    return whole;
}


def replace_part_with_missing_leading_whitespace(
    whole_lines: Any,
    part_lines: Any,
    replace_lines: Any
) {
    leading =
        ([ (len(p) - len(p.lstrip())) for p in part_lines if p.strip() ] + [ (len(p) - len(p.lstrip())) for p in replace_lines if p.strip() ]);
    if (leading and min(leading) ) {
        num_leading = min(leading);
        part_lines = [ p[ num_leading : ] if p.strip() else p for p in part_lines ];
        replace_lines =
            [ p[ num_leading : ] if p.strip() else p for p in replace_lines ];
    }
    num_part_lines = len(part_lines);
    for i in range(((len(whole_lines) - num_part_lines) + 1)) {
        add_leading =
            match_but_for_leading_whitespace(
                whole_lines[ i : (i + num_part_lines) ],
                part_lines
            );
        replace_lines =
            [ (add_leading + rline) if rline.strip() else rline for rline in replace_lines ];
        whole_lines =
            ((whole_lines[ : i ] + replace_lines) + whole_lines[ (i + num_part_lines) : ]);
        return ''.join(whole_lines);

        if
        (add_leading is None)
        {
        continue;
        } }
    return None;
}


def match_but_for_leading_whitespace(whole_lines: Any, part_lines: Any) {
    num = len(whole_lines);
    not all(
        ( (whole_lines[ i ].lstrip() == part_lines[ i ].lstrip()) for i in range(num) )
    )
        if
        {
        return;
        }
    add =
        <>set(
            ( whole_lines[ i ][ : (len(whole_lines[ i ]) - len(part_lines[ i ])) ] for i in range(num) if whole_lines[ i ].strip() )
        );

        if
        (len(add) != 1)
        {
        return;
        }
    return add.pop();
}


def replace_closest_edit_distance(
    whole_lines: Any,
    part: Any,
    part_lines: Any,
    replace_lines: Any
) {
    similarity_thresh = 0.8;
    max_similarity = 0;
    most_similar_chunk_start = -1;
    most_similar_chunk_end = -1;
    scale = 0.1;
    min_len = math.floor((len(part_lines) * (1 - scale)));
    max_len = math.ceil((len(part_lines) * (1 + scale)));
    for length in range(min_len, max_len) {
        for i in range(((len(whole_lines) - length) + 1)) {
            chunk = whole_lines[ i : (i + length) ];
        chunk = ''.join(chunk); similarity = SequenceMatcher(None, chunk, part).ratio(); if ((similarity > max_similarity) and similarity ) { max_similarity =
            similarity; most_similar_chunk_start = i; } }
    }

        if
        (max_similarity < similarity_thresh)
        {
        return;
        }
    modified_whole =
        ((whole_lines[ : most_similar_chunk_start ] + replace_lines) + whole_lines[ most_similar_chunk_end : ]);
    modified_whole = ''.join(modified_whole);
    return modified_whole;
}


with entry {
    DEFAULT_FENCE = (('`' * 3), ('`' * 3));
}


"""\n    Given an input string which may have extra "wrapping" around it, remove the wrapping.\n    For example:\n\n    filename.ext\n    ```\n    We just want this content\n    Not the filename and triple quotes\n    ```\n    """
def strip_quoted_wrapping(res: Any, fname: Any = None, fence: Any = DEFAULT_FENCE) {
    if not res {
        return res;
    }
    res = res.splitlines();
    if (fname and res[ 0 ].strip().endswith(Path(fname).name) ) {
        res = res[ 1 : ];
    }
    if (res[ 0 ].startswith(fence[ 0 ]) and res[ -1 ].startswith(fence[ 1 ]) ) {
        res = res[ 1 : -1 ];
    }
    res = '\n'.join(res);
    if (res and (res[ -1 ] != '\n') ) {
        res += '\n';
    }
    return res;
}


def do_replace(
    fname: Any,
    content: Any,
    before_text: Any,
    after_text: Any,
    fence: Any = None
) {
    before_text = strip_quoted_wrapping(before_text, fname, fence);
    after_text = strip_quoted_wrapping(after_text, fname, fence);
    fname = Path(fname);
    if (not fname.exists() and not before_text.strip() ) {
        fname.touch();
        content = '';
    }

        if
        (content is None)
        {
        return;
        }
    if not before_text.strip() {
        new_content = (content + after_text);
    }
        else
        {
        new_content = replace_most_similar_chunk(content, before_text, after_text);
        }

    return new_content;
}


with entry {
    HEAD = '^<{5,9} SEARCH>?\\s*$';
    DIVIDER = '^={5,9}\\s*$';
    UPDATED = '^>{5,9} REPLACE\\s*$';
    HEAD_ERR = '<<<<<<< SEARCH';
    DIVIDER_ERR = '=======';
    UPDATED_ERR = '>>>>>>> REPLACE';
    separators = '|'.join([HEAD, DIVIDER, UPDATED]);
    split_re =
        re.compile((('^((?:' + separators) + ')[ ]*\\n)'), (re.MULTILINE | re.DOTALL));
    missing_filename_err =
        'Bad/missing filename. The filename must be alone on the line before the opening fence {fence[0]}';
    triple_backticks = ('`' * 3);
}


def strip_filename(filename: Any, fence: Any) {
    filename = filename.strip();

        if
        (filename == '...')
        {
        return;
        }
    start_fence = fence[ 0 ];
    if filename.startswith(start_fence) { candidate = filename[ len(start_fence) : ]; if (candidate and (('.' in candidate) or ('/' in candidate) ) ) {
        return candidate;
    } return;  }
    if filename.startswith(triple_backticks) { candidate =
        filename[ len(triple_backticks) : ]; if (candidate and (('.' in candidate) or ('/' in candidate) ) ) {
        return candidate;
    } return;  }
    filename = filename.rstrip(':');
    filename = filename.lstrip('#');
    filename = filename.strip();
    filename = filename.strip('`');
    filename = filename.strip('*');
    return filename;
}


def find_original_update_blocks(
    content: Any,
    fence: Any = DEFAULT_FENCE,
    valid_fnames: Any = None
) {
    lines = content.splitlines(keepends=True);
    i = 0;
    current_filename = None;
    head_pattern = re.compile(HEAD);
    divider_pattern = re.compile(DIVIDER);
    updated_pattern = re.compile(UPDATED);
    while (i < len(lines)) {
        line = lines[ i ];
        shell_starts =

            ['```bash',
            '```sh',
            '```shell',
            '```cmd',
            '```batch',
            '```powershell',
            '```ps1',
            '```zsh',
            '```fish',
            '```ksh',
            '```csh',
            '```tcsh'];
        next_is_editblock =
            ((((i + 1) < len(lines)) and head_pattern.match(lines[ (i + 1) ].strip()) )
            or (((i + 2) < len(lines)) and head_pattern.match(lines[ (i + 2) ].strip()) )
            );

            if
            head_pattern.match(line.strip())
            {
            try {
                if (((i + 1) < len(lines))
                and divider_pattern.match(lines[ (i + 1) ].strip())
                ) {
                    filename = find_filename(lines[ max(0, (i - 3)) : i ], fence, None);
                }
                    else
                    {
                    filename =
                        find_filename(lines[ max(0, (i - 3)) : i ], fence, valid_fnames);
                    }

                if not filename {
                    if current_filename {
                        filename = current_filename;
                    }
                        else
                        {
                        raise ValueError(missing_filename_err.format(fence=fence)) ;
                        }

                }
                current_filename = filename;
                original_text = [];
                i += 1;
                while ((i < len(lines)) and not divider_pattern.match(lines[ i ].strip()) ) {
                    original_text.append(lines[ i ]);
                    i += 1;
                }

                    if
                    ((i >= len(lines)) or not divider_pattern.match(lines[ i ].strip()) )
                    {
                    raise ValueError(f"'Expected `'{DIVIDER_ERR}'`'") ;
                    }
                updated_text = [];
                i += 1;
                while ((i < len(lines))
                and not (updated_pattern.match(lines[ i ].strip())
                or divider_pattern.match(lines[ i ].strip())
                )
                ) {
                    updated_text.append(lines[ i ]);
                    i += 1;
                }

                    if
                    ((i >= len(lines))
                    or not (updated_pattern.match(lines[ i ].strip())
                    or divider_pattern.match(lines[ i ].strip())
                    )
                    )
                    {
                    raise ValueError(
                        f"'Expected `'{UPDATED_ERR}'` or `'{DIVIDER_ERR}'`'"
                    ) ;
                    }
                yield (filename, ''.join(original_text), ''.join(updated_text)) ;;
            } except ValueError as e {
                processed = ''.join(lines[ : (i + 1) ]);
                err = e.args[ 0 ];
            raise ValueError(f"{processed}'\n^^^ '{err}") ; }
            }
        i += 1;
    if (<>any(( line.strip().startswith(start) for start in shell_starts ))
    and not next_is_editblock
    ) {
        shell_content = [];
    i += 1; while ((i < len(lines)) and not lines[ i ].strip().startswith('```') ) {
        shell_content.append(lines[ i ]);
        i += 1;
    } if ((i < len(lines)) and lines[ i ].strip().startswith('```') ) {
        i += 1;
    } yield (None, ''.join(shell_content)) ;; continue; } }
}


"""\n    Deepseek Coder v2 has been doing this:\n\n\n     ```python\n    word_count.py\n    ```\n    ```python\n    <<<<<<< SEARCH\n    ...\n\n    This is a more flexible search back for filenames.\n    """
def find_filename(lines: Any, fence: Any, valid_fnames: Any) {
    if (valid_fnames is None) {
        valid_fnames = [];
    }
    lines.reverse();
    lines = lines[ : 3 ];
    filenames = [];
    for line in lines { filename = strip_filename(line, fence); if filename {
        filenames.append(filename);
    }
        if
        (not line.startswith(fence[ 0 ]) and not line.startswith(triple_backticks) )
        {
        break;
        } }
    not filenames
        if
        {
        return;
        }

        for
        fname
        in
        filenames
        {
        if (fname in valid_fnames) {
            return fname;
        }
        }
    for fname in filenames {

            for
            vfn
            in
            valid_fnames
            {
            if (fname == Path(vfn).name) {
                return vfn;
            }
            }
    }
    for fname in filenames {
        close_matches = difflib.get_close_matches(fname, valid_fnames, n=1, cutoff=0.8);
    if (len(close_matches) == 1) {
        return close_matches[ 0 ];
    } }

        for
        fname
        in
        filenames
        {
        if ('.' in fname) {
            return fname;
        }
        }
    if filenames {
        return filenames[ 0 ];
    }
}


def find_similar_lines(search_lines: Any, content_lines: Any, threshold: Any = 0.6) {
    search_lines = search_lines.splitlines();
    content_lines = content_lines.splitlines();
    best_ratio = 0;
    best_match = None;
    for i in range(((len(content_lines) - len(search_lines)) + 1)) {
        chunk = content_lines[ i : (i + len(search_lines)) ];
        ratio = SequenceMatcher(None, search_lines, chunk).ratio();
    if (ratio > best_ratio) {
        best_ratio = ratio;
        best_match = chunk;
        best_match_i = i;
    } }
    if (best_ratio < threshold) {
        return '';
    }
    if ((best_match[ 0 ] == search_lines[ 0 ])
    and (best_match[ -1 ] == search_lines[ -1 ])
    ) {
        return '\n'.join(best_match);
    }
    N = 5;
    best_match_end = min(len(content_lines), ((best_match_i + len(search_lines)) + N));
    best_match_i = max(0, (best_match_i - N));
    best = content_lines[ best_match_i : best_match_end ];
    return '\n'.join(best);
}


def main() {
    history_md = Path(sys.argv[ 1 ]).read_text();
    not history_md
        if
        {
        return;
        }
    messages = utils.split_chat_history_markdown(history_md);
    for msg in messages {
        msg = msg[ 'content' ];
        edits = <>list(find_original_update_blocks(msg));
        for (fname, before, after) in edits {
            diff =
                difflib.unified_diff(
                    before.splitlines(keepends=True),
                    after.splitlines(keepends=True),
                    fromfile='before',
                    tofile='after'
                );
            diff = ''.join(diff);
            dump(before);
            dump(after);
            dump(diff);
        }
    }
}


with entry {
    if (__name__ == '__main__') {
        main();
    }
}