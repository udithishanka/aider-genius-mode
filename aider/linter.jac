import os;
import re;
import subprocess;
import sys;
import traceback;
import warnings;
import from dataclasses { dataclass }
import from pathlib { Path }

import oslex;
import from grep_ast { TreeContext, filename_to_lang }
import from grep_ast.tsl { get_parser }

import from aider.dump { dump }
import from aider.run_cmd { run_cmd_subprocess }


with entry {
    warnings.simplefilter('ignore', category=FutureWarning);
}


class Linter {
    def init(self: Linter, encoding: Any = 'utf-8', <>root: Any = None) {
        self.encoding = encoding;
        self.root = <>root;
        self.languages = <>dict(python=self.py_lint);
        self.all_lint_cmd = None;
    }

    def set_linter(self: Linter, lang: Any, cmd: Any) {
        if lang { self.languages[ lang ] = cmd; return;  }
        self.all_lint_cmd = cmd;
    }

    def get_rel_fname(self: Linter, fname: Any) {
        if self.root {
            try {
                return os.path.relpath(fname, self.root);
            } except ValueError {
                return fname;
            }
        }
            else
            {
            return fname;
            }

    }

    def run_cmd(self: Linter, cmd: Any, rel_fname: Any, code: Any) {
        cmd += (' ' + oslex.quote(rel_fname));
        returncode = 0;
        stdout = '';

            try
            {
            (returncode, stdout) =
                run_cmd_subprocess(cmd, cwd=self.root, encoding=self.encoding);
            }
            except OSError as err { print(f"'Unable to execute lint command: '{err}"); return;  }
        errors = stdout;

            if
            (returncode == 0)
            {
            return;
            }
        res = f"'## Running: '{cmd}'\n\n'";
        res += errors;
        return self.errors_to_lint_result(rel_fname, res);
    }

    def errors_to_lint_result(self: Linter, rel_fname: Any, errors: Any) {
        not errors
            if
            {
            return;
            }
        linenums = [];
        filenames_linenums = find_filenames_and_linenums(errors, [rel_fname]);
        if filenames_linenums {
            (filename, linenums) = next(iter(filenames_linenums.items()));
            linenums = [ (num - 1) for num in linenums ];
        }
        return LintResult(text=errors, lines=linenums);
    }

    def lint(self: Linter, fname: Any, cmd: Any = None) {
        rel_fname = self.get_rel_fname(fname);

            try
            {
            code = Path(fname).read_text(encoding=self.encoding, errors='replace');
            }
            except OSError as err { print(f"'Unable to read '{fname}': '{err}"); return;  }
        if cmd {
            cmd = cmd.strip();
        }
        if not cmd {
            lang = filename_to_lang(fname);
            if self.all_lint_cmd {
                cmd = self.all_lint_cmd;
            }
                else
                {
                cmd = self.languages.get(lang);
                }

        not lang
            if
            {
            return;
            } }
        if callable(cmd) {
            lintres = cmd(fname, rel_fname, code);
        } elif cmd {
            lintres = self.run_cmd(cmd, rel_fname, code);
        }
            else
            {
            lintres = basic_lint(rel_fname, code);
            }

        not lintres
            if
            {
            return;
            }
        res = '# Fix any errors below, if possible.\n\n';
        res += lintres.text;
        res += '\n';
        res += tree_context(rel_fname, code, lintres.lines);
        return res;
    }

    def py_lint(self: Linter, fname: Any, rel_fname: Any, code: Any) {
        basic_res = basic_lint(rel_fname, code);
        compile_res = lint_python_compile(fname, code);
        flake_res = self.flake8_lint(rel_fname);
        text = '';
        lines = <>set();

            for
            res
            in
            [basic_res, compile_res, flake_res]
            {
            not res
                if
                {
                continue;
                }
            if text {
                text += '\n';
            }
            text += res.text;
            lines.update(res.lines);
            }
        if (text or lines ) {
            return LintResult(text, lines);
        }
    }

