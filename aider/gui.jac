import os;
import random;
import sys;

import streamlit as st;

import from aider { urls }
import from aider.coders { Coder }
import from aider.dump { dump }
import from aider.io { InputOutput }
import from aider.main { main as cli_main }
import from aider.scrape { Scraper, has_playwright }


class CaptureIO(InputOutput) {
    with entry {
        lines = [];
    }

    def tool_output(self: CaptureIO, msg: Any, log_only: Any = False) {
        if not log_only {
            self.lines.append(msg);
        }
        <>super().tool_output(msg, log_only=log_only);
    }

    def tool_error(self: CaptureIO, msg: Any) {
        self.lines.append(msg);
        <>super().tool_error(msg);
    }

    def tool_warning(self: CaptureIO, msg: Any) {
        self.lines.append(msg);
        <>super().tool_warning(msg);
    }

    def get_captured_lines(self: CaptureIO) {
        lines = self.lines;
        self.lines = [];
        return lines;
    }
}


def search(text: Any = None) {
    results = [];
    for (<>root, _, files) in os.walk('aider') {
        for file in files {
            path = os.path.join(<>root, file);
        if (not text or (text in path) ) {
            results.append(path);
        } }
    }
    return results;
}


class State {
    with entry {
        keys = <>set();
    }

    def <>init(self: State, key: Any, val: Any = None) {

            if
            (key in self.keys)
            {
            return;
            }
        self.keys.add(key);
        setattr(self, key, val);
        return True;
    }
}


@ st.cache_resource

 def get_state() {
    return State();
}


@ st.cache_resource

 def get_coder() {
    coder = cli_main(return_coder=True);

        if
        not isinstance(coder, Coder)
        {
        raise ValueError(coder) ;
        }

        if
        not coder.repo
        {
        raise ValueError('GUI can currently only be used inside a git repo') ;
        }
    io =
        CaptureIO(
            pretty=False,
            yes=True,
            dry_run=coder.io.dry_run,
            encoding=coder.io.encoding
        );
    coder.commands.io = io;
    for line in coder.get_announcements() {
        coder.io.tool_output(line);
    }
    return coder;
}


class GUI {
    with entry {
        prompt = None;
        prompt_as = 'user';
        last_undo_empty = None;
        recent_msgs_empty = None;
        web_content_empty = None;
    }

    def announce(self: GUI) {
        lines = self.coder.get_announcements();
        lines = '  \n'.join(lines);
        return lines;
    }

    def show_edit_info(self: GUI, edit: Any) {
        commit_hash = edit.get('commit_hash');
        commit_message = edit.get('commit_message');
        diff = edit.get('diff');
        fnames = edit.get('fnames');
        if fnames {
            fnames = sorted(fnames);
        }

            if
            (not commit_hash and not fnames )
            {
            return;
            }
        show_undo = False;
        res = '';
        if commit_hash {
            res += f"'Commit `'{commit_hash}'`: '{commit_message}'  \n'";
        if (commit_hash == self.coder.last_aider_commit_hash) {
            show_undo = True;
        } }
        if fnames {
            fnames = [ f"'`'{fname}'`'" for fname in fnames ];
            fnames = ', '.join(fnames);
            res += f"'Applied edits to '{fnames}'.'";
        }
        if diff {
            with st.expander(res)  {
                st.code(diff, language='diff');
                if show_undo {
                    self.add_undo(commit_hash);
                }
            }
        }
            else
            {
            with st.container(border=True)  {
                st.write(res);
                if show_undo {
                    self.add_undo(commit_hash);
                }
            }
            }

    }

    def add_undo(self: GUI, commit_hash: Any) {
        if self.last_undo_empty {
            self.last_undo_empty.empty();
        }
        self.last_undo_empty = st.empty();
        undone = (self.state.last_undone_commit_hash == commit_hash);
        if not undone {
            with self.last_undo_empty  {
                if self.button(
                    f"'Undo commit `'{commit_hash}'`'",
                    key=f"'undo_'{commit_hash}"
                ) {
                    self.do_undo(commit_hash);
                }
            }
        }
    }

