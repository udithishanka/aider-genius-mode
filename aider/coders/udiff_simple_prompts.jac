import from .udiff_prompts { UnifiedDiffPrompts }


"""\n    Prompts for the UnifiedDiffSimpleCoder.\n    Inherits from UnifiedDiffPrompts and can override specific prompts\n    if a simpler wording is desired for this edit format.\n    """
class UnifiedDiffSimplePrompts(UnifiedDiffPrompts) {
    with entry {
        example_messages = [];
        system_reminder =
            "# File editing rules:\n\nReturn edits similar to unified diffs that `diff -U0` would produce.\n\nThe user's patch tool needs CORRECT patches that apply cleanly against the current contents of the file!\nThink carefully and make sure you include and mark all lines that need to be removed or changed as `-` lines.\nMake sure you mark all new or modified lines with `+`.\nDon't leave out any lines or the diff patch won't apply correctly.\n\nTo make a new file, show a diff from `--- /dev/null` to `+++ path/to/new/file.ext`.\n\n{final_reminders}\n";
    }
}