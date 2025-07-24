import from .editblock_fenced_prompts { EditBlockFencedPrompts }


class EditorDiffFencedPrompts(EditBlockFencedPrompts) {
    with entry {
        shell_cmd_prompt = '';
        no_shell_cmd_prompt = '';
        shell_cmd_reminder = '';
        go_ahead_tip = '';
        rename_with_shell = '';
    }
}