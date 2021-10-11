{ The Initial Developer is "Barbichette" and of the Original Code
  can be found here: http://www.delphifr.com//code.aspx?ID=45846

  His work was inspired from an "Oniria" source that can be found here: http://www.delphifr.com/codes/CALCULATRICE-CHAIN%20ES-MATHEMATIQUES_45537.aspx



  The method used to parse is called "reverse Polish notation" :
  http://en.wikipedia.org/wiki/Reverse_Polish_notation

  From Wikipedia:
  "Reverse Polish notation (or RPN) is a mathematical notation wherein every operator follows all of its operands, in contrast to Polish notation,
  which puts the operator in the prefix position. It is also known as Postfix notation and is parenthesis-free as long as operator arities are fixed.
  The description "Polish" refers to the nationality of logician Jan ?ukasiewicz, who invented (prefix) Polish notation in the 1920s."

  Exemple:

  Infix notation |       RPN
  -------------------------------
      2+2*3      |    2 2 3 * +
      2*2+3      |    2 2 x 3 +
}

{   Component(s):
    tcyMathParser

    Description:
    Math parsing component that can evaluate an expression using common operators, some functions and variables

    $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
    $  €€€ Accept any PAYPAL DONATION $$$  €
    $      to: mauricio_box@yahoo.com      €
    €€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€

    * ***** BEGIN LICENSE BLOCK *****
    *
    * Version: MPL 1.1
    *
    * The contents of this file are subject to the Mozilla Public License Version
    * 1.1 (the "License"); you may not use this file except in compliance with the
    * License. You may obtain a copy of the License at http://www.mozilla.org/MPL/
    *
    * Software distributed under the License is distributed on an "AS IS" basis,
    * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
    * the specific language governing rights and limitations under the License.
    *
    * The Initial Developer of the Original Code is Mauricio
    * (https://sourceforge.net/projects/tcycomponents/).
    *
    * No contributors for now ...
    *
    * Alternatively, the contents of this file may be used under the terms of
    * either the GNU General Public License Version 2 or later (the "GPL"), or the
    * GNU Lesser General Public License Version 2.1 or later (the "LGPL"), in which
    * case the provisions of the GPL or the LGPL are applicable instead of those
    * above. If you wish to allow use of your version of this file only under the
    * terms of either the GPL or the LGPL, and not to allow others to use your
    * version of this file under the terms of the MPL, indicate your decision by
    * deleting the provisions above and replace them with the notice and other
    * provisions required by the LGPL or the GPL. If you do not delete the
    * provisions above, a recipient may use your version of this file under the
    * terms of any one of the MPL, the GPL or the LGPL.
    *
    * ***** END LICENSE BLOCK *****}

unit cyMathParser;

interface

uses Math, SysUtils, StrUtils, windows;

const
  cNoError = 0;
  // Internal error:
  cInternalError = 1;
  // Expression errors:
  cErrorInvalidCar = 2;
  cErrorUnknownName = 3;
  cErrorInvalidFloat = 4;
  cErrorOperator = 5;
  cErrorFxNeedLeftParentese = 6;
  cErrorNotEnoughArgs = 7;
  cErrorSeparatorNeedArgument = 8;
  cErrorMissingLeftParenteses = 9;
  cErrorMissingRightParenteses = 10;
  cErrorLeftParentese = 11;
  cErrorRightParentese = 12;
  cErrorSeparator = 13;
  cErrorOperatorNeedArgument = 14;
  // Calc errors:
  cCalcError = 100;    // From here, this is a calculation error ...
  cErrorDivByZero = 101;
  cErrorPower = 102;
  cErrorFxInvalidValue = 103;

type
  TTypeStack = (tsNotDef, tsValue, tsOperator, tsFunction, tsLeftParenthese, tsRightParenthese, tsSeparator, tsVariable);

  // Handled operators and functions:
  TOperationType = (opNone,
           // Operators
           OpPower, OpMultiply, OpDivide, OpAdd, OpSubstract, OpMod, OpNeg,
           // Functions
           OpCos, OpSin, OpTan, OpLog, OpLn, OpASin, OpACos, OpATan, OpExp, OpSqrt, OpSqr, OpLogN,OpInt,OpFrac,OpAbs,
           OpCeil, OpFloor, OpLdexp, OpLnXP1, OpMax, OpMin, OpRoundTo, OpSign, OpSum);

  // Operators and functions information :
  TOperationInfo = record
    Priority: byte;
    Arguments: Integer;
    Name: String;
    OperationType: TOperationType;
  end;

const
  MaxOperationsInfo = 31;

  // Operators and functions rules and specifications :
  OperationsInfo: array[0..MaxOperationsInfo] of TOperationInfo = (
     // None
     (Priority: 0; Arguments: 0; Name: '';        OperationType: opNone)      // opNone
     // Operators
    ,(Priority: 3; Arguments: 2; Name: '^';       OperationType: OpPower)     // OpPower
    ,(Priority: 2; Arguments: 2; Name: '*';       OperationType: OpMultiply)  // OpMultiply
    ,(Priority: 2; Arguments: 2; Name: '/';       OperationType: OpDivide)    // OpDivide
    ,(Priority: 1; Arguments: 2; Name: '+';       OperationType: OpAdd)       // OpAdd
    ,(Priority: 1; Arguments: 2; Name: '-';       OperationType: OpSubstract) // OpSubstract
    ,(Priority: 2; Arguments: 2; Name: 'mod';     OperationType: OpMod)       // OpMod (5 mod 3 = 2)
    ,(Priority: 4; Arguments: 1; Name: 'neg';     OperationType: OpNeg)       // OpNeg (negative value, used for diferenciate with substract operator)
    // Functions
    ,(Priority: 0; Arguments: 1; Name: 'cos';     OperationType: OpCos)       // OpCos
    ,(Priority: 0; Arguments: 1; Name: 'sin';     OperationType: OpSin)       // OpSin
    ,(Priority: 0; Arguments: 1; Name: 'tan';     OperationType: OpTan)       // OpTan
    ,(Priority: 0; Arguments: 1; Name: 'log';     OperationType: OpLog)       // OpLog
    ,(Priority: 0; Arguments: 1; Name: 'ln';      OperationType: OpLn)        // OpLn
    ,(Priority: 0; Arguments: 1; Name: 'asin';    OperationType: OpASin)      // OpASin
    ,(Priority: 0; Arguments: 1; Name: 'acos';    OperationType: OpACos)      // OpACos
    ,(Priority: 0; Arguments: 1; Name: 'atan';    OperationType: OpATan)      // OpATan
    ,(Priority: 0; Arguments: 1; Name: 'exp';     OperationType: OpExp)       // OpExp
    ,(Priority: 0; Arguments: 1; Name: 'sqrt';    OperationType: OpSqrt)      // OpSqrt
    ,(Priority: 0; Arguments: 1; Name: 'sqr';     OperationType: OpSqr)       // OpSqr
    ,(Priority: 0; Arguments: 2; Name: 'logn';    OperationType: OpLogN)      // OpLogN
    ,(Priority: 0; Arguments: 1; Name: 'int';     OperationType: OpInt)       // OpInt
    ,(Priority: 0; Arguments: 1; Name: 'frac';    OperationType: OpFrac)      // OpFrac
    ,(Priority: 0; Arguments: 1; Name: 'abs';     OperationType: OpAbs)       // OpAbs
    ,(Priority: 0; Arguments: 1; Name: 'ceil';    OperationType: OpCeil)      // OpCeil
    ,(Priority: 0; Arguments: 1; Name: 'floor';   OperationType: OpFloor)     // OpFloor
    ,(Priority: 0; Arguments: 2; Name: 'ldexp';   OperationType: OpLdexp)     // OpLdexp
    ,(Priority: 0; Arguments: 1; Name: 'lnxp1';   OperationType: OpLnXP1)     // OpLnXP1
    ,(Priority: 0; Arguments: 2; Name: 'max';     OperationType: OpMax)       // OpMax
    ,(Priority: 0; Arguments: 2; Name: 'min';     OperationType: OpMin)       // OpMin
    ,(Priority: 0; Arguments: 2; Name: 'roundto'; OperationType: OpRoundTo)   // OpRoundTo
    ,(Priority: 0; Arguments: 1; Name: 'sign';    OperationType: OpSign)      // OpSign
    ,(Priority: 0; Arguments:-1; Name: 'sum';     OperationType: OpSum)       // OpSum
    );

function GetOperationType(s: string): TOperationType;
function GetOperationInfo(OperationType: TOperationType): TOperationInfo;

type
  TStackInfo = record
    Value: Extended;
    OperationType: TOperationType;
    TypeStack: TTypeStack;
    VarName: string;
    ArgumentsCount: Integer;  // Number of arguments for functions with no fixed arguments
  end;

  TStack = class
  private
    fCount: Integer;
  protected
    fList: array of TStackInfo;
    function GetStackInfo(Index: Integer): TStackInfo;
    procedure SetStackInfo(Index: Integer; StackInfo: TStackInfo);
  public
    constructor create;
    property Count: Integer read fCount;
    property StackInfo[Index: Integer]: TStackInfo read GetStackInfo write SetStackInfo; default;
    function Add(StackInfo: TStackInfo): Integer;
    function Insert(StackInfo: TStackInfo; Index: Integer): Integer;
    procedure Delete(Index: Integer);
    function DeleteLast: TStackInfo;
    function Last: TStackInfo;
    procedure Clear;
  end;

  function ReturnTStackInfo(Value: Extended; TypeStack: TTypeStack; OperationType: TOperationType = opNone; VariableName: string = ''): TStackInfo;


type
  TVariables = class
  private
    fCount: Integer;
    fNames: Array of string;
    fValues: Array of Extended;
    function Add(Name: String; Value: Extended): Integer;
    procedure Delete(Name: String);
  protected
    procedure Clear;
    function GetName(Index: Integer): String;
    function GetValue(Index: Integer): Extended; overload;
  public
    constructor create;
    property Count: Integer read fCount;
    property Names[Index: Integer]: String read GetName;
    property Values[Index: Integer]: Extended read GetValue;
    function GetIndex(Name: String): Integer;
    function GetValue(Name: String; var Value: Extended): boolean; overload;
    procedure SetValue(Name: String; Value: Extended);
  end;

  function ValidVariableName(Name: string): Boolean;


type
  TcyMathParser = class
  private
    fLastError: integer;
    fLastErrorBeforeParse: Integer;
    fResultStack: TStack;
    fPrefixStack: TStack;
    fExpression: String;
    procedure InfixToPreFix(infix: TStack; Prefix: TStack);
    procedure StrToInfixStack(aExpression: String; aStack: TStack);
    function ValidateInfixStack(aStack: TStack):Boolean;
    function GetParserResult: Extended;
    procedure SetExpression(const Value: String);
    protected
  public
    Variables: TVariables;
    constructor create;
    destructor Destroy; override;
    property Expression: String read fExpression write SetExpression;
    property ParserResult: Extended read GetParserResult;
    procedure Parse;
    function GetLastError: Integer;
    function GetLastErrorString: String;
  end;

function GetErrorString(ErrorCode: integer): String;


implementation

function GetOperationType(s: string): TOperationType;
var
 i: Integer;
begin
  Result := opNone;

  for i:= 0 to MaxOperationsInfo do
    if OperationsInfo[i].Name = s
    then begin
      Result := OperationsInfo[i].OperationType;
      break;
    end;
end;

function GetOperationInfo(OperationType: TOperationType): TOperationInfo;
var i: Integer;
begin
  Result := OperationsInfo[0];  // None

 for i:= 1 to MaxOperationsInfo do
  if OperationsInfo[i].OperationType = OperationType
  then begin
    Result := OperationsInfo[i];
    break;
  end;
end;

function ReturnTStackInfo(Value: Extended; TypeStack: TTypeStack; OperationType: TOperationType = opNone; VariableName: string = ''): TStackInfo;
begin
  Result.Value := Value;
  Result.OperationType := OperationType;
  Result.TypeStack := TypeStack;
  Result.VarName := VariableName;
end;

constructor TStack.Create;
begin
  inherited;
  fCount := 0;
  SetLength(fList, 0);
end;

function TStack.GetStackInfo(Index: Integer): TStackInfo;
begin
  Result := fList[Index];
end;

procedure TStack.SetStackInfo(Index: Integer; StackInfo: TStackInfo);
begin
  fList[Index] := StackInfo;
end;

function TStack.Add(StackInfo: TStackInfo): Integer;
begin
  inc(fCount);
  Setlength(fList, fCount);
  fList[fCount - 1] := StackInfo;
  Result := fCount - 1;
end;

function TStack.Insert(StackInfo: TStackInfo; Index: Integer): Integer;
var i: Integer;
begin
  if Index > fCount then Index := fCount;
  if Index < 0 then Index := 0;

  Setlength(fList, fCount + 1);
  i:= fCount - 1;

  while i >= Index do
  begin
    fList[i+1] := fList[i];
    dec(i);
  end;
  fList[Index] := StackInfo;
  inc(fCount);
  Result := Index;
end;

procedure TStack.Delete(Index: Integer);
begin
  dec(fCount);
  while Index < fCount do
  begin
    fList[Index] := fList[Index+1];
    inc(Index);
  end;
  Setlength(fList, fCount);
end;

function TStack.DeleteLast: TStackInfo;
begin
  Result := fList[fCount-1];
  Delete(fCount-1);
end;

function TStack.Last: TStackInfo;
begin
  Result := fList[fCount-1];
end;

procedure TStack.Clear;
begin
  fCount := 0;
  Setlength(fList, 0);
end;

// Determine if variable Name is defined with 'a'..'z', '_' and does not enter in conflict with function Names:
function ValidVariableName(Name: string): Boolean;
var
 i: Integer;
begin
  Result:= false;
  Name := trim(Lowercase(Name));
  if (Name = '') or (Name = 'e') then exit;        // ex: 5E3 = 5 * 10*10*10
  if GetOperationType(Name) <> opNone then exit;
  if not (Name[1] in ['_','a'..'z']) then exit;

  for i:= 2 to length(Name) do
    if not (Name[i] in ['_','a'..'z','0'..'9'])
    then exit;

  Result:= True;
end;

constructor TVariables.Create;
begin
  Clear;
end;

procedure TVariables.Clear;
begin
  fCount := 0;
  setlength(fNames, 0);
  setlength(fValues, 0);
end;

function TVariables.GetIndex(Name: String): Integer;
var i: Integer;
begin
  Result := -1;
  Name := lowercase(Name);

  for i:= 0 to fCount - 1 do
    if fNames[i] = Name
    then begin
      Result := i;
      exit;
    end;
end;

function TVariables.GetValue(Name: string; var Value: Extended): Boolean;
var i: Integer;
begin
  Result:= false;
  Name := lowercase(Name);
  i := GetIndex(Name);

  if i<> -1
  then begin
    Value := fValues[i];
    Result := True;
  end;
end;

procedure TVariables.SetValue(Name: String; Value: Extended);
var
 i: Integer;
begin
  Name := lowercase(Name);
  i := GetIndex(Name);

  if i = -1
  then Add(Name, Value)
  else fValues[i] := value;
end;

function TVariables.Add(Name: String; Value: Extended): Integer;
begin
  Name := lowercase(Name);
  Result := GetIndex(Name);

  if Result = -1
  then begin
    inc(fCount);
    setlength(fNames, fCount);
    setlength(fValues, fCount);
    fNames[fCount-1] := Name;
    fValues[fCount-1] := Value;
    Result := fCount-1;
  end;
end;

procedure TVariables.Delete(Name: String);
var
 i: Integer;
begin
  Name := Lowercase(Name);
  i := GetIndex(Name);
  if i = -1 then exit;
  dec(fCount);
  move(fNames[i + 1], fNames[i], (fCount - i - 1) * sizeof(string));
  move(fValues[i + 1], fValues[i], (fCount-i-1) * sizeof(extended));
  setlength(fNames, fCount);
  setlength(fValues, fCount);
end;

function TVariables.GetName(Index: Integer): String;
begin
  Result := fNames[Index];
end;

function TVariables.GetValue(Index: Integer): Extended;
begin
  Result := fValues[Index];
end;

constructor TcyMathParser.Create;
begin
  inherited;
  fExpression := '';
  fLastError := cNoError;
  fLastErrorBeforeParse := cNoError;
  fResultStack := TStack.Create;
  fPrefixStack := TStack.Create;
  Variables := TVariables.Create;
  //Variables.Add('pi', 3.1415926535897932385);
end;

destructor TcyMathParser.Destroy;
begin
  fResultStack.Free;
  fPrefixStack.Free;
  Variables.Free;
  inherited;
end;

procedure TcyMathParser.SetExpression(const Value: String);
var InfixStack: TStack;
begin
  fExpression := Value;
  fLastError := cNoError;
  fLastErrorBeforeParse := cNoError;
  fPrefixStack.Clear;
  fResultStack.Clear;
  if fExpression = '' then exit;

  // Get infix stack :
  InfixStack := TStack.create;
  StrToInfixStack(fExpression, InfixStack);

  if fLastError = cNoError then
    if ValidateInfixStack(InfixStack) then
      InfixToPreFix(InfixStack, fPrefixStack);

  fLastErrorBeforeParse := fLastError;

  InfixStack.Free;
end;

// Convert infix notation to stack infix notation :
procedure TcyMathParser.StrToInfixStack(aExpression: String; aStack: TStack);
var
  i, j, lengthExpr: integer;
  s: string;
  v: Extended;
  Op: TOperationType;
begin
  aStack.Clear;
  aExpression := LowerCase(aExpression);
  lengthExpr := length(aExpression);
  i := 1;

  while i <= lengthExpr do
    case aExpression[i] of
      '(','{','[':
        begin
          aStack.Add(ReturnTStackInfo(0, tsLeftParenthese));
          inc(i);
        end;

      ')','}',']':
        begin
          aStack.Add(ReturnTStackInfo(0, tsRightParenthese));
          inc(i);
        end;

      'a'..'z', '_':  // Functions and variables must begin with a letter or with '_'
        begin
          s := '';
          for j := i to lengthExpr do
            if aExpression[j] in ['a'..'z', '_', '0'..'9', ' ']
            then begin
              // case of the function "E": (Exemple: 5E3 = 5 * 10*10*10), must be followed by a number :
              if (s = 'e') and (aExpression[j] in ['0'..'9', ' '])
              then begin
                s := '';
                inc(i);  // Return to next car after "E"
                // E must be replaced by *10^
                aStack.Add(ReturnTStackInfo(0, tsOperator, GetOperationType('*')));
                aStack.Add(ReturnTStackInfo(10, tsValue));
                aStack.Add(ReturnTStackInfo(0, tsOperator, GetOperationType('^')));
                Break;
              end
              else
                // case of the operator "mod"
                if (s = 'mod') and (aExpression[j] in ['0'..'9', ' '])
                then begin
                  s := '';
                  i := i + 3;  // Return to next car after "mod"
                  aStack.Add(ReturnTStackInfo(0, tsOperator, OpMod));
                  Break;
                end
                else
                  if aExpression[j] <> ' '
                  then s := s + aExpression[j]
                  else Break;
            end
            else
              break;

          if s <> ''
          then begin
            i := j;
            Op := GetOperationType(s);  // Know if it is a function or variable  ...

            if op = opNone
            then
              aStack.Add(ReturnTStackInfo(0, tsVariable, opNone, s))
            else
              if GetOperationInfo(Op).Priority <> 0 // Operators
              then aStack.Add(ReturnTStackInfo(0, tsOperator, Op))
              else aStack.Add(ReturnTStackInfo(0, tsFunction, Op));
          end;
        end;

      '0'..'9', '.', ',':
        begin
          s:= '';
          for j := i to lengthExpr do
            if aExpression[j] in ['0'..'9']
            then
              s := s + aExpression[j]
            else
              if aExpression[j] in ['.', ',']
              then s := s + DecimalSeparator
              else break;

          i := j;

          if not TryStrToFloat(s, V)
          then begin
            fLastError := cErrorInvalidFloat;
            Exit;
          end;

          aStack.Add(ReturnTStackInfo(v, tsValue));
        end;

      ';':
        begin
          aStack.Add(ReturnTStackInfo(0, TsSeparator));
          inc(i);
        end;

      '-', '+', '/', '*', '^':
        begin
          aStack.Add(ReturnTStackInfo(0, tsOperator, GetOperationType(aExpression[i])));
          inc(i);
        end;

      '%':
        begin
          aStack.Add(ReturnTStackInfo(0, tsOperator, OpDivide));
          aStack.Add(ReturnTStackInfo(100, tsValue));
          inc(i);
        end;

      // Space, just ignore
      ' ':
        Inc(i);

      else begin
        fLastError := cErrorInvalidCar;
        exit;
      end;
    end;
end;

function TcyMathParser.ValidateInfixStack(aStack: TStack): Boolean;
var
  LeftParentesesCount, RightParentesesCount: Integer;
  i: Integer;

  j, c, NbArguments: Integer;
begin
  LeftParentesesCount := 0;
  RightParentesesCount := 0;

  i := 0;
  while (fLastError = cNoError) and (i <= aStack.Count-1) do   // Note that aStack.Count can change!
    case aStack[i].TypeStack of
      tsLeftParenthese:
      begin
        // *** Check for invalid position *** //
        if i > 0
        then begin
          // Need multiply operator ?
          if aStack[i-1].TypeStack in [tsValue, TsVariable, tsRightParenthese]
          then begin
            aStack.Insert(ReturnTStackInfo(0, tsOperator, OpMultiply), i);
            Continue; // Will process this new stack
          end;
        end;

        if (i = aStack.Count - 1)
        then fLastError := cErrorMissingRightParenteses;

        inc(LeftParentesesCount);
        inc(i);
      end;

      tsRightParenthese:
      begin
        // *** Check for invalid position *** //
        if i > 0
        then begin
         if aStack[i-1].TypeStack in [tsFunction, tsOperator, TsSeparator]
         then fLastError := cErrorRightParentese;
        end;

        inc(RightParentesesCount);
        inc(i);

        if (fLastError = cNoError) and (RightParentesesCount > LeftParentesesCount)
        then fLastError := cErrorMissingLeftParenteses;
      end;

      tsValue, TsVariable:
      begin
        // *** Check for invalid position *** //
        if i > 0
        then begin
          // Need multiply operator ?
          if aStack[i-1].TypeStack in [tsValue, TsVariable, tsRightParenthese]
          then begin
            aStack.Insert(ReturnTStackInfo(0, tsOperator, OpMultiply), i);
            Continue; // Will process this new stack
          end;

          if aStack[i-1].TypeStack = tsFunction
          then fLastError := cErrorFxNeedLeftParentese;
        end;

        inc(i);
      end;

      tsFunction:
      begin
        // *** Check for invalid position *** //
        if i > 0
        then begin
          // Need multiply operator ?
          if aStack[i-1].TypeStack in [tsValue, TsVariable, tsRightParenthese]
          then begin
            aStack.Insert(ReturnTStackInfo(0, tsOperator, OpMultiply), i);
            Continue; // Will process this new stack
          end;
        end;

        if (i = aStack.Count - 1)
        then fLastError := cErrorFxNeedLeftParentese;

        inc(i);
      end;

      tsSeparator:
      begin
        // *** Check for invalid use *** //
        if i = 0
        then
          fLastError := cErrorSeparator
        else
          if (i = aStack.Count - 1)
          then
            fLastError := cErrorSeparatorNeedArgument
          else
            case aStack[i-1].TypeStack of
              tsFunction: fLastError := cErrorFxNeedLeftParentese;
              tsSeparator: fLastError := cErrorSeparatorNeedArgument;
              tsOperator, tsLeftParenthese: fLastError := cErrorSeparator;
            end;

        inc(i);
      end;

      tsOperator:
      begin
        // *** Check for invalid use *** //
        if i = 0
        then begin
          case aStack[0].OperationType of
            OpAdd:
              begin
                aStack.Delete(0);
                Dec(i);
              end;

            OpSubstract:
              aStack.fList[0].OperationType := OpNeg;

            else
              fLastError := cErrorOperator;
          end;
        end
        else
          if (i = aStack.Count - 1)
          then
            fLastError := cErrorOperatorNeedArgument
          else
            case aStack[i-1].TypeStack of
              tsFunction: fLastError := cErrorFxNeedLeftParentese;
              tsOperator, tsLeftParenthese, tsSeparator:  // excluding opNeg that is handled upper ...
                case aStack[i].OperationType of     // Check current operation
                  OpSubstract:
                    if (aStack[i-1].TypeStack = tsOperator) and (aStack[i-1].OperationType = OpNeg)
                    then begin
                      // opSubstract nullify opNeg :
                      aStack.Delete(i-1);
                      Dec(i);

                      aStack.Delete(i);
                      Dec(i);
                    end
                    else
                      aStack.fList[i].OperationType := OpNeg;

                  OpAdd:
                    begin
                      aStack.Delete(i);
                      Dec(i);
                    end;

                  else   // like opMultiply etc ...
                    fLastError := cErrorOperator;
                end;
            end;

        inc(i);
      end;
    end;

  // Handle functions with undefined operands number :
  i:= 0;
  while (fLastError = cNoError) and (i < aStack.Count) do
  begin
    if (aStack[i].TypeStack = tsFunction) and (GetOperationInfo(aStack[i].OperationType).Arguments = -1)
    then begin
      c := 1;
      NbArguments := 1;
      j := i + 2;

      while (j < aStack.Count) and (c > 0) do
      begin
        case aStack[j].TypeStack of
          tsSeparator: if c = 1 then inc(NbArguments);
          tsLeftParenthese:  Inc(c);
          tsRightParenthese: dec(c);
        end;
        inc(j);
      end;

      aStack.fList[i].ArgumentsCount := NbArguments;        // Store the number of arguments
    end;

    inc(i);
  end;

  if (fLastError = cNoError) and (LeftParentesesCount <> RightParentesesCount)
  then
    if LeftParentesesCount > RightParentesesCount
    then fLastError := cErrorMissingRightParenteses
    else fLastError := cErrorMissingLeftParenteses;

  Result := fLastError = cNoError;
end;

procedure TcyMathParser.InfixToPreFix(Infix: TStack; Prefix: TStack);
var
  TmpStack: TStack;
  i: Integer;
  Current: TStackInfo;
begin
  TmpStack := TStack.Create;

  for i:= 0 to Infix.Count-1 do
  begin
    Current := Infix[i];

    case Current.TypeStack of
      tsValue, TsVariable:
        Prefix.Add(Current);

      tsFunction:
        TmpStack.Add(Current);

      tsLeftParenthese:
        TmpStack.Add(Current);

      tsRightParenthese:  // end of previous argument or group of arguments
        begin
          while TmpStack.Count <> 0 do
            if TmpStack.Last.TypeStack <> tsLeftParenthese
            then Prefix.Add(TmpStack.DeleteLast)
            else Break;

          TmpStack.DeleteLast;

          if TmpStack.Count <> 0 then
            if TmpStack.Last.TypeStack = tsFunction then
              Prefix.Add(TmpStack.DeleteLast);
        end;

      tsSeparator:        // end of previous argument
        begin
          while TmpStack.Count <> 0 do
            if TmpStack.Last.TypeStack <> tsLeftParenthese
            then Prefix.Add(TmpStack.DeleteLast)
            else Break;
        end;

      tsOperator:
        begin
          while (TmpStack.Count > 0) do
            if (TmpStack.Last.TypeStack = tsOperator) and (GetOperationInfo(Current.OperationType).Priority <= GetOperationInfo(TmpStack.Last.OperationType).Priority)
            then Prefix.Add(TmpStack.DeleteLast)
            else Break;

         TmpStack.Add(Current);
        end;
    end;
  end;

  while TmpStack.Count > 0 do
    Prefix.Add(TmpStack.DeleteLast);

  TmpStack.Free;
end;

procedure TcyMathParser.Parse;

    function ExtendedMod(x, y: Extended): Extended;
    begin
      Result := x - int(x / y) * y;
    end;

var
  Current: TStackInfo;
  i, j, Arguments: Integer;
  aValue: Extended;
  Values: array of Extended;

        procedure ApplyOperation;
        var v: Integer;
        begin
          try
            case Current.OperationType of
              opNone: ;

              // Operators :
              OpPower    : if (frac(Values[0]) <> 0) and (Values[1] < 0)
                           then fLastError := cErrorPower
                           else fResultStack.Add(ReturnTStackInfo(power(Values[1], Values[0]), tsValue));

              OpMultiply : fResultStack.Add(ReturnTStackInfo(Values[1] * Values[0], tsValue));

              OpDivide   : if Values[0] = 0
                           then fLastError := cErrorDivByZero
                           else fResultStack.Add(ReturnTStackInfo(Values[1] / Values[0], tsValue));

              OpAdd      : fResultStack.Add(ReturnTStackInfo(Values[1] + Values[0], tsValue));

              OpSubstract: fResultStack.Add(ReturnTStackInfo(Values[1] - Values[0], tsValue));

              OpNeg      : fResultStack.Add(ReturnTStackInfo(-Values[0], tsValue));

              opMod      : if Values[0] = 0
                           then fLastError := cErrorDivByZero
                           else fResultStack.Add( ReturnTStackInfo(ExtendedMod(Values[1], Values[0]), tsValue) );

              // Functions :
              OpCos      : fResultStack.Add(ReturnTStackInfo(cos(Values[0]), tsValue));

              OpSin      : fResultStack.Add(ReturnTStackInfo(sin(Values[0]), tsValue));

              OpTan      : fResultStack.Add(ReturnTStackInfo(tan(Values[0]), tsValue));

              OpLog      : if Values[0] <= 0
                           then fLastError := cErrorFxInvalidValue
                           else fResultStack.Add(ReturnTStackInfo(log10(Values[0]), tsValue));

              OpLn       : if Values[0] <= 0
                           then fLastError := cErrorFxInvalidValue
                           else fResultStack.Add(ReturnTStackInfo(ln(Values[0]), tsValue));

              OpASin     : if (Values[0] < -1) or (Values[0] > 1)
                           then fLastError := cErrorFxInvalidValue
                           else fResultStack.Add(ReturnTStackInfo(arcsin(Values[0]), tsValue));

              OpACos     : if (Values[0] < -1) or (Values[0] > 1)
                           then fLastError := cErrorFxInvalidValue
                           else fResultStack.Add(ReturnTStackInfo(arccos(Values[0]), tsValue));

              OpATan     : fResultStack.Add(ReturnTStackInfo(arctan(Values[0]), tsValue));

              OpExp      : fResultStack.Add(ReturnTStackInfo(exp(Values[0]), tsValue));

              OpSqrt     : if Values[0] < 0
                           then fLastError := cErrorFxInvalidValue
                           else fResultStack.Add(ReturnTStackInfo(sqrt(Values[0]), tsValue));

              OpSqr      : fResultStack.Add(ReturnTStackInfo(sqr(Values[0]), tsValue));

              OpInt      : fResultStack.Add(ReturnTStackInfo(int(Values[0]), tsValue));

              OpFrac     : fResultStack.Add(ReturnTStackInfo(frac(Values[0]), tsValue));

              OpAbs      : fResultStack.Add(ReturnTStackInfo(abs(Values[0]), tsValue));

              OpLogN     : if (Values[1] <= 0) or (Values[0] <= 0) or (Log2(Values[1]) = 0)
                           then fLastError := cErrorFxInvalidValue
                           else fResultStack.Add(ReturnTStackInfo(logn(Values[1], Values[0]), tsValue));

              OpCeil     : fResultStack.Add(ReturnTStackInfo(Ceil(Values[0]), tsValue));

              OpFloor    : fResultStack.Add(ReturnTStackInfo(Floor(Values[0]), tsValue));

              OpLdexp    : fResultStack.Add(ReturnTStackInfo(Ldexp(Values[1], round(Values[0])), tsValue));

              OpLnXP1    : if Values[0] <= -1
                           then fLastError := cErrorFxInvalidValue
                           else fResultStack.Add(ReturnTStackInfo(LnXP1(Values[0]), tsValue));

              OpMax      : fResultStack.Add(ReturnTStackInfo(Max(Values[1], Values[0]), tsValue));

              OpMin      : fResultStack.Add(ReturnTStackInfo(Min(Values[1], Values[0]), tsValue));

              OpRoundTo  : fResultStack.Add(ReturnTStackInfo(RoundTo(Values[1], round(Values[0])), tsValue));

              OpSign     : fResultStack.Add(ReturnTStackInfo(Sign(Values[0]), tsValue));

              OpSum      : begin
                             aValue := 0;
                             for v := 0 to Arguments-1 do
                               aValue := aValue + Values[v];

                             fResultStack.Add(ReturnTStackInfo(aValue, tsValue));
                           end;
            end;
          except
            on EInvalidOp do fLastError := cCalcError;
          end;
        end;

begin
  fResultStack.Clear;
  fLastError := fLastErrorBeforeParse;

  i := 0;
  while (fLastError = cNoError) and (i < fPrefixStack.Count) do
  begin
    Current := fPrefixStack[i];
    inc(i);

    case Current.TypeStack of
      tsValue :
        fResultStack.Add(Current);

      tsVariable:
        begin
         if not Variables.GetValue(Current.VarName, aValue)
         then fLastError := cErrorUnknownName
         else fResultStack.Add(ReturnTStackInfo(aValue, tsValue));
        end;

      tsOperator, tsFunction:
        begin
          Arguments := GetOperationInfo(Current.OperationType).Arguments;

          // Functions with undefined arguments :
          if Arguments = -1
          then Arguments := Current.ArgumentsCount;

          if fResultStack.Count >= Arguments // Suficient arguments/operands?
          then begin
            SetLength(Values, Arguments);

            // Store needed arguments/operands in array:
            for j := 0 to Arguments - 1 do
              Values[j] := fResultStack.DeleteLast.Value;

            // Make the calc :
            ApplyOperation;
          end
          else
            fLastError := cErrorNotEnoughArgs;
        end;
    end;
  end;

  // All stacks parsed ?
  if fResultStack.Count > 1 then
    fLastError := cInternalError;
end;

function TcyMathParser.GetParserResult: Extended;
begin
  if fResultStack.Count > 0
  then Result := fResultStack[0].Value   // Retrieve topmost stack
  else Result := 0;
end;

function TcyMathParser.GetLastError: Integer;
begin
  Result := fLastError;
end;

function TcyMathParser.GetLastErrorString: String;
begin
  Result := GetErrorString(fLastError);
end;

function GetErrorString(ErrorCode: integer): String;
begin
  case ErrorCode of
    cNoError:                     Result := '';

    cInternalError:               Result := 'Cannot parse';

    cErrorInvalidCar:             Result := 'Invalid car';
    cErrorUnknownName:            Result := 'Unknown function or variable';
    cErrorInvalidFloat:           Result := 'Invalid float number';
    cErrorOperator:               Result := 'Operator cannot be placed here';
    cErrorFxNeedLeftParentese:    Result := 'A function must be followed by left parentese';
    cErrorNotEnoughArgs:          Result := 'Not enough arguments or operands';
    cErrorSeparatorNeedArgument:  Result := 'Missing argument after separator';
    cErrorMissingLeftParenteses:  Result := 'Missing at least one left parentese';
    cErrorMissingRightParenteses: Result := 'Missing at least one right parentese';
    cErrorLeftParentese:          Result := 'Left parentese cannot be placed here';
    cErrorRightParentese:         Result := 'Right parentese cannot be placed here';
    cErrorSeparator:              Result := 'Separator cannot be placed here';
    cErrorOperatorNeedArgument:   Result := 'Operator must be followed by argument';

    cCalcError:                   Result := 'Invalid operation';
    cErrorDivByZero:              Result := 'Division by zero';
    cErrorPower:                  Result := 'Invalid use of power function';
    cErrorFxInvalidValue:         Result := 'Invalid parameter value for function';
  end;
end;

end.
