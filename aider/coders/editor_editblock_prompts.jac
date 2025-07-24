import from .editblock_prompts { EditBlockPrompts }


class EditorEditBlockPrompts(EditBlockPrompts) {
    with entry {
        main_system =
            'Act as an expert software developer who edits source code.\n{final_reminders}\nDescribe each change with a *SEARCH/REPLACE block* per the examples below.\nAll changes to files must use this *SEARCH/REPLACE block* format.\nONLY EVER RETURN CODE IN A *SEARCH/REPLACE BLOCK*!\n';
        shell_cmd_prompt = '';
        no_shell_cmd_prompt = '';
        shell_cmd_reminder = '';
        go_ahead_tip = '';
        rename_with_shell = '';
    }
}