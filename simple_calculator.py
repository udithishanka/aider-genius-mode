def add(a, b):
    return a + b

def subtract(a, b):
    return a - b

def multiply(a, b):
    return a * b

def divide(a, b):
    if b == 0:
        raise ValueError("Cannot divide by zero.")
    return a / b

def main():
    print("Simple Calculator")
    print("Operations: add, subtract, multiply, divide")
    print("Type 'exit' to quit.")
    while True:
        try:
            user_input = input("Enter operation and two numbers (e.g. add 2 3): ").strip()
            if user_input.lower() == "exit":
                print("Exiting calculator.")
                break
            parts = user_input.split()
            if len(parts) != 3:
                print("Invalid input format. Please enter operation and two numbers.")
                continue
            op, num1_str, num2_str = parts
            try:
                num1 = float(num1_str)
                num2 = float(num2_str)
            except ValueError:
                print("Invalid numbers. Please enter valid numeric values.")
                continue

            if op == "add":
                result = add(num1, num2)
            elif op == "subtract":
                result = subtract(num1, num2)
            elif op == "multiply":
                result = multiply(num1, num2)
            elif op == "divide":
                try:
                    result = divide(num1, num2)
                except ValueError as e:
                    print(e)
                    continue
            else:
                print(f"Unknown operation '{op}'. Supported operations: add, subtract, multiply, divide.")
                continue

            print(f"Result: {result}")
        except KeyboardInterrupt:
            print("\nExiting calculator.")
            break

if __name__ == "__main__":
    main()
