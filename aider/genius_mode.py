class GeniusMode:
    """Autonomous loop to plan, edit and validate code."""

    def __init__(self, coder, task=None, max_iterations=5):
        self.coder = coder
        self.task = task
        self.max_iterations = max_iterations

    def log(self, phase, action, reasoning):
        self.coder.io.tool_output(f"Phase: {phase}")
        self.coder.io.tool_output(f"Action: {action}")
        self.coder.io.tool_output(f"Reasoning: {reasoning}")

    def validate(self):
        self.log("Validation", "Run lint and tests", "Ensure code quality")
        if self.coder.auto_lint:
            self.coder.commands.cmd_lint(fnames=list(self.coder.abs_fnames))
        if self.coder.auto_test and self.coder.test_cmd:
            self.coder.commands.cmd_test(self.coder.test_cmd)
        lint_ok = self.coder.lint_outcome is not False
        test_ok = self.coder.test_outcome is not False
        if lint_ok and test_ok:
            self.coder.io.tool_output("Next Step Decision: Completed task successfully")
            return True
        self.coder.io.tool_output("Next Step Decision: Validation failed; retrying")
        return False

    def run(self):
        for _ in range(self.max_iterations):
            self.log("Planning", "Analyze repository", "Gather repo context")
            if self.coder.repo_map:
                repo_map = self.coder.get_repo_map(force_refresh=True)
                if repo_map:
                    self.coder.io.tool_output(repo_map)
            self.log("Editing", "Generate code", "Apply modifications based on planning")
            self.coder.run(with_message=self.task)
            if self.validate():
                return True
        self.coder.io.tool_output("Next Step Decision: Reached iteration limit")
        return False