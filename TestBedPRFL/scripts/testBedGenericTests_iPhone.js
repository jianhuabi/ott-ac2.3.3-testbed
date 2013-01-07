//
//  testBedGenericTests_iPhone.js
//  ActiveCloak
//
//  Created by Apple User on 2/26/11.
//  Copyright 2011 Irdeto. All rights reserved.
//

////////////////////////////////////////////////////////////////////////////////
// This secion contains utility functions to support testing process

function assertEquals(expected, received, message) 
{
  if (received != expected) 
  {
    if (! message) 
    	message = "Expected " + expected + " but received " + received;
    throw message;
  }
}

function assertTrue(expression, message) 
{
	if (!expression) 
	{
    	if (!message) 
    		message = "Assertion failed";
    	throw message;
  	}
    else if (message)
    {
        UIALogger.logMessage(message);
    }
}

function assertFalse(expression, message) 
{
  	assertTrue(! expression, message);
}

function assertNotNull(thingie, message) 
{
  	if (thingie == null || thingie.toString() == "[object UIAElementNil]") 
  	{
    	if (message == null) 
    		message = "Expected not null object";
    	throw message;
  	}
}

function logElementArrayInfo(elements, title)
{
    UIALogger.logMessage(title + "array count = " + elements.length.toString());
    for (index = 0; index < elements.length; index++)
    {
        UIALogger.logMessage("\elements[" + index.toString() + "].name = '" + elements[index].name() + "' (" + elements[index].toString() + ")");
    }
}

function test(title, testFunction, options)
{
	if (options == null)
	{
		options = {logTree: true};
	}
	target = UIATarget.localTarget();
	application = target.frontMostApp();
    g_title = title;
	UIALogger.logStart(title);
	try
	{
		testFunction(target, application);
		UIALogger.logPass(title);
	}
	catch (e)
	{
		UIALogger.logError(e);
		if (options.logTree)
		{
			application.logElementTree();
		}
		UIALogger.logFail(title)
	}
    //catch (ReferenceError refError)
    //{
	//	UIALogger.logError(refError);
	//	UIALogger.logFail(title)
    //}
}

function onUnexpectedAlert(alert)
{
    var title = alert.name();
    UIALogger.logMessage("Alert with title = '" + title + "'");
    return false; // use default handler
}

var g_orientationList = 
[
 {numb: UIA_DEVICE_ORIENTATION_UNKNOWN,             name:"UIA_DEVICE_ORIENTATION_UNKNOWN"},
 {numb: UIA_DEVICE_ORIENTATION_PORTRAIT,            name:"UIA_DEVICE_ORIENTATION_PORTRAIT"},
 {numb: UIA_DEVICE_ORIENTATION_PORTRAIT_UPSIDEDOWN, name:"UIA_DEVICE_ORIENTATION_PORTRAIT_UPSIDEDOWN"},
 {numb: UIA_DEVICE_ORIENTATION_LANDSCAPELEFT,       name:"UIA_DEVICE_ORIENTATION_LANDSCAPELEFT"},
 {numb: UIA_DEVICE_ORIENTATION_LANDSCAPERIGHT,      name:"UIA_DEVICE_ORIENTATION_LANDSCAPERIGHT"},
 {numb: UIA_DEVICE_ORIENTATION_FACEUP,              name:"UIA_DEVICE_ORIENTATION_FACEUP"},
 {numb: UIA_DEVICE_ORIENTATION_FACEDOWN,            name:"UIA_DEVICE_ORIENTATION_FACEDOWN"}
];

function logOrientationName(title, orientation)
{
    var orientationName = "<not found>";
    
    for (index = 0; index < g_orientationList.length; index++)
    {
        if (g_orientationList[index].numb == orientation)
        {
            orientationName = g_orientationList[index].name;
            break;
        }
    }
    UIALogger.logMessage(title + orientationName);
}

function ensureInterfaceOrientation(target, application, orientation)
{
    logOrientationName("ensure Interface Orientation: ", orientation);
    var currentOrientation = application.interfaceOrientation();
    if (currentOrientation != orientation)
    {
        var deviceOrientation = orientation;
        target.setDeviceOrientation(deviceOrientation);
        currentOrientation = application.interfaceOrientation();
        while (currentOrientation != orientation)
        {
            logOrientationName("current interfaceOrientation: ", currentOrientation);
            target.delay(1);
            currentOrientation = application.interfaceOrientation();
        }
    }
    logOrientationName("ensured Interface Orientation: ", currentOrientation);
}

