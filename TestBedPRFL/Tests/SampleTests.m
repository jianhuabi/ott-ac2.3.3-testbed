//
//  SampleTests.m
//  TestBed
//
//  Created by Apple User on 11/17/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SampleTests.h"
#import "TestObject.h"
#import "Tests.h"


@implementation SampleTests

#ifdef SAMPLE_TESTS

-(id)SampleTestRules:(OperationId)operation withView:(DetailViewController*)view
{
    id result = nil;
    
    switch (operation) {
        default:
            // raise an exception 
            break;
        case opid_getName:
            result = @"Sample Test Rules";
            break;
        case opid_getDescription:
            result = @"A sample test.";
            break;
        case opid_getTestType:
            result = [NSNumber numberWithShort:TestType_Automatic];
            break;
        case opid_runTest: {
            BOOL ret = YES;
            
            [self Log:@"Sample test rules!\n"];
            [NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
            result = [NSNumber numberWithBool:ret];
        }
            break;
    }
    
    return result;
}

AUTO_TEST_START(SampleTest1_HelloWorld, "Sample Test #1 (Hello world)", "One more test sample")
[self Log:@"Message from Test #1 - Hello world!\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END

AUTO_TEST_START(SampleTest2_HelloiPad, "Sample Test #2 (Hello iPad)", "One more test sample")
[self Log:@"Message from Test #2 - Hello iPad!\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END

AUTO_TEST_START(SampleTest3_HelloiPod, "Sample Test #3 (Hello iPod)", "One more test sample")
[self Log:@"Message from Test #3 - Hello iPod!\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END

AUTO_TEST_START(SampleTest4_HelloiPhone, "Sample Test #4 (Hello iPhone)", "One more test sample")
[self Log:@"Message from Test #4 - Hello iPhone!\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END

#endif

@end


@implementation TestFordCars
@end

@implementation TestToyotaCars
@end

@implementation TestBentleyCars

#ifdef SAMPLE_TESTS

AUTO_TEST_START(Test_FlyingSpur, "Flying Spur", "Test Continential Flying Spur")
[self Log:@"Continential Flying Sur - Bentley's high-performance sedan.\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END

AUTO_TEST_START(Test_GT, "Continential GT", "Test Continential GT")
[self Log:@"Continential GT - Bentley's high-performance luxury coupe.\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END
AUTO_TEST_START(Test_GTC, "Continential GTC", "Test Continential GTC")
[self Log:@"Continential GTC - Bentley's luxury four-seat convertable.\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END
AUTO_TEST_START(Test_Arnage, "Arnage", "Test Arnage")
[self Log:@"Arnage - Bentley's luxurious high-performance sedan.\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END
AUTO_TEST_START(Test_Supersporta, "Continential Supersports", "Test Continential Supersports")
[self Log:@"Continential Supersports - Bentley's ultra-high performance coupe.\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END
AUTO_TEST_START(Test_Azure, "Azure", "Test Azure")
[self Log:@"Azure - Bentley's flagship convertable.\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END
AUTO_TEST_START(Test_Brooklands, "Brooklands", "Test Brooklands")
[self Log:@"Brooklands - Bentley's luxurious flagship coupe.\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END

#endif

@end

@implementation TestFordSUVs

#ifdef SAMPLE_TESTS

AUTO_TEST_START(Test_Escape, "Escape", "Test Escape")
[self Log:@"Escape - Fords's compact 4-door SUV.\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END
AUTO_TEST_START(Test_Edge, "Edge", "Test Edge")
[self Log:@"Edge - Fords's crossover SUV.\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END
AUTO_TEST_START(Test_Explorer, "Explorer", "Test Explorer")
[self Log:@"Explorer - Fords's midsize 4-door sport utility.\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END
AUTO_TEST_START(Test_ExplorerSportTrac, "Explorer Sport Trac", "Test Explorer Sport Trac")
[self Log:@"Explorer Sport Trac - Fords's sport utility truck.\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END
AUTO_TEST_START(Test_Flex, "Flex", "Test Flex")
[self Log:@"Flex - Fords's new full-size crossover.\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END
AUTO_TEST_START(Test_Expedition, "Expedition", "Test Expedition")
[self Log:@"Expedition - Fords's full-size SUV.\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END

#endif

@end

@implementation TestFordSedans

#ifdef SAMPLE_TESTS

AUTO_TEST_START(Test_Fiesta, "Fiesta", "Test Fiesta")
[self Log:@"Fiesta - Fords's new small car.\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END
AUTO_TEST_START(Test_Focus, "Focus", "Test Focus")
[self Log:@"Focus - Fords's entry-level compact.\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END
AUTO_TEST_START(Test_Fusion, "Fusion", "Test Fusion")
[self Log:@"Fusion - Fords's midsize sedan.\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END
AUTO_TEST_START(Test_Mustang, "Mustang", "Test Mustang")
[self Log:@"Mustang - Fords's sport car icon.\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END
AUTO_TEST_START(Test_Taurus, "Taurus", "Test Taurus")
[self Log:@"Taurus - Fords's full-size sedan.\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END
AUTO_TEST_START(Test_FusionHyprid, "Fusion Hyprid", "Test Fusion Hyprid")
[self Log:@"Fusion Hyprid - Fords's midsize hybrid sedan.\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END

#endif

@end

@implementation TestToyotaSUVs

#ifdef SAMPLE_TESTS

AUTO_TEST_START(Test_RAV4, "RAV4", "Test RAV4")
[self Log:@"RAV4 - Toyotas's compact SUV.\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END
AUTO_TEST_START(Test_FJCruiser, "FJ Cruiser", "Test FJ Cruiser")
[self Log:@"FJ Cruiser - Toyotas's off-road SUV.\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END
AUTO_TEST_START(Test_Venza, "Venza", "Test Venza")
[self Log:@"Venza - Toyotas's new crossover sedan.\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END
AUTO_TEST_START(Test_Highlander, "Highlander", "Test Highlander")
[self Log:@"Highlander - Toyotas's mid-size, car-based SUV.\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END
AUTO_TEST_START(Test_4Runner, "4Runner", "Test 4Runner")
[self Log:@"4Runner - Toyotas's midsize sport-utility vehicle.\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END
AUTO_TEST_START(Test_HighlanderHybrid, "Highlander Hybrid", "Test Highlander Hybrid")
[self Log:@"Highlander Hybrid - Toyotas's midsize crossover hybrid SUV.\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END
AUTO_TEST_START(Test_Sequoia, "Sequoia", "Test Sequoia")
[self Log:@"Sequoia - Toyotas's full-size SUV.\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END
AUTO_TEST_START(Test_LandCruiser, "Land Cruiser", "Test Land Cruiser")
[self Log:@"Land Cruiser - Toyotas's premium full-size SUV.\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END

#endif

@end

@implementation TestToyotaPassengerCars

#ifdef SAMPLE_TESTS

AUTO_TEST_START(Test_Yaris, "Yaris", "Test Yaris")
[self Log:@"Yaris - Toyotas's subcompact hatchback and sedan.\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END
AUTO_TEST_START(Test_Corolla, "Corolla", "Test Corolla")
[self Log:@"Corolla - Toyotas's compact sedan.\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END
AUTO_TEST_START(Test_Matrix, "Matrix", "Test Matrix")
[self Log:@"Matrix - Toyotas's compact crossover.\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END
AUTO_TEST_START(Test_Camry, "Camry", "Test Camry")
[self Log:@"Camry - Toyotas's midsize sedan.\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END
AUTO_TEST_START(Test_Prius, "Prius", "Test Prius")
[self Log:@"Prius - Toyotas's first gas/electric hybrid.\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END
AUTO_TEST_START(Test_Venza, "Venza", "Test Venza")
[self Log:@"Venza - Toyotas's new crossover sedan.\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END
AUTO_TEST_START(Test_Avalon, "Avalon", "Test Avalon")
[self Log:@"Avalon - Toyotas's full-size sedan.\n"];
[NSThread sleepForTimeInterval:(NSTimeInterval)1.0];           
TEST_END

#endif

@end
