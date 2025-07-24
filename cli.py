import argparse

def greet(name):
    return f"Hello, {name}!"

def main():
    parser = argparse.ArgumentParser(description="Sample CLI Program")
    parser.add_argument("name", type=str, help="Name of the person to greet")
    
    args = parser.parse_args()
    greeting = greet(args.name)
    print(greeting)

if __name__ == "__main__":
    main()
