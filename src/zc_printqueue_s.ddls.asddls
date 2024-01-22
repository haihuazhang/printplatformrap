@EndUserText.label: 'Maintain PrintQueueSingleton'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: [ 'SingletonID' ]
define root view entity ZC_PrintQueue_S
  provider contract transactional_query
  as projection on ZI_PrintQueue_S
{
  key SingletonID,
  LastChangedAtMax,
  TransportRequestID,
  HideTransport,
  _PrintQueue : redirected to composition child ZC_PrintQueue
  
}
