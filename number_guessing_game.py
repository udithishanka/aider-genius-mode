import random

def main():
    print("Welcome to the Number Guessing Game!")
    while True:
        number = random.randint(1, 100)
        print("I have selected a number between 1 and 100.")
        while True:
            guess_str = input("Enter your guess (or 'q' to quit): ").strip()
            if guess_str.lower() == 'q':
                print("Thanks for playing! Goodbye.")
                return
            try:
                guess = int(guess_str)
            except ValueError:
                print("Invalid input. Please enter a valid integer.")
                continue
            if guess < 1 or guess > 100:
                print("Your guess must be between 1 and 100.")
                continue
            if guess < number:
                print("Too low. Try again.")
            elif guess > number:
                print("Too high. Try again.")
            else:
                print("Correct! You guessed the number.")
                break
        play_again = input("Play again? (y/n): ").strip().lower()
        if play_again != 'y':
            print("Thanks for playing! Goodbye.")
            break

if __name__ == '__main__':
    main()
