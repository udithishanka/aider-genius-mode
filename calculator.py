from typing import Union

class JacCalculator:
    """
    A simple calculator to perform basic arithmetic operations.
    """

    def add(self, a: Union[int, float], b: Union[int, float]) -> Union[int, float]:
        """
        Add two numbers.

        :param a: First number
        :param b: Second number
        :return: Sum of a and b
        """
        return a + b

    def subtract(self, a: Union[int, float], b: Union[int, float]) -> Union[int, float]:
        """
        Subtract two numbers.

        :param a: First number
        :param b: Second number
        :return: Difference of a and b
        """
        return a - b

    def multiply(self, a: Union[int, float], b: Union[int, float]) -> Union[int, float]:
        """
        Multiply two numbers.

        :param a: First number
        :param b: Second number
        :return: Product of a and b
        """
        return a * b

    def divide(self, a: Union[int, float], b: Union[int, float]) -> Union[int, float]:
        """
        Divide two numbers.

        :param a: First number
        :param b: Second number
        :return: Quotient of a and b
        :raises ValueError: If b is zero
        """
        if b == 0:
            raise ValueError("Cannot divide by zero.")
        return a / b
