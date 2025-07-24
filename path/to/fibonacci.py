def fibonacci_iterative(n):
    """Return the Fibonacci sequence up to the n-th term using iteration."""
    sequence = []
    a, b = 0, 1
    for _ in range(n):
        sequence.append(a)
        a, b = b, a + b
    return sequence

def fibonacci_recursive(n):
    """Return the n-th Fibonacci number using recursion."""
    if n <= 0:
        return 0
    elif n == 1:
        return 1
    else:
        return fibonacci_recursive(n - 1) + fibonacci_recursive(n - 2)

def main():
    try:
        n = int(input("Enter the number of terms in the Fibonacci sequence: "))
        if n < 0:
            raise ValueError("The number of terms must be a non-negative integer.")
        
        sequence = fibonacci_iterative(n)
        print(f"The Fibonacci sequence up to {n} terms is: {sequence}")
        
        reverse_option = input("Would you like to see the sequence in reverse? (y/n): ").strip().lower()
        if reverse_option == 'y':
            print(f"The Fibonacci sequence in reverse is: {sequence[::-1]}")
        
        nth_term = int(input("Enter the term number to get the Fibonacci number (0-indexed): "))
        if nth_term < 0:
            raise ValueError("The term number must be a non-negative integer.")
        print(f"The {nth_term}-th Fibonacci number is: {fibonacci_recursive(nth_term)}")
    
    except ValueError as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
