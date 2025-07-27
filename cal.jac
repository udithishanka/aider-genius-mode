"""Simple calculator in Jac language"""

obj Calculator {
    has result: float = 0.0;

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
        if b == 0 {
            raise ValueError("Cannot divide by zero");
        }
        return a / b;
    }
}

with entry {
    calc = Calculator();

    print("Add 5 + 3 =", calc.add(5, 3));
    print("Subtract 10 - 4 =", calc.subtract(10, 4));
    print("Multiply 6 * 7 =", calc.multiply(6, 7));
    print("Divide 20 / 5 =", calc.divide(20, 5));
}
