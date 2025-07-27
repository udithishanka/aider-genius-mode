def add(a: float, b: float) -> float:
    """Add two numbers."""
    return a + b

def subtract(a: float, b: float) -> float:
    """Subtract the second number from the first."""
    return a - b

def multiply(a: float, b: float) -> float:
    """Multiply two numbers."""
    return a * b

def divide(a: float, b: float) -> float:
    """Divide the first number by the second.

    Raises:
        ValueError: If the second number is zero.
    """
    if b == 0:
        raise ValueError("Cannot divide by zero.")
    return a / b

def main() -> None:
    """Main function to demonstrate basic math operations."""
    x, y = 10, 5
    print(f"Add: {x} + {y} = {add(x, y)}")
    print(f"Subtract: {x} - {y} = {subtract(x, y)}")
    print(f"Multiply: {x} * {y} = {multiply(x, y)}")
    print(f"Divide: {x} / {y} = {divide(x, y)}")

if __name__ == "__main__":
    main()
