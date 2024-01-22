@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@EndUserText.label: 'Projection View for ZR_ZT_PRT_QUEUES'
@ObjectModel.semanticKey: [ 'Queue' ]
define root view entity ZC_ZT_PRT_QUEUES
  provider contract transactional_query
  as projection on ZR_ZT_PRT_QUEUES
{
  key Queue,
  Name,
  Plant,
  QueueUsage,
  LocalLastChangedAt
  
}
