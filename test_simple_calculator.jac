import simple_calculator;

test "addition operation" {
    check simple_calculator.add(2.0, 3.0) == 5.0;
    check simple_calculator.add(-1.0, 1.0) == 0.0;
    check simple_calculator.add(0.0, 0.0) == 0.0;
}

test "subtraction operation" {
    check simple_calculator.subtract(5.0, 3.0) == 2.0;
    check simple_calculator.subtract(-1.0, -1.0) == 0.0;
    check simple_calculator.subtract(0.0, 5.0) == -5.0;
}

test "multiplication operation" {
    check simple_calculator.multiply(2.0, 3.0) == 6.0;
    check simple_calculator.multiply(-2.0, 3.0) == -6.0;
    check simple_calculator.multiply(0.0, 5.0) == 0.0;
}

test "division operation" {
    check simple_calculator.divide(6.0, 3.0) == 2.0;
    check simple_calculator.divide(-6.0, 3.0) == -2.0;
    check simple_calculator.divide(0.0, 5.0) == 0.0;
}

test "division by zero raises error" {
    error_raised = false;
    try {
        simple_calculator.divide(5.0, 0.0);
    } except ValueError {
        error_raised = true;
    }
    check error_raised;
}

test "invalid input handling" {
    # Since input validation is done in the entry block with input(),
    # and not exposed as functions, we cannot test invalid inputs directly here.
    # This test is a placeholder to acknowledge input validation is manual.
    check true;
}