    def do_sidebar(self: GUI) {
        with st.sidebar  {
            st.title('Aider');
            self.do_add_to_chat();
            self.do_recent_msgs();
            self.do_clear_chat_history();
            st.warning(
                'This browser version of aider is experimental. Please share feedback in [GitHub issues](https://github.com/Aider-AI/aider/issues).'
            );
        }
    }

    def do_settings_tab(self: GUI) {
        ;
    }

    def do_recommended_actions(self: GUI) {
        text = 'Aider works best when your code is stored in a git repo.  \n';
        text += f"'[See the FAQ for more info]('{urls.git}')'";
        with st.expander('Recommended actions', expanded=True)  {
            with st.popover('Create a git repo to track changes')  {
                st.write(text);
                self.button('Create git repo', key=random.random(), help='?');
            }
            with st.popover('Update your `.gitignore` file')  {
                st.write(
                    "It's best to keep aider's internal files out of your git repo."
                );
                self.button(
                    'Add `.aider*` to `.gitignore`',
                    key=random.random(),
                    help='?'
                );
            }
        }
    }

    def do_add_to_chat(self: GUI) {
        self.do_add_files();
        self.do_add_web_page();
    }

    def do_add_files(self: GUI) {
        fnames =
            st.multiselect(
                'Add files to the chat',
                self.coder.get_all_relative_files(),
                default=self.state.initial_inchat_files,
                placeholder='Files to edit',
                disabled=self.prompt_pending(),
                help='Only add the files that need to be *edited* for the task you are working on. Aider will pull in other relevant code to provide context to the LLM.'
            );

            for
            fname
            in
            fnames
            {
            if (fname not in self.coder.get_inchat_relative_files()) {
                self.coder.add_rel_fname(fname);
                self.info(f"'Added '{fname}' to the chat'");
            }
            }

            for
            fname
            in
            self.coder.get_inchat_relative_files()
            {
            if (fname not in fnames) {
                self.coder.drop_rel_fname(fname);
                self.info(f"'Removed '{fname}' from the chat'");
            }
            }
    }

    def do_add_web_page(self: GUI) {
        with st.popover('Add a web page to the chat')  {
            self.do_web();
        }
    }

    def do_add_image(self: GUI) {
        with st.popover('Add image')  {
            st.markdown('Hello World 👋');
            st.file_uploader('Image file', disabled=self.prompt_pending());
        }
    }

    def do_run_shell(self: GUI) {
        with st.popover('Run shell commands, tests, etc')  {
            st.markdown(
                'Run a shell command and optionally share the output with the LLM. This is a great way to run your program or run tests and have the LLM fix bugs.'
            );
            st.text_input('Command:');
            st.radio(
                'Share the command output with the LLM?',

                ['Review the output and decide whether to share',
                'Automatically share the output on non-zero exit code (ie, if any tests fail)']
            );
            st.selectbox(
                'Recent commands',
                ['my_app.py --doit', 'my_app.py --cleanup'],
                disabled=self.prompt_pending()
            );
        }
    }

    def do_tokens_and_cost(self: GUI) {
        st.expander('Tokens and costs', expanded=True)
            with
            {
            ;
            }
    }

    def do_show_token_usage(self: GUI) {
        with st.popover('Show token usage')  {
            st.write('hi');
        }
    }

    def do_clear_chat_history(self: GUI) {
        text = 'Saves tokens, reduces confusion';
        if self.button('Clear chat history', help=text) {
            self.coder.done_messages = [];
            self.coder.cur_messages = [];
            self.info(
                "Cleared chat history. Now the LLM can't see anything before this line."
            );
        }
    }

    def do_show_metrics(self: GUI) {
        st.metric('Cost of last message send & reply', '$0.0019', help='foo');
        st.metric('Cost to send next message', '$0.0013', help='foo');
        st.metric('Total cost this session', '$0.22');
    }

