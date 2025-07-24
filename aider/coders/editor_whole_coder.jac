import from .editor_whole_prompts { EditorWholeFilePrompts }
import from .wholefile_coder { WholeFileCoder }


"""A coder that operates on entire files, focused purely on editing files."""
class EditorWholeFileCoder(WholeFileCoder) {
    with entry {
        edit_format = 'editor-whole';
        gpt_prompts = EditorWholeFilePrompts();
    }
}