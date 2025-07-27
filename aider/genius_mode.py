import json
import subprocess
import time
from typing import Dict, List, Optional, Tuple, Any
from pathlib import Path

class GeniusAgent:
    """
    AI Agent that autonomously plans, codes, validates, and iterates on development tasks.
    
    This implements a sophisticated agent architecture where the AI acts with multiple phases:
    - Planning: Analyzes the codebase and creates a task graph
    - Editing/Code Generation: Generates and edits code based on planning
    - Code Execution/Validation: Runs tests, lints, and security scans
    - Web Search for Updates: Searches for additional context when needed
    - Feedback Loop: Uses validation results to improve next iteration
    """

    def __init__(self, coder, task=None, max_iterations=10, enable_web_search=True, 
                 enable_security_scan=True, planning_model=None):
        self.coder = coder
        self.task = task or "Analyze and improve the codebase"
        self.max_iterations = max_iterations
        self.enable_web_search = enable_web_search
        self.enable_security_scan = enable_security_scan
        self.planning_model = planning_model or coder.main_model
        
        # Agent state
        self.current_iteration = 0
        self.task_graph = []
        self.completed_tasks = []
        self.failed_tasks = []
        self.context_memory = {}
        self.validation_results = {}
        
        # Phase trackers
        self.planning_complete = False
        self.needs_web_search = False
        self.last_error_context = None

    def log_agent_action(self, phase: str, action: str, reasoning: str, details: Optional[Dict] = None):
        """Enhanced logging for agent actions with structured data"""
        self.coder.io.tool_output(f"🤖 Genius Agent - Phase: {phase}")
        self.coder.io.tool_output(f"   Action: {action}")
        self.coder.io.tool_output(f"   Reasoning: {reasoning}")
        if details:
            for key, value in details.items():
                self.coder.io.tool_output(f"   {key}: {value}")
        self.coder.io.tool_output("")  # Add spacing

    def planning_phase(self) -> bool:
        """
        Advanced planning phase that analyzes the repository and creates a dynamic task graph.
        """
        self.log_agent_action(
            "Planning", 
            "Analyzing repository structure and dependencies",
            "Building comprehensive understanding of codebase before making changes"
        )
        
        # Gather repository context
        repo_context = self._gather_repository_context()
        
        # Analyze current issues and opportunities
        issues = self._analyze_current_issues()
        
        # Create dynamic task graph
        self.task_graph = self._create_task_graph(repo_context, issues)
        
        # Store context for future reference
        self.context_memory['repo_analysis'] = repo_context
        self.context_memory['identified_issues'] = issues
        
        self.log_agent_action(
            "Planning",
            "Task graph created",
            f"Generated {len(self.task_graph)} prioritized tasks",
            {"tasks": [task["name"] for task in self.task_graph]}
        )
        
        self.planning_complete = True
        return len(self.task_graph) > 0

    def _gather_repository_context(self) -> Dict[str, Any]:
        """Gather comprehensive repository context"""
        context = {
            "files_in_chat": list(self.coder.abs_fnames),
            "readonly_files": list(self.coder.abs_read_only_fnames),
            "repo_map": None,
            "terminal_output": None,
            "git_status": None
        }
        
        # Get repository map
        if self.coder.repo_map:
            repo_map = self.coder.get_repo_map(force_refresh=True)
            if repo_map:
                context["repo_map"] = repo_map
                
        # Get git status if available
        if self.coder.repo:
            try:
                git_status = self.coder.repo.get_dirty_files()
                context["git_status"] = git_status
            except Exception as e:
                self.log_agent_action("Planning", "Git status failed", str(e))
        
        return context

    def _analyze_current_issues(self) -> List[Dict[str, Any]]:
        """Analyze current issues in the codebase"""
        issues = []
        
        # Check for linting issues
        if self.coder.auto_lint and self.coder.abs_fnames:
            try:
                for fname in list(self.coder.abs_fnames):
                    lint_result = self.coder.linter.lint(fname)
                    if lint_result:
                        issues.append({
                            "type": "lint",
                            "file": fname,
                            "description": "Linting issues found",
                            "details": lint_result,
                            "priority": "medium"
                        })
            except Exception as e:
                self.log_agent_action("Planning", "Lint analysis failed", str(e))
        
        # Check for test failures
        if self.coder.test_cmd:
            try:
                test_result = self.coder.commands.cmd_test(self.coder.test_cmd)
                if test_result:  # cmd_test returns output on failure
                    issues.append({
                        "type": "test",
                        "description": "Test failures detected",
                        "details": test_result,
                        "priority": "high"
                    })
            except Exception as e:
                self.log_agent_action("Planning", "Test analysis failed", str(e))
        
        return issues

    def _create_task_graph(self, repo_context: Dict, issues: List[Dict]) -> List[Dict[str, Any]]:
        """Create a dynamic task graph based on analysis"""
        tasks = []
        
        # Add tasks based on discovered issues
        for issue in issues:
            if issue["type"] == "lint":
                tasks.append({
                    "name": f"Fix linting issues in {Path(issue['file']).name}",
                    "type": "fix_lint",
                    "priority": 2,
                    "file": issue["file"],
                    "details": issue["details"]
                })
            elif issue["type"] == "test":
                tasks.append({
                    "name": "Fix failing tests",
                    "type": "fix_tests",
                    "priority": 1,
                    "details": issue["details"]
                })
        
        # Add improvement tasks based on the original task
        if self.task and self.task != "Analyze and improve the codebase":
            tasks.append({
                "name": self.task,
                "type": "feature_implementation",
                "priority": 1,
                "details": self.task
            })
        
        # Add code quality improvement tasks
        if repo_context["files_in_chat"]:
            tasks.append({
                "name": "Improve code quality and documentation",
                "type": "improvement",
                "priority": 3,
                "details": "Review and improve code quality, add documentation where needed"
            })
        
        # Sort by priority (lower number = higher priority)
        tasks.sort(key=lambda x: x["priority"])
        
        return tasks

    def editing_code_generation_phase(self, task: Dict[str, Any]) -> bool:
        """
        Enhanced editing phase that generates/edits code based on current task.
        """
        self.log_agent_action(
            "Editing/Code Generation",
            f"Working on: {task['name']}",
            f"Implementing {task['type']} with targeted approach",
            {"task_details": task.get("details", "No additional details")}
        )
        
        # Prepare context-aware message for the task
        message = self._prepare_task_message(task)
        
        # Check if we need additional context via web search
        if self.enable_web_search and self._should_search_web(task):
            web_context = self._perform_web_search(task)
            if web_context:
                message += f"\n\nAdditional context from web search:\n{web_context}"
        
        try:
            # Execute the coding task
            self.coder.run(with_message=message)
            return True
        except Exception as e:
            self.log_agent_action("Editing", "Code generation failed", str(e))
            self.last_error_context = str(e)
            return False

    def _prepare_task_message(self, task: Dict[str, Any]) -> str:
        """Prepare a context-aware message for the current task"""
        base_message = f"Task: {task['name']}\n\n"
        
        if task["type"] == "fix_lint":
            base_message += f"Please fix the following linting issues in {task['file']}:\n"
            base_message += f"```\n{task['details']}\n```\n"
            base_message += "Focus on fixing the specific issues without changing unrelated code."
            
        elif task["type"] == "fix_tests":
            base_message += "Please fix the failing tests:\n"
            base_message += f"```\n{task['details']}\n```\n"
            base_message += "Analyze the test failures and fix the underlying issues."
            
        elif task["type"] == "feature_implementation":
            base_message += f"Please implement the following feature or improvement:\n{task['details']}\n"
            base_message += "Consider the existing codebase structure and maintain consistency."
            
        elif task["type"] == "improvement":
            base_message += "Please review the code and make improvements:\n"
            base_message += "- Add documentation where missing\n"
            base_message += "- Improve code readability and structure\n"
            base_message += "- Add type hints where appropriate\n"
            base_message += "- Ensure consistent coding style\n"
        
        # Add context from previous failures if any
        if self.last_error_context:
            base_message += f"\n\nNote: Previous attempt failed with: {self.last_error_context}\n"
            base_message += "Please address this issue in your implementation."
        
        return base_message

    def _should_search_web(self, task: Dict[str, Any]) -> bool:
        """Determine if web search would be helpful for this task"""
        # Search for feature implementation tasks or when dealing with errors
        return (
            task["type"] == "feature_implementation" or
            self.last_error_context is not None or
            "API" in task.get("details", "") or
            "documentation" in task.get("details", "").lower()
        )

    def _perform_web_search(self, task: Dict[str, Any]) -> Optional[str]:
        """Perform web search for additional context"""
        search_queries = self._generate_search_queries(task)
        
        for query in search_queries[:2]:  # Limit to 2 searches to avoid being too slow
            try:
                # Use a search URL - this is a simplified implementation
                search_url = f"https://www.google.com/search?q={query.replace(' ', '+')}"
                self.log_agent_action(
                    "Web Search",
                    f"Searching for: {query}",
                    "Gathering additional context for informed implementation"
                )
                
                # In a real implementation, you'd use the scraper here
                # For now, we'll just log that we would search
                return f"Would search for: {query}"
                
            except Exception as e:
                self.log_agent_action("Web Search", "Search failed", str(e))
        
        return None

    def _generate_search_queries(self, task: Dict[str, Any]) -> List[str]:
        """Generate relevant search queries for the task"""
        queries = []
        
        if task["type"] == "feature_implementation":
            # Extract key terms from the task
            details = task.get("details", "")
            queries.append(f"how to implement {details} python")
            queries.append(f"{details} best practices")
            
        elif task["type"] == "fix_tests":
            queries.append("python test debugging common issues")
            
        elif self.last_error_context:
            # Search for error solutions
            error_key_terms = self.last_error_context[:100]  # First 100 chars
            queries.append(f"python error {error_key_terms}")
        
        return queries

    def code_execution_validation_phase(self) -> Tuple[bool, Dict[str, Any]]:
        """
        Comprehensive validation phase with testing, linting, and security scanning.
        """
        self.log_agent_action(
            "Code Execution/Validation",
            "Running comprehensive validation suite",
            "Ensuring code quality, functionality, and security"
        )
        
        validation_results = {
            "lint_passed": True,
            "tests_passed": True,
            "security_passed": True,
            "lint_output": None,
            "test_output": None,
            "security_output": None
        }
        
        # Run linting
        if self.coder.auto_lint and self.coder.abs_fnames:
            self.log_agent_action("Validation", "Running linter", "Checking code style and syntax")
            try:
                self.coder.commands.cmd_lint(fnames=list(self.coder.abs_fnames))
                lint_passed = self.coder.lint_outcome is not False
                validation_results["lint_passed"] = lint_passed
                
                if not lint_passed:
                    validation_results["lint_output"] = "Linting issues detected"
                    
            except Exception as e:
                validation_results["lint_passed"] = False
                validation_results["lint_output"] = str(e)
        
        # Run tests
        if self.coder.auto_test and self.coder.test_cmd:
            self.log_agent_action("Validation", "Running tests", "Verifying functionality")
            try:
                test_output = self.coder.commands.cmd_test(self.coder.test_cmd)
                test_passed = test_output is None  # cmd_test returns None on success
                validation_results["tests_passed"] = test_passed
                validation_results["test_output"] = test_output
                
            except Exception as e:
                validation_results["tests_passed"] = False
                validation_results["test_output"] = str(e)
        
        # Security scan (if enabled)
        if self.enable_security_scan:
            security_result = self._run_security_scan()
            validation_results["security_passed"] = security_result["passed"]
            validation_results["security_output"] = security_result["output"]
        
        # Overall success
        overall_success = (
            validation_results["lint_passed"] and
            validation_results["tests_passed"] and
            validation_results["security_passed"]
        )
        
        self.validation_results = validation_results
        
        # Log results
        status = "✅ PASSED" if overall_success else "❌ FAILED"
        self.log_agent_action(
            "Validation",
            f"Validation complete: {status}",
            "All validation checks completed",
            {
                "Lint": "✅" if validation_results["lint_passed"] else "❌",
                "Tests": "✅" if validation_results["tests_passed"] else "❌",
                "Security": "✅" if validation_results["security_passed"] else "❌"
            }
        )
        
        return overall_success, validation_results

    def _run_security_scan(self) -> Dict[str, Any]:
        """Run basic security scanning on the codebase"""
        self.log_agent_action("Security Scan", "Checking for security issues", "Ensuring code security")
        
        security_issues = []
        
        # Basic security checks for Python files
        for fname in self.coder.abs_fnames:
            if fname.endswith('.py'):
                try:
                    # Check if file exists before reading
                    if not Path(fname).exists():
                        continue
                        
                    with open(fname, 'r', encoding='utf-8') as f:
                        content = f.read()
                        
                    # Check for common security issues
                    if 'eval(' in content:
                        security_issues.append(f"{fname}: Use of eval() detected - potential security risk")
                    if 'exec(' in content:
                        security_issues.append(f"{fname}: Use of exec() detected - potential security risk")
                    if 'shell=True' in content:
                        security_issues.append(f"{fname}: shell=True in subprocess - potential security risk")
                    if 'pickle.loads' in content:
                        security_issues.append(f"{fname}: pickle.loads() detected - potential security risk")
                        
                except Exception as e:
                    # Don't fail the entire scan for individual file issues
                    self.log_agent_action("Security Scan", f"Could not scan {fname}", str(e))
                    continue
        
        return {
            "passed": len(security_issues) == 0,
            "output": "\n".join(security_issues) if security_issues else "No security issues detected"
        }

    def generate_report(self) -> str:
        """Generate a comprehensive report of the agent's work"""
        report = [
            "🤖 Genius Agent Execution Report",
            "=" * 40,
            f"Task: {self.task}",
            f"Iterations completed: {self.current_iteration}/{self.max_iterations}",
            f"Tasks completed: {len(self.completed_tasks)}",
            f"Tasks failed: {len(self.failed_tasks)}",
            "",
            "Completed Tasks:",
        ]
        
        for task in self.completed_tasks:
            report.append(f"  ✅ {task['name']}")
            
        if self.failed_tasks:
            report.append("\nFailed Tasks:")
            for task in self.failed_tasks:
                report.append(f"  ❌ {task['name']}")
        
        if self.validation_results:
            report.extend([
                "\nFinal Validation Results:",
                f"  Lint: {'✅' if self.validation_results['lint_passed'] else '❌'}",
                f"  Tests: {'✅' if self.validation_results['tests_passed'] else '❌'}",
                f"  Security: {'✅' if self.validation_results['security_passed'] else '❌'}",
            ])
        
        return "\n".join(report)

    def run(self) -> bool:
        """
        Main execution loop for the Genius Agent.
        Implements the complete agent architecture with feedback loops.
        """
        self.log_agent_action(
            "Initialization",
            "Starting Genius Agent",
            f"Beginning autonomous development cycle for: {self.task}",
            {"max_iterations": self.max_iterations, "web_search": self.enable_web_search}
        )
        
        # Initial planning phase
        if not self.planning_phase():
            self.log_agent_action("Error", "Planning failed", "Could not create task graph")
            return False
        
        # Main execution loop
        for iteration in range(self.max_iterations):
            self.current_iteration = iteration + 1
            
            self.log_agent_action(
                "Iteration",
                f"Starting iteration {self.current_iteration}",
                f"Working through task graph: {len(self.task_graph) - len(self.completed_tasks)} tasks remaining"
            )
            
            # Get next task from graph
            current_task = self._get_next_task()
            if not current_task:
                self.log_agent_action("Completion", "All tasks completed", "No more tasks in the queue")
                break
            
            # Execute the editing/code generation phase
            edit_success = self.editing_code_generation_phase(current_task)
            if not edit_success:
                self.failed_tasks.append(current_task)
                continue
            
            # Validate the changes
            validation_success, validation_details = self.code_execution_validation_phase()
            
            if validation_success:
                self.completed_tasks.append(current_task)
                self.last_error_context = None  # Clear error context on success
                
                # Check if we should commit changes
                if self.coder.auto_commits and self.coder.repo and self.coder.repo.is_dirty():
                    commit_msg = f"Genius Agent: {current_task['name']}"
                    self.coder.commands.cmd_commit(commit_msg)
                    self.log_agent_action("Git", "Changes committed", commit_msg)
                
            else:
                # Handle validation failure with feedback
                self._handle_validation_failure(current_task, validation_details)
        
        # Generate final report
        report = self.generate_report()
        self.coder.io.tool_output(report)
        
        # Return success if we completed at least one task and have no critical failures
        success = len(self.completed_tasks) > 0 and (
            not self.validation_results or 
            (self.validation_results["tests_passed"] and self.validation_results["security_passed"])
        )
        
        return success

    def _get_next_task(self) -> Optional[Dict[str, Any]]:
        """Get the next task from the task graph"""
        for task in self.task_graph:
            if task not in self.completed_tasks and task not in self.failed_tasks:
                return task
        return None

    def _handle_validation_failure(self, task: Dict[str, Any], validation_details: Dict[str, Any]):
        """Handle validation failure with intelligent feedback"""
        self.log_agent_action(
            "Feedback Loop",
            "Processing validation failure",
            "Analyzing failure and preparing retry strategy"
        )
        
        # Store error context for next iteration
        error_messages = []
        if validation_details["lint_output"]:
            error_messages.append(f"Lint errors: {validation_details['lint_output']}")
        if validation_details["test_output"]:
            error_messages.append(f"Test failures: {validation_details['test_output']}")
        if validation_details["security_output"]:
            error_messages.append(f"Security issues: {validation_details['security_output']}")
        
        self.last_error_context = " | ".join(error_messages)
        
        # Decide whether to retry or mark as failed
        retry_count = getattr(task, 'retry_count', 0)
        if retry_count < 2:  # Allow up to 2 retries
            task['retry_count'] = retry_count + 1
            self.log_agent_action(
                "Feedback",
                f"Scheduling retry {retry_count + 1}/2",
                "Will retry with error context"
            )
        else:
            self.failed_tasks.append(task)
            self.log_agent_action(
                "Feedback",
                "Task marked as failed",
                "Maximum retries exceeded"
            )


# Backwards compatibility
class GeniusMode(GeniusAgent):
    """Legacy wrapper for backwards compatibility"""
    
    def __init__(self, coder, task=None, max_iterations=5):
        super().__init__(coder, task, max_iterations)