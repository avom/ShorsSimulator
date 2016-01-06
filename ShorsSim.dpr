program ShorsSim;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  ShorsSim.Complex in 'ShorsSim.Complex.pas',
  ShorsSim.ShorsAlgorithm in 'ShorsSim.ShorsAlgorithm.pas',
  System.Generics.Collections,
  ShorsSim.Utils in 'ShorsSim.Utils.pas',
  ShorsSim.Rational in 'ShorsSim.Rational.pas';

var
  Algo: TShorsAlgorithm;
  Factors: TPair<UInt64, UInt64>;
begin
  Randomize;
  try
    Algo := TShorsAlgorithm.Create;
    try
      Factors := Algo.Run(5* 11);
      Readln;
    finally
      Algo.Free;
    end;

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
