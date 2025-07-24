import glob;
import os;
import re;
import subprocess;
import sys;
import tempfile;
import from collections { OrderedDict }
import from os.path { expanduser }
import from pathlib { Path }

import pyperclip;
import from PIL { Image, ImageGrab }
import from prompt_toolkit.completion { Completion, PathCompleter }
import from prompt_toolkit.document { Document }

import from aider { models, prompts, voice }
import from aider.editor { pipe_editor }
import from aider.format_settings { format_settings }
import from aider.help { Help, install_help_extra }
import from aider.io { CommandCompletionException }
import from aider.llm { litellm }
import from aider.repo { ANY_GIT_ERROR }
import from aider.run_cmd { run_cmd }
import from aider.scrape { Scraper, install_playwright }
import from aider.utils { is_image_file }

import from .dump { dump }


class SwitchCoder(Exception) {
    def init(self: SwitchCoder, placeholder: Any = None, **kwargs: Any) {
        self.kwargs = kwargs;
        self.placeholder = placeholder;
    }
}


class Commands {
    with entry {
        voice = None;
        scraper = None;
    }

    def clone(self: Commands) {
        return Commands(
            self.io,
            None,
            voice_language=self.voice_language,
            verify_ssl=self.verify_ssl,
            args=self.args,
            parser=self.parser,
            verbose=self.verbose,
            editor=self.editor,
            original_read_only_fnames=self.original_read_only_fnames
        );
    }

    def init(
        self: Commands,
        io: Any,
        coder: Any,
        voice_language: Any = None,
        voice_input_device: Any = None,
        voice_format: Any = None,
        verify_ssl: Any = True,
        args: Any = None,
        parser: Any = None,
        verbose: Any = False,
        editor: Any = None,
        original_read_only_fnames: Any = None
    ) {
        self.io = io;
        self.coder = coder;
        self.parser = parser;
        self.args = args;
        self.verbose = verbose;
        self.verify_ssl = verify_ssl;
        if (voice_language == 'auto') {
            voice_language = None;
        }
        self.voice_language = voice_language;
        self.voice_format = voice_format;
        self.voice_input_device = voice_input_device;
        self.help = None;
        self.editor = editor;
        self.original_read_only_fnames = <>set((original_read_only_fnames or [] ));
    }

    """Switch the Main Model to a new LLM"""
    def cmd_model(self: Commands, args: Any) {
        model_name = args.strip();
        if not model_name { announcements = '\n'.join(self.coder.get_announcements()); self.io.tool_output(announcements); return;  }
        model =
            models.Model(
                model_name,
                editor_model=self.coder.main_model.editor_model.name,
                weak_model=self.coder.main_model.weak_model.name
            );
        models.sanity_check_models(self.io, model);
        old_model_edit_format = self.coder.main_model.edit_format;
        current_edit_format = self.coder.edit_format;
        new_edit_format = current_edit_format;
        if (current_edit_format == old_model_edit_format) {
            new_edit_format = model.edit_format;
        }
        raise SwitchCoder(main_model=model, edit_format=new_edit_format) ;
    }

    """Switch the Editor Model to a new LLM"""
    def cmd_editor_model(self: Commands, args: Any) {
        model_name = args.strip();
        model =
            models.Model(
                self.coder.main_model.name,
                editor_model=model_name,
                weak_model=self.coder.main_model.weak_model.name
            );
        models.sanity_check_models(self.io, model);
        raise SwitchCoder(main_model=model) ;
    }

    """Switch the Weak Model to a new LLM"""
    def cmd_weak_model(self: Commands, args: Any) {
        model_name = args.strip();
        model =
            models.Model(
                self.coder.main_model.name,
                editor_model=self.coder.main_model.editor_model.name,
                weak_model=model_name
            );
        models.sanity_check_models(self.io, model);
        raise SwitchCoder(main_model=model) ;
    }

    """Switch to a new chat mode"""
    def cmd_chat_mode(self: Commands, args: Any) {
        import from aider { coders }
        ef = args.strip();
        valid_formats =
            OrderedDict(
                sorted(
                    (
                    (coder.edit_format,
                    coder.__doc__.strip().split('\n')[ 0 ]
                    if coder.__doc__
                    else 'No description') for coder in coders.__all__ if getattr(coder, 'edit_format', None) )
                )
            );
        show_formats =
            OrderedDict(

                [('help', 'Get help about using aider (usage, config, troubleshoot).'),
                ('ask', 'Ask questions about your code without making any changes.'),
                ('code', 'Ask for changes to your code (using the best edit format).'),

                ('architect',
                'Work with an architect model to design code changes, and an editor to make them.'),

                ('context',
                'Automatically identify which files will need to be edited.')]
            );
        if ((ef not in valid_formats) and (ef not in show_formats) ) { if ef {
            self.io.tool_error(f"'Chat mode "'{ef}'" should be one of these:\n'");
        }
            else
            {
            self.io.tool_output('Chat mode should be one of these:\n');
            }
         max_format_length = max(( len(format) for format in valid_formats.keys() )); for (format, description) in show_formats.items() {
            self.io.tool_output(f"'- '{format}' : '{description}");
        } self.io.tool_output('\nOr a valid edit format:\n');
            for
            (format, description)
            in
            valid_formats.items()
            {
            if (format not in show_formats) {
                self.io.tool_output(f"'- '{format}' : '{description}");
            }
            } return;  }
        summarize_from_coder = True;
        edit_format = ef;
        if (ef == 'code') {
            edit_format = self.coder.main_model.edit_format;
            summarize_from_coder = False;
        } elif (ef == 'ask') {
            summarize_from_coder = False;
        }
        raise SwitchCoder(
            edit_format=edit_format,
            summarize_from_coder=summarize_from_coder
        ) ;
    }

    def completions_model(self: Commands) {
        models = litellm.model_cost.keys();
        return models;
    }

    """Search the list of available models"""
    def cmd_models(self: Commands, args: Any) {
        args = args.strip();
        if args {
            models.print_matching_models(self.io, args);
        }
            else
            {
            self.io.tool_output('Please provide a partial model name to search for.');
            }

    }

    """Scrape a webpage, convert to markdown and send in a message"""
    def cmd_web(self: Commands, args: Any, return_content: Any = False) {
        url = args.strip();
        if not url { self.io.tool_error('Please provide a URL to scrape.'); return;  }
        self.io.tool_output(f"'Scraping '{url}'...'");
        if not self.scraper {
            disable_playwright = getattr(self.args, 'disable_playwright', False);
            if disable_playwright {
                res = False;
            }
                else
                {
                res = install_playwright(self.io);
                }
            if not res {
                self.io.tool_warning('Unable to initialize playwright.');
            }
            self.scraper =
                Scraper(
                    print_error=self.io.tool_error,
                    playwright_available=res,
                    verify_ssl=self.verify_ssl
                );
        }
        content = (self.scraper.scrape(url) or '' );
        content = (f"'Here is the content of '{url}':\n\n'" + content);
        if return_content {
            return content;
        }
        self.io.tool_output('... added to chat.');
        self.coder.cur_messages +=
        [<>dict(role='user', content=content),
        <>dict(role='assistant', content='Ok.')];
    }

