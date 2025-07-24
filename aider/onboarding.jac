import base64;
import hashlib;
import http.server;
import os;
import secrets;
import socketserver;
import threading;
import time;
import webbrowser;
import from urllib.parse { parse_qs, urlparse }

import requests;

import from aider { urls }
import from aider.io { InputOutput }


"""\n    Checks if the user is on a free tier for OpenRouter.\n\n    Args:\n        api_key: The OpenRouter API key to check.\n\n    Returns:\n        A boolean indicating if the user is on a free tier (True) or paid tier (False).\n        Returns True if the check fails.\n    """
def check_openrouter_tier(api_key: Any) {
    try {
        response =
            requests.get(
                'https://openrouter.ai/api/v1/auth/key',
                headers={'Authorization' : f"'Bearer '{api_key}" },
                timeout=5
            );
        response.raise_for_status();
        data = response.json();
        return data.get('data', {}).get('is_free_tier', True);
    } except Exception {
        return True;
    }
}


"""\n    Attempts to select a default model based on available API keys.\n    Checks OpenRouter tier status to select appropriate model.\n\n    Returns:\n        The name of the selected model, or None if no suitable default is found.\n    """
def try_to_select_default_model() {
    openrouter_key = os.environ.get('OPENROUTER_API_KEY');
    if openrouter_key {
        is_free_tier = check_openrouter_tier(openrouter_key);
        if is_free_tier {
            return 'openrouter/deepseek/deepseek-r1:free';
        }
            else
            {
            return 'openrouter/anthropic/claude-sonnet-4';
            }

    }
    model_key_pairs =

        [('ANTHROPIC_API_KEY', 'sonnet'),
        ('DEEPSEEK_API_KEY', 'deepseek'),
        ('OPENAI_API_KEY', 'gpt-4o'),
        ('GEMINI_API_KEY', 'gemini/gemini-2.5-pro-exp-03-25'),
        ('VERTEXAI_PROJECT', 'vertex_ai/gemini-2.5-pro-exp-03-25')];
    for (env_key, model_name) in model_key_pairs {
        api_key_value = os.environ.get(env_key);
        if api_key_value {
            return model_name;
        }
    }
    return None;
}


"""\n    Offers OpenRouter OAuth flow to the user if no API keys are found.\n\n    Args:\n        io: The InputOutput object for user interaction.\n        analytics: The Analytics object for tracking events.\n\n    Returns:\n        True if authentication was successful, False otherwise.\n    """
def offer_openrouter_oauth(io: Any, analytics: Any) {
    io.tool_output('OpenRouter provides free and paid access to many LLMs.');
    if io.confirm_ask('Login to OpenRouter or create a free account?', default='y') {
        analytics.event('oauth_flow_initiated', provider='openrouter');
        openrouter_key = start_openrouter_oauth_flow(io, analytics);
        if openrouter_key {
            os.environ[ 'OPENROUTER_API_KEY' ] = openrouter_key;
            analytics.event('oauth_flow_success');
            return True;
        }
        analytics.event('oauth_flow_failure');
        io.tool_error('OpenRouter authentication did not complete successfully.');
    }
    return False;
}


"""\n    Selects a default model based on available API keys if no model is specified.\n    Offers OAuth flow for OpenRouter if no keys are found.\n\n    Args:\n        args: The command line arguments object.\n        io: The InputOutput object for user interaction.\n        analytics: The Analytics object for tracking events.\n\n    Returns:\n        The name of the selected model, or None if no suitable default is found.\n    """
def select_default_model(args: Any, io: Any, analytics: Any) {
    if args.model {
        return args.model;
    }
    model = try_to_select_default_model();
    if model {
        io.tool_warning(f"'Using '{model}' model with API key from environment.'");
        analytics.event('auto_model_selection', model=model);
        return model;
    }
    no_model_msg = 'No LLM model was specified and no API keys were provided.';
    io.tool_warning(no_model_msg);
    offer_openrouter_oauth(io, analytics);
    model = try_to_select_default_model();
    if model {
        return model;
    }
    io.offer_url(urls.models_and_keys, 'Open documentation URL for more info?');
}


def find_available_port(start_port: Any = 8484, end_port: Any = 8584) {
    for port in range(start_port, (end_port + 1)) {

            try
            {
            with socketserver.TCPServer(('localhost', port), None)  {
                return port;
            }
            }
            OSError
                except
                {
                continue;
                }
    }
    return None;
}


