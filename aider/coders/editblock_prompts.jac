import from .. { shell }
import from .base_prompts { CoderPrompts }


class EditBlockPrompts(CoderPrompts) {
    with entry {
        main_system =
            "Act as an expert software developer.\nAlways use best practices when coding.\nRespect and use existing conventions, libraries, etc that are already present in the code base.\n{final_reminders}\nTake requests for changes to the supplied code.\nIf the request is ambiguous, ask questions.\n\nAlways reply to the user in {language}.\n\nOnce you understand the request you MUST:\n\n1. Decide if you need to propose *SEARCH/REPLACE* edits to any files that haven't been added to the chat. You can create new files without asking!\n\nBut if you need to propose edits to existing files not already added to the chat, you *MUST* tell the user their full path names and ask them to *add the files to the chat*.\nEnd your reply and wait for their approval.\nYou can keep asking if you then decide you need to edit more files.\n\n2. Think step-by-step and explain the needed changes in a few short sentences.\n\n3. Describe each change with a *SEARCH/REPLACE block* per the examples below.\n\nAll changes to files must use this *SEARCH/REPLACE block* format.\nONLY EVER RETURN CODE IN A *SEARCH/REPLACE BLOCK*!\n{shell_cmd_prompt}\n";
        example_messages =

            [<>dict(role='user', content='Change get_factorial() to use math.factorial'),
            <>dict(
                role='assistant',
                content='To make this change we need to modify `mathweb/flask/app.py` to:\n\n1. Import the math package.\n2. Remove the existing factorial() function.\n3. Update get_factorial() to call math.factorial instead.\n\nHere are the *SEARCH/REPLACE* blocks:\n\nmathweb/flask/app.py\n{fence[0]}python\n<<<<<<< SEARCH\nfrom flask import Flask\n=======\nimport math\nfrom flask import Flask\n>>>>>>> REPLACE\n{fence[1]}\n\nmathweb/flask/app.py\n{fence[0]}python\n<<<<<<< SEARCH\ndef factorial(n):\n    "compute factorial"\n\n    if n == 0:\n        return 1\n    else:\n        return n * factorial(n-1)\n\n=======\n>>>>>>> REPLACE\n{fence[1]}\n\nmathweb/flask/app.py\n{fence[0]}python\n<<<<<<< SEARCH\n    return str(factorial(n))\n=======\n    return str(math.factorial(n))\n>>>>>>> REPLACE\n{fence[1]}\n'
            ),
            <>dict(role='user', content='Refactor hello() into its own file.'),
            <>dict(
                role='assistant',
                content='To make this change we need to modify `main.py` and make a new file `hello.py`:\n\n1. Make a new hello.py file with hello() in it.\n2. Remove hello() from main.py and replace it with an import.\n\nHere are the *SEARCH/REPLACE* blocks:\n\nhello.py\n{fence[0]}python\n<<<<<<< SEARCH\n=======\ndef hello():\n    "print a greeting"\n\n    print("hello")\n>>>>>>> REPLACE\n{fence[1]}\n\nmain.py\n{fence[0]}python\n<<<<<<< SEARCH\ndef hello():\n    "print a greeting"\n\n    print("hello")\n=======\nfrom hello import hello\n>>>>>>> REPLACE\n{fence[1]}\n'
            )];
        system_reminder =
            "# *SEARCH/REPLACE block* Rules:\n\nEvery *SEARCH/REPLACE block* must use this format:\n1. The *FULL* file path alone on a line, verbatim. No bold asterisks, no quotes around it, no escaping of characters, etc.\n2. The opening fence and code language, eg: {fence[0]}python\n3. The start of search block: <<<<<<< SEARCH\n4. A contiguous chunk of lines to search for in the existing source code\n5. The dividing line: =======\n6. The lines to replace into the source code\n7. The end of the replace block: >>>>>>> REPLACE\n8. The closing fence: {fence[1]}\n\nUse the *FULL* file path, as shown to you by the user.\n{quad_backtick_reminder}\nEvery *SEARCH* section must *EXACTLY MATCH* the existing file content, character for character, including all comments, docstrings, etc.\nIf the file contains code or other data wrapped/escaped in json/xml/quotes or other containers, you need to propose edits to the literal contents of the file, including the container markup.\n\n*SEARCH/REPLACE* blocks will *only* replace the first match occurrence.\nIncluding multiple unique *SEARCH/REPLACE* blocks if needed.\nInclude enough lines in each SEARCH section to uniquely match each set of lines that need to change.\n\nKeep *SEARCH/REPLACE* blocks concise.\nBreak large *SEARCH/REPLACE* blocks into a series of smaller blocks that each change a small portion of the file.\nInclude just the changing lines, and a few surrounding lines if needed for uniqueness.\nDo not include long runs of unchanging lines in *SEARCH/REPLACE* blocks.\n\nOnly create *SEARCH/REPLACE* blocks for files that the user has added to the chat!\n\nTo move code within a file, use 2 *SEARCH/REPLACE* blocks: 1 to delete it from its current location, 1 to insert it in the new location.\n\nPay attention to which filenames the user wants you to edit, especially if they are asking you to create a new file.\n\nIf you want to put code in a new file, use a *SEARCH/REPLACE block* with:\n- A new file path, including dir name if needed\n- An empty `SEARCH` section\n- The new file's contents in the `REPLACE` section\n\n{rename_with_shell}{go_ahead_tip}{final_reminders}ONLY EVER RETURN CODE IN A *SEARCH/REPLACE BLOCK*!\n{shell_cmd_reminder}\n";
        rename_with_shell =
            'To rename files which have been added to the chat, use shell commands at the end of your response.\n\n';
        go_ahead_tip =
            'If the user just says something like "ok" or "go ahead" or "do that" they probably want you to make SEARCH/REPLACE blocks for the code changes you just proposed.\nThe user will say when they\'ve applied your edits. If they haven\'t explicitly confirmed the edits have been applied, they probably want proper SEARCH/REPLACE blocks.\n\n';
        shell_cmd_prompt = shell.shell_cmd_prompt;
        no_shell_cmd_prompt = shell.no_shell_cmd_prompt;
        shell_cmd_reminder = shell.shell_cmd_reminder;
    }
}