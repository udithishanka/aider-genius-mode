def fibonacci(n):
    """Return the Fibonacci sequence up to the n-th term."""
    sequence = []
    a, b = 0, 1
    for _ in range(n):
        sequence.append(a)
        a, b = b, a + b
    return sequence

def main():
    n = int(input("Enter the number of terms in the Fibonacci sequence: "))
    print(f"The Fibonacci sequence up to {n} terms is: {fibonacci(n)}")

if __name__ == "__main__":
    main()
