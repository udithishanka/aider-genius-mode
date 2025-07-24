import importlib;
import os;
import warnings;

import from aider.dump { dump }


with entry {
    warnings.filterwarnings('ignore', category=UserWarning, module='pydantic');
    AIDER_SITE_URL = 'https://aider.chat';
    AIDER_APP_NAME = 'Aider';
    os.environ[ 'OR_SITE_URL' ] = AIDER_SITE_URL;
    os.environ[ 'OR_APP_NAME' ] = AIDER_APP_NAME;
    os.environ[ 'LITELLM_MODE' ] = 'PRODUCTION';
    VERBOSE = False;
}


class LazyLiteLLM {
    with entry {
        _lazy_module = None;
    }

    def __getattr__(self: LazyLiteLLM, name: Any) {
        if (name == '_lazy_module') {
            return <>super();
        }
        self._load_litellm();
        return getattr(self._lazy_module, name);
    }

    def _load_litellm(self: LazyLiteLLM) {

            if
            (self._lazy_module is not None)
            {
            return;
            }
        if VERBOSE {
            print('Loading litellm...');
        }
        self._lazy_module = importlib.import_module('litellm');
        self._lazy_module.suppress_debug_info = True;
        self._lazy_module.set_verbose = False;
        self._lazy_module.drop_params = True;
        self._lazy_module._logging._disable_debugging();
    }
}


with entry {
    litellm = LazyLiteLLM();
    __all__ = [litellm];
}