    def is_command(self: Commands, inp: Any) {
        return (inp[ 0 ] in '/!');
    }

    def get_raw_completions(self: Commands, cmd: Any) {
        assert cmd.startswith('/') ;
        cmd = cmd[ 1 : ];
        cmd = cmd.replace('-', '_');
        raw_completer = getattr(self, f"'completions_raw_'{cmd}", None);
        return raw_completer;
    }

    def get_completions(self: Commands, cmd: Any) {
        assert cmd.startswith('/') ;
        cmd = cmd[ 1 : ];
        cmd = cmd.replace('-', '_');
        fun = getattr(self, f"'completions_'{cmd}", None);
        not fun
            if
            {
            return;
            }
        return sorted(fun());
    }

    def get_commands(self: Commands) {
        commands = [];
        attr dir(self)
            for
            in
            {
            not attr.startswith('cmd_')
                if
                {
                continue;
                }
            commands.append(('/' + cmd));
            }
        cmd = attr[ 4 : ]; cmd = cmd.replace('_', '-');
        return commands;
    }

    def do_run(self: Commands, cmd_name: Any, args: Any) {
        cmd_name = cmd_name.replace('-', '_');
        cmd_method_name = f"'cmd_'{cmd_name}";
        cmd_method = getattr(self, cmd_method_name, None);
        if not cmd_method { self.io.tool_output(f"'Error: Command '{cmd_name}' not found.'"); return;  }
        try {
            return cmd_method(args);
        } except ANY_GIT_ERROR as err {
            self.io.tool_error(f"'Unable to complete '{cmd_name}': '{err}");
        }
    }

    def matching_commands(self: Commands, inp: Any) {
        words = inp.strip().split();
        not words
            if
            {
            return;
            }
        first_word = words[ 0 ];
        rest_inp = inp[ len(words[ 0 ]) : ].strip();
        all_commands = self.get_commands();
        matching_commands =
            [ cmd for cmd in all_commands if cmd.startswith(first_word) ];
        return (matching_commands, first_word, rest_inp);
    }

    def run(self: Commands, inp: Any) {
        if inp.startswith('!') {
            self.coder.event('command_run');
            return self.do_run('run', inp[ 1 : ]);
        }
        res = self.matching_commands(inp);

            if
            (res is None)
            {
            return;
            }
        (matching_commands, first_word, rest_inp) = res;
        if (len(matching_commands) == 1) {
            command = matching_commands[ 0 ][ 1 : ];
            self.coder.event(f"'command_'{command}");
            return self.do_run(command, rest_inp);
        } elif (first_word in matching_commands) {
            command = first_word[ 1 : ];
            self.coder.event(f"'command_'{command}");
            return self.do_run(command, rest_inp);
        } elif (len(matching_commands) > 1) {
            self.io.tool_error(f"'Ambiguous command: '{', '.join(matching_commands)}");
        }
            else
            {
            self.io.tool_error(f"'Invalid command: '{first_word}");
            }

    }

    """Commit edits to the repo made outside the chat (commit message optional)"""
    def cmd_commit(self: Commands, args: Any = None) {
        try {
            self.raw_cmd_commit(args);
        } except ANY_GIT_ERROR as err {
            self.io.tool_error(f"'Unable to complete commit: '{err}");
        }
    }

    def raw_cmd_commit(self: Commands, args: Any = None) {
        if not self.coder.repo { self.io.tool_error('No git repository found.'); return;  }
        if not self.coder.repo.is_dirty() { self.io.tool_warning('No more changes to commit.'); return;  }
        commit_message = args.strip() if args else None;
        self.coder.repo.commit(message=commit_message, coder=self.coder);
    }

    """Lint and fix in-chat files or all dirty files if none in chat"""
    def cmd_lint(self: Commands, args: Any = '', fnames: Any = None) {
        if not self.coder.repo { self.io.tool_error('No git repository found.'); return;  }
        if not fnames {
            fnames = self.coder.get_inchat_relative_files();
        }
        if (not fnames and self.coder.repo ) {
            fnames = self.coder.repo.get_dirty_files();
        }
        if not fnames { self.io.tool_warning('No dirty files to lint.'); return;  }
        fnames = [ self.coder.abs_root_path(fname) for fname in fnames ];
        lint_coder = None;
        for fname in fnames {

                try
                {
                errors = self.coder.linter.lint(fname);
                }
                except FileNotFoundError as err { self.io.tool_error(f"'Unable to lint '{fname}"); self.io.tool_output(str(err)); continue; }
            self.io.tool_output(errors);
            lint_coder.add_rel_fname(fname);
            lint_coder.run(errors);
            lint_coder.abs_fnames = <>set();
        not errors
            if
            {
            continue;
            } not self.io.confirm_ask(f"'Fix lint errors in '{fname}'?'", default='y')
            if
            {
            continue;
            } if (self.coder.repo.is_dirty() and self.coder.dirty_commits ) {
            self.cmd_commit('');
        } if not lint_coder {
            lint_coder =
                self.coder.clone(cur_messages=[], done_messages=[], fnames=None);
        } }
        if (lint_coder and self.coder.repo.is_dirty() and self.coder.auto_commits ) {
            self.cmd_commit('');
        }
    }

    """Clear the chat history"""
    def cmd_clear(self: Commands, args: Any) {
        self._clear_chat_history();
        self.io.tool_output('All chat history cleared.');
    }

    def _drop_all_files(self: Commands) {
        self.coder.abs_fnames = <>set();
        if self.original_read_only_fnames {
            to_keep = <>set();
            for abs_fname in self.coder.abs_read_only_fnames {
                rel_fname = self.coder.get_rel_fname(abs_fname);
            if ((abs_fname in self.original_read_only_fnames)
            or (rel_fname in self.original_read_only_fnames)
            ) {
                to_keep.add(abs_fname);
            } }
            self.coder.abs_read_only_fnames = to_keep;
        }
            else
            {
            self.coder.abs_read_only_fnames = <>set();
            }

    }

    def _clear_chat_history(self: Commands) {
        self.coder.done_messages = [];
        self.coder.cur_messages = [];
    }

    """Drop all files and clear the chat history"""
    def cmd_reset(self: Commands, args: Any) {
        self._drop_all_files();
        self._clear_chat_history();
        self.io.tool_output('All files dropped and chat history cleared.');
    }

