#!/usr/bin/env python3
"""
Demonstration of the enhanced Genius Agent functionality.

This script shows how the new GeniusAgent works with different types of tasks
and demonstrates the multi-phase AI agent architecture.
"""

import sys
from pathlib import Path

# Add the current directory to the path so we can import aider modules
sys.path.insert(0, str(Path(__file__).parent))

from aider.genius_mode import GeniusAgent
from aider.io import InputOutput
from aider.models import Model


class MockCoder:
    """Mock coder for demonstration purposes"""
    
    def __init__(self):
        self.io = InputOutput(pretty=True, yes=True)
        self.main_model = Model("gpt-4")
        self.abs_fnames = {"/demo/project/main.py", "/demo/project/utils.py"}
        self.abs_read_only_fnames = {"/demo/project/README.md"}
        self.auto_lint = True
        self.auto_test = True
        self.auto_commits = True
        self.test_cmd = "python -m pytest"
        self.repo_map = True
        self.repo = MockRepo()
        self.commands = MockCommands()
        self.linter = MockLinter()
        self.lint_outcome = True
        self.test_outcome = True
        
    def get_repo_map(self, force_refresh=False):
        return """
Repository Map:
├── main.py - Main application entry point
├── utils.py - Utility functions
├── tests/
│   ├── test_main.py - Tests for main.py
│   └── test_utils.py - Tests for utils.py
└── README.md - Project documentation
"""
    
    def run(self, with_message=None):
        """Mock the coder run method"""
        self.io.tool_output(f"🔧 Executing: {with_message}")
        self.io.tool_output("✅ Code generation completed")


class MockRepo:
    """Mock repository for demonstration"""
    
    def get_dirty_files(self):
        return ["main.py"]
    
    def is_dirty(self):
        return True


class MockCommands:
    """Mock commands for demonstration"""
    
    def cmd_lint(self, fnames=None):
        print("🔍 Running linter...")
        return None
    
    def cmd_test(self, test_cmd):
        print(f"🧪 Running tests: {test_cmd}")
        return None  # None means success
    
    def cmd_commit(self, message):
        print(f"📝 Committing: {message}")


class MockLinter:
    """Mock linter for demonstration"""
    
    def lint(self, fname):
        return None  # No lint issues


def demo_basic_usage():
    """Demonstrate basic Genius Agent usage"""
    print("=" * 60)
    print("🤖 Genius Agent Demo - Basic Usage")
    print("=" * 60)
    
    # Create a mock coder
    coder = MockCoder()
    
    # Create a Genius Agent with a simple task
    agent = GeniusAgent(
        coder=coder,
        task="Add proper error handling to the main application",
        max_iterations=3,
        enable_web_search=False,  # Disabled for demo
        enable_security_scan=True
    )
    
    # Run the agent
    success = agent.run()
    
    print(f"\n🎯 Agent execution {'succeeded' if success else 'failed'}")
    return success


def demo_advanced_features():
    """Demonstrate advanced Genius Agent features"""
    print("\n" + "=" * 60)
    print("🚀 Genius Agent Demo - Advanced Features")
    print("=" * 60)
    
    # Create a mock coder
    coder = MockCoder()
    
    # Create a more sophisticated agent
    agent = GeniusAgent(
        coder=coder,
        task="Implement a new user authentication system with comprehensive testing",
        max_iterations=5,
        enable_web_search=True,
        enable_security_scan=True
    )
    
    # Simulate some existing issues
    agent.context_memory = {
        "previous_errors": ["Authentication test failed", "SQL injection vulnerability"]
    }
    
    # Run the agent
    success = agent.run()
    
    print(f"\n🎯 Advanced agent execution {'succeeded' if success else 'failed'}")
    return success


def demo_task_graph():
    """Demonstrate the task graph creation"""
    print("\n" + "=" * 60)
    print("📋 Genius Agent Demo - Task Graph Creation")
    print("=" * 60)
    
    coder = MockCoder()
    agent = GeniusAgent(
        coder=coder,
        task="Refactor codebase for better maintainability",
        max_iterations=3
    )
    
    # Manually trigger planning phase to show task graph
    agent.planning_phase()
    
    print("\n📋 Generated Task Graph:")
    for i, task in enumerate(agent.task_graph, 1):
        priority_indicator = "🔴" if task["priority"] == 1 else "🟡" if task["priority"] == 2 else "🟢"
        print(f"  {i}. {priority_indicator} {task['name']} (Type: {task['type']})")
    
    return True


def demo_validation_phases():
    """Demonstrate the validation phase"""
    print("\n" + "=" * 60)
    print("✅ Genius Agent Demo - Validation Phases")
    print("=" * 60)
    
    coder = MockCoder()
    agent = GeniusAgent(coder=coder, task="Test validation system")
    
    # Run validation phase directly
    success, results = agent.code_execution_validation_phase()
    
    print(f"\n🎯 Validation {'passed' if success else 'failed'}")
    print("📊 Detailed Results:")
    for check, status in results.items():
        if check.endswith('_passed'):
            check_name = check.replace('_passed', '').title()
            status_icon = "✅" if status else "❌"
            print(f"  {status_icon} {check_name}: {'Passed' if status else 'Failed'}")
    
    return success


def demo_legacy_compatibility():
    """Demonstrate backwards compatibility with the old GeniusMode"""
    print("\n" + "=" * 60)
    print("🔄 Genius Agent Demo - Legacy Compatibility")
    print("=" * 60)
    
    from aider.genius_mode import GeniusMode
    
    coder = MockCoder()
    
    # Use the old interface
    genius_mode = GeniusMode(
        coder=coder,
        task="Legacy task execution",
        max_iterations=2
    )
    
    # This should work exactly like the old version but with new features
    success = genius_mode.run()
    
    print(f"\n🎯 Legacy interface {'succeeded' if success else 'failed'}")
    return success


def main():
    """Run all demonstrations"""
    print("🤖 Genius Agent Demonstration Suite")
    print("=" * 60)
    print("This demo shows the enhanced AI agent capabilities of aider's Genius Mode.")
    print("The agent autonomously plans, codes, validates, and iterates on development tasks.")
    print()
    
    results = []
    
    # Run all demos
    results.append(demo_basic_usage())
    results.append(demo_advanced_features())
    results.append(demo_task_graph())
    results.append(demo_validation_phases())
    results.append(demo_legacy_compatibility())
    
    # Summary
    print("\n" + "=" * 60)
    print("📋 Demo Summary")
    print("=" * 60)
    successful = sum(results)
    total = len(results)
    
    print(f"✅ Successful demos: {successful}/{total}")
    if successful == total:
        print("🎉 All demonstrations completed successfully!")
        print("\nThe Genius Agent is ready for autonomous development tasks!")
    else:
        print("⚠️  Some demonstrations had issues, but the core functionality works.")
    
    print("\n🚀 Key Features Demonstrated:")
    print("  • Multi-phase agent architecture (Planning → Coding → Validation)")
    print("  • Dynamic task graph creation and prioritization")
    print("  • Comprehensive validation (lint, test, security)")
    print("  • Web search integration for additional context")
    print("  • Intelligent feedback loops and error handling")
    print("  • Backwards compatibility with existing GeniusMode")
    
    return 0 if successful == total else 1


if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)
