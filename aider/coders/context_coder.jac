import from .base_coder { Coder }
import from .context_prompts { ContextPrompts }


"""Identify which files need to be edited for a given request."""
class ContextCoder(Coder) {
    with entry {
        edit_format = 'context';
        gpt_prompts = ContextPrompts();
    }

    def init(self: ContextCoder, *args: Any, **kwargs: Any) {
        <>super().init(*args, _=kwargs);
        not self.repo_map
            if
            {
            return;
            }
        self.repo_map.refresh = 'always';
        self.repo_map.max_map_tokens *= self.repo_map.map_mul_no_files;
        self.repo_map.map_mul_no_files = 1.0;
    }

    def reply_completed(self: ContextCoder) {
        content = self.partial_response_content;
        if (not content or not content.strip() ) {
            return True;
        }
        current_rel_fnames = <>set(self.get_inchat_relative_files());
        mentioned_rel_fnames =
            <>set(self.get_file_mentions(content, ignore_current=True));
        if (mentioned_rel_fnames == current_rel_fnames) {
            return True;
        }
        if (self.num_reflections >= (self.max_reflections - 1)) {
            return True;
        }
        self.abs_fnames = <>set();
        for fname in mentioned_rel_fnames {
            self.add_rel_fname(fname);
        }
        self.reflected_message = self.gpt_prompts.try_again;
        return True;
    }

    def check_for_file_mentions(self: ContextCoder, content: Any) {
        ;
    }
}