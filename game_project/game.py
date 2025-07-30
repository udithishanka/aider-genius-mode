def main():
    print("Welcome to the game!")
    game_over = False

    while not game_over:
        user_input = input("Enter command (type 'quit' to exit): ").strip().lower()

        if user_input == "quit":
            print("Thanks for playing!")
            game_over = True
        else:
            # Placeholder for game state update and rendering
            print(f"You entered: {user_input}")
            # Here you would update game state and render output

if __name__ == "__main__":
    main()
