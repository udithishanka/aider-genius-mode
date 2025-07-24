import from ..dump { dump }
import from .base_coder { Coder }
import from .help_prompts { HelpPrompts }


"""Interactive help and documentation about aider."""
class HelpCoder(Coder) {
    with entry {
        edit_format = 'help';
        gpt_prompts = HelpPrompts();
    }

    def get_edits(self: HelpCoder, mode: Any = 'update') {
        return [];
    }

    def apply_edits(self: HelpCoder, edits: Any) {
        ;
    }
}