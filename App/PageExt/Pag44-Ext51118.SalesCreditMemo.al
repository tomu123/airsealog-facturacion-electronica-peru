pageextension 51118 "EB Sales Credit Memo" extends "Sales Credit Memo"
{
    layout
    {
        // Add changes to page layout here
        addafter(LegalPropertyType)
        {
            group(EBInformation)
            {
                Editable = ShowElectronicInvoice;
                Visible = ShowElectronicInvoice;
                Caption = 'Electronic Bill', Comment = 'ESM="Facturación electrónica"';
                field("EB Electronic Bill"; "EB Electronic Bill")
                {
                    ApplicationArea = All;
                }
                field("EB Type Operation Document"; "EB Type Operation Document")
                {
                    ApplicationArea = All;
                    Editable = "EB Electronic Bill";
                }
                field("EB TAX Ref. Document Type"; "EB TAX Ref. Document Type")
                {
                    ApplicationArea = All;
                    Editable = "EB Electronic Bill";
                }
                field("EB NC/ND Description Type"; "EB NC/ND Description Type")
                {
                    ApplicationArea = All;
                    Caption = 'NC Description Type', Comment = 'ESM="Tipo descripción NC"';
                    Editable = "EB Electronic Bill";
                }
                field("EB NC/ND Support Description"; "EB NC/ND Support Description")
                {
                    ApplicationArea = All;
                    Caption = 'NC Support Description', Comment = 'ESM="Motivo Nota de crédito"';
                    Editable = "EB Electronic Bill";
                }
                field("EB Motive discount code"; "EB Motive discount code")
                {
                    ApplicationArea = All;
                    Editable = "EB Electronic Bill";
                }
            }
        }

        modify("Applies-to Doc. Type")
        {
            Visible = false;
        }
        modify("Applies-to Doc. No.")
        {
            Visible = false;
        }
        modify("Applies-to ID")
        {
            Visible = false;
        }
        addafter("VAT Registration No.")
        {
            field("Posting No. Series"; "Posting No. Series")
            {
                ApplicationArea = All;
            }
            field("Posting No."; "Posting No.")
            {
                ApplicationArea = All;

            }

        }
    }

    actions
    {
        // Add changes to page actions here
    }

    trigger OnOpenPage()
    begin
        EBSetup.Get();
        ShowElectronicInvoice := EBSetup."EB Electronic Sender";
    end;

    var
        EBSetup: Record "EB Electronic Bill Setup";
        ShowElectronicInvoice: Boolean;
}