    def do_git(self: GUI) {
        with st.expander('Git', expanded=False)  {
            self.button('Commit any pending changes');
            with st.popover('Run git command')  {
                st.markdown('## Run git command');
                st.text_input('git', value='git ');
                self.button('Run');
                st.selectbox(
                    'Recent git commands',
                    ['git checkout -b experiment', 'git stash'],
                    disabled=self.prompt_pending()
                );
            }
        }
    }

    def do_recent_msgs(self: GUI) {
        if not self.recent_msgs_empty {
            self.recent_msgs_empty = st.empty();
        }
        if self.prompt_pending() {
            self.recent_msgs_empty.empty();
            self.state.recent_msgs_num += 1;
        }
        with self.recent_msgs_empty  {
            self.old_prompt =
                st.selectbox(
                    'Resend a recent chat message',
                    self.state.input_history,
                    placeholder='Choose a recent chat message',
                    index=None,
                    key=f"'recent_msgs_'{self.state.recent_msgs_num}",
                    disabled=self.prompt_pending()
                );
            if self.old_prompt {
                self.prompt = self.old_prompt;
            }
        }
    }

    def do_messages_container(self: GUI) {
        self.messages = st.container();
        with self.messages  {
            for msg in self.state.messages {
                role = msg[ 'role' ];
            if (role == 'edit') {
                self.show_edit_info(msg);
            } elif (role == 'info') {
                st.info(msg[ 'content' ]);
            } elif (role == 'text') {
                text = msg[ 'content' ];
                line = text.splitlines()[ 0 ];
                with self.messages.expander(line)  {
                    st.text(text);
                }
            } elif (role in ('user', 'assistant')) {
                with st.chat_message(role)  {
                    st.write(msg[ 'content' ]);
                }
            }
                else
                {
                st.dict(msg);
                }
                }
        }
    }

    def initialize_state(self: GUI) {
        messages =

            [<>dict(role='info', content=self.announce()),
            <>dict(role='assistant', content='How can I help you?')];
        self.state.<>init('messages', messages);
        self.state.<>init('last_aider_commit_hash', self.coder.last_aider_commit_hash);
        self.state.<>init('last_undone_commit_hash');
        self.state.<>init('recent_msgs_num', 0);
        self.state.<>init('web_content_num', 0);
        self.state.<>init('prompt');
        self.state.<>init('scraper');
        self.state.<>init(
            'initial_inchat_files',
            self.coder.get_inchat_relative_files()
        );
        if ('input_history' not in self.state.keys) {
            input_history = <>list(self.coder.io.get_input_history());
            seen = <>set();
            input_history =
                [ x for x in input_history if not ((x in seen) or seen.add(x) ) ];
            self.state.input_history = input_history;
            self.state.keys.add('input_history');
        }
    }

    """Create a button, disabled if prompt pending"""
    def button(self: GUI, args: Any, **kwargs: Any) {
        if self.prompt_pending() {
            kwargs[ 'disabled' ] = True;
        }
        return st.button(args, _=kwargs);
    }

    def init(self: GUI) {
        self.coder = get_coder();
        self.state = get_state();
        self.coder.yield_stream = True;
        self.coder.stream = True;
        self.coder.pretty = False;
        self.initialize_state();
        self.do_messages_container();
        self.do_sidebar();
        user_inp = st.chat_input('Say something');
        if user_inp {
            self.prompt = user_inp;
        }
        if self.prompt_pending() {
            self.process_chat();
        }
        not self.prompt
            if
            {
            return;
            }
        self.state.prompt = self.prompt;
        if (self.prompt_as == 'user') {
            self.coder.io.add_to_input_history(self.prompt);
        }
        self.state.input_history.append(self.prompt);
        if self.prompt_as {
            self.state.messages.append(
                {'role' : self.prompt_as , 'content' : self.prompt }
            );
        }
        if (self.prompt_as == 'user') {
            with self.messages.chat_message('user')  {
                st.write(self.prompt);
            }
        } elif (self.prompt_as == 'text') {
            line = self.prompt.splitlines()[ 0 ];
            line += '??';
            with self.messages.expander(line)  {
                st.text(self.prompt);
            }
        }
        st.rerun();
    }

    def prompt_pending(self: GUI) {
        return (self.state.prompt is not None);
    }

