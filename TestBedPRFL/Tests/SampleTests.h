//
//  SampleTests.h
//  TestBed
//
//  Created by Apple User on 11/17/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Tests.h"


@interface SampleTests : Tests {
}
@end

@interface TestFordCars : SampleTests {
}
@end

@interface TestToyotaCars : SampleTests {
}
@end

@interface TestBentleyCars : SampleTests {
}
@end

@interface TestFordSUVs : TestFordCars {
}
@end

@interface TestFordSedans : TestFordCars {
}
@end

@interface TestToyotaSUVs : TestToyotaCars {
}
@end

@interface TestToyotaPassengerCars : TestToyotaCars {
}
@end