    """Report on the number of tokens used by the current chat context"""
    def cmd_tokens(self: Commands, args: Any) {
        res = [];
        self.coder.choose_fence();
        main_sys = self.coder.fmt_system_prompt(self.coder.gpt_prompts.main_system);
        main_sys += ('\n' + self.coder.fmt_system_prompt(self.coder.gpt_prompts.system_reminder));
        msgs =

            [<>dict(role='system', content=main_sys),
            <>dict(
                role='system',
                content=self.coder.fmt_system_prompt(
                    self.coder.gpt_prompts.system_reminder
                )
            )];
        tokens = self.coder.main_model.token_count(msgs);
        res.append((tokens, 'system messages', ''));
        msgs = (self.coder.done_messages + self.coder.cur_messages);
        if msgs {
            tokens = self.coder.main_model.token_count(msgs);
            res.append((tokens, 'chat history', 'use /clear to clear'));
        }
        other_files =
            (<>set(self.coder.get_all_abs_files()) - <>set(self.coder.abs_fnames));
        if self.coder.repo_map {
            repo_content =
                self.coder.repo_map.get_repo_map(self.coder.abs_fnames, other_files);
            if repo_content {
                tokens = self.coder.main_model.token_count(repo_content);
                res.append((tokens, 'repository map', 'use --map-tokens to resize'));
            }
        }
        fence = ('`' * 3);
        file_res = [];
        for fname in self.coder.abs_fnames {
            relative_fname = self.coder.get_rel_fname(fname);
            content = self.io.read_text(fname);
            if is_image_file(relative_fname) {
                tokens = self.coder.main_model.token_count_for_image(fname);
            }
                else
                {
                content =
                    ((f"{relative_fname}'\n'{fence}'\n'" + content) + '{fence}\n');
                tokens = self.coder.main_model.token_count(content);
                }

            file_res.append((tokens, f"{relative_fname}", '/drop to remove'));
        }
        for fname in self.coder.abs_read_only_fnames {
            relative_fname = self.coder.get_rel_fname(fname);
            content = self.io.read_text(fname);
        if ((content is not None) and not is_image_file(relative_fname) ) {
            content = ((f"{relative_fname}'\n'{fence}'\n'" + content) + '{fence}\n');
            tokens = self.coder.main_model.token_count(content);
            file_res.append(
                (tokens, f"{relative_fname}' (read-only)'", '/drop to remove')
            );
        } }
        file_res.sort();
        res.extend(file_res);
        self.io.tool_output(
            f"'Approximate context window usage for '{self.coder.main_model.name}', in tokens:'"
        );
        self.io.tool_output();
        width = 8;
        cost_width = 9;
        def fmt(v: Any) {
            return format(int(v), ',').rjust(width);
        }
        col_width = max(( len(row[ 1 ]) for row in res ));
        cost_pad = (' ' * cost_width);
        total = 0;
        total_cost = 0.0;
        for (tk, msg, tip) in res {
            total += tk;
            cost =
                (tk * (self.coder.main_model.info.get('input_cost_per_token') or 0 ));
            total_cost += cost;
            msg = msg.ljust(col_width);
            self.io.tool_output(f"'$'{cost}' '{fmt(tk)}' '{msg}' '{tip}");
        }
        self.io.tool_output(('=' * ((width + cost_width) + 1)));
        self.io.tool_output(f"'$'{total_cost}' '{fmt(total)}' tokens total'");
        limit = (self.coder.main_model.info.get('max_input_tokens') or 0 );
        not limit
            if
            {
            return;
            }
        remaining = (limit - total);
        if (remaining > 1024) {
            self.io.tool_output(
                f"{cost_pad}{fmt(remaining)}' tokens remaining in context window'"
            );
        } elif (remaining > 0) {
            self.io.tool_error(
                f"{cost_pad}{fmt(remaining)}' tokens remaining in context window (use /drop or /clear to make space)'"
            );
        }
            else
            {
            self.io.tool_error(
                f"{cost_pad}{fmt(remaining)}' tokens remaining, window exhausted (use /drop or /clear to make space)'"
            );
            }

        self.io.tool_output(f"{cost_pad}{fmt(limit)}' tokens max context window size'");
    }

    """Undo the last git commit if it was done by aider"""
    def cmd_undo(self: Commands, args: Any) {
        try {
            self.raw_cmd_undo(args);
        } except ANY_GIT_ERROR as err {
            self.io.tool_error(f"'Unable to complete undo: '{err}");
        }
    }

    def raw_cmd_undo(self: Commands, args: Any) {
        if not self.coder.repo { self.io.tool_error('No git repository found.'); return;  }
        last_commit = self.coder.repo.get_head_commit();
        if (not last_commit or not last_commit.parents ) { self.io.tool_error('This is the first commit in the repository. Cannot undo.'); return;  }
        last_commit_hash = self.coder.repo.get_head_commit_sha(short=True);
        last_commit_message =
            self.coder.repo.get_head_commit_message('(unknown)').strip();
        last_commit_message = (last_commit_message.splitlines() or [''] )[ 0 ];
        if (last_commit_hash not in self.coder.aider_commit_hashes) { self.io.tool_error(
            'The last commit was not made by aider in this chat session.'
        ); self.io.tool_output(
            'You could try `/git reset --hard HEAD^` but be aware that this is a destructive command!'
        ); return;  }
        if (len(last_commit.parents) > 1) { self.io.tool_error(
            f"'The last commit '{last_commit.hexsha}" has more than 1 parent, can't undo.""
        ); return;  }
        prev_commit = last_commit.parents[ 0 ];
        changed_files_last_commit =
            [ item.a_path for item in last_commit.diff(prev_commit) ];
        for fname in changed_files_last_commit {
            if self.coder.repo.repo.is_dirty(path=fname) { self.io.tool_error(
                f"'The file '{fname}' has uncommitted changes. Please stash them before undoing.'"
            ); return;  }

                try
                {
                prev_commit.tree[ fname ];
                }
                except KeyError { self.io.tool_error(
                    f"'The file '{fname}' was not in the repository in the previous commit. Cannot undo safely.'"
                ); return;  }
        }
        local_head = self.coder.repo.repo.git.rev_parse('HEAD');
        current_branch = self.coder.repo.repo.active_branch.name;
        try {
            remote_head =
                self.coder.repo.repo.git.rev_parse(f"'origin/'{current_branch}");
            has_origin = True;
        } except ANY_GIT_ERROR {
            has_origin = False;
        }
        has_origin
            if
            {
            if (local_head == remote_head) { self.io.tool_error(
                'The last commit has already been pushed to the origin. Undoing is not possible.'
            ); return;  }
            }
        restored = <>set();
        unrestored = <>set();
        for file_path in changed_files_last_commit {
            try {
                self.coder.repo.repo.git.checkout('HEAD~1', file_path);
                restored.add(file_path);
            } except ANY_GIT_ERROR {
                unrestored.add(file_path);
            }
        }
        if unrestored { self.io.tool_error(f"'Error restoring '{file_path}', aborting undo.'"); self.io.tool_output('Restored files:'); for file in restored {
            self.io.tool_output(f"'  '{file}");
        } self.io.tool_output('Unable to restore files:'); for file in unrestored {
            self.io.tool_output(f"'  '{file}");
        } return;  }
        self.coder.repo.repo.git.reset('--soft', 'HEAD~1');
        self.io.tool_output(f"'Removed: '{last_commit_hash}' '{last_commit_message}");
        current_head_hash = self.coder.repo.get_head_commit_sha(short=True);
        current_head_message =
            self.coder.repo.get_head_commit_message('(unknown)').strip();
        current_head_message = (current_head_message.splitlines() or [''] )[ 0 ];
        self.io.tool_output(f"'Now at:  '{current_head_hash}' '{current_head_message}");
        if self.coder.main_model.send_undo_reply {
            return prompts.undo_command_reply;
        }
    }

