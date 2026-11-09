defmodule Kontonummer.Banks do
  @moduledoc """
  Module containing bank registry data for Swedish banks.
  There are two types of bank account number formats in Sweden, where the second have additional validations.

  === Only Type 2 Rules ===
  The comment field corresponds to the comment number in the official bank registry.
  Kommentar/Comment
  1.
  Kontonumret består av 10 siffror. Vägning sker enligt 10-modul på 10 sista siffrorna, enligt
  format för räkningsnummer (exkl clearingnummer).
  Th account number consistof 10 digits. Checksum calculation uses the last ten digits using
  the modulus 10 check, according format for account number (clearing number not included).
  2.
  Räkningsnumret består av 9 siffror. Vägning sker enligt 11-modul på 9 siffror, enligt format för
  räkningsnummer (exkl clearingnummer).
  Checksum consists of 9 digits. Checksum calculation uses the 9 last digits using the modulus
  11 check.

  3.
  Kontonumret består av upp till 10 siffror. Vägning sker som regel enligt 10-modul på de sista
  10 siffrorna, enligt format för räkningsnummer (exkl clearingnummer).
  The account number consists of 10 digits. Checksum calculation uses the last ten digits using
  the modulus 10 check, according format for account number (clearing number not included


  """
  @type range :: %{
          start: integer(),
          finish: integer()
        }

  @type bank :: %{
          optional(:clearing_length) => 4 | 5,
          name: String.t(),
          type: integer(),
          comment: integer(),
          ranges: [range()],
          account_min_length: integer() | nil,
          account_max_length: integer() | nil
        }

  @banks [
    #
    # Type 1 Banks below
    #
    %{
      name: "Svea Bank AB",
      type: 1,
      comment: 2,
      ranges: [%{start: 9_660, finish: 9_669}],
      account_min_length: nil,
      account_max_length: nil
    },
    %{
      name: "Aion Bank SA",
      type: 1,
      comment: 1,
      ranges: [%{start: 9_580, finish: 9_589}],
      account_min_length: nil,
      account_max_length: nil
    },
    %{
      name: "Avanza Bank AB",
      type: 1,
      comment: 2,
      ranges: [%{start: 9_550, finish: 9_569}],
      account_min_length: nil,
      account_max_length: nil
    },
    %{
      name: "BlueStep Finans AB",
      type: 1,
      comment: 1,
      ranges: [%{start: 9_680, finish: 9_689}],
      account_min_length: nil,
      account_max_length: nil
    },
    %{
      name: "BNP Paribas SA",
      type: 1,
      comment: 2,
      ranges: [%{start: 9_470, finish: 9_479}],
      account_min_length: nil,
      account_max_length: nil
    },
    %{
      name: "Citibank",
      type: 1,
      comment: 2,
      ranges: [%{start: 9_040, finish: 9_049}],
      account_min_length: nil,
      account_max_length: nil
    },
    %{
      name: "Danske Bank",
      type: 1,
      comment: 1,
      ranges: [%{start: 1_200, finish: 1_399}, %{start: 2_400, finish: 2_499}],
      account_min_length: nil,
      account_max_length: nil
    },
    %{
      name: "DNB Bank",
      type: 1,
      comment: 2,
      ranges: [%{start: 9_190, finish: 9_199}, %{start: 9_260, finish: 9_269}],
      account_min_length: nil,
      account_max_length: nil
    },
    %{
      name: "Ekobanken",
      type: 1,
      comment: 2,
      ranges: [%{start: 9_700, finish: 9_709}],
      account_min_length: nil,
      account_max_length: nil
    },
    %{
      name: "Erik Penser AB",
      type: 1,
      comment: 2,
      ranges: [%{start: 9_590, finish: 9_599}],
      account_min_length: nil,
      account_max_length: nil
    },
    %{
      name: "ICA Banken AB",
      type: 1,
      comment: 1,
      ranges: [%{start: 9_270, finish: 9_279}],
      account_min_length: nil,
      account_max_length: nil
    },
    %{
      name: "IKANO Bank",
      type: 1,
      comment: 1,
      ranges: [%{start: 9_170, finish: 9_179}],
      account_min_length: nil,
      account_max_length: nil
    },
    %{
      name: "JAK Medlemsbank",
      type: 1,
      comment: 2,
      ranges: [%{start: 9_670, finish: 9_679}],
      account_min_length: nil,
      account_max_length: nil
    },
    %{
      name: "Klarna Bank",
      type: 1,
      comment: 2,
      ranges: [%{start: 9_780, finish: 9_789}],
      account_min_length: nil,
      account_max_length: nil
    },
    %{
      name: "Landshypotek AB",
      type: 1,
      comment: 2,
      ranges: [%{start: 9_390, finish: 9_399}],
      account_min_length: nil,
      account_max_length: nil
    },
    %{
      name: "Lunar Bank A/S",
      type: 1,
      comment: 2,
      ranges: [%{start: 9_710, finish: 9_719}],
      account_min_length: nil,
      account_max_length: nil
    },
    %{
      name: "Lån & Spar Bank Sverige",
      type: 1,
      comment: 1,
      ranges: [%{start: 9_630, finish: 9_639}],
      account_min_length: nil,
      account_max_length: nil
    },
    %{
      name: "Länsförsäkringar Bank",
      type: 1,
      comment: 1,
      ranges: [
        %{start: 3_400, finish: 3_409},
        %{start: 9_060, finish: 9_069}
      ],
      account_min_length: nil,
      account_max_length: nil
    },
    %{
      name: "Länsförsäkringar Bank",
      type: 1,
      comment: 2,
      ranges: [%{start: 9_020, finish: 9_029}],
      account_min_length: nil,
      account_max_length: nil
    },
    %{
      name: "Marginalen Bank",
      type: 1,
      comment: 1,
      ranges: [%{start: 9_230, finish: 9_239}],
      account_min_length: nil,
      account_max_length: nil
    },
    %{
      name: "Multitude Bank plc",
      type: 1,
      comment: 1,
      ranges: [%{start: 9_070, finish: 9_079}],
      account_min_length: nil,
      account_max_length: nil
    },
    %{
      name: "Noba Bank Group AB",
      type: 1,
      comment: 2,
      ranges: [%{start: 9_640, finish: 9_649}],
      account_min_length: nil,
      account_max_length: nil
    },
    %{
      name: "Nordea",
      type: 1,
      comment: 1,
      ranges: [
        %{start: 1_100, finish: 1_199},
        %{start: 1_400, finish: 2_099},
        # Stops before 3300
        %{start: 3_000, finish: 3_299},
        # After 3300
        %{start: 3_301, finish: 3_399},
        # Stops before 3782
        %{start: 3_410, finish: 3_781},
        # After 3782
        %{start: 3_783, finish: 3_999}
      ],
      account_min_length: nil,
      account_max_length: nil
    },
    %{
      name: "Nordea",
      type: 1,
      comment: 2,
      ranges: [%{start: 4_000, finish: 4_999}],
      account_min_length: nil,
      account_max_length: nil
    },
    %{
      name: "Nordnet Bank",
      type: 1,
      comment: 2,
      ranges: [%{start: 9_100, finish: 9_109}],
      account_min_length: nil,
      account_max_length: nil
    },
    %{
      name: "Northmill Bank AB",
      type: 1,
      comment: 2,
      ranges: [%{start: 9_750, finish: 9_759}],
      account_min_length: nil,
      account_max_length: nil
    },
    %{
      name: "Resurs Bank",
      type: 1,
      comment: 1,
      ranges: [%{start: 9_280, finish: 9_289}],
      account_min_length: nil,
      account_max_length: nil
    },
    %{
      name: "Riksgälden",
      type: 1,
      comment: 2,
      ranges: [%{start: 9_880, finish: 9_889}],
      account_min_length: nil,
      account_max_length: nil
    },
    %{
      name: "Santander Consumer Bank AS",
      type: 1,
      comment: 1,
      ranges: [%{start: 9_460, finish: 9_469}],
      account_min_length: nil,
      account_max_length: nil
    },
    %{
      name: "SBAB",
      type: 1,
      comment: 1,
      ranges: [%{start: 9_250, finish: 9_259}],
      account_min_length: nil,
      account_max_length: nil
    },
    %{
      name: "SEB",
      type: 1,
      comment: 1,
      ranges: [
        %{start: 5_000, finish: 5_999},
        %{start: 9_120, finish: 9_124},
        %{start: 9_130, finish: 9_149}
      ],
      account_min_length: nil,
      account_max_length: nil
    },
    %{
      name: "Skandiabanken",
      type: 1,
      comment: 2,
      ranges: [%{start: 9_150, finish: 9_169}],
      account_min_length: nil,
      account_max_length: nil
    },
    %{
      name: "Swedbank",
      type: 1,
      comment: 1,
      ranges: [%{start: 7_000, finish: 7_999}],
      account_min_length: nil,
      account_max_length: nil
    },
    %{
      name: "Ålandsbanken",
      type: 1,
      comment: 2,
      ranges: [%{start: 2_300, finish: 2_399}],
      account_min_length: nil,
      account_max_length: nil
    },
    #
    # Type 2 Banks below
    #
    %{
      name: "Danske Bank",
      type: 2,
      comment: 1,
      ranges: [%{start: 9_180, finish: 9_189}],
      account_min_length: 10,
      account_max_length: 10
    },
    %{
      name: "Handelsbanken",
      type: 2,
      comment: 2,
      ranges: [%{start: 6_000, finish: 6_999}],
      account_min_length: 9,
      account_max_length: 9
    },
    %{
      name: "Nordea/Plusgirot",
      type: 2,
      comment: 3,
      ranges: [%{start: 9_500, finish: 9_549}, %{start: 9_960, finish: 9_969}],
      account_min_length: 2,
      account_max_length: 10
    },
    %{
      name: "Nordea - Personkonto",
      type: 2,
      comment: 1,
      ranges: [%{start: 3_300, finish: 3_300}, %{start: 3_782, finish: 3_782}],
      account_min_length: 10,
      account_max_length: 10
    },
    %{
      name: "Riksgälden",
      type: 2,
      comment: 1,
      ranges: [%{start: 9_890, finish: 9_899}],
      account_min_length: 10,
      account_max_length: 10
    },
    %{
      name: "Sparbanken Syd",
      type: 2,
      comment: 1,
      ranges: [%{start: 9_570, finish: 9_579}],
      account_min_length: 10,
      account_max_length: 10
    },
    %{
      name: "Swedbank",
      type: 2,
      comment: 3,
      ranges: [%{start: 8_000, finish: 8_999}],
      clearing_length: 5,
      account_min_length: 2,
      account_max_length: 10
    },
    %{
      name: "Swedbank",
      type: 2,
      comment: 1,
      ranges: [%{start: 9_300, finish: 9_329}, %{start: 9_330, finish: 9_349}],
      account_min_length: 10,
      account_max_length: 10
    }
  ]

  @spec bank_by_clearing(integer()) :: bank() | nil
  def bank_by_clearing(clearing_number) when is_integer(clearing_number) do
    Enum.find(@banks, &clearing_in_bank?(&1, clearing_number))
  end

  defp clearing_in_bank?(bank, clearing_number) do
    Enum.any?(bank.ranges, fn range ->
      clearing_number >= range.start and clearing_number <= range.finish
    end)
  end

  @spec clearing_valid?(bank(), integer()) :: boolean()
  def clearing_valid?(bank, clearing_number) when is_integer(clearing_number) do
    clearing_in_bank?(bank, clearing_number)
  end

  @spec validate_account_number(bank(), String.t()) :: boolean()
  def validate_account_number(bank, account_number) do
  end

  @doc """
  Returns the list of banks with their registry data.
  """
  @spec banks() :: [bank()]
  def banks do
    @banks
  end
end
