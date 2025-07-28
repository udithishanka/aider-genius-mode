# Simple Jac program demonstrating 'by' keyword usage

import from mtllm.llms { OpenAI }

glob llm = OpenAI(model_name="gpt-4o");

# Define an AI-powered function using 'by' keyword to delegate to llm
def greet(name: str) -> str by llm();

# Provide semantic string to instruct the AI what to do
sem greet = """\
Generate a greeting message for the given name.
The message should be friendly and concise.
""";

with entry {
    name: str = "World";
    message = greet(name);
    print(message);
}
