@EndUserText.label: 'Maintain PrintQueue'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
define view entity ZC_PrintQueue
  as projection on ZI_PrintQueue
{
  key Queue,
  Name,
  Plant,
  QueueUsage,
  CreatedBy,
  CreatedAt,
  LastChangedBy,
  LastChangedAt,
  @Consumption.hidden: true
  LocalLastChangedAt,
  @Consumption.hidden: true
  SingletonID,
  _PrintQueueAll : redirected to parent ZC_PrintQueue_S
  
}
