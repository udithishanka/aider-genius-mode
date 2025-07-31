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


def get_number(prompt):
    while True:
        try:
            value = input(prompt)
            num = float(value)
            return num
        except ValueError:
            print("Invalid input. Please enter a valid number.")


def main():
    calc = Calculator()
    print("Basic Calculator")
    print("Operations: +, -, *, /")
    while True:
        a = get_number("Enter first number (or 'q' to quit): ")
        b = get_number("Enter second number: ")
        op = input("Enter operation (+, -, *, /): ").strip()

        try:
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
        except ZeroDivisionError as e:
            print(e)
            continue

        print(f"Result: {result}")

        cont = input("Perform another calculation? (y/n): ").strip().lower()
        if cont != 'y':
            print("Goodbye!")
            break


if __name__ == "__main__":
    main()
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


def get_number(prompt):
    while True:
        try:
            value = input(prompt)
            num = float(value)
            return num
        except ValueError:
            print("Invalid input. Please enter a valid number.")


def main():
    calc = Calculator()
    print("Basic Calculator")
    print("Operations: +, -, *, /")
    while True:
        a = get_number("Enter first number (or 'q' to quit): ")
        b = get_number("Enter second number: ")
        op = input("Enter operation (+, -, *, /): ").strip()

        try:
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
        except ZeroDivisionError as e:
            print(e)
            continue

        print(f"Result: {result}")

        cont = input("Perform another calculation? (y/n): ").strip().lower()
        if cont != 'y':
            print("Goodbye!")
            break


if __name__ == "__main__":
    main()
