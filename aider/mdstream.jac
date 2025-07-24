import io;
import time;

import from rich { box }
import from rich.console { Console }
import from rich.live { Live }
import from rich.markdown { CodeBlock, Heading, Markdown }
import from rich.panel { Panel }
import from rich.syntax { Syntax }
import from rich.text { Text }

import from aider.dump { dump }


with entry {
    _text_prefix =
        "\n# Header\n\nLorem Ipsum is simply dummy text of the printing and typesetting industry.\nLorem Ipsum has been the industry's standard dummy text ever since the 1500s,\nwhen an unknown printer took a galley of type and scrambled it to make a type\nspecimen book. It has survived not only five centuries, but also the leap into\nelectronic typesetting, remaining essentially unchanged. It was popularised in\nthe 1960s with the release of Letraset sheets containing Lorem Ipsum passages,\nand more recently with desktop publishing software like Aldus PageMaker\nincluding versions of Lorem Ipsum.\n\n\n\n## Sub header\n\n- List 1\n- List 2\n- List me\n- List you\n\n\n\n```python\n";
    _text_suffix = '\n```\n\n## Sub header too\n\nThe end.\n\n';
}


"""A code block with syntax highlighting and no padding."""
class NoInsetCodeBlock(CodeBlock) {
    def __rich_console__(self: NoInsetCodeBlock, console: Any, options: Any) {
        code = str(self.text).rstrip();
        syntax =
            Syntax(
                code,
                self.lexer_name,
                theme=self.theme,
                word_wrap=True,
                padding=(1, 0)
            );
        yield syntax ;;
    }
}


"""A heading class that renders left-justified."""
class LeftHeading(Heading) {
    def __rich_console__(self: LeftHeading, console: Any, options: Any) {
        text = self.text;
        text.justify = 'left';
        if (self.tag == 'h1') {
            yield Panel(text, box=box.HEAVY, style='markdown.h1.border') ;;
        } elif (self.tag == 'h2') {
            yield Text('') ;;
        }
    }
}


"""Markdown with code blocks that have no padding and left-justified headings."""
class NoInsetMarkdown(Markdown) {
    with entry {
        elements =

            {** Markdown.elements , 'fence' : NoInsetCodeBlock , 'code_block' : NoInsetCodeBlock , 'heading_open' : LeftHeading };
    }
}


"""Streaming markdown renderer that progressively displays content with a live updating window.\n\n    Uses rich.console and rich.live to render markdown content with smooth scrolling\n    and partial updates. Maintains a sliding window of visible content while streaming\n    in new markdown text.\n    """
class MarkdownStream {
    with entry {
        live = None;
        when = 0;
        min_delay = (1.0 / 20);
        live_window = 6;
    }

    """Initialize the markdown stream.\n\n        Args:\n            mdargs (dict, optional): Additional arguments to pass to rich Markdown renderer\n        """
    def init(self: MarkdownStream, mdargs: Any = None) {
        self.printed = [];
        if mdargs {
            self.mdargs = mdargs;
        }
            else
            {
            self.mdargs = <>dict();
            }

        self.live = None;
        self._live_started = False;
    }

    """Render markdown text to a list of lines.\n\n        Args:\n            text (str): Markdown text to render\n\n        Returns:\n            list: List of rendered lines with line endings preserved\n        """
    def _render_markdown_to_lines(self: MarkdownStream, text: Any) {
        string_io = io.StringIO();
        console = Console(file=string_io, force_terminal=True);
        markdown = NoInsetMarkdown(text, _=self.mdargs);
        console.print(markdown);
        output = string_io.getvalue();
        return output.splitlines(keepends=True);
    }

    """Destructor to ensure Live display is properly cleaned up."""
    def __del__(self: MarkdownStream) {
        if self.live {

                try
                {
                self.live.stop();
                }
                Exception
                    except
                    {
                    ;
                    }
        }
    }

    """Update the displayed markdown content.\n\n        Args:\n            text (str): The markdown text received so far\n            final (bool): If True, this is the final update and we should clean up\n\n        Splits the output into "stable" older lines and the "last few" lines\n        which aren\'t considered stable. They may shift around as new chunks\n        are appended to the markdown text.\n\n        The stable lines emit to the console above the Live window.\n        The unstable lines emit into the Live window so they can be repainted.\n\n        Markdown going to the console works better in terminal scrollback buffers.\n        The live window doesn\'t play nice with terminal scrollback.\n        """
    def update(self: MarkdownStream, text: Any, final: Any = False) {
        if not getattr(self, '_live_started', False) {
            self.live = Live(Text(''), refresh_per_second=(1.0 / self.min_delay));
            self.live.start();
            self._live_started = True;
        }
        now = time.time();

            if
            (not final and ((now - self.when) < self.min_delay) )
            {
            return;
            }
        self.when = now;
        start = time.time();
        lines = self._render_markdown_to_lines(text);
        render_time = (time.time() - start);
        self.min_delay = min(max((render_time * 10), (1.0 / 20)), 2);
        num_lines = len(lines);
        if not final {
            num_lines -= self.live_window;
        }
        if (final or (num_lines > 0) ) {
            num_printed = len(self.printed);
            show = (num_lines - num_printed);
            show = lines[ num_printed : num_lines ];
            show = ''.join(show);
            show = Text.from_ansi(show);
            self.live.console.print(show);
            self.printed = lines[ : num_lines ];

            if
            (show <= 0)
            {
            return;
            } }
        if final { self.live.update(Text('')); self.live.stop(); self.live = None; return;  }
        rest = lines[ num_lines : ];
        rest = ''.join(rest);
        rest = Text.from_ansi(rest);
        self.live.update(rest);
    }

    """\n        Splits text into chunks on blank lines "\n\n".\n        """
    def find_minimal_suffix(self: MarkdownStream, text: Any, match_lines: Any = 50) { }
}


with entry {
    if (__name__ == '__main__') {
        with open('aider/io.py', 'r') as f  {
            code = f.read();
        }
        _text = ((_text_prefix + code) + _text_suffix);
        _text = (_text * 10);
        pm = MarkdownStream();
        print('Using NoInsetMarkdown for code blocks with padding=0');
        for i in range(6, len(_text), 5) {
            pm.update(_text[ : i ]);
            time.sleep(0.01);
        }
        pm.update(_text, final=True);
    }
}
