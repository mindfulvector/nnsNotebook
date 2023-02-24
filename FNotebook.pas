unit FNotebook;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, IOUtils,

  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Tabs, htmlcomp, Vcl.ExtCtrls,
  System.Generics.Collections,

  htmledit, System.Actions, Vcl.ActnList;

type
  TForm1 = class(TForm)
    HtTabSet1: THtTabSet;
    HtmlEditor1: THtmlEditor;
    Actions: TActionList;
    actTabsNext: TAction;
    actTabsPrev: TAction;
    tSave: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure HtTabSet1Change(Sender: TObject; NewTab: Integer;
      var AllowChange: Boolean);
    procedure actTabsNextExecute(Sender: TObject);
    procedure actTabsPrevExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure tSaveTimer(Sender: TObject);
  private
    { Private declarations }
    CurrentNotebook: integer;
    CurrentPage: integer;
    AppDataDir: string;
    procedure LoadPage(newNotebook: Integer);
    function GetNotebookDir(notebook: Integer = -1): string;
    procedure SavePage;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.actTabsNextExecute(Sender: TObject);
begin
  HtTabSet1.SelectNext(True);
end;

procedure TForm1.actTabsPrevExecute(Sender: TObject);
begin
  HtTabSet1.SelectNext(False);
end;

procedure TForm1.LoadPage(newNotebook: Integer);
var
  notebookDir: string;
  pageFile: string;
begin

  // To notify other events that we are loading
  CurrentNotebook := -1;

  // Ensure new notebook exists
  notebookDir := GetNotebookDir;
  notebookDir := Format('%s\Notebook%d\', [AppDataDir, newNotebook + 1]);
  TDirectory.CreateDirectory(notebookDir);

  // Load new notebook from page 1 for now, until we have proper page handling
  pageFile := Format('%s\Page%d.html', [notebookDir, CurrentPage + 1]);
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
  CurrentNotebook := newNotebook;
end;

function TForm1.GetNotebookDir(Notebook: Integer = -1): string;
begin
  if Notebook = -1 then Notebook := CurrentNotebook;

  // Ensure current notebook dir exists
  Result := Format('%s\Notebook%d\', [AppDataDir, Notebook + 1]);
  TDirectory.CreateDirectory(Result);
end;

procedure TForm1.SavePage;
var
  notebookDir: string;
begin
  notebookDir := GetNotebookDir;
  // Save current page to directory above
  HtmlEditor1.SavetoFile(Format('%s\Page%d.html', [notebookDir, CurrentPage + 1]));
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
  CurrentNotebook := 0;
  CurrentPage := 0;
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
