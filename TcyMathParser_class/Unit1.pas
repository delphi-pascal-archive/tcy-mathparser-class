unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons, Math, ComCtrls;

type
  TForm1 = class(TForm)
    Label1: TLabel;
    Image1: TImage;
    Label3: TLabel;
    MemExprs: TMemo;
    Label2: TLabel;
    MemRslts: TMemo;
    MemGraf: TMemo;
    Bevel1: TBevel;
    TrackBar1: TTrackBar;
    Label4: TLabel;
    procedure MemExprsChange(Sender: TObject);
    procedure MemGrafChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Image1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  private
    { Déclarations privées }
    XAxisCoord, YAxisCoord, savX, savY: Integer;
  public
    { Déclarations publiques }
  end;

var
  Form1: TForm1;

implementation

uses cyMathParser;

{$R *.dfm}

procedure TForm1.FormShow(Sender: TObject);
begin
  XAxisCoord := Image1.Height div 2;
  YAxisCoord := Image1.Width div 2;

  MemExprsChange(nil);
  MemGrafChange(nil);
end;

procedure TForm1.Image1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  savX := X;
  savY := Y;
end;

procedure TForm1.Image1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  YAxisCoord := YAxisCoord + (X - savX);
  XAxisCoord := XAxisCoord + (Y - savY);
  MemGrafChange(nil);
end;

procedure TForm1.MemExprsChange(Sender: TObject);
var
 i:integer;
 CurrentLine, CurrentExpression, Variable: String;
 MathParser: TcyMathParser;
begin
 MemRslts.Clear;
 MathParser := TcyMathParser.create;

 for i:=0 to MemExprs.Lines.Count-1 do
 begin
   CurrentLine := MemExprs.Lines[i];

   // si il y a un =, c'est une affectation de valeur à une variable:
   if pos('=', CurrentLine) <> 0
   then begin
     // on coupe en deux autour du =
     Variable := trim(copy(CurrentLine, 1, pos('=', CurrentLine)-1));
     CurrentExpression := copy(CurrentLine, pos('=', CurrentLine)+1,length(CurrentLine));

     // tous les noms ne sont pas valide, ATTENTION!!!!
     if not ValidVariableName(Variable)
     then begin
       MemRslts.Lines.add('Nom de variable invalide');
       Continue;  // Revenir au "for" ...
     end;
    end
   else begin
     // sinon, c'est une simple expression à calculer
     Variable := '';
     CurrentExpression := CurrentLine;
   end;

   MathParser.Expression := CurrentExpression;
   MathParser.Parse;       // On évalue l'expression

   if MathParser.GetLastError = 0
   then begin
     // si c'est une affectation
     if Variable <> ''
     then begin
       // on affiche le résultat et on stock le résultat :
       MemRslts.Lines.Add(Variable + '=' + FloatToStr(MathParser.ParserResult));
       MathParser.Variables.SetValue(Variable, MathParser.ParserResult);
     end
     else
     // sinon, on affiche juste le résultat
       MemRslts.Lines.Add(FloatToStr(MathParser.ParserResult));
   end
   else
     MemRslts.Lines.add(MathParser.GetLastErrorString);
 end;

 MathParser.Free;
end;

procedure TForm1.MemGrafChange(Sender: TObject);
var
  pX, pY, j: integer;
  x, fx: Extended;
  MathParser: TcyMathParser;
begin
  // Effacer l'image :
  image1.Canvas.Rectangle(image1.ClientRect);
  // Tracer les axes :
  image1.canvas.Pen.Color:=clgray;
  image1.Canvas.MoveTo(0, XAxisCoord);
  image1.Canvas.LineTo(Image1.Width, XAxisCoord);
  image1.Canvas.MoveTo(YAxisCoord, 0);
  image1.Canvas.LineTo(YAxisCoord, Image1.Height);

  MathParser := TcyMathParser.create;

  for j := 0 to MemGraf.Lines.Count-1 do
  begin
    MathParser.Expression := MemGraf.lines[j];
    if MathParser.GetLastError <> 0 then continue;

    for pX := 0 to Image1.Width do
    begin
      // Définir la valeur de x :
      x := (pX - YAxisCoord) / TrackBar1.Position;
      MathParser.Variables.SetValue('x', x);
      // Calculer f(x):
      MathParser.Parse;

      if MathParser.GetLastError = 0
      then begin
       fx := MathParser.ParserResult;
       pY := Round( -(-XAxisCoord + fx * TrackBar1.Position) );
       image1.Canvas.Pixels[pX, pY] := clBlue;
      end
      else
        if MathParser.GetLastError < cCalcError  // Erreur dans l' expression
        then begin
          image1.Canvas.TextOut(2, 2 + j * 16, MathParser.GetLastErrorString);
          Break;
        end;
    end;
  end;

  MathParser.Free;

end;

end.
