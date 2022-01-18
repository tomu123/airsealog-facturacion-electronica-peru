page 51020 "EB Electronic Bill Entries"
{
    PageType = List;
    ApplicationArea = All;
    Caption = 'Electronic Bill Entries', Comment = 'ESM="Mov. Facturación Electrónica"';
    PromotedActionCategories = 'New,Process,Report,Information,InternalControl', Comment = 'ESM="Nueavo,Proceso,Reporte,Información SUNAT,Control Interno"';
    UsageCategory = Lists;
    Editable = false;
    SourceTable = "EB Electronic Bill Entry";

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("EB Document Type"; "EB Document Type")
                {
                    ApplicationArea = All;
                }
                field("EB Document No."; "EB Document No.")
                {
                    ApplicationArea = All;
                }
                field("EB Legal Document"; "EB Legal Document")
                {
                    ApplicationArea = All;
                }
                field("EB Ship Status"; "EB Ship Status")
                {
                    ApplicationArea = All;
                }
                field("EB Legal Status Code"; "EB Legal Status Code")
                {
                    ApplicationArea = All;
                }
                field("EB XML Sender Exists"; "EB XML Sender Exists")
                {
                    ApplicationArea = All;
                }
                field("EB Response Text"; "EB Response Text")
                {
                    ApplicationArea = All;
                }
                field("EB Last Modify Date"; "EB Last Modify Date")
                {
                    ApplicationArea = All;
                }
                field("EB Last Modify User Id."; "EB Last Modify User Id.")
                {
                    ApplicationArea = All;
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
                Caption = 'Download Files', Comment = 'ESM="Descargar archivos"';
                Image = TransmitElectronicDoc;
                action(InternalXml)
                {
                    ApplicationArea = All;
                    Caption = 'Internal XML', Comment = 'ESM="Solicitud XML"';
                    Image = XMLFile;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    Scope = "Repeater";

                    trigger OnAction();
                    begin
                        if IsEmpty then
                            exit;
                        DownLoadSenderFile(Rec);
                        Message('Este documento XML solo es válido para temas de control interno y de testeo en Business Central.');
                    end;
                }
                action(ResponseXML)
                {
                    ApplicationArea = All;
                    Caption = 'Response XML', Comment = 'ESM="Respuesta XML"';
                    Image = XMLFile;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    Scope = "Repeater";

                    trigger OnAction();
                    begin
                        if IsEmpty then
                            exit;
                        DownLoadResponseFile(Rec);
                        Message('Este documento XML solo es válido para temas de control interno y de testeo en Business Central.');
                    end;
                }
                action(PdfFile)
                {
                    ApplicationArea = All;
                    Caption = 'PDF File', Comment = 'ESM="Representación PDF"';
                    Image = SendAsPDF;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    Scope = "Repeater";

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
                    Caption = 'Legal Xml', Comment = 'ESM="XML SUNAT"';
                    Image = XMLFile;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    Scope = "Repeater";

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
                    Caption = 'Cdr Xml', Comment = 'ESM="CDR XML"';
                    Image = XMLFile;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    Scope = "Repeater";

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
                Caption = 'Resend Document', Comment = 'ESM="Reenviar documento electrónico"';
                Image = SendElectronicDocument;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Scope = "Repeater";

                trigger OnAction()
                var
                    EBMgt: Codeunit "EB Billing Management";
                begin
                    EBMgt.PostElectronicDocument("EB Document No.", "EB Legal Document");
                end;
            }
            action(ResendDocumentCustomer)
            {
                ApplicationArea = All;
                Caption = 'Resend Document Electronic Cust', Comment = 'ESM="Reenviar documento electrónico Cliente"';
                Image = SendElectronicDocument;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Scope = "Repeater";

                trigger OnAction()
                var
                    EBMgt: Codeunit "EB Send Electronic Management";
                begin
                    if "EB Ship Status" = "EB Ship Status"::Succes then
                        EBMgt.SendElectronicDocument(Rec)
                    else
                        Error('Solo se pueden enviar los documentos con estado a SUNAT Enviado.');
                end;
            }
            action(ChangeElecBillEntryStatus)
            {
                ApplicationArea = All;
                Caption = 'Change Electronic Bill Entries Status', Comment = 'ESM="Cambiar Status de Mov Electronicos"';
                Image = SendElectronicDocument;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Scope = "Repeater";
                Visible = false;

                trigger OnAction()
                var
                    ElecBillEntry: Record "EB Electronic Bill Entry";
                begin
                    ElecBillEntry.Reset();
                    if ElecBillEntry.FindSet() then begin
                        repeat
                            ElecBillEntry."EB Status Send Doc. Cust" := ElecBillEntry."EB Status Send Doc. Cust"::Send;
                            ElecBillEntry.Modify();
                        until ElecBillEntry.Next() = 0;
                    end;
                end;
            }
        }
    }
}
