"""Task Manager module"""

import from web_search { WebSearcher };

obj Task {
    has task_id: int;
    has description: str;
    has completed: bool = false;

    can mark_complete {
        self.completed = true;
    }
}

obj TaskManager {
    has tasks: list = [];

    can add_task(task_id: int, description: str) {
        new_task = Task(task_id=task_id, description=description);
        self.tasks.append(new_task);
    }

    can mark_task_complete(task_id: int) {
        for task in self.tasks {
            if task.task_id == task_id {
                task.mark_complete();
                break;
            }
        }
    }

    can get_tasks() -> list {
        return self.tasks;
    }

    can search_tasks(query: str) -> list {
        searcher = WebSearcher();
        results = searcher.search(query, 5);
        return results;
    }
}

with entry:__main__ {
    tm = TaskManager();

    print("Welcome to Jac Task Manager CLI");
    while true {
        print("\nOptions:");
        print("1. Add Task");
        print("2. Mark Task Complete");
        print("3. List Tasks");
        print("4. Search Tasks");
        print("5. Exit");

        choice = input("Enter choice: ");
        if choice == "1" {
            id_str = input("Enter task ID (integer): ");
            desc = input("Enter task description: ");
            if id_str.isdigit() {
                tm.add_task(int(id_str), desc);
                print("Task added.");
            } else {
                print("Invalid task ID.");
            }
        } elif choice == "2" {
            id_str = input("Enter task ID to mark complete: ");
            if id_str.isdigit() {
                tm.mark_task_complete(int(id_str));
                print("Task marked complete.");
            } else {
                print("Invalid task ID.");
            }
        } elif choice == "3" {
            tasks = tm.get_tasks();
            if len(tasks) == 0 {
                print("No tasks found.");
            } else {
                for t in tasks {
                    status = "Done" if t.completed else "Pending";
                    print(f"ID: {t.task_id}, Desc: {t.description}, Status: {status}");
                }
            }
        } elif choice == "4" {
            query = input("Enter search query: ");
            results = tm.search_tasks(query);
            print("Search results:");
            for r in results {
                print(r);
            }
        } elif choice == "5" {
            print("Exiting Task Manager.");
            break;
        } else {
            print("Invalid choice.");
        }
    }
}
