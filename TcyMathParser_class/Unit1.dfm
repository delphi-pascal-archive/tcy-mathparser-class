object Form1: TForm1
  Left = 217
  Top = 126
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'TcyMathParser class'
  ClientHeight = 587
  ClientWidth = 811
  Color = clBtnFace
  Font.Charset = RUSSIAN_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnShow = FormShow
  PixelsPerInch = 120
  TextHeight = 16
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 80
    Height = 16
    Caption = 'Expressions: '
  end
  object Image1: TImage
    Left = 288
    Top = 168
    Width = 513
    Height = 361
    OnMouseDown = Image1MouseDown
    OnMouseUp = Image1MouseUp
  end
  object Label3: TLabel
    Left = 8
    Top = 296
    Width = 48
    Height = 16
    Caption = 'Results:'
  end
  object Label2: TLabel
    Left = 288
    Top = 16
    Width = 33
    Height = 30
    Caption = 'F(x)='
  end
  object Bevel1: TBevel
    Left = 280
    Top = 16
    Width = 9
    Height = 561
    Shape = bsLeftLine
  end
  object Label4: TLabel
    Left = 288
    Top = 536
    Width = 38
    Height = 16
    Caption = 'Zoom:'
  end
  object MemExprs: TMemo
    Left = 8
    Top = 30
    Width = 265
    Height = 259
    Lines.Strings = (
      '2+2*3'
      '2(15+25)'
      '-1+3'
      '1.3'
      '1,3'
      '-(2+3)'
      'var1=25'
      'var2=70'
      'var1+var2')
    TabOrder = 0
    OnChange = MemExprsChange
  end
  object MemRslts: TMemo
    Left = 8
    Top = 320
    Width = 265
    Height = 257
    TabOrder = 1
  end
  object MemGraf: TMemo
    Left = 320
    Top = 16
    Width = 482
    Height = 145
    Lines.Strings = (
      'x'
      '1/x'
      'x*x')
    TabOrder = 2
    OnChange = MemGrafChange
  end
  object TrackBar1: TTrackBar
    Left = 288
    Top = 554
    Width = 521
    Height = 23
    Max = 100
    Min = 1
    Position = 60
    TabOrder = 3
    ThumbLength = 15
    TickStyle = tsNone
    OnChange = MemGrafChange
  end
end