    """Display the diff of changes since the last message"""
    def cmd_diff(self: Commands, args: Any = '') {
        try {
            self.raw_cmd_diff(args);
        } except ANY_GIT_ERROR as err {
            self.io.tool_error(f"'Unable to complete diff: '{err}");
        }
    }

    def raw_cmd_diff(self: Commands, args: Any = '') {
        if not self.coder.repo { self.io.tool_error('No git repository found.'); return;  }
        current_head = self.coder.repo.get_head_commit_sha();
        if (current_head is None) { self.io.tool_error(
            'Unable to get current commit. The repository might be empty.'
        ); return;  }
        if (len(self.coder.commit_before_message) < 2) {
            commit_before_message = (current_head + '^');
        }
            else
            {
            commit_before_message = self.coder.commit_before_message[ -2 ];
            }

        if (not commit_before_message or (commit_before_message == current_head) ) { self.io.tool_warning('No changes to display since the last message.'); return;  }
        self.io.tool_output(f"'Diff since '{commit_before_message[ : 7 ]}'...'");
        if self.coder.pretty { run_cmd(f"'git diff '{commit_before_message}"); return;  }
        diff =
            self.coder.repo.diff_commits(
                self.coder.pretty,
                commit_before_message,
                'HEAD'
            );
        self.io.print(diff);
    }

    def quote_fname(self: Commands, fname: Any) {
        if ((' ' in fname) and ('"' not in fname) ) {
            fname = f"'"'{fname}'"'";
        }
        return fname;
    }

    def completions_raw_read_only(self: Commands, document: Any, complete_event: Any) {
        text = document.text_before_cursor;
        after_command = text.split()[ -1 ];
        new_document = Document(after_command, cursor_position=len(after_command));
        def get_paths() {
            return [self.coder.root] if self.coder.root else None;
        }
        path_completer =
            PathCompleter(get_paths=get_paths, only_directories=False, expanduser=True);
        adjusted_start_position = -len(after_command);
        all_completions = [];
        for completion in path_completer.get_completions(new_document, complete_event) {
            quoted_text = self.quote_fname((after_command + completion.text));
            all_completions.append(
                Completion(
                    text=quoted_text,
                    start_position=adjusted_start_position,
                    display=completion.display,
                    style=completion.style,
                    selected_style=completion.selected_style
                )
            );
        }
        add_completions = self.completions_add();

            for
            completion
            in
            add_completions
            {
            if (after_command in completion) {
                all_completions.append(
                    Completion(
                        text=completion,
                        start_position=adjusted_start_position,
                        display=completion
                    )
                );
            }
            }
        sorted_completions = sorted(all_completions, key=lambda  c: Any: c.text);
        for completion in sorted_completions {
            yield completion ;;
        }
    }

    def completions_add(self: Commands) {
        files = <>set(self.coder.get_all_relative_files());
        files = (files - <>set(self.coder.get_inchat_relative_files()));
        files = [ self.quote_fname(fn) for fn in files ];
        return files;
    }

    def glob_filtered_to_repo(self: Commands, pattern: Any) {
        not pattern.strip()
            if
            {
            return [];
            }

            try
            {
            if os.path.isabs(pattern) {
                raw_matched_files = [Path(pattern)];

                    else
                    {

                        try
                        {
                        raw_matched_files = <>list(Path(self.coder.root).glob(pattern));
                        }
                        except (IndexError, AttributeError) {
                            raw_matched_files = [];
                        }
                    }

            }
            }
            except ValueError as err { self.io.tool_error(f"'Error matching '{pattern}': '{err}"); }
        matched_files = [];
        for fn in raw_matched_files {
            matched_files += expand_subdir(fn);
        }
        matched_files =
            [ fn.relative_to(self.coder.root) for fn in matched_files if fn.is_relative_to(self.coder.root) ];
        if self.coder.repo { git_files = self.coder.repo.get_tracked_files(); }
        res = <>list(map(str, matched_files));
        return res;
    }

    """Add files to the chat so aider can edit them or review them in detail"""
    def cmd_add(self: Commands, args: Any) {
        all_matched_files = <>set();
        filenames = parse_quoted_filenames(args);
        for word in filenames {
            if Path(word).is_absolute() {
                fname = Path(word);

                    else
                    {
                    fname = (Path(self.coder.root) / word);
                    }

            }
            if fname.exists() {
                if fname.is_file() { all_matched_files.add(str(fname)); continue; }
                word = re.sub('([\\*\\?\\[\\]])', '[\\1]', word);
            }
            matched_files = self.glob_filtered_to_repo(word);
            if matched_files { all_matched_files.update(matched_files); continue; }
            if self.io.confirm_ask(
                f""No files matched '"{word}"'. Do you want to create "{fname}'?'"
            ) {
                try {
                    fname.parent.mkdir(parents=True, exist_ok=True);
                    fname.touch();
                    all_matched_files.add(str(fname));
                } except OSError as e {
                    self.io.tool_error(f"'Error creating file '{fname}': '{e}");
                }
            }
        if (self.coder.repo and self.coder.repo.ignored_file(fname) ) { self.io.tool_warning(
            f"'Skipping '{fname}' due to aiderignore or --subtree-only.'"
        ); continue; } if (('*' in str(fname)) or ('?' in str(fname)) ) { self.io.tool_error(
            f"'No match, and cannot create file with wildcard characters: '{fname}"
        ); continue; } if (fname.exists() and fname.is_dir() and self.coder.repo ) { self.io.tool_error(f"'Directory '{fname}' is not in git.'"); self.io.tool_output(f"'You can add to git with: /git add '{fname}"); continue; } }
        for matched_file in sorted(all_matched_files) { abs_file_path =
            self.coder.abs_root_path(matched_file); if (not abs_file_path.startswith(self.coder.root)
        and not is_image_file(matched_file)
        ) { self.io.tool_error(
            f"'Can not add '{abs_file_path}', which is not within '{self.coder.root}"
        ); continue; } if (self.coder.repo
        and self.coder.repo.git_ignored_file(matched_file)
        and not self.coder.add_gitignore_files
        ) { self.io.tool_error(f""Can't add "{matched_file}' which is in gitignore'"); continue; } if (abs_file_path in self.coder.abs_fnames) { self.io.tool_error(
            f"{matched_file}' is already in the chat as an editable file'"
        ); continue; }
            elif
            (abs_file_path in self.coder.abs_read_only_fnames)
            {
            if (self.coder.repo and self.coder.repo.path_in_repo(matched_file) ) {
                self.coder.abs_read_only_fnames.remove(abs_file_path);
                self.coder.abs_fnames.add(abs_file_path);
                self.io.tool_output(
                    f"'Moved '{matched_file}' from read-only to editable files in the chat'"
                );
            }
                else
                {
                self.io.tool_error(
                    f"'Cannot add '{matched_file}" as it's not part of the repository""
                );
                }

            }
            elif (is_image_file(matched_file)
            and not self.coder.main_model.info.get('supports_vision')
            ) { self.io.tool_error(
                f"'Cannot add image file '{matched_file}' as the '{self.coder.main_model.name}' does not support images.'"
            ); continue; }
         }
    }

