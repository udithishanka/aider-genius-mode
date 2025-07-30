import random

def init_game():
    """Initialize the game state."""
    number_to_guess = random.randint(1, 100)
    attempts = 0
    max_attempts = 10
    return {
        "number_to_guess": number_to_guess,
        "attempts": attempts,
        "max_attempts": max_attempts,
        "game_over": False,
        "won": False,
    }

def process_guess(game_state, guess):
    """Process the player's guess and update the game state."""
    game_state["attempts"] += 1
    number = game_state["number_to_guess"]

    if guess == number:
        game_state["game_over"] = True
        game_state["won"] = True
        return "Correct! You won!"
    elif guess < number:
        return "Too low!"
    else:
        return "Too high!"

def check_game_over(game_state):
    """Check if the game is over due to max attempts."""
    if game_state["attempts"] >= game_state["max_attempts"]:
        game_state["game_over"] = True
        return True
    return False

def main():
    print("Welcome to the Number Guessing Game!")
    print("I'm thinking of a number between 1 and 100.")
    print(f"You have 10 attempts to guess it.")

    game_state = init_game()

    while not game_state["game_over"]:
        print(f"\nAttempts left: {game_state['max_attempts'] - game_state['attempts']}")
        user_input = input("Enter your guess (or type 'quit' to exit): ").strip().lower()

        if user_input == "quit":
            print("Thanks for playing!")
            break

        if not user_input.isdigit():
            print("Please enter a valid number.")
            continue

        guess = int(user_input)
        if guess < 1 or guess > 100:
            print("Your guess must be between 1 and 100.")
            continue

        feedback = process_guess(game_state, guess)
        print(feedback)

        if game_state["game_over"]:
            if game_state["won"]:
                print(f"You guessed the number in {game_state['attempts']} attempts!")
            else:
                print(f"Game over! The number was {game_state['number_to_guess']}.")
            break

        if check_game_over(game_state):
            if not game_state["won"]:
                print(f"Game over! The number was {game_state['number_to_guess']}.")
            break

if __name__ == "__main__":
    main()
