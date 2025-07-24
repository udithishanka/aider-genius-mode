import threading;
import time;

import pyperclip;


"""Watches clipboard for changes and updates IO placeholder"""
class ClipboardWatcher {
    def init(self: ClipboardWatcher, io: Any, verbose: Any = False) {
        self.io = io;
        self.verbose = verbose;
        self.stop_event = None;
        self.watcher_thread = None;
        self.last_clipboard = None;
        self.io.clipboard_watcher = self;
    }

    """Start watching clipboard for changes"""
    def start(self: ClipboardWatcher) {
        self.stop_event = threading.Event();
        self.last_clipboard = pyperclip.paste();
        def watch_clipboard() {
            while not self.stop_event.is_set() {

                    try
                    {
                    current = pyperclip.paste();
                    time.sleep(0.5);
                    }
                    except Exception as e { if self.verbose {
                        import from aider.dump { dump }
                        dump(f"'Clipboard watcher error: '{e}");
                    } continue; }
                if (current != self.last_clipboard) { self.last_clipboard = current; self.io.interrupt_input(); self.io.placeholder =
                    current; if (len(current.splitlines()) > 1) {
                    self.io.placeholder = (('\n' + self.io.placeholder) + '\n');
                } }
            }
        }
        self.watcher_thread = threading.Thread(target=watch_clipboard, daemon=True);
        self.watcher_thread.start();
    }

    """Stop watching clipboard for changes"""
    def stop(self: ClipboardWatcher) {
        if self.stop_event {
            self.stop_event.set();
        }
        if self.watcher_thread {
            self.watcher_thread.join();
            self.watcher_thread = None;
            self.stop_event = None;
        }
    }
}


"""Example usage of the clipboard watcher"""
def main() {
    import from aider.io { InputOutput }
    io = InputOutput();
    watcher = ClipboardWatcher(io, verbose=True);
    try {
        watcher.start();
        while True {
            time.sleep(1);
        }
    } except KeyboardInterrupt {
        print('\nStopped watching clipboard');
        watcher.stop();
    }
}


with entry {
    if (__name__ == '__main__') {
        main();
    }
}