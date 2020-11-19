pageextension 51109 "EB Setup Localization" extends "Setup Localization"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
        addafter(MasterData)
        {
            action(EBSetup)
            {
                ApplicationArea = All;
                Caption = 'Electronic Bill Setup.', Comment = 'ESM="Conf. Facturación electrónica"';
                Image = Setup;
                RunObject = page "EB Electronic Bill Setup Card";
            }
            action(ProbarDoc)
            {
                ApplicationArea = All;
                Caption = 'Probar Doc.';
                Image = Setup;
                trigger OnAction()
                var
                    cu51015: Codeunit 51015;
                begin
                    // F001-000004

                    cu51015.PostElectronicDocument('F001-000004', '01')
                end;
            }
        }
    }

    var
        myInt: Integer;
}