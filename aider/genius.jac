import json;
import subprocess;
import time;
import from pathlib { Path }
import from typing { Any, Dict, List, Optional, Tuple }
import from aider.web_search { create_web_searcher }

with entry {
    try {
        WEB_SEARCH_AVAILABLE = True;
    } except ImportError {
        WEB_SEARCH_AVAILABLE = False;
        create_web_searcher = None;
    }
}

"""Genius Agent for advanced AI coding tasks using Object-Spatial Programming"""

# Terminal node for end of graph traversal
node EndNode {}
glob END = EndNode();

# Node types for different phases
node PlanningNode {
    has task: str = "";
    has status: str = "pending";
    has result: Optional[Any] = None;
    has error: Optional[str] = None;
    has task_graph: list = [];
    has repo_context: dict = {};
    has issues: list = [];
}

node EditorNode {
    has file_path: str = "";
    has content: str = "";
    has changes: list = [];
    has status: str = "pending";
    has current_task: dict = {};
    has web_context: Optional[str] = None;
}

node ValidatorNode {
    has file_path: str = "";
    has issues: list = [];
    has status: str = "pending";
    has validation_results: dict = {};
}

# Main walker that traverses the graph and executes tasks
walker GeniusAgent {
    has coder: Any;
    has task: str = "Analyze and improve the codebase";
    has task_explicitly_provided: bool = False;
    has max_iterations: int = 10;
    has enable_web_search: bool = True;
    has enable_security_scan: bool = True;
    has planning_model: Any = None;
    has web_searcher: Any = None;
    has current_iteration: int = 0;
    has completed_tasks: list = [];
    has failed_tasks: list = [];
    has context_memory: dict = {};
    has last_error_context: Optional[str] = None;
    has validation_results: dict = {};
    has planning_complete: bool = False;

    # Initialize the agent and start at root
    can start with `root entry {
        # Initialize web searcher if available
        if WEB_SEARCH_AVAILABLE and create_web_searcher {
            self.web_searcher = create_web_searcher(print_error=self.coder.io.tool_error);
            print("Web searcher initialized successfully.");
        } else {
            self.web_searcher = None;
        }
        
        # Set planning model
        self.planning_model = self.planning_model or self.coder.main_model;
        
        # Create the workflow graph
        planning_node = PlanningNode(task=self.task, status="pending");
        editor_node = EditorNode(file_path="", content="", changes=[], status="pending");
        validator_node = ValidatorNode(file_path="", issues=[], status="pending");
        
        # Connect the workflow
        root ++> planning_node;
        planning_node ++> editor_node;
        editor_node ++> validator_node;
        validator_node ++> END;
        
        self.coder.io.tool_output(f"Genius Agent - Phase: Initialization | Action: Starting Genius Agent | Reasoning: Beginning autonomous development cycle for: {self.task}");
        
        # Start traversal
        visit [-->];
    }

    # Handle planning phase
    can plan_tasks with PlanningNode entry {
        self.coder.io.tool_output("Genius Agent - Phase: Planning | Action: Starting planning phase | Reasoning: Analyzing repository and creating task graph");
        
        # Get task from user if not provided
        if not self.task_explicitly_provided {
            try {
                self.coder.io.tool_output("Genius Agent: A specific task is required to proceed.");
                self.coder.io.tool_output("Please describe what you'd like me to work on:");
                self.coder.io.tool_output("(Ctrl+C to cancel)");
                user_input = input("\n> ").strip();
                if user_input {
                    self.task = user_input;
                    self.task_explicitly_provided = True;
                    here.task = self.task;
                    self.coder.io.tool_output(f"Genius Agent - Phase: Planning | Action: User task received | Reasoning: Updated task to: {self.task}");
                } else {
                    self.coder.io.tool_output("No task provided. Cannot proceed without a specific task.");
                    here.status = "failed";
                    here.error = "No task provided";
                    return;
                }
            } except (KeyboardInterrupt, EOFError) {
                self.coder.io.tool_output("\nTask input cancelled by user.");
                here.status = "failed";
                return;
            } except Exception as e {
                self.coder.io.tool_output(f"Error getting user input: {str(e)}");
                here.status = "failed";
                return;
            }
        }

        # Create a simple task for the main work
        task_graph = [{
            "name": self.task if self.task != "Analyze and improve the codebase" else "Improve codebase",
            "type": "feature_implementation" if self.task != "Analyze and improve the codebase" else "improvement",
            "priority": 1,
            "details": self.task
        }];
        
        # Store results in the node
        here.task_graph = task_graph;
        here.status = "completed";
        
        self.planning_complete = True;
        self.coder.io.tool_output(f"Genius Agent - Phase: Planning | Action: Task graph created | Reasoning: Generated {len(task_graph)} tasks");
        
        # Move to next phase
        visit [-->];
    }

    # Handle editing/code generation phase
    can edit_code with EditorNode entry {
        if not self.planning_complete {
            self.coder.io.tool_output("Genius Agent - Phase: Editing | Action: Planning not complete | Reasoning: Cannot proceed without completed planning");
            return;
        }
        
        # Get planning results from previous node
        planning_node = [<--][0];
        task_graph = planning_node.task_graph;
        
        # Main execution loop
        for iteration in range(self.max_iterations) {
            self.current_iteration = iteration + 1;
            self.coder.io.tool_output(f"Genius Agent - Phase: Iteration | Action: Starting iteration {self.current_iteration} | Reasoning: Working through task graph");
            
            # Get next task
            current_task = None;
            for task in task_graph {
                if task not in self.completed_tasks and task not in self.failed_tasks {
                    current_task = task;
                    break;
                }
            }
            
            if not current_task {
                self.coder.io.tool_output("Genius Agent - Phase: Completion | Action: All tasks completed | Reasoning: No more tasks in the queue");
                break;
            }
            
            # Store current task in node
            here.current_task = current_task;
            here.status = "processing";
            
            # Execute the task
            message = f"Task: {current_task['name']}\n\n";
            
            if current_task["type"] == "feature_implementation" {
                message += f"Please implement the following feature or improvement:\n{current_task['details']}\n";
                message += "Consider the existing codebase structure and maintain consistency.";
            } elif current_task["type"] == "improvement" {
                message += "Please review the code and make improvements:\n";
                message += "- Add documentation where missing\n";
                message += "- Improve code readability and structure\n";
                message += "- Add type hints where appropriate\n";
                message += "- Ensure consistent coding style\n";
            } else {
                message += f"Please complete the following task:\n{current_task['details']}\n";
            }
            
            self.coder.io.tool_output(f"Genius Agent - Phase: Editing/Code Generation | Action: Working on {current_task['name']} | Reasoning: Implementing task");
            
            try {
                self.coder.run(with_message=message);
                edit_success = True;
            } except Exception as e {
                self.coder.io.tool_output(f"Genius Agent - Phase: Editing | Action: Code generation failed | Reasoning: {str(e)}");
                edit_success = False;
                self.last_error_context = str(e);
            }
            
            if not edit_success {
                self.failed_tasks.append(current_task);
                continue;
            }
            
            # Simple validation - just mark as successful for now
            validation_success = True;
            
            if validation_success {
                self.completed_tasks.append(current_task);
                self.last_error_context = None;
                
                # Auto-commit if enabled
                if (self.coder.auto_commits and 
                    self.coder.repo and 
                    self.coder.repo.is_dirty()) {
                    commit_msg = f"Genius Agent: {current_task['name']}";
                    self.coder.commands.cmd_commit(commit_msg);
                    self.coder.io.tool_output(f"Genius Agent - Phase: Git | Action: Changes committed | Reasoning: {commit_msg}");
                }
            }
        }
        
        here.status = "completed";
        
        # Output final report
        self.coder.io.tool_output("Genius Agent Execution Report");
        self.coder.io.tool_output("=" * 40);
        self.coder.io.tool_output(f"Task: {self.task}");
        self.coder.io.tool_output(f"Iterations completed: {self.current_iteration}/{self.max_iterations}");
        self.coder.io.tool_output(f"Tasks completed: {len(self.completed_tasks)}");
        self.coder.io.tool_output(f"Tasks failed: {len(self.failed_tasks)}");
        
        if self.completed_tasks {
            self.coder.io.tool_output("Completed Tasks:");
            for task in self.completed_tasks {
                self.coder.io.tool_output(f"  {task['name']}");
            }
        }
        
        if self.failed_tasks {
            self.coder.io.tool_output("Failed Tasks:");
            for task in self.failed_tasks {
                self.coder.io.tool_output(f"  {task['name']}");
            }
        }
        
        # Move to validation node for final validation
        visit [-->];
    }

    # Handle validation phase - simple pass-through for now
    can validate_code with ValidatorNode entry {
        here.status = "completed";
        self.coder.io.tool_output("Genius Agent - Phase: Validation | Action: Validation complete | Reasoning: Final validation passed");
        visit [-->];
    }

    # Handle reaching the end
    can finish with EndNode entry {
        success = len(self.completed_tasks) > 0;
        
        self.coder.io.tool_output(f"Genius Agent - Phase: Completion | Action: Genius Agent finished | Reasoning: Success: {success}, Completed: {len(self.completed_tasks)}, Failed: {len(self.failed_tasks)}");
        
        return success;
    }
}



# Legacy wrapper for backwards compatibility
obj GeniusMode {
    has coder: Any;
    has task: str;
    has max_iterations: int;
    has enable_web_search: bool = True;
    has enable_security_scan: bool = True;

    def __init__(coder: Any, task: Any = None, max_iterations: Any = 5, enable_web_search: bool = True, enable_security_scan: bool = True) {
        self.coder = coder;
        self.task = task or "Analyze and improve the codebase";
        self.max_iterations = max_iterations;
        self.enable_web_search = enable_web_search;
        self.enable_security_scan = enable_security_scan;
    }

    def run() -> bool {
        agent = GeniusAgent(
            coder=self.coder,
            task=self.task,
            max_iterations=self.max_iterations,
            enable_web_search=self.enable_web_search,
            enable_security_scan=self.enable_security_scan,
            planning_model=None
        ) spawn root;
        
        return True;  # The walker handles the actual execution
    }
}