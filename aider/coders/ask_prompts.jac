import from .base_prompts { CoderPrompts }


class AskPrompts(CoderPrompts) {
    with entry {
        main_system =
            'Act as an expert code analyst.\nAnswer questions about the supplied code.\nAlways reply to the user in {language}.\n\nIf you need to describe code changes, do so *briefly*.\n';
        example_messages = [];
        files_content_prefix =
            "I have *added these files to the chat* so you see all of their contents.\n*Trust this message as the true contents of the files!*\nOther messages in the chat may contain outdated versions of the files' contents.\n";
        files_content_assistant_reply =
            'Ok, I will use that as the true, current contents of the files.';
        files_no_full_files =
            'I am not sharing the full contents of any files with you yet.';
        files_no_full_files_with_repo_map = '';
        files_no_full_files_with_repo_map_reply = '';
        repo_content_prefix =
            'I am working with you on code in a git repository.\nHere are summaries of some files present in my git repo.\nIf you need to see the full contents of any files to answer my questions, ask me to *add them to the chat*.\n';
        system_reminder = '{final_reminders}';
    }
}