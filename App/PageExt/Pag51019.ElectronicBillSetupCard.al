page 51019 "EB Electronic Bill Setup Card"
{
    PageType = Card;
    ApplicationArea = All;
    Caption = 'Electronic Bill Setup', Comment = 'ESM="Configuración de facturación electrónica"';
    UsageCategory = Administration;
    SourceTable = "EB Electronic Bill Setup";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("EB Electronic Sender"; "EB Electronic Sender")
                {
                    ApplicationArea = All;
                    Caption = 'Electronic Sender', comment = 'ESM="Emisor Electrónico"';
                }
                field("EB Company Name"; "EB Company Name")
                {
                    ApplicationArea = All;
                    Editable = "EB Electronic Sender";
                    Caption = 'Company Name', comment = 'ESM="Empresa"';
                }
            }
            group(Parameters)
            {
                Caption = 'Parameters', comment = 'ESM="Parámetros"';
                Editable = "EB Electronic Sender";
                field("EB URI Service"; "EB URI Service")
                {
                    ApplicationArea = All;
                    Caption = 'URI Service', comment = 'ESM="URI Servicio de Facturación"';
                }
            }
            group(Functions)
            {
                Caption = 'Functions', comment = 'ESM="Funciones"';
                Editable = "EB Electronic Sender";
                field("EB Invoice"; "EB Invoice")
                {
                    ApplicationArea = All;
                    Caption = 'Invoice', comment = 'ESM="Factura"';
                }
                field("EB Ticket"; "EB Ticket")
                {
                    ApplicationArea = All;
                    Caption = 'Ticket', comment = 'ESM="Boleta"';
                }
                field("EB Credit Note"; "EB Credit Note")
                {
                    ApplicationArea = All;
                    Caption = 'Credit Memo', comment = 'ESM="Nota de Crédito"';
                }
                field("EB Debit Note"; "EB Debit Note")
                {
                    ApplicationArea = All;
                    Caption = 'Debit Memo', comment = 'ESM="Nota de Débito"';
                }
                field("EB Retention"; "EB Retention")
                {
                    ApplicationArea = All;
                    Caption = 'Retention', comment = 'ESM="Retención"';
                }
                field("EB Voided Document"; "EB Voided Document")
                {
                    ApplicationArea = All;
                    Caption = 'Voided Document', comment = 'ESM="Comunicación de Baja"';
                }
                field("EB Summary Documents"; "EB Summary Documents")
                {
                    ApplicationArea = All;
                    Caption = 'Summary Documents', comment = 'ESM="Resumen Diario"';
                }
                field("EB Validate Summary Document"; "EB Validate Summary Document")
                {
                    ApplicationArea = All;
                    Caption = 'Validate Summary Document', comment = 'ESM="Validar Resumen Diario"';
                }
                field("EB Get PDF"; "EB Get PDF")
                {
                    ApplicationArea = All;
                    Caption = 'Get PDF', comment = 'ESM="Obtener PDF"';
                }
                field("EB Get Ticket Status"; "EB Get Ticket Status")
                {
                    ApplicationArea = All;
                    Caption = 'Ticket Status', comment = 'ESM="Estado del Ticket"';

                }
                field("EB Get QR"; "EB Get QR")
                {
                    ApplicationArea = All;
                    Caption = 'Get QR', comment = 'ESM="Obtener Código QR"';
                    Visible = false;
                }
            }
            group(Detractions)
            {
                Caption = 'Detractions', comment = 'ESM="Detracciones"';
                Editable = "EB Electronic Sender";
                field("EB Detraction Code"; "EB Detraction Code")
                {
                    ApplicationArea = All;
                    Caption = 'Detraction Code', comment = 'ESM="Código Detracción"';
                }
                field("EB Detrac. Goods/Services Code"; "EB Detrac. Goods/Services Code")
                {
                    ApplicationArea = All;
                    Caption = 'Detrac. Goods/Services Code', comment = 'ESM="Bien o Servicio de Detracción"';
                }
                field("EB Detrac. National Bank Code"; "EB Detrac. National Bank Code")
                {
                    ApplicationArea = All;
                    Caption = 'EnglishText', comment = 'ESM="Código Detracción de Banco Nación"';
                }
            }
            group(Others)
            {
                Caption = 'Others', comment = 'ESM="Otros"';
                Editable = "EB Electronic Sender";
                field("EB Charge G/L Account"; "EB Charge G/L Account")
                {
                    ApplicationArea = All;
                    Caption = 'Charge G/L Account', comment = 'ESM="Cuenta Cargo "';

                }
                field("EB Charge/Dsct Detailed Code"; "EB Charge/Dsct Detailed Code")
                {
                    ApplicationArea = All;
                    Caption = 'Charge/Dsct Detailed Code', comment = 'ESM="Código Cargo/Descuento Detalle"';
                }
                field("EB National Bank Account No."; "EB National Bank Account No.")
                {
                    ApplicationArea = All;
                    Caption = 'National Bank Account No.', comment = 'ESM="Número Cuenta Banco Nación"';
                }
                field("EB Elec. Bill Resolution No."; "EB Elec. Bill Resolution No.")
                {
                    ApplicationArea = All;
                    Caption = 'Elec. Bill Resolution No.', comment = 'ESM="Nro. Resolución Facturación Electrónica"';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ElectronicBillEntries)
            {
                ApplicationArea = All;
                Caption = 'Entries', comment = 'ESM="Movimientos"';
                Image = EntriesList;
                RunObject = page "EB Electronic Bill Entries";
            }
            action(TestCorreos)
            {
                ApplicationArea = All;
                Caption = 'Test mailing queue', comment = 'ESM="Probar cola de envío de correos"';
                trigger OnAction()
                var
                    JobQueueEntry: Record "Job Queue Entry";
                    NotificationEntryDispatcher: Codeunit "Notification Entry Dispatcher";
                    DocumentMailing: Codeunit "Document-Mailing";
                begin
                    JobQueueEntry.Reset();
                    JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
                    JobQueueEntry.SetRange("Object ID to Run", 1509);
                    IF JobQueueEntry.FindFirst() THEN
                        NotificationEntryDispatcher.RUN(JobQueueEntry);
                end;
            }
            action(TestEBSetup)
            {
                ApplicationArea = All;
                Caption = 'Test Electronic Bill', comment = 'ESM="Prueba Facturación Electrónica"';
                trigger OnAction()
                var
                    EBMgt: Codeunit "EB Billing Management";
                begin
                    EBMgt.PostElectronicDocument('F122-00000003', '01');
                end;
            }
        }
    }



    trigger OnOpenPage()
    begin
        Reset();
        if not FindFirst() then begin
            Init();
            "EB Primary Key" := '';
            Insert();
        end;
    end;
}