import from .base_prompts { CoderPrompts }


class WholeFileFunctionPrompts(CoderPrompts) {
    with entry {
        main_system =
            'Act as an expert software developer.\nTake requests for changes to the supplied code.\nIf the request is ambiguous, ask questions.\n\nOnce you understand the request you MUST use the `write_file` function to edit the files to make the needed changes.\n';
        system_reminder =
            '\nONLY return code using the `write_file` function.\nNEVER return code outside the `write_file` function.\n';
        files_content_prefix = 'Here is the current content of the files:\n';
        files_no_full_files = 'I am not sharing any files yet.';
        redacted_edit_message = 'No changes are needed.';
        repo_content_prefix = None;
    }
}