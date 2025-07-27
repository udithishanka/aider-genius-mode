# This script performs basic arithmetic operations in Jac language.

# Function to add two numbers
def add(a: int, b: int) -> int:
    """
    Add two integers.

    :param a: First integer
    :param b: Second integer
    :return: Sum of a and b
    """
    return a + b

# Function to subtract two numbers
def subtract(a: int, b: int) -> int:
    """
    Subtract two integers.

    :param a: First integer
    :param b: Second integer
    :return: Difference of a and b
    """
    return a - b

# Function to multiply two numbers
def multiply(a: int, b: int) -> int:
    """
    Multiply two integers.

    :param a: First integer
    :param b: Second integer
    :return: Product of a and b
    """
    return a * b

# Function to divide two numbers
def divide(a: int, b: int) -> float:
    """
    Divide two integers.

    :param a: Dividend
    :param b: Divisor
    :return: Quotient of a and b
    :raises ValueError: If b is zero
    """
    if b == 0:
        raise ValueError("Cannot divide by zero.")
    return a / b

# Example usage
if __name__ == "__main__":
    x = 10
    y = 5
    print(f"Add: {add(x, y)}")
    print(f"Subtract: {subtract(x, y)}")
    print(f"Multiply: {multiply(x, y)}")
    print(f"Divide: {divide(x, y)}")
