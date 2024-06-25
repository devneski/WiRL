object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'WiRL HelloWorld'
  ClientHeight = 317
  ClientWidth = 554
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 13
  object TopPanel: TPanel
    Left = 0
    Top = 0
    Width = 554
    Height = 73
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    ExplicitWidth = 550
    DesignSize = (
      554
      73)
    object Label1: TLabel
      Left = 28
      Top = 17
      Width = 63
      Height = 13
      Caption = 'Port number:'
    end
    object StartButton: TButton
      Left = 16
      Top = 41
      Width = 75
      Height = 25
      Action = actStartServer
      TabOrder = 0
    end
    object StopButton: TButton
      Left = 104
      Top = 41
      Width = 75
      Height = 25
      Action = actStopServer
      TabOrder = 1
    end
    object PortNumberEdit: TEdit
      Left = 97
      Top = 14
      Width = 82
      Height = 21
      TabOrder = 2
      Text = '8080'
    end
    object btnDocumentation: TButton
      Left = 393
      Top = 41
      Width = 153
      Height = 25
      Action = actShowDocumentation
      Anchors = [akTop, akRight]
      TabOrder = 3
      ExplicitLeft = 389
    end
  end
  object Button1: TButton
    Left = 8
    Top = 96
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 1
    Visible = False
    OnClick = Button1Click
  end
  object Memo1: TMemo
    Left = 104
    Top = 98
    Width = 442
    Height = 183
    Lines.Strings = (
      'Memo1')
    TabOrder = 2
    Visible = False
  end
  object Button2: TButton
    Left = 8
    Top = 136
    Width = 75
    Height = 25
    Caption = 'Button2'
    TabOrder = 3
    Visible = False
    OnClick = Button2Click
  end
  object MainActionList: TActionList
    Left = 104
    Top = 96
    object actStartServer: TAction
      Caption = 'Start Server'
      OnExecute = actStartServerExecute
      OnUpdate = actStartServerUpdate
    end
    object actStopServer: TAction
      Caption = 'Stop Server'
      OnExecute = actStopServerExecute
      OnUpdate = actStopServerUpdate
    end
    object actShowDocumentation: TAction
      Caption = 'Show Documentation'
      OnExecute = actShowDocumentationExecute
      OnUpdate = actShowDocumentationUpdate
    end
  end
  object XMLDocument1: TXMLDocument
    Left = 272
    Top = 152
  end
end
