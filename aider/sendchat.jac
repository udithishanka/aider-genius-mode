import from aider.dump { dump }
import from aider.utils { format_messages }


"""Check if messages alternate between user and assistant roles.\n    System messages can be interspersed anywhere.\n    Also verifies the last non-system message is from the user.\n    Returns True if valid, False otherwise."""
def sanity_check_messages(messages: Any) {
    last_role = None;
    last_non_system_role = None;
    for msg in messages {
        role = msg.get('role');
        last_role = role;
        last_non_system_role = role;

        if
        (role == 'system')
        {
        continue;
        } if (last_role and (role == last_role) ) { turns = format_messages(messages); raise ValueError(("Messages don't properly alternate user/assistant:\n\n" + turns)) ; } }
    return (last_non_system_role == 'user');
}


"""Ensure messages alternate between 'assistant' and 'user' roles.\n\n    Inserts empty messages of the opposite role when consecutive messages\n    of the same role are found.\n\n    Args:\n        messages: List of message dictionaries with 'role' and 'content' keys.\n\n    Returns:\n        List of messages with alternating roles.\n    """
def ensure_alternating_roles(messages: Any) {
    if not messages {
        return messages;
    }
    fixed_messages = [];
    prev_role = None;
    for msg in messages {
        current_role = msg.get('role');
        fixed_messages.append(msg);
        prev_role = current_role;

        if
        (current_role == prev_role)
        {
        if (current_role == 'user') {
            fixed_messages.append({'role' : 'assistant' , 'content' : '' });
        }
            else
            {
            fixed_messages.append({'role' : 'user' , 'content' : '' });
            }

        } }
    return fixed_messages;
}