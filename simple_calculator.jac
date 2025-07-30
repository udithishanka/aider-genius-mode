# Basic calculator supporting addition, subtraction, multiplication, division
# with input validation and division by zero handling.

def add(a: float, b: float) -> float {
    return a + b;
}

def subtract(a: float, b: float) -> float {
    return a - b;
}

def multiply(a: float, b: float) -> float {
    return a * b;
}

def divide(a: float, b: float) -> float {
    if b == 0.0 {
        raise ValueError("Division by zero is not allowed");
    }
    return a / b;
}

with entry {
    print("Simple Calculator");
    print("Enter two numbers and an operation (+, -, *, /)");

    # Read first number
    print("Enter first number:");
    input1 = input();
    if not input1.isdigit() and not (input1.replace('.', '', 1).isdigit() and input1.count('.') < 2) {
        print("Invalid input: first number is not numeric");
        return;
    }
    num1 = float(input1);

    # Read second number
    print("Enter second number:");
    input2 = input();
    if not input2.isdigit() and not (input2.replace('.', '', 1).isdigit() and input2.count('.') < 2) {
        print("Invalid input: second number is not numeric");
        return;
    }
    num2 = float(input2);

    # Read operation
    print("Enter operation (+, -, *, /):");
    op = input();

    result: float;
    try {
        if op == "+" {
            result = add(num1, num2);
        } elif op == "-" {
            result = subtract(num1, num2);
        } elif op == "*" {
            result = multiply(num1, num2);
        } elif op == "/" {
            result = divide(num1, num2);
        } else {
            print("Invalid operation");
            return;
        }
        print(f"Result: {result}");
    } except ValueError as e {
        print(f"Error: {e}");
    }
}