def generate_pkce_codes() {
    code_verifier = secrets.token_urlsafe(64);
    hasher = hashlib.sha256();
    hasher.update(code_verifier.encode('utf-8'));
    code_challenge =
        base64.urlsafe_b64encode(hasher.digest()).rstrip(b'=').decode('utf-8');
    return (code_verifier, code_challenge);
}


def exchange_code_for_key(code: Any, code_verifier: Any, io: Any) {
    try {
        response =
            requests.post(
                'https://openrouter.ai/api/v1/auth/keys',
                headers={'Content-Type' : 'application/json' },
                json=
                {'code' : code , 'code_verifier' : code_verifier , 'code_challenge_method' : 'S256' },
                timeout=30
            );
        response.raise_for_status();
        data = response.json();
        api_key = data.get('key');
        return api_key;
    if not api_key {
        io.tool_error("Error: 'key' not found in OpenRouter response.");
        io.tool_error(f"'Response: '{response.text}");
        return None;
    } } except requests.exceptions.Timeout {
        io.tool_error('Error: Request to OpenRouter timed out during code exchange.');
        return None;
    } except requests.exceptions.HTTPError as e {
        io.tool_error(
            f"'Error exchanging code for OpenRouter key: '{e.response.status_code}' '{e.response.reason}"
        );
        io.tool_error(f"'Response: '{e.response.text}");
        return None;
    } except requests.exceptions.RequestException as e {
        io.tool_error(f"'Error exchanging code for OpenRouter key: '{e}");
        return None;
    } except Exception as e {
        io.tool_error(f"'Unexpected error during code exchange: '{e}");
        return None;
    }
}


