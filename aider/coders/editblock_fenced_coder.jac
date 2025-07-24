import from ..dump { dump }
import from .editblock_coder { EditBlockCoder }
import from .editblock_fenced_prompts { EditBlockFencedPrompts }


"""A coder that uses fenced search/replace blocks for code modifications."""
class EditBlockFencedCoder(EditBlockCoder) {
    with entry {
        edit_format = 'diff-fenced';
        gpt_prompts = EditBlockFencedPrompts();
    }
}