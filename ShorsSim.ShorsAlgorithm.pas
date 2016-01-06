unit ShorsSim.ShorsAlgorithm;

interface

uses
  System.Generics.Collections,
  ShorsSim.Complex;

type
  TState = record
    Amplitude: Complex;
    InputRegister: UInt64;
    OutputRegister: UInt64;
  end;

  TShorsAlgorithm = class
  private
    FA: UInt64;
    FN: UInt64;
    FQ: UInt64;
    FM: UInt64;
    FA0: UInt64;
    FStates: TArray<TState>;
    function QuantumFindPeriod: UInt64;
    procedure InitRegisters;
    procedure CalculatePeriods;
    procedure MeasureOutputRegister;
    procedure ApplyQuantumFourierTransform;
    function MeasureInputRegister: UInt64;
    function GetMinR(Register1Measurement: UInt64): UInt64;
    function TryMultiplesAsPeriod(MinR: UInt64): UInt64;
    function PowerOf(N: UInt64): UInt64;
  public
    function Run(N: UInt64): TPair<UInt64, UInt64>;
  end;

implementation

uses
  System.Math,
  ShorsSim.Utils,
  ShorsSim.Rational;

{ TShorsAlgorithm }

procedure TShorsAlgorithm.ApplyQuantumFourierTransform;
var
  i: Integer;
  NewStates: TArray<TState>;
  W: TArray<Complex>;
  Col, Row: Integer;
begin
  SetLength(NewStates, FQ);
  SetLength(W, FQ);
  for i := 0 to FQ - 1 do
  begin
    NewStates[i].Amplitude := 0;
    NewStates[i].InputRegister := FStates[i].InputRegister;
    NewStates[i].OutputRegister := FStates[FA0].OutputRegister;

    W[i] := (2 * Pi * Complex.i / FQ).Exp.Power(i);
  end;

  for Col := 0 to FQ - 1 do
  begin
    for Row := 0 to FQ - 1 do
    begin
      NewStates[Row].Amplitude := NewStates[Row].Amplitude + FStates[Col].Amplitude *
        W[Col * Row mod FQ] / Sqrt(FQ);
    end;
  end;

  FStates := NewStates;
end;

procedure TShorsAlgorithm.CalculatePeriods;
var
  i: Integer;
  P: UInt64;
begin
  P := 1;
  for i := 0 to FQ - 1 do
  begin
    FStates[i].OutputRegister := P;
    P := P * FA mod FN;
  end;
end;

function TShorsAlgorithm.GetMinR(Register1Measurement: UInt64): UInt64;

  function ContinuedFractions(const Rat: TRational): TRational;
  var
    NewDenominator: TRational;
  begin
    if Rat.IsWhole or (Rat.Denominator div (Rat.Numerator mod Rat.Denominator) >= FN) then
      Exit(Rat.Floor);

    NewDenominator := TRational.Create(Rat.Denominator, Rat.Numerator mod Rat.Denominator);
    Result := Rat.Floor + ContinuedFractions(NewDenominator).MultiplicateInverse;
  end;

begin
  Result := ContinuedFractions(TRational.Create(Register1Measurement, FQ)).Denominator;
  // Result := ContinuedFractions(TRational.Create(4915, 8192)).Denominator; // TODO: use measurement
end;

procedure TShorsAlgorithm.InitRegisters;
var
  i: Integer;
begin
  for i := 0 to FQ - 1 do
  begin
    FStates[i].Amplitude := Sqrt(1 / FN);
    FStates[i].InputRegister := i;
    FStates[i].OutputRegister := 0;
  end;
end;

function TShorsAlgorithm.PowerOf(N: UInt64): UInt64;
var
  Root: Double;
  i: UInt64;
begin
  i := 1;
  repeat
    Inc(i);
    Root := Power(N, 1 / i);
    if PowerModN(Round(Root), i, N) = 0 then
      Exit(Round(Root));
  until Root < 2.99;
  Result := N;
end;

function TShorsAlgorithm.MeasureInputRegister: UInt64;
var
  Prob, TotalProb: Double;
begin
  Prob := Random;
  TotalProb := 0;
  Result := 0;
  while Prob > TotalProb do
  begin
    TotalProb := TotalProb + (FStates[Result].Amplitude * FStates[Result].Amplitude).Abs;
    Inc(Result);
  end;
  Dec(Result);
  Writeln('Measured register 1: ', Result);
end;

procedure TShorsAlgorithm.MeasureOutputRegister;
var
  Measurement: UInt64;
  i: Integer;
begin
  // http://www.uwyo.edu/moorhouse/slides/talk2.pdf
  // According to previous article all values can be observed with same probability (step 3).
  // I don't think it's strictly true, but it's close enough anyway (especially for large integers).
  Measurement := FStates[Random(FQ)].OutputRegister;
  // Measurement := 28; // TODO: testing
  FM := 0;
  for i := 0 to FQ - 1 do
  begin
    if FStates[i].OutputRegister = Measurement then
    begin
      Inc(FM);
      if FM = 1 then
        FA0 := i;
    end;
  end;

  for i := 0 to FQ - 1 do
    FStates[i].Amplitude := IfThen(FStates[i].OutputRegister = Measurement, Sqrt(1 / FM));

  Writeln('Measured register 2: ', Measurement);
end;

function TShorsAlgorithm.QuantumFindPeriod: UInt64;
begin
  repeat
    InitRegisters;
    CalculatePeriods;
    MeasureOutputRegister;
    ApplyQuantumFourierTransform;
    Result := TryMultiplesAsPeriod(GetMinR(MeasureInputRegister));
    if Result = 0 then
      Writeln('Period not found, restart quantum subroutine');
  until Result > 0;
end;

function TShorsAlgorithm.Run(N: UInt64): TPair<UInt64, UInt64>;
var
  G: UInt64;
  Period: UInt64;
  Y: UInt64;
  P: UInt64;
begin
  Writeln('Starting Shor');
  if Odd(N) then
  begin
    P := PowerOf(N);
    if P < N then
      Result := TPair<UInt64, UInt64>.Create(P, N div P)
    else
    begin
      FN := N;
      FQ := 1 shl ((Floor(Log2(N)) + 1) shl 1 + 1);
      SetLength(FStates, FQ);

      repeat
        FA := Random(N - 2) + 2;
        Writeln('Random A = ', FA);
        G := Gcd(FA, N);
        if G > 1 then
        begin
          Result.Key := G;
          Result.Value := N div G;
          Break;
        end;

        Period := QuantumFindPeriod;
        if Odd(Period) then
        begin
          Writeln('Found odd period, start over!');
          Continue;
        end;

        Y := PowerModN(FA, Period div 2, N);
        if (Y = 1) or (Y = N - 1) then
        begin
          Writeln('Period not suitable, Y = +-1 (mod N)');
          Continue;
        end;

        Result := TPair<UInt64, UInt64>.Create(Gcd(Y - 1, N), Gcd(Y + 1, N));
        Break;
      until False;
    end
  end
  else
    TPair<UInt64, UInt64>.Create(2, N div 2);

  Writeln('Factors found: ', N, ' = ', Result.Key, ' * ', Result.Value);
end;

function TShorsAlgorithm.TryMultiplesAsPeriod(MinR: UInt64): UInt64;
var
  i: Integer;
begin
  for i := 1 to Ceil(Log2(FN)) do
  begin
    if PowerModN(FA, MinR * i, FN) = 1 then
      Exit(MinR * i);
  end;
  Exit(0);
end;

end.