function ensureInterfaceOrientationPortrait(target, application)
{
    var currentOrientation = application.interfaceOrientation();
    if (currentOrientation != UIA_DEVICE_ORIENTATION_PORTRAIT &&
        currentOrientation != UIA_DEVICE_ORIENTATION_PORTRAIT_UPSIDEDOWN)
    {
        if (target.deviceOrientation() == UIA_DEVICE_ORIENTATION_PORTRAIT)
        {
            ensureInterfaceOrientation(target, application, UIA_DEVICE_ORIENTATION_PORTRAIT);
        }
        else if (target.deviceOrientation() == UIA_DEVICE_ORIENTATION_PORTRAIT_UPSIDEDOWN)
        {
            ensureInterfaceOrientation(target, application, UIA_DEVICE_ORIENTATION_PORTRAIT_UPSIDEDOWN);
        }
        else
        {
            ensureInterfaceOrientation(target, application, UIA_DEVICE_ORIENTATION_PORTRAIT);
        }
    }
    
}

function ensureInterfaceOrientationLandscape(target, application)
{
    var currentOrientation = application.interfaceOrientation();
    if (currentOrientation != UIA_DEVICE_ORIENTATION_LANDSCAPELEFT &&
        currentOrientation != UIA_DEVICE_ORIENTATION_LANDSCAPERIGHT)
    {
        if (target.deviceOrientation() == UIA_DEVICE_ORIENTATION_LANDSCAPELEFT)
        {
            ensureInterfaceOrientation(target, application, UIA_DEVICE_ORIENTATION_LANDSCAPERIGHT);
        }
        else if (target.deviceOrientation() == UIA_DEVICE_ORIENTATION_LANDSCAPERIGHT)
        {
            ensureInterfaceOrientation(target, application, UIA_DEVICE_ORIENTATION_LANDSCAPELEFT);
        }
        else
        {
            ensureInterfaceOrientation(target, application, UIA_DEVICE_ORIENTATION_LANDSCAPELEFT);
        }
    }
    
}

function performScrollDown(scrollView, number)
{
    var count = number;
    while (count > 0)
    {
        scrollView.scrollDown();
        target.delay(1);
        count -= 1;
    }
}

