"""\nOpenRouter model metadata caching and lookup.\n\nThis module keeps a local cached copy of the OpenRouter model list\n(downloaded from ``https://openrouter.ai/api/v1/models``) and exposes a\nhelper class that returns metadata for a given model in a format compatible\nwith litellm’s ``get_model_info``.\n"""
import from __future__ { annotations }

import json;
import time;
import from pathlib { Path }
import from typing { Dict }

import requests;


"""Convert a price string (USD per token) to a float."""
def _cost_per_token(val: (str | None)) -> (float | None) {
    if (val in (None, '', '0')) {
        return 0.0 if (val == '0') else None;
    }
    try {
        return float(val);
    } except Exception {
        return None;
    }
}


class OpenRouterModelManager {
    with entry {
        MODELS_URL = 'https://openrouter.ai/api/v1/models';
        CACHE_TTL = ((60 * 60) * 24);
    }

    def init(self: OpenRouterModelManager) -> None {
        self.cache_dir = ((Path.home() / '.aider') / 'caches');
        self.cache_file = (self.cache_dir / 'openrouter_models.json');
        self.content: (Dict | None) = None;
        self.verify_ssl: bool = True;
        self._cache_loaded = False;
    }

    """Enable/disable SSL verification for API requests."""
    def set_verify_ssl(self: OpenRouterModelManager, verify_ssl: bool) -> None {
        self.verify_ssl = verify_ssl;
    }

    """\n        Return metadata for *model* or an empty ``dict`` when unknown.\n\n        ``model`` should use the aider naming convention, e.g.\n        ``openrouter/nousresearch/deephermes-3-mistral-24b-preview:free``.\n        """
    def get_model_info(self: OpenRouterModelManager, model: str) -> Dict {
        self._ensure_content();

            if
            (not self.content or ('data' not in self.content) )
            {
            return {};
            }
        route = self._strip_prefix(model);
        candidates = {route};
        if (':' in route) {
            candidates.add(route.split(':', 1)[ 0 ]);
        }
        record =
            next(
                ( item for item in self.content[ 'data' ] if (item.get('id') in candidates) ),
                None
            );
        not record
            if
            {
            return {};
            }
        context_len =
            (record.get('top_provider', {}).get('context_length')
            or record.get('context_length')
            or None );
        pricing = record.get('pricing', {});
        return
        {'max_input_tokens' : context_len , 'max_tokens' : context_len , 'max_output_tokens' : context_len , 'input_cost_per_token' : _cost_per_token(pricing.get('prompt')) , 'output_cost_per_token' : _cost_per_token(pricing.get('completion')) , 'litellm_provider' : 'openrouter' };
    }

    def _strip_prefix(self: OpenRouterModelManager, model: str) -> str {
        return model[ len('openrouter/') : ]
        if model.startswith('openrouter/')
        else model;
    }

    def _ensure_content(self: OpenRouterModelManager) -> None {
        self._load_cache();
        if not self.content {
            self._update_cache();
        }
    }

    def _load_cache(self: OpenRouterModelManager) -> None {
        self._cache_loaded
            if
            {
            return;
            }

            try
            {
            self.cache_dir.mkdir(parents=True, exist_ok=True);
            if self.cache_file.exists() {
                cache_age = (time.time() - self.cache_file.stat().st_mtime);
            if (cache_age < self.CACHE_TTL) {
                try {
                    self.content = json.loads(self.cache_file.read_text());
                } except json.JSONDecodeError {
                    self.content = None;
                }
            } }
            }
            OSError
                except
                {
                ;
                }
        self._cache_loaded = True;
    }

    def _update_cache(self: OpenRouterModelManager) -> None {
        response = requests.get(self.MODELS_URL, timeout=10, verify=self.verify_ssl); if (response.status_code == 200) { self.content = response.json(); }
    }
}