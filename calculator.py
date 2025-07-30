import os
import sys

def add(a,b):
    result=a+b
    return result

def subtract(a, b):
    return a - b

def multiply(a,b):
    result = a*b
    return result

def divide(a, b):
    if b == 0:
        raise ValueError("Cannot divide by zero")
    return a / b

def main():
    print("Simple Calculator")
    print("1. Add")
    print("2. Subtract")  
    print("3. Multiply")
    print("4. Divide")
    
    choice = input("Enter choice (1-4): ")
    
    if choice in ['1', '2', '3', '4']:
        try:
            num1 = float(input("Enter first number: "))
            num2 = float(input("Enter second number: "))
            
            if choice == '1':
                result = add(num1, num2)
                print(f"{num1} + {num2} = {result}")
            elif choice == '2':
                result = subtract(num1, num2)
                print(f"{num1} - {num2} = {result}")
            elif choice == '3':
                result = multiply(num1, num2)
                print(f"{num1} * {num2} = {result}")
            elif choice == '4':
                result = divide(num1, num2)
                print(f"{num1} / {num2} = {result}")
                
        except ValueError as e:
            print(f"Error: {e}")
        except Exception as e:
            print(f"An error occurred: {e}")
    else:
        print("Invalid choice")

if __name__ == "__main__":
    main()