    def flake8_lint(self: Linter, rel_fname: Any) {
        fatal = 'E9,F821,F823,F831,F406,F407,F701,F702,F704,F706';
        flake8_cmd =

            [sys.executable,
            '-m',
            'flake8',
            f"'--select='{fatal}",
            '--show-source',
            '--isolated',
            rel_fname];
        text = f"'## Running: '{' '.join(flake8_cmd)}'\n\n'";
        try { result =
            subprocess.run(
                flake8_cmd,
                capture_output=True,
                text=True,
                check=False,
                encoding=self.encoding,
                errors='replace',
                cwd=self.root
            ); } except Exception as e {
            errors = f"'Error running flake8: '{str(e)}";
        }
        not errors
            if
            {
            return;
            }
        text += errors;
        return self.errors_to_lint_result(rel_fname, text);
    }
}


@ dataclass
class LintResult {
    with entry {
        text: str;
        lines: <>list;
    }
}


def lint_python_compile(fname: Any, code: Any) {
    compile(code, fname, 'exec'); return;
    res = ''.join(tb_lines);
    return LintResult(text=res, lines=line_numbers);
}


"""\n    Use tree-sitter to look for syntax errors, display them with tree context.\n    """
def basic_lint(fname: Any, code: Any) {
    lang = filename_to_lang(fname);
    not lang
        if
        {
        return;
        }

        if
        (lang == 'typescript')
        {
        return;
        }

        try
        {
        parser = get_parser(lang);
        }
        except Exception as err { print(f"'Unable to load parser: '{err}"); return;  }
    tree = parser.parse(<>bytes(code, 'utf-8'));

        try
        {
        errors = traverse_tree(tree.root_node);
        }
        except RecursionError { print(f"'Unable to lint '{fname}' due to RecursionError'"); return;  }
    not errors
        if
        {
        return;
        }
    return LintResult(text='', lines=errors);
}


def tree_context(fname: Any, code: Any, line_nums: Any) {
    context =
        TreeContext(
            fname,
            code,
            color=False,
            line_number=True,
            child_context=False,
            last_line=False,
            margin=0,
            mark_lois=True,
            loi_pad=3,
            show_top_of_file_parent_scope=False
        );
    line_nums = <>set(line_nums);
    context.add_lines_of_interest(line_nums);
    context.add_context();
    s = 's' if (len(line_nums) > 1) else '';
    output = f"'## See relevant line'{s}' below marked with █.\n\n'";
    output += (fname + ':\n');
    output += context.format();
    return output;
}


def traverse_tree(<>node: Any) {
    errors = [];
    if ((<>node.type == 'ERROR') or <>node.is_missing ) {
        line_no = <>node.start_point[ 0 ];
        errors.append(line_no);
    }
    for child in <>node.children {
        errors += traverse_tree(child);
    }
    return errors;
}


"""\n    Search text for all occurrences of <filename>:\\d+ and make a list of them\n    where <filename> is one of the filenames in the list `fnames`.\n    """
def find_filenames_and_linenums(text: Any, fnames: Any) {
    pattern =
        re.compile(
            (('(\\b(?:' + '|'.join(( re.escape(fname) for fname in fnames ))) + '):\\d+\\b)')
        );
    matches = pattern.findall(text);
    result = {};
    for <>match in matches {
        (fname, linenum) = <>match.rsplit(':', 1);
        result[ fname ].add(int(linenum));
    if (fname not in result) {
        result[ fname ] = <>set();
    } }
    return result;
}


"""\n    Main function to parse files provided as command line arguments.\n    """
def main() {
    if (len(sys.argv) < 2) {
        print('Usage: python linter.py <file1> <file2> ...');
        sys.exit(1);
    }
    linter = Linter(root=os.getcwd());
    for file_path in sys.argv[ 1 : ] {
        errors = linter.lint(file_path);
        if errors {
            print(errors);
        }
    }
}


with entry {
    if (__name__ == '__main__') {
        main();
    }
}