# Kontonummer
The reason behind this lib is that Swedish bank account numbers (kontonummer) have
varied formats depending on the bank. This library provides functionality to validate
and work with these account numbers based on bank registry data.

It includes a list of Swedish banks with their respective account number formats
and validation rules. Reference material for Swedish bank account number structures
can be found [here](https://www.bankgirot.se/globalassets/dokument/anvandarmanualer/bankernaskontonummeruppbyggnad_anvandarmanual_sv.pdf).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `kontonummer` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:kontonummer, "~> 0.2.0"}
  ]
end
```

## Todo

- Add more banks and their account number formats
- Implement additional validation rules as needed
- Add validation for each bank's specific account number structure, ie send in a bank code along with the account number
- Write comprehensive tests for various account number scenarios
- Improve documentation with usage examples
- Adding support for formatting account numbers according to bank-specific rules
