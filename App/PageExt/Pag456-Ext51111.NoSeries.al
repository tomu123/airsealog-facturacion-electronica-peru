pageextension 51111 "EB No Series" extends "No. Series"
{
    layout
    {
        // Add changes to page layout here
        addbefore("Legal Document")
        {
            field("EB Electronic Bill"; "EB Electronic Bill")
            {
                ApplicationArea = All;
                Visible = ShowElectronicBill;
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
        ShowElectronicBill := EBSetup."EB Electronic Sender";
    end;

    var
        EBSetup: Record "EB Electronic Bill Setup";
        ShowElectronicBill: Boolean;
}