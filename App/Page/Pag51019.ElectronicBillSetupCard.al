page 51019 "EB Electronic Bill Setup Card"
{
    PageType = Card;
    ApplicationArea = All;
    Caption = 'Electronic Bill Setup';
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
                }
                field("EB Company Name"; "EB Company Name")
                {
                    ApplicationArea = All;
                    Editable = "EB Electronic Sender";
                }
            }
            group(Parameters)
            {
                Caption = 'Parameters';
                Editable = "EB Electronic Sender";
                field("EB URI Service"; "EB URI Service")
                {
                    ApplicationArea = All;
                }
            }
            group(Functions)
            {
                Caption = 'Functions';
                Editable = "EB Electronic Sender";
                field("EB Invoice"; "EB Invoice")
                {
                    ApplicationArea = All;
                }
                field("EB Ticket"; "EB Ticket")
                {
                    ApplicationArea = All;
                }
                field("EB Credit Note"; "EB Credit Note")
                {
                    ApplicationArea = All;
                }
                field("EB Debit Note"; "EB Debit Note")
                {
                    ApplicationArea = All;
                }
                field("EB Retention"; "EB Retention")
                {
                    ApplicationArea = All;
                }
                field("EB Voided Document"; "EB Voided Document")
                {
                    ApplicationArea = All;
                }
                field("EB Summary Documents"; "EB Summary Documents")
                {
                    ApplicationArea = All;
                }
                field("EB Validate Summary Document"; "EB Validate Summary Document")
                {
                    ApplicationArea = All;
                }
                field("EB Get PDF"; "EB Get PDF")
                {
                    ApplicationArea = All;
                }
                field("EB Get Ticket Status"; "EB Get Ticket Status")
                {
                    ApplicationArea = All;
                }
                field("EB Get QR"; "EB Get QR")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
            }
            group(Detractions)
            {
                Caption = 'Detractions';
                Editable = "EB Electronic Sender";
                field("EB Detraction Code"; "EB Detraction Code")
                {
                    ApplicationArea = All;
                }
                field("EB Detrac. Goods/Services Code"; "EB Detrac. Goods/Services Code")
                {
                    ApplicationArea = All;
                }
                field("EB Detrac. National Bank Code"; "EB Detrac. National Bank Code")
                {
                    ApplicationArea = All;
                }
            }
            group(Others)
            {
                Caption = 'Others';
                Editable = "EB Electronic Sender";
                field("EB Charge G/L Account"; "EB Charge G/L Account")
                {
                    ApplicationArea = All;
                }
                field("EB Charge/Dsct Detailed Code"; "EB Charge/Dsct Detailed Code")
                {
                    ApplicationArea = All;
                }
                field("EB National Bank Account No."; "EB National Bank Account No.")
                {
                    ApplicationArea = All;
                }
                field("EB Elec. Bill Resolution No."; "EB Elec. Bill Resolution No.")
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
            action(ElectronicBillEntries)
            {
                ApplicationArea = All;
                Caption = 'Entries';
                Image = EntriesList;
                RunObject = page "EB Electronic Bill Entries";
            }
            action(TestCorreos)
            {
                ApplicationArea = All;
                Caption = 'Probar cola de envío de correos';
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
                Caption = 'Test Electronic Bill';
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