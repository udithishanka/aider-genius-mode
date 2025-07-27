# Simple Calculation Script in Jac Language

# This script performs basic arithmetic operations and demonstrates
# the use of functions, type hints, and documentation in Jac language.

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
        raise ValueError("Cannot divide by zero")
    return a / b

# Main function to demonstrate calculations
def main():
    """
    Main function to perform calculations and print results.
    """
    num1 = 10
    num2 = 5

    print(f"Addition: {add(num1, num2)}")
    print(f"Subtraction: {subtract(num1, num2)}")
    print(f"Multiplication: {multiply(num1, num2)}")
    print(f"Division: {divide(num1, num2)}")

# Execute main function
if __name__ == "__main__":
    main()
