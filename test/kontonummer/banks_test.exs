defmodule Kontonummer.BanksTest do
  use ExUnit.Case, async: true
  alias Kontonummer.Banks

  doctest Kontonummer.Banks

  describe "validate_account_number/2" do
    test "returns true for account numbers with valid length" do
      bank = %{account_min_length: 9, account_max_length: 9}
      assert Banks.validate_account_number(bank, "123456789")
    end

    test "returns false for account numbers shorter than min length" do
      bank = %{account_min_length: 9, account_max_length: 9}
      refute Banks.validate_account_number(bank, "12345678")
    end

    test "returns false for account numbers longer than max length" do
      bank = %{account_min_length: 9, account_max_length: 9}
      refute Banks.validate_account_number(bank, "1234567890")
    end

    test "returns true when min length is nil and length is valid" do
      bank = %{account_min_length: nil, account_max_length: 10}
      assert Banks.validate_account_number(bank, "1234567890")
    end

    test "returns true when max length is nil and length is valid" do
      bank = %{account_min_length: 9, account_max_length: nil}
      assert Banks.validate_account_number(bank, "123456789")
    end

    test "returns true when both min and max length are nil" do
      bank = %{account_min_length: nil, account_max_length: nil}
      assert Banks.validate_account_number(bank, "1234567")
    end

    test "returns true for account numbers at the boundaries" do
      bank = %{account_min_length: 2, account_max_length: 10}
      assert Banks.validate_account_number(bank, "12")
      assert Banks.validate_account_number(bank, "1234567890")
    end

    test "returns false for account numbers just outside the boundaries" do
      bank = %{account_min_length: 2, account_max_length: 10}
      refute Banks.validate_account_number(bank, "1")
      refute Banks.validate_account_number(bank, "12345678901")
    end
  end
end