    def completions_drop(self: Commands) {
        files = self.coder.get_inchat_relative_files();
        read_only_files =
            [ self.coder.get_rel_fname(fn) for fn in self.coder.abs_read_only_fnames ];
        all_files = (files + read_only_files);
        all_files = [ self.quote_fname(fn) for fn in all_files ];
        return all_files;
    }

    """Remove files from the chat session to free up context space"""
    def cmd_drop(self: Commands, args: Any = '') {
        if not args.strip() { if self.original_read_only_fnames {
            self.io.tool_output(
                'Dropping all files from the chat session except originally read-only files.'
            );
        }
            else
            {
            self.io.tool_output('Dropping all files from the chat session.');
            }
         self._drop_all_files(); return;  }
        filenames = parse_quoted_filenames(args);
        for word in filenames {
            expanded_word = os.path.expanduser(word);
            read_only_matched = [];
            f self.coder.abs_read_only_fnames
                for
                in
                {
                if (expanded_word in f) { read_only_matched.append(f); continue; }

                    try
                    {
                    abs_word = os.path.abspath(expanded_word);
                    if os.path.samefile(abs_word, f) {
                        read_only_matched.append(f);
                    }
                    }
                    (FileNotFoundError, OSError)
                        except
                        {
                        continue;
                        }
                }
            for matched_file in read_only_matched {
                self.coder.abs_read_only_fnames.remove(matched_file);
                self.io.tool_output(
                    f"'Removed read-only file '{matched_file}' from the chat'"
                );
            }
            if <>any(( (c in expanded_word) for c in '*?[]' )) {
                matched_files = self.glob_filtered_to_repo(expanded_word);

                    else
                    {
                    matched_files =
                        [ self.coder.get_rel_fname(f) for f in self.coder.abs_fnames if (expanded_word in f) ];
                    }

            }
            for matched_file in matched_files {
                abs_fname = self.coder.abs_root_path(matched_file);
            if (abs_fname in self.coder.abs_fnames) {
                self.coder.abs_fnames.remove(abs_fname);
                self.io.tool_output(f"'Removed '{matched_file}' from the chat'");
            } }
        if not matched_files {
            matched_files.append(expanded_word);
        } }
    }

    """Run a git command (output excluded from chat)"""
    def cmd_git(self: Commands, args: Any) {
        combined_output = None;
        try {
            args = ('git ' + args);
            env = <>dict(subprocess.os.environ);
            env[ 'GIT_EDITOR' ] = 'true';
            result =
                subprocess.run(
                    args,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    env=env,
                    shell=True,
                    encoding=self.io.encoding,
                    errors='replace'
                );
            combined_output = result.stdout;
        } except Exception as e {
            self.io.tool_error(f"'Error running /git command: '{e}");
        }

            if
            (combined_output is None)
            {
            return;
            }
        self.io.tool_output(combined_output);
    }

    """Run a shell command and add the output to the chat on non-zero exit code"""
    def cmd_test(self: Commands, args: Any) {
        if (not args and self.coder.test_cmd ) {
            args = self.coder.test_cmd;
        }
        not args
            if
            {
            return;
            }

            if
            not callable(args)
            {

                if
                (<>type(args) is not str)
                {
                raise ValueError(repr(args)) ;
                }
            return self.cmd_run(args, True);
            }
        errors = args();
        not errors
            if
            {
            return;
            }
        self.io.tool_output(errors);
        return errors;
    }

    """Run a shell command and optionally add the output to the chat (alias: !)"""
    def cmd_run(self: Commands, args: Any, add_on_nonzero_exit: Any = False) {
        (exit_status, combined_output) =
            run_cmd(
                args,
                verbose=self.verbose,
                error_print=self.io.tool_error,
                cwd=self.coder.root
            );

            if
            (combined_output is None)
            {
            return;
            }
        token_count = self.coder.main_model.token_count(combined_output);
        k_tokens = (token_count / 1000);
        if add_on_nonzero_exit {
            add = (exit_status != 0);
        }
            else
            {
            add =
                self.io.confirm_ask(
                    f"'Add '{k_tokens}'k tokens of command output to the chat?'"
                );
            }

        if add {
            num_lines = len(combined_output.strip().splitlines());
            line_plural = 'line' if (num_lines == 1) else 'lines';
            self.io.tool_output(
                f"'Added '{num_lines}' '{line_plural}' of output to the chat.'"
            );
            msg = prompts.run_output.format(command=args, output=combined_output);
            self.coder.cur_messages +=
            [<>dict(role='user', content=msg),
            <>dict(role='assistant', content='Ok.')];
        if (add_on_nonzero_exit and (exit_status != 0) ) {
            return msg;
        } elif (add and (exit_status != 0) ) {
            self.io.placeholder = "What's wrong? Fix";
        }  }
        return None;
    }

    """Exit the application"""
    def cmd_exit(self: Commands, args: Any) {
        self.coder.event('exit', reason='/exit');
        sys.exit();
    }

    """Exit the application"""
    def cmd_quit(self: Commands, args: Any) {
        self.cmd_exit(args);
    }

