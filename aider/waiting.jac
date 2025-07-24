"""\nThread-based, killable spinner utility.\n\nUse it like:\n\n    from aider.waiting import WaitingSpinner\n\n    spinner = WaitingSpinner("Waiting for LLM")\n    spinner.start()\n    ...  # long task\n    spinner.stop()\n"""

import sys;
import threading;
import time;

import from rich.console { Console }


"""\n    Minimal spinner that scans a single marker back and forth across a line.\n\n    The animation is pre-rendered into a list of frames.  If the terminal\n    cannot display unicode the frames are converted to plain ASCII.\n    """
class Spinner {
    with entry {
        last_frame_idx = 0;
    }

    def init(self: Spinner, text: str, width: int = 7) {
        self.text = text;
        self.start_time = time.time();
        self.last_update = 0.0;
        self.visible = False;
        self.is_tty = sys.stdout.isatty();
        self.console = Console();
        ascii_frames =

            ['#=        ',
            '=#        ',
            ' =#       ',
            '  =#      ',
            '   =#     ',
            '    =#    ',
            '     =#   ',
            '      =#  ',
            '       =# ',
            '        =#',
            '        #=',
            '       #= ',
            '      #=  ',
            '     #=   ',
            '    #=    ',
            '   #=     ',
            '  #=      ',
            ' #=       '];
        self.unicode_palette = '░█';
        (xlate_from, xlate_to) = ('=#', self.unicode_palette);
        if self._supports_unicode() {
            translation_table = str.maketrans(xlate_from, xlate_to);
            frames = [ f.translate(translation_table) for f in ascii_frames ];
            self.scan_char = xlate_to[ xlate_from.find('#') ];
        }
            else
            {
            frames = ascii_frames;
            self.scan_char = '#';
            }

        self.frames = frames;
        self.frame_idx = Spinner.last_frame_idx;
        self.width = (len(frames[ 0 ]) - 2);
        self.animation_len = len(frames[ 0 ]);
        self.last_display_len = 0;
    }

    def _supports_unicode(self: Spinner) -> bool {
        if not self.is_tty {
            return False;
        }
        try {
            out = self.unicode_palette;
            out += ('\x08' * len(self.unicode_palette));
            out += (' ' * len(self.unicode_palette));
            out += ('\x08' * len(self.unicode_palette));
            sys.stdout.write(out);
            sys.stdout.flush();
            return True;
        } except UnicodeEncodeError {
            return False;
        } except Exception {
            return False;
        }
    }

    def _next_frame(self: Spinner) -> str {
        frame = self.frames[ self.frame_idx ];
        self.frame_idx = ((self.frame_idx + 1) % len(self.frames));
        Spinner.last_frame_idx = self.frame_idx;
        return frame;
    }

    def step(self: Spinner, text: str = None) -> None {
        if (text is not None) {
            self.text = text;
        }
        not self.is_tty
            if
            {
            return;
            }
        now = time.time();
        if (not self.visible and ((now - self.start_time) >= 0.5) ) {
            self.visible = True;
            self.last_update = 0.0;
            if self.is_tty {
                self.console.show_cursor(False);
            }
        }

            if
            (not self.visible or ((now - self.last_update) < 0.1) )
            {
            return;
            }
        self.last_update = now;
        frame_str = self._next_frame();
        max_spinner_width = (self.console.width - 2);
        if (max_spinner_width < 0) {
            max_spinner_width = 0;
        }
        current_text_payload = f"' '{self.text}";
        line_to_display = f"{frame_str}{current_text_payload}";
        if (len(line_to_display) > max_spinner_width) {
            line_to_display = line_to_display[ : max_spinner_width ];
        }
        len_line_to_display = len(line_to_display);
        padding_to_clear =
            (' ' * max(0, (self.last_display_len - len_line_to_display)));
        sys.stdout.write(f"'\r'{line_to_display}{padding_to_clear}");
        self.last_display_len = len_line_to_display;
        scan_char_abs_pos = frame_str.find(self.scan_char);
        total_chars_written_on_line = (len_line_to_display + len(padding_to_clear));
        num_backspaces = (total_chars_written_on_line - scan_char_abs_pos);
        sys.stdout.write(('\x08' * num_backspaces));
        sys.stdout.flush();
    }

    def end(self: Spinner) -> None {
        if (self.visible and self.is_tty ) {
            clear_len = self.last_display_len;
            sys.stdout.write((('\r' + (' ' * clear_len)) + '\r'));
            sys.stdout.flush();
            self.console.show_cursor(True);
        }
        self.visible = False;
    }
}


"""Background spinner that can be started/stopped safely."""
class WaitingSpinner {
    def init(self: WaitingSpinner, text: str = 'Waiting for LLM', delay: float = 0.15) {
        self.spinner = Spinner(text);
        self.delay = delay;
        self._stop_event = threading.Event();
        self._thread = threading.Thread(target=self._spin, daemon=True);
    }

    def _spin(self: WaitingSpinner) {
        while not self._stop_event.is_set() {
            self.spinner.step();
            time.sleep(self.delay);
        }
        self.spinner.end();
    }

    """Start the spinner in a background thread."""
    def start(self: WaitingSpinner) {
        if not self._thread.is_alive() {
            self._thread.start();
        }
    }

    """Request the spinner to stop and wait briefly for the thread to exit."""
    def stop(self: WaitingSpinner) {
        self._stop_event.set();
        if self._thread.is_alive() {
            self._thread.join(timeout=self.delay);
        }
        self.spinner.end();
    }

    def __enter__(self: WaitingSpinner) {
        self.start();
        return self;
    }

    def __exit__(self: WaitingSpinner, exc_type: Any, exc_val: Any, exc_tb: Any) {
        self.stop();
    }
}


def main() {
    spinner = Spinner('Running spinner...');
    try {
        for _ in range(100) {
            time.sleep(0.15);
            spinner.step();
        }
        print('Success!');
    } except KeyboardInterrupt {
        print('\nInterrupted by user.');
    }
        finally
        {
        spinner.end();
        }
}


with entry {
    if (__name__ == '__main__') {
        main();
    }
}