import jaclang  # ensures .jac import hook is available
from .main import main as jac_main

def main():
    return jac_main()

if __name__ == "__main__":
    raise SystemExit(main())
