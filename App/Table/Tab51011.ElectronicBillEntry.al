table 51011 "EB Electronic Bill Entry"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(51000; "EB Document Type"; Option)
        {
            DataClassification = ToBeClassified;
            Caption = 'Document Type';
            OptionMembers = " ",Invoice,"Credit Memo",Retention;
            OptionCaption = ' ,Invoice,Credit Memo,Retention';
        }
        field(51001; "EB Document No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Document No.';
        }
        field(51002; "EB Legal Document"; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'Legal Document';
            TableRelation = "Legal Document"."Legal No.";
        }
        field(51003; "EB Ship Status"; Option)
        {
            DataClassification = ToBeClassified;
            Caption = 'Ship Status';
            OptionMembers = "UnSent",Succes,"In Process","Process with Errors";
            OptionCaption = 'UnSent,Succes,In Process,Process with Errors';
        }
        field(51004; "EB XML Sender Exists"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'XML Sender Exists';
        }
        field(51005; "EB XML Sender Blob"; Blob)
        {
            DataClassification = ToBeClassified;
            Caption = 'XML Sender Blob';
        }
        field(51008; "EB Response Text"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'Response Text';
        }
        field(51009; "EB Last Modify Date"; DateTime)
        {
            DataClassification = ToBeClassified;
            Caption = 'Last Modify Date';
        }
        field(51010; "EB Last Modify User Id."; Code[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Last Modify User Id.';
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(51011; "EB Legal Status Code"; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'Legal Status Code';
        }
        field(51012; "EB Qr Exists"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'XML Qr Exists';
        }
        field(51013; "EB Qr Blob"; Blob)
        {
            DataClassification = ToBeClassified;
            Caption = 'XML Qr Blob';
        }
    }

    keys
    {
        key(PK; "EB Document Type", "EB Document No.", "EB Legal Document")
        {
            Clustered = true;
        }
    }

    var

        FileIsNotExist: Label 'The File is not exists.', comment = 'ESM="El archivo no existe"';
        DialogTitle: Label 'Download File', comment = 'ESM="Descargar archivo"';
        MsgEmptyEntry: Label 'There is no entry identified with document %1 and type %2.', comment = 'ESM="No hay ninguna entrada identificada con el documento %1 y el tipo %2."';
    //FileIsNotExist: TextConst ENU = 'The File is not exists.';
    //DialogTitle: TextConst ENU = 'Download File';
    //MsgEmptyEntry: TextConst ENU = 'There is no entry identified with document %1 and type %2.';

    trigger OnInsert()
    begin

    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

    procedure InsertEBEntryRecord(DocumentType: Option; DocumentNo: Code[20]; LegalDocument: Code[10]; ShipStatus: Option; LegalStatusCode: Code[10]; ResponseText: Text; var TempBlobXML: Codeunit "Temp Blob"; var TempBlobQr: Codeunit "Temp Blob"; ModifyStatusAndQR: Boolean): Integer //var SenderXMLInStream: InStream; QrInStream: InStream;
    var
        EBEntry: Record "EB Electronic Bill Entry";
        NextEntryNo: Integer;
        SenderXMLInStream: InStream;
        QrInStream: InStream;
        SenderXMLOutStream: OutStream;
        QrOutStream: OutStream;
        FileName: Text;
        FileText: Text;
        FullFileText: Text;
    begin
        EBEntry.Reset();
        EBEntry.SetRange("EB Document Type", DocumentType);
        EBEntry.SetRange("EB Document No.", DocumentNo);
        EBEntry.SetRange("EB Legal Document", LegalDocument);
        if EBEntry.IsEmpty then begin
            EBEntry.Init();
            EBEntry."EB Document Type" := DocumentType;
            EBEntry."EB Document No." := DocumentNo;
            EBEntry."EB Legal Document" := LegalDocument;
            EBEntry."EB Ship Status" := ShipStatus;
            EBEntry."EB Legal Status Code" := LegalStatusCode;

            TempBlobXML.CreateInStream(SenderXMLInStream);
            EBEntry."EB XML Sender Blob".CreateOutStream(SenderXMLOutStream);
            while not SenderXMLInStream.EOS do begin
                SenderXMLInStream.ReadText(FileText);
                SenderXMLOutStream.WriteText(FileText);
            end;
            //SenderXMLOutStream.WriteText(FullFileText);
            //CopyStream(SenderXMLOutStream, SenderXMLInStream);
            EBEntry.CalcFields("EB XML Sender Blob");
            EBEntry."EB XML Sender Exists" := EBEntry."EB XML Sender Blob".HasValue();

            TempBlobQr.CreateInStream(QrInStream);
            EBEntry."EB Qr Blob".CreateOutStream(QrOutStream);
            CopyStream(QrOutStream, QrInStream);
            EBEntry.CalcFields("EB Qr Blob");
            EBEntry."EB Qr Exists" := EBEntry."EB Qr Blob".HasValue();

            EBEntry."EB Last Modify Date" := CurrentDateTime;
            EBEntry."EB Last Modify User Id." := UserId;
            EBEntry."EB Response Text" := ResponseText;
            EBEntry.Insert();
        end else begin
            EBEntry.FindSet();
            if ModifyStatusAndQR then begin
                EBEntry."EB Ship Status" := ShipStatus;
                EBEntry."EB Legal Status Code" := LegalStatusCode;
            end;
            TempBlobXML.CreateInStream(SenderXMLInStream);
            EBEntry."EB XML Sender Blob".CreateOutStream(SenderXMLOutStream);
            CopyStream(SenderXMLOutStream, SenderXMLInStream);
            EBEntry.CalcFields("EB XML Sender Blob");
            EBEntry."EB XML Sender Exists" := EBEntry."EB XML Sender Blob".HasValue();
            EBEntry."EB Last Modify Date" := CurrentDateTime;
            EBEntry."EB Last Modify User Id." := UserId;
            EBEntry."EB Response Text" := ResponseText;
            EBEntry.Modify();
        end;
    end;

    procedure DownLoadSenderFile(var EBEntry: Record "EB Electronic Bill Entry")
    var
        NewFileInStream: InsTream;
        NewFileOutStream: OutStream;
        ToFileName: text[250];
        TempBlob: Codeunit "Temp Blob";
    begin
        EBEntry.CalcFields("EB XML Sender Blob");
        //If not EBEntry."EB XML Sender Blob".HasValue then begin
        //    Message(FileIsNotExist);
        //    exit;
        //end;
        EBEntry."EB XML Sender Blob".CreateInStream(NewFileInStream);
        ToFileName := StrSubstNo('%1-%2-%3.%4', Format(EBEntry."EB Document Type"), EBEntry."EB Document No.", EBEntry."EB Legal Document", 'xml');
        DownloadFromStream(NewFileInStream, DialogTitle, '', 'All Files (*.*)|*.*', ToFileName);
    end;

    /*procedure DownLoadPdfFile(var EBEntry: Record "EB Electronic Bill Entry")
    var
        NewFileInStream: InsTream;
        NewFileOutStream: OutStream;
        ToFileName: text[250];
        TempBlob: Codeunit "Temp Blob";
    begin
        EBEntry.CalcFields("EB Pdf Blob");
        If not EBEntry."EB Pdf Blob".HasValue then begin
            Message(FileIsNotExist);
            exit;
        end;
        EBEntry."EB Pdf Blob".CreateInStream(NewFileInStream);
        ToFileName := StrSubstNo('%1-%2-%3.%4', Format(EBEntry."EB Document Type"), EBEntry."EB Document No.", EBEntry."EB Legal Document", 'pdf');
        DownloadFromStream(NewFileInStream, DialogTitle, '', 'All Files (*.*)|*.*', ToFileName);
    end;

    procedure DownLoadLegalXmlFile(var EBEntry: Record "EB Electronic Bill Entry")
    var
        NewFileInStream: InsTream;
        NewFileOutStream: OutStream;
        ToFileName: text[250];
        TempBlob: Codeunit "Temp Blob";
    begin
        EBEntry.CalcFields("EB XML Legal Blob");
        If not EBEntry."EB XML Legal Blob".HasValue then begin
            Message(FileIsNotExist);
            exit;
        end;
        EBEntry."EB XML Legal Blob".CreateInStream(NewFileInStream);
        ToFileName := StrSubstNo('%1-%2-%3.%4', Format(EBEntry."EB Document Type"), EBEntry."EB Document No.", EBEntry."EB Legal Document", 'xml');
        DownloadFromStream(NewFileInStream, DialogTitle, '', 'All Files (*.*)|*.*', ToFileName);
    end;

    procedure DownLoadCdrFile(var EBEntry: Record "EB Electronic Bill Entry")
    var
        NewFileInStream: InsTream;
        NewFileOutStream: OutStream;
        ToFileName: text[250];
        TempBlob: Codeunit "Temp Blob";
    begin
        EBEntry.CalcFields("EB Cdr Blob");
        If not EBEntry."EB Cdr Blob".HasValue then begin
            Message(FileIsNotExist);
            exit;
        end;
        EBEntry."EB Cdr Blob".CreateInStream(NewFileInStream);
        ToFileName := StrSubstNo('%1-%2-%3.%4', Format(EBEntry."EB Document Type"), EBEntry."EB Document No.", EBEntry."EB Legal Document", 'xml');
        DownloadFromStream(NewFileInStream, DialogTitle, '', 'All Files (*.*)|*.*', ToFileName);
    end;*/

    procedure GetDocumentFile(FileType: Option)
    var
        EBMgt: Codeunit "EB Billing Management";
    begin
        //PDF = [0] | XML = [1] | CDR = [2]
        if IsEmpty then
            exit;
        EBMgt.GetDocumentFile(Rec, FileType);
    end;

    /*procedure UploadPdfFile(DocumentNo: Code[20]; LegalDocument: Code[10]; var TempBlobResp: Codeunit "Temp Blob")
    var
        EBEntry: Record "EB Electronic Bill Entry";
        PdfOutStream: OutStream;
        FileInStream: InStream;
        ToFileName: Text;
    begin
        EBEntry.Reset();
        EBEntry.SetRange("EB Document No.", DocumentNo);
        EBEntry.SetRange("EB Legal Document", LegalDocument);
        if EBEntry.FindSet() then begin
            TempBlobResp.CreateInStream(FileInStream);
            EBEntry."EB Pdf Blob".CreateOutStream(PdfOutStream);
            CopyStream(PdfOutStream, FileInStream);
            EBEntry.CalcFields("EB Pdf Blob");
            EBEntry."EB Pdf Exists" := EBEntry."EB Pdf Blob".HasValue();
            EBEntry.Modify();
            ToFileName := StrSubstNo('%1-%2-%3.%4', Format(EBEntry."EB Document Type"), EBEntry."EB Document No.", EBEntry."EB Legal Document", 'pdf');
            DownloadFromStream(FileInStream, DialogTitle, '', 'All Files (*.*)|*.*', ToFileName);
            //DownLoadPdfFile(EBEntry);
        end else
            Message(StrSubstNo(MsgEmptyEntry, DocumentNo, LegalDocument));
    end;

    procedure UploadLegalXmlFile(DocumentNo: Code[20]; LegalDocument: Code[10]; var FileInStream: InStream)
    var
        EBEntry: Record "EB Electronic Bill Entry";
        LegalXmlOutStream: OutStream;
    begin
        EBEntry.Reset();
        EBEntry.SetRange("EB Document No.", DocumentNo);
        EBEntry.SetRange("EB Legal Document", LegalDocument);
        if EBEntry.FindSet() then begin
            EBEntry."EB XML Legal Blob".CreateOutStream(LegalXmlOutStream);
            CopyStream(LegalXmlOutStream, FileInStream);
            EBEntry.CalcFields("EB XML Legal Blob");
            EBEntry."EB XML Legal Exists" := EBEntry."EB XML Legal Blob".HasValue();
            EBEntry.Modify();
            DownLoadLegalXmlFile(EBEntry);
        end else
            Message(StrSubstNo(MsgEmptyEntry, DocumentNo, LegalDocument));
    end;

    procedure UploadCdrFile(DocumentNo: Code[20]; LegalDocument: Code[10]; var FileInStream: InStream)
    var
        EBEntry: Record "EB Electronic Bill Entry";
        CdrOutStream: OutStream;
    begin
        EBEntry.Reset();
        EBEntry.SetRange("EB Document No.", DocumentNo);
        EBEntry.SetRange("EB Legal Document", LegalDocument);
        if EBEntry.FindSet() then begin
            EBEntry."EB Cdr Blob".CreateOutStream(CdrOutStream);
            CopyStream(CdrOutStream, FileInStream);
            EBEntry.CalcFields("EB Cdr Blob");
            EBEntry."EB Cdr Exists" := EBEntry."EB Cdr Blob".HasValue();
            EBEntry.Modify();
            DownLoadCdrFile(EBEntry);
        end else
            Message(StrSubstNo(MsgEmptyEntry, DocumentNo, LegalDocument));
    end;*/
}