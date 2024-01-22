@EndUserText.label: 'PrintQueueSingleton'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define root view entity ZI_PrintQueue_S
  as select from I_Language
    left outer join ZZT_PRT_QUEUES on 0 = 0
  composition [0..*] of ZI_PrintQueue as _PrintQueue
{
  key 1 as SingletonID,
  _PrintQueue,
  max( ZZT_PRT_QUEUES.LAST_CHANGED_AT ) as LastChangedAtMax,
  cast( '' as SXCO_TRANSPORT) as TransportRequestID,
  cast( 'X' as ABAP_BOOLEAN preserving type) as HideTransport
  
}
where I_Language.Language = $session.system_language
