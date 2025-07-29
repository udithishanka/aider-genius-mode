def get_number(prompt):
    while True:
        try:
            return float(input(prompt))
        except ValueError:
            print("Invalid input. Please enter a valid number.")

def get_operator():
    while True:
        op = input("Enter an operator (+, -, *, /): ")
        if op in ('+', '-', '*', '/'):
            return op
        else:
            print("Invalid operator. Please enter one of +, -, *, /.")

def calculate(num1, num2, operator):
    try:
        if operator == '+':
            return num1 + num2
        elif operator == '-':
            return num1 - num2
        elif operator == '*':
            return num1 * num2
        elif operator == '/':
            return num1 / num2
    except ZeroDivisionError:
        return None

def main():
    print("Simple Calculator")
    while True:
        num1 = get_number("Enter the first number: ")
        operator = get_operator()
        num2 = get_number("Enter the second number: ")

        result = calculate(num1, num2, operator)
        if result is None:
            print("Error: Division by zero is not allowed.")
        else:
            print(f"{num1} {operator} {num2} = {result}")

        cont = input("Do you want to perform another calculation? (y/n): ").strip().lower()
        if cont != 'y':
            print("Goodbye!")
            break

if __name__ == "__main__":
    main()