    def cost(self: GUI) {
        cost = ((random.random() * 0.003) + 0.001);
        st.caption(f"'$'{cost}");
    }

    def process_chat(self: GUI) {
        prompt = self.state.prompt;
        self.state.prompt = None;
        self.num_reflections = 0;
        self.max_reflections = 3;
        while prompt {
            with self.messages.chat_message('assistant')  {
                res = st.write_stream(self.coder.run_stream(prompt));
                self.state.messages.append({'role' : 'assistant' , 'content' : res });
            }
            prompt = None;

                if
                self.coder.reflected_message
                {
                if (self.num_reflections < self.max_reflections) {
                    self.num_reflections += 1;
                    self.info(self.coder.reflected_message);
                    prompt = self.coder.reflected_message;
                }
                }
        }
        with self.messages  {
            edit = <>dict(role='edit', fnames=self.coder.aider_edited_files);
            self.state.messages.append(edit);
            self.show_edit_info(edit);
        if (self.state.last_aider_commit_hash != self.coder.last_aider_commit_hash) {
            edit[ 'commit_hash' ] = self.coder.last_aider_commit_hash;
            edit[ 'commit_message' ] = self.coder.last_aider_commit_message;
            commits = f"{self.coder.last_aider_commit_hash}'~1'";
            diff =
                self.coder.repo.diff_commits(
                    self.coder.pretty,
                    commits,
                    self.coder.last_aider_commit_hash
                );
            edit[ 'diff' ] = diff;
            self.state.last_aider_commit_hash = self.coder.last_aider_commit_hash;
        } }
        st.rerun();
    }

    def info(self: GUI, message: Any, echo: Any = True) {
        info = <>dict(role='info', content=message);
        self.state.messages.append(info);
        if echo {
            self.messages.info(message);
        }
    }

    def do_web(self: GUI) {
        st.markdown('Add the text content of a web page to the chat');
        if not self.web_content_empty {
            self.web_content_empty = st.empty();
        }
        if self.prompt_pending() {
            self.web_content_empty.empty();
            self.state.web_content_num += 1;
        }
        with self.web_content_empty  {
            self.web_content =
                st.text_input(
                    'URL',
                    placeholder='https://...',
                    key=f"'web_content_'{self.state.web_content_num}"
                );
        }
        not self.web_content
            if
            {
            return;
            }
        url = self.web_content;
        if not self.state.scraper {
            self.scraper =
                Scraper(print_error=self.info, playwright_available=has_playwright());
        }
        content = (self.scraper.scrape(url) or '' );
        if content.strip() {
            content = (f"{url}'\n\n'" + content);
            self.prompt = content;
            self.prompt_as = 'text';
        }
            else
            {
            self.info(f"'No web content found for `'{url}'`.'");
            self.web_content = None;
            }

    }

    def do_undo(self: GUI, commit_hash: Any) {
        self.last_undo_empty.empty();
        if ((self.state.last_aider_commit_hash != commit_hash)
        or (self.coder.last_aider_commit_hash != commit_hash)
        ) { self.info(f"'Commit `'{commit_hash}'` is not the latest commit.'"); return;  }
        self.coder.commands.io.get_captured_lines();
        reply = self.coder.commands.cmd_undo(None);
        lines = self.coder.commands.io.get_captured_lines();
        lines = '\n'.join(lines);
        lines = lines.splitlines();
        lines = '  \n'.join(lines);
        self.info(lines, echo=False);
        self.state.last_undone_commit_hash = commit_hash;
        if reply {
            self.prompt_as = None;
            self.prompt = reply;
        }
    }
}


def gui_main() {
    st.set_page_config(
        layout='wide',
        page_title='Aider',
        page_icon=urls.favicon,
        menu_items=
        {'Get Help' : urls.website , 'Report a bug' : 'https://github.com/Aider-AI/aider/issues' , 'About' : '# Aider\nAI pair programming in your browser.' }
    );
    GUI();
}


with entry {
    if (__name__ == '__main__') {
        status = gui_main();
        sys.exit(status);
    }
}