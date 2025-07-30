import random

def get_valid_guess():
    while True:
        try:
            guess = int(input("Enter your guess (1-100): "))
            if 1 <= guess <= 100:
                return guess
            else:
                print("Please enter an integer between 1 and 100.")
        except ValueError:
            print("Invalid input. Please enter an integer.")

def main():
    number = random.randint(1, 100)
    guesses = 0

    while True:
        guess = get_valid_guess()
        guesses += 1

        if guess < number:
            print("Too low.")
        elif guess > number:
            print("Too high.")
        else:
            print(f"Correct! You guessed the number in {guesses} guesses.")
            break

if __name__ == "__main__":
    main()
