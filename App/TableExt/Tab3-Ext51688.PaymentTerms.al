tableextension 51688 "ASL Payment Terms" extends "Payment Terms"
{
    fields
    {
        // Add changes to table fields here
        field(52004; "Payment Type"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
        field(52005; "Payment Method Type"; Option)
        {
            OptionMembers = " ",Credito,Contado;
        }
    }

    var
        myInt: Integer;
}