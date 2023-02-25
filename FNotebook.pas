unit FNotebook;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, IOUtils,

  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Tabs, htmlcomp, Vcl.ExtCtrls,
  System.Generics.Collections,

  htmledit, System.Actions, Vcl.ActnList, Vcl.BaseImageCollection,
  VCL.TMSFNCTypes, Vcl.ComCtrls, Vcl.ToolWin, JvExComCtrls, JvToolBar,
  System.ImageList, Vcl.ImgList, Vcl.VirtualImageList, Vcl.ImageCollection,
  Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnMan, Vcl.ActnCtrls;

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
  private
    { Private declarations }
    zbiCurrentNotebook: ZeroBasedInteger;
    zbiCurrentPage: ZeroBasedInteger;
    AppDataDir: string;
    procedure LoadPage(zbiNewNotebook: ZeroBasedInteger;
                       zbiNewPage: ZeroBasedInteger = 0);
    function GetNotebookDir(zbiNotebook: ZeroBasedInteger = -1): string;
    procedure SavePage;
    procedure NextPage;
    procedure PrevPage;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

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
  HtTabSet1.SelectNext(false);
end;

procedure TForm1.actTabsNextExecute(Sender: TObject);
begin
  HtTabSet1.SelectNext(True);
end;

procedure TForm1.NextPage;
begin
  LoadPage(zbiCurrentNotebook, zbiCurrentPage + 1);
end;

procedure TForm1.PrevPage;
begin
  if zbiCurrentPage > 0 then
  begin
    LoadPage(zbiCurrentNotebook, zbiCurrentPage - 1);
  end;
end;

procedure TForm1.LoadPage(zbiNewNotebook: ZeroBasedInteger;
                          zbiNewPage: ZeroBasedInteger = 0);
var
  notebookDir: string;
  pageFile: string;
begin

  // To notify other events that we are loading
  zbiCurrentNotebook := -1;
  zbiCurrentPage := -1;

  // Ensure new notebook exists
  notebookDir := GetNotebookDir;
  notebookDir := Format('%s\Notebook%d\', [AppDataDir, zbiNewNotebook + 1]);
  TDirectory.CreateDirectory(notebookDir);

  // Load new notebook from page 1 for now, until we have proper page handling
  pageFile := Format('%s\Page%d.html', [notebookDir, zbiNewPage + 1]);
  if TFile.Exists(pageFile) then
  begin
    HtmlEditor1.LoadFromFile(pageFile);
  end
  else
  begin
    HtmlEditor1.SelectAll;
    HtmlEditor1.DeleteSelection;
  end;

  // Now set current notebook since we have finished loading
  zbiCurrentNotebook := zbiNewNotebook;
  zbiCurrentPage := zbiNewPage;
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

procedure TForm1.tSaveTimer(Sender: TObject);
begin
  SavePage;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SavePage;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  i: integer;
  editor: THtmlEditor;
begin
  zbiCurrentNotebook := 0;
  zbiCurrentPage := 0;
  // Crete database directory
  AppDataDir := Format('%s\nnsNotebook\', [TPath.GetDocumentsPath]);
  TDirectory.CreateDirectory(AppDataDir);

  LoadPage(0);
end;

procedure TForm1.HtTabSet1Change(Sender: TObject; NewTab: Integer;
  var AllowChange: Boolean);
begin
  SavePage;
  // Takes only the tab to load for now, defaults to page 1
  LoadPage(NewTab);
end;

end.
