import from mtllm.llms { OpenAI };

glob llm = OpenAI(model_name="gpt-4o");

def generate_greeting(name: str) -> str by llm();

sem generate_greeting = """
Generate a friendly greeting for the given name.
""";

test test_greeting {
    try {
        greeting = generate_greeting(name="Bard");
        print(greeting);
        check greeting != "";
    } except Exception as e {
        print(f"Error: {e}");
        check False; // Force test failure
    }
}
