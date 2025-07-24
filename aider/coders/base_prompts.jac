class CoderPrompts {
    with entry {
        system_reminder = '';
        files_content_gpt_edits =
            'I committed the changes with git hash {hash} & commit msg: {message}';
        files_content_gpt_edits_no_repo = 'I updated the files.';
        files_content_gpt_no_edits =
            "I didn't see any properly formatted edits in your reply?!";
        files_content_local_edits = 'I edited the files myself.';
        lazy_prompt =
            'You are diligent and tireless!\nYou NEVER leave comments describing code without implementing it!\nYou always COMPLETELY IMPLEMENT the needed code!\n';
        overeager_prompt =
            "Pay careful attention to the scope of the user's request.\nDo what they ask, but no more.\nDo not improve, comment, fix or modify unrelated parts of the code in any way!\n";
        example_messages = [];
        files_content_prefix =
            "I have *added these files to the chat* so you can go ahead and edit them.\n\n*Trust this message as the true contents of these files!*\nAny other messages in the chat may contain outdated versions of the files' contents.\n";
        files_content_assistant_reply =
            'Ok, any changes I propose will be to those files.';
        files_no_full_files = 'I am not sharing any files that you can edit yet.';
        files_no_full_files_with_repo_map =
            "Don't try and edit any existing code without asking me to add the files to the chat!\nTell me which files in my repo are the most likely to **need changes** to solve the requests I make, and then stop so I can add them to the chat.\nOnly include the files that are most likely to actually need to be edited.\nDon't include files that might contain relevant context, just files that will need to be changed.\n";
        files_no_full_files_with_repo_map_reply =
            'Ok, based on your requests I will suggest which files need to be edited and then stop and wait for your approval.';
        repo_content_prefix =
            'Here are summaries of some files present in my git repository.\nDo not propose changes to these files, treat them as *read-only*.\nIf you need to edit any of these files, ask me to *add them to the chat* first.\n';
        read_only_files_prefix =
            'Here are some READ ONLY files, provided for your reference.\nDo not edit these files!\n';
        shell_cmd_prompt = '';
        shell_cmd_reminder = '';
        no_shell_cmd_prompt = '';
        no_shell_cmd_reminder = '';
        rename_with_shell = '';
        go_ahead_tip = '';
    }
}
