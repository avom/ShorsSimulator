unit ShorsSim.Complex;

interface

type
  Complex = record
  private
    FRe: Double;
    FIm: Double;
  public
    constructor Create(Re, Im: Double);

    function Abs: Double;
    function Exp: Complex;
    function Power(P: UInt64): Complex;

    property Re: Double read FRe;
    property Im: Double read FIm;

    class function I: Complex; static;

    class operator Implicit(A: Double): Complex;
    class operator Add(A, B: Complex): Complex;
    class operator Multiply(A, B: Complex): Complex;
    class operator Divide(A, B: Complex): Complex;
  end;

implementation

uses
  System.Math;

{ Complex }

constructor Complex.Create(Re, Im: Double);
begin
  FRe := Re;
  FIm := Im;
end;

class operator Complex.Divide(A, B: Complex): Complex;
begin
  Result.FRe := (A.Re * B.Re + A.Im * B.Im) / (B.Re * B.Re + B.Im * B.Im);
  Result.FIm := (A.Im * B.Re - A.Re * B.Im) / (B.Re * B.Re + B.Im * B.Im);
end;

function Complex.Exp: Complex;
begin
  Result := Complex.Create(Cos(Im), Sin(Im)) * System.Exp(Re);
end;

function Complex.Abs: Double;
begin
  Result := Sqrt(Re * Re + Im * Im);
end;

class function Complex.I: Complex;
begin
  Result := Complex.Create(0, 1);
end;

class operator Complex.Implicit(A: Double): Complex;
begin
  Result := Complex.Create(A, 0);
end;

class operator Complex.Multiply(A, B: Complex): Complex;
begin
  Result.FRe := A.Re * B.Re - A.Im * B.Im;
  Result.FIm := A.Re * B.Im + A.Im * B.Re;
end;

function Complex.Power(P: UInt64): Complex;
var
  A: Complex;
begin
  Result := 1;
  A := Self;
  while P > 0 do
  begin
    if P and 1 = 1 then
      Result := Result * A;
    A := A * A;
    P := P shr 1;
  end;
end;

class operator Complex.Add(A, B: Complex): Complex;
begin
  Result.FRe := A.Re + B.Re;
  Result.FIm := A.Im + B.Im;
end;

end.
