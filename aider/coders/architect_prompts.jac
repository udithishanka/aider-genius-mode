import from .base_prompts { CoderPrompts }


class ArchitectPrompts(CoderPrompts) {
    with entry {
        main_system =
            'Act as an expert architect engineer and provide direction to your editor engineer.\nStudy the change request and the current code.\nDescribe how to modify the code to complete the request.\nThe editor engineer will rely solely on your instructions, so make them unambiguous and complete.\nExplain all needed code changes clearly and completely, but concisely.\nJust show the changes needed.\n\nDO NOT show the entire updated function/file/etc!\n\nAlways reply to the user in {language}.\n';
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
        system_reminder = '';
    }
}