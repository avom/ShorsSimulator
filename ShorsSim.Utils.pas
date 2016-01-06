unit ShorsSim.Utils;

interface

function Gcd(A, B: UInt64): UInt64;
function PowerModN(A, B, N: UInt64): UInt64;

implementation

function Gcd(A, B: UInt64): UInt64;
var
  T: UInt64;
begin
  while B > 0 do
  begin
    T := A;
    A := B;
    B := T mod B;
  end;
  Result := A;
end;

function PowerModN(A, B, N: UInt64): UInt64;
begin
  if A = 0 then
    Exit(0)
  else if A = 1 then
    Exit(1);

  Result := 1;
  while B > 0 do
  begin
    if B and 1 = 1 then
      Result := (Result * A) mod N;

    A := A * A;
    B := B shr 1;
  end;
end;

end.
