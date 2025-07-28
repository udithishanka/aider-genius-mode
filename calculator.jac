"""Simple calculator in Jac language"""

obj Calculator {
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
            raise ValueError("Cannot divide by zero");
        }
        return a / b;
    }
}

with entry {
    calc = Calculator();

    print("Addition: 5 + 3 =", calc.add(5, 3));
    print("Subtraction: 5 - 3 =", calc.subtract(5, 3));
    print("Multiplication: 5 * 3 =", calc.multiply(5, 3));
    print("Division: 5 / 3 =", calc.divide(5, 3));
}
