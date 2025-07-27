#!/usr/bin/env python3
"""
simple_calculator.py

A simple calculator for basic arithmetic operations.
"""

def add(a, b):
    """Return the sum of a and b."""
    return a + b

def subtract(a, b):
    """Return the difference of a and b (a minus b)."""
    return a - b

def multiply(a, b):
    """Return the product of a and b."""
    return a * b

def divide(a, b):
    """Return the quotient of a divided by b. Raises on division by zero."""
    if b == 0:
        raise ValueError("Cannot divide by zero.")
    return a / b

def main():
    print("Simple Calculator")
    try:
        a = float(input("Enter first number: "))
        b = float(input("Enter second number: "))
    except ValueError:
        print("Invalid number entered.")
        return

    print("\nSelect operation:")
    print("  1) Add")
    print("  2) Subtract")
    print("  3) Multiply")
    print("  4) Divide")
    choice = input("Enter choice (1/2/3/4): ").strip()

    try:
        if choice == '1':
            result = add(a, b)
        elif choice == '2':
            result = subtract(a, b)
        elif choice == '3':
            result = multiply(a, b)
        elif choice == '4':
            result = divide(a, b)
        else:
            print("Invalid choice.")
            return
    except ValueError as e:
        print(f"Error: {e}")
        return

    print(f"\nResult: {result}")

if __name__ == "__main__":
    main()
