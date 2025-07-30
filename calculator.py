class Calculator:
    """Basic calculator with addition, subtraction, multiplication, and division."""

    def add(self, a, b):
        """Return the sum of a and b."""
        return a + b

    def subtract(self, a, b):
        """Return the difference of a and b."""
        return a - b

    def multiply(self, a, b):
        """Return the product of a and b."""
        return a * b

    def divide(self, a, b):
        """Return the division of a by b. Raises ValueError on division by zero."""
        if b == 0:
            raise ValueError("Cannot divide by zero.")
        return a / b


def main():
    calc = Calculator()
    print("Basic Calculator")
    print("Enter two numbers and an operation (+, -, *, /). Type 'exit' to quit.")

    while True:
        try:
            inp = input("Enter first number (or 'exit'): ").strip()
            if inp.lower() == "exit":
                print("Goodbye!")
                break
            a = float(inp)

            inp = input("Enter second number: ").strip()
            b = float(inp)

            op = input("Enter operation (+, -, *, /): ").strip()
            if op == "+":
                result = calc.add(a, b)
            elif op == "-":
                result = calc.subtract(a, b)
            elif op == "*":
                result = calc.multiply(a, b)
            elif op == "/":
                result = calc.divide(a, b)
            else:
                print("Invalid operation. Please enter one of +, -, *, /.")
                continue

            print(f"Result: {result}")
        except ValueError as e:
            print(f"Error: {e}")
        except Exception:
            print("Invalid input. Please enter numeric values.")


import argparse
import sys

def cli():
    parser = argparse.ArgumentParser(description="Basic calculator CLI")
    parser.add_argument("a", type=float, help="First number")
    parser.add_argument("b", type=float, help="Second number")
    parser.add_argument(
        "operation",
        choices=["add", "subtract", "multiply", "divide"],
        help="Operation to perform",
    )
    args = parser.parse_args()

    calc = Calculator()
    try:
        if args.operation == "add":
            result = calc.add(args.a, args.b)
        elif args.operation == "subtract":
            result = calc.subtract(args.a, args.b)
        elif args.operation == "multiply":
            result = calc.multiply(args.a, args.b)
        elif args.operation == "divide":
            result = calc.divide(args.a, args.b)
        print(f"Result: {result}")
    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) > 1:
        cli()
    else:
        main()
class Calculator:
    """Basic calculator with addition, subtraction, multiplication, and division."""

    def add(self, a, b):
        return a + b

    def subtract(self, a, b):
        return a - b

    def multiply(self, a, b):
        return a * b

    def divide(self, a, b):
        if b == 0:
            raise ValueError("Cannot divide by zero.")
        return a / b


def main():
    calc = Calculator()
    print("Basic Calculator")
    print("Enter 'q' to quit.")
    while True:
        try:
            a = input("Enter first number: ")
            if a.lower() == 'q':
                break
            a = float(a)

            b = input("Enter second number: ")
            if b.lower() == 'q':
                break
            b = float(b)

            op = input("Enter operation (+, -, *, /): ")
            if op.lower() == 'q':
                break

            if op == '+':
                result = calc.add(a, b)
            elif op == '-':
                result = calc.subtract(a, b)
            elif op == '*':
                result = calc.multiply(a, b)
            elif op == '/':
                result = calc.divide(a, b)
            else:
                print("Invalid operation. Please enter one of +, -, *, /.")
                continue

            print(f"Result: {result}")
        except ValueError as e:
            print(f"Error: {e}")
        except Exception:
            print("Invalid input. Please enter numeric values.")


if __name__ == "__main__":
    main()
class Calculator:
    """Basic calculator with addition, subtraction, multiplication, and division."""

    def add(self, a, b):
        return a + b

    def subtract(self, a, b):
        return a - b

    def multiply(self, a, b):
        return a * b

    def divide(self, a, b):
        if b == 0:
            raise ValueError("Cannot divide by zero.")
        return a / b


def main():
    calc = Calculator()
    print("Simple Calculator")
    while True:
        try:
            a = float(input("Enter first number (or 'q' to quit): "))
        except ValueError:
            print("Exiting calculator.")
            break
        try:
            b = float(input("Enter second number: "))
        except ValueError:
            print("Invalid input for second number. Try again.")
            continue

        print("Select operation:")
        print("1. Add")
        print("2. Subtract")
        print("3. Multiply")
        print("4. Divide")

        choice = input("Enter choice (1/2/3/4): ")

        try:
            if choice == '1':
                result = calc.add(a, b)
            elif choice == '2':
                result = calc.subtract(a, b)
            elif choice == '3':
                result = calc.multiply(a, b)
            elif choice == '4':
                result = calc.divide(a, b)
            else:
                print("Invalid choice. Try again.")
                continue
            print(f"Result: {result}")
        except ValueError as e:
            print(f"Error: {e}")

        print()

if __name__ == "__main__":
    main()