    """List all known files and indicate which are included in the chat session"""
    def cmd_ls(self: Commands, args: Any) {
        files = self.coder.get_all_relative_files();
        other_files = [];
        chat_files = [];
        read_only_files = [];
        for file in files {
            abs_file_path = self.coder.abs_root_path(file);
        if (abs_file_path in self.coder.abs_fnames) {
            chat_files.append(file);
        }
            else
            {
            other_files.append(file);
            }
         }
        for abs_file_path in self.coder.abs_read_only_fnames {
            rel_file_path = self.coder.get_rel_fname(abs_file_path);
            read_only_files.append(rel_file_path);
        }
        if (not chat_files and not other_files and not read_only_files ) { self.io.tool_output('\nNo files in chat, git repo, or read-only list.'); return;  }
        if other_files {
            self.io.tool_output('Repo files not in the chat:\n');
        }
        for file in other_files {
            self.io.tool_output(f"'  '{file}");
        }
        if read_only_files {
            self.io.tool_output('\nRead-only files:\n');
        }
        for file in read_only_files {
            self.io.tool_output(f"'  '{file}");
        }
        if chat_files {
            self.io.tool_output('\nFiles in chat:\n');
        }
        for file in chat_files {
            self.io.tool_output(f"'  '{file}");
        }
    }

    def basic_help(self: Commands) {
        commands = sorted(self.get_commands());
        pad = max(( len(cmd) for cmd in commands ));
        pad = (('{cmd:' + str(pad)) + '}');
        for cmd in commands {
            cmd_method_name = f"'cmd_'{cmd[ 1 : ]}".replace('-', '_');
            cmd_method = getattr(self, cmd_method_name, None);
            cmd = pad.format(cmd=cmd);
            if cmd_method {
                description = cmd_method.__doc__;
                self.io.tool_output(f"{cmd}' '{description}");
            }
                else
                {
                self.io.tool_output(f"{cmd}' No description available.'");
                }

        }
        self.io.tool_output();
        self.io.tool_output(
            'Use `/help <question>` to ask questions about how to use aider.'
        );
    }

    """Ask questions about aider"""
    def cmd_help(self: Commands, args: Any) {
        if not args.strip() { self.basic_help(); return;  }
        self.coder.event('interactive help');
        import from aider.coders.base_coder { Coder }
        if not self.help {
            res = install_help_extra(self.io);
            self.help = Help();
        if not res { self.io.tool_error('Unable to initialize interactive help.'); return;  } }
        coder =
            Coder.create(
                io=self.io,
                from_coder=self.coder,
                edit_format='help',
                summarize_from_coder=False,
                map_tokens=512,
                map_mul_no_files=1
            );
        user_msg = self.help.ask(args);
        user_msg += '\n# Announcement lines from when this session of aider was launched:\n\n';
        user_msg += ('\n'.join(self.coder.get_announcements()) + '\n');
        coder.run(user_msg, preproc=False);
        if self.coder.repo_map {
            map_tokens = self.coder.repo_map.max_map_tokens;
            map_mul_no_files = self.coder.repo_map.map_mul_no_files;
        }
            else
            {
            map_tokens = 0;
            map_mul_no_files = 1;
            }

        raise SwitchCoder(
            edit_format=self.coder.edit_format,
            summarize_from_coder=False,
            from_coder=coder,
            map_tokens=map_tokens,
            map_mul_no_files=map_mul_no_files,
            show_announcements=False
        ) ;
    }

    def completions_ask(self: Commands) {
        raise CommandCompletionException() ;
    }

    def completions_code(self: Commands) {
        raise CommandCompletionException() ;
    }

    def completions_architect(self: Commands) {
        raise CommandCompletionException() ;
    }

    def completions_context(self: Commands) {
        raise CommandCompletionException() ;
    }

    """Ask questions about the code base without editing any files. If no prompt provided, switches to ask mode."""
    def cmd_ask(self: Commands, args: Any) {
        return self._generic_chat_command(args, 'ask');
    }

    """Ask for changes to your code. If no prompt provided, switches to code mode."""
    def cmd_code(self: Commands, args: Any) {
        return self._generic_chat_command(args, self.coder.main_model.edit_format);
    }

    """Enter architect/editor mode using 2 different models. If no prompt provided, switches to architect/editor mode."""
    def cmd_architect(self: Commands, args: Any) {
        return self._generic_chat_command(args, 'architect');
    }

    """Enter context mode to see surrounding code context. If no prompt provided, switches to context mode."""
    def cmd_context(self: Commands, args: Any) {
        return self._generic_chat_command(
            args,
            'context',
            placeholder=(args.strip() or None )
        );
    }

    def _generic_chat_command(
        self: Commands,
        args: Any,
        edit_format: Any,
        placeholder: Any = None
    ) {
        if not args.strip() {
            return self.cmd_chat_mode(edit_format);
        }
        import from aider.coders.base_coder { Coder }
        coder =
            Coder.create(
                io=self.io,
                from_coder=self.coder,
                edit_format=edit_format,
                summarize_from_coder=False
            );
        user_msg = args;
        coder.run(user_msg);
        raise SwitchCoder(
            edit_format=self.coder.edit_format,
            summarize_from_coder=False,
            from_coder=coder,
            show_announcements=False,
            placeholder=placeholder
        ) ;
    }

    """Show help about all commands in markdown"""
    def get_help_md(self: Commands) {
        res = '\n|Command|Description|\n|:------|:----------|\n';
        commands = sorted(self.get_commands());
        for cmd in commands {
            cmd_method_name = f"'cmd_'{cmd[ 1 : ]}".replace('-', '_');
            cmd_method = getattr(self, cmd_method_name, None);
            if cmd_method {
                description = cmd_method.__doc__;
                res += f"'| **'{cmd}'** | '{description}' |\n'";
            }
                else
                {
                res += f"'| **'{cmd}'** | |\n'";
                }

        }
        res += '\n';
        return res;
    }

    """Record and transcribe voice input"""
    def cmd_voice(self: Commands, args: Any) {
        not self.voice
            if
            {
            if ('OPENAI_API_KEY' not in os.environ) { self.io.tool_error('To use /voice you must provide an OpenAI API key.'); return;  }

                try
                {
                self.voice =
                    voice.Voice(
                        audio_format=(self.voice_format or 'wav' ),
                        device_name=self.voice_input_device
                    );
                }
                except voice.SoundDeviceError { self.io.tool_error(
                    'Unable to import `sounddevice` and/or `soundfile`, is portaudio installed?'
                ); return;  }
            }

            try
            {
            text = self.voice.record_and_transcribe(None, language=self.voice_language);
            }
            except litellm.OpenAIError as err { self.io.tool_error(f"'Unable to use OpenAI whisper model: '{err}"); return;  }
        if text {
            self.io.placeholder = text;
        }
    }

    """Paste image/text from the clipboard into the chat.        Optionally provide a name for the image."""
    def cmd_paste(self: Commands, args: Any) {
        try { image = ImageGrab.grabclipboard(); text = pyperclip.paste(); if text {
            self.io.tool_output(text);
            return text;
        } self.io.tool_error('No image or text content found in clipboard.'); return;  } except Exception as e {
            self.io.tool_error(f"'Error processing clipboard content: '{e}");
        }
    }

