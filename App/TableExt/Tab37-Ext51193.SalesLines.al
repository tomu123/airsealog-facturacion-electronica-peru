tableextension 51193 "EB Sales Lines" extends "Sales Line"
{
    fields
    {
        // Add changes to table fields here 51100..51200
        field(51100; "EB Motive discount code"; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'Motive discount code', Comment = 'ESM="Cód. Motivo descuento"';
            TableRelation = "Legal Document"."Legal No." where("Option Type" = const("Catalogue SUNAT"), "Type Code" = const('53'), "Applied Level" = const(Line));

            trigger OnValidate()
            var
                SalesHeader: Record "Sales Header";
            begin
                if "EB Motive discount code" = '' then
                    exit;
                SalesHeader.Get("Document Type", "Document No.");
                SalesHeader.TestField("EB Motive discount code", '');
            end;

        }
        field(51101; "EB No. Invoice Advanced"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'No. Invoice Advanced', Comment = 'ESM="No. factura anticipo"';
            //TableRelation = "Sales Invoice Header" where("Invoice Payment Advanced" = const(true), "Bill-to Customer No." = field("Bill-to Customer No."));
            trigger OnValidate()
            var
                DimMgt: Codeunit DimensionManagement;
                DimSetEntry: Record "Dimension Set Entry";
                DimSetEntryTemp: Record "Dimension Set Entry" temporary;
                DimValue: Record "Dimension Value";
            begin
                Clear(DimSetEntryTemp);
                clear(DimValue);
                //Debes de definir una dimensión en la tabla localizado "Advance Dimension Code"
                //ANTICIPO Nombre dimension
                //Dimensión set id diferente de 0
                if "Dimension Set ID" <> 0 then begin
                    if "EB No. Invoice Advanced" = '' then begin
                        DimSetEntry.Reset();
                        DimSetEntry.SetRange("Dimension Set ID", "Dimension Set ID");
                        DimSetEntry.SetRange("Dimension Code", 'ANTICIPO');
                        if DimSetEntry.FindFirst() then
                            DimSetEntry.Delete();
                    end;
                    DimValue.Reset();
                    DimValue.SetRange("Dimension Code", 'ANTICIPO');
                    DimValue.SetRange(Code, "EB No. Invoice Advanced");
                    if not DimValue.FindSet() then begin
                        DimValue.Init();
                        DimValue.Validate("Dimension Code", 'ANTICIPO');
                        DimValue.Validate(code, "EB No. Invoice Advanced");
                        DimValue.Name := 'Factura ' + "EB No. Invoice Advanced";
                        DimValue.Insert();
                    end;

                    DimSetEntry.Reset();
                    DimSetEntry.SetRange("Dimension Set ID", "Dimension Set ID");
                    if DimSetEntry.FindFirst() then
                        repeat
                            DimSetEntryTemp.Init();
                            DimSetEntryTemp.TransferFields(DimSetEntry, true);
                            DimSetEntryTemp.Insert();
                        until DimSetEntry.Next() = 0;

                    if "EB No. Invoice Advanced" <> '' then begin
                        DimSetEntryTemp.Init();
                        DimSetEntryTemp."Dimension Set ID" := "Dimension Set ID";
                        DimSetEntryTemp.Validate("Dimension Code", 'ANTICIPO');
                        DimSetEntryTemp.Validate("Dimension Value Code", "EB No. Invoice Advanced");
                        DimSetEntryTemp.Insert();
                    end;

                    DimSetEntryTemp.Reset();
                    "Dimension Set ID" := DimMgt.GetDimensionSetID(DimSetEntryTemp);
                end;
            end;
        }
        field(51102; "Account Advanced"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Account Advanced', Comment = 'ESM="Cuenta de anticipos"';
        }
        field(51103; "Amount Advanced"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Amount Advanced', Comment = 'ESM="Importe Anticipo"';
        }
    }

    var
        myInt: Integer;
}