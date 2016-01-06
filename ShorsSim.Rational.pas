unit ShorsSim.Rational;

interface

type
  TRational = record
  private
    FNumerator: UInt64;
    FDenominator: UINt64;
  public
    constructor Create(Numerator, Denominator: UInt64);

    function Floor: UInt64;
    function IsWhole: Boolean;
    function MultiplicateInverse: TRational;

    property Numerator: UInt64 read FNumerator;
    property Denominator: UINt64 read FDenominator;

    class operator Implicit(A: UInt64): TRational;
    class operator Add(A, B: TRational): TRational;
  end;

implementation

uses
  ShorsSim.Utils;

{ TRational }

class operator TRational.Add(A, B: TRational): TRational;
var
  G: UInt64;
begin
  Result.FNumerator := A.Numerator * B.Denominator + A.Denominator * B.Numerator;
  Result.FDenominator := A.Denominator * B.Denominator;
  G := Gcd(Result.FNumerator, Result.FDenominator);
  Result.FNumerator := Result.FNumerator div G;
  Result.FDenominator := Result.FDenominator div G;
end;

constructor TRational.Create(Numerator, Denominator: UInt64);
begin
  Assert(Denominator <> 0);
  FNumerator := Numerator;
  FDenominator := Denominator;
end;

function TRational.Floor: UInt64;
begin
  Result := Numerator div Denominator;
end;

class operator TRational.Implicit(A: UInt64): TRational;
begin
  Result := TRational.Create(A, 1);
end;

function TRational.IsWhole: Boolean;
begin
  Result := Numerator mod Denominator = 0;
end;

function TRational.MultiplicateInverse: TRational;
begin
  Assert(Numerator <> 0);
  Result.FNumerator := Denominator;
  Result.FDenominator := Numerator;
end;

end.
