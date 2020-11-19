pageextension 51210 "EB Posted Sales Credit Memo" extends "Posted Sales Credit Memo"
{
    layout
    {
        // Add changes to page layout here

        addafter("External Document No.")
        {
            field("EB Electronic Bill"; "EB Electronic Bill")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        addafter(IncomingDocument)
        {
            action(electronicCreditMemo)
            {
                ApplicationArea = All;
                Caption = 'Electronic Credit Memo', Comment = 'ESM="Nota de Cédito Electrónica"';
                Image = ElectronicDoc;
                RunObject = page "EB Electronic Bill Entries";
                RunPageLink = "EB Document No." = field("No."), "EB Document Type" = const("Credit Memo");
            }
        }
    }
}