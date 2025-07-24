import argparse

def greet(name, casual=False):
    if casual:
        return f"Hey, {name}!"
    return f"Hello, {name}!"

def main():
    parser = argparse.ArgumentParser(description="Sample CLI Program")
    parser.add_argument("name", type=str, help="Name of the person to greet")
    parser.add_argument("--casual", action="store_true", help="Use a casual greeting")
    
    args = parser.parse_args()
    greeting = greet(args.name, args.casual)
    print(greeting)

if __name__ == "__main__":
    main()
