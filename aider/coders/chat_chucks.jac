import from dataclasses { dataclass, field }
import from typing { List }


@ dataclass
class ChatChunks {
    with entry {
        system: List = field(default_factory=<>list);
        examples: List = field(default_factory=<>list);
        done: List = field(default_factory=<>list);
        repo: List = field(default_factory=<>list);
        readonly_files: List = field(default_factory=<>list);
        chat_files: List = field(default_factory=<>list);
        cur: List = field(default_factory=<>list);
        reminder: List = field(default_factory=<>list);
    }

    def all_messages(self: ChatChunks) {
        return (((((((self.system + self.examples) + self.readonly_files) + self.repo) + self.done) + self.chat_files) + self.cur) + self.reminder);
    }

    def add_cache_control_headers(self: ChatChunks) {
        if self.examples {
            self.add_cache_control(self.examples);
        }
            else
            {
            self.add_cache_control(self.system);
            }

        if self.repo {
            self.add_cache_control(self.repo);
        }
            else
            {
            self.add_cache_control(self.readonly_files);
            }

        self.add_cache_control(self.chat_files);
    }

    def add_cache_control(self: ChatChunks, messages: Any) {
        not messages
            if
            {
            return;
            }
        content = messages[ -1 ][ 'content' ];
        if (<>type(content) is str) {
            content = <>dict(type='text', text=content);
        }
        content[ 'cache_control' ] = {'type' : 'ephemeral' };
        messages[ -1 ][ 'content' ] = [content];
    }

    def cacheable_messages(self: ChatChunks) {
        messages = self.all_messages();
        (i, message) enumerate(reversed(messages))
            for
            in
            {
            if (isinstance(message.get('content'), <>list)
            and message[ 'content' ][ 0 ].get('cache_control')
            ) {
                return messages[ : (len(messages) - i) ];
            }
            }
        return messages;
    }
}
