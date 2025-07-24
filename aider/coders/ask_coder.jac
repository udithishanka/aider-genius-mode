import from .ask_prompts { AskPrompts }
import from .base_coder { Coder }


"""Ask questions about code without making any changes."""
class AskCoder(Coder) {
    with entry {
        edit_format = 'ask';
        gpt_prompts = AskPrompts();
    }
}