    """Add files to the chat that are for reference only, or turn added files to read-only"""
    def cmd_read_only(self: Commands, args: Any) {
        if not args.strip() { for fname in <>list(self.coder.abs_fnames) {
            self.coder.abs_fnames.remove(fname);
            self.coder.abs_read_only_fnames.add(fname);
            rel_fname = self.coder.get_rel_fname(fname);
            self.io.tool_output(f"'Converted '{rel_fname}' to read-only'");
        } return;  }
        filenames = parse_quoted_filenames(args);
        all_paths = [];
        for pattern in filenames {
            expanded_pattern = expanduser(pattern);
            path_obj = Path(expanded_pattern);
            is_abs = path_obj.is_absolute();
            matches = [];
            if path_obj.exists() {
                matches = [path_obj];
            } elif is_abs {
                matches = [ Path(p) for p in <>glob.glob(expanded_pattern) ];
            }
                else
                {
                matches = <>list(Path(self.coder.root).glob(expanded_pattern));
                }

        if not is_abs {
            path_obj = (Path(self.coder.root) / path_obj);
        } if not matches {
            self.io.tool_error(f"'No matches found for: '{pattern}");
        }
            else
            {
            all_paths.extend(matches);
            }
         }
        for path in sorted(all_paths) {
            abs_path = self.coder.abs_root_path(path);
            if os.path.isfile(abs_path) {
                self._add_read_only_file(abs_path, path);
            } elif os.path.isdir(abs_path) {
                self._add_read_only_directory(abs_path, path);
            }
                else
                {
                self.io.tool_error(f"'Not a file or directory: '{abs_path}");
                }

        }
    }

    def _add_read_only_file(self: Commands, abs_path: Any, original_name: Any) {
        if (is_image_file(original_name)
        and not self.coder.main_model.info.get('supports_vision')
        ) { self.io.tool_error(
            f"'Cannot add image file '{original_name}' as the '{self.coder.main_model.name}' does not support images.'"
        ); return;  }
        if (abs_path in self.coder.abs_read_only_fnames) { self.io.tool_error(
            f"{original_name}' is already in the chat as a read-only file'"
        ); return;  } elif (abs_path in self.coder.abs_fnames) {
            self.coder.abs_fnames.remove(abs_path);
            self.coder.abs_read_only_fnames.add(abs_path);
            self.io.tool_output(
                f"'Moved '{original_name}' from editable to read-only files in the chat'"
            );
        }
            else
            {
            self.coder.abs_read_only_fnames.add(abs_path);
            self.io.tool_output(f"'Added '{original_name}' to read-only files.'");
            }

    }

    def _add_read_only_directory(self: Commands, abs_path: Any, original_name: Any) {
        added_files = 0;
        for (<>root, _, files) in os.walk(abs_path) {
            for file in files {
                file_path = os.path.join(<>root, file);
            if ((file_path not in self.coder.abs_fnames)
            and (file_path not in self.coder.abs_read_only_fnames)
            ) {
                self.coder.abs_read_only_fnames.add(file_path);
                added_files += 1;
            } }
        }
        if (added_files > 0) {
            self.io.tool_output(
                f"'Added '{added_files}' files from directory '{original_name}' to read-only files.'"
            );
        }
            else
            {
            self.io.tool_output(
                f"'No new files added from directory '{original_name}'.'"
            );
            }

    }

    """Print out the current repository map"""
    def cmd_map(self: Commands, args: Any) {
        repo_map = self.coder.get_repo_map();
        if repo_map {
            self.io.tool_output(repo_map);
        }
            else
            {
            self.io.tool_output('No repository map available.');
            }

    }

    """Force a refresh of the repository map"""
    def cmd_map_refresh(self: Commands, args: Any) {
        repo_map = self.coder.get_repo_map(force_refresh=True);
        if repo_map {
            self.io.tool_output('The repo map has been refreshed, use /map to view it.');
        }
    }

    """Print out the current settings"""
    def cmd_settings(self: Commands, args: Any) {
        settings = format_settings(self.parser, self.args);
        announcements = '\n'.join(self.coder.get_announcements());
        model_sections = [];
        active_models =

            [('Main model', self.coder.main_model),
            ('Editor model', getattr(self.coder.main_model, 'editor_model', None)),
            ('Weak model', getattr(self.coder.main_model, 'weak_model', None))];

            for
            (label, model)
            in
            active_models
            {
            not model
                if
                {
                continue;
                }
            info = (getattr(model, 'info', {}) or {} );
            not info
                if
                {
                continue;
                }
            model_sections.append(f"{label}' ('{model.name}'):'");
            for (k, v) in sorted(info.items()) {
                model_sections.append(f"'  '{k}': '{v}");
            }
            model_sections.append('');
            }
        model_metadata = '\n'.join(model_sections);
        output = f"{announcements}'\n'{settings}";
        if model_metadata {
            output += ('\n' + model_metadata);
        }
        self.io.tool_output(output);
    }

    def completions_raw_load(self: Commands, document: Any, complete_event: Any) {
        return self.completions_raw_read_only(document, complete_event);
    }

    """Load and execute commands from a file"""
    def cmd_load(self: Commands, args: Any) {
        if not args.strip() { self.io.tool_error('Please provide a filename containing commands to load.'); return;  }

            try
            {
            with open(args.strip(), 'r', encoding=self.io.encoding, errors='replace') as f  {
                commands = f.readlines();
            }
            }
            except FileNotFoundError { self.io.tool_error(f"'File not found: '{args}"); return;  }
            except Exception as e { self.io.tool_error(f"'Error reading file: '{e}"); return;  }
        for cmd in commands {
            cmd = cmd.strip();
            self.io.tool_output(f"'\nExecuting: '{cmd}");
            try {
                self.run(cmd);
            } except SwitchCoder {
                self.io.tool_error(
                    f""Command '"{cmd}"' is only supported in interactive mode, skipping.""
                );
            }

            if
            (not cmd or cmd.startswith('#') )
            {
            continue;
            } }
    }

    def completions_raw_save(self: Commands, document: Any, complete_event: Any) {
        return self.completions_raw_read_only(document, complete_event);
    }

    """Save commands to a file that can reconstruct the current chat session's files"""
    def cmd_save(self: Commands, args: Any) {
        if not args.strip() { self.io.tool_error('Please provide a filename to save the commands to.'); return;  }
        try {
            with open(args.strip(), 'w', encoding=self.io.encoding) as f  {
                f.write('/drop\n');
                for fname in sorted(self.coder.abs_fnames) {
                    rel_fname = self.coder.get_rel_fname(fname);
                    f.write(f"'/add       '{rel_fname}'\n'");
                }
                for fname in sorted(self.coder.abs_read_only_fnames) {
                    if Path(fname).is_relative_to(self.coder.root) {
                        rel_fname = self.coder.get_rel_fname(fname);
                        f.write(f"'/read-only '{rel_fname}'\n'");
                    }
                        else
                        {
                        f.write(f"'/read-only '{fname}'\n'");
                        }

                }
            }
            self.io.tool_output(f"'Saved commands to '{args.strip()}");
        } except Exception as e {
            self.io.tool_error(f"'Error saving commands to file: '{e}");
        }
    }

