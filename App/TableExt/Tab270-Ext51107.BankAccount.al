tableextension 51107 "EB Bank Account" extends "Bank Account"
{
    fields
    {
        // Add changes to table fields here
        field(51003; "EB Show Electronic Bill"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Show Electronic Bill';

        }
    }
}