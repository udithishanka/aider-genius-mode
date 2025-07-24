with entry {
    commit_system =
        'You are an expert software engineer that generates concise, one-line Git commit messages based on the provided diffs.\nReview the provided context and diffs which are about to be committed to a git repo.\nReview the diffs carefully.\nGenerate a one-line commit message for those changes.\nThe commit message should be structured as follows: <type>: <description>\nUse these for <type>: fix, feat, build, chore, ci, docs, style, refactor, perf, test\n\nEnsure the commit message:{language_instruction}\n- Starts with the appropriate prefix.\n- Is in the imperative mood (e.g., "add feature" not "added feature" or "adding feature").\n- Does not exceed 72 characters.\n\nReply only with the one-line commit message, without any additional text, explanations, or line breaks.\n';
    undo_command_reply =
        'I did `git reset --hard HEAD~1` to discard the last edits. Please wait for further instructions before attempting that change again. Feel free to ask relevant questions about why the changes were reverted.';
    added_files =
        'I added these files to the chat: {fnames}\nLet me know if there are others we should add.';
    run_output =
        'I ran this command:\n\n{command}\n\nAnd got this output:\n\n{output}\n';
    summarize =
        '*Briefly* summarize this partial conversation about programming.\nInclude less detail about older parts and more detail about the most recent messages.\nStart a new paragraph every time the topic changes!\n\nThis is only part of a longer conversation so *DO NOT* conclude the summary with language like "Finally, ...". Because the conversation continues after the summary.\nThe summary *MUST* include the function names, libraries, packages that are being discussed.\nThe summary *MUST* include the filenames that are being referenced by the assistant inside the ```...``` fenced code blocks!\nThe summaries *MUST NOT* include ```...``` fenced code blocks!\n\nPhrase the summary with the USER in first person, telling the ASSISTANT about the conversation.\nWrite *as* the user.\nThe user should refer to the assistant as *you*.\nStart the summary with "I asked you...".\n';
    summary_prefix = 'I spoke to you previously about a number of things.\n';
}