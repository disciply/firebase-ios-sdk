// Copyright 2017 Google
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import <XCTest/XCTest.h>

#import "FirebaseCommunity/FIRObjectSwizzler.h"
#import "FirebaseCommunity/FIRSwizzledObject.h"

@interface FIRObjectSwizzlerTest : XCTestCase

@end

@implementation FIRObjectSwizzlerTest

/** Exists just as a donor method. */
- (void)donorMethod {
}

- (void)testRetainedAssociatedObjects {
  NSObject *object = [[NSObject alloc] init];
  NSObject *associatedObject = [[NSObject alloc] init];
  size_t addressOfAssociatedObject = (size_t)&associatedObject;
  [FIRObjectSwizzler setAssociatedObject:object
                                     key:@"test"
                                   value:associatedObject
                             association:FIR_ASSOCIATION_RETAIN];
  associatedObject = nil;
  associatedObject = [FIRObjectSwizzler getAssociatedObject:object key:@"test"];
  XCTAssertEqual((size_t)&associatedObject, addressOfAssociatedObject);
  XCTAssertNotNil(associatedObject);
}

/** Tests that creating an object swizzler works. */
- (void)testObjectSwizzlerInit {
  NSObject *object = [[NSObject alloc] init];
  FIRObjectSwizzler *objectSwizzler = [[FIRObjectSwizzler alloc] initWithObject:object];
  XCTAssertNotNil(objectSwizzler);
}

/** Tests that you're able to swizzle an object. */
- (void)testSwizzle {
  NSObject *object = [[NSObject alloc] init];
  FIRObjectSwizzler *objectSwizzler = [[FIRObjectSwizzler alloc] initWithObject:object];
  XCTAssertEqual([object class], [NSObject class]);
  [objectSwizzler swizzle];
  XCTAssertNotEqual([object class], [NSObject class]);
  XCTAssertTrue([[object class] isSubclassOfClass:[NSObject class]]);
  XCTAssertTrue([object respondsToSelector:@selector(fpr_class)]);
}

/** Tests that swizzling a nil object fails. */
- (void)testSwizzleNil {
  NSObject *object = [[NSObject alloc] init];
  FIRObjectSwizzler *objectSwizzler = [[FIRObjectSwizzler alloc] initWithObject:object];
  XCTAssertEqual([object class], [NSObject class]);
  object = nil;
  XCTAssertThrows([objectSwizzler swizzle]);
}

/** Tests the ability to copy a selector from one class to the swizzled object's generated class. */
- (void)testCopySelectorFromClassIsClassSelectorAndSwizzle {
  NSObject *object = [[NSObject alloc] init];
  FIRObjectSwizzler *objectSwizzler = [[FIRObjectSwizzler alloc] initWithObject:object];
  [objectSwizzler copySelector:@selector(donorMethod) fromClass:[self class] isClassSelector:NO];
  XCTAssertFalse([object respondsToSelector:@selector(donorMethod)]);
  XCTAssertFalse([[object class] instancesRespondToSelector:@selector(donorMethod)]);
  [objectSwizzler swizzle];
  XCTAssertTrue([object respondsToSelector:@selector(donorMethod)]);
  // [object class] should return the original class, not the swizzled class.
  XCTAssertTrue(
      [[(FIRSwizzledObject *)object fpr_class] instancesRespondToSelector:@selector(donorMethod)]);
}

/** Tests that some helper methods are always added to swizzled objects. */
- (void)testCommonSelectorsAddedUponSwizzling {
  NSObject *object = [[NSObject alloc] init];
  FIRObjectSwizzler *objectSwizzler = [[FIRObjectSwizzler alloc] initWithObject:object];
  XCTAssertFalse([object respondsToSelector:@selector(fpr_class)]);
  [objectSwizzler swizzle];
  XCTAssertTrue([object respondsToSelector:@selector(fpr_class)]);
}

