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
