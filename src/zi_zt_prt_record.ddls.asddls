@EndUserText.label: 'Record of Printing - Interface View'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define root view entity ZI_ZT_PRT_RECORD 
provider contract transactional_interface
as projection on ZR_ZT_PRT_RECORD
{
    key UUID,
    TemplateUUID,
    IsExternalProvidedData,
    ExternalProvidedData,
    ProvidedKeys,
    Pdf,
    MimeType,
    FileName,
    SendToPrintQueue,
    NumberOfCopies,
    PrintQueue,
    MimeTypeData,
    CreatedBy,
    CreatedAt,
    LastChangedBy,
    LastChangedAt,
    LocalLastChangedAt,
    /* Associations */
    _Template
}