/** Tests that there's no retain cycle and that -dealloc causes unswizzling. */
- (void)testRetainCycleDoesntExistAndDeallocCausesUnswizzling {
  NSObject *object = [[NSObject alloc] init];
  FIRObjectSwizzler *objectSwizzler = [[FIRObjectSwizzler alloc] initWithObject:object];
  [objectSwizzler copySelector:@selector(donorMethod) fromClass:[self class] isClassSelector:NO];
  [objectSwizzler swizzle];
  // If objectSwizzler were used, the strong reference would make it live to the end of this test.
  // We want to make sure it dies when the object dies, hence the weak reference.
  __weak FIRObjectSwizzler *weakObjectSwizzler = objectSwizzler;
  objectSwizzler = nil;
  XCTAssertNotNil(weakObjectSwizzler);
  object = nil;
  XCTAssertNil(weakObjectSwizzler);
}

/** Tests the class get/set associated object methods. */
- (void)testClassSetAssociatedObjectCopy {
  NSObject *object = [[NSObject alloc] init];
  NSDictionary *objectToBeAssociated = [[NSDictionary alloc] init];
  [FIRObjectSwizzler setAssociatedObject:object
                                     key:@"fpr_key"
                                   value:objectToBeAssociated
                             association:FIR_ASSOCIATION_COPY];
  NSDictionary *returnedObject = [FIRObjectSwizzler getAssociatedObject:object key:@"fpr_key"];
  XCTAssertEqualObjects(returnedObject, objectToBeAssociated);
}

/** Tests the class get/set associated object methods. */
- (void)testClassSetAssociatedObjectAssign {
  NSObject *object = [[NSObject alloc] init];
  NSDictionary *objectToBeAssociated = [[NSDictionary alloc] init];
  [FIRObjectSwizzler setAssociatedObject:object
                                     key:@"fpr_key"
                                   value:objectToBeAssociated
                             association:FIR_ASSOCIATION_ASSIGN];
  NSDictionary *returnedObject = [FIRObjectSwizzler getAssociatedObject:object key:@"fpr_key"];
  XCTAssertEqualObjects(returnedObject, objectToBeAssociated);
}

/** Tests the class get/set associated object methods. */
- (void)testClassSetAssociatedObjectRetain {
  NSObject *object = [[NSObject alloc] init];
  NSDictionary *objectToBeAssociated = [[NSDictionary alloc] init];
  [FIRObjectSwizzler setAssociatedObject:object
                                     key:@"fpr_key"
                                   value:objectToBeAssociated
                             association:FIR_ASSOCIATION_RETAIN];
  NSDictionary *returnedObject = [FIRObjectSwizzler getAssociatedObject:object key:@"fpr_key"];
  XCTAssertEqualObjects(returnedObject, objectToBeAssociated);
}

/** Tests the class get/set associated object methods. */
- (void)testClassSetAssociatedObjectCopyNonatomic {
  NSObject *object = [[NSObject alloc] init];
  NSDictionary *objectToBeAssociated = [[NSDictionary alloc] init];
  [FIRObjectSwizzler setAssociatedObject:object
                                     key:@"fpr_key"
                                   value:objectToBeAssociated
                             association:FIR_ASSOCIATION_COPY_NONATOMIC];
  NSDictionary *returnedObject = [FIRObjectSwizzler getAssociatedObject:object key:@"fpr_key"];
  XCTAssertEqualObjects(returnedObject, objectToBeAssociated);
}

/** Tests the class get/set associated object methods. */
- (void)testClassSetAssociatedObjectRetainNonatomic {
  NSObject *object = [[NSObject alloc] init];
  NSDictionary *objectToBeAssociated = [[NSDictionary alloc] init];
  [FIRObjectSwizzler setAssociatedObject:object
                                     key:@"fpr_key"
                                   value:objectToBeAssociated
                             association:FIR_ASSOCIATION_RETAIN_NONATOMIC];
  NSDictionary *returnedObject = [FIRObjectSwizzler getAssociatedObject:object key:@"fpr_key"];
  XCTAssertEqualObjects(returnedObject, objectToBeAssociated);
}

