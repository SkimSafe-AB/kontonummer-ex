defmodule Kontonummer.Validate.Modulus10Test do
  use ExUnit.Case, async: true
  alias Kontonummer.Validate.Modulus10

  doctest Kontonummer.Validate.Modulus10

  describe "valid?/1" do
    test "validates the example from PDF (page 7)" do
      # PDF example: 3 3 1 6 8 1 2 0 5 7 4 9 2
      # Sum should be 50, which is divisible by 10
      digits = [3, 3, 1, 6, 8, 1, 2, 0, 5, 7, 4, 9, 2]
      assert Modulus10.valid?(digits) == true
    end

    test "validates all zeros" do
      # All zeros should be valid (sum = 0, divisible by 10)
      assert Modulus10.valid?([0, 0, 0, 0, 0, 0, 0, 0, 0, 0]) == true
    end

    test "rejects invalid account numbers" do
      # Change last digit to make it invalid
      assert Modulus10.valid?([3, 3, 1, 6, 8, 1, 2, 0, 5, 7, 4, 9, 3]) == false
      assert Modulus10.valid?([1, 2, 3, 4, 5, 6, 7, 8, 9, 0]) == false
      assert Modulus10.valid?([1, 1, 1, 1, 1, 1, 1, 1, 1, 1]) == false
    end

    test "validates various valid numbers" do
      # Generated valid numbers
      assert Modulus10.valid?([0, 0, 0, 0, 0, 0, 0, 0, 0, 0]) == true

      # Generate valid numbers using check_digit
      base1 = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]
      check1 = Modulus10.check_digit(base1)
      valid1 = List.replace_at(base1, -1, check1)
      assert Modulus10.valid?(valid1) == true

      base2 = [9, 8, 7, 6, 5, 4, 3, 2, 1, 0]
      check2 = Modulus10.check_digit(base2)
      valid2 = List.replace_at(base2, -1, check2)
      assert Modulus10.valid?(valid2) == true
    end

    test "handles single digit" do
      assert Modulus10.valid?([0]) == true
      assert Modulus10.valid?([5]) == false
    end

    test "handles two digits" do
      assert Modulus10.valid?([0, 0]) == true
      # 1*2 + 8*1 = 2 + 8 = 10 ✅
      assert Modulus10.valid?([1, 8]) == true
      # 5*2 + 5*1 = 10+5=1+5 = 6 ❌ not divisible by 10
      assert Modulus10.valid?([5, 5]) == false
      # 2*2 + 6*1 = 4 + 6 = 10 ✅
      assert Modulus10.valid?([2, 6]) == true
    end

    test "rejects non-list input" do
      assert Modulus10.valid?("123") == false
      assert Modulus10.valid?(123) == false
      assert Modulus10.valid?(nil) == false
    end

    test "handles empty list" do
      # Empty list sum is 0, divisible by 10
      assert Modulus10.valid?([]) == true
    end

    test "handles longer numbers (Type 2 banks with 10 digits)" do
      # Common for Swedish Type 2 banks
      valid_10_digit = [1, 2, 3, 4, 5, 6, 7, 8, 9, 7]
      assert Modulus10.valid?(valid_10_digit) == true
    end
  end

  describe "checksum/1" do
    test "calculates checksum for PDF example" do
      # PDF example from page 7
      digits = [3, 3, 1, 6, 8, 1, 2, 0, 5, 7, 4, 9, 2]
      # Calculation from PDF:
      # Weights: 1 2 1 2 1 2 1 2 1 2 1 2 1 (right to left)
      # Products: 3 6 1 12 8 2 2 0 5 14 4 18 2
      # Modified: 3 6 1 3 8 2 2 0 5 5 4 9 2
      # Sum: 3+6+1+3+8+2+2+0+5+5+4+9+2 = 50
      assert Modulus10.checksum(digits) == 50
    end

    test "calculates checksum for all zeros" do
      assert Modulus10.checksum([0, 0, 0, 0, 0, 0, 0, 0, 0, 0]) == 0
    end

    test "calculates checksum for simple numbers" do
      # [1, 0]: Reversed = [0, 1]
      # Index 0: 0*1 = 0
      # Index 1: 1*2 = 2
      # Sum = 2 ✅
      assert Modulus10.checksum([1, 0]) == 2

      # [0, 1]: Reversed = [1, 0]
      # Index 0: 1*1 = 1
      # Index 1: 0*2 = 0
      # Sum = 1 ✅
      assert Modulus10.checksum([0, 1]) == 1

      # [1, 1]: Reversed = [1, 1]
      # Index 0: 1*1 = 1
      # Index 1: 1*2 = 2
      # Sum = 3 ✅
      assert Modulus10.checksum([1, 1]) == 3
    end

    test "handles product modification (>9)" do
      # [9, 9]: 9*1 + 9*2 = 9 + 18 = 9 + 9 = 18
      assert Modulus10.checksum([9, 9]) == 18

      # [5, 5]: 5*1 + 5*2 = 5 + 10 = 5 + 1 = 6
      assert Modulus10.checksum([5, 5]) == 6
    end
  end

  describe "check_digit/1" do
    test "calculates check digit for PDF example" do
      # Take the valid number, replace last digit with 0
      digits = [3, 3, 1, 6, 8, 1, 2, 0, 5, 7, 4, 9, 0]
      # Should return 2 (the original check digit)
      assert Modulus10.check_digit(digits) == 2
    end

    test "calculates check digit for all zeros" do
      assert Modulus10.check_digit([0, 0, 0, 0, 0, 0, 0, 0, 0, 0]) == 0
    end

    test "calculates check digit for various numbers" do
      # For [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]
      # Calculate what the last digit should be to make it valid
      check = Modulus10.check_digit([1, 2, 3, 4, 5, 6, 7, 8, 9, 0])

      # Verify by creating the full number and checking it's valid
      full_number = [1, 2, 3, 4, 5, 6, 7, 8, 9, check]
      assert Modulus10.valid?(full_number) == true
    end

    test "round-trip: check_digit + validation" do
      # Take any base number, calculate check digit, verify it's valid
      base_numbers = [
        [1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [9, 8, 7, 6, 5, 4, 3, 2, 1, 0],
        [5, 5, 5, 5, 5, 5, 5, 5, 5, 0]
      ]

      for base <- base_numbers do
        check = Modulus10.check_digit(base)
        # Replace last 0 with calculated check digit
        full = List.replace_at(base, -1, check)
        assert Modulus10.valid?(full) == true
      end
    end
  end
end
