{******************************************************************************}
{                                                                              }
{       WiRL: RESTful Library for Delphi                                       }
{                                                                              }
{       Copyright (c) 2015-2023 WiRL Team                                      }
{                                                                              }
{       https://github.com/delphi-blocks/WiRL                                  }
{                                                                              }
{******************************************************************************}
unit WiRL.http.FileSystemEngine;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  System.IOUtils,

{$IFDEF MSWINDOWS}
  Winapi.Windows,
{$ENDIF}

  WiRL.http.Accept.MediaType,
  WiRL.Core.Context,
  WiRL.Core.Context.Server,
  WiRL.Core.Exceptions,
  WiRL.http.Request,
  WiRL.http.Response,
  WiRL.http.Server;

type
  TWiRLFileSystemErrorEvent = procedure (ASender: TObject; AStatusCode: Integer; AContext: TWiRLContext) of object;

  TStringFunc = TFunc<string>;

  TWiRLFileSystemEngine = class(TWiRLCustomEngine)
  private const
    DefaultEngineName = 'WiRL FileSystemEngine';
    DefaultRootFolder = '{AppPath}' + PathDelim + 'www';
  private
    FRootFolder: string;
    FMacros: TDictionary<string,TStringFunc>;
    FExpandedRootFolder: string;
    FContentTypesForExt: TDictionary<string, string>;
    FIndexFileNames: TStringList;
    FOnError: TWiRLFileSystemErrorEvent;
    function GetContentType(const AFileName: string): string;
    procedure ServeFileContent(const AFileNamme: string; AResponse: TWiRLResponse);
    procedure CheckRelativePath(const ARelativeURL: string);
    function DirectoryHasIndexFile(const ADirectory: string;
      out AIndexFullPath: string): Boolean;
    function ExpandMacros(const ATemplate: string): string;
    procedure HandleError(AStatusCode: Integer; AContext: TWiRLContext);
    procedure SetRootFolderProp(const Value: string);
  protected
    procedure InitExtDictionary; virtual;
    procedure InitIndexFileNames; virtual;
    procedure InitMacros; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function SetEngineName(const AEngineName: string): TWiRLFileSystemEngine;
    function SetRootFolder(const ARootFolder: string): TWiRLFileSystemEngine;
    procedure HandleRequest(AContext: TWiRLContext); override;
    procedure Startup; override;
    property IndexFileNames: TStringList read FIndexFileNames;
    property ContentTypesForExt: TDictionary<string, string> read FContentTypesForExt;
    property Macros: TDictionary<string,TStringFunc> read FMacros;
  published
    property RootFolder: string read FRootFolder write SetRootFolderProp;
    property OnError: TWiRLFileSystemErrorEvent read FOnError write FOnError;
  end;

implementation

const
  HtmlErrorTemplate =
    '<!DOCTYPE html>' + sLineBreak +
    '<html lang=en>' + sLineBreak +
    '  <meta charset=utf-8>' + sLineBreak +
    '  <meta name=viewport content="initial-scale=1, minimum-scale=1, width=device-width">' + sLineBreak +
    '  <title>{ErrorMessage}</title>' + sLineBreak +
    '  <h1>{AppName}</h1>' + sLineBreak +
    '  <p>{ErrorMessage}' + sLineBreak +
    '  <p>{Detail}' + sLineBreak +
    '</html>';

function RemoveTrailingDelim(const APath: string): string;
begin
  if APath.EndsWith(PathDelim) then
    Result := APath.Substring(0, APath.Length - 1)
  else
    Result := APath;
end;

procedure TWiRLFileSystemEngine.CheckRelativePath(const ARelativeURL: string);
begin
  if ARelativeURL.Contains('..') then
    raise EWiRLWebApplicationException.Create('Unprocessable Entity', 422);
end;

constructor TWiRLFileSystemEngine.Create(AOwner: TComponent);
begin
  inherited;
  FContentTypesForExt := TDictionary<string, string>.Create;
  FMacros := TDictionary<string,TStringFunc>.Create;
  FIndexFileNames := TStringList.Create;
  FRootFolder := DefaultRootFolder;
  FEngineName := DefaultEngineName;

  InitExtDictionary;
  InitIndexFileNames;
  InitMacros;
end;

destructor TWiRLFileSystemEngine.Destroy;
begin
  FContentTypesForExt.Free;
  FIndexFileNames.Free;
  FMacros.Free;
  inherited;
end;

function TWiRLFileSystemEngine.GetContentType(const AFileName: string): string;
begin
  if not FContentTypesForExt.TryGetValue(ExtractFileExt(AFileName), Result) then
    Result := TMediaType.APPLICATION_OCTET_STREAM;
end;

function TWiRLFileSystemEngine.DirectoryHasIndexFile(const ADirectory: string;
  out AIndexFullPath: string): Boolean;
var
  LIndex: Integer;
  LIndexFileName: string;
  LIndexFullFileName: string;
begin
  Result := False;
  for LIndex := 0 to IndexFileNames.Count-1 do
  begin
    LIndexFileName := IndexFileNames[LIndex];
    LIndexFullFileName := TPath.Combine(ADirectory, LIndexFileName);
    if FileExists(LIndexFullFileName) then
    begin
      Result := True;
      AIndexFullPath := LIndexFullFileName;
      Break;
    end;
  end;
end;

function TWiRLFileSystemEngine.ExpandMacros(const ATemplate: string): string;
var
  LMacroPair: TPair<string,TFunc<string>>;
begin
  Result := ATemplate;
  for LMacroPair in FMacros do
    Result := Result.Replace('{' + LMacroPair.Key + '}', RemoveTrailingDelim(LMacroPair.Value()), [rfIgnoreCase]);
//  Result := Result.Replace(PathDelim + PathDelim, PathDelim, [rfReplaceAll]);
end;

procedure TWiRLFileSystemEngine.HandleError(AStatusCode: Integer;
  AContext: TWiRLContext);
var
  LContent: string;
  LDetail: string;
  LErrorMessage: string;
begin
  LDetail := '';
  LErrorMessage := '<i>Error code: <b>' + IntToStr(AStatusCode) + '</b></i>';
  if AStatusCode = 404 then
  begin
    LDetail := 'The requested URL <code>' + AContext.Request.PathInfo + '</code> was not found on this server.';
    LErrorMessage := '<b>' + IntToStr(AStatusCode) + '</b> page not found';
  end;

  LContent := HtmlErrorTemplate;
  LContent := LContent.Replace('{ErrorMessage}', LErrorMessage, [rfReplaceAll]);
  LContent := LContent.Replace('{AppName}', FEngineName, [rfReplaceAll]);
  LContent := LContent.Replace('{Detail}', LDetail, [rfReplaceAll]);

  AContext.Response.StatusCode := AStatusCode;
  AContext.Response.ContentType := TMediaType.TEXT_HTML;
  AContext.Response.Content := LContent;

  if Assigned(FOnError) then
    FOnError(Self, AStatusCode, AContext);
end;

procedure TWiRLFileSystemEngine.HandleRequest(AContext: TWiRLContext);
var
  LRelativeURL: string;
  LFullPath: string;
  LIndexFileFullPath: string;
begin
  inherited;
  LRelativeURL := StringReplace(AContext.Request.PathInfo, '/', PathDelim, [rfReplaceAll]).Substring(BasePath.Length);
  CheckRelativePath(LRelativeURL);
  if LRelativeURL.StartsWith(PathDelim) then
    LFullPath := FExpandedRootFolder + LRelativeURL
  else
    LFullPath := FExpandedRootFolder + PathDelim + LRelativeURL;

  if DirectoryExists(LFullPath) then
  begin
    if DirectoryHasIndexFile(LFullPath, LIndexFileFullPath) then
      ServeFileContent(LIndexFileFullPath, AContext.Response)
    else
      HandleError(404, AContext);
  end
  else if FileExists(LFullPath) then
  begin
    ServeFileContent(LFullPath, AContext.Response);
  end
  else
  begin
    HandleError(404, AContext);
  end;
end;

procedure TWiRLFileSystemEngine.InitExtDictionary;
begin
  ContentTypesForExt.Add('.svg', 'image/svg+xml');
  ContentTypesForExt.Add('.jpg', 'image/jpeg');
  ContentTypesForExt.Add('.jpeg', 'image/jpeg');
  ContentTypesForExt.Add('.png', 'image/png');
  ContentTypesForExt.Add('.pdf', 'application/pdf');
  ContentTypesForExt.Add('.htm', 'text/html');
  ContentTypesForExt.Add('.html', 'text/html');
  ContentTypesForExt.Add('.js', 'application/javascript');
  ContentTypesForExt.Add('.css', 'text/css');
  ContentTypesForExt.Add('.txt', 'text/plain');
end;

procedure TWiRLFileSystemEngine.InitIndexFileNames;
begin
  IndexFileNames.Add('index.html');
  IndexFileNames.Add('index.htm');
  IndexFileNames.Add('default.html');
  IndexFileNames.Add('default.htm');
end;

procedure TWiRLFileSystemEngine.InitMacros;
begin
  Macros.Add('AppPath', function ():string
  begin
    Result := ExtractFilePath(ParamStr(0));
  end);

  Macros.Add('CurrPath', function ():string
  begin
    Result := TDirectory.GetCurrentDirectory;
  end);

  Macros.Add('TempPath', function ():string
  begin
    Result := TPath.GetTempPath;
  end);

  Macros.Add('HomePath', function ():string
  begin
    Result := TPath.GetHomePath;
  end);

  Macros.Add('DocumentsPath', function ():string
  begin
    Result := TPath.GetDocumentsPath;
  end);

  Macros.Add('PublicPath', function ():string
  begin
    Result := TPath.GetPublicPath;
  end);
end;

procedure TWiRLFileSystemEngine.ServeFileContent(const AFileNamme: string;
  AResponse: TWiRLResponse);
begin
  AResponse.StatusCode := 200;
  AResponse.ContentStream := TFileStream.Create(AFileNamme, fmOpenRead);
  AResponse.ContentType := GetContentType(AFileNamme);
end;

function TWiRLFileSystemEngine.SetEngineName(
  const AEngineName: string): TWiRLFileSystemEngine;
begin
  FEngineName := AEngineName;
  Result := Self;
end;

function TWiRLFileSystemEngine.SetRootFolder(
  const ARootFolder: string): TWiRLFileSystemEngine;
begin
  RootFolder := ARootFolder;
  Result := Self;
end;

procedure TWiRLFileSystemEngine.SetRootFolderProp(const Value: string);
begin
  if FRootFolder <> Value then
  begin
    if (Value.Length > 1) and (Value.EndsWith(PathDelim)) then
      FRootFolder := Value.Substring(0, Value.Length - 1)
    else
      FRootFolder := Value;
  end;
end;

procedure TWiRLFileSystemEngine.Startup;
begin
  inherited;
  FExpandedRootFolder := ExpandMacros(FRootFolder);
end;

end.