function performScrollUp(scrollView, number)
{
    var count = number;
    while (count > 0)
    {
        scrollView.scrollUp();
        target.delay(1);
        count -= 1;
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

var const_ResetLogMenuIndex = 0;
var const_ExitMediaPLayerMenuIndex = 1;
var const_SendStatusReportMenuIndex = 2;
var const_SendListOfTestsMenuIndex = 3;
var const_SwitchToDemoModeMenuIndex = 4;
var const_SwitchToTestModeMenuIndex = 2;

var str_TestModePopupMenuName = "testModePopupMenu";
var str_DemoModePopupMenuName = "demoModePopupMenu";

var g_title = null;
var g_aboutInfoIsValid = false;

////////////////////////////////////////////////////////////////////////////////
// These are utility functions to support TestBed testing

function onAboutInfoAlert(alert)
{
    var staticTexts = alert.staticTexts();
    var title = staticTexts.length > 0 ? staticTexts[0].name() : "<null>";
    UIALogger.logMessage("Alert with title = '" + title + "'");
    alert.logElementTree();
    g_aboutInfoIsValid = staticTexts.length == 2 && staticTexts[0].name() == "TestBed" && 
        staticTexts[1].name().substr(0, 33) == "Copyright (C) 2010, Irdeto Canada";
    //target.delay(3);
    return false; // use default handler
} 

function onPopupMenu(menu)
{
    var title = menu.name();
    UIALogger.logMessage("Alert with title = '" + title + "'");
    return false; // use default handler
} 

function tapActionSheetButton(target, actionSheet, buttonIndex)
{
    var headerHeight = 28;
    var buttonHeight = 50;
    
    if (buttonIndex >= 0) 
    {
        var actionSheetRect = actionSheet.rect();
        UIALogger.logMessage("actionSheet:{rect:{origin:{x:" + actionSheetRect.origin.x.toString() 
                             + ", y:" + actionSheetRect.origin.y.toString()
                             + "}, size:{width:" + actionSheetRect.size.width.toString()
                             + ", height:" + actionSheetRect.size.height.toString()
                             + "}}}");
        var xOffset = actionSheetRect.size.width / 2;
        var yOffset = headerHeight + buttonIndex * buttonHeight + buttonHeight / 2;
        if (yOffset < actionSheetRect.size.height) {
            var tap_x = actionSheetRect.origin.x + xOffset;
            var tap_y = actionSheetRect.origin.y + yOffset;
            target.tap({x:tap_x, y:tap_y});
        }
    }
    else
    {
        var message = "Cannot tap button " + buttonIndex.toString() + ". It does not exist";
        throw message;
    }
}

function checkActionSheetDismissed(mainWindow)
{
    var actionSheet = application.actionSheet();
    while (actionSheet != null 
           && actionSheet.isValid())
    {
        target.delay(1);
        actionSheet = application.actionSheet();
    }
    
    target.delay(1);
}

function performMenuAction_iPhone(target, application, menuName, menuItemIndex)
{
    var mainWindow = application.mainWindow();
    var currentOnAlert = UIATarget.onAlert;
    UIATarget.onAlert = onUnexpectedAlert;
    
    var menuButton = mainWindow.toolbars()[0].buttons()["Menu"];
    assertTrue(menuButton != null, "Top toolbar Menu button exists");
    UIALogger.logMessage("Found 'Menu' button");
    
    menuButton.tap();
    
    var actionSheet = application.actionSheet();
    assertTrue(actionSheet != null 
               && actionSheet.name() == menuName /*"testModePopupMenu"*/ 
               && actionSheet.isValid(), 
               "Action Sheet from Menu button has poped up.");
    
    assertTrue(actionSheet.buttons().length <= 0, "Action Sheet does not show any buttons by default");
    tapActionSheetButton(target, actionSheet, menuItemIndex);
    target.delay(1);
    
    checkActionSheetDismissed(application);
    
    UIATarget.onAlert = currentOnAlert;
}

////////////////////////////////////////////////////////////////////////////////
// This section contains test functions to run

function changeOrientation(target, application)
{
    
    var currentOrientation = application.interfaceOrientation();
    
    logOrientationName("currentOrientation = ", currentOrientation);
    
    ensureInterfaceOrientation(target, application, UIA_DEVICE_ORIENTATION_PORTRAIT);
    ensureInterfaceOrientation(target, application, UIA_DEVICE_ORIENTATION_PORTRAIT_UPSIDEDOWN);
    ensureInterfaceOrientation(target, application, UIA_DEVICE_ORIENTATION_LANDSCAPELEFT);
    ensureInterfaceOrientation(target, application, UIA_DEVICE_ORIENTATION_LANDSCAPERIGHT);
    ensureInterfaceOrientation(target, application, currentOrientation);
}

function switchTabBars(target, application)
{
    var mainWindow = application.mainWindow();
	assertTrue(mainWindow != null, "Verified 'mainWindow' != null");
    UIATarget.onAlert = onUnexpectedAlert;
    
    var tabBar = application.tabBar();
    assertTrue(tabBar.isValid(), "Obtained TabBar");
    var selectedTabName = tabBar.selectedButton().name();
    UIALogger.logMessage("Selected Tab Name = " + selectedTabName);
    
    var tabBarButtons = tabBar.buttons();
    logElementArrayInfo(tabBarButtons, "Tab Bar Buttons ");
    
    var tabBarTestsButton = tabBarButtons["Tests"];
    var tabBarLogInfoButton = tabBarButtons["Log Info"];

    UIALogger.logMessage("Tapped 'Tests' tab bar button");
    tabBarTestsButton.tap();
    target.delay(1);
    application.mainWindow().logElementTree();
    UIALogger.logMessage("Tapped 'Log Info' tab bar button");
    tabBarLogInfoButton.tap();
    target.delay(1);
    application.mainWindow().logElementTree();
    var testDetailView = application.mainWindow().elements()["testDetailView"];
    
    
    logElementArrayInfo(application.elements(), "Application Elements ");
}

function showAboutInfo (target, application)
{
	assertTrue(target != null, "Verifeid 'target' != null");
    
	assertTrue(application != null, "Verified 'application' != null");
	
    var mainWindow = application.mainWindow();
	assertTrue(mainWindow != null, "Verified 'mainWindow' != null");
    
    UIATarget.onAlert = onUnexpectedAlert;

    var toolbars = mainWindow.toolbars();
    logElementArrayInfo(toolbars, "Main window toolbars ");
    assertTrue(toolbars.length == 2, "Verfied that 2 toolbars exist");
    
    var topToolbar = toolbars[0];
    var bottomToolbar = toolbars[1];
    
    var topButtons = topToolbar.buttons();
    logElementArrayInfo(topButtons, "Top toolbar button ");
    
    var aboutInfoButton = topButtons.firstWithName("aboutInfoButton");
    assertTrue(aboutInfoButton != null, "About Info button exists");
    
    
    // show About information
    UIALogger.logMessage("Show About information");
    UIATarget.onAlert = onAboutInfoAlert;
    aboutInfoButton.tap();
    UIALogger.logMessage("Tapped info button");
        
    // delay script for 3 seconds
    target.delay(1);
    assertTrue(g_aboutInfoIsValid, "About Info dialog appeared correctly");
    
    UIATarget.onAlert = onUnexpectedAlert;
    target.delay(1);
    
}

function navigateAndPlayVideoTestsInPortraitMode(target, application)
{
    var mainWindow = application.mainWindow();
    var currentOnAlert = UIATarget.onAlert;
    UIATarget.onAlert = onUnexpectedAlert;

    // remember the orientation
    var currentOrientation = application.interfaceOrientation();
    
    // change orientation if it is required
    ensureInterfaceOrientationPortrait(target, application);
    
    target.captureScreenWithName("beforeTest"); // specify a name for the screenshot
    
    var tabBar = application.tabBar();
    assertTrue(tabBar.isValid(), "Obtained TabBar");
    var selectedTabName = tabBar.selectedButton().name();
    UIALogger.logMessage("Selected Tab Name = " + selectedTabName);
    
    var tabBarButtons = tabBar.buttons();
    logElementArrayInfo(tabBarButtons, "Tab Bar Buttons ");
    
    var tabBarTestsButton = tabBarButtons["Tests"];
    var tabBarLogInfoButton = tabBarButtons["Log Info"];
    
    tabBarTestsButton.tap();
    
    var solutionTestsCell = mainWindow.tableViews()[0].cells()["SolutionTests"];
    assertTrue(solutionTestsCell != null && solutionTestsCell.name() == "SolutionTests", "SolutionTests group exists");
    
    solutionTestsCell.tap();
    target.delay(1);
    
    var videoTestsCell = mainWindow.tableViews()[0].cells()["VideoTests"];
    assertTrue(videoTestsCell != null && videoTestsCell.name() == "VideoTests", "VideoTests group exists");

    videoTestsCell.tap();
    target.delay(1);

    mainWindow.tableViews()[0].scrollUp();
    target.delay(1);
    target.dragFromToForDuration({x:160, y:400}, {x:160, y:50}, 0.5);
    target.delay(2);
    var bbbUrlCell = mainWindow.tableViews()[0].cells()[12]/*["Big Buck Bunny"]*/;
    var bbbSelectButton = bbbUrlCell.elements()["Run"];
    bbbUrlCell.tap();
    bbbSelectButton.tap();
    target.delay(1);
    
    tabBarLogInfoButton.tap();
    target.delay(1);
    
    tabBarTestsButton.tap();
    target.delay(1);
    
    mainWindow.tableViews()[0].scrollUp();
    target.delay(1);
    target.dragFromToForDuration({x:160, y:400}, {x:160, y:50}, 0.5);
    target.delay(2);
    bbbUrlCell = mainWindow.tableViews()[0].cells()[11]/*["Big Buck Bunny"]*/;
    bbbSelectButton = bbbUrlCell.elements()["Run"];
    bbbUrlCell.tap();
    bbbSelectButton.tap();
    target.delay(1);

    tabBarLogInfoButton.tap();
    target.delay(1);
    
    tabBarTestsButton.tap();
    target.delay(1);

    mainWindow.tableViews()[0].scrollUp();
    target.delay(1);
    var playCurrentlySelectedVideoCell = mainWindow.tableViews()[0].cells()[4]/*["Play Currently Selected Video"]*/;
    var playVideoButton = playCurrentlySelectedVideoCell.elements()["Run"];
    playCurrentlySelectedVideoCell.tap();
    playVideoButton.tap();
    target.delay(3);

    tabBarLogInfoButton.tap();
    
    target.delay(15);
    target.captureScreenWithName("playingBbb"); // specify a name for the screenshot
    
    tabBarTestsButton.tap();
    target.delay(3);
    
    mainWindow.tableViews()[0].scrollUp();
    target.delay(1);
    target.dragFromToForDuration({x:160, y:400}, {x:160, y:50}, 0.6);
    target.delay(2);
    var avatarUrlCell = mainWindow.tableViews()[0].cells()[10]/*["Avatar Behind-the-Scenes"]*/;
    var avatarSelectButton = avatarUrlCell.elements()["Run"];
    avatarUrlCell.tap();
    avatarSelectButton.tap();
    target.delay(2);

    mainWindow.tableViews()[0].scrollUp();
    target.delay(1);
    playCurrentlySelectedVideoCell = mainWindow.tableViews()[0].cells()[4]/*["Play Currently Selected Video"]*/;
    playVideoButton = playCurrentlySelectedVideoCell.elements()["Run"];
    playCurrentlySelectedVideoCell.tap();
    playVideoButton.tap();
    target.delay(3);
    
    tabBarLogInfoButton.tap();
    
    target.delay(30);
    target.captureScreenWithName("playingAvatar"); // specify a name for the screenshot

    performMenuAction_iPhone(target, application, str_TestModePopupMenuName, const_ExitMediaPLayerMenuIndex);

    // wait until media player stops working
    target.delay(3);
    
    tabBarTestsButton.tap();
    target.delay(3);
    
    var navigationBar = mainWindow.navigationBar();
    assertTrue(navigationBar.isValid(), "Obtained navigationBar");
    var navigationBarButtons = navigationBar.buttons();
    assertTrue(navigationBarButtons.length == 2, "navigationBar contains 2 buttons");
    var solutionTestsButton = navigationBarButtons["SolutionTests"];
    assertTrue(solutionTestsButton.isValid(), "Obtained 'SolutionTests' button in the navigationBar");
    
    solutionTestsButton.tap();
    target.delay(1);
    
    navigationBar = mainWindow.navigationBar();
    navigationBarButtons = navigationBar.buttons();
    assertTrue(navigationBarButtons.length == 2, "navigationBar still contains 2 buttons");
    var testsButton = navigationBarButtons["Tests"];
    assertTrue(testsButton.isValid(), "Obtained 'Tests' button in the navigationBar");
    
    testsButton.tap();
    target.delay(1);
    
    navigationBar = mainWindow.navigationBar();
    navigationBarButtons = navigationBar.buttons();
    assertTrue(navigationBarButtons.length == 1 && navigationBarButtons[0].name() == "Run", "Navigation has only Run button");
    target.delay(1);

    tabBarLogInfoButton.tap();
    
    // restore orientation
    ensureInterfaceOrientation(target, application, currentOrientation);
}

function navigateAndPlayVideoTestsInLandscapeMode(target, application)
{
    var mainWindow = application.mainWindow();
    var currentOnAlert = UIATarget.onAlert;
    UIATarget.onAlert = onUnexpectedAlert;
    
    // remember the orientation
    var currentOrientation = application.interfaceOrientation();
    
    // change orientation if it is required
    ensureInterfaceOrientationLandscape(target, application);
    
    target.captureScreenWithName("beforeTest"); // specify a name for the screenshot
    
    var tabBar = application.tabBar();
    assertTrue(tabBar.isValid(), "Obtained TabBar");
    var selectedTabName = tabBar.selectedButton().name();
    UIALogger.logMessage("Selected Tab Name = " + selectedTabName);
    
    var tabBarButtons = tabBar.buttons();
    logElementArrayInfo(tabBarButtons, "Tab Bar Buttons ");
    
    var tabBarTestsButton = tabBarButtons["Tests"];
    var tabBarLogInfoButton = tabBarButtons["Log Info"];
    
    tabBarTestsButton.tap();
    
    var solutionTestsCell = mainWindow.tableViews()[0].cells()["SolutionTests"];
    assertTrue(solutionTestsCell != null && solutionTestsCell.name() == "SolutionTests", "SolutionTests group exists");
    
    solutionTestsCell.tap();
    target.delay(1);
    
    var videoTestsCell = mainWindow.tableViews()[0].cells()["VideoTests"];
    assertTrue(videoTestsCell != null && videoTestsCell.name() == "VideoTests", "VideoTests group exists");
    
    videoTestsCell.tap();
    target.delay(1);
    
    mainWindow.tableViews()[0].scrollUp();
    target.delay(1);
    performScrollDown(mainWindow.tableViews()[0], 2);
    target.delay(2);
    var bbbUrlCell = mainWindow.tableViews()[0].cells()[12]/*["Big Buck Bunny"]*/;
    var bbbSelectButton = bbbUrlCell.elements()["Run"];
    bbbUrlCell.tap();
    bbbSelectButton.tap();
    target.delay(1);
    
    tabBarLogInfoButton.tap();
    target.delay(1);
    
    tabBarTestsButton.tap();
    target.delay(1);
    
    performScrollUp(mainWindow.tableViews()[0], 2);
    target.delay(1);
    performScrollDown(mainWindow.tableViews()[0], 2);
    target.delay(2);
    bbbUrlCell = mainWindow.tableViews()[0].cells()[11]/*["Big Buck Bunny"]*/;
    bbbSelectButton = bbbUrlCell.elements()["Run"];
    bbbUrlCell.tap();
    bbbSelectButton.tap();
    target.delay(1);
    
    tabBarLogInfoButton.tap();
    target.delay(1);
    
    tabBarTestsButton.tap();
    target.delay(1);
    
    performScrollUp(mainWindow.tableViews()[0], 1);
    target.delay(1);
    var playCurrentlySelectedVideoCell = mainWindow.tableViews()[0].cells()[4]/*["Play Currently Selected Video"]*/;
    var playVideoButton = playCurrentlySelectedVideoCell.elements()["Run"];
    playCurrentlySelectedVideoCell.tap();
    playVideoButton.tap();
    target.delay(3);
    
    tabBarLogInfoButton.tap();
    
    target.delay(15);
    target.captureScreenWithName("playingBbb"); // specify a name for the screenshot
    
    tabBarTestsButton.tap();
    target.delay(3);
    
    performScrollDown(mainWindow.tableViews()[0], 1);
    target.delay(2);
    var avatarUrlCell = mainWindow.tableViews()[0].cells()[10]/*["Avatar Behind-the-Scenes"]*/;
    var avatarSelectButton = avatarUrlCell.elements()["Run"];
    avatarUrlCell.tap();
    avatarSelectButton.tap();
    target.delay(2);
    
    performScrollUp(mainWindow.tableViews()[0], 1);
    target.delay(1);
    playCurrentlySelectedVideoCell = mainWindow.tableViews()[0].cells()[4]/*["Play Currently Selected Video"]*/;
    playVideoButton = playCurrentlySelectedVideoCell.elements()["Run"];
    playCurrentlySelectedVideoCell.tap();
    playVideoButton.tap();
    target.delay(3);
    
    tabBarLogInfoButton.tap();
    
    target.delay(30);
    target.captureScreenWithName("playingAvatar"); // specify a name for the screenshot
    
    performMenuAction_iPhone(target, application, str_TestModePopupMenuName, const_ExitMediaPLayerMenuIndex);
    
    // wait until media player stops working
    target.delay(3);
    
    tabBarTestsButton.tap();
    target.delay(3);
    
    var navigationBar = mainWindow.navigationBar();
    assertTrue(navigationBar.isValid(), "Obtained navigationBar");
    var navigationBarButtons = navigationBar.buttons();
    assertTrue(navigationBarButtons.length == 2, "navigationBar contains 2 buttons");
    var solutionTestsButton = navigationBarButtons["SolutionTests"];
    assertTrue(solutionTestsButton.isValid(), "Obtained 'SolutionTests' button in the navigationBar");
    
    solutionTestsButton.tap();
    target.delay(1);
    
    navigationBar = mainWindow.navigationBar();
    navigationBarButtons = navigationBar.buttons();
    assertTrue(navigationBarButtons.length == 2, "navigationBar still contains 2 buttons");
    var testsButton = navigationBarButtons["Tests"];
    assertTrue(testsButton.isValid(), "Obtained 'Tests' button in the navigationBar");
    
    testsButton.tap();
    target.delay(1);
    
    navigationBar = mainWindow.navigationBar();
    navigationBarButtons = navigationBar.buttons();
    assertTrue(navigationBarButtons.length == 1 && navigationBarButtons[0].name() == "Run", "Navigation has only Run button");
    target.delay(1);
    
    tabBarLogInfoButton.tap();
    
    // restore orientation
    ensureInterfaceOrientation(target, application, currentOrientation);
    
}

////////////////////////////////////////////////////////////////////////////////
// This section contains the sequense of tests 

try
{
    test("Change Orientation", changeOrientation, null);
    
    test("Switching Tab Bars", switchTabBars, null);
    
    test("Show About Info", showAboutInfo, null);
    
    test("Navigate And Play Video Test in Portrait Mode", navigateAndPlayVideoTestsInPortraitMode, null);
    
    test("Navigate And Play Video Tests in Landscape Mode", navigateAndPlayVideoTestsInLandscapeMode, null);

} 
catch (e)
{
	UIALogger.logError(e);
	if (options.logTree)
	{
		application.logElementTree();
	}
	UIALogger.logFail(title)
}