/** Tests the swizzler get/set associated object methods. */
- (void)testSetGetAssociatedObjectCopy {
  NSObject *object = [[NSObject alloc] init];
  NSDictionary *associatedObject = [[NSDictionary alloc] init];
  FIRObjectSwizzler *swizzler = [[FIRObjectSwizzler alloc] initWithObject:object];
  [swizzler setAssociatedObjectWithKey:@"key"
                                 value:associatedObject
                           association:FIR_ASSOCIATION_COPY];
  NSDictionary *returnedObject = [swizzler getAssociatedObjectForKey:@"key"];
  XCTAssertEqualObjects(returnedObject, associatedObject);
}

/** Tests the swizzler get/set associated object methods. */
- (void)testSetGetAssociatedObjectAssign {
  NSObject *object = [[NSObject alloc] init];
  NSDictionary *associatedObject = [[NSDictionary alloc] init];
  FIRObjectSwizzler *swizzler = [[FIRObjectSwizzler alloc] initWithObject:object];
  [swizzler setAssociatedObjectWithKey:@"key"
                                 value:associatedObject
                           association:FIR_ASSOCIATION_ASSIGN];
  NSDictionary *returnedObject = [swizzler getAssociatedObjectForKey:@"key"];
  XCTAssertEqualObjects(returnedObject, associatedObject);
}

/** Tests the swizzler get/set associated object methods. */
- (void)testSetGetAssociatedObjectRetain {
  NSObject *object = [[NSObject alloc] init];
  NSDictionary *associatedObject = [[NSDictionary alloc] init];
  FIRObjectSwizzler *swizzler = [[FIRObjectSwizzler alloc] initWithObject:object];
  [swizzler setAssociatedObjectWithKey:@"key"
                                 value:associatedObject
                           association:FIR_ASSOCIATION_RETAIN];
  NSDictionary *returnedObject = [swizzler getAssociatedObjectForKey:@"key"];
  XCTAssertEqualObjects(returnedObject, associatedObject);
}

/** Tests the swizzler get/set associated object methods. */
- (void)testSetGetAssociatedObjectCopyNonatomic {
  NSObject *object = [[NSObject alloc] init];
  NSDictionary *associatedObject = [[NSDictionary alloc] init];
  FIRObjectSwizzler *swizzler = [[FIRObjectSwizzler alloc] initWithObject:object];
  [swizzler setAssociatedObjectWithKey:@"key"
                                 value:associatedObject
                           association:FIR_ASSOCIATION_COPY_NONATOMIC];
  NSDictionary *returnedObject = [swizzler getAssociatedObjectForKey:@"key"];
  XCTAssertEqualObjects(returnedObject, associatedObject);
}

/** Tests the swizzler get/set associated object methods. */
- (void)testSetGetAssociatedObjectRetainNonatomic {
  NSObject *object = [[NSObject alloc] init];
  NSDictionary *associatedObject = [[NSDictionary alloc] init];
  FIRObjectSwizzler *swizzler = [[FIRObjectSwizzler alloc] initWithObject:object];
  [swizzler setAssociatedObjectWithKey:@"key"
                                 value:associatedObject
                           association:FIR_ASSOCIATION_RETAIN_NONATOMIC];
  NSDictionary *returnedObject = [swizzler getAssociatedObjectForKey:@"key"];
  XCTAssertEqualObjects(returnedObject, associatedObject);
}

- (void)testSetGetAssociatedObjectWithoutProperAssociation {
  NSObject *object = [[NSObject alloc] init];
  NSDictionary *associatedObject = [[NSDictionary alloc] init];
  FIRObjectSwizzler *swizzler = [[FIRObjectSwizzler alloc] initWithObject:object];
  [swizzler setAssociatedObjectWithKey:@"key" value:associatedObject association:1337];
  NSDictionary *returnedObject = [swizzler getAssociatedObjectForKey:@"key"];
  XCTAssertEqualObjects(returnedObject, associatedObject);
}

@end