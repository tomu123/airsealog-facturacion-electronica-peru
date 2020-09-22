page 51020 "EB Electronic Bill Entries"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;
    SourceTable = "EB Electronic Bill Entry";
    Caption = 'Electronic Bill Entries', comment = 'ESM="Movimientos Facturación Electrónica"';

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("EB Document Type"; "EB Document Type")
                {
                    ApplicationArea = All;
                    Caption = 'Document Type', comment = 'ESM="Tipo Documento"';
                }
                field("EB Document No."; "EB Document No.")
                {
                    ApplicationArea = All;
                    Caption = 'Document No.', comment = 'ESM="Nro. Documento"';
                }
                field("EB Legal Document"; "EB Legal Document")
                {
                    ApplicationArea = All;
                    Caption = 'Legal Document', comment = 'ESM="Documento Legal"';
                }
                field("EB Ship Status"; "EB Ship Status")
                {
                    ApplicationArea = All;
                    Caption = 'Ship Status', comment = 'ESM="Estado Envio"';
                }
                field("EB Legal Status Code"; "EB Legal Status Code")
                {
                    ApplicationArea = All;
                    Caption = 'Legal Status Status', comment = 'ESM="Código Estado"';
                }
                field("EB XML Sender Exists"; "EB XML Sender Exists")
                {
                    ApplicationArea = All;
                    Caption = 'XML Sender Exists File', comment = 'ESM="Existe Archivo XML Enviado"';
                }
                field("EB Response Text"; "EB Response Text")
                {
                    ApplicationArea = All;
                    Caption = 'Response Text', comment = 'ESM="Respuesta"';
                }
                field("EB Last Modify Date"; "EB Last Modify Date")
                {
                    ApplicationArea = All;
                    Caption = 'Last Modify Date', comment = 'ESM="Fecha últ. modificación"';
                }
                field("EB Last Modify User Id."; "EB Last Modify User Id.")
                {
                    ApplicationArea = All;
                    Caption = 'Last Modify User Id.', comment = 'ESM="Usuario últ. modificación"';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(DownloadFiles)
            {
                Caption = 'Download Files', comment = 'ESM="Descargar Archivos"';
                Image = TransmitElectronicDoc;
                action(InternalXml)
                {
                    ApplicationArea = All;
                    Caption = 'Internal XML', comment = 'ESM="XML Interno"';
                    Image = XMLFile;
                    trigger OnAction();
                    begin
                        if IsEmpty then
                            exit;
                        DownLoadSenderFile(Rec);
                    end;
                }
                action(PdfFile)
                {
                    ApplicationArea = All;
                    Caption = 'PDF File', comment = 'ESM="Archivo PDF"';
                    Image = SendAsPDF;
                    trigger OnAction();
                    begin
                        if IsEmpty then
                            exit;
                        GetDocumentFile(0);
                    end;
                }
                action(LegalXml)
                {
                    ApplicationArea = All;
                    Caption = 'Legal Xml', comment = 'ESM="XML Legal"';
                    Image = XMLFile;
                    trigger OnAction();
                    begin
                        if IsEmpty then
                            exit;
                        GetDocumentFile(1);
                    end;
                }
                action(CdrXml)
                {
                    ApplicationArea = All;
                    Caption = 'Cdr Xml', comment = 'ESM="CDR"';
                    Image = XMLFile;
                    trigger OnAction();
                    begin
                        if IsEmpty then
                            exit;
                        GetDocumentFile(2);
                    end;
                }
            }

            action(ResendDocument)
            {
                ApplicationArea = All;
                Caption = 'Resend Document', comment = 'ESM="Reenviar Documento"';
                trigger OnAction()
                var
                    EBMgt: Codeunit "EB Billing Management";
                begin
                    EBMgt.PostElectronicDocument("EB Document No.", "EB Legal Document");
                end;
            }
        }
    }
}

