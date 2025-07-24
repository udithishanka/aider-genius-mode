import from .wholefile_prompts { WholeFilePrompts }


class EditorWholeFilePrompts(WholeFilePrompts) {
    with entry {
        main_system =
            'Act as an expert software developer and make changes to source code.\n{final_reminders}\nOutput a copy of each file that needs changes.\n';
    }
}