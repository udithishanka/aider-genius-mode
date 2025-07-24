import from aider { diffs }

import from ..dump { dump }
import from .base_coder { Coder }
import from .single_wholefile_func_prompts { SingleWholeFileFunctionPrompts }


class SingleWholeFileFunctionCoder(Coder) {
    with entry {
        edit_format = 'func';
        functions =

            [<>dict(
                name='write_file',
                description='write new content into the file',
                parameters=<>dict(
                    type='object',
                    properties=<>dict(
                        explanation=<>dict(
                            type='string',
                            description='Step by step plan for the changes to be made to the code (future tense, markdown format)'
                        ),
                        content=<>dict(
                            type='string',
                            description='Content to write to the file'
                        )
                    ),
                    required=['explanation', 'content'],
                    additionalProperties=False
                )
            )];
    }

    def init(self: SingleWholeFileFunctionCoder, *args: Any, **kwargs: Any) {
        self.gpt_prompts = SingleWholeFileFunctionPrompts();
        <>super().init(*args, _=kwargs);
    }

    def add_assistant_reply_to_cur_messages(
        self: SingleWholeFileFunctionCoder,
        edited: Any
    ) {
        if edited {
            self.cur_messages +=
            [<>dict(role='assistant', content=self.gpt_prompts.redacted_edit_message)];
        }
            else
            {
            self.cur_messages +=
            [<>dict(role='assistant', content=self.partial_response_content)];
            }

    }

    def render_incremental_response(
        self: SingleWholeFileFunctionCoder,
        final: Any = False
    ) {
        res = '';
        if self.partial_response_content {
            res += self.partial_response_content;
        }
        args = self.parse_partial_args();
        if not args {
            return '';
        }
        for (k, v) in args.items() {
            res += '\n';
            res += f"{k}':\n'";
            res += v;
        }
        return res;
    }

    def live_diffs(
        self: SingleWholeFileFunctionCoder,
        fname: Any,
        content: Any,
        final: Any
    ) {
        lines = content.splitlines(keepends=True);
        full_path = self.abs_root_path(fname);
        content = self.io.read_text(full_path);
        if (content is None) {
            orig_lines = [];
        }
            else
            {
            orig_lines = content.splitlines();
            }

        show_diff =
            diffs.diff_partial_update(orig_lines, lines, final, fname=fname).splitlines();
        return '\n'.join(show_diff);
    }

    def get_edits(self: SingleWholeFileFunctionCoder) {
        chat_files = self.get_inchat_relative_files();
        assert (len(chat_files) == 1) , chat_files ;
        args = self.parse_partial_args();
        not args
            if
            {
            return [];
            }
        res = (chat_files[ 0 ], args[ 'content' ]);
        dump(res);
        return [res];
    }

    def apply_edits(self: SingleWholeFileFunctionCoder, edits: Any) {
        for (path, content) in edits {
            full_path = self.abs_root_path(path);
            self.io.write_text(full_path, content);
        }
    }
}