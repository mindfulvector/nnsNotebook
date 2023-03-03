unit FNotebook;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, IOUtils,
  htmledit, Crypt2, Global, System.ImageList, Vcl.ImgList, Vcl.VirtualImageList,
  Vcl.BaseImageCollection, Vcl.ImageCollection, System.Actions, Vcl.ActnList,
  Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnMan, Vcl.ExtCtrls, Vcl.ComCtrls,
  Vcl.ToolWin, Vcl.ActnCtrls, htmlcomp, Vcl.Controls, Vcl.Tabs,
  Vcl.Graphics, Vcl.Forms, Vcl.Dialogs,
  System.Generics.Collections,
  VCL.TMSFNCTypes, JvExComCtrls, JvToolBar, Vcl.StdCtrls, JvExStdCtrls,
  JvHtControls, Vcl.FileCtrl, FlCtrlEx,
  clRamLog, clRichLog;

type
  ZeroBasedInteger = integer;
  OneBasedInteger = integer;

  TForm1 = class(TForm)
    HtTabSet1: THtTabSet;
    HtmlEditor1: THtmlEditor;
    tSave: TTimer;
    actman: TActionManager;
    actPageNext: TAction;
    actPagePrev: TAction;
    ActionToolBar2: TActionToolBar;
    actNotebookNext: TAction;
    Action3: TAction;
    unvis: TPanel;
    imgcol: TImageCollection;
    imglst: TVirtualImageList;
    StatusBar1: TStatusBar;
    actPageExport: TAction;
    FileListBoxEx1: TFileListBoxEx;
    procedure FormCreate(Sender: TObject);
    procedure HtTabSet1Change(Sender: TObject; NewTab: Integer;
      var AllowChange: Boolean);
    procedure actTabsNextExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure tSaveTimer(Sender: TObject);
    procedure actPagePrevExecute(Sender: TObject);
    procedure actPageNextExecute(Sender: TObject);
    procedure Action3Execute(Sender: TObject);
    procedure actNotebookNextExecute(Sender: TObject);
    procedure actPageExportExecute(Sender: TObject);
    procedure HtmlEditor1UrlClick(Sender: TElement);
    procedure FileListBoxEx1Change(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure StatusBar1Click(Sender: TObject);
    procedure StatusBar1DblClick(Sender: TObject);
  private
    { Private declarations }
    bDebugMode: boolean;
    zbiCurrentNotebook: ZeroBasedInteger;
    zbiCurrentPage: ZeroBasedInteger;
    AppDataDir: string;
    richLog: TRichLog;
    ramLog: TRamLog;
    procedure Log(message: string);
    procedure LoadPage(zbiNewNotebook: ZeroBasedInteger;
                       zbiNewPage: ZeroBasedInteger = 0);
    function GetNotebookDir(zbiNotebook: ZeroBasedInteger = -1): string;
    procedure SavePage;
    procedure NextPage;
    procedure PrevPage;
    procedure ExportPage;
    procedure ImportPage;
    procedure LaunchBrowser(URL: string);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses ShellApi;

resourcestring
  StrUnableToLoadChikc = 'Unable to load chikcat.dll, error recieved was: "%s"';
  StrDefaultPage1_Begin = '<html><body><p><b><span style="color: #1F497D">';
  StrDefaultPage1_Line2 = '<p>Welcome to the Near North Notebook program!</span></b>&nbsp;<br/><small>aka <b>nnNotebook</b>!</small></p>';
  StrDefaultPage1_Line3 = '<p>Each Notebook tab above is a directory under Documents\nnNotebook. '+
    'Each one can contain unlimited pages.</p><p>It currently can switch between 10 notebooks, '+
    'auto saves every 5 minutes as well as on tab change and on close.</p>';
  StrDefaultPage1_Line4 = '<p>Rich text formatting is fairly robust, and '+
  'accessed by selecting a piece of text then using the '+
  '<span style="background-color: #FFFF00">popup</span>.</p>';
  StrDefaultPage1_Line5 = '<p>Additional features will be added soon, such as '+
  'file exporting, syncronization, and more.</p><p>&nbsp;</p>';
  StrDefaultPage1_Line6 = '<p style="text-align:justify;">Example: '+
  '<span style="background-color: #FFFF00">Select this text</span> with your '+
  'mouse to see the formatting toolbar</p><p>&nbsp;</p>';
  StrDefaultPage1_End = '</body></html>';

const STATUSPANEL_STATE: integer = 0;
const STATUSPANEL_CURRENT_LOCATION: integer = 1;

procedure TForm1.actPageExportExecute(Sender: TObject);
begin
  ExportPage;
end;

procedure TForm1.actPageNextExecute(Sender: TObject);
begin
  NextPage;
end;

procedure TForm1.actPagePrevExecute(Sender: TObject);
begin
  PrevPage;
end;

procedure TForm1.Action3Execute(Sender: TObject);
begin
  HtTabSet1.SelectNext(true);
end;

procedure TForm1.actNotebookNextExecute(Sender: TObject);
begin
  SavePage;
  HtTabSet1.SelectNext(false);
end;

procedure TForm1.actTabsNextExecute(Sender: TObject);
begin
  SavePage;
  HtTabSet1.SelectNext(True);
end;

procedure TForm1.NextPage;
begin
  SavePage;
  LoadPage(zbiCurrentNotebook, zbiCurrentPage + 1);
end;

procedure TForm1.ExportPage;
begin

end;

procedure TForm1.ImportPage;
begin

end;

procedure TForm1.PrevPage;
begin
  SavePage;
  if zbiCurrentPage > 0 then
  begin
    LoadPage(zbiCurrentNotebook, zbiCurrentPage - 1);
  end;
end;

procedure TForm1.Log(message: string);
begin
  ramLog.AddInfo('[' + DateTimeToStr(Now) + '] ' + message);
  if bDebugMode then
    StatusBar1.Panels[STATUSPANEL_STATE].Text := message;
end;

procedure TForm1.LoadPage(zbiNewNotebook: ZeroBasedInteger;
                          zbiNewPage: ZeroBasedInteger = 0);
var
  notebookDir: string;
  pageFile: string;
begin
  // If off, log lines don't appear in status bar
  bDebugMode := false;

  // Temporarily set the new notebook and page for directory creation
  zbiCurrentNotebook := zbiNewNotebook;
  zbiCurrentPage := zbiNewPage;

  // Ensure new notebook directory exists
  notebookDir := GetNotebookDir;
  notebookDir := Format('%sNotebook%d', [AppDataDir, zbiNewNotebook + 1]);
  TDirectory.CreateDirectory(notebookDir);

  if not FileListBoxEx1.Directory.ToUpper.Equals(notebookDir.ToUpper) then
  begin
    Log('New directory selected, loading file list: "'
        +FileListBoxEx1.Directory.ToUpper + '" != "'
        +notebookDir.ToUpper + '"');
    FileListBoxEx1.Directory := notebookDir;
  end;

  // Determine the page file
  pageFile := Format('%s\Page%d.html', [notebookDir, zbiNewPage + 1]);

  // To notify other events that we are loading, set both values to -1
  // so that other events don't accidentally replace something when
  // we start modifying values in a moment
  zbiCurrentNotebook := -1;
  zbiCurrentPage := -1;

  // Check if the page file we calculated above exists or not, then either
  // load it or clear the editor. On first start of the program, load
  // default text into Notebook 1, Page 1.
  if TFile.Exists(pageFile) then
  begin
    HtmlEditor1.LoadFromFile(pageFile);
  end
  else
  begin
    HtmlEditor1.SelectAll;
    HtmlEditor1.DeleteSelection;
    if (zbiNewNotebook = 0) and (zbiNewPage = 0) then
    begin
      HtmlEditor1.LoadFromString(
StrDefaultPage1_Begin+
StrDefaultPage1_Line2+
StrDefaultPage1_Line3+
StrDefaultPage1_Line4+
StrDefaultPage1_Line5+
StrDefaultPage1_Line6+
StrDefaultPage1_End)
    end;

  end;

  // Now set current notebook since we have finished loading
  zbiCurrentNotebook := zbiNewNotebook;
  zbiCurrentPage := zbiNewPage;

  Statusbar1.Panels[STATUSPANEL_CURRENT_LOCATION].Text := (
    Format('Notebook %d, page %d',
      [zbiCurrentNotebook + 1, zbiCurrentPage + 1]));
end;

function TForm1.GetNotebookDir(zbiNotebook: ZeroBasedInteger): string;
begin
  if zbiNotebook = -1 then zbiNotebook := zbiCurrentNotebook;

  // Ensure current notebook dir exists
  Result := Format('%s\Notebook%d\', [AppDataDir, zbiNotebook + 1]);
  TDirectory.CreateDirectory(Result);
end;

procedure TForm1.SavePage;
var
  notebookDir: string;
begin
  notebookDir := GetNotebookDir;
  // Save current page to directory above
  HtmlEditor1.SavetoFile(Format('%s\Page%d.html', [notebookDir, zbiCurrentPage + 1]));
end;

procedure TForm1.StatusBar1Click(Sender: TObject);
begin
  if richLog.Visible then
  begin
    bDebugMode := false;
    richLog.Visible := false;
  end else begin
    bDebugMode := not bDebugMode;
  end;
  if bDebugMode then
    Log('Debug mode enabled. Click to disable. Double click to show full log view.')
  else
    Log('Debug mode disabled. Click to re-enable.');

end;

procedure TForm1.StatusBar1DblClick(Sender: TObject);
begin
  richLog.Visible := true;
  bDebugMode := true;
  if richLog.Visible then
    Log('Full log view enabled. Click status bar to disable')
  else
    Log('Full log view disabled.');
end;

procedure TForm1.LaunchBrowser(URL: string);
begin
  URL := StringReplace(URL, '"', '%22', [rfReplaceAll]);
  ShellExecute(0, 'open', PChar(URL), nil, nil, SW_SHOWNORMAL);
end;

procedure TForm1.tSaveTimer(Sender: TObject);
begin
  SavePage;
end;

procedure TForm1.FileListBoxEx1Change(Sender: TObject);
begin
  if (zbiCurrentNotebook > -1) and (FileListBoxEx1.ItemIndex > -1) then
    LoadPage(zbiCurrentNotebook, FileListBoxEx1.ItemIndex);
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SavePage;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  i: integer;
  editor: THtmlEditor;
  glob: HCkGlobal;
  success: boolean;
begin
  richLog := TRichLog.Create(self);
  richLog.SetParentComponent(self);
  richLog.Width := 200;
  richLog.Height := 200;
  richLog.ReadOnly := true;
  richLog.Visible := false;
  ramLog := TRamLog.Create;
  ramLog.RichLog := richLog;

  Log('Starting app');

  glob := CkGlobal_Create();
  success := CkGlobal_UnlockBundle(glob,'Anything for 30-day trial');
  if (success <> True) then
  begin
    ShowMessage(Format(StrUnableToLoadChikc, [CkGlobal__lastErrorText(glob)]));
    Exit;
  end;

  zbiCurrentNotebook := 0;
  zbiCurrentPage := 0;
  // Crete database directory
  AppDataDir := Format('%s\nnNotebook\', [TPath.GetDocumentsPath]);
  TDirectory.CreateDirectory(AppDataDir);

  LoadPage(0);
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  richLog.Top := StatusBar1.Top - richLog.Height;
  richLog.Width := self.Width;
  StatusBar1.Panels[STATUSPANEL_STATE].Width := Round(self.Width * 0.75);
end;

procedure TForm1.HtmlEditor1UrlClick(Sender: TElement);
begin
  LaunchBrowser(Sender['href']);
end;

procedure TForm1.HtTabSet1Change(Sender: TObject; NewTab: Integer;
  var AllowChange: Boolean);
begin
  SavePage;
  // Takes only the tab to load for now, defaults to page 1
  LoadPage(NewTab);
end;

end.
