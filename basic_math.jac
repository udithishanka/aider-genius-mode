walker main {
    can any;
    start -> math_ops;

    math_ops {
        # Define sample numbers
        a = 12;
        b = 4;

        # Perform basic arithmetic operations
        add = a + b;
        sub = a - b;
        mul = a * b;
        div = a / b;
        mod = a % b;

        # Print results
        print("Basic Math Operations:");
        print(to_str(a) + " + " + to_str(b) + " = " + to_str(add));
        print(to_str(a) + " - " + to_str(b) + " = " + to_str(sub));
        print(to_str(a) + " * " + to_str(b) + " = " + to_str(mul));
        print(to_str(a) + " / " + to_str(b) + " = " + to_str(div));
        print(to_str(a) + " % " + to_str(b) + " = " + to_str(mod));

        halt;
    }
}

spawn main;
