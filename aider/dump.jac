"""\nEditor module for handling system text editor interactions.\n\nThis module provides functionality to:\n- Discover and launch the system's configured text editor\n- Create and manage temporary files for editing\n- Handle editor preferences from environment variables\n- Support cross-platform editor operations\n"""

import os;
import platform;
import subprocess;
import tempfile;

import from rich.console { Console }

import from aider.dump { dump }


with entry {
    DEFAULT_EDITOR_NIX = 'vi';
    DEFAULT_EDITOR_OS_X = 'vim';
    DEFAULT_EDITOR_WINDOWS = 'notepad';
    console = Console();
}


"""\n    Print a status message with appropriate styling.\n\n    :param success: Whether the operation was successful\n    :param message: The message to display\n    :param style: Optional style override. If None, uses green for success and red for failure\n    """
def print_status_message(success: Any, message: Any, style: Any = None) {
    if (style is None) {
        style = 'bold green' if success else 'bold red';
    }
    console.print(message, style=style);
    print('');
}


"""\n    Create a temporary file with the given input data.\n\n    :param input_data: Content to write to the temporary file\n    :param suffix: Optional file extension (without the dot)\n    :param prefix: Optional prefix for the temporary filename\n    :param dir: Optional directory to create the file in\n    :return: Path to the created temporary file\n    :raises: OSError if file creation or writing fails\n    """
def write_temp_file(
    input_data: Any = '',
    suffix: Any = None,
    prefix: Any = None,
    dir: Any = None
) {
    kwargs = {'prefix' : prefix , 'dir' : dir };
    if suffix {
        kwargs[ 'suffix' ] = f"'.'{suffix}";
    }
    (fd, filepath) = tempfile.mkstemp(_=kwargs);

        try
        {
        with os.fdopen(fd, 'w') as f  {
            f.write(input_data);
        }
        }
        except Exception { os.close(fd); raise ; }
    return filepath;
}


"""\n    Fetches the preferred editor from the environment variables.\n\n    This function checks the following environment variables in order to\n    determine the user's preferred editor:\n\n     - VISUAL\n     - EDITOR\n\n    :param default: The default editor to return if no environment variable is set.\n    :type default: str or None\n    :return: The preferred editor as specified by environment variables or the default value.\n    :rtype: str or None\n    """
def get_environment_editor(default: Any = None) {
    editor = os.environ.get('VISUAL', os.environ.get('EDITOR', default));
    return editor;
}


"""\n    Discovers and returns the appropriate editor command.\n\n    Handles cases where the editor command includes arguments, including quoted arguments\n    with spaces (e.g. \'vim -c "set noswapfile"\').\n\n    :return: The editor command as a string\n    :rtype: str\n    """
def discover_editor(editor_override: Any = None) {
    system = platform.system();
    if (system == 'Windows') {
        default_editor = DEFAULT_EDITOR_WINDOWS;
    } elif (system == 'Darwin') {
        default_editor = DEFAULT_EDITOR_OS_X;
    }
        else
        {
        default_editor = DEFAULT_EDITOR_NIX;
        }

    if editor_override {
        editor = editor_override;
    }
        else
        {
        editor = get_environment_editor(default_editor);
        }

    return editor;
}


"""\n    Opens the system editor with optional input data and returns the edited content.\n\n    This function creates a temporary file with the provided input data, opens it in\n    the system editor, waits for the user to make changes and close the editor, then\n    reads and returns the modified content. The temporary file is deleted afterwards.\n\n    :param input_data: Initial content to populate the editor with\n    :type input_data: str\n    :param suffix: Optional file extension for the temporary file (e.g. '.txt', '.md')\n    :type suffix: str or None\n    :return: The edited content after the editor is closed\n    :rtype: str\n    """
def pipe_editor(input_data: Any = '', suffix: Any = None, editor: Any = None) {
    filepath = write_temp_file(input_data, suffix);
    command_str = discover_editor(editor);
    command_str += (' ' + filepath);
    subprocess.call(command_str, shell=True);
    with open(filepath, 'r') as f  {
        output_data = f.read();
    }
    try {
        os.remove(filepath);
    } except PermissionError {
        print_status_message(
            False,
            f"'WARNING: Unable to delete temporary file '{filepath}'. You may need to delete it manually.'"
        );
    }
    return output_data;
}