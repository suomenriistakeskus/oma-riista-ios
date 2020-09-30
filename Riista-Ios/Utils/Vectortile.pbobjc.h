// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: vectortile.proto

// This CPP symbol can be defined to use imports that match up to the framework
// imports needed when using CocoaPods.
#if !defined(GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS)
 #define GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS 0
#endif

#if GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS
 #import <Protobuf/GPBProtocolBuffers.h>
#else
 #import "GPBProtocolBuffers.h"
#endif

#if GOOGLE_PROTOBUF_OBJC_VERSION < 30002
#error This file was generated by a newer version of protoc which is incompatible with your Protocol Buffer library sources.
#endif
#if 30002 < GOOGLE_PROTOBUF_OBJC_MIN_SUPPORTED_VERSION
#error This file was generated by an older version of protoc which is incompatible with your Protocol Buffer library sources.
#endif

// @@protoc_insertion_point(imports)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

CF_EXTERN_C_BEGIN

@class Tile_Feature;
@class Tile_Layer;
@class Tile_Value;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Enum Tile_GeomType

/** GeomType is described in section 4.3.4 of the specification */
typedef GPB_ENUM(Tile_GeomType) {
  Tile_GeomType_Unknown = 0,
  Tile_GeomType_Point = 1,
  Tile_GeomType_Linestring = 2,
  Tile_GeomType_Polygon = 3,
};

GPBEnumDescriptor *Tile_GeomType_EnumDescriptor(void);

/**
 * Checks to see if the given value is defined by the enum or was not known at
 * the time this source was generated.
 **/
BOOL Tile_GeomType_IsValidValue(int32_t value);

#pragma mark - VectortileRoot

/**
 * Exposes the extension registry for this file.
 *
 * The base class provides:
 * @code
 *   + (GPBExtensionRegistry *)extensionRegistry;
 * @endcode
 * which is a @c GPBExtensionRegistry that includes all the extensions defined by
 * this file and all files that it depends on.
 **/
@interface VectortileRoot : GPBRootObject
@end

#pragma mark - Tile

typedef GPB_ENUM(Tile_FieldNumber) {
  Tile_FieldNumber_LayersArray = 3,
};

@interface Tile : GPBMessage

@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<Tile_Layer*> *layersArray;
/** The number of items in @c layersArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger layersArray_Count;

@end

#pragma mark - Tile_Value

typedef GPB_ENUM(Tile_Value_FieldNumber) {
  Tile_Value_FieldNumber_StringValue = 1,
  Tile_Value_FieldNumber_FloatValue = 2,
  Tile_Value_FieldNumber_DoubleValue = 3,
  Tile_Value_FieldNumber_IntValue = 4,
  Tile_Value_FieldNumber_UintValue = 5,
  Tile_Value_FieldNumber_SintValue = 6,
  Tile_Value_FieldNumber_BoolValue = 7,
};

/**
 * Variant type encoding
 * The use of values is described in section 4.1 of the specification
 **/
@interface Tile_Value : GPBMessage

/** Exactly one of these values must be present in a valid message */
@property(nonatomic, readwrite, copy, null_resettable) NSString *stringValue;
/** Test to see if @c stringValue has been set. */
@property(nonatomic, readwrite) BOOL hasStringValue;

@property(nonatomic, readwrite) float floatValue;

@property(nonatomic, readwrite) BOOL hasFloatValue;
@property(nonatomic, readwrite) double doubleValue;

@property(nonatomic, readwrite) BOOL hasDoubleValue;
@property(nonatomic, readwrite) int64_t intValue;

@property(nonatomic, readwrite) BOOL hasIntValue;
@property(nonatomic, readwrite) uint64_t uintValue;

@property(nonatomic, readwrite) BOOL hasUintValue;
@property(nonatomic, readwrite) int64_t sintValue;

@property(nonatomic, readwrite) BOOL hasSintValue;
@property(nonatomic, readwrite) BOOL boolValue;

@property(nonatomic, readwrite) BOOL hasBoolValue;
@end

#pragma mark - Tile_Feature

typedef GPB_ENUM(Tile_Feature_FieldNumber) {
  Tile_Feature_FieldNumber_Id_p = 1,
  Tile_Feature_FieldNumber_TagsArray = 2,
  Tile_Feature_FieldNumber_Type = 3,
  Tile_Feature_FieldNumber_GeometryArray = 4,
};

/**
 * Features are described in section 4.2 of the specification
 **/
@interface Tile_Feature : GPBMessage

@property(nonatomic, readwrite) uint64_t id_p;

@property(nonatomic, readwrite) BOOL hasId_p;
/**
 * Tags of this feature are encoded as repeated pairs of
 * integers.
 * A detailed description of tags is located in sections
 * 4.2 and 4.4 of the specification
 **/
@property(nonatomic, readwrite, strong, null_resettable) GPBUInt32Array *tagsArray;
/** The number of items in @c tagsArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger tagsArray_Count;

/** The type of geometry stored in this feature. */
@property(nonatomic, readwrite) Tile_GeomType type;

@property(nonatomic, readwrite) BOOL hasType;
/**
 * Contains a stream of commands and parameters (vertices).
 * A detailed description on geometry encoding is located in
 * section 4.3 of the specification.
 **/
@property(nonatomic, readwrite, strong, null_resettable) GPBUInt32Array *geometryArray;
/** The number of items in @c geometryArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger geometryArray_Count;

@end

#pragma mark - Tile_Layer

typedef GPB_ENUM(Tile_Layer_FieldNumber) {
  Tile_Layer_FieldNumber_Name = 1,
  Tile_Layer_FieldNumber_FeaturesArray = 2,
  Tile_Layer_FieldNumber_KeysArray = 3,
  Tile_Layer_FieldNumber_ValuesArray = 4,
  Tile_Layer_FieldNumber_Extent = 5,
  Tile_Layer_FieldNumber_Version = 15,
};

/**
 * Layers are described in section 4.1 of the specification
 **/
@interface Tile_Layer : GPBMessage

/**
 * Any compliant implementation must first read the version
 * number encoded in this message and choose the correct
 * implementation for this version number before proceeding to
 * decode other parts of this message.
 **/
@property(nonatomic, readwrite) uint32_t version;

@property(nonatomic, readwrite) BOOL hasVersion;
@property(nonatomic, readwrite, copy, null_resettable) NSString *name;
/** Test to see if @c name has been set. */
@property(nonatomic, readwrite) BOOL hasName;

/** The actual features in this tile. */
@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<Tile_Feature*> *featuresArray;
/** The number of items in @c featuresArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger featuresArray_Count;

/** Dictionary encoding for keys */
@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<NSString*> *keysArray;
/** The number of items in @c keysArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger keysArray_Count;

/** Dictionary encoding for values */
@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<Tile_Value*> *valuesArray;
/** The number of items in @c valuesArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger valuesArray_Count;

/**
 * Although this is an "optional" field it is required by the specification.
 * See https://github.com/mapbox/vector-tile-spec/issues/47
 **/
@property(nonatomic, readwrite) uint32_t extent;

@property(nonatomic, readwrite) BOOL hasExtent;
@end

NS_ASSUME_NONNULL_END

CF_EXTERN_C_END

#pragma clang diagnostic pop

// @@protoc_insertion_point(global_scope)