@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: '##GENERATED ZZT_PRT_QUEUES'
define root view entity ZR_ZT_PRT_QUEUES
  as select from zzt_prt_queues
{
  key queue as Queue,
  name as Name,
  plant as Plant,
  @Consumption.valueHelpDefinition: [{ entity: { name: 'ZR_PRINTQUEUSAGE_VH', element: 'value_low' }}]
  queue_usage as QueueUsage,
  @Semantics.user.createdBy: true
  created_by as CreatedBy,
  @Semantics.systemDateTime.createdAt: true
  created_at as CreatedAt,
  @Semantics.user.lastChangedBy: true
  last_changed_by as LastChangedBy,
  @Semantics.systemDateTime.lastChangedAt: true
  last_changed_at as LastChangedAt,
  @Semantics.systemDateTime.localInstanceLastChangedAt: true
  local_last_changed_at as LocalLastChangedAt
  
}
