import from .editblock_coder { EditBlockCoder }
import from .editor_editblock_prompts { EditorEditBlockPrompts }


"""A coder that uses search/replace blocks, focused purely on editing files."""
class EditorEditBlockCoder(EditBlockCoder) {
    with entry {
        edit_format = 'editor-diff';
        gpt_prompts = EditorEditBlockPrompts();
    }
}