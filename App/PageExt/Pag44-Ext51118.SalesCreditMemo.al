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
                Caption = 'Electronic Bill', Comment = 'ESM="Factura electrónica"';
                field("EB Electronic Bill"; "EB Electronic Bill")
                {
                    ApplicationArea = All;
                    Caption = 'Electronic Bill', Comment = 'ESM="Factura electrónica"';
                }
                field("EB Type Operation Document"; "EB Type Operation Document")
                {
                    ApplicationArea = All;
                    Caption = 'Type Operation Document', Comment = 'ESM="Tipo Operación Documento"';
                    Editable = "EB Electronic Bill";
                }
                field("EB TAX Ref. Document Type"; "EB TAX Ref. Document Type")
                {
                    ApplicationArea = All;
                    Caption = 'TAX Ref. Document Type', Comment = 'ESM="Tipo Doc. Tributario Ref."';
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