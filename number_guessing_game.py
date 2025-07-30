import random

def main():
    number = random.randint(1, 100)
    print("Welcome to the Number Guessing Game!")
    print("I'm thinking of a number between 1 and 100.")

    while True:
        guess_str = input("Make a guess: ")
        if not guess_str.isdigit():
            print("Please enter a valid integer.")
            continue

        guess = int(guess_str)
        if guess < 1 or guess > 100:
            print("Your guess must be between 1 and 100.")
            continue

        if guess < number:
            print("Too low.")
        elif guess > number:
            print("Too high.")
        else:
            print(f"Congratulations! You guessed the number {number} correctly!")
            break

if __name__ == "__main__":
    main()
