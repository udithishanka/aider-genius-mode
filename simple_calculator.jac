"""Simple Calculator in Jac"""

obj Calculator {
    can add(a: float, b: float) -> float {
        return a + b;
    }

    can subtract(a: float, b: float) -> float {
        return a - b;
    }

    can multiply(a: float, b: float) -> float {
        return a * b;
    }

    can divide(a: float, b: float) -> float {
        if b == 0 {
            raise ValueError("Error: Division by zero is not allowed.");
        }
        return a / b;
    }
}

with entry {
    print("Welcome to the Jac Simple Calculator!");
    print("Enter 'exit' to quit.");

    calc = Calculator();

    while true {
        print("Enter first number:");
        input1 = input();
        if input1 == "exit" {
            print("Exiting calculator. Goodbye!");
            break;
        }
        if not input1.isdigit() and not (input1.startswith("-") and input1[1:].isdigit()) {
            print("Invalid input. Please enter a valid number.");
            continue;
        }
        num1 = float(input1);

        print("Enter operator (+, -, *, /):");
        op = input();
        if op == "exit" {
            print("Exiting calculator. Goodbye!");
            break;
        }
        if op not in ["+", "-", "*", "/"] {
            print("Invalid operator. Please enter one of +, -, *, /.");
            continue;
        }

        print("Enter second number:");
        input2 = input();
        if input2 == "exit" {
            print("Exiting calculator. Goodbye!");
            break;
        }
        if not input2.isdigit() and not (input2.startswith("-") and input2[1:].isdigit()) {
            print("Invalid input. Please enter a valid number.");
            continue;
        }
        num2 = float(input2);

        try {
            result = 0.0;
            if op == "+" {
                result = calc.add(num1, num2);
            } elif op == "-" {
                result = calc.subtract(num1, num2);
            } elif op == "*" {
                result = calc.multiply(num1, num2);
            } elif op == "/" {
                result = calc.divide(num1, num2);
            }
            print(f"Result: {result}");
        } except ValueError as e {
            print(e);
        }
    }
}
