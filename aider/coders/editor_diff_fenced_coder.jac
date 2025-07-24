import from .editblock_fenced_coder { EditBlockFencedCoder }
import from .editor_diff_fenced_prompts { EditorDiffFencedPrompts }


"""A coder that uses search/replace blocks, focused purely on editing files."""
class EditorDiffFencedCoder(EditBlockFencedCoder) {
    with entry {
        edit_format = 'editor-diff-fenced';
        gpt_prompts = EditorDiffFencedPrompts();
    }
}