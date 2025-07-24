import from .udiff_coder { UnifiedDiffCoder }
import from .udiff_simple_prompts { UnifiedDiffSimplePrompts }


"""\n    A coder that uses unified diff format for code modifications.\n    This variant uses a simpler prompt that doesn't mention specific\n    diff rules like using `@@ ... @@` lines or avoiding line numbers.\n    """
class UnifiedDiffSimpleCoder(UnifiedDiffCoder) {
    with entry {
        edit_format = 'udiff-simple';
        gpt_prompts = UnifiedDiffSimplePrompts();
    }
}