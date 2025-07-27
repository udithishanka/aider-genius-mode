def add(a: float, b: float) -> float:
    """
    Add two numbers.

    :param a: First number
    :param b: Second number
    :return: Sum of a and b
    """
    return a + b

def subtract(a: float, b: float) -> float:
    """
    Subtract two numbers.

    :param a: First number
    :param b: Second number
    :return: Difference of a and b
    """
    return a - b

def multiply(a: float, b: float) -> float:
    """
    Multiply two numbers.

    :param a: First number
    :param b: Second number
    :return: Product of a and b
    """
    return a * b

def divide(a: float, b: float) -> float:
    """
    Divide two numbers.

    :param a: First number
    :param b: Second number
    :return: Quotient of a and b
    :raises ValueError: If b is zero
    """
    if b == 0:
        raise ValueError("Cannot divide by zero.")
    return a / b

def main():
    """
    Main function to demonstrate basic math operations.
    """
    x, y = 10, 5
    print(f"Addition: {x} + {y} = {add(x, y)}")
    print(f"Subtraction: {x} - {y} = {subtract(x, y)}")
    print(f"Multiplication: {x} * {y} = {multiply(x, y)}")
    print(f"Division: {x} / {y} = {divide(x, y)}")

if __name__ == "__main__":
    main()
