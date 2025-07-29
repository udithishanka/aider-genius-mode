# TaskManager object in Jac using Object Spatial Programming paradigm

# Define a Task object with unique id and state
walker Task {
    has id: int
    has description: str
    has completed: bool

    # Initialize task with id and description, default completed to false
    construct(id: int, description: str) {
        self.id = id
        self.description = description
        self.completed = false
    }

    # Mark this task as completed
    action complete() {
        self.completed = true
    }

    # Check if task is completed
    action is_completed() -> bool {
        return self.completed
    }
}

# Define TaskManager object to manage tasks
walker TaskManager {
    has tasks: list

    # Initialize with empty task list
    construct() {
        self.tasks = []
    }

    # Create a new task with unique id and description
    action create_task(description: str) -> Task {
        # Generate unique id based on current number of tasks
        let new_id = len(self.tasks) + 1
        # Create new task object spatially organized
        let new_task = Task(new_id, description)
        # Insert task spatially (simulate spatial organization)
        self.tasks.append(new_task)
        return new_task
    }

    # Mark task as completed by id
    action complete_task(task_id: int) -> bool {
        for task in self.tasks {
            if task.id == task_id {
                task.complete()
                return true
            }
        }
        return false
    }

    # Check task status by id
    action is_task_completed(task_id: int) -> bool {
        for task in self.tasks {
            if task.id == task_id {
                return task.is_completed()
            }
        }
        return false
    }

    # Get task status by id: pending, completed, or overdue
    action get_task_status(task_id: int) -> str {
        for task in self.tasks {
            if task.id == task_id {
                if task.completed {
                    return "completed"
                }
                # For demonstration, no overdue logic implemented, return pending
                return "pending"
            }
        }
        return "not_found"
    }

    # Get all tasks with their statuses
    action list_tasks() -> list {
        return self.tasks
    }
}
