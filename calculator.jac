"""Basic calculator functions in Jac."""

def add(x: float, y: float) -> float {
    """Adds two numbers."""
    return x + y;
}

def subtract(x: float, y: float) -> float {
    """Subtracts two numbers."""
    return x - y;
}

def multiply(x: float, y: float) -> float {
    """Multiplies two numbers."""
    return x * y;
}

def divide(x: float, y: float) -> float {
    """Divides two numbers."""
    if y == 0:
        raise ValueError("Cannot divide by zero.");
    return x / y;
}

with entry {
    result_add = add(5.0, 3.0);
    print(f"Addition: 5.0 + 3.0 = {result_add}");

    result_subtract = subtract(5.0, 3.0);
    print(f"Subtraction: 5.0 - 3.0 = {result_subtract}");

    result_multiply = multiply(5.0, 3.0);
    print(f"Multiplication: 5.0 * 3.0 = {result_multiply}");

    try:
        result_divide = divide(5.0, 0.0);
        print(f"Division: 5.0 / 0.0 = {result_divide}");
    except ValueError as e:
        print(f"Error: {e}");
}
