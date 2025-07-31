"""
Number Guessing Game

This script implements a simple number guessing game where the computer randomly selects
a number between 1 and 100, and the user tries to guess it. After each guess, the user
receives feedback indicating whether the guess was too low, too high, or correct.

The user can quit the game anytime by entering 'q'. After guessing correctly, the user
is prompted to play again or exit.

To run the game, execute this script directly:
    python number_guessing_game.py
"""

import random

def main():
    """Main game loop for the number guessing game.

    Repeatedly selects a random number and prompts the user to guess it.
    Provides feedback on each guess and handles input validation.
    Allows the user to quit or play multiple rounds.
    """
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

        while True:
            play_again = input("Play again? (y/n): ").strip().lower()
            if play_again in ('y', 'n'):
                break
            print("Please enter 'y' or 'n'.")

        if play_again != 'y':
            print("Thanks for playing! Goodbye.")
            break

if __name__ == '__main__':
    main()
