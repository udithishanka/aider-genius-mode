class Calculator:
    def add(self, a, b):
        return a + b

    def subtract(self, a, b):
        return a - b

    def multiply(self, a, b):
        return a * b

    def divide(self, a, b):
        if b == 0:
            raise ZeroDivisionError("Cannot divide by zero.")
        return a / b


def main():
    calc = Calculator()
    print("Simple Calculator")
    print("Operations: add, subtract, multiply, divide")

    while True:
        try:
            a = float(input("Enter the first number (or 'q' to quit): "))
        except ValueError:
            inp = input("Invalid input. Enter a number or 'q' to quit: ")
            if inp.lower() == 'q':
                print("Exiting calculator.")
                break
            try:
                a = float(inp)
            except ValueError:
                print("Invalid input. Please try again.")
                continue

        try:
            b = float(input("Enter the second number: "))
        except ValueError:
            print("Invalid input. Please enter a valid number.")
            continue

        op = input("Enter operation (add, subtract, multiply, divide): ").strip().lower()

        try:
            if op == "add":
                result = calc.add(a, b)
            elif op == "subtract":
                result = calc.subtract(a, b)
            elif op == "multiply":
                result = calc.multiply(a, b)
            elif op == "divide":
                result = calc.divide(a, b)
            else:
                print("Unknown operation. Please try again.")
                continue
        except ZeroDivisionError as e:
            print(f"Error: {e}")
            continue

        print(f"Result: {result}\n")


if __name__ == "__main__":
    main()
