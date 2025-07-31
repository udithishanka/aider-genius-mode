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

    This function runs the entire game session. It repeatedly:
    - Generates a random target number between 1 and 100.
    - Prompts the user to guess the number, providing feedback on each guess.
    - Validates user input to ensure it is an integer within the valid range.
    - Allows the user to quit anytime by entering 'q'.
    - After a correct guess, asks if the user wants to play again.

    The game continues until the user chooses to quit.
    """
    print("Welcome to the Number Guessing Game!")

    # Outer loop to allow multiple rounds of the game
    while True:
        # Generate a random number between 1 and 100 for the current round
        number = random.randint(1, 100)
        print("I have selected a number between 1 and 100.")

        # Inner loop to process guesses for the current number
        while True:
            # Prompt user for a guess or to quit
            guess_str = input("Enter your guess (or 'q' to quit): ").strip()
            if guess_str.lower() == 'q':
                print("Thanks for playing! Goodbye.")
                return

            # Attempt to convert input to an integer
            try:
                guess = int(guess_str)
            except ValueError:
                print("Invalid input. Please enter a valid integer.")
                continue

            # Check if guess is within the valid range
            if guess < 1 or guess > 100:
                print("Your guess must be between 1 and 100.")
                continue

            # Compare guess to the target number and provide feedback
            if guess < number:
                print("Too low. Try again.")
            elif guess > number:
                print("Too high. Try again.")
            else:
                print("Correct! You guessed the number.")
                break

        # Ask the user if they want to play another round
        while True:
            play_again = input("Play again? (yes/no): ").strip().lower()
            if play_again in ('yes', 'no'):
                break
            print("Please enter 'yes' or 'no'.")

        # Exit the game if the user does not want to play again
        if play_again != 'yes':
            print("Thanks for playing! Goodbye.")
            break

if __name__ == '__main__':
    main()
