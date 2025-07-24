import re;

import from aider.dump { dump }


with entry {
    REASONING_TAG = ('thinking-content-' + '7bbeb8e1441453ad999a0bbba8a46d4b');
    REASONING_START = '--------------\n► **THINKING**';
    REASONING_END = '------------\n► **ANSWER**';
}


"""\n    Remove reasoning content from text based on tags.\n\n    Args:\n        res (str): The text to process\n        reasoning_tag (str): The tag name to remove\n\n    Returns:\n        str: Text with reasoning content removed\n    """
def remove_reasoning_content(res: Any, reasoning_tag: Any) {
    if not reasoning_tag {
        return res;
    }
    pattern = f"'<'{reasoning_tag}'>.*?</'{reasoning_tag}'>'";
    res = re.sub(pattern, '', res, flags=re.DOTALL).strip();
    closing_tag = f"'</'{reasoning_tag}'>'";
    if (closing_tag in res) {
        parts = res.split(closing_tag, 1);
        res = parts[ 1 ].strip() if (len(parts) > 1) else res;
    }
    return res;
}


"""\n    Replace opening and closing reasoning tags with standard formatting.\n    Ensures exactly one blank line before START and END markers.\n\n    Args:\n        text (str): The text containing the tags\n        tag_name (str): The name of the tag to replace\n\n    Returns:\n        str: Text with reasoning tags replaced with standard format\n    """
def replace_reasoning_tags(text: Any, tag_name: Any) {
    if not text {
        return text;
    }
    text = re.sub(f"'\\s*<'{tag_name}'>\\s*'", f"'\n'{REASONING_START}'\n\n'", text);
    text = re.sub(f"'\\s*</'{tag_name}'>\\s*'", f"'\n\n'{REASONING_END}'\n\n'", text);
    return text;
}


"""\n    Format reasoning content with appropriate tags.\n\n    Args:\n        reasoning_content (str): The content to format\n        tag_name (str): The tag name to use\n\n    Returns:\n        str: Formatted reasoning content with tags\n    """
def format_reasoning_content(reasoning_content: Any, tag_name: Any) {
    if not reasoning_content {
        return '';
    }
    formatted = f"'<'{tag_name}'>\n\n'{reasoning_content}'\n\n</'{tag_name}'>'";
    return formatted;
}
