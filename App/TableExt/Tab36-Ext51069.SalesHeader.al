tableextension 51069 "EB Sales Header" extends "Sales Header"
{
    fields
    {
        // Add changes to table fields here
        field(51100; "EB Type Operation Document"; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'Type Operation Document', Comment = 'ESM="Tipo Operación Doc."';
            TableRelation = "Legal Document"."Legal No." where("Option Type" = const("Catalogue SUNAT"), "Type Code" = const('51'));
            ValidateTableRelation = false;
        }
        field(51101; "EB NC/ND Description Type"; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'NC/ND Description Type';
            TableRelation = if ("Legal Document" = const('07')) "Legal Document"."Legal No." where("Option Type" = const("Catalogue SUNAT"), "Type Code" = const('09')) else
            if ("Legal Document" = const('08')) "Legal Document"."Legal No." where("Option Type" = const("Catalogue SUNAT"), "Type Code" = const('10'));
        }
        field(51102; "EB NC/ND Support Description"; Text[200])
        {
            DataClassification = ToBeClassified;
            Caption = 'NC/ND Support Description';
        }
        field(51103; "EB TAX Ref. Document Type"; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'TAX Ref. Document Type', Comment = 'ESM="Tipo Doc. Ref. IVA"';
            TableRelation = "Legal Document"."Legal No." where("Option Type" = const("Catalogue SUNAT"), "Type Code" = const('12'));
            ValidateTableRelation = false;
        }
        field(51104; "EB Electronic Bill"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Electronic Bill', Comment = 'ESM="Factura Electrónica"';
            trigger OnValidate()
            begin
                SetPostingSerieNo();
            end;
        }
        field(51105; "EB Language Invoice"; Option)
        {
            DataClassification = ToBeClassified;
            Caption = 'Language', Comment = 'ESM="Lenguaje"';
            OptionMembers = Spanish,English;
            OptionCaption = 'Spanish,English', Comment = 'ESM="Español,Ingles"';
        }
        field(51106; "EB Motive discount code"; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'Motive discount code', Comment = 'ESM="Cód. Motivo descuento"';
            TableRelation = "Legal Document"."Legal No." where("Option Type" = const("Catalogue SUNAT"), "Type Code" = const('53'), "Applied Level" = const(Header));
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                SalesLine: Record "Sales Line";
            begin
                if "EB Motive discount code" = '' then
                    exit;
                SalesLine.Reset();
                SalesLine.SetRange("Document Type", Rec."Document Type");
                SalesLine.SetRange("Document No.", Rec."No.");
                if SalesLine.FindFirst() then
                    repeat
                        SalesLine.TestField("EB Motive discount code", '');
                    until SalesLine.Next() = 0;
            end;
        }
        field(51120; "Initial Advanced"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Initial Advanced', comment = 'ESM="Anticipo Inicial"';
        }
        field(51121; "Final Advanced"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Final Advanced', comment = 'ESM="Anticipo Final"';
        }
        field(51122; "Invoice Payment Advanced"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(51123; "Total Applied. Advance"; Decimal)
        {

            FieldClass = FlowField;
            CalcFormula = Sum("Sales Line"."Amount Advanced" where("Document No." = field("No.")));

        }
    }

    procedure ValidateAnticipo(VAR pSalesInvHeader: Record 112)
    var
        lclSalesLine: Record 37;
        lclSalesInvLine: Record 113;
        lclTotalAmountAdvance: Decimal;
        lclTotalNewAdvanceDocument: Decimal;
        lclSalesInvHeader: Record 112;
        lclGLSetup: Record "Setup Localization";
        lclCurrencyCode: Code[10];
        lclCounter: Integer;
        lclGLAccountCode: Code[20];
        lclTotalDescontado: Decimal;
        lclSalesInvLineDescontado: Record 113;
    begin
        lclGLAccountCode := '';
        lclGLSetup.GET;
        IF pSalesInvHeader."Currency Code" <> '' THEN BEGIN
            lclGLSetup.TESTFIELD("Account Advanced USD");
            lclGLAccountCode := lclGLSetup."Account Advanced USD";
        END ELSE BEGIN
            lclGLSetup.TESTFIELD("Account Advanced PEN");
            lclGLAccountCode := lclGLSetup."Account Advanced PEN";
        END;

        lclTotalAmountAdvance := 0;
        lclTotalNewAdvanceDocument := 0;
        lclTotalDescontado := 0;
        lclCounter := 0;
        lclCurrencyCode := '';
        //**Importe Inicial
        lclSalesInvLine.RESET;
        lclSalesInvLine.SETRANGE("Document No.", pSalesInvHeader."No.");
        IF lclSalesInvLine.FINDSET THEN
            REPEAT
                /*
                    lclSalesInvHeader.RESET;
                    //lclSalesInvHeader.SETRANGE("Tipo Extorno", lclSalesInvHeader."Tipo Extorno"::Normal);
                    lclSalesInvHeader.SETRANGE("Currency Code", pSalesInvHeader."Currency Code");
                    IF lclSalesInvHeader.FINDSET THEN BEGIN*/
                lclTotalAmountAdvance += lclSalesInvLine."Line Amount";
            //END;
            UNTIL lclSalesInvLine.NEXT = 0;
        //**Importe Descontado
        lclSalesInvLineDescontado.RESET;
        lclSalesInvLineDescontado.SETRANGE("EB No. Invoice Advanced", pSalesInvHeader."No.");
        IF lclSalesInvLineDescontado.FINDSET THEN
            REPEAT
                lclTotalDescontado += lclSalesInvLineDescontado."Line Amount";
            UNTIL lclSalesInvLineDescontado.NEXT = 0;

        lclSalesLine.RESET;
        lclSalesLine.SETRANGE("Document No.", Rec."No.");
        IF lclSalesLine.FINDSET THEN
            REPEAT
                lclTotalNewAdvanceDocument += lclSalesLine."Line Amount";
                lclCounter += 1;
            UNTIL lclSalesLine.NEXT = 0;

        //BEGIN @CCL:11::12::17
        //Se agreg¢ el absoluto a lclTotalDescontado
        IF ((lclTotalAmountAdvance - lclTotalDescontado) > 0) AND (lclTotalNewAdvanceDocument > 0) THEN BEGIN
            IF (lclTotalAmountAdvance - ABS(lclTotalDescontado)) < lclTotalNewAdvanceDocument THEN BEGIN
                InsertSalesLineAnticipo((lclTotalAmountAdvance - ABS(lclTotalDescontado)), lclCounter + 1, pSalesInvHeader."No.", lclGLAccountCode);
                "Invoice Payment Advanced" := TRUE;
                MODIFY;
            END ELSE
                IF (lclTotalAmountAdvance - ABS(lclTotalDescontado)) = lclTotalNewAdvanceDocument THEN BEGIN
                    InsertSalesLineAnticipo(lclTotalNewAdvanceDocument, lclCounter + 1, pSalesInvHeader."No.", lclGLAccountCode);
                    "Invoice Payment Advanced" := FALSE;
                    "Final Advanced" := TRUE;
                    MODIFY;
                END ELSE
                    IF (lclTotalAmountAdvance - ABS(lclTotalDescontado)) > lclTotalNewAdvanceDocument THEN BEGIN
                        InsertSalesLineAnticipo(lclTotalNewAdvanceDocument, lclCounter + 1, pSalesInvHeader."No.", lclGLAccountCode);
                        "Final Advanced" := TRUE;
                        MODIFY;
                    END;
        END;
        //END @CCL:11::12::17
    END;

    LOCAL PROCEDURE InsertSalesLineAnticipo(pAmounAdvance: Decimal; pCounter: Integer; pInvoiceAdvanceNo: Code[20]; pGLAccount: Code[20]);
    VAR
        lclSalesLine: Record 37;
    BEGIN
        lclSalesLine.RESET;
        lclSalesLine.SETRANGE("Document No.", Rec."No.");
        lclSalesLine.SETRANGE("Document Type", Rec."Document Type");
        lclSalesLine.SETRANGE(Type, lclSalesLine.Type::"G/L Account");
        lclSalesLine.SETRANGE("EB No. Invoice Advanced", pInvoiceAdvanceNo);
        lclSalesLine.DELETEALL;

        lclSalesLine.INIT;
        lclSalesLine."Document No." := Rec."No.";
        lclSalesLine."Document Type" := Rec."Document Type";
        lclSalesLine."Line No." := pCounter * 100000;
        lclSalesLine.Type := lclSalesLine.Type::"G/L Account";
        lclSalesLine.VALIDATE("No.", pGLAccount);
        lclSalesLine."Location Code" := Rec."Location Code";
        lclSalesLine.VALIDATE(Quantity, -1);
        lclSalesLine.VALIDATE("Unit Price", pAmounAdvance);
        lclSalesLine."Amount Advanced" := pAmounAdvance;
        lclSalesLine.Validate("EB No. Invoice Advanced", pInvoiceAdvanceNo);
        lclSalesLine.INSERT;
    END;

    var
        table36: Record 37;
}