@class ObservationSpecimenMetadata;

@protocol MetadataManager

- (BOOL)hasObservationMetadata;
- (ObservationSpecimenMetadata*) getObservationMetadataForSpecies:(NSInteger)speciesCode;

@end
