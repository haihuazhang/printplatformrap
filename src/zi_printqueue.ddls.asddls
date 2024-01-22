@EndUserText.label: 'PrintQueue'
@AccessControl.authorizationCheck: #CHECK
define view entity ZI_PrintQueue
  as select from ZZT_PRT_QUEUES
  association to parent ZI_PrintQueue_S as _PrintQueueAll on $projection.SingletonID = _PrintQueueAll.SingletonID
{
  key QUEUE as Queue,
  NAME as Name,
  PLANT as Plant,
  QUEUE_USAGE as QueueUsage,
  @Semantics.user.createdBy: true
  CREATED_BY as CreatedBy,
  @Semantics.systemDateTime.createdAt: true
  CREATED_AT as CreatedAt,
  @Semantics.user.lastChangedBy: true
  LAST_CHANGED_BY as LastChangedBy,
  @Semantics.systemDateTime.lastChangedAt: true
  LAST_CHANGED_AT as LastChangedAt,
  @Semantics.systemDateTime.localInstanceLastChangedAt: true
  LOCAL_LAST_CHANGED_AT as LocalLastChangedAt,
  1 as SingletonID,
  _PrintQueueAll
  
}
