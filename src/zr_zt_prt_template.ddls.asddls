@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: '##GENERATED Printing Template'
define root view entity ZR_ZT_PRT_TEMPLATE
  as select from zzt_prt_template as Template
{
  key uuid                      as UUID,
      template_name             as TemplateName,
      service_definition_name   as ServiceDefinitionName,
      is_external_provided_data as IsExternalProvidedData,
      @Semantics.largeObject:
      { mimeType: 'MimeType',
      fileName: 'FileName',
      contentDispositionPreference: #ATTACHMENT }
      template                  as Template,
      @Semantics.mimeType: true
      mime_type                 as MimeType,
      file_name                 as FileName,

      @Semantics.largeObject:
      { mimeType: 'XSDType',
      fileName: 'XSDFileName',
      contentDispositionPreference: #ATTACHMENT }
      xsd_file                  as XSDFile,
      @Semantics.mimeType: true
      xsd_type                  as XSDType,
      xsd_file_name             as XSDFileName,

      fmname                    as FMname,
      @Semantics.user.createdBy: true
      created_by                as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at                as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by           as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at           as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at     as LocalLastChangedAt

}