"""Initiates the OpenRouter OAuth PKCE flow using a local server."""
def start_openrouter_oauth_flow(io: Any, analytics: Any) {
    port = find_available_port();
    if not port {
        io.tool_error('Could not find an available port between 8484 and 8584.');
        io.tool_error(
            'Please ensure a port in this range is free, or configure manually.'
        );
        return None;
    }
    callback_url = f"'http://localhost:'{port}'/callback/aider'";
    auth_code = None;
    server_error = None;
    server_started = threading.Event();
    shutdown_server = threading.Event();
    class OAuthCallbackHandler(http.server.SimpleHTTPRequestHandler) {
        def do_GET(self: OAuthCallbackHandler) {
            nonlocal auth_code , server_error ;
            parsed_path = urlparse(self.path);
            if (parsed_path.path == '/callback/aider') {
                query_params = parse_qs(parsed_path.query);
            if ('code' in query_params) {
                auth_code = query_params[ 'code' ][ 0 ];
                self.send_response(200);
                self.send_header('Content-type', 'text/html');
                self.end_headers();
                self.wfile.write(
                    b'<html><body><h1>Success!</h1><p>Aider has received the authentication code. You can close this browser tab.</p></body></html>'
                );
                shutdown_server.set();
            }
                else
                {
                self.send_response(302);
                self.send_header('Location', urls.website);
                self.end_headers();
                }
             }
                else
                {
                self.send_response(302);
                self.send_header('Location', urls.website);
                self.end_headers();
                self.wfile.write(b'Not Found');
                }

        }

        def log_message(self: OAuthCallbackHandler, format: Any, *args: Any) {
            ;
        }
    }
    def run_server() {
        nonlocal server_error ;
        try {
            with socketserver.TCPServer(('localhost', port), OAuthCallbackHandler) as httpd  {
                io.tool_output(
                    f"'Temporary server listening on '{callback_url}",
                    log_only=True
                );
                server_started.set();
                io.tool_output('Shutting down temporary server.', log_only=True);
            while not shutdown_server.is_set() {
                httpd.handle_request();
                time.sleep(0.1);
            } }
        } except Exception as e {
            server_error = f"'Failed to start or run temporary server: '{e}";
            server_started.set();
            shutdown_server.set();
        }
    }
    server_thread = threading.Thread(target=run_server, daemon=True);
    server_thread.start();
    if not server_started.wait(timeout=5) {
        io.tool_error('Temporary authentication server failed to start in time.');
        shutdown_server.set();
        server_thread.join(timeout=1);
        return None;
    }
    if server_error {
        io.tool_error(server_error);
        shutdown_server.set();
        server_thread.join(timeout=1);
        return None;
    }
    (code_verifier, code_challenge) = generate_pkce_codes();
    auth_url_base = 'https://openrouter.ai/auth';
    auth_params =

        {'callback_url' : callback_url , 'code_challenge' : code_challenge , 'code_challenge_method' : 'S256' };
    auth_url =
        f"{auth_url_base}'?'{'&'.join(( f"{k}'='{v}" for (k, v) in auth_params.items() ))}";
    io.tool_output(
        '\nPlease open this URL in your browser to connect Aider with OpenRouter:'
    );
    io.tool_output();
    print(auth_url);
    MINUTES = 5;
    io.tool_output(
        f"'\nWaiting up to '{MINUTES}' minutes for you to finish in the browser...'"
    );
    io.tool_output('Use Control-C to interrupt.');

        try
        {
        webbrowser.open(auth_url);
        }
        Exception
            except
            {
            ;
            }
    interrupted = False;
    try {
        shutdown_server.wait(timeout=(MINUTES * 60));
    } except KeyboardInterrupt {
        io.tool_warning('\nOAuth flow interrupted.');
        analytics.event(
            'oauth_flow_failed',
            provider='openrouter',
            reason='user_interrupt'
        );
        interrupted = True;
        shutdown_server.set();
    }
    server_thread.join(timeout=1);
    if interrupted {
        return None;
    }
    if server_error {
        io.tool_error(f"'Authentication failed: '{server_error}");
        analytics.event('oauth_flow_failed', provider='openrouter', reason=server_error);
        return None;
    }
    if not auth_code {
        io.tool_error('Authentication with OpenRouter failed.');
        analytics.event('oauth_flow_failed', provider='openrouter');
        return None;
    }
    io.tool_output('Completing authentication...');
    analytics.event('oauth_flow_code_received', provider='openrouter');
    api_key = exchange_code_for_key(auth_code, code_verifier, io);
    if api_key {
        os.environ[ 'OPENROUTER_API_KEY' ] = api_key;
        try {
            config_dir = os.path.expanduser('~/.aider');
            os.makedirs(config_dir, exist_ok=True);
            key_file = os.path.join(config_dir, 'oauth-keys.env');
            with open(key_file, 'a', encoding='utf-8') as f  {
                f.write(f"'OPENROUTER_API_KEY="'{api_key}'"\n'");
            }
            io.tool_warning(
                'Aider will load the OpenRouter key automatically in future sessions.'
            );
            io.tool_output();
            analytics.event('oauth_flow_success', provider='openrouter');
            return api_key;
        } except Exception as e {
            io.tool_error(
                f"'Successfully obtained key, but failed to save it to file: '{e}"
            );
            io.tool_warning(
                'Set OPENROUTER_API_KEY environment variable for this session only.'
            );
            analytics.event(
                'oauth_flow_save_failed',
                provider='openrouter',
                reason=str(e)
            );
            return api_key;
        }
    }
        else
        {
        io.tool_error('Authentication with OpenRouter failed.');
        analytics.event(
            'oauth_flow_failed',
            provider='openrouter',
            reason='code_exchange_failed'
        );
        return None;
        }

}


class DummyAnalytics {
    def event(self: DummyAnalytics, *args: Any, **kwargs: Any) {
        ;
    }
}


"""Main function to test the OpenRouter OAuth flow."""
def main() {
    print('Starting OpenRouter OAuth flow test...');
    io =
        InputOutput(
            pretty=True,
            yes=False,
            input_history_file=None,
            chat_history_file=None,
            tool_output_color='BLUE',
            tool_error_color='RED'
        );
    analytics = DummyAnalytics();
    if ('OPENROUTER_API_KEY' in os.environ) {
        print('Warning: OPENROUTER_API_KEY is already set in environment.');
    }
    api_key = start_openrouter_oauth_flow(io, analytics);
    if api_key {
        print('\nOAuth flow completed successfully!');
        print(f"'Obtained API Key (first 5 chars): '{api_key[ : 5 ]}'...'");
    }
        else
        {
        print('\nOAuth flow failed or was cancelled.');
        }

    print('\nOpenRouter OAuth flow test finished.');
}


with entry {
    if (__name__ == '__main__') {
        main();
    }
}