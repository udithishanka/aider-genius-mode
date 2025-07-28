# Simple Jac program demonstrating the use of the 'by' keyword
# The 'by' keyword is used to specify that a function is executed by a model (e.g., an LLM)

import from mtllm.llms { OpenAI };

# Initialize a global LLM model instance
glob llm = OpenAI(model_name="gpt-4o");

# Define a function that uses the 'by' keyword to indicate it is executed by the LLM
def greet(name: str) -> str by llm();

# Provide semantic string instructions for the LLM on how to implement the greet function
sem greet = """
Generate a friendly greeting message for the given name.
Example: For input 'Alice', output 'Hello, Alice! Welcome to Jac programming.'
""";

with entry {
    # Call the AI-powered greet function
    message = greet("Alice");
    print(message);
}