    """Toggle multiline mode (swaps behavior of Enter and Meta+Enter)"""
    def cmd_multiline_mode(self: Commands, args: Any) {
        self.io.toggle_multiline_mode();
    }

    """Copy the last assistant message to the clipboard"""
    def cmd_copy(self: Commands, args: Any) {
        all_messages = (self.coder.done_messages + self.coder.cur_messages);
        assistant_messages =
            [ msg for msg in reversed(all_messages) if (msg[ 'role' ] == 'assistant') ];
        if not assistant_messages { self.io.tool_error('No assistant messages found to copy.'); return;  }
        last_assistant_message = assistant_messages[ 0 ][ 'content' ];
        try {
            pyperclip.copy(last_assistant_message);
            preview =
                (last_assistant_message[ : 50 ] + '...')
                if (len(last_assistant_message) > 50)
                else last_assistant_message;
            self.io.tool_output(
                f"'Copied last assistant message to clipboard. Preview: '{preview}"
            );
        } except pyperclip.PyperclipException as e {
            self.io.tool_error(f"'Failed to copy to clipboard: '{str(e)}");
            self.io.tool_output(
                'You may need to install xclip or xsel on Linux, or pbcopy on macOS.'
            );
        } except Exception as e {
            self.io.tool_error(
                f"'An unexpected error occurred while copying to clipboard: '{str(e)}"
            );
        }
    }

    """Report a problem by opening a GitHub Issue"""
    def cmd_report(self: Commands, args: Any) {
        import from aider.report { report_github_issue }
        announcements = '\n'.join(self.coder.get_announcements());
        issue_text = announcements;
        if args.strip() {
            title = args.strip();
        }
            else
            {
            title = None;
            }

        report_github_issue(issue_text, title=title, confirm=False);
    }

    """Open an editor to write a prompt"""
    def cmd_editor(self: Commands, initial_content: Any = '') {
        user_input = pipe_editor(initial_content, suffix='md', editor=self.editor);
        if user_input.strip() {
            self.io.set_placeholder(user_input.rstrip());
        }
    }

    """Alias for /editor: Open an editor to write a prompt"""
    def cmd_edit(self: Commands, args: Any = '') {
        return self.cmd_editor(args);
    }

    """Set the thinking token budget, eg: 8096, 8k, 10.5k, 0.5M, or 0 to disable."""
    def cmd_think_tokens(self: Commands, args: Any) {
        model = self.coder.main_model;
        if not args.strip() { formatted_budget = model.get_thinking_tokens(); if (formatted_budget is None) {
            self.io.tool_output('Thinking tokens are not currently set.');
        }
            else
            {
            budget = model.get_raw_thinking_tokens();
            self.io.tool_output(
                f"'Current thinking token budget: '{budget}' tokens ('{formatted_budget}').'"
            );
            }
         return;  }
        value = args.strip();
        model.set_thinking_tokens(value);
        if (value == '0') {
            self.io.tool_output('Thinking tokens disabled.');
        }
            else
            {
            formatted_budget = model.get_thinking_tokens();
            budget = model.get_raw_thinking_tokens();
            self.io.tool_output(
                f"'Set thinking token budget to '{budget}' tokens ('{formatted_budget}').'"
            );
            }

        self.io.tool_output();
        announcements = '\n'.join(self.coder.get_announcements());
        self.io.tool_output(announcements);
    }

    """Set the reasoning effort level (values: number or low/medium/high depending on model)"""
    def cmd_reasoning_effort(self: Commands, args: Any) {
        model = self.coder.main_model;
        if not args.strip() { reasoning_value = model.get_reasoning_effort(); if (reasoning_value is None) {
            self.io.tool_output('Reasoning effort is not currently set.');
        }
            else
            {
            self.io.tool_output(f"'Current reasoning effort: '{reasoning_value}");
            }
         return;  }
        value = args.strip();
        model.set_reasoning_effort(value);
        reasoning_value = model.get_reasoning_effort();
        self.io.tool_output(f"'Set reasoning effort to '{reasoning_value}");
        self.io.tool_output();
        announcements = '\n'.join(self.coder.get_announcements());
        self.io.tool_output(announcements);
    }

    """Copy the current chat context as markdown, suitable to paste into a web UI"""
    def cmd_copy_context(self: Commands, args: Any = None) {
        chunks = self.coder.format_chat_chunks();
        markdown = '';
        for messages in [chunks.repo, chunks.readonly_files, chunks.chat_files] {
            msg messages
                for
                in
                {

                    if
                    (msg[ 'role' ] != 'user')
                    {
                    continue;
                    }
                if isinstance(content, <>list) {
                    part content
                        for
                        in
                        {
                        if (part.get('type') == 'text') {
                            markdown += (part[ 'text' ] + '\n\n');
                        }
                        }

                        else
                        {
                        markdown += (content + '\n\n');
                        }

                }
                }
            content = msg[ 'content' ];
        }
        args = (args or '' );
        markdown += f""\nJust tell me how to edit the files to make the changes.\nDon't give me back entire files.\nJust show me the edits I need to make.\n\n"{args}'\n'";
        try {
            pyperclip.copy(markdown);
            self.io.tool_output('Copied code context to clipboard.');
        } except pyperclip.PyperclipException as e {
            self.io.tool_error(f"'Failed to copy to clipboard: '{str(e)}");
            self.io.tool_output(
                'You may need to install xclip or xsel on Linux, or pbcopy on macOS.'
            );
        } except Exception as e {
            self.io.tool_error(
                f"'An unexpected error occurred while copying to clipboard: '{str(e)}"
            );
        }
    }
}


def expand_subdir(file_path: Any) {
    if file_path.is_file() { yield file_path ;; return;  }
    if file_path.is_dir() {
        for file in file_path.rglob('*') {
            if file.is_file() {
                yield file ;;
            }
        }
    }
}


def parse_quoted_filenames(args: Any) {
    filenames = re.findall('\\"(.+?)\\"|(\\S+)', args);
    filenames = [ name for sublist in filenames for name in sublist if name ];
    return filenames;
}


def get_help_md() {
    md = Commands(None, None).get_help_md();
    return md;
}


def main() {
    md = get_help_md();
    print(md);
}


with entry {
    if (__name__ == '__main__') {
        status = main();
        sys.exit(status);
    }
}