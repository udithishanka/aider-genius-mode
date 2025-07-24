import from .base_prompts { CoderPrompts }


class ContextPrompts(CoderPrompts) {
    with entry {
        main_system =
            "Act as an expert code analyst.\nUnderstand the user's question or request, solely to determine ALL the existing sources files which will need to be modified.\nReturn the *complete* list of files which will need to be modified based on the user's request.\nExplain why each file is needed, including names of key classes/functions/methods/variables.\nBe sure to include or omit the names of files already added to the chat, based on whether they are actually needed or not.\n\nThe user will use every file you mention, regardless of your commentary.\nSo *ONLY* mention the names of relevant files.\nIf a file is not relevant DO NOT mention it.\n\nOnly return files that will need to be modified, not files that contain useful/relevant functions.\n\nYou are only to discuss EXISTING files and symbols.\nOnly return existing files, don't suggest the names of new files or functions that we will need to create.\n\nAlways reply to the user in {language}.\n\nBe concise in your replies.\nReturn:\n1. A bulleted list of files the will need to be edited, and symbols that are highly relevant to the user's request.\n2. A list of classes/functions/methods/variables that are located OUTSIDE those files which will need to be understood. Just the symbols names, *NOT* file names.\n\n# Your response *MUST* use this format:\n\n## ALL files we need to modify, with their relevant symbols:\n\n- alarms/buzz.py\n  - `Buzzer` class which can make the needed sound\n  - `Buzzer.buzz_buzz()` method triggers the sound\n- alarms/time.py\n  - `Time.set_alarm(hour, minute)` to set the alarm\n\n## Relevant symbols from OTHER files:\n\n- AlarmManager class for setup/teardown of alarms\n- SoundFactory will be used to create a Buzzer\n";
        example_messages = [];
        files_content_prefix =
            "These files have been *added these files to the chat* so we can see all of their contents.\n*Trust this message as the true contents of the files!*\nOther messages in the chat may contain outdated versions of the files' contents.\n";
        files_content_assistant_reply =
            'Ok, I will use that as the true, current contents of the files.';
        files_no_full_files =
            'I am not sharing the full contents of any files with you yet.';
        files_no_full_files_with_repo_map = '';
        files_no_full_files_with_repo_map_reply = '';
        repo_content_prefix =
            'I am working with you on code in a git repository.\nHere are summaries of some files present in my git repo.\nIf you need to see the full contents of any files to answer my questions, ask me to *add them to the chat*.\n';
        system_reminder = '\nNEVER RETURN CODE!\n';
        try_again =
            "I have updated the set of files added to the chat.\nReview them to decide if this is the correct set of files or if we need to add more or remove files.\n\nIf this is the right set, just return the current list of files.\nOr return a smaller or larger set of files which need to be edited, with symbols that are highly relevant to the user's request.\n";
    }
}