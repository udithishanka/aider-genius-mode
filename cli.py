import argparse
from calculator import add, subtract, multiply, divide

def main():
    parser = argparse.ArgumentParser(description="Basic calculator CLI")
    parser.add_argument("a", type=float, help="First number")
    parser.add_argument("b", type=float, help="Second number")
    parser.add_argument(
        "operation",
        choices=["add", "subtract", "multiply", "divide"],
        help="Operation to perform",
    )

    args = parser.parse_args()

    try:
        if args.operation == "add":
            result = add(args.a, args.b)
        elif args.operation == "subtract":
            result = subtract(args.a, args.b)
        elif args.operation == "multiply":
            result = multiply(args.a, args.b)
        elif args.operation == "divide":
            result = divide(args.a, args.b)
        else:
            parser.error(f"Unsupported operation: {args.operation}")

        print(f"Result: {result}")
    except ValueError